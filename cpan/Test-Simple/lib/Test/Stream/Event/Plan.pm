package Test::Stream::Event::Plan;
use strict;
use warnings;

use Test::Stream::Event(
    accessors  => [qw/max directive reason/],
    ctx_method => '_plan',
);

use Test::Stream::Carp qw/confess/;

my %ALLOWED = (
    'SKIP'    => 1,
    'NO PLAN' => 1,
);

sub init {
    $_[0]->SUPER::init();

    if ($_[0]->[DIRECTIVE]) {
        $_[0]->[DIRECTIVE] = 'SKIP'    if $_[0]->[DIRECTIVE] eq 'skip_all';
        $_[0]->[DIRECTIVE] = 'NO PLAN' if $_[0]->[DIRECTIVE] eq 'no_plan';

        confess "'" . $_[0]->[DIRECTIVE] . "' is not a valid plan directive"
            unless $ALLOWED{$_[0]->[DIRECTIVE]};
    }
    else {
        $_[0]->[DIRECTIVE] = '';
        confess "Cannot have a reason without a directive!"
            if defined $_[0]->[REASON];

        confess "No number of tests specified"
            unless defined $_[0]->[MAX];
    }
}

sub to_tap {
    my $self = shift;

    my $max       = $self->[MAX];
    my $directive = $self->[DIRECTIVE];
    my $reason    = $self->[REASON];

    return if $directive && $directive eq 'NO PLAN';

    my $plan = "1..$max";
    if ($directive) {
        $plan .= " # $directive";
        $plan .= " $reason" if defined $reason;
    }

    return [OUT_STD, "$plan\n"];
}

sub extra_details {
    my $self = shift;
    return (
        max       => $self->max       || 0,
        directive => $self->directive || undef,
        reason    => $self->reason    || undef
    );
}

1;

__END__

=head1 NAME

Test::Stream::Event::Plan - The event of a plan

=encoding utf8

=head1 DESCRIPTION

Plan events are fired off whenever a plan is declared, done testing is called,
or a subtext completes.

=head1 SYNOPSYS

    use Test::Stream::Context qw/context/;
    use Test::Stream::Event::Plan;

    my $ctx = context();
    my $event = $ctx->plan($max, $directive, $reason);

=head1 ACCESSORS

=over 4

=item $num = $plan->max

Get the number of expected tests

=item $dir = $plan->directive

Get the directive (such as TODO, skip_all, or no_plan).

=item $reason = $plan->reason

Get the reason for the directive.

=back

=head1 SUMMARY FIELDS

=over 4

=item max

Number of expected tests.

=item directive

Directive.

=item reason

Reason for directive.

=back

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
