package Test::Stream::IOSets;
use strict;
use warnings;

use Test::Stream::Util qw/protect/;

init_legacy();

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    $self->reset_legacy;

    return $self;
}

sub init_encoding {
    my $self = shift;
    my ($name, @handles) = @_;

    unless($self->{$name}) {
        my ($out, $fail, $todo);

        if (@handles) {
            ($out, $fail, $todo) = @handles;
        }
        else {
            ($out, $fail) = $self->open_handles();
        }

        binmode($out,  ":encoding($name)");
        binmode($fail, ":encoding($name)");

        $self->{$name} = [$out, $fail, $todo || $out];
    }

    return $self->{$name};
}

my $LEGACY;
sub hard_reset { $LEGACY = undef }
sub init_legacy {
    return if $LEGACY;

    my ($out, $err) = open_handles();

    _copy_io_layers(\*STDOUT, $out);
    _copy_io_layers(\*STDERR, $err);

    _autoflush($out);
    _autoflush($err);

    # LEGACY, BAH!
    # This is necessary to avoid out of sequence writes to the handles
    _autoflush(\*STDOUT);
    _autoflush(\*STDERR);

    $LEGACY = [$out, $err, $out];
}

sub reset_legacy {
    my $self = shift;
    init_legacy() unless $LEGACY;
    my ($out, $fail, $todo) = @$LEGACY;
    $self->{legacy} = [$out, $fail, $todo];
}

sub _copy_io_layers {
    my($src, $dst) = @_;

    protect {
        require PerlIO;
        my @src_layers = PerlIO::get_layers($src);
        _apply_layers($dst, @src_layers) if @src_layers;
    };

    return;
}

sub _autoflush {
    my($fh) = pop;
    my $old_fh = select $fh;
    $| = 1;
    select $old_fh;

    return;
}

sub open_handles {
    open( my $out, ">&STDOUT" ) or die "Can't dup STDOUT:  $!";
    open( my $err, ">&STDERR" ) or die "Can't dup STDERR:  $!";

    _autoflush($out);
    _autoflush($err);

    return ($out, $err);
}

sub _apply_layers {
    my ($fh, @layers) = @_;
    my %seen;
    my @unique = grep { $_ !~ /^(unix|perlio)$/ && !$seen{$_}++ } @layers;
    binmode($fh, join(":", "", "raw", @unique));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::IOSets - Manage sets of IO Handles in specific encodings.

=head1 DESCRIPTION

The module does 2 things, first it emulates the old behavior of
L<Test::Builder> which clones and modifies the STDOUT and STDERR handles. This
legacy behavior can be referenced as C<'legacy'> in place of an encoding. It
also manages multiple clones of the standard file handles which are set to
specific encodings.

=head1 METHODS

In general you should not use this module yourself. If you must use it directly
then there is really only 1 method you should use:

=over 4

=item $ar = $ioset->init_encoding($ENCODING)

=item $ar = $ioset->init_encoding('legacy')

=item $ar = $ioset->init_encoding($NAME, $STDOUT, $STDERR)

C<init_encoding()> will return an arrayref of 3 filehandles, STDOUT, STDERR,
and TODO. TODO is typically just STDOUT again. If the encoding specified has
not yet been initialized it will initialize it. If you provide filehandles they
will be used, but only during initializatin. Typically a filehandle set is
created by cloning STDER and STDOUT and modifying them to use the correct
encoding.

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
