#!/usr/bin/perl
#
# Regenerate (overwriting only if changed):
#
#    lib/p7.pm
#

BEGIN {
    require './regen/regen_lib.pl';
    push @INC, './lib';
}

use strict;
use warnings;

our $VERSION = '0.00001';

my $HintStrict = 0;
my $HintUTF8;

{
    open my $perl_h, "<", "perl.h" or die "$0 cannot open perl.h: $!";
    while ( readline $perl_h ) {
        if (m/#\s*define\s+HINT_UTF8\s/) {
            /(0x[A-Fa-f0-9]+)/ or die "No hex number in:\n\n$_\n ";
            $HintUTF8 = oct $1;
        }
        elsif (
            m/#\s*define\s+(HINT_STRICT_REFS|HINT_STRICT_SUBS|HINT_STRICT_VARS)\s/
        ) {
            /(0x[A-Fa-f0-9]+)/ or die "No hex number in:\n\n$_\n ";
            $HintStrict |= oct $1;
        }

        m{^#define SAWAMPERSAND_LEFT\s} and last;

    }
}
die "No HintUTF8 defined in perl.h"   unless $HintUTF8;
die "No HintStrict defined in perl.h" unless $HintStrict;

my $miniperl = q[./miniperl];

my $oneliner
    = q[use warnings; no warnings qw/experimental/; our $w; BEGIN {$w = ${^WARNING_BITS} } print unpack("H*", $w)];
-x $miniperl or die "miniperl is required to run $0";
my $WARNINGS_P7
    = qx|$miniperl -Ilib -e '$oneliner'|;    # force to use current miniperl
die q[Fail to generate $WARNINGS_P7] unless $? == 0;

# {
#     open my $warnings_h, '<', 'warnings.h' or die "$0 cannot open warnings.h: $!";
#     while (readline $warnings_h) {
#         next unless m{^#define WARN_EXPERIMENTAL};
#         print $_;
#     }
# }

###########################################################################
# Open files to be generated

my ( $p5, $p7, $p7_h )
    = map { open_new( $_, '>', { by => 'regen/pX.pl' } ); } 'lib/p5.pm',
    'lib/p7.pm', 'perl7.h';

my %VARS = (
    P7_WARNINGS => $WARNINGS_P7,
    VERSION     => qq[our \$VERSION = '$VERSION';],
);

###########################################################################
# Generate lib/p5.pm
{
    while (<DATA>) {    # header
        last if /^# START P5$/;
    }

    while (<DATA>) {    # footer
        last if /^# START P7$/;
        s{~(\w+)~}{$VARS{$1}}g;
        print $p5 $_;
    }

    read_only_bottom_close_and_rename($p5);
}

###########################################################################
# Generate lib/p7.pm
{

    my $hints_strict = sprintf( "0x%08X", $HintStrict );    # convert back to hex
    $VARS{P7_HINTS_STRICT} = $hints_strict;

    my $oneliner = <<'EOS';
my ( $a, $b );
BEGIN { $a = $^H }
use strict;
use feature ":7.0";
BEGIN { $b = $^H };
my $hints = $b - $a;
printf( "0x%08X", $hints );
EOS
    $oneliner =~ s{\n+}{ }g;

    my $hints_v7
        = qx|$miniperl -Ilib -5 '$oneliner'|;  # force to use current miniperl
    die q[Fail to generate hints for 7.0] unless $? == 0;

    chomp $hints_v7;

# ./perl -Ilib -5 'my $a; BEGIN { print "a:$^H\n"; $a = $^H } use strict; use feature ":7.0"; BEGIN { print "b:$^H\n"; $b = $^H }; print "b-a: " .($b - $a)."\n"'

    $VARS{P7_HINTS} = $hints_v7;

    while (<DATA>) {
        last if /^# START P7_H$/;
        s{~(\w+)~}{$VARS{$1}}g;
        print {$p7} $_;
    }

    read_only_bottom_close_and_rename($p7);
}

###########################################################################
# Generate p7.h

#╰─> ./miniperl -Ilib -5 'print( "$^H\n"); BEGIN { require feature; feature->import(":7.0"); print "$^H\n"; map { print "$_ $^H{$_}\n"; } keys %^H; }'
{
    my $oneliner = <<'EOS';
BEGIN { require feature; feature->import(":7.0"); map { print "$_\n" if $^H{$_} } sort keys %^H; }
EOS
    $oneliner =~ s{\n+}{ }g;

    my $features
        = qx|$miniperl -Ilib -5 '$oneliner'|;  # force to use current miniperl
    die q[Fail to generate features list for 7.0] unless $? == 0;

    $VARS{SHA_FEATURE_PM} = 'FIXME';    # add a test to check sanity of file
    $VARS{FEATURES} = '';

    my @feature_list = split( "\n", $features );
    foreach my $name (@feature_list) {
        $name =~ s{^\s+}{};
        $name =~ s{\s+$}{};
        $VARS{FEATURES} .= '$^H{' . $name . '} = 1; ';
    }

    chop $VARS{FEATURES};

    while (<DATA>) {
        s{~(\w+)~}{$VARS{$1}}g;
        print {$p7_h} $_;
    }

    read_only_bottom_close_and_rename($p7_h);
}

###########################################################################
# Template for p7.pm

__END__

# START P5

package p5;

# This helps hint to perl 7+ what level of compatibility this code has with future versions of perl.
# use p5 should be the first thing in your code. Especially before use strict, warnings, v5.XXX, or feature.

~VERSION~

sub _warn_once {
    local $^W;
    local ${^WARNING_BITS};
    BEGIN {
        $^W = 0;
        ${^WARNING_BITS} = 0;
    }

    #*_warn_once = sub{};
    #warn("# This code is being run using Perl $]. It should be updated or may break in Perl 8. See YYY for more information.");
}

BEGIN {
    $] <= 8 or die("This code is incompatible with Perl 8. Please see XXX for more information.");
    _warn_once() if $] > 6;
}

