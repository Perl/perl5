package Test::Stream::Event;
use strict;
use warnings;

use Scalar::Util qw/blessed/;
use Test::Stream::Carp qw/confess/;

use Test::Stream::ArrayBase(
    accessors => [qw/context created in_subtest/],
    no_import => 1,
);

sub import {
    my $class = shift;

    # Import should only when event is imported, subclasses do not use this
    # import.
    return if $class ne __PACKAGE__;

    my $caller = caller;
    my (%args) = @_;

    my $ctx_meth = delete $args{ctx_method};

    require Test::Stream::Context;
    require Test::Stream;

    # %args may override base
    Test::Stream::ArrayBase->apply_to($caller, base => $class, %args);
    Test::Stream::Context->register_event($caller, $ctx_meth);
    Test::Stream::Exporter::export_to(
        'Test::Stream',
        $caller,
        qw/OUT_STD OUT_ERR OUT_TODO/,
    );
}

sub init {
    confess("No context provided!") unless $_[0]->[CONTEXT];
}

sub encoding { $_[0]->[CONTEXT]->encoding }

sub extra_details {}

sub summary {
    my $self = shift;
    my $type = blessed $self;
    $type =~ s/^.*:://g;

    my $ctx = $self->context;

    my ($package, $file, $line) = $ctx->call;
    my ($tool_pkg, $tool_name)  = @{$ctx->provider};
    $tool_name =~ s/^\Q$tool_pkg\E:://;

    return (
        type => lc($type),

        $self->extra_details(),

        package => $package || undef,
        file    => $file,
        line    => $line,

        tool_package => $tool_pkg,
        tool_name    => $tool_name,

        encoding => $ctx->encoding || undef,
        in_todo  => $ctx->in_todo  || 0,
        todo     => $ctx->todo     || '',
        pid      => $ctx->pid      || 0,
        skip     => $ctx->skip     || '',
    );
}

sub subevents { }

1;

__END__

=head1 NAME

Test::Stream::Event - Base class for events

=head1 DESCRIPTION

Base class for all event objects that get passed through
L<Test::Stream>.

=head1 SYNOPSYS

    package Test::Stream::Event::MyEvent;
    use strict;
    use warnings;

    # This will make our class an event subclass, add the specified accessors,
    # inject a helper method into the context objects, and add constants for
    # all our fields, and fields we inherit.
    use Test::Stream::Event(
        accessors  => [qw/foo bar baz/],
        ctx_method => 'my_event',
    );

    # Chance to initialize some defaults
    sub init {
        my $self = shift;
        # no other args in @_

        $self->SUPER::init();

        $self->set_foo('xxx') unless defined $self->foo;

        # Events are arrayrefs, all accessors have a constant defined with
        # their index.
        $self->[BAR] ||= "";

        ...
    }

    # If your event produces TAP output it must define this method
    sub to_tap {
        my $self = shift;
        return (
            # Constants are defined at import, all are optional, and may appear
            # any number of times.
            [OUT_STD, $self->foo],
            [OUT_ERR, $self->bar],
            [OUT_STD, $self->baz],
        );
    }

    # This is your hook to add details to the summary fields.
    sub extra_details {
        my $self = shift;

        my @super_details = $self->SUPER::extra_details();

        return (
            @super_details,

            foo => $self->foo || undef,
            bar => $self->bar || '',
            ...
        );
    }

    1;

=head1 IMPORTING

=head2 ARGUMENTS

In addition to the arguments listed here, you may pass in any arguments
accepted by L<Test::Stream::ArrayBase>.

=over 4

=item ctx_method => $NAME

This specifies the name of the helper meth that will be injected into
L<Test::Stream::Context> to help generate your events. If this is not specified
it will use the lowercased last section of your package name.

=item base => $BASE_CLASS

This lets you specify an event class to subclass. B<THIS MUST BE AN EVENT
CLASS>. If you do not specify anything here then C<Test::Stream::Event> will be
used.

=item accessors => \@FIELDS

This lets you define any fields you wish to be present in your class. This is
the only way to define storage for your event. Each field specified will get a
read-only accessor with the same name as the field, as well as a setter
C<set_FIELD()>. You will also get a constant that returns the index of the
field in the classes arrayref. The constant is the name of the field in all
upper-case.

=back

=head2 SUBCLASSING

C<Test::Stream::Event> is added to your @INC for you, unless you specify an
alternative base class, which must itself subclass C<Test::Stream::Event>.

