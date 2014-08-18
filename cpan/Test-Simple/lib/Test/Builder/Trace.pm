package Test::Builder::Trace;
use strict;
use warnings;

use Test::Builder::Util qw/accessor accessors is_tester try/;
use Test::Builder::Trace::Frame;
use List::Util qw/first/;
use Scalar::Util qw/blessed/;

accessor _anointed    => sub { [] };
accessor _full        => sub { [] };
accessor _level       => sub { [] };
accessor _tools       => sub { [] };
accessor _transitions => sub { [] };
accessor _stack       => sub { [] };
accessor _todo        => sub { [] };
accessor raw          => sub { [] };
accessor packages     => sub { [] };
accessor seek_level   => sub { 0  };
accessor todo_raw     => sub { {} };

accessors qw/_report encoding _parent/;

sub nest {
    my $class = shift;
    my ($code, @args) = @_;
    $code->(@args);
}

sub anoint {
    my $class = shift;
    my ($target, $oil) = @_;

    unless (is_tester($target)) {
        my $meta = {anointed_by => {}};
        no strict 'refs';
        *{"$target\::TB_TESTER_META"} = sub {$meta};
    }

    return 1 unless $oil;
    my $meta = $target->TB_TESTER_META;
    $meta->{anointed_by}->{$oil} = 1;
}

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    my $seek_level = do { no warnings 'once'; $Test::Builder::Level - $Test::Builder::BLevel };
    $self->seek_level($seek_level);

    my %todo;
    my %packages;

    my $raw   = $self->raw;
    my $plist = $self->packages;

    my $stack_level = 0;
    while(my @call = CORE::caller($stack_level++)) {
        unless(exists $todo{$call[0]}) {
            no strict 'refs';
            $todo{$call[0]} = ${"$call[0]\::TODO"};
        }

        my $record = [@call[0 .. 4], $todo{$call[0]}];
        push @$raw => $record;

        next if $packages{$call[0]}++;
        push @$plist => $call[0];
        next if $self->encoding;
        next unless is_tester($call[0]);
        next if $call[3] eq 'Test::Builder::subtest';
        $self->encoding($call[0]->TB_TESTER_META->{encoding});
    }

    $self->todo_raw(\%todo);

    return $self;
}

accessor todo_reasons => sub {
    my $self = shift;
    my %seen;
    return [grep { $_ && !$seen{$_} } values %{$self->todo_raw}];
};

accessor todo_package => sub {
    my $self = shift;

    # Do not force building, but if it is built use it.
    if ($self->{_build}) {
        return $self->report->package          if $self->report && $self->report->todo;
        return $self->todo->[-1]->package      if @{$self->todo};
        return $self->anointed->[-1]->package  if @{$self->anointed};
        return;
    }

    my $raw = $self->todo_raw;
    if (@{$self->todo_reasons}) {
        for my $pkg (@{$self->packages}) {
            next unless $raw->{$pkg};
            return $pkg;
        }
    }

    my $anointed;
    for my $pkg (@{$self->packages}) {
        no strict 'refs';
        no warnings 'once';

        my $ref = *{$pkg . '::TODO'}{SCALAR};
        return $pkg if $ref == *Test::More::TODO{SCALAR};

        $anointed ||= $pkg if is_tester($pkg);
    }

    return $anointed;
};

sub _build {
    my $self = shift;
    my $class = blessed($self);

    return if $self->{_build}++;

    my $seek_level  = $self->seek_level;
    my $stack_level = 0;
    my $notb_level  = 0;

    my $current = $self;
    for my $call (@{$self->raw}) {
        my $depth = $stack_level++;
        my $frame = Test::Builder::Trace::Frame->new($depth, @$call);
        my ($pkg, $file, $line, $sub, $todo) = @$call;

        push @{$current->_full} => $frame;

        if ($frame->nest) {
            $current->report;
            $current->_parent( bless {}, $class );
            $current = $current->_parent;
            next;
        }

        next if $frame->builder;

        $notb_level++ unless $current->_is_transition($frame);

        if ($seek_level && $notb_level - 1 == $seek_level) {
            $frame->level(1);
            $current->_report($current->tools->[-1]) if $current->tools->[-1] && !($current->_report || $frame->anointed);
        }

        next unless grep { $frame->$_ } qw/provider_tool anointed transition level todo/;

        push @{$current->_stack}       => $frame;
        push @{$current->_tools}       => $frame if $frame->provider_tool;
        push @{$current->_anointed}    => $frame if $frame->anointed;
        push @{$current->_transitions} => $frame if $frame->transition;
        push @{$current->_level}       => $frame if $frame->level;
        push @{$current->_todo}        => $frame if $frame->todo;
    }
}

