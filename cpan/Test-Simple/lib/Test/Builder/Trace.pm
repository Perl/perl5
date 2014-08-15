package Test::Builder::Trace;
use strict;
use warnings;

use Test::Builder::Util qw/accessor accessors is_tester try/;
use Test::Builder::Trace::Frame;
use List::Util qw/first/;

accessor anointed    => sub { [] };
accessor full        => sub { [] };
accessor level       => sub { [] };
accessor tools       => sub { [] };
accessor transitions => sub { [] };
accessor stack       => sub { [] };
accessor todo        => sub { [] };

accessors qw/_report parent/;

my $LEVEL_WARNED = 0;

sub nest {
    my $class = shift;
    my ($code, @args) = @_;
    $code->(@args);
}

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    my $stack_level = 0;
    my $seek_level = do { no warnings 'once'; $Test::Builder::Level - $Test::Builder::BLevel };
    my $notb_level = 0;

    my $current = $self;
    while(my @call = CORE::caller($stack_level)) {
        my $depth = $stack_level++;
        my $frame = Test::Builder::Trace::Frame->new($depth, @call);
        my ($pkg, $file, $line, $sub) = @call;

        push @{$current->full} => $frame;

        if ($frame->nest) {
            $current->report;
            $current->parent( bless {}, $class );
            $current = $current->parent;
            next;
        }

        next if $frame->builder;

        $notb_level++ unless $current->_is_transition($frame);

        if ($seek_level && $notb_level - 1 == $seek_level) {
            $frame->level(1);
            $current->report($current->tools->[-1]) if $current->tools->[-1] && !($current->_report || $frame->anointed);

            warn "\$Test::Builder::Level was used to trace a test! \$Test::Builder::Level is deprecated!\n"
                if $INC{'Test/Tester2.pm'} && !$LEVEL_WARNED++;
        }

        next unless grep { $frame->$_ } qw/provider_tool anointed transition level todo/;

        push @{$current->stack}       => $frame;
        push @{$current->tools}       => $frame if $frame->provider_tool;
        push @{$current->anointed}    => $frame if $frame->anointed;
        push @{$current->transitions} => $frame if $frame->transition;
        push @{$current->level}       => $frame if $frame->level;
        push @{$current->todo}        => $frame if $frame->todo;
    }

    $current->report;
    $current->encoding; # Generate this now

    return $self;
}

sub encoding {
    my $self = shift;

    unless($self->{encoding}) {
        return unless @{$self->anointed};
        $self->{encoding} = $self->anointed->[0]->package->TB_TESTER_META->{encoding};
    }

    return $self->{encoding};
}

sub todo_package {
    my $self = shift;
    return $self->report->package          if $self->report && $self->report->todo;
    return $self->todo->[-1]->package      if @{$self->todo};
    return $self->anointed->[-1]->package  if @{$self->anointed};
}

sub report {
    my $self = shift;
    my ($report) = @_;

    if ($report) {
        $report->report(1);
        $self->_report($report);
    }
    elsif (!$self->_report) {
        my $level      = $self->level->[0];
        my $tool       = $self->tools->[-1];
        my $anointed   = first { !$_->provider_tool } @{$self->anointed};
        my $transition = $self->transitions->[-1];

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

1;

__END__

=pod

=head1 NAME

Test::Builder::Trace - Module to represent a stack trace from a test result.

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

Used as a tracing barrier. Results produced in the coderef will trace to that
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

=item $package = $trace->todo_package

Get the name of the package from which the $TODO variable should be checked.

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
