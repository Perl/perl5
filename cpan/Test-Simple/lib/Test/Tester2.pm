package Test::Tester2;
use strict;
use warnings;

use Test::Builder 1.301001;
use Test::Builder::Stream;
use Test::Builder::Util qw/try/;

use Scalar::Util qw/blessed reftype/;
use Carp qw/croak/;

use Test::Builder::Provider;
gives qw/intercept display_events display_event render_event/;
provides qw/events_are/;

sub intercept(&) {
    my ($code) = @_;

    my @events;

    my ($ok, $error) = try {
        Test::Builder::Stream->intercept(
            sub {
                my $stream = shift;
                $stream->exception_followup;

                $stream->listen(
                    INTERCEPTOR => sub {
                        my ($item) = @_;
                        push @events => $item;
                    }
                );
                $code->();
            }
        );
    };

    die $error unless $ok || (blessed($error) && $error->isa('Test::Builder::Event'));

    return \@events;
}

sub events_are {
    my ($events, @checks) = @_;

    my @res_list = @$events;

    my $overall_name;
    my $seek = 0;
    my $skip = 0;
    my $ok = 1;
    my $wnum = 0;
    my @diag;

    while($ok && @checks) {
        my $action = shift @checks;

        if ($action =~ m/^(!)?filter_providers?$/) {
            @res_list = _filter_list(
                $1 || 0,
                shift(@checks),
                sub { $_[0]->trace->report->provider_tool->{package} },
                @res_list
            );
            next;
        }
        elsif ($action =~ m/^(!)?filter_types?$/) {
            @res_list = _filter_list(
                $1 || 0,
                shift(@checks),
                sub { $_[0]->type },
                @res_list
            );
            next;
        }
        elsif ($action eq 'skip') {
            $skip = shift @checks;
            next if $skip eq '*';

            shift(@res_list) while $skip--;

            next;
        }
        elsif ($action eq 'seek') {
            $seek = shift @checks;
            next;
        }
        elsif ($action eq 'end') {
            if(@res_list) {
                $ok = 0;
                push @diag => "Expected end of events, but more events remain";
            }
            $overall_name = shift @checks;
            last;
        }
        elsif ($action eq 'name') {
            $overall_name = shift @checks;
            next;
        }

        my $type = $action;
        my $got  = shift @res_list;
        my $want = shift @checks; $wnum++;
        my $id = "$type " . (delete $want->{id} || $wnum);

        $want ||= "(UNDEF)";
        croak "($id) '$type' must be paired with a hashref, but you gave: '$want'"
            unless $want && ref $want && reftype $want eq 'HASH';

        $got = shift(@res_list) while ($skip || $seek) && $got && $type ne $got->type;
        $skip = 0;

        if (!$got) {
            $ok = 0;
            push @diag => "($id) Wanted event type '$type', But no more events left to check!";
            push @diag => "Full event found was: " . render_event($got);
            last;
        }

        if ($type ne $got->type) {
            $ok = 0;
            push @diag => "($id) Wanted event type '$type', But got: '" . $got->type . "'";
            push @diag => "Full event found was: " . render_event($got);
            last;
        }

        my $fields = _simplify_event($got);

        for my $key (keys %$want) {
            my $wval = $want->{$key};
            my $rtype = reftype($wval) || "";
            $rtype = 'REGEXP' if $rtype eq 'SCALAR' && "$wval" =~ m/^\(\?[-xism]{5}:.*\)$/;
            my $gval = $fields->{$key};

            my $field_ok;
            if ($rtype eq 'CODE') {
                $field_ok = $wval->($gval);
                $gval = "(UNDEF)" unless defined $gval;
                push @diag => "($id) $key => '$gval' did not validate via coderef" unless $field_ok;
            }
            elsif ($rtype eq 'REGEXP') {
                $field_ok = defined $gval && $gval =~ $wval;
                $gval = "(UNDEF)" unless defined $gval;
                push @diag => "($id) $key => '$gval' does not match $wval" unless $field_ok;
            }
            elsif(!exists $fields->{$key}) {
                $field_ok = 0;
                push @diag => "($id) Wanted $key => '$wval', but '$key' does not exist" unless $field_ok;
            }
            elsif(defined $wval && !defined $gval) {
                $field_ok = 0;
                push @diag => "($id) Wanted $key => '$wval', but '$key' is not defined" unless $field_ok;
            }
            elsif($wval =~ m/^\d+x?[\d\.e_]*$/i && $gval =~ m/^\d+x?[\d\.e_]*$/i) {
                $field_ok = $wval == $gval;
                push @diag => "($id) Wanted $key => '$wval', but got $key => '$gval'" unless $field_ok;
            }
            else {
                $field_ok = "$wval" eq "$gval";
                push @diag => "($id) Wanted $key => '$wval', but got $key => '$gval'" unless $field_ok;
            }

            $ok &&= $field_ok;
        }

        unless ($ok) {
            push @diag => "Full event found was: " . render_event($got);
            last;
        }
    }

    # Find the test name
    while(my $action = shift @checks) {
        next unless $action eq 'end' || $action eq 'name';
        $overall_name = shift @checks;
    }

    builder()->ok($ok, $overall_name || "Got expected events", @diag);
    return $ok;
}

