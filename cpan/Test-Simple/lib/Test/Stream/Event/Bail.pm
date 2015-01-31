package Test::Stream::Event::Bail;
use strict;
use warnings;

use Test::Stream::Event(
    accessors => [qw/reason quiet/],
);

sub to_tap {
    my $self = shift;
    return if $self->[QUIET];
    return [
        OUT_STD,
        "Bail out!  " . $self->reason . "\n",
    ];
}

sub extra_details {
    my $self = shift;
    return (
        $self->reason || '',
        $self->quiet  || 0,
    );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::Event::Bail - Bailout!

=head1 DESCRIPTION

The bailout event is generated when things go horribly wrong and you need to
halt all testing in the current file.

=head1 SYNOPSYS

    use Test::Stream::Context qw/context/;
    use Test::Stream::Event::Bail;

    my $ctx = context();
    my $event = $ctx->bail('Stuff is broken');

=head1 METHODS

Inherits from L<Test::Stream::Event>. Also defines:

=over 4

=item $reason = $e->reason

The reason for the bailout.

=item $bool = quiet

Should the bailout be quiet?

=back

=head1 SUMMARY FIELDS

These are the fields that will be present when calling
C<< my %sum = $e->summary >>. Please note that the fields are returned as an
order key+pair list, they can be directly assigned to a hash if desired, or
they can be assigned to an array to preserver the order. The order is as it
appears below, B<NOT> alphabetical.

=over 4

=item reason

Reason for the bailout

=item quiet

Boolean, true if the bailout should be quiet.

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
