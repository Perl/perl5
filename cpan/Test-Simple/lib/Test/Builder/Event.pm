package Test::Builder::Event;
use strict;
use warnings;

use Carp qw/confess/;
use Scalar::Util qw/blessed/;

use Test::Builder::Util qw/accessors new/;

accessors(qw/trace pid depth in_todo source constructed/);

sub init {
    my $self = shift;
    my %params = @_;

    $self->constructed([caller(1)]);
    $self->pid($$) unless $params{pid};
}

sub type {
    my $self = shift;
    my $class = blessed($self);
    if ($class && $class =~ m/^.*::([^:]+)$/) {
        return lc($1);
    }

    confess "Could not determine event type for $self";
}

sub indent {
    my $self = shift;
    return '' unless $self->depth;
    return '    ' x $self->depth;
}

sub encoding {
    my $self = shift;
    return unless $self->trace;
    return $self->trace->encoding;
}

1;

__END__

=head1 NAME

Test::Builder::Event - Base class for events

=head1 DESCRIPTION

Base class for all event objects that get passed through
L<Test::Builder::Stream>.

=head1 METHODS

=head2 CONSTRUCTORS

=over 4

=item $r = $class->new(...)

Create a new instance

=back

=head2 SIMPLE READ/WRITE ACCESSORS

=over 4

=item $r->trace

Get the test trace info, including where to report errors.

=item $r->pid

PID in which the event was created.

=item $r->depth

Builder depth of the event (0 for normal, 1 for subtest, 2 for nested, etc).

=item $r->in_todo

True if the event was generated inside a todo.

=item $r->source

Builder that created the event, usually $0, but the name of a subtest when
inside a subtest.

=item $r->constructed

Package, File, and Line in which the event was built.

=back

=head2 INFORMATION

=over 4

=item $r->type

Type of event. Usually this is the lowercased name from the end of the
package. L<Test::Builder::Event::Ok> = 'ok'.

=item $r->indent

Returns the indentation that should be used to display the event ('    ' x
depth).

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 SOURCE

The source code repository for Test::More can be found at
F<http://github.com/Test-More/test-more/>.

=head1 COPYRIGHT

Copyright 2014 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>
