package Test2::API::Instance;
use strict;
use warnings;

our $VERSION = '1.302073';


our @CARP_NOT = qw/Test2::API Test2::API::Instance Test2::IPC::Driver Test2::Formatter/;
use Carp qw/confess carp/;
use Scalar::Util qw/reftype/;

use Test2::Util qw/get_tid USE_THREADS CAN_FORK pkg_to_file try/;

use Test2::Util::Trace();
use Test2::API::Stack();

use Test2::Util::HashBase qw{
    _pid _tid
    no_wait
    finalized loaded
    ipc stack formatter
    contexts

    ipc_shm_size
    ipc_shm_last
    ipc_shm_id
    ipc_polling
    ipc_drivers
    formatters

    exit_callbacks
    post_load_callbacks
    context_acquire_callbacks
    context_init_callbacks
    context_release_callbacks
};

sub pid { $_[0]->{+_PID} ||= $$ }
sub tid { $_[0]->{+_TID} ||= get_tid() }

# Wrap around the getters that should call _finalize.
BEGIN {
    for my $finalizer (IPC, FORMATTER) {
        my $orig = __PACKAGE__->can($finalizer);
        my $new  = sub {
            my $self = shift;
            $self->_finalize unless $self->{+FINALIZED};
            $self->$orig;
        };

        no strict 'refs';
        no warnings 'redefine';
        *{$finalizer} = $new;
    }
}

sub import {
    my $class = shift;
    return unless @_;
    my ($ref) = @_;
    $$ref = $class->new;
}

sub init { $_[0]->reset }

sub reset {
    my $self = shift;

    delete $self->{+_PID};
    delete $self->{+_TID};

    $self->{+CONTEXTS}    = {};

    $self->{+IPC_DRIVERS} = [];
    $self->{+IPC_POLLING} = undef;

    $self->{+FORMATTERS} = [];
    $self->{+FORMATTER}  = undef;

    $self->{+FINALIZED} = undef;
    $self->{+IPC}       = undef;

    $self->{+NO_WAIT} = 0;
    $self->{+LOADED}  = 0;

    $self->{+EXIT_CALLBACKS}            = [];
    $self->{+POST_LOAD_CALLBACKS}       = [];
    $self->{+CONTEXT_ACQUIRE_CALLBACKS} = [];
    $self->{+CONTEXT_INIT_CALLBACKS}    = [];
    $self->{+CONTEXT_RELEASE_CALLBACKS} = [];

    $self->{+STACK} = Test2::API::Stack->new;
}

sub _finalize {
    my $self = shift;
    my ($caller) = @_;
    $caller ||= [caller(1)];

    $self->{+FINALIZED} = $caller;

    $self->{+_PID} = $$        unless defined $self->{+_PID};
    $self->{+_TID} = get_tid() unless defined $self->{+_TID};

    unless ($self->{+FORMATTER}) {
        my ($formatter, $source);
        if ($ENV{T2_FORMATTER}) {
            $source = "set by the 'T2_FORMATTER' environment variable";

            if ($ENV{T2_FORMATTER} =~ m/^(\+)?(.*)$/) {
                $formatter = $1 ? $2 : "Test2::Formatter::$2"
            }
            else {
                $formatter = '';
            }
        }
        elsif (@{$self->{+FORMATTERS}}) {
            ($formatter) = @{$self->{+FORMATTERS}};
            $source = "Most recently added";
        }
        else {
            $formatter = 'Test2::Formatter::TAP';
            $source    = 'default formatter';
        }

        unless (ref($formatter) || $formatter->can('write')) {
            my $file = pkg_to_file($formatter);
            my ($ok, $err) = try { require $file };
            unless ($ok) {
                my $line   = "* COULD NOT LOAD FORMATTER '$formatter' ($source) *";
                my $border = '*' x length($line);
                die "\n\n  $border\n  $line\n  $border\n\n$err";
            }
        }

        $self->{+FORMATTER} = $formatter;
    }

    # Turn on IPC if threads are on, drivers are registered, or the Test2::IPC
    # module is loaded.
    return unless USE_THREADS || $INC{'Test2/IPC.pm'} || @{$self->{+IPC_DRIVERS}};

    # Turn on polling by default, people expect it.
    $self->enable_ipc_polling;

    unless (@{$self->{+IPC_DRIVERS}}) {
        my ($ok, $error) = try { require Test2::IPC::Driver::Files };
        die $error unless $ok;
        push @{$self->{+IPC_DRIVERS}} => 'Test2::IPC::Driver::Files';
    }

    for my $driver (@{$self->{+IPC_DRIVERS}}) {
        next unless $driver->can('is_viable') && $driver->is_viable;
        $self->{+IPC} = $driver->new or next;
        $self->ipc_enable_shm if $self->{+IPC}->use_shm;
        return;
    }

    die "IPC has been requested, but no viable drivers were found. Aborting...\n";
}

