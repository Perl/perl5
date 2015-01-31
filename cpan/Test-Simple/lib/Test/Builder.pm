package Test::Builder;

use 5.008001;
use strict;
use warnings;

our $VERSION = '1.301001_098';
$VERSION = eval $VERSION;    ## no critic (BuiltinFunctions::ProhibitStringyEval)


use Test::Stream 1.301001 qw/ -internal STATE_LEGACY STATE_PLAN STATE_COUNT /;
use Test::Stream::Toolset;
use Test::Stream::Context;
use Test::Stream::Carp qw/confess/;
use Test::Stream::Meta qw/MODERN/;

use Test::Stream::Util qw/try protect unoverload_str is_regex/;
use Scalar::Util qw/blessed reftype/;

use Test::More::Tools;

BEGIN {
    my $meta = Test::Stream::Meta->is_tester('main');
    Test::Stream->shared->set_use_legacy(1)
        unless $meta && $meta->[MODERN];
}

# The mostly-singleton, and other package vars.
our $Test  = Test::Builder->new;
our $_ORIG_Test = $Test;
our $Level = 1;

sub ctx {
    my $self = shift || die "No self in context";
    my ($add) = @_;
    my $ctx = Test::Stream::Context::context(2 + ($add || 0), $self->{stream});
    if (defined $self->{Todo}) {
        $ctx->set_in_todo(1);
        $ctx->set_todo($self->{Todo});
        $ctx->set_diag_todo(1);
    }
    return $ctx;
}

sub stream {
    my $self = shift;
    return $self->{stream} || Test::Stream->shared;
}

sub depth { $_[0]->{depth} || 0 }

# This is only for unit tests at this point.
sub _ending {
    my $self = shift;
    my ($ctx) = @_;
    require Test::Stream::ExitMagic;
    $self->{stream}->set_no_ending(0);
    Test::Stream::ExitMagic->new->do_magic($self->{stream}, $ctx);
}

my %WARNED;
our $CTX;
our %ORIG = (
    ok   => \&ok,
    diag => \&diag,
    note => \&note,
    plan => \&plan,
    done_testing => \&done_testing,
);

sub WARN_OF_OVERRIDE {
    my ($sub, $ctx) = @_;

    return unless $ctx->modern;
    my $old = $ORIG{$sub};
    # Use package instead of self, we want replaced subs, not subclass overrides.
    my $new = __PACKAGE__->can($sub);

    return if $new == $old;

    require B;
    my $o    = B::svref_2object($new);
    my $gv   = $o->GV;
    my $st   = $o->START;
    my $name = $gv->NAME;
    my $pkg  = $gv->STASH->NAME;
    my $line = $st->line;
    my $file = $st->file;

    warn <<"    EOT" unless $WARNED{"$pkg $name $file $line"}++;

*******************************************************************************
Something monkeypatched Test::Builder::$sub()!
The new sub is '$pkg\::$name' defined in $file around line $line.
In the near future monkeypatching Test::Builder::ok() will no longer work
as expected.
*******************************************************************************
    EOT
}


####################
# {{{ Constructors #
####################

sub new {
    my $class  = shift;
    my %params = @_;
    $Test ||= $class->create(shared_stream => 1);

    return $Test;
}

sub create {
    my $class  = shift;
    my %params = @_;

    my $self = bless {}, $class;
    $self->reset(%params);

    return $self;
}

# Copy an object, currently a shallow.
# This does *not* bless the destination.  This keeps the destructor from
# firing when we're just storing a copy of the object to restore later.
sub _copy {
    my ($src, $dest) = @_;
    %$dest = %$src;
    return;
}

####################
# }}} Constructors #
####################

#############################
# {{{ Children and subtests #
#############################

sub subtest {
    my $self = shift;
    my $ctx = $self->ctx();
    require Test::Stream::Subtest;
    return Test::Stream::Subtest::subtest(@_);
}

