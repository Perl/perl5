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
    while (readline $perl_h) {
        if ( m/#\s*define\s+HINT_UTF8\s/ ) {
            /(0x[A-Fa-f0-9]+)/ or die "No hex number in:\n\n$_\n ";
            $HintUTF8 = oct $1;
        }
        elsif ( m/#\s*define\s+(HINT_STRICT_REFS|HINT_STRICT_SUBS|HINT_STRICT_VARS)\s/ ) {
            /(0x[A-Fa-f0-9]+)/ or die "No hex number in:\n\n$_\n ";
            $HintStrict |= oct $1;
        }

        m{^#define SAWAMPERSAND_LEFT\s} and last;

    }    
}
die "No HintUTF8 defined in perl.h"          unless $HintUTF8;
die "No HintStrict defined in perl.h"        unless $HintStrict;

my $oneliner = q[use warnings; no warnings qw/experimental/; our $w; BEGIN {$w = ${^WARNING_BITS} } print unpack("H*", $w)];
my $WARNINGS_P7 = qx|$^X -Ilib -e '$oneliner'|;
die q[Fail to generate $WARNINGS_P7] unless $? == 0;


###########################################################################
# Open files to be generated

my ($p5, $p7) = map {
    open_new($_, '>', { by => 'regen/pX.pl' });
} 'lib/p5.pm', 'lib/p7.pm';


###########################################################################
# Generate lib/p5.pm

while (<DATA>) { # header
    last if /^# START P5$/;
}

while (<DATA>) { # variables
    last if /^__VARS__$/;
    print {$p5} $_;
}

print {$p5} <<EOV;

our \$VERSION = '$VERSION';

EOV

while (<DATA>) { # footer
    last if /^# START P7$/ ;
    print $p5 $_ ;
}

read_only_bottom_close_and_rename($p5);

###########################################################################
# Generate lib/p7.pm

# print the header
while (<DATA>) { # header
    last if /^__VARS__$/;
    print $p7 $_ ;
}

my $hints_v7 = sprintf( "0x%08X", $HintUTF8 | $HintStrict ); # convert back to hex

print {$p7} <<EOV;

our \$VERSION = '$VERSION';

our \$p7_hints;
our \$p7_warnings;

BEGIN {
    \$p7_hints    = $hints_v7;
    \$p7_warnings = '$WARNINGS_P7';    
}

EOV

while (<DATA>) {
    print {$p7} $_;
}

read_only_bottom_close_and_rename($p7);


###########################################################################
# Template for p7.pm

__END__

# START P5

package p5;

# This helps hint to perl 7+ what level of compatibility this code has with future versions of perl.
# use p5 should be the first thing in your code. Especially before use strict, warnings, v5.XXX, or feature.

__VARS__

sub _warn_once {
    local $^W = 0;
    *_warn_once = sub{};
    
    warn("This code is being run using Perl $]. It should be updated or may break in Perl 8. See YYY for more information.");
}

BEGIN {
    $] <= 8 or die("This code is incompatible with Perl 8. Please see XXX for more information.");
    _warn_once() if $] > 6;
}

sub import {
    # no warnings;
    ${^WARNING_BITS} = 0;

    # perl  -e'my $h; BEGIN {  $h = $^H } printf("\$^H = 0x%08X\n", $h); ' 
    $^H = 0x0;
    %^H = ();
}

#sub unimport {} # maybe restore?

1;

# START P7

package p7;

# use p7 enables perl 5 code to function in a perl 7-ish way as much as possible compared to the version you are running.
# it also is a hint to both tools and the compiler what the level of compatibility is with future versions of the language.

__VARS__

BEGIN {
    # This code is a proof of concept provided against 5.30. In order for this code to work on other versions of perl
    # we would need to generate it as part of shipping it to CPAN.
    $] >= 5.030 or die("Perl 5.30 is required to use this module.");
}

sub import {

    # use warnings; no warnings qw/experimental/;
    # perl -e'use warnings; no warnings qw/experimental/;  my $w; BEGIN {$w = ${^WARNING_BITS} } print unpack("H*", $w) . "\n"'
    ${^WARNING_BITS} = pack( "H*", $p7_warnings );

    # use strict; use utf8;
    # perl  -MData::Dumper -e'my $h; use strict; use utf8; use feature (qw/bitwise current_sub declared_refs evalbytes fc postderef_qq refaliasing say signatures state switch unicode_eval unicode_strings/); BEGIN {  $h = $^H } printf("\$^H = 0x%08X\n", $h); print Dumper \%^H; '
    $^H |= $p7_hints;

    require feature;
    feature->import(':7.0');
}

1;
