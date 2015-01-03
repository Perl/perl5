package Test::Stream::PackageUtil;
use strict;
use warnings;

sub confess { require Carp; goto &Carp::confess }

my @SLOTS = qw/HASH SCALAR ARRAY IO FORMAT CODE/;
my %SLOTS = map {($_ => 1)} @SLOTS;

my %SIGMAP = (
    '&' => 'CODE',
    '%' => 'HASH',
    '$' => 'SCALAR',
    '*' => 'IO',
);

sub import {
    my $caller = caller;
    no strict 'refs';
    *{"$caller\::package_sym"}       = \&package_sym;
    *{"$caller\::package_purge_sym"} = \&package_purge_sym;
    1;
}

sub package_sym {
    my ($pkg, @parts) = @_;
    confess "you must specify a package" unless $pkg;

    my ($slot, $name);

    if (@parts > 1) {
        ($slot, $name) = @parts;
    }
    elsif (@parts) {
        my $sig;
        ($sig, $name) = $parts[0] =~ m/^(\W)?(\w+)$/;
        $slot = $SIGMAP{$sig || '&'};
    }

    confess "you must specify a symbol type" unless $slot;
    confess "you must specify a symbol name" unless $name;

    confess "'$slot' is not a valid symbol type! Valid: " . join(", ", @SLOTS)
        unless $SLOTS{$slot};

    no warnings 'once';
    no strict 'refs';
    return *{"$pkg\::$name"}{$slot};
}

sub package_purge_sym {
    my ($pkg, @pairs) = @_;

    for(my $i = 0; $i < @pairs; $i += 2) {
        my $purge = $pairs[$i];
        my $name  = $pairs[$i + 1];

        confess "'$purge' is not a valid symbol type! Valid: " . join(", ", @SLOTS)
            unless $SLOTS{$purge};

        no strict 'refs';
        local *GLOBCLONE = *{"$pkg\::$name"};
        my $stash = \%{"${pkg}\::"};
        delete $stash->{$name};
        for my $slot (@SLOTS) {
            next if $slot eq $purge;
            *{"$pkg\::$name"} = *GLOBCLONE{$slot} if defined *GLOBCLONE{$slot};
        }
    }
}

1;

__END__

=head1 NAME

Test::Stream::PackageUtil - Utils for manipulating package symbol tables.

=head1 DESCRIPTION

Collection of utilities L<Test::Stream> and friends use to manipulate package
symbol tables. This is primarily useful when trackign things like C<$TODO>
vars. It is also used for exporting and meta-construction of object methods.

=head1 EXPORTS

Both exports are exported by default, you cannot pick and choose. These work
equally well as functions and class-methods. These will not work as object
methods.

=over 4

=item $ref = package_sym($PACKAGE, $SLOT => $NAME)

Get the reference to a symbol in the package. C<$PACKAGE> should be the package
name. C<$SLOT> should be a valid typeglob slot (Supported slots: HASH SCALAR ARRAY
IO FORMAT CODE). C<$NAME> should be the name of the symbol.

=item package_purge_sym($PACKAGE, $SLOT => $NAME, $SLOT2 => $NAME2, ...)

This is used to remove symbols from a package. The first argument, C<$PACKAGE>,
should be the name of the package. The remaining arguments should be key/value
pairs. The key in each pair should be the typeglob slot to clear (Supported
slots: HASH SCALAR ARRAY IO FORMAT CODE). The value in the pair should be the
name of the symbol to remove.

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
