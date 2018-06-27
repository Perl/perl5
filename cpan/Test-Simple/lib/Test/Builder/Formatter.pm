package Test::Builder::Formatter;
use strict;
use warnings;

our $VERSION = '1.302073';

BEGIN { require Test2::Formatter::TAP; our @ISA = qw(Test2::Formatter::TAP) }

use Test2::Util::HashBase qw/no_header no_diag/;

BEGIN {
    *OUT_STD = Test2::Formatter::TAP->can('OUT_STD');
    *OUT_ERR = Test2::Formatter::TAP->can('OUT_ERR');

    my $todo = OUT_ERR() + 1;
    *OUT_TODO = sub() { $todo };
}

__PACKAGE__->register_event('Test::Builder::TodoDiag', 'event_todo_diag');

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->{+HANDLES}->[OUT_TODO] = $self->{+HANDLES}->[OUT_STD];
}

sub event_todo_diag {
    my $self = shift;
    my @out = $self->event_diag(@_);
    $out[0]->[0] = OUT_TODO();
    return @out;
}

sub event_diag {
    my $self = shift;
    return if $self->{+NO_DIAG};
    return $self->SUPER::event_diag(@_);
}

sub event_plan {
    my $self = shift;
    return if $self->{+NO_HEADER};
    return $self->SUPER::event_plan(@_);
}

sub event_ok_multiline {
    my $self = shift;
    my ($out, $space, @extra) = @_;

    return(
        [OUT_STD, "$out\n"],
        map {[OUT_STD, "# $_\n"]} @extra,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Builder::Formatter - Test::Builder subclass of Test2::Formatter::TAP

=head1 DESCRIPTION

This is what takes events and turns them into TAP.

=head1 SYNOPSIS

    use Test::Builder; # Loads Test::Builder::Formatter for you

=head1 METHODS

=over 4

=item $f->event_todo_diag

Additional method used to process L<Test::Builder::TodoDiag> events.

=item $f->event_diag

=item $f->event_plan

These override the parent class methods to do nothing if C<no_header> is set.

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