sub child {
    my( $self, $name ) = @_;

    my $ctx = $self->ctx;

    if ($self->{child}) {
        my $cname = $self->{child}->{Name};
        $ctx->throw("You already have a child named ($cname) running");
    }

    $name ||= "Child of " . $self->{Name};
    my $stream = $self->{stream} || Test::Stream->shared;
    $ctx->subtest_start($name, parent_todo => $ctx->in_todo);

    my $child = bless {
        %$self,
        '?' => $?,
        parent => $self,
    };

    $? = 0;
    $child->{Name} = $name;
    $self->{child} = $child;
    Scalar::Util::weaken($self->{child});

    return $child;
}

sub finalize {
    my $self = shift;

    return unless $self->{parent};

    my $ctx = $self->ctx;

    if ($self->{child}) {
        my $cname = $self->{child}->{Name};
        $ctx->throw("Can't call finalize() with child ($cname) active");
    }

    $self->_ending($ctx);
    my $passing = $ctx->stream->is_passing;
    my $count = $ctx->stream->count;
    my $name = $self->{Name};

    my $stream = $self->{stream} || Test::Stream->shared;

    my $parent = $self->parent;
    $self->{parent}->{child} = undef;
    $self->{parent} = undef;

    $? = $self->{'?'};

    my $st = $ctx->subtest_stop($name);

    $parent->ctx->subtest(
        # Stuff from ok (most of this gets initialized inside)
        undef, # real_bool, gets set properly by initializer
        $st->{name}, # name
        undef, # diag
        undef, # bool
        undef, # level

        # Subtest specific stuff
        $st->{state},
        $st->{events},
        $st->{exception},
        $st->{early_return},
        $st->{delayed},
        $st->{instant},
    );
}

sub in_subtest {
    my $self = shift;
    my $ctx = $self->ctx;
    return scalar @{$ctx->stream->subtests};
}

sub parent { $_[0]->{parent} }
sub name   { $_[0]->{Name} }

sub DESTROY {
    my $self = shift;
    return unless $self->{parent};
    return if $self->{Skip_All};
    $self->{parent}->is_passing(0);
    my $name = $self->{Name};
    die "Child ($name) exited without calling finalize()";
}

#############################
# }}} Children and subtests #
#############################

#####################################
# {{{ stuff for TODO status #
#####################################

sub find_TODO {
    my ($self, $pack, $set, $new_value) = @_;

    unless ($pack) {
        if (my $ctx = Test::Stream::Context->peek) {
            $pack = $ctx->package;
            my $old = $ctx->todo;
            $ctx->set_todo($new_value) if $set;
            return $old;
        }

        $pack = $self->exported_to || return;
    }

    no strict 'refs';    ## no critic
    no warnings 'once';
    my $old_value = ${$pack . '::TODO'};
    $set and ${$pack . '::TODO'} = $new_value;
    return $old_value;
}

sub todo {
    my ($self, $pack) = @_;

    return $self->{Todo} if defined $self->{Todo};

    my $ctx = $self->ctx;

    my $todo = $self->find_TODO($pack);
    return $todo if defined $todo;

    return '';
}

sub in_todo {
    my $self = shift;

    my $ctx = $self->ctx;
    return 1 if $ctx->in_todo;

    return (defined $self->{Todo} || $self->find_TODO) ? 1 : 0;
}

sub todo_start {
    my $self = shift;
    my $message = @_ ? shift : '';

    $self->{Start_Todo}++;
    if ($self->in_todo) {
        push @{$self->{Todo_Stack}} => $self->todo;
    }
    $self->{Todo} = $message;

    return;
}

sub todo_end {
    my $self = shift;

    if (!$self->{Start_Todo}) {
        $self->ctx(-1)->throw('todo_end() called without todo_start()');
    }

    $self->{Start_Todo}--;

    if ($self->{Start_Todo} && @{$self->{Todo_Stack}}) {
        $self->{Todo} = pop @{$self->{Todo_Stack}};
    }
    else {
        delete $self->{Todo};
    }

    return;
}

