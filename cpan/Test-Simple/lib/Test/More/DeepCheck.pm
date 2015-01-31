package Test::More::DeepCheck;
use strict;
use warnings;

use Test::Stream::ArrayBase(
    accessors => [qw/seen/],
);

sub init {
    $_[0]->[SEEN] ||= [{}];
}

my %PAIRS = ( '{' => '}', '[' => ']' );
my $DNE = bless [], 'Does::Not::Exist';

sub is_dne { ref $_[-1] eq ref $DNE }
sub dne { $DNE };

sub preface { "" };

sub format_stack {
    my $self = shift;
    my $start = $self->STACK_START;
    my $end   = @$self - 1;

    my @Stack = @{$self}[$start .. $end];

    my @parts1 = ('     $got');
    my @parts2 = ('$expected');

    my $did_arrow = 0;
    for my $entry (@Stack) {
        next unless $entry;
        my $type = $entry->{type} || '';
        my $idx  = $entry->{idx};
        my $key  = $entry->{key};
        my $wrap = $entry->{wrap};

        if ($type eq 'HASH') {
            unless ($did_arrow) {
                push @parts1 => '->';
                push @parts2 => '->';
                $did_arrow++;
            }
            push @parts1 => "{$idx}";
            push @parts2 => "{$idx}";
        }
        elsif ($type eq 'OBJECT') {
            push @parts1 => '->';
            push @parts2 => '->';
            push @parts1 => "$idx()";
            push @parts2 => "{$idx}";
            $did_arrow = 0;
        }
        elsif ($type eq 'ARRAY') {
            unless ($did_arrow) {
                push @parts1 => '->';
                push @parts2 => '->';
                $did_arrow++;
            }
            push @parts1 => "[$idx]";
            push @parts2 => "[$idx]";
        }
        elsif ($type eq 'REF') {
            unshift @parts1 => '${';
            unshift @parts2 => '${';
            push @parts1 => '}';
            push @parts2 => '}';
        }

        if ($wrap) {
            my $pair = $PAIRS{$wrap};
            unshift @parts1 => $wrap;
            unshift @parts2 => $wrap;
            push @parts1 => $pair;
            push @parts2 => $pair;
        }
    }

    my $error = $Stack[-1]->{error};
    chomp($error) if $error;

    my @vals = @{$Stack[-1]{vals}}[0, 1];
    my @vars = (
        join('', @parts1),
        join('', @parts2),
    );

    my $out = $self->preface;
    for my $idx (0 .. $#vals) {
        my $val = $vals[$idx];
        $vals[$idx] =
              !defined $val ? 'undef'
            : is_dne($val)  ? "Does not exist"
            : ref $val      ? "$val"
            :                 "'$val'";
    }

    $out .= "$vars[0] = $vals[0]\n";
    $out .= "$vars[1] = $vals[1]\n";
    $out .= "$error\n" if $error;

    $out =~ s/^/    /msg;
    return $out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::More::DeepCheck - Base class or is_deeply() and mostly_like()
implementations.

=head1 DESCRIPTION

This is the base class for deep check functions provided by L<Test::More> and
L<Test::MostlyLike>. This class contains all the debugging and diagnostics
code shared betweent he 2 tools.

Most of this was refactored from the original C<is_deeply()> implementation. If
you find any bugs or incompatabilities please report them.

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
