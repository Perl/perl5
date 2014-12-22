package Test::Stream::Toolset;
use strict;
use warnings;

use Test::Stream::Context qw/context/;
use Test::Stream::Meta    qw/is_tester init_tester/;
use Test::Stream::Carp    qw/carp/;

# Preload these so the autoload is not necessary
use Test::Stream::Event::Bail;
use Test::Stream::Event::Diag;
use Test::Stream::Event::Finish;
use Test::Stream::Event::Note;
use Test::Stream::Event::Ok;
use Test::Stream::Event::Plan;
use Test::Stream::Event::Subtest;

use Test::Stream::Exporter qw/import export_to default_exports export/;
default_exports qw/is_tester init_tester context/;

export before_import => sub {
    my $class = shift;
    my ($importer, $list) = @_;

    my $meta = init_tester($importer);

    my $context = context(1);
    my $other   = [];
    my $idx     = 0;

    while ($idx <= $#{$list}) {
        my $item = $list->[$idx++];
        next unless $item;

        if (defined $item and $item eq 'no_diag') {
            Test::Stream->shared->set_no_diag(1);
        }
        elsif ($item eq 'tests') {
            $context->plan($list->[$idx++]);
        }
        elsif ($item eq 'skip_all') {
            $context->plan(0, 'SKIP', $list->[$idx++]);
        }
        elsif ($item eq 'no_plan') {
            $context->plan(0, 'NO PLAN');
        }
        elsif ($item eq 'import') {
            push @$other => @{$list->[$idx++]};
        }
        else {
            carp("Unknown option: $item");
        }
    }

    @$list = @$other;

    return;
};

Test::Stream::Exporter->cleanup();


1;

=head1 NAME

Test::Stream::Toolset - Helper for writing testing tools

=head1 DESCRIPTION

This package provides you with tools to write testing tools. It makes your job
of integrating with L<Test::Builder> and other testing tools much easier.

=head1 SYNOPSYS

    package My::Tester;
    use strict;
    use warnings;
    use Test::Stream::Toolset;

    # Optional, you can just use Exporter if you would like
    use Test::Stream::Exporter;

    # These can come from Test::More, so do not export them by default
    # exports is the Test::Stream::Exporter equivilent to @EXPORT_OK
    exports qw/context done_testing/;

    # These are the API we want to provide, export them by default
    # default_exports is the Test::Stream::Exporter equivilent to @EXPORT
    default_exports qw/my_ok my_note/;

    sub my_ok {
        my ($test, $name) = @_;
        my $ctx = context();

        my @diag;
        push @diag => "'$test' is not true!" unless $test;

        $ctx->ok($test, $name, \@diag);

        return $test ? 1 : 0; # Reduce to a boolean
    }

    sub my_note {
        my ($msg) = @_;
        my $ctx = context();

        $ctx->note($msg);

        return $msg;
    }

    sub done_testing {
        my ($expected) = @_;
        my $ctx = context();
        $ctx->done_testing($expected);
    }

    1;

=head2 TEST-MORE STYLE IMPORT

If you want to be able to pass Test-More arguments such as 'tests', 'skip_all',
and 'no_plan', then use the following:

    package My::Tester;
    use Test::Stream::Exporter;               # Gives us 'import()'
    use Test::Stream::Toolset;                # default exports
    use Test::Stream::Toolset 'before_import' # Test-More style argument support

2 'use' statements were used above for clarity, you can get all the desired
imports at once:

    use Test::Stream::Toolset qw/context init_tester is_tester before_import/;

Then in the test:

    use My::Tester tests => 5;

=head1 EXPORTS

=over 4

=item $ctx = context()

The context() method is used to get the current context, generating one if
necessary. The context object is an instance of L<Test::Stream::Context>, and
is used to generate events suck as C<ok> and C<plan>. The context also knows
what file+line errors should be reported at.

B<WARNING:> Do not directly store the context in anything other than a lexical
variable scoped to your function! As long as there are references to a context
object, C<context()> will return that object. You want the object to be
destroyed at the end of the current scope so that the next function you call
can create a new one. If you need a copy of the context use
C<< $ctx = $ctx->snapshot >>.

=item $meta = init_tester($CLASS)

This method can be used to initialize a class as a test class. In most cases
you do not actually need to use this. If the class is already a tester this
will return the existing meta object.