#####################################
# }}} Finding Testers and Providers #
#####################################

################
# {{{ Planning #
################

my %PLAN_CMDS = (
    no_plan  => 'no_plan',
    skip_all => 'skip_all',
    tests    => '_plan_tests',
);

sub plan {
    my ($self, $cmd, @args) = @_;

    my $ctx = $CTX || Test::Stream::Context->peek || $self->ctx();
    WARN_OF_OVERRIDE(plan => $ctx);

    return unless $cmd;

    if (my $method = $PLAN_CMDS{$cmd}) {
        $self->$method(@args);
    }
    else {
        my @in = grep { defined } ($cmd, @args);
        $self->ctx->throw("plan() doesn't understand @in");
    }

    return 1;
}

sub skip_all {
    my ($self, $reason) = @_;

    $self->{Skip_All} = 1;

    my $ctx = $CTX || Test::Stream::Context->peek || $self->ctx();

    $ctx->_plan(0, 'SKIP', $reason);
}

sub no_plan {
    my ($self, @args) = @_;

    my $ctx = $CTX || Test::Stream::Context->peek || $self->ctx();

    $ctx->alert("no_plan takes no arguments") if @args;
    $ctx->_plan(0, 'NO PLAN');

    return 1;
}

sub _plan_tests {
    my ($self, $arg) = @_;

    my $ctx = $CTX || Test::Stream::Context->peek || $self->ctx();

    if ($arg) {
        $ctx->throw("Number of tests must be a positive integer.  You gave it '$arg'")
            unless $arg =~ /^\+?\d+$/;

        $ctx->_plan($arg);
    }
    elsif (!defined $arg) {
        $ctx->throw("Got an undefined number of tests");
    }
    else {
        $ctx->throw("You said to run 0 tests");
    }

    return;
}

sub done_testing {
    my ($self, $num_tests) = @_;

    my $ctx = $CTX || Test::Stream::Context->peek || $self->ctx();
    WARN_OF_OVERRIDE(done_testing => $ctx);

    my $out = $ctx->stream->done_testing($ctx, $num_tests);
    return $out;
}

################
# }}} Planning #
################

#############################
# {{{ Base Event Producers #
#############################

sub ok {
    my $self = shift;
    my($test, $name) = @_;

    my $ctx = $CTX || Test::Stream::Context->peek || $self->ctx();
    WARN_OF_OVERRIDE(ok => $ctx);

    if ($self->{child}) {
        $self->is_passing(0);
        $ctx->throw("Cannot run test ($name) with active children");
    }

    $ctx->_unwind_ok($test, $name);
    return $test ? 1 : 0;
}

sub BAIL_OUT {
    my( $self, $reason ) = @_;
    $self->ctx()->bail($reason);
}

sub skip {
    my( $self, $why ) = @_;
    $why ||= '';
    unoverload_str( \$why );

    my $ctx = $self->ctx();
    $ctx->set_skip($why);
    $ctx->ok(1, '');
    $ctx->set_skip(undef);
}

sub todo_skip {
    my( $self, $why ) = @_;
    $why ||= '';
    unoverload_str( \$why );

    my $ctx = $self->ctx();
    $ctx->set_skip($why);
    $ctx->set_todo($why);
    $ctx->ok(0, '');
    $ctx->set_skip(undef);
    $ctx->set_todo(undef);
}

sub diag {
    my $self = shift;
    my $msg = join '', map { defined($_) ? $_ : 'undef' } @_;

    my $ctx = $CTX || Test::Stream::Context->peek || $self->ctx();
    WARN_OF_OVERRIDE(diag => $ctx);

    $ctx->_diag($msg);
    return;
}

sub note {
    my $self = shift;
    my $msg = join '', map { defined($_) ? $_ : 'undef' } @_;

    my $ctx = $CTX || Test::Stream::Context->peek || $self->ctx();
    WARN_OF_OVERRIDE(note => $ctx);

    $ctx->_note($msg);
}

