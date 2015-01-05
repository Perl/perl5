package Test::Stream;
use strict;
use warnings;

our $VERSION = '1.301001_097';
$VERSION = eval $VERSION;    ## no critic (BuiltinFunctions::ProhibitStringyEval)

use Test::Stream::Context qw/context/;
use Test::Stream::Threads;
use Test::Stream::IOSets;
use Test::Stream::Util qw/try/;
use Test::Stream::Carp qw/croak confess carp/;
use Test::Stream::Meta qw/MODERN ENCODING init_tester/;

use Test::Stream::ArrayBase(
    accessors => [qw{
        no_ending no_diag no_header
        pid tid
        state
        subtests
        subtest_tap_instant
        subtest_tap_delayed
        mungers
        listeners
        follow_ups
        bailed_out
        exit_on_disruption
        use_tap use_legacy _use_fork
        use_numbers
        io_sets
        event_id
        in_subthread
    }],
);

sub STATE_COUNT()   { 0 }
sub STATE_FAILED()  { 1 }
sub STATE_PLAN()    { 2 }
sub STATE_PASSING() { 3 }
sub STATE_LEGACY()  { 4 }
sub STATE_ENDED()   { 5 }

sub OUT_STD()  { 0 }
sub OUT_ERR()  { 1 }
sub OUT_TODO() { 2 }

use Test::Stream::Exporter;
exports qw/
    OUT_STD OUT_ERR OUT_TODO
    STATE_COUNT STATE_FAILED STATE_PLAN STATE_PASSING STATE_LEGACY STATE_ENDED
/;
default_exports qw/ cull tap_encoding context /;
Test::Stream::Exporter->cleanup;

sub tap_encoding {
    my ($encoding) = @_;

    require Encode;

    croak "encoding '$encoding' is not valid, or not available"
        unless $encoding eq 'legacy' || Encode::find_encoding($encoding);

    require Test::Stream::Context;
    my $ctx = Test::Stream::Context::context();
    $ctx->stream->io_sets->init_encoding($encoding);

    my $meta = init_tester($ctx->package);
    $meta->[ENCODING] = $encoding;
}

sub cull {
    my $ctx = Test::Stream::Context::context();
    $ctx->stream->fork_cull();
}

sub before_import {
    my $class = shift;
    my ($importer, $list) = @_;

    if (@$list && $list->[0] eq '-internal') {
        shift @$list;
        return;
    }

    my $meta = init_tester($importer);
    $meta->[MODERN] = 1;

    my $other  = [];
    my $idx    = 0;
    my $stream = $class->shared;

    while ($idx <= $#{$list}) {
        my $item = $list->[$idx++];
        next unless $item;

        if ($item eq 'subtest_tap') {
            my $val = $list->[$idx++];
            if (!$val || $val eq 'none') {
                $stream->set_subtest_tap_instant(0);
                $stream->set_subtest_tap_delayed(0);
            }
            elsif ($val eq 'instant') {
                $stream->set_subtest_tap_instant(1);
                $stream->set_subtest_tap_delayed(0);
            }
            elsif ($val eq 'delayed') {
                $stream->set_subtest_tap_instant(0);
                $stream->set_subtest_tap_delayed(1);
            }
            elsif ($val eq 'both') {
                $stream->set_subtest_tap_instant(1);
                $stream->set_subtest_tap_delayed(1);
            }
            else {
                croak "'$val' is not a valid option for '$item'";
            }
        }
        elsif ($item eq 'utf8') {
            $stream->io_sets->init_encoding('utf8');
            $meta->[ENCODING] = 'utf8';
        }
        elsif ($item eq 'encoding') {
            my $encoding = $list->[$idx++];

            croak "encoding '$encoding' is not valid, or not available"
                unless Encode::find_encoding($encoding);

            $stream->io_sets->init_encoding($encoding);
            $meta->[ENCODING] = $encoding;
        }
        elsif ($item eq 'enable_fork') {
            $stream->use_fork;
        }
        else {
            push @$other => $item;
        }
    }

    @$list = @$other;

    return;
}

