package Test::Builder::Event::Child;
use strict;
use warnings;

use base 'Test::Builder::Event';

use Carp qw/confess/;

use Test::Builder::Util qw/accessors/;
accessors qw/name is_subtest/;

sub action {
    my $self = shift;
    if (@_) {
        my ($action) = @_;
        confess "action must be one of 'push' or 'pop'"
            unless $action =~ m/^(push|pop)$/;

        $self->{action} = $action;
    }

    confess "action was never set!"
        unless $self->{action};

    return $self->{action};
}

sub to_tap { }

1;

__END__

=head1 NAME

Test::Builder::Event::Child - Child event type

=head1 DESCRIPTION

Sent when a child Builder is spawned, such as a subtest.

=head1 METHODS

See L<Test::Builder::Event> which is the base class for this module.

=head2 CONSTRUCTORS

=over 4

=item $r = $class->new(...)

Create a new instance

=back

=head2 ATTRIBUTES

=over 4

=item $r->action

Either 'push' or 'pop'. When a child is created a push is sent, when a child
exits a pop is sent.

=back

=head2 SIMPLE READ/WRITE ACCESSORS

=over 4

=item $r->name

Name of the child

=item $r->is_subtest

True if the child was spawned for a subtest.

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

=item $r->to_tap

no-op, return nothing.

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