#############################
# }}} Base Event Producers #
#############################

#######################
# {{{ Public helpers #
#######################

sub explain {
    my $self = shift;

    return map {
        ref $_
          ? do {
            protect { require Data::Dumper };
            my $dumper = Data::Dumper->new( [$_] );
            $dumper->Indent(1)->Terse(1);
            $dumper->Sortkeys(1) if $dumper->can("Sortkeys");
            $dumper->Dump;
          }
          : $_
    } @_;
}

sub carp {
    my $self = shift;
    $self->ctx->alert(join '' => @_);
}

sub croak {
    my $self = shift;
    $self->ctx->throw(join '' => @_);
}

sub has_plan {
    my $self = shift;

    my $plan = $self->ctx->stream->plan || return undef;
    return 'no_plan' if $plan->directive && $plan->directive eq 'NO PLAN';
    return $plan->max;
}

sub reset {
    my $self = shift;
    my %params = @_;

    $self->{use_shared} = 1 if $params{shared_stream};

    if ($self->{use_shared}) {
        Test::Stream->shared->_reset;
        Test::Stream->shared->state->[-1]->[STATE_LEGACY] = [];
    }
    else {
        $self->{stream} = Test::Stream->new();
        $self->{stream}->set_use_legacy(1);
        $self->{stream}->state->[-1]->[STATE_LEGACY] = [];
    }

    # We leave this a global because it has to be localized and localizing
    # hash keys is just asking for pain.  Also, it was documented.
    $Level = 1;

    $self->{Name} = $0;

    $self->{Original_Pid} = $$;
    $self->{Child_Name}   = undef;

    $self->{Exported_To} = undef;

    $self->{Todo}               = undef;
    $self->{Todo_Stack}         = [];
    $self->{Start_Todo}         = 0;
    $self->{Opened_Testhandles} = 0;

    return;
}

#######################
# }}} Public helpers #
#######################

#################################
# {{{ Advanced Event Producers #
#################################

sub cmp_ok {
    my( $self, $got, $type, $expect, $name ) = @_;
    my $ctx = $self->ctx;
    my ($ok, @diag) = tmt->cmp_check($got, $type, $expect);
    $ctx->ok($ok, $name, \@diag);
    return $ok;
}

sub is_eq {
    my( $self, $got, $expect, $name ) = @_;
    my $ctx = $self->ctx;
    my ($ok, @diag) = tmt->is_eq($got, $expect);
    $ctx->ok($ok, $name, \@diag);
    return $ok;
}

sub is_num {
    my( $self, $got, $expect, $name ) = @_;
    my $ctx = $self->ctx;
    my ($ok, @diag) = tmt->is_num($got, $expect);
    $ctx->ok($ok, $name, \@diag);
    return $ok;
}

sub isnt_eq {
    my( $self, $got, $dont_expect, $name ) = @_;
    my $ctx = $self->ctx;
    my ($ok, @diag) = tmt->isnt_eq($got, $dont_expect);
    $ctx->ok($ok, $name, \@diag);
    return $ok;
}

sub isnt_num {
    my( $self, $got, $dont_expect, $name ) = @_;
    my $ctx = $self->ctx;
    my ($ok, @diag) = tmt->isnt_num($got, $dont_expect);
    $ctx->ok($ok, $name, \@diag);
    return $ok;
}

sub like {
    my( $self, $thing, $regex, $name ) = @_;
    my $ctx = $self->ctx;
    my ($ok, @diag) = tmt->regex_check($thing, $regex, '=~');
    $ctx->ok($ok, $name, \@diag);
    return $ok;
}

sub unlike {
    my( $self, $thing, $regex, $name ) = @_;
    my $ctx = $self->ctx;
    my ($ok, @diag) = tmt->regex_check($thing, $regex, '!~');
    $ctx->ok($ok, $name, \@diag);
    return $ok;
}

