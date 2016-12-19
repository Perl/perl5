package Test2::Event::Subtest;
use strict;
use warnings;

our $VERSION = '1.302073';


BEGIN { require Test2::Event::Ok; our @ISA = qw(Test2::Event::Ok) }
use Test2::Util::HashBase qw{subevents buffered subtest_id};

sub init {
	my $self = shift;
	$self->SUPER::init();
	$self->{+SUBEVENTS} ||= [];
	if ($self->{+EFFECTIVE_PASS}) {
		$_->set_effective_pass(1) for grep { $_->can('effective_pass') } @{$self->{+SUBEVENTS}};
	}
}

{
	no warnings 'redefine';

	sub set_subevents {
		my $self      = shift;
		my @subevents = @_;

		if ($self->{+EFFECTIVE_PASS}) {
			$_->set_effective_pass(1) for grep { $_->can('effective_pass') } @subevents;
		}

		$self->{+SUBEVENTS} = \@subevents;
	}

	sub set_effective_pass {
		my $self = shift;
		my ($pass) = @_;

		if ($pass) {
			$_->set_effective_pass(1) for grep { $_->can('effective_pass') } @{$self->{+SUBEVENTS}};
		}
		elsif ($self->{+EFFECTIVE_PASS} && !$pass) {
			for my $s (grep { $_->can('effective_pass') } @{$self->{+SUBEVENTS}}) {
				$_->set_effective_pass(0) unless $s->can('todo') && defined $s->todo;
			}
		}

		$self->{+EFFECTIVE_PASS} = $pass;
	}
}

sub summary {
    my $self = shift;

    my $name = $self->{+NAME} || "Nameless Subtest";

    my $todo = $self->{+TODO};
    if ($todo) {
        $name .= " (TODO: $todo)";
    }
    elsif (defined $todo) {
        $name .= " (TODO)"
    }

    return $name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Event::Subtest - Event for subtest types

=head1 DESCRIPTION

This class represents a subtest. This class is a subclass of
L<Test2::Event::Ok>.

=head1 ACCESSORS

This class inherits from L<Test2::Event::Ok>.

=over 4

=item $arrayref = $e->subevents

Returns the arrayref containing all the events from the subtest

=item $bool = $e->buffered

True if the subtest is buffered, that is all subevents render at once. If this
is false it means all subevents render as they are produced.

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