sub plan   { $_[0]->[STATE]->[-1]->[STATE_PLAN]   }
sub count  { $_[0]->[STATE]->[-1]->[STATE_COUNT]  }
sub failed { $_[0]->[STATE]->[-1]->[STATE_FAILED] }
sub ended  { $_[0]->[STATE]->[-1]->[STATE_ENDED]  }
sub legacy { $_[0]->[STATE]->[-1]->[STATE_LEGACY] }

sub is_passing {
    my $self = shift;

    if (@_) {
        ($self->[STATE]->[-1]->[STATE_PASSING]) = @_;
    }

    my $current = $self->[STATE]->[-1]->[STATE_PASSING];

    my $plan = $self->[STATE]->[-1]->[STATE_PLAN];
    return $current if $self->[STATE]->[-1]->[STATE_ENDED];
    return $current unless $plan;
    return $current unless $plan->max;
    return $current if $plan->directive && $plan->directive eq 'NO PLAN';
    return $current unless $self->[STATE]->[-1]->[STATE_COUNT] > $plan->max;

    return $self->[STATE]->[-1]->[STATE_PASSING] = 0;
}

sub init {
    my $self = shift;

    $self->[PID]         = $$;
    $self->[TID]         = get_tid();
    $self->[STATE]       = [[0, 0, undef, 1]];
    $self->[USE_TAP]     = 1;
    $self->[USE_NUMBERS] = 1;
    $self->[IO_SETS]     = Test::Stream::IOSets->new;
    $self->[EVENT_ID]    = 1;
    $self->[NO_ENDING]   = 1;
    $self->[SUBTESTS]    = [];

    $self->[SUBTEST_TAP_INSTANT] = 1;
    $self->[SUBTEST_TAP_DELAYED] = 0;

    $self->use_fork if USE_THREADS;

    $self->[EXIT_ON_DISRUPTION] = 1;
}

{
    my ($root, @stack, $magic);

    END {
        $root->fork_cull if $root && $root->_use_fork && $$ == $root->[PID];
        $magic->do_magic($root) if $magic && $root && !$root->[NO_ENDING]
    }

    sub _stack { @stack }

    sub shared {
        my ($class) = @_;
        return $stack[-1] if @stack;

        @stack = ($root = $class->new(0));
        $root->[NO_ENDING] = 0;

        require Test::Stream::Context;
        require Test::Stream::Event::Finish;
        require Test::Stream::ExitMagic;
        require Test::Stream::ExitMagic::Context;

        $magic = Test::Stream::ExitMagic->new;

        return $root;
    }

    sub clear {
        $root->[NO_ENDING] = 1;
        $root  = undef;
        $magic = undef;
        @stack = ();
    }

    sub intercept_start {
        my $class = shift;
        my ($new) = @_;

        my $old = $stack[-1];

        unless($new) {
            $new = $class->new();

            $new->set_exit_on_disruption(0);
            $new->set_use_tap(0);
            $new->set_use_legacy(0);
        }

        push @stack => $new;

        return ($new, $old);
    }

    sub intercept_stop {
        my $class = shift;
        my ($current) = @_;
        croak "Stream stack inconsistency" unless $current == $stack[-1];
        pop @stack;
    }
}

sub intercept {
    my $class = shift;
    my ($code) = @_;

    croak "The first argument to intercept must be a coderef"
        unless $code && ref $code && ref $code eq 'CODE';

    my ($new, $old) = $class->intercept_start();
    my ($ok, $error) = try { $code->($new, $old) };
    $class->intercept_stop($new);

    die $error unless $ok;
    return $ok;
}

sub listen {
    my $self = shift;
    for my $sub (@_) {
        next unless $sub;

        croak "listen only takes coderefs for arguments, got '$sub'"
            unless ref $sub && ref $sub eq 'CODE';

        push @{$self->[LISTENERS]} => $sub;
    }
}

sub munge {
    my $self = shift;
    for my $sub (@_) {
        next unless $sub;

        croak "munge only takes coderefs for arguments, got '$sub'"
            unless ref $sub && ref $sub eq 'CODE';

        push @{$self->[MUNGERS]} => $sub;
    }
}

sub follow_up {
    my $self = shift;
    for my $sub (@_) {
        next unless $sub;

        croak "follow_up only takes coderefs for arguments, got '$sub'"
            unless ref $sub && ref $sub eq 'CODE';

        push @{$self->[FOLLOW_UPS]} => $sub;
    }
}