sub formatter_set { $_[0]->{+FORMATTER} ? 1 : 0 }

sub add_formatter {
    my $self = shift;
    my ($formatter) = @_;
    unshift @{$self->{+FORMATTERS}} => $formatter;

    return unless $self->{+FINALIZED};

    # Why is the @CARP_NOT entry not enough?
    local %Carp::Internal = %Carp::Internal;
    $Carp::Internal{'Test2::Formatter'} = 1;

    carp "Formatter $formatter loaded too late to be used as the global formatter";
}

sub add_context_acquire_callback {
    my $self =  shift;
    my ($code) = @_;

    my $rtype = reftype($code) || "";

    confess "Context-acquire callbacks must be coderefs"
        unless $code && $rtype eq 'CODE';

    push @{$self->{+CONTEXT_ACQUIRE_CALLBACKS}} => $code;
}

sub add_context_init_callback {
    my $self =  shift;
    my ($code) = @_;

    my $rtype = reftype($code) || "";

    confess "Context-init callbacks must be coderefs"
        unless $code && $rtype eq 'CODE';

    push @{$self->{+CONTEXT_INIT_CALLBACKS}} => $code;
}

sub add_context_release_callback {
    my $self =  shift;
    my ($code) = @_;

    my $rtype = reftype($code) || "";

    confess "Context-release callbacks must be coderefs"
        unless $code && $rtype eq 'CODE';

    push @{$self->{+CONTEXT_RELEASE_CALLBACKS}} => $code;
}

sub add_post_load_callback {
    my $self = shift;
    my ($code) = @_;

    my $rtype = reftype($code) || "";

    confess "Post-load callbacks must be coderefs"
        unless $code && $rtype eq 'CODE';

    push @{$self->{+POST_LOAD_CALLBACKS}} => $code;
    $code->() if $self->{+LOADED};
}

sub load {
    my $self = shift;
    unless ($self->{+LOADED}) {
        $self->{+_PID} = $$        unless defined $self->{+_PID};
        $self->{+_TID} = get_tid() unless defined $self->{+_TID};

        # This is for https://github.com/Test-More/test-more/issues/16
        # and https://rt.perl.org/Public/Bug/Display.html?id=127774
        # END blocks run in reverse order. This insures the END block is loaded
        # as late as possible. It will not solve all cases, but it helps.
        eval "END { Test2::API::test2_set_is_end() }; 1" or die $@;

        $self->{+LOADED} = 1;
        $_->() for @{$self->{+POST_LOAD_CALLBACKS}};
    }
    return $self->{+LOADED};
}

sub add_exit_callback {
    my $self = shift;
    my ($code) = @_;
    my $rtype = reftype($code) || "";

    confess "End callbacks must be coderefs"
        unless $code && $rtype eq 'CODE';

    push @{$self->{+EXIT_CALLBACKS}} => $code;
}

sub add_ipc_driver {
    my $self = shift;
    my ($driver) = @_;
    unshift @{$self->{+IPC_DRIVERS}} => $driver;

    return unless $self->{+FINALIZED};

    # Why is the @CARP_NOT entry not enough?
    local %Carp::Internal = %Carp::Internal;
    $Carp::Internal{'Test2::IPC::Driver'} = 1;

    carp "IPC driver $driver loaded too late to be used as the global ipc driver";
}

