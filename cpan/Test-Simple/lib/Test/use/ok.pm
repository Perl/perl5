package Test::use::ok;
use strict;
use warnings;
use 5.005;

our $VERSION = '1.301001_097';
$VERSION = eval $VERSION;    ## no critic (BuiltinFunctions::ProhibitStringyEval)

use Test::Stream 1.301001 '-internal';

1;
__END__

=encoding utf8

=head1 NAME

Test::use::ok - Alternative to Test::More::use_ok

=head1 SYNOPSIS

    use ok 'Some::Module';

=head1 DESCRIPTION

According to the B<Test::More> documentation, it used to be recommended to run
C<use_ok()> inside a C<BEGIN> block, so functions are exported at compile-time
and prototypes are properly honored.

That is, instead of writing this:

    use_ok( 'Some::Module' );
    use_ok( 'Other::Module' );

One should write this:

    BEGIN { use_ok( 'Some::Module' ); }
    BEGIN { use_ok( 'Other::Module' ); }

However, people often either forget to add C<BEGIN>, or mistakenly group
C<use_ok> with other tests in a single C<BEGIN> block, which can create subtle
differences in execution order.

With this module, simply change all C<use_ok> in test scripts to C<use ok>,
and they will be executed at C<BEGIN> time.  The explicit space after C<use>
makes it clear that this is a single compile-time action.

=head1 SEE ALSO

L<Test::More>

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

=cut