sub use_fork {
    require File::Temp;
    require Storable;

    $_[0]->[_USE_FORK] ||= File::Temp::tempdir(CLEANUP => 0);
    confess "Could not get a temp dir" unless $_[0]->[_USE_FORK];
    if ($^O eq 'VMS') {
        require VMS::Filespec;
        $_[0]->[_USE_FORK] = VMS::Filespec::unixify($_[0]->[_USE_FORK]);
    }
    return 1;
}

sub fork_out {
    my $self = shift;

    my $tempdir = $self->[_USE_FORK];
    confess "Fork support has not been turned on!" unless $tempdir;

    my $tid = get_tid();

    for my $event (@_) {
        next unless $event;
        next if $event->isa('Test::Stream::Event::Finish');

        # First write the file, then rename it so that it is not read before it is ready.
        my $name =  $tempdir . "/$$-$tid-" . ($self->[EVENT_ID]++);
        my ($ret, $err) = try { Storable::store($event, $name) };
        # Temporary to debug an error on one cpan-testers box
        unless ($ret) {
            require Data::Dumper;
            confess(Data::Dumper::Dumper({ error => $err, event => $event}));
        }
        rename($name, "$name.ready") || confess "Could not rename file '$name' -> '$name.ready'";
    }
}

sub fork_cull {
    my $self = shift;

    confess "fork_cull() can only be called from the parent process!"
        if $$ != $self->[PID];

    confess "fork_cull() can only be called from the parent thread!"
        if get_tid() != $self->[TID];

    my $tempdir = $self->[_USE_FORK];
    confess "Fork support has not been turned on!" unless $tempdir;

    opendir(my $dh, $tempdir) || croak "could not open temp dir ($tempdir)!";

    my @files = sort readdir($dh);
    for my $file (@files) {
        next if $file =~ m/^\.+$/;
        next unless $file =~ m/\.ready$/;

        # Untaint the path.
        my $full = "$tempdir/$file";
        ($full) = ($full =~ m/^(.*)$/gs);

        my $obj = Storable::retrieve($full);
        confess "Empty event object found '$full'" unless $obj;

        if ($ENV{TEST_KEEP_TMP_DIR}) {
            rename($full, "$full.complete")
                || confess "Could not rename file '$full', '$full.complete'";
        }
        else {
            unlink($full) || die "Could not unlink file: $file";
        }

        my $cache = $self->_update_state($self->[STATE]->[0], $obj);
        $self->_process_event($obj, $cache);
        $self->_finalize_event($obj, $cache);
    }

    closedir($dh);
}

sub done_testing {
    my $self = shift;
    my ($ctx, $num) = @_;
    my $state = $self->[STATE]->[-1];

    if (my $old = $state->[STATE_ENDED]) {
        my ($p1, $f1, $l1) = $old->call;
        $ctx->ok(0, "done_testing() was already called at $f1 line $l1");
        return;
    }

    # Do not run followups in subtest!
    if ($self->[FOLLOW_UPS] && !@{$self->[SUBTESTS]}) {
        $_->($ctx) for @{$self->[FOLLOW_UPS]};
    }

    $state->[STATE_ENDED] = $ctx->snapshot;

    my $ran  = $state->[STATE_COUNT];
    my $plan = $state->[STATE_PLAN] ? $state->[STATE_PLAN]->max : 0;

    if (defined($num) && $plan && $num != $plan) {
        $ctx->ok(0, "planned to run $plan but done_testing() expects $num");
        return;
    }

    $ctx->plan($num || $plan || $ran) unless $state->[STATE_PLAN];

    if ($plan && $plan != $ran) {
        $state->[STATE_PASSING] = 0;
        return;
    }

    if ($num && $num != $ran) {
        $state->[STATE_PASSING] = 0;
        return;
    }

    unless ($ran) {
        $state->[STATE_PASSING] = 0;
        return;
    }
}