#################################
# }}} Advanced Event Producers #
#################################

################################################
# {{{ Misc #
################################################

sub _new_fh {
    my $self = shift;
    my($file_or_fh) = shift;

    return $file_or_fh if $self->is_fh($file_or_fh);

    my $fh;
    if( ref $file_or_fh eq 'SCALAR' ) {
        open $fh, ">>", $file_or_fh
          or croak("Can't open scalar ref $file_or_fh: $!");
    }
    else {
        open $fh, ">", $file_or_fh
          or croak("Can't open test output log $file_or_fh: $!");
        Test::Stream::IOSets->_autoflush($fh);
    }

    return $fh;
}

sub output {
    my $self = shift;
    my $handles = $self->ctx->stream->io_sets->init_encoding('legacy');
    $handles->[0] = $self->_new_fh(@_) if @_;
    return $handles->[0];
}

sub failure_output {
    my $self = shift;
    my $handles = $self->ctx->stream->io_sets->init_encoding('legacy');
    $handles->[1] = $self->_new_fh(@_) if @_;
    return $handles->[1];
}

sub todo_output {
    my $self = shift;
    my $handles = $self->ctx->stream->io_sets->init_encoding('legacy');
    $handles->[2] = $self->_new_fh(@_) if @_;
    return $handles->[2] || $handles->[0];
}

sub reset_outputs {
    my $self = shift;
    my $ctx = $self->ctx;
    $ctx->stream->io_sets->reset_legacy;
}

sub use_numbers {
    my $self = shift;
    my $ctx = $self->ctx;
    $ctx->stream->set_use_numbers(@_) if @_;
    $ctx->stream->use_numbers;
}

sub no_ending {
    my $self = shift;
    my $ctx = $self->ctx;
    $ctx->stream->set_no_ending(@_) if @_;
    $ctx->stream->no_ending || 0;
}

sub no_header {
    my $self = shift;
    my $ctx = $self->ctx;
    $ctx->stream->set_no_header(@_) if @_;
    $ctx->stream->no_header || 0;
}

sub no_diag {
    my $self = shift;
    my $ctx = $self->ctx;
    $ctx->stream->set_no_diag(@_) if @_;
    $ctx->stream->no_diag || 0;
}

sub exported_to {
    my($self, $pack) = @_;
    $self->{Exported_To} = $pack if defined $pack;
    return $self->{Exported_To};
}

sub is_fh {
    my $self     = shift;
    my $maybe_fh = shift;
    return 0 unless defined $maybe_fh;

    return 1 if ref $maybe_fh  eq 'GLOB';    # its a glob ref
    return 1 if ref \$maybe_fh eq 'GLOB';    # its a glob

    my $out;
    protect {
        $out = eval { $maybe_fh->isa("IO::Handle") }
            || eval { tied($maybe_fh)->can('TIEHANDLE') };
    };

    return $out;
}

sub BAILOUT { goto &BAIL_OUT }

sub expected_tests {
    my $self = shift;

    my $ctx = $self->ctx;
    $ctx->plan(@_) if @_;

    my $plan = $ctx->stream->state->[-1]->[STATE_PLAN] || return 0;
    return $plan->max || 0;
}

sub caller {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    my $self = shift;

    my $ctx = $self->ctx;

    return wantarray ? $ctx->call : $ctx->package;
}

sub level {
    my( $self, $level ) = @_;
    $Level = $level if defined $level;
    return $Level;
}

sub maybe_regex {
    my ($self, $regex) = @_;
    return is_regex($regex);
}

sub is_passing {
    my $self = shift;
    my $ctx = $self->ctx;
    $ctx->stream->is_passing(@_);
}