sub display_events {
    my ($events) = @_;
    display_event($_) for @$events;
}

sub display_event {
    print STDERR render_event(@_);
}

sub render_event {
    my ($event) = @_;

    my @order = qw/
        name bool real_bool action max
        directive reason in_todo
        package file line pid
        depth is_subtest source tests_failed tests_run
        tool_name tool_package
        message
        tap
    /;

    my $fields = _simplify_event($event);

    my %seen;
    my $out = "$fields->{type} => {\n";
    for my $field (@order, keys %$fields) {
        next if $field eq 'type';
        next if $seen{$field}++;
        next unless defined $fields->{$field};
        if ($fields->{$field} =~ m/\n/sm) {
            $out .= "  $field:\n";
            for my $line (split /\n+/sm, $fields->{$field}) {
                next unless $line;
                next if $line eq "\n";
                $out .= "    $line\n";
            }
        }
        else {
            $out .= "  $field: $fields->{$field}\n";
        }
    }
    $out .= "}\n";

    return $out;
}

sub _simplify_event {
    my ($r) = @_;

    my $fields = {map { ref $r->{$_} ? () : ($_ => $r->{$_}) } keys %$r};
    $fields->{type} = $r->type;

    if ($r->trace && $r->trace->report) {
        my $report = $r->trace->report;
        @{$fields}{qw/line file package/} = map { $report->$_ } qw/line file package/;
        @{$fields}{qw/tool_package tool_name/} = @{$report->provider_tool}{qw/package name/} if $report->provider_tool;
    }

    $fields->{tap} = $r->to_tap if $r->can('to_tap');
    chomp($fields->{tap}) if $fields->{tap};

    return $fields;
}

sub _filter_list {
    my ($negate, $args, $fetch, @items) = @_;

    my (@regex, @code, %name);
    for my $arg (ref $args && reftype $args eq 'ARRAY' ? @$args : ($args)) {
        my $reftype = reftype $arg || "";
        if ($reftype eq 'REGEXP') {
            push @regex => $arg;
        }
        elsif($reftype eq 'CODE') {
            push @code  => $arg;
        }
        else {
            $name{$arg}++;
        }
    }

    my @newlist;
    for my $item (@items) {
        my $val = $fetch->($item) || next;

        my $match = $name{$val} || (grep { $_->($val) } @code) || (grep { $val =~ $_ } @regex) || 0;
        $match = !$match if $negate;
        push @newlist => $item if $match;
    }
    return @newlist;
}


1;

__END__

=head1 NAME

Test::Tester2 - Tools for validating the events produced by your testing
tools.

=head1 DESCRIPTION

Unit tests are tools to validate your code. This library provides tools to
validate your tools!

=head1 TEST COMPONENT MAP

  [Test Script] > [Test Tool] > [Test::Builder] > [Test::Bulder::Stream] > [Event Formatter]

A test script uses a test tool such as L<Test::More>, which uses Test::Builder
to produce events. The events are sent to L<Test::Builder::Stream> which then
forwards them on to one or more formatters. The default formatter is
L<Test::Builder::Fromatter::TAP> which produces TAP output.

=head1 SYNOPSIS

    use Test::More;
    use Test::Tester2;

    # Intercept all the Test::Builder::Event objects produced in the block.
    my $events = intercept {
        ok(1, "pass");
        ok(0, "fail");
        diag("xxx");
    };

    # By Hand
    is($events->[0]->{bool}, 1, "First event passed");

    # With help
    events_are(
        $events,
        ok   => { id => 'a', bool => 1, name => 'pass' },

        ok   => { id => 'b1', bool => 0, name => 'fail',         line => 7, file => 'my_test.t' },
        diag => { id => 'b2', message => qr/Failed test 'fail'/, line => 7, file => 'my_test.t' },

        diag => { id => 'c', message => qr/xxx/ },

        end => 'Name of this test',
    );

    # You can combine the 2:
    events_are(
        intercept { ... },
        ok => { bool => 1 },
        ...
    );

    done_testing;

=head1 EXPORTS

=over 4

=item $events = intercept { ... }

Capture the L<Test::Builder::Event> objects generated by tests inside the block.

=item events_are($events, ...)

Validate the given events.

=item $dump = render_event($event)