=item $meta = is_tester($CLASS)

This method can be used to check if an object is a tester. If the object is a
tester it will return the meta object for the tester.

=item before_import

This method is used by C<import()> to parse Test-More style import arguments.
You should never need to run this yourself, it works just by being imported.

B<NOTE:> This will only work if you use Test::Stream::Exporter for your
'import' method.

=back

=head1 GENERATING EVENTS

Events are always generated via a context object. Whenever you load an
L<Test::Stream::Event> class it will add a method to L<Test::Stream::Context>
which can be used to fire off that type of event.

The following event types are all loaded automatically by
L<Test::Stream::Toolset>

=over 4

=item L<Test::Stream::Event::Ok>

    $ctx->ok($bool, $name, \@diag)

Ok events are your actual assertions. You assert that a condition is what you
expect. It is recommended that you name your assertions. You can include an
array of diag objects and/or diagniostics strings that will be printed to
STDERR as comments in the event of a failure.

=item L<Test::Stream::Event::Diag>

    $ctx->diag($MESSAGE)

Produce an independant diagnostics message.

=item L<Test::Stream::Event::Note>

    $ctx->note($MESSAGE)

Produce a note, that is a message that is printed to STDOUT as a comment.

=item L<Test::Stream::Event::Plan>

    $ctx->plan($MAX, $DIRECTIVE, $REASON)

This will set the plan. C<$MAX> should be the number of tests you expect to
run. You may set this to 0 for some plan directives. Examples of directives are
C<'skip_all'> and C<'no_plan'>. Some directives have an additional argument
called C<$REASON> which is aptly named as the reason for the directive.

=item L<Test::Stream::Event::Bail>

    $ctx->bail($MESSAGE)

In the event of a catostrophic failure that should terminate the test file, use
this event to stop everything and print the reason.

=item L<Test::Stream::Event::Finish>

=item L<Test::Stream::Event::Subtest>

These are not intended for public use, but are documented for completeness.

=back

=head1 MODIFYING EVENTS

If you want to make changes to event objects before they are processed, you can
add a munger. The return from a munger is ignored, you must make your changes
directly to the event object.

    Test::Stream->shared->munge(sub {
        my ($stream, $event) = @_;
        ...
    });

B<Note:> every munger is called for every event of every type. There is also no
way to remove a munger. For performance reasons it is best to only ever add one
munger per toolset which dispatches according to events and state.

=head1 LISTENING FOR EVENTS

If you wish to know when an event has occured so that you can do something
after it has been processed, you can add a listener. Your listener will be
called for every single event that occurs, after it has been processed. The
return from a listener is ignored.

    Test::Stream->shared->listen(sub {
        my ($stream, $event) = @_;
        ...
    });

B<Note:> every listener is called for every event of every type. There is also no
way to remove a listener. For performance reasons it is best to only ever add one
listener per toolset which dispatches according to events and state.

=head1 I WANT TO EMBED FUNCTIONALITY FROM TEST::MORE

Take a look at L<Test::More::Tools> which provides an interfaces to the code in
Test::More. You can use that library to produce booleans and diagnostics
without actually triggering events, giving you the opportunity to generate your
own.

=head1 FROM TEST::BUILDER TO TEST::STREAM

This is a list of things people used to override in Test::Builder, and the new
API that should be used instead of overrides.

=over 4

=item ok

=item note

=item diag

=item plan

In the past people would override these methods on L<Test::Builder>.
L<Test::Stream> now provides a proper API for handling all event types.

Anything that used to be done via overrides can now be done using
c<Test::Stream->shared->listen(sub { ... })> and
C<Test::Stream->shared->munge(sub { ... })>, which are documented above.

=item done_testing

In the past people have overriden C<done_testing()> to insert some code between
the last test and the final plan. The proper way to do this now is with a
follow_up hook.

    Test::Stream->shared->follow_up(sub {
        my ($context) = @_;
        ...
    });

There are multiple ways that follow_ups will be triggered, but they are
guarenteed to only be called once, at the end of testing. This will either be
the start of C<done_testing()>, or an END block called after your tests are
complete.

=back

=head1 HOW DO I TEST MY TEST TOOLS?

See L<Test::Stream::Tester>. This library gives you all the tools you need to
test your testing tools.

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
