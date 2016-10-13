package Test2::Event;
use strict;
use warnings;

our $VERSION = '1.302059';


use Test2::Util::HashBase qw/trace nested in_subtest subtest_id/;
use Test2::Util::ExternalMeta qw/meta get_meta set_meta delete_meta/;

sub causes_fail      { 0 }
sub increments_count { 0 }
sub diagnostics      { 0 }
sub no_display       { 0 }

sub callback { }

sub terminate { () }
sub global    { () }
sub sets_plan { () }

sub summary { ref($_[0]) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Event - Base class for events

=head1 DESCRIPTION

Base class for all event objects that get passed through
L<Test2>.

=head1 SYNOPSIS

    package Test2::Event::MyEvent;
    use strict;
    use warnings;

    # This will make our class an event subclass (required)
    use base 'Test2::Event';

    # Add some accessors (optional)
    # You are not obligated to use HashBase, you can use any object tool you
    # want, or roll your own accessors.
    use Test2::Util::HashBase qw/foo bar baz/;

    # Chance to initialize some defaults
    sub init {
        my $self = shift;
        # no other args in @_

        $self->set_foo('xxx') unless defined $self->foo;

        ...
    }

    1;

=head1 METHODS

=over 4

=item $trace = $e->trace

Get a snapshot of the L<Test2::Util::Trace> as it was when this event was
generated

=item $bool = $e->causes_fail

Returns true if this event should result in a test failure. In general this
should be false.

=item $bool = $e->increments_count

Should be true if this event should result in a test count increment.

=item $e->callback($hub)

If your event needs to have extra effects on the L<Test2::Hub> you can override
this method.

This is called B<BEFORE> your event is passed to the formatter.

=item $call = $e->created

Get the C<caller()> details from when the event was generated. This is usually
inside a tools package. This is typically used for debugging.

=item $num = $e->nested

If this event is nested inside of other events, this should be the depth of
nesting. (This is mainly for subtests)

=item $bool = $e->global

Set this to true if your event is global, that is ALL threads and processes
should see it no matter when or where it is generated. This is not a common
thing to want, it is used by bail-out and skip_all to end testing.

=item $code = $e->terminate

This is called B<AFTER> your event has been passed to the formatter. This
should normally return undef, only change this if your event should cause the
test to exit immediately.

If you want this event to cause the test to exit you should return the exit
code here. Exit code of 0 means exit success, any other integer means exit with
failure.

This is used by L<Test2::Event::Plan> to exit 0 when the plan is
'skip_all'. This is also used by L<Test2::Event:Bail> to force the test
to exit with a failure.

This is called after the event has been sent to the formatter in order to
ensure the event is seen and understood.

=item $todo = $e->todo

=item $e->set_todo($todo)

Get/Set the todo reason on the event. Any value other than C<undef> makes the
event 'TODO'.

Not all events make use of this field, but they can all have it set/cleared.

=item $bool = $e->diag_todo

=item $e->diag_todo($todo)

True if this event should be considered 'TODO' for diagnostics purposes. This
essentially means that any message that would go to STDERR will go to STDOUT
instead so that a harness will hide it outside of verbose mode.

=item $msg = $e->summary

This is intended to be a human readable summary of the event. This should
ideally only be one line long, but you can use multiple lines if necessary. This
is intended for human consumption. You do not need to make it easy for machines
to understand.

The default is to simply return the event package name.

=item ($count, $directive, $reason) = $e->sets_plan()

Check if this event sets the testing plan. It will return an empty list if it
does not. If it does set the plan it will return a list of 1 to 3 items in
order: Expected Test Count, Test Directive, Reason for directive.

=item $bool = $e->diagnostics

True if the event contains diagnostics info. This is useful because a
non-verbose harness may choose to hide events that are not in this category.
Some formatters may choose to send these to STDERR instead of STDOUT to ensure
they are seen.

=item $bool = $e->no_display

False by default. This will return true on events that should not be displayed
by formatters.

=item $id = $e->in_subtest

If the event is inside a subtest this should have the subtest ID.

=item $id = $e->subtest_id

If the event is a final subtest event, this should contain the subtest ID.

=back

=head1 THIRD PARTY META-DATA

This object consumes L<Test2::Util::ExternalMeta> which provides a consistent
way for you to attach meta-data to instances of this class. This is useful for
tools, plugins, and other extensions.

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