This will produce a simplified string of the event data for easy reading. This
is useful in debugging, in fact this is the same string that events_are will
print when there is a mismatch to show you the event.

=item display_event($event)

=item display_events($events)

These will print the render_event string to STDERR.

=back

=head1 INTERCEPTING EVENTS

    my $events = intercept {
        ok(1, "pass");
        ok(0, "fail");
        diag("xxx");
    };

Any events generated within the block will be intercepted and placed inside
the C<$events> array reference.

=head2 EVENT TYPES

All events will be subclasses of L<Test::Builder::Event>

=over 4

=item L<Test::Builder::Event::Ok>

=item L<Test::Builder::Event::Note>

=item L<Test::Builder::Event::Diag>

=item L<Test::Builder::Event::Plan>

=item L<Test::Builder::Event::Finish>

=item L<Test::Builder::Event::Bail>

=item L<Test::Builder::Event::Child>

=back

=head1 VALIDATING EVENTS

    my $events = intercept {
        ok(1, "pass");
        ok(0, "fail");
        diag("xxx");
    };

    events_are(
        $events,
        name => 'Name of the test',                       # Name this overall test
        ok   => { id => 'a', bool => 1, name => 'pass' }, # check an 'ok' with ID 'a'
        ok   => { id => 'b', bool => 0, name => 'fail' }, # check an 'ok' with ID 'b'
        diag => { message => qr/Failed test 'fail'/ },    # check a 'diag' no ID
        diag => { message => qr/xxx/ },                   # check a 'diag' no ID
        'end'                                             # directive 'end'
    );

The first argument to C<events_are()> must be an arrayref containing
L<Test::Builder::Event> objects. Such an arrayref can be produced by
C<intercept { ... }>.

All additional arguments to C<events_are()> must be key value pairs (except
for 'end'). The key must either be a directive, or a event-type optionally
followed by a name. Values for directives are specific to the directives.
Values for event types must always be hashrefs with 0 or more fields to check.

=head2 TYPES AND IDS

Since you can provide many checks, it can be handy to ID them. If you do not
provide an ID then they will be assigned a number in sequence starting at 1.
You can specify an ID by passing in the 'id' parameter.

    ok => { id => 'foo', ... }

This can be very helpful when tracking down the location of a failing check.

=head2 VALIDATING FIELDS

The hashref against which events are checked is composed of keys, and values.
The values may be regular values, which are checked for equality with the
corresponding property of the event object. Alternatively you can provide a
regex to match against, or a coderef that validates it for you.

=over 4

=item field => 'exact_value',

The specified field must exactly match the given value, be it number or string.

=item field => qr/.../,

The specified field must match the regular expression.

=item field => sub { my $val = shift; return $val ? 1 : 0 },

The value from the event will be passed into your coderef as the only
argument. The coderef should return true for valid, false for invalid.

=back

=head2 FIELDS PRESENT FOR ALL EVENT TYPES

=over 4

=item pid

The process ID the event came from.

=item depth

Usually 0, but will be 1 for subtests, 2 for nested subtests, etc.

=item source

Usually $0, but in a subtest it will be the name of the subtest that generated
the event.

=item in_todo

True if the event was generated inside a todo.

=item line

Line number to which failures will be reported.

(This is actually usually undefined for plan and finish)

=item file

File to which failures will be reported

(This is actually usually undefined for plan and finish)

=item package

package to which errors will be reported

(This is actually usually undefined for plan and finish)

=item tool_package

B<Note:> Only present if applicable.

If the event was generated by an L<Test::Builder::Provider>, this will tell
you what package provided the tool.

For example, if the event was provided by C<Test::More::ok()> this will
contain C<'Test::More'>.

=item tool_name

B<Note:> Only present if applicable.

If the event was generated by an L<Test::Builder::Provider>, this will tell
you what the tool was called.

For example, if the event was provided by C<Test::More::ok()> this will
contain C<'ok'>.

=item tap

B<Note:> Only present if applicable.

The TAP string that would be printed by the TAP formatter. This is
particularily useful for diags since it translates filenames into the proper
encoding, the original message however will be untranslated.

=back

=head2 EVENT SPECIFIC FIELDS

=head3 ok

=over 4

=item bool

True if the test passed (or failed but is in todo).

=item real_bool

The actual event of the test, not mangled by todo.

=item name

The name of the test.

=item todo

The todo reason.

=item skip

The reason the test was skipped.

=back

=head3 diag and note

=over 4

=item message

Message for the diag/note.

=back

=head3 plan

=over 4

=item max

Will be a number if a numeric plan was issued.

=item directive

Usually empty, but may be 'skip_all' or 'no_plan'

=item reason

Reason for the directive.

=back

=head3 finish

=over 4

=item tests_run