# Yeah, this is not efficient, but it is only legacy support, barely anything
# uses it, and they really should not.
sub current_test {
    my $self = shift;

    my $ctx = $self->ctx;

    if (@_) {
        my ($num) = @_;
        my $state = $ctx->stream->state->[-1];
        $state->[STATE_COUNT] = $num;

        my $old = $state->[STATE_LEGACY] || [];
        my $new = [];

        my $nctx = $ctx->snapshot;
        $nctx->set_todo('incrementing test number');
        $nctx->set_in_todo(1);

        for (1 .. $num) {
            my $i;
            $i = shift @$old while @$old && (!$i || !$i->isa('Test::Stream::Event::Ok'));
            $i ||= Test::Stream::Event::Ok->new(
                $nctx,
                [CORE::caller()],
                0,
                undef,
                undef,
                undef,
                1,
            );

            push @$new => $i;
        }

        $state->[STATE_LEGACY] = $new;
    }

    $ctx->stream->count;
}

sub details {
    my $self = shift;
    my $ctx = $self->ctx;
    my $state = $ctx->stream->state->[-1];
    my @out;
    return @out unless $state->[STATE_LEGACY];

    for my $e (@{$state->[STATE_LEGACY]}) {
        next unless $e && $e->isa('Test::Stream::Event::Ok');
        push @out => $e->to_legacy;
    }

    return @out;
}

sub summary {
    my $self = shift;
    my $ctx = $self->ctx;
    my $state = $ctx->stream->state->[-1];
    return @{[]} unless $state->[STATE_LEGACY];
    return map { $_->isa('Test::Stream::Event::Ok') ? ($_->bool ? 1 : 0) : ()} @{$state->[STATE_LEGACY]};
}

###################################
# }}} Misc #
###################################

####################
# {{{ TB1.5 stuff  #
####################

# This is just a list of method Test::Builder current does not have that Test::Builder 1.5 does.
my %TB15_METHODS = map { $_ => 1 } qw{
    _file_and_line _join_message _make_default _my_exit _reset_todo_state
    _result_to_hash _results _todo_state formatter history in_test
    no_change_exit_code post_event post_result set_formatter set_plan test_end
    test_exit_code test_start test_state
};

our $AUTOLOAD;