sub report {
    my $self = shift;
    my ($report) = @_;

    if ($report) {
        $report->report(1);
        $self->_report($report);
    }
    elsif (!$self->_report) {
        $self->_build;
        my $level      = $self->_level->[0];
        my $tool       = $self->_tools->[-1];
        my $anointed   = first { !$_->provider_tool } @{$self->_anointed};
        my $transition = $self->_transitions->[-1];

        if ($tool && $level) {
            ($report) = sort { $b->{depth} <=> $a->{depth} } $tool, $level;
        }

        $report ||= $level || $tool || $anointed || $transition;

        if ($report) {
            $report->report(1);
            $self->_report($report);
        }
    }

    return $self->_report;
}

sub _is_transition {
    my $self = shift;
    my ($frame) = @_;

    # Check if it already knows
    return 1 if $frame->transition;

    return if $frame->builder;
    return unless @{$self->full} > 1;
    return unless $self->full->[-2]->builder || $self->full->[-2]->nest;

    $frame->transition(1);

    return 1;
}

for my $name (qw/anointed full level tools transitions stack todo parent/) {
    my $acc = "_$name";
    my $sub = sub {
        my $self = shift;
        $self->_build;
        return $self->$acc;
    };

    no strict 'refs';
    *$name = $sub;
}

1;

__END__

=pod

=head1 NAME

Test::Builder::Trace - Module to represent a stack trace from a test event.

=head1 DESCRIPTION

When a test fails it will report the filename and line where the failure
occured. In order to do this it needs to look at the stack and figure out where
your tests stop, and the tools you are using begin. This object helps you find
the desired caller frame.

=head1 CLASS METHODS

=over 4

=item $trace = $class->new

Create a new object tracing from itself to the deepest stack frame.

    my $trace = Test::Builder::Trace->new();

=item $class->nest(sub { ... })

Used as a tracing barrier. Events produced in the coderef will trace to that
coderef and no deeper.

=item $class->anoint($TARGET_PACKAGE)

=item $class->anoint($TARGET_PACKAGE, $ANOINTED_BY_PACKAGE)

Used to anoint a package as a testing package.

=back

=head1 UTILITY METHODS

=over 4

=item $frame = $trace->report

Get the L<Test::Builder::Trace::Frame> object that should be used when
reporting errors. The 'report' is determined by examining the stack,
C<$Test::Builder::Level>, and provider/anointed metadata.

=item $trace = $trace->parent

A trace stops when it encounters a call to C<Test::Builder::Trace::nest> which
acts as a tracing barrier. When such a barrier is encountered the tracing
continues, but stores the frames in a new L<Test::Builder::Trace> object that
is set as the parent. You can use this to examine the stack beyond the main
trace.

=back

=head1 STACKS

All stacks are arrayrefs containing L<Test::Builder::Trace::Frame> objects.

=over 4

=item $arrayref = $trace->stack

This stack contains all frames that are relevant to finding the report. Many
frames are kept out of this list. This will usually be the most helpful stack
to examine.

=item $arrayref = $trace->full

Absolutely every frame is kept in this stack. Examine this if you want to see
EVERYTHING.

=item $arrayref = $trace->anointed

This stack contains all the frames that come from an anointed package.

=item $arrayref = $trace->level

This stack contains all the frames that match the C<$Test::Builder::Level>
variable.

=item $arrayref = $trace->tools

This stack contains all the frames that are calls to provider tools.

=item $arrayref = $trace->transitions

This stack contains all the frames that act as transitions between external
code and L<Test::Builder> related code.

=item $arrayref - $trace->todo

This stack contains all the frames that seem to have a $TODO variable available
to them. See L<Test::Builder::Trace::Frame> for caveats.

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2014 by Chad Granum E<lt>exodist7@gmail.comE<gt>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