Number of tests that ran.

=item tests_failed

Number of tests that failed.

=back

=head3 bail

=over 4

=item reason

Reason the test bailed.

=back

=head3 child

=over 4

=item name

Name of the child

=item is_subtest

True if the child was created to start subtests

=item action

Always either 'push' or 'pop'. 'push' when a child is created, 'pop' when a
child is destroyed.

=back

=head2 VALIDATION DIRECTIVES

These provide ways to filter or skip events. They apply as seen, and do not
effect checks before they are seen.

=head3 filter_provider

=over 4

=item filter_provider => ...

=item filter_providers => [...]

=item '!filter_provider' => ...

=item '!filter_providers' => [...]

Filter events so that you only see ones where the tool provider matches one or
more of the conditions specified. Conditions may be a value to match, a regex
to match, or a codref that takes the provider name and validates it returning
either true or false.

Prefixing with '!' will negate the matching, that is only tool providers that
do not match will be checked.

The filter will remove any events that do not match for the remainder of the
checks. Checks before the directive are used will see unfiltered events.

example:

    my $events = intercept {
        Test::More::ok(1, "foo");
        Test::More::ok(1, "bar");
        Test::More::ok(1, "baz");
        Test::Simple::ok(1, "bat");
    };

    events_are(
        $events,
        ok => { name => "foo" },
        ok => { name => "bar" },

        # From this point on, only more 'Test::Simple' events will be checked.
        filter_provider => 'Test::Simple',

        # So it goes right to the Test::Simple event.
        ok => { name => "bat" },
    );

=back

=head3 filter_type

=over 4

=item filter_type => ...

=item filter_types => [...]

=item '!filter_type' => ...

=item '!filter_types' => [...]

Filter events so that you only see ones where the type matches one or more of
the conditions specified. Conditions may be a value to match, a regex to match,
or a codref that takes the provider name and validates it returning either true
or false.

Prefixing with '!' will negate the matching, that is only types that do not
match will be checked.

The filter will remove any events that do not match for the remainder of the
checks. Checks before the directive are used will see unfiltered events.

example:

    my $events = intercept {
        ok(1, "foo");
        diag("XXX");

        ok(1, "bar");
        diag("YYY");

        ok(1, "baz");
        diag("ZZZ");
    };

    events_are(
        $events,
        ok => { name => "foo" },
        diag => { message => 'XXX' },
        ok => { name => "bar" },
        diag => { message => 'YYY' },

        # From this point on, only 'diag' types will be seen
        filter_type => 'diag',

        # So it goes right to the next diag.
        diag => { message => 'ZZZ' },
    );

=back

=head3 skip

=over 4

=item skip => #

=item skip => '*'

The numeric form will skip the next # events.

example:

    my $events = intercept {
        ok(1, "foo");
        diag("XXX");

        ok(1, "bar");
        diag("YYY");

        ok(1, "baz");
        diag("ZZZ");
    };

    events_are(
        $events,
        ok => { name => "foo" },

        skip => 1, # Skips the diag

        ok => { name => "bar" },

        skip => 2, # Skips a diag and an ok

        diag => { message => 'ZZZ' },
    );

When '*' is used as an argument, the checker will skip until a event type
matching the next type to check is found.

example:

    my $events = intercept {
        ok(1, "foo");

        diag("XXX");
        diag("YYY");
        diag("ZZZ");

        ok(1, "bar");
    };

    events_are(
        $events,
        ok => { name => "foo" },

        skip => '*', # Skip until the next 'ok' is found since that is our next check.

        ok => { name => "bar" },
    );

=back

=head3 seek

=over 4

=item seek => $BOOL

When turned on (true), any unexpected events will be skipped. You can turn
this on and off any time.

    my $events = intercept {
        ok(1, "foo");

        diag("XXX");
        diag("YYY");

        ok(1, "bar");
        diag("ZZZ");

        ok(1, "baz");
    };

    events_are(
        $events,

        seek => 1,
        ok => { name => "foo" },
        # The diags are ignored,
        ok => { name => "bar" },

        seek => 0,

        # This will fail because the diag is not ignored anymore.
        ok => { name => "baz" },
    );

=back

=head3 name

=over 4

=item name => "Name of test"

Used to name the test when not using 'end'.

=back

=head3 end

=over 4

=item 'end'

=item end => 'Test Name'

Used to say that there should not be any more events. Without this any events
after your last check are simply ignored. This will generate a failure if any
unchecked events remain.

This is also how you can name the overall test. The default name is 'Got
expected events'.

=back

=head1 SEE ALSO

=over 4

=item L<Test::Tester> *Deprecated*

Deprecated predecessor to this module

=item L<Test::Builder::Tester> *Deprecated*

The original test tester, checks TAP output

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

