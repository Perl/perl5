package Test::Stream::Exporter::Meta;
use strict;
use warnings;

use Test::Stream::PackageUtil;

# Test::Stream::Carp uses this module.
sub croak   { require Carp; goto &Carp::croak }
sub confess { require Carp; goto &Carp::confess }

sub exports { $_[0]->{exports} }
sub default { @{$_[0]->{pdlist}} }
sub all     { @{$_[0]->{polist}} }

sub add {
    my $self = shift;
    my ($name, $ref) = @_;

    confess "Name is mandatory" unless $name;

    confess "$name is already exported"
        if $self->exports->{$name};

    $ref ||= package_sym($self->{package}, $name);

    confess "No reference or package sub found for '$name' in '$self->{package}'"
        unless $ref && ref $ref;

    $self->exports->{$name} = $ref;
    push @{$self->{polist}} => $name;
}

sub add_default {
    my $self = shift;
    my ($name, $ref) = @_;

    $self->add($name, $ref);
    push @{$self->{pdlist}} => $name;

    $self->{default}->{$name} = 1;
}

sub add_bulk {
    my $self = shift;
    for my $name (@_) {
        confess "$name is already exported"
            if $self->exports->{$name};

        my $ref = package_sym($self->{package}, $name)
            || confess "No reference or package sub found for '$name' in '$self->{package}'";

        $self->{exports}->{$name} = $ref;
    }

    push @{$self->{polist}} => @_;
}

sub add_default_bulk {
    my $self = shift;

    for my $name (@_) {
        confess "$name is already exported by $self->{package}"
            if $self->exports->{$name};

        my $ref = package_sym($self->{package}, $name)
            || confess "No reference or package sub found for '$name' in '$self->{package}'";

        $self->{exports}->{$name} = $ref;
        $self->{default}->{$name} = 1;
    }

    push @{$self->{polist}} => @_;
    push @{$self->{pdlist}} => @_;
}

my %EXPORT_META;

sub new {
    my $class = shift;
    my ($pkg) = @_;

    confess "Package is required!"
        unless $pkg;

    unless($EXPORT_META{$pkg}) {
        # Grab anything set in @EXPORT or @EXPORT_OK
        my (@pdlist, @polist);
        {
            no strict 'refs';
            @pdlist = @{"$pkg\::EXPORT"};
            @polist = @{"$pkg\::EXPORT_OK"};

            @{"$pkg\::EXPORT"}    = ();
            @{"$pkg\::EXPORT_OK"} = ();
        }

        my $meta = bless({
            exports => {},
            default => {},
            pdlist  => do { no strict 'refs'; no warnings 'once'; \@{"$pkg\::EXPORT"} },
            polist  => do { no strict 'refs'; no warnings 'once'; \@{"$pkg\::EXPORT_OK"} },
            package => $pkg,
        }, $class);

        $meta->add_default_bulk(@pdlist);
        my %seen = map {$_ => 1} @pdlist;
        $meta->add_bulk(grep {!$seen{$_}++} @polist);

        $EXPORT_META{$pkg} = $meta;
    }

    return $EXPORT_META{$pkg};
}

sub get {
    my $class = shift;
    my ($pkg) = @_;

    confess "Package is required!"
        unless $pkg;

    return $EXPORT_META{$pkg};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::Exporter::Meta - Meta object for exporters.

=head1 DESCRIPTION

L<Test::Stream::Exporter> uses this package to manage exports.

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