sub import {
    # no warnings;
    ${^WARNING_BITS} = 0;
    $^W = 0;

    # perl  -e'my $h; BEGIN {  $h = $^H } printf("\$^H = 0x%08X\n", $h); '
    $^H = 0x0; # FIXME only reset the features...
    %^H = ();

    return;
}

sub unimport {
    # maybe restore? p7 warnings... and co...
    # we want to restore p7 behavior..
    require p7;
    p7->import;

    return;
}

1;

__END__

=head1 NAME

p7

=head1 SYNOPSIS

use p5;

=head1 DESCRIPTION

Description for p5.

=head1 AUTHOR

atoomic

=cut

# START P7

package p7;

# use p7 enables perl 5 code to function in a perl 7-ish way as much as possible compared to the version you are running.
# it also is a hint to both tools and the compiler what the level of compatibility is with future versions of the language.

~VERSION~

BEGIN {
    # This code is a proof of concept provided against 5.30. In order for this code to work on other versions of perl
    # we would need to generate it as part of shipping it to CPAN.
    $] >= 5.030 or die("Perl 5.30 is required to use this module.");
}

sub import {

    # use warnings; no warnings qw/experimental/;
    # perl -e'use warnings; no warnings qw/experimental/;  my $w; BEGIN {$w = ${^WARNING_BITS} } print unpack("H*", $w) . "\n"'
    ${^WARNING_BITS} = pack( "H*", '~P7_WARNINGS~' );

    # use strict; use utf8;
    # perl  -MData::Dumper -e'my $h; use strict; use utf8; use feature (qw/bitwise current_sub declared_refs evalbytes fc postderef_qq refaliasing say signatures state switch unicode_eval/); BEGIN {  $h = $^H } printf("\$^H = 0x%08X\n", $h); print Dumper \%^H; '
    $^H |= ~P7_HINTS_STRICT~;

    require feature;
    feature->import(':7.0');
}

1;

__END__

=head1 NAME

p7

=head1 SYNOPSIS

use p7;

=head1 DESCRIPTION

Description for p7.

=head1 AUTHOR

atoomic

=cut

# START P7_H

/*    perl7.h
 *
 *    Copyright (C) 2020 by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

#ifndef H_PERL_7
#define H_PERL_7 1

/* this is used by toke.c to setup a Perl7 flavor */
/* #define P7_TOKE_SETUP "use p7;" */

/*
*   GENERATED using lib/feature.pm: ~SHA_FEATURE_PM~
*/

#define P7_TOKE_SETUP "BEGIN { "\
                      "   ${^WARNING_BITS} = pack( 'H*', '555555555555555555555555150001500101' );"\
                      "   $^H |= ~P7_HINTS~;"\
                      "   ~FEATURES~"\
                      "}"

/*

bitwise current_sub declared_refs evalbytes fc postderef_qq refaliasing say signatures state switch unicode_eval
*/

#endif /* Include guard */