sub enable_ipc_polling {
    my $self = shift;

    $self->{+_PID} = $$        unless defined $self->{+_PID};
    $self->{+_TID} = get_tid() unless defined $self->{+_TID};

    $self->add_context_init_callback(
        # This is called every time a context is created, it needs to be fast.
        # $_[0] is a context object
        sub {
            return unless $self->{+IPC_POLLING};
            return $_[0]->{hub}->cull unless $self->{+IPC_SHM_ID};

            my $val;
            {
                shmread($self->{+IPC_SHM_ID}, $val, 0, $self->{+IPC_SHM_SIZE}) or return;

                return if $val eq $self->{+IPC_SHM_LAST};
                $self->{+IPC_SHM_LAST} = $val;
            }

            $_[0]->{hub}->cull;
        }
    ) unless defined $self->ipc_polling;

    $self->set_ipc_polling(1);
}

sub ipc_enable_shm {
    my $self = shift;

    return 1 if defined $self->{+IPC_SHM_ID};

    $self->{+_PID} = $$        unless defined $self->{+_PID};
    $self->{+_TID} = get_tid() unless defined $self->{+_TID};

    my ($ok, $err) = try {
        # SysV IPC can be available but not enabled.
        #
        # In some systems (*BSD) accessing the SysV IPC APIs without
        # them being enabled can cause a SIGSYS.  We suppress the SIGSYS
        # and then get ENOSYS from the calls.
        local $SIG{SYS} = 'IGNORE';

        require IPC::SysV;

        my $ipc_key = IPC::SysV::IPC_PRIVATE();
        my $shm_size = $self->{+IPC}->can('shm_size') ? $self->{+IPC}->shm_size : 64;
        my $shm_id = shmget($ipc_key, $shm_size, 0666) or die;

        my $initial = 'a' x $shm_size;
        shmwrite($shm_id, $initial, 0, $shm_size) or die;

        $self->{+IPC_SHM_SIZE} = $shm_size;
        $self->{+IPC_SHM_ID}   = $shm_id;
        $self->{+IPC_SHM_LAST} = $initial;
    };

    return $ok;
}

sub ipc_free_shm {
    my $self = shift;

    my $id = delete $self->{+IPC_SHM_ID};
    return unless defined $id;

    shmctl($id, IPC::SysV::IPC_RMID(), 0);
}

sub get_ipc_pending {
    my $self = shift;
    return -1 unless defined $self->{+IPC_SHM_ID};
    my $val;
    shmread($self->{+IPC_SHM_ID}, $val, 0, $self->{+IPC_SHM_SIZE}) or return -1;
    return 0 if $val eq $self->{+IPC_SHM_LAST};
    $self->{+IPC_SHM_LAST} = $val;
    return 1;
}

sub set_ipc_pending {
    my $self = shift;

    return undef unless defined $self->{+IPC_SHM_ID};

    my ($val) = @_;

    confess "value is required for set_ipc_pending"
        unless $val;

    shmwrite($self->{+IPC_SHM_ID}, $val, 0, $self->{+IPC_SHM_SIZE});
}

sub disable_ipc_polling {
    my $self = shift;
    return unless defined $self->{+IPC_POLLING};
    $self->{+IPC_POLLING} = 0;
}

sub _ipc_wait {
    my $fail = 0;

    if (CAN_FORK) {
        while (1) {
            my $pid = CORE::wait();
            my $err = $?;
            last if $pid == -1;
            next unless $err;
            $fail++;
            $err = $err >> 8;
            warn "Process $pid did not exit cleanly (status: $err)\n";
        }
    }

    if (USE_THREADS) {
        for my $t (threads->list()) {
            $t->join;
            # In older threads we cannot check if a thread had an error unless
            # we control it and its return.
            my $err = $t->can('error') ? $t->error : undef;
            next unless $err;
            my $tid = $t->tid();
            $fail++;
            chomp($err);
            warn "Thread $tid did not end cleanly: $err\n";
        }
    }

    return 0 unless $fail;
    return 255;
}

sub DESTROY {
    my $self = shift;

    return unless defined($self->{+_PID}) && $self->{+_PID} == $$;
    return unless defined($self->{+_TID}) && $self->{+_TID} == get_tid();

    shmctl($self->{+IPC_SHM_ID}, IPC::SysV::IPC_RMID(), 0)
        if defined $self->{+IPC_SHM_ID};
}

