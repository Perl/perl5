package TAP::Parser::Scheduler;

use strict;
use vars qw($VERSION);
use Carp;
use TAP::Parser::Scheduler::Job;
use TAP::Parser::Scheduler::Spinner;

=head1 NAME

TAP::Parser::Scheduler - Schedule tests during parallel testing

=head1 VERSION

Version 3.13

=cut

$VERSION = '3.13';

=head1 SYNOPSIS

    use TAP::Parser::Scheduler;

=head1 DESCRIPTION

=head1 METHODS

=head2 Class Methods

=head3 C<new>

    my $sched = TAP::Parser::Scheduler->new;

Returns a new C<TAP::Parser::Scheduler> object.

=cut

sub new {
    my $class = shift;

    croak "Need a number of key, value pairs" if @_ % 2;

    my %args  = @_;
    my $tests = delete $args{tests} || croak "Need a 'tests' argument";
    my $rules = delete $args{rules} || { par => '**' };

    croak "Unknown arg(s): ", join ', ', sort keys %args
      if keys %args;

    # Turn any simple names into a name, description pair. TODO: Maybe
    # construct jobs here?
    my $self = bless {}, $class;

    $self->_set_rules( $rules, $tests );

    return $self;
}

# Build the scheduler data structure.
#
# SCHEDULER-DATA ::= JOB
#                ||  ARRAY OF ARRAY OF SCHEDULER-DATA
#
# The nested arrays are the key to scheduling. The outer array contains
# a list of things that may be executed in parallel. Whenever an
# eligible job is sought any element of the outer array that is ready to
# execute can be selected. The inner arrays represent sequential
# execution. They can only proceed when the first job is ready to run.

sub _set_rules {
    my ( $self, $rules, $tests ) = @_;
    my @tests = map { TAP::Parser::Scheduler::Job->new(@$_) }
      map { 'ARRAY' eq ref $_ ? $_ : [ $_, $_ ] } @$tests;
    my $schedule = $self->_rule_clause( $rules, \@tests );

    # If any tests are left add them as a sequential block at the end of
    # the run.
    $schedule = [ [ $schedule, @tests ] ] if @tests;

    $self->{schedule} = $schedule;
}

sub _rule_clause {
    my ( $self, $rule, $tests ) = @_;
    croak 'Rule clause must be a hash'
      unless 'HASH' eq ref $rule;

    my @type = keys %$rule;
    croak 'Rule clause must have exactly one key'
      unless @type == 1;

    my %handlers = (
        par => sub {
            [ map { [$_] } @_ ];
        },
        seq => sub { [ [@_] ] },
    );

    my $handler = $handlers{ $type[0] }
      || croak 'Unknown scheduler type: ', $type[0];
    my $val = $rule->{ $type[0] };

    return $handler->(
        map {
            'HASH' eq ref $_
              ? $self->_rule_clause( $_, $tests )
              : $self->_expand( $_, $tests )
          } 'ARRAY' eq ref $val ? @$val : $val
    );
}

sub _expand {
    my ( $self, $name, $tests ) = @_;

    $name =~ s{(\?|\*\*?|.)}{
        $1 eq '?'  ? '[^/]'
      : $1 eq '*'  ? '[^/]*'
      : $1 eq '**' ? '.*?'
      :             quotemeta($1);
    }gex;

    my $pattern = qr{^$name$};
    my @match   = ();

    for ( my $ti = 0; $ti < @$tests; $ti++ ) {
        if ( $tests->[$ti]->filename =~ $pattern ) {
            push @match, splice @$tests, $ti, 1;
            $ti--;
        }
    }

    return @match;
}

=head3 C<get_all>

Get a list of all remaining tests.

=cut

sub get_all {
    my $self = shift;
    $self->_gather( $self->{schedule} );
}

sub _gather {
    my ( $self, $rule ) = @_;
    return unless defined $rule;
    return $rule unless 'ARRAY' eq ref $rule;
    return map { $self->_gather($_) } grep {defined} map {@$_} @$rule;
}

=head3 C<get_job>

Return the next available job or C<undef> if none are available. Returns
a C<TAP::Parser::Scheduler::Spinner> if the scheduler still has pending
jobs but none are available to run right now.

=cut

sub get_job {
    my $self = shift;
    my @jobs = $self->_find_next_job( $self->{schedule} );
    return $jobs[0] if @jobs;

    # TODO: This isn't very efficient...
    return TAP::Parser::Scheduler::Spinner->new
      if $self->get_all;

    return;
}

sub _not_empty {
    my $ar = shift;
    return 1 unless defined $ar && 'ARRAY' eq ref $ar;
    return 1 if grep { _not_empty($_) } @$ar;
    return;
}

sub _is_empty { !_not_empty(@_) }

sub _find_next_job {
    my ( $self, $rule ) = @_;

    my @queue = ();
    for my $seq (@$rule) {

        # Prune any exhausted items.
        shift @$seq while @$seq && _is_empty( $seq->[0] );
        if ( @$seq && defined $seq->[0] ) {
            if ( 'ARRAY' eq ref $seq->[0] ) {
                push @queue, $seq;
            }
            else {
                my $job = splice @$seq, 0, 1, undef;
                $job->on_finish( sub { shift @$seq } );
                return $job;
            }
        }
    }

    for my $seq (@queue) {
        if ( my @jobs = $self->_find_next_job( $seq->[0] ) ) {
            return @jobs;
        }
    }

    return;
}

=head3 C<as_string>

Return a human readable representation of the scheduling tree.

=cut

sub as_string {
    my $self = shift;
    return $self->_as_string( $self->{schedule} );
}

sub _as_string {
    my ( $self, $rule, $depth ) = ( shift, shift, shift || 0 );
    my $pad    = ' ' x 2;
    my $indent = $pad x $depth;
    if ( !defined $rule ) {
        return "$indent(undef)\n";
    }
    elsif ( 'ARRAY' eq ref $rule ) {
        return unless @$rule;
        my $type = ( 'par', 'seq' )[ $depth % 2 ];
        return join(
            '', "$indent$type:\n",
            map { $self->_as_string( $_, $depth + 1 ) } @$rule
        );
    }
    else {
        return "$indent'" . $rule->filename . "'\n";
    }
}

1;
