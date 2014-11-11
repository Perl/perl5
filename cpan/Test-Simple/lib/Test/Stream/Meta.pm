package Test::Stream::Meta;
use strict;
use warnings;

use Scalar::Util();
use Test::Stream::Util qw/protect/;

use Test::Stream::ArrayBase(
    accessors => [qw/package encoding modern todo stream/],
);

use Test::Stream::PackageUtil;

use Test::Stream::Exporter qw/import export_to default_exports/;
default_exports qw{ is_tester init_tester };
Test::Stream::Exporter->cleanup();

my %META;

sub snapshot {
    my $self = shift;
    my $class = Scalar::Util::blessed($self);
    return bless [@$self], $class;
}

sub is_tester {
    my $pkg = shift;
    return $META{$pkg};
}

sub init_tester {
    my $pkg = shift;
    $META{$pkg} ||= bless [$pkg, 'legacy', 0, undef], __PACKAGE__;
    return $META{$pkg};
}

1;

__END__

=head1 NAME

Test::Stream::Meta - Meta object for unit test packages.

=head1 DESCRIPTION

This object is used to track metadata for unit tests packages.

=head1 SYNOPSYS

    use Test::Stream::Meta qw/init_tester is_tester/;

    sub import {
        my $class = shift;
        my $caller = caller;

        my $meta = init_tester($caller);
    }

    sub check_stuff {
        my $caller = caller;
        my $meta = is_tester($caller) || return;

        ...
    }

=head1 EXPORTS

=over 4

=item $meta = is_tester($package)

Get the meta object for a specific package, if it has one.

=item $meta = init_tester($package)

Get the meta object for a specific package, or create one.

=back

=head1 METHODS

=over 4

=item $meta_copy = $meta->snapshot

Get a snapshot copy of the metadata. This snapshot will not change when the
original does.

=item $val = $meta->package

=item $val = $meta->encoding

=item $val = $meta->modern

=item $val = $meta->todo

=item $val = $meta->stream

These are various attributes stored on the meta object.

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