sub subtest_start {
    my $self = shift;
    my ($name, %params) = @_;

    my $state = [0, 0, undef, 1];

    $params{parent_todo} ||= Test::Stream::Context::context->in_todo;

    if(@{$self->[SUBTESTS]}) {
        $params{parent_todo} ||= $self->[SUBTESTS]->[-1]->{parent_todo};
    }

    push @{$self->[STATE]}    => $state;
    push @{$self->[SUBTESTS]} => {
        instant => $self->[SUBTEST_TAP_INSTANT],
        delayed => $self->[SUBTEST_TAP_DELAYED],

        %params,

        state        => $state,
        events       => [],
        name         => $name,
    };

    return $self->[SUBTESTS]->[-1];
}

sub subtest_stop {
    my $self = shift;
    my ($name) = @_;

    confess "No subtest to stop!"
        unless @{$self->[SUBTESTS]};

    confess "Subtest name mismatch!"
        unless $self->[SUBTESTS]->[-1]->{name} eq $name;

    my $st = pop @{$self->[SUBTESTS]};
    pop @{$self->[STATE]};

    return $st;
}

sub subtest { @{$_[0]->[SUBTESTS]} ? $_[0]->[SUBTESTS]->[-1] : () }

sub send {
    my ($self, $e) = @_;

    my $cache = $self->_update_state($self->[STATE]->[-1], $e);

    # Subtests get dibbs on events
    if (my $num = @{$self->[SUBTESTS]}) {
        my $st = $self->[SUBTESTS]->[-1];

        $e->set_in_subtest($num);
        $e->context->set_diag_todo(1) if $st->{parent_todo};

        push @{$st->{events}} => $e;

        $self->_render_tap($cache) if $st->{instant} && !$cache->{no_out};
    }
    elsif($self->[_USE_FORK] && ($$ != $self->[PID] || get_tid() != $self->[TID])) {
        $self->fork_out($e);
    }
    else {
        $self->_process_event($e, $cache);
    }

    $self->_finalize_event($e, $cache);

    return $e;
}

sub _update_state {
    my ($self, $state, $e) = @_;
    my $cache = {tap_event => $e, state => $state};

    if ($e->isa('Test::Stream::Event::Ok')) {
        $cache->{do_tap} = 1;
        $state->[STATE_COUNT]++;
        if (!$e->bool) {
            $state->[STATE_FAILED]++;
            $state->[STATE_PASSING] = 0;
        }
    }
    elsif (!$self->[NO_HEADER] && $e->isa('Test::Stream::Event::Finish')) {
        $state->[STATE_ENDED] = $e->context->snapshot;

        my $plan = $state->[STATE_PLAN];
        if ($plan && $e->tests_run && $plan->directive eq 'NO PLAN') {
            $plan->set_max($state->[STATE_COUNT]);
            $plan->set_directive(undef);
            $cache->{tap_event} = $plan;
            $cache->{do_tap} = 1;
        }
        else {
            $cache->{do_tap} = 0;
            $cache->{no_out} = 1;
        }
    }
    elsif ($self->[NO_DIAG] && $e->isa('Test::Stream::Event::Diag')) {
        $cache->{no_out} = 1;
    }
    elsif ($e->isa('Test::Stream::Event::Plan')) {
        $cache->{is_plan} = 1;

        if($self->[NO_HEADER]) {
            $cache->{no_out} = 1;
        }
        elsif(my $existing = $state->[STATE_PLAN]) {
            my $directive = $existing ? $existing->directive : '';

            if ($existing && (!$directive || $directive eq 'NO PLAN')) {
                my ($p1, $f1, $l1) = $existing->context->call;
                my ($p2, $f2, $l2) = $e->context->call;
                die "Tried to plan twice!\n    $f1 line $l1\n    $f2 line $l2\n";
            }
        }

        my $directive = $e->directive;
        $cache->{no_out} = 1 if $directive && $directive eq 'NO PLAN';
    }

    push @{$state->[STATE_LEGACY]} => $e if $self->[USE_LEGACY];

    $cache->{number} = $state->[STATE_COUNT];

    return $cache;
}

sub _process_event {
    my ($self, $e, $cache) = @_;

    if ($self->[MUNGERS]) {
        $_->($self, $e, $e->subevents) for @{$self->[MUNGERS]};
    }

    $self->_render_tap($cache) unless $cache->{no_out};

    if ($self->[LISTENERS]) {
        $_->($self, $e) for @{$self->[LISTENERS]};
    }
}

