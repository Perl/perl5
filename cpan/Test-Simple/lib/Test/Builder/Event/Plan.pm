package Test::Builder::Event::Plan;
use strict;
use warnings;

use base 'Test::Builder::Event';

use Test::Builder::Util qw/accessors/;
accessors qw/max directive reason/;

sub to_tap {
    my $self = shift;

    my $max       = $self->max;
    my $directive = $self->directive;
    my $reason    = $self->reason;

    return if $directive && $directive eq 'NO_PLAN';

    my $plan = "1..$max";
    $plan .= " # $directive" if defined $directive;
    $plan .= " $reason"      if defined $reason;

    return "$plan\n";
}

1;

__END__

=head1 NAME

Test::Builder::Event::Plan - The event of a plan

=head1 DESCRIPTION

The plan event object.

=head1 METHODS

See L<Test::Builder::Event> which is the base class for this module.

=head2 CONSTRUCTORS

=over 4

=item $r = $class->new(...)

Create a new instance

=back

=head2 SIMPLE READ/WRITE ACCESSORS

=over 4

=item $r->max

When the plan is specified as a number of tests, this is set to that number.

=item $r->directive

This will be set to 'skip_all' or 'no_plan' in some cases.

=item $r->reason

If there is a directive, this gives details.

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

Returns the TAP string for the plan (not indented).

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
