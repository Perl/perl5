package Test::Stream::Event::Subtest;
use strict;
use warnings;

use Scalar::Util qw/blessed/;
use Test::Stream::Carp qw/confess/;
use Test::Stream qw/-internal STATE_PASSING STATE_COUNT STATE_FAILED STATE_PLAN/;

use Test::Stream::Event(
    base      => 'Test::Stream::Event::Ok',
    accessors => [qw/state events exception early_return delayed instant/],
);

sub init {
    my $self = shift;
    $self->[EVENTS] ||= [];

    $self->[REAL_BOOL] = $self->[STATE]->[STATE_PASSING] && $self->[STATE]->[STATE_COUNT];

    if ($self->[EXCEPTION]) {
        push @{$self->[DIAG]} => "Exception in subtest '$self->[NAME]': $self->[EXCEPTION]";
        $self->[STATE]->[STATE_PASSING] = 0;
        $self->[BOOL] = 0;
        $self->[REAL_BOOL] = 0;
    }

    if (my $le = $self->[EARLY_RETURN]) {
        my $is_skip = $le->isa('Test::Stream::Event::Plan');
        $is_skip &&= $le->directive;
        $is_skip &&= $le->directive eq 'SKIP';

        if ($is_skip) {
            my $skip = $le->reason || "skip all";
            # Should be a snapshot now:
            $self->[CONTEXT]->set_skip($skip);
            $self->[REAL_BOOL] = 1;
        }
        else { # BAILOUT
            $self->[REAL_BOOL] = 0;
        }
    }

    push @{$self->[DIAG]} => "  No tests run for subtest."
        unless $self->[EXCEPTION] || $self->[EARLY_RETURN] || $self->[STATE]->[STATE_COUNT];

    # Have the 'OK' init run
    $self->SUPER::init();
}

sub subevents {
    return (
        @{$_[0]->[DIAG] || []},
        map { $_, $_->subevents } @{$_[0]->[EVENTS] || []},
    );
}

sub to_tap {
    my $self = shift;
    my ($num) = @_;

    my $delayed = $self->[DELAYED];

    unless($delayed) {
        return if $self->[EXCEPTION]
               && $self->[EXCEPTION]->isa('Test::Stream::Event::Bail');

        return $self->SUPER::to_tap($num);
    }

    # Subtest final result first
    $self->[NAME] =~ s/$/ {/mg;
    my @out = (
        $self->SUPER::to_tap($num),
        $self->_render_events($num),
        [OUT_STD, "}\n"],
    );
    $self->[NAME] =~ s/ \{$//mg;
    return @out;
}

sub _render_events {
    my $self = shift;
    my ($num) = @_;

    my $delayed = $self->[DELAYED];

    my $idx = 0;
    my @out;
    for my $e (@{$self->events}) {
        next unless $e->can('to_tap');
        $idx++ if $e->isa('Test::Stream::Event::Ok');
        push @out => $e->to_tap($idx, $delayed);
    }

    for my $set (@out) {
        $set->[1] =~ s/^/    /mg;
    }

    return @out;
}

sub extra_details {
    my $self = shift;

    my @out = $self->SUPER::extra_details();
    my $plan = $self->[STATE]->[STATE_PLAN];
    my $exception = $self->exception;

    return (
        @out,

        events => $self->events || undef,

        exception => $exception || undef,
        plan      => $plan      || undef,

        passing => $self->[STATE]->[STATE_PASSING],
        count   => $self->[STATE]->[STATE_COUNT],
        failed  => $self->[STATE]->[STATE_FAILED],
    );
}

1;

__END__

=head1 NAME

Test::Stream::Event::Subtest - Subtest event

=head1 DESCRIPTION

This event is used to encapsulate subtests.

=head1 SYNOPSYS

B<YOU PROBABLY DO NOT WANT TO DIRECTLY GENERATE A SUBTEST EVENT>. See the
C<subtest()> function from L<Test::More::Tools> instead.

=head1 INHERITENCE

the C<Test::Stream::Event::Subtest> class inherits from
L<Test::Stream::Event::Ok> and shares all of its methods and fields.

=head1 ACCESSORS

=over 4

=item my $se = $e->events

This returns an arrayref with all events generated during the subtest.

=item my $x = $e->exception

If the subtest was killed by a C<skip_all> or C<BAIL_OUT> the event will be
returned by this accessor.

=back

=head1 SUMMARY FIELDS

C<Test::Stream::Event::Subtest> inherits all of the summary fields from
L<Test::Stream::Event::Ok>.

=over 4

=item events => \@subevents

An arrayref containing all the events generated within the subtest, including
plans.

=item exception => \$plan_or_bail

If the subtest was aborted due to a bail-out or a skip_all, the event that
caused the abort will be here (in addition to the events arrayref.

=item plan => \$plan

The plan event for the subtest, this may be auto-generated.

=item passing => $bool

True if the subtest was passing, false otherwise. This should not be confused
with 'bool' inherited from L<Test::Stream::Event::Ok> which takes TODO into
account.

=item count => $num

Number of tests run inside the subtest.

=item failed => $num

Number of tests that failed inside the subtest.

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