Events B<CAN NOT> use multiple inheritance in most cases. This is mainly
because events are arrayrefs and not hashrefs. Each subclass must add fields as
new indexes after the last index of the parent class.

=head2 CONTEXT HELPER

All events need some initial fields for construction. These fields include a
context, and some other state from construction time. The context object will
get helper methods for all events that fill in these fields for you. It is not
advised to ever construct an event object yourself, you should I<always> use
the context helper method.

=head1 EVENTS ARE ARRAY REFERENCES

Events are an arrayref. Events use L<Test::Stream::ArrayBase> under the hood to
generate accessors, constants, and field indexes. The key thing to take away
from this is that you cannot add attributes on the fly, you B<MUST> use
L<Test::Stream::Event> and/or L<Test::Stream::ArrayBase> to add fields.

If you need a place to store extar generic, and possibly unpredictable, data,
you should add a field and assign a hashref to it, then use that hashref to
store your mixed data.

=head1 METHODS

=over 4

=item $ctx = $e->context

Get a snapshot of the context as it was when this event was generated

=item $call = $e->created

Get the C<caller()> details from when the objects was created. This is usually
the call to the tool that generated the event such as C<Test::More::ok()>.

=item $bool = $e->in_subtest

Check if the event was generated within a subtest.

=item $encoding = $e->encoding

Get the encoding that was in effect when the event was generated

=item @details = $e->extra_details

Get an ordered key/value pair list of summary fields for the event. Override
this to add additional fields.

=item @summary = $e->summary

Get an ordered key/value pair list of summary fields for the event, including
parent class fields. In general you should not override this as it has a useful
(thought not depended upon) order.

=back

=head1 SUMMARY FIELDS

These are the fields that will be present when calling
C<< my %sum = $e->summary >>. Please note that the fields are returned as an
order key+pair list, they can be directly assigned to a hash if desired, or
they can be assigned to an array to preserver the order. The order is as it
appears below, B<NOT> alphabetical.

=over 4

=item type

The name of the event type, typically this is the lowercase form of the last
part of the class name.

=item package

The package that generated this event.

=item file

The file in which the event was generated, and to which errors should be attributed.

=item line

The line number on which the event was generated, and to which errors should be
attributed.

=item tool_package

The package that provided the tool that generated the event (example:
Test::More)

=item tool_name

The name of the sub that produced the event (examples: C<ok()>, C<is()>).

=item encoding

The encoding that should be used when printing the TAP output from this event.

=item in_todo

True if the event was generated while TODO was in effect.

=item todo

The todo message if the event was generated with TODO in effect.

=item pid

The PID in which the event was generated.

=item skip

The skip message if the event was generated via skip.

=back

=encoding utf8

=head1 SOURCE

The source code repository for Test::More can be found at
F<http://github.com/Test-More/test-more/>.

=head1 MAINTAINER

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

The following people have all contributed to the Test-More dist (sorted using
VIM's sort function).

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=item Fergal Daly E<lt>fergal@esatclear.ie>E<gt>

=item Mark Fowler E<lt>mark@twoshortplanks.comE<gt>

=item Michael G Schwern E<lt>schwern@pobox.comE<gt>

=item 唐鳳

=back

=head1 COPYRIGHT

There has been a lot of code migration between modules,
here are all the original copyrights together:

=over 4

=item Test::Stream

=item Test::Stream::Tester

Copyright 2014 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=item Test::Simple

=item Test::More

=item Test::Builder

Originally authored by Michael G Schwern E<lt>schwern@pobox.comE<gt> with much
inspiration from Joshua Pritikin's Test module and lots of help from Barrie
Slaymaker, Tony Bowden, blackstar.co.uk, chromatic, Fergal Daly and the perl-qa
gang.

Idea by Tony Bowden and Paul Johnson, code by Michael G Schwern
E<lt>schwern@pobox.comE<gt>, wardrobe by Calvin Klein.

Copyright 2001-2008 by Michael G Schwern E<lt>schwern@pobox.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=item Test::use::ok

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to L<Test-use-ok>.

This work is published from Taiwan.

L<http://creativecommons.org/publicdomain/zero/1.0>

=item Test::Tester

This module is copyright 2005 Fergal Daly <fergal@esatclear.ie>, some parts
are based on other people's work.

Under the same license as Perl itself

See http://www.perl.com/perl/misc/Artistic.html

=item Test::Builder::Tester

Copyright Mark Fowler E<lt>mark@twoshortplanks.comE<gt> 2002, 2004.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=back