sub set_exit {
    my $self = shift;

    my $exit     = $?;
    my $new_exit = $exit;

    if ($INC{'Test/Builder.pm'} && $Test::Builder::VERSION ne $Test2::API::VERSION) {
        print STDERR <<"        EOT";

********************************************************************************
*                                                                              *
*            Test::Builder -- Test2::API version mismatch detected             *
*                                                                              *
********************************************************************************
   Test2::API Version: $Test2::API::VERSION
Test::Builder Version: $Test::Builder::VERSION

This is not a supported configuration, you will have problems.

        EOT
    }

    for my $ctx (values %{$self->{+CONTEXTS}}) {
        next unless $ctx;

        next if $ctx->_aborted && ${$ctx->_aborted};

        # Only worry about contexts in this PID
        my $trace = $ctx->trace || next;
        next unless $trace->pid && $trace->pid == $$;

        # Do not worry about contexts that have no hub
        my $hub = $ctx->hub  || next;

        # Do not worry if the state came to a sudden end.
        next if $hub->bailed_out;
        next if defined $hub->skip_reason;

        # now we worry
        $trace->alert("context object was never released! This means a testing tool is behaving very badly");

        $exit     = 255;
        $new_exit = 255;
    }

    if (!defined($self->{+_PID}) or !defined($self->{+_TID}) or $self->{+_PID} != $$ or $self->{+_TID} != get_tid()) {
        $? = $exit;
        return;
    }

    my @hubs = $self->{+STACK} ? $self->{+STACK}->all : ();

    if (@hubs and $self->{+IPC} and !$self->{+NO_WAIT}) {
        local $?;
        my %seen;
        for my $hub (reverse @hubs) {
            my $ipc = $hub->ipc or next;
            next if $seen{$ipc}++;
            $ipc->waiting();
        }

        my $ipc_exit = _ipc_wait();
        $new_exit ||= $ipc_exit;
    }

    # None of this is necessary if we never got a root hub
    if(my $root = shift @hubs) {
        my $trace = Test2::Util::Trace->new(
            frame  => [__PACKAGE__, __FILE__, 0, __PACKAGE__ . '::END'],
            detail => __PACKAGE__ . ' END Block finalization',
        );
        my $ctx = Test2::API::Context->new(
            trace => $trace,
            hub   => $root,
        );

        if (@hubs) {
            $ctx->diag("Test ended with extra hubs on the stack!");
            $new_exit  = 255;
        }

        unless ($root->no_ending) {
            local $?;
            $root->finalize($trace) unless $root->ended;
            $_->($ctx, $exit, \$new_exit) for @{$self->{+EXIT_CALLBACKS}};
            $new_exit ||= $root->failed;
            $new_exit ||= 255 unless $root->is_passing;
        }
    }

    $new_exit = 255 if $new_exit > 255;

    if ($new_exit && eval { require Test2::API::Breakage; 1 }) {
        my @warn = Test2::API::Breakage->report();

        if (@warn) {
            print STDERR "\nYou have loaded versions of test modules known to have problems with Test2.\nThis could explain some test failures.\n";
            print STDERR "$_\n" for @warn;
            print STDERR "\n";
        }
    }

    $? = $new_exit;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::API::Instance - Object used by Test2::API under the hood

=head1 DESCRIPTION

This object encapsulates the global shared state tracked by
L<Test2>. A single global instance of this package is stored (and
obscured) by the L<Test2::API> package.

There is no reason to directly use this package. This package is documented for
completeness. This package can change, or go away completely at any time.
Directly using, or monkeypatching this package is not supported in any way
shape or form.

=head1 SYNOPSIS

    use Test2::API::Instance;

    my $obj = Test2::API::Instance->new;

=over 4

=item $pid = $obj->pid

PID of this instance.

=item $obj->tid

Thread ID of this instance.

=item $obj->reset()

Reset the object to defaults.

=item $obj->load()

Set the internal state to loaded, and run and stored post-load callbacks.

=item $bool = $obj->loaded

Check if the state is set to loaded.

=item $arrayref = $obj->post_load_callbacks

Get the post-load callbacks.

=item $obj->add_post_load_callback(sub { ... })

Add a post-load callback. If C<load()> has already been called then the callback will
be immediately executed. If C<load()> has not been called then the callback will be
stored and executed later when C<load()> is called.

=item $hashref = $obj->contexts()

Get a hashref of all active contexts keyed by hub id.

=item $arrayref = $obj->context_acquire_callbacks

Get all context acquire callbacks.

=item $arrayref = $obj->context_init_callbacks

Get all context init callbacks.

=item $arrayref = $obj->context_release_callbacks

Get all context release callbacks.

=item $obj->add_context_init_callback(sub { ... })

Add a context init callback. Subs are called every time a context is created. Subs
get the newly created context as their only argument.

=item $obj->add_context_release_callback(sub { ... })

Add a context release callback. Subs are called every time a context is released. Subs
get the released context as their only argument. These callbacks should not
call release on the context.

=item $obj->set_exit()

This is intended to be called in an C<END { ... }> block. This will look at
test state and set $?. This will also call any end callbacks, and wait on child
processes/threads.

=item $obj->ipc_enable_shm()

Turn on SHM for IPC (if possible)

=item $shm_id = $obj->ipc_shm_id()

If SHM is enabled for IPC this will be the shm_id for it.

=item $shm_size = $obj->ipc_shm_size()

If SHM is enabled for IPC this will be the size of it.

=item $shm_last_val = $obj->ipc_shm_last()

If SHM is enabled for IPC this will return the last SHM value seen.

=item $obj->set_ipc_pending($val)

use the IPC SHM to tell other processes and threads there is a pending event.
C<$val> should be a unique value no other thread/process will generate.

B<Note:> This will also make the current process see a pending event. It does
not set C<ipc_shm_last()>, this is important because doing so could hide a
previous change.

=item $pending = $obj->get_ipc_pending()

This returns -1 if SHM is not enabled for IPC.

This returns 0 if the SHM value matches the last known value, which means there
are no pending events.

This returns 1 if the SHM value has changed, which means there are probably
pending events.

When 1 is returned this will set C<< $obj->ipc_shm_last() >>.

=item $drivers = $obj->ipc_drivers

Get the list of IPC drivers.

=item $obj->add_ipc_driver($DRIVER_CLASS)

Add an IPC driver to the list. The most recently added IPC driver will become
the global one during initialization. If a driver is added after initialization
has occurred a warning will be generated:

    "IPC driver $driver loaded too late to be used as the global ipc driver"

=item $bool = $obj->ipc_polling

Check if polling is enabled.

=item $obj->enable_ipc_polling

Turn on polling. This will cull events from other processes and threads every
time a context is created.

=item $obj->disable_ipc_polling

Turn off IPC polling.

=item $bool = $obj->no_wait

=item $bool = $obj->set_no_wait($bool)

Get/Set no_wait. This option is used to turn off process/thread waiting at exit.

=item $arrayref = $obj->exit_callbacks

Get the exit callbacks.

=item $obj->add_exit_callback(sub { ... })

Add an exit callback. This callback will be called by C<set_exit()>.

=item $bool = $obj->finalized

Check if the object is finalized. Finalization happens when either C<ipc()>,
C<stack()>, or C<format()> are called on the object. Once finalization happens
these fields are considered unchangeable (not enforced here, enforced by
L<Test2>).

=item $ipc = $obj->ipc

Get the one true IPC instance.

=item $stack = $obj->stack

Get the one true hub stack.

=item $formatter = $obj->formatter

Get the global formatter. By default this is the C<'Test2::Formatter::TAP'>
package. This could be any package that implements the C<write()> method. This
can also be an instantiated object.

=item $bool = $obj->formatter_set()

Check if a formatter has been set.

=item $obj->add_formatter($class)

=item $obj->add_formatter($obj)

Add a formatter. The most recently added formatter will become the global one
during initialization. If a formatter is added after initialization has occurred
a warning will be generated:

    "Formatter $formatter loaded too late to be used as the global formatter"

=back

=head1 SOURCE

The source code repository for Test2 can be found at
F<http://github.com/Test-More/test-more/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2016 Chad Granum E<lt>exodist@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