sub AUTOLOAD {
    $AUTOLOAD =~ m/^(.*)::([^:]+)$/;
    my ($package, $sub) = ($1, $2);

    my @caller = CORE::caller();
    my $msg    = qq{Can't locate object method "$sub" via package "$package" at $caller[1] line $caller[2].\n};

    $msg .= <<"    EOT" if $TB15_METHODS{$sub};

    *************************************************************************
    '$sub' is a Test::Builder 1.5 method. Test::Builder 1.5 is a dead branch.
    You need to update your code so that it no longer treats Test::Builders
    over a specific version number as anything special.

    See: http://blogs.perl.org/users/chad_exodist_granum/2014/03/testmore---new-maintainer-also-stop-version-checking.html
    *************************************************************************
    EOT

    die $msg;
}

####################
# }}} TB1.5 stuff  #
####################

##################################
# {{{ Legacy support, do not use #
##################################

# These are here to support old versions of Test::More which may be bundled
# with some dists. See https://github.com/Test-More/test-more/issues/479

sub _try {
    my( $self, $code, %opts ) = @_;

    my $error;
    my $return;
    protect {
        $return = eval { $code->() };
        $error = $@;
    };

    die $error if $error and $opts{die_on_fail};

    return wantarray ? ( $return, $error ) : $return;
}

sub _unoverload {
    my $self = shift;
    my $type = shift;

    $self->_try(sub { require overload; }, die_on_fail => 1);

    foreach my $thing (@_) {
        if( $self->_is_object($$thing) ) {
            if( my $string_meth = overload::Method( $$thing, $type ) ) {
                $$thing = $$thing->$string_meth();
            }
        }
    }

    return;
}

sub _is_object {
    my( $self, $thing ) = @_;

    return $self->_try( sub { ref $thing && $thing->isa('UNIVERSAL') } ) ? 1 : 0;
}

sub _unoverload_str {
    my $self = shift;

    return $self->_unoverload( q[""], @_ );
}

sub _unoverload_num {
    my $self = shift;

    $self->_unoverload( '0+', @_ );

    for my $val (@_) {
        next unless $self->_is_dualvar($$val);
        $$val = $$val + 0;
    }

    return;
}

# This is a hack to detect a dualvar such as $!
sub _is_dualvar {
    my( $self, $val ) = @_;

    # Objects are not dualvars.
    return 0 if ref $val;

    no warnings 'numeric';
    my $numval = $val + 0;
    return ($numval != 0 and $numval ne $val ? 1 : 0);
}

##################################
# }}} Legacy support, do not use #
##################################

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Builder - *DEPRECATED* Module for building testing libraries.

=head1 DESCRIPTION

This module was previously the base module for almost any testing library. This
module is now little more than a compatability wrapper around L<Test::Stream>.
If you are looking to write or update a testing library you should look at
L<Test::Stream::Toolset>.

=head1 PACKAGE VARS

=over 4

=item $Test::Builder::Test

The variable that holds the Test::Builder singleton.

=item $Test::Builder::Level

In the past this variable was used to track stack depth so that Test::Builder
could report the correct line number. If you use Test::Builder this will still
work, but in new code it is better to use the L<Test::Stream::Context> module.

=back

=head1 METHODS

=head2 CONSTRUCTORS

=over 4

=item Test::Builder->new

Returns the singleton stored in C<$Test::Builder::Test>.

=item Test::Builder->create

=item Test::Builder->create(use_shared => 1)

Returns a new instance of Test::Builder. It is important to note that this
instance will not use the shared L<Test::Stream> object unless you pass in the
C<< use_shared => 1 >> argument.

=back

=head2 UTIL

=over 4

=item $TB->ctx

Helper method for Test::Builder to get a L<Test::Stream::Context> object.

=item $TB->depth

Get the subtest depth

=item $TB->find_TODO

=item $TB->in_todo

=item $TB->todo

These all check on todo state and value

=back

=head2 OTHER

=over 4

=item $TB->caller

=item $TB->carp

=item $TB->croak

These let you figure out when/where the test is defined in the test file.

=item $TB->child

Start a subtest (Please do not use this)

=item $TB->finalize

Finish a subtest (Please do not use this)

=item $TB->explain

Interface to Data::Dumper that dumps whatever you give it.

=item $TB->exported_to

This used to tell you what package used Test::Builder, it never worked well.
The previous bad and unpredictable behavior of this has largely been preserved,
however nothing internal uses it in any meaningful way anymore.

=item $TB->is_fh

Check if something is a filehandle

=item $TB->level

Get/Set C<$Test::Builder::Level>. $Level is a package var, and most things
localize it, so this method is pretty useless.

=item $TB->maybe_regex

Check if something might be a regex.

=item $TB->reset

Reset the builder object to a very basic and default state. You almost
certainly do not need this unless you are writing a tool to test testing
libraries. Even then you probably do not want this.

=item $TB->todo_end

=item $TB->todo_start

Start/end TODO state, there are better ways to do this now.

=back

=head2 STREAM INTERFACE

These simply interface into functionality of L<Test::Stream>.

=over 4

=item $TB->failure_output

=item $TB->output

=item $TB->reset_outputs

=item $TB->todo_output

These get/set the IO handle used in the 'legacy' tap encoding.

=item $TB->no_diag

Do not display L<Test::Stream::Event::Diag> events.

=item $TB->no_ending

Do not do some special magic at the end that tells you what went wrong with
tests.

=item $TB->no_header

Do not display the plan

=item $TB->use_numbers

Turn numbers in TAP on and off.

=back

=head2 HISTORY

=over

=item $TB->details

Get all the events that occured on this object. Each event will be transformed
into a hash that matches the legacy output of this method.

=item $TB->expected_tests

Set/Get expected number of tests

=item $TB->has_plan

Check if there is a plan

=item $TB->summary

List of pass/fail results.

=back

=head2 EVENT GENERATORS

See L<Test::Stream::Context>, L<Test::Stream::Toolset>, and
L<Test::More::Tools>. Calling the methods below is not advised.

=over 4

=item $TB->BAILOUT

=item $TB->BAIL_OUT

=item $TB->cmp_ok

=item $TB->current_test

=item $TB->diag

=item $TB->done_testing

=item $TB->is_eq

=item $TB->is_num

=item $TB->is_passing

=item $TB->isnt_eq

=item $TB->isnt_num

=item $TB->like

=item $TB->no_plan

=item $TB->note

=item $TB->ok

=item $TB->plan

=item $TB->skip

=item $TB->skip_all

=item $TB->subtest

=item $TB->todo_skip

=item $TB->unlike

=back

=head2 ACCESSORS

=over 4

=item $TB->stream

Get the stream used by this builder (or the shared stream).

=item $TB->name

Name of the test

=item $TB->parent

Parent if this is a child.

=back

=head1 MONKEYPATCHING

Many legacy testing modules monkeypatch C<ok()>, C<plan()>, and others. The
abillity to monkeypatch these to effect all events of the specified type is now
considered discouraged. For backwords compatability monkeypatching continues to
work, however in the distant future it will be removed. L<Test::Stream> upon
which Test::Builder is now built, provides hooks and API's for doing everything
that previously required monkeypatching.

=head1 TUTORIALS

=over 4

=item L<Test::Tutorial>

The original L<Test::Tutorial>. Uses comedy to introduce you to testing from
scratch.

=item L<Test::Tutorial::WritingTests>

The L<Test::Tutorial::WritingTests> tutorial takes a more technical approach.
The idea behind this tutorial is to give you a technical introduction to
testing that can easily be used as a reference. This is for people who say
"Just tell me how to do it, and quickly!".

=item L<Test::Tutorial::WritingTools>

The L<Test::Tutorial::WritingTools> tutorial is an introduction to writing
testing tools that play nicely with other L<Test::Stream> and L<Test::Builder>
based tools. This is what you should look at if you want to write
Test::MyWidget.

=back

=head1 SOURCE

The source code repository for Test::More can be found at
F<http://github.com/Test-More/test-more/>.

=head1 MAINTAINER

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

The following people have all contributed to the Test-More dist (sorted using
VIM's sort function).

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=item Fergal Daly E<lt>fergal@esatclear.ie>E<gt>

=item Mark Fowler E<lt>mark@twoshortplanks.comE<gt>

=item Michael G Schwern E<lt>schwern@pobox.comE<gt>

=item 唐鳳

=back

=head1 COPYRIGHT

There has been a lot of code migration between modules,
here are all the original copyrights together:

=over 4

=item Test::Stream

=item Test::Stream::Tester

Copyright 2014 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=item Test::Simple

=item Test::More

=item Test::Builder

Originally authored by Michael G Schwern E<lt>schwern@pobox.comE<gt> with much
inspiration from Joshua Pritikin's Test module and lots of help from Barrie
Slaymaker, Tony Bowden, blackstar.co.uk, chromatic, Fergal Daly and the perl-qa
gang.

Idea by Tony Bowden and Paul Johnson, code by Michael G Schwern
E<lt>schwern@pobox.comE<gt>, wardrobe by Calvin Klein.

Copyright 2001-2008 by Michael G Schwern E<lt>schwern@pobox.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=item Test::use::ok

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to L<Test-use-ok>.

This work is published from Taiwan.

L<http://creativecommons.org/publicdomain/zero/1.0>

=item Test::Tester

This module is copyright 2005 Fergal Daly <fergal@esatclear.ie>, some parts
are based on other people's work.

Under the same license as Perl itself

See http://www.perl.com/perl/misc/Artistic.html

=item Test::Builder::Tester

Copyright Mark Fowler E<lt>mark@twoshortplanks.comE<gt> 2002, 2004.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=back