sub _render_tap {
    my ($self, $cache) = @_;

    return if $^C;
    return unless $self->[USE_TAP];
    my $e = $cache->{tap_event};
    return unless $cache->{do_tap} || $e->can('to_tap');

    my $num = $self->use_numbers ? $cache->{number} : undef;
    my @sets = $e->to_tap($num);

    my $in_subtest = $e->in_subtest || 0;
    my $indent = '    ' x $in_subtest;

    for my $set (@sets) {
        my ($hid, $msg) = @$set;
        next unless $msg;
        my $enc = $e->encoding || confess "Could not find encoding!";
        my $io = $self->[IO_SETS]->{$enc}->[$hid] || confess "Could not find IO $hid for $enc";

        local($\, $", $,) = (undef, ' ', '');
        $msg =~ s/^/$indent/mg if $in_subtest;
        print $io $msg;
    }
}

sub _scan_for_begin {
    my ($stop_at) = @_;
    my $level = 2;

    while (my @call = caller($level++)) {
        return 1 if $call[3] =~ m/::BEGIN$/;
        return 0 if $call[3] eq $stop_at;
    }

    return undef;
}

sub _finalize_event {
    my ($self, $e, $cache) = @_;

    if ($cache->{is_plan}) {
        $cache->{state}->[STATE_PLAN] = $e;
        return unless $e->directive;
        return unless $e->directive eq 'SKIP';

        my $subtest = @{$self->[SUBTESTS]};

        $self->[SUBTESTS]->[-1]->{early_return} = $e if $subtest;

        if ($subtest) {
            my $begin = _scan_for_begin('Test::Stream::Subtest::subtest');

            if ($begin) {
                warn "SKIP_ALL in subtest via 'BEGIN' or 'use', using exception for flow control\n";
                die $e;
            }
            elsif(defined $begin) {
                no warnings 'exiting';
                eval { last TEST_STREAM_SUBTEST };
                warn "SKIP_ALL in subtest flow control error: $@";
                warn "Falling back to using an exception.\n";
                die $e;
            }
            else {
                warn "SKIP_ALL in subtest could not find flow-control label, using exception for flow control\n";
                die $e;
            }
        }

        die $e unless $self->[EXIT_ON_DISRUPTION];
        exit 0;
    }
    elsif (!$cache->{do_tap} && $e->isa('Test::Stream::Event::Bail')) {
        $self->[BAILED_OUT] = $e;
        $self->[NO_ENDING]  = 1;

        my $subtest = @{$self->[SUBTESTS]};

        $self->[SUBTESTS]->[-1]->{early_return} = $e if $subtest;

        if ($subtest) {
            my $begin = _scan_for_begin('Test::Stream::Subtest::subtest');

            if ($begin) {
                warn "BAILOUT in subtest via 'BEGIN' or 'use', using exception for flow control.\n";
                die $e;
            }
            elsif(defined $begin) {
                no warnings 'exiting';
                eval { last TEST_STREAM_SUBTEST };
                warn "BAILOUT in subtest flow control error: $@";
                warn "Falling back to using an exception.\n";
                die $e;
            }
            else {
                warn "BAILOUT in subtest could not find flow-control label, using exception for flow control.\n";
                die $e;
            }
        }

        die $e unless $self->[EXIT_ON_DISRUPTION];
        exit 255;
    }
}

sub _reset {
    my $self = shift;

    return unless $self->pid != $$ || $self->tid != get_tid();

    $self->[PID] = $$;
    $self->[TID] = get_tid();
    if (USE_THREADS || $self->[_USE_FORK]) {
        $self->[_USE_FORK] = undef;
        $self->use_fork;
    }
    $self->[STATE] = [[0, 0, undef, 1]];
}

sub CLONE {
    for my $stream (_stack()) {
        next unless defined $stream->pid;
        next unless defined $stream->tid;

        next if $$ == $stream->pid && get_tid() == $stream->tid;

        $stream->[IN_SUBTHREAD] = 1;
    }
}

sub DESTROY {
    my $self = shift;

    return if $self->in_subthread;

    my $dir = $self->[_USE_FORK] || return;

    return unless defined $self->pid;
    return unless defined $self->tid;

    return unless $$        == $self->pid;
    return unless get_tid() == $self->tid;

    if ($ENV{TEST_KEEP_TMP_DIR}) {
        print STDERR "# Not removing temp dir: $dir\n";
        return;
    }

    opendir(my $dh, $dir) || confess "Could not open temp dir! ($dir)";
    while(my $file = readdir($dh)) {
        next if $file =~ m/^\.+$/;
        die "Unculled event! You ran tests in a child process, but never pulled them in!\n"
            if $file !~ m/\.complete$/;
        unlink("$dir/$file") || confess "Could not unlink file: '$dir/$file'";
    }
    closedir($dh);
    rmdir($dir) || warn "Could not remove temp dir ($dir)";
}

sub STORABLE_freeze {
    my ($self, $cloning) = @_;
    return if $cloning;
    return ($self);
}

sub STORABLE_thaw {
    my ($self, $cloning, @vals) = @_;
    return if $cloning;
    return Test::Stream->shared;
}


1;

__END__

=head1 NAME

Test::Stream - A modern infrastructure for testing.

=head1 SYNOPSYS

    # Enables modern enhancements such as forking support and TAP encoding.
    # Also turns off expensive legacy support.
    use Test::Stream;
    use Test::More;

    # ... Tests ...

    done_testing;

=head1 FEATURES

When you load Test::Stream inside your test file you prevent Test::More from
turning on some expensive legacy support. You will also get warnings if your
code, or any other code you load uses deprecated or discouraged practices.

=head1 IMPORT ARGUMENTS

Any import argument not recognised will be treated as an export, if it is not a
valid export an exception will be thrown.

=over 4

=item '-internal'

This argument, I<when given first>, will prevent the import process from
turning on enhanced features. This is mainly for internal use (thus the name)
in order to access/load Test::Stream.

=item subtest_tap => 'none'

Do not show events within subtests, just the subtest result itself.

=item subtest_tap => 'instant'

Show events as they happen (this is how legacy Test::More worked). This is the
default.

=item subtest_tap => 'delayed'

Show events within subtest AFTER the subtest event itself is complete.

=item subtest_tap => 'both'

Show events as they happen, then also display them after.

=item 'enable_fork'

Turns on support for code that forks. This is not activated by default because
it adds ~30ms to the Test::More compile-time, which can really add up in large
test suites. Turn it on only when needed.

=item 'utf8'

Set the TAP encoding to utf8

=item encoding => '...'

Set the TAP encoding.

=back

=head1 EXPORTS

=head2 DEFAULT EXPORTS

=over 4

=item tap_encoding( $ENCODING )

Set the tap encoding from this point on.

=item cull

Bring in results from child processes/threads. This is automatically done
whenever a context is obtained, but you may wish to do it on demand.

=back

=head2 CONSTANTS

none of these are exported by default you must request them

=over

=item OUT_STD

=item OUT_ERR

=item OUT_TODO

These are indexes of specific IO handles inside an IO set (each encoding has an
IO set).

=item STATE_COUNT

=item STATE_FAILED

=item STATE_PLAN

=item STATE_PASSING

=item STATE_LEGACY

=item STATE_ENDED

These are indexes into the STATE array present in the stream.

=back

=head1 THE STREAM STACK AND METHODS

At any point there can be any number of streams. Most streams will be present
in the stream stack. The stack is managed via a collection of class methods.
You can always access the "current" or "central" stream using
Test::Stream->shared. If you want your events to go where they are supposed to
then you should always send them to the shared stream.

It is important to note that any toogle, control, listener, munger, etc.
applied to a stream will effect only that stream. Independant streams, streams
down the stack, and streams added later will not get any settings from other
stacks. Keep this in mind if you take it upon yourself to modify the stream
stack.

=head2 TOGGLES AND CONTROLS

=over 4

=item $stream->use_fork

Turn on forking support (it cannot be turned off).

=item $stream->set_subtest_tap_instant($bool)

=item $bool = $stream->subtest_tap_instant

Render subtest events as they happen.

=item $stream->set_subtest_tap_delayed($bool)

=item $bool = $stream->subtest_tap_delayed

Render subtest events when printing the result of the subtest

=item $stream->set_exit_on_disruption($bool)

=item $bool = $stream->exit_on_disruption

When true, skip_all and bailout will call exit. When false the bailout and
skip_all events will be thrown as exceptions.

=item $stream->set_use_tap($bool)

=item $bool = $stream->use_tap

Turn TAP rendering on or off.

=item $stream->set_use_legacy($bool)

=item $bool = $stream->use_legacy

Turn legacy result storing on and off.

=item $stream->set_use_numbers($bool)

=item $bool = $stream->use_numbers

Turn test numbers on and off.

=item $stash = $stream->subtest_start($name, %params)

=item $stash = $stream->subtest_stop($name)

These will push/pop new states and subtest stashes.

B<Using these directly is not recommended.> Also see the wrapper methods in
L<Test::Stream::Context>.

=back

=head2 SENDING EVENTS

    Test::Stream->shared->send($event)

The C<send()> method is used to issue an event to the stream. This method will
handle thread/fork sych, mungers, listeners, TAP output, etc.

=head2 ALTERING EVENTS

    Test::Stream->shared->munge(sub {
        my ($stream, $event) = @_;

        ... Modify the event object ...

        # return is ignored.
    });

Mungers can never be removed once added. The return from a munger is ignored.
Any changes you wish to make to the object must be done directly by altering
it in place. The munger is called before the event is rendered as TAP, and
AFTER the event has made any necessary state changes.

=head2 LISTENING FOR EVENTS

    Test::Stream->shared->listen(sub {
        my ($stream, $event) = @_;

        ... do whatever you want with the event ...

        # return is ignored
    });

Listeners can never be removed once added. The return from a listener is
ignored. Changing an event in a listener is not something you should ever do,
though no protections are in place to prevent it (this may change!). The
listeners are called AFTER the event has been rendered as TAP.

=head2 POST-TEST BEHAVIORS

    Test::Stream->shared->follow_up(sub {
        my ($context) = @_;

        ... do whatever you need to ...

        # Return is ignored
    });

follow_up subs are called only once, when the stream recieves a finish event. There are 2 ways a finish event can occur:

=over 4

=item done_testing

A finish event is generated when you call done_testing. The finish event occurs
before the plan is output.

=item EXIT MAGIC

A finish event is generated when the Test::Stream END block is called, just
before cleanup. This event will not happen if it was already geenerated by a
call to done_testing.

=back

=head2 OTHER METHODS

=over

=item $stream->state

Get the current state of the stream. The state is an array where specific
indexes have specific meanings. These indexes are managed via constants.

=item $stream->plan

Get the plan event, if a plan has been issued.

=item $stream->count

Get the test count so far.

=item $stream->failed

Get the number of failed tests so far.

=item $stream->ended

Get the context in which the tests ended, if they have ended.

=item $stream->legacy

Used internally to store events for legacy support.

=item $stream->is_passing

Check if the test is passing its plan.

=item $stream->done_testing($context, $max)

Tell the stream we are done testing.

=item $stream->fork_cull

Gather events from other threads/processes.

=back

=head2 STACK METHODS AND INTERCEPTING EVENTS

=over 4

=item $stream = Test::Stream->shared

Get the current shared stream. The shared stream is the stream at the top of
the stack.

=item Test::Stream->clear

Completely remove the stream stack. It is very unlikely you will ever want to
do this.

=item ($new, $old) = Test::Stream->intercept_start($new)

=item ($new, $old) = Test::Stream->intercept_start

Push a new stream to the top of the stack. If you do not provide a stack a new
one will be created for you. If you have one created for you it will have the
following differences from a default stack:

    $new->set_exit_on_disruption(0);
    $new->set_use_tap(0);
    $new->set_use_legacy(0);

=item Test::Stream->intercept_stop($top)

Pop the stack, you must pass in the instance you expect to be popped, there
will be an exception if they do not match.

=item Test::Stream->intercept(sub { ... })

    Test::Stream->intercept(sub {
        my ($new, $old) = @_;

        ...
    });

Temporarily push a new stream to the top of the stack. The codeblock you pass
in will be run. Once your codelbock returns the stack will be popped and
restored to the previous state.

=back

=encoding utf8

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
