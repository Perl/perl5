use v5.16.0;
use strict;
use warnings;
require 'regen/regen_lib.pl';
use charnames qw(:loose);

my $out_fh = open_new('utf8_strings.h', '>',
		      {style => '*', by => $0,
                      from => "Unicode data"});

print $out_fh <<END;
/* This file contains #defines for various Unicode code points.  The values
 * for the macros are all or portions of the UTF-8 encoding for the code
 * point.  Note that the names all have the suffix "_UTF8".
 *
 * The suffix "_FIRST_BYTE" may be appended to the name if the value is just
 * the first byte of the UTF-8 representation; the value will be a numeric
 * constant.
 *
 * The suffix "_TAIL" is appened if instead it represents all but the first
 * byte.  This, and with no suffix are both string constants */

END

# The data are at the end of this file.  Each line represents one #define.
# Each line begins with either a Unicode character name with the blanks in it
# squeezed out or replaced by underscores; or it may be a hexadecimal code
# point.  In the latter case, the name will be looked-up to use as the name
# of the macro.  In either case, the macro name will have suffixes as
# listed above, and all blanks will be replaced by underscores.
#
# Each line may optionally have one of the following flags on it, separated by
# white space from the initial token.
#   first   indicates that the output is to be of the FIRST_BYTE form
#           described in the comments above that are placed in the file.
#   tail    indicates that the output is of the _TAIL form.
#
# This program is used to make it convenient to create compile time constants
# of UTF-8, and to generate proper EBCDIC as well as ASCII without manually
# having to figure things out.

while ( <DATA> ) {
    chomp;
    unless ($_ =~ m/ ^ ( [^\ ]* )           # Name or code point token
                       (?: [\ ]+ ( .* ) )?  # optional flag
                   /x)
    {
        die "Unexpected syntax at line $.: $_\n";
    }

    my $name_or_cp = $1;
    my $flag = $2;

    my $name;
    my $cp;

    if ($name_or_cp =~ /[^[:xdigit:]]/) {

        # Anything that isn't a hex value must be a name.
        $name = $name_or_cp;
        $cp = charnames::vianame($name =~ s/_/ /gr);
        die "Unknown name '$name' at line $.: $_\n" unless defined $name;
    }
    else {
        $cp = $name_or_cp;
        $name = charnames::viacode("0$cp"); # viacode requires a leading zero
                                            # to be sure that the argument is hex
        die "Unknown code point '$cp' at line $.: $_\n" unless defined $cp;
    }

    $name =~ s/ /_/g;   # The macro name can have no blanks in it

    my $str = join "", map { sprintf "\\x%02X", $_ }
                       unpack("U0C*", pack("U", hex $cp));

    my $suffix = '_UTF8';
    if (! defined $flag) {
        $str = "\"$str\"";  # Will be a string constant
    } elsif ($flag eq 'tail') {
            $str =~ s/\\x..//;  # Remove the first byte
            $suffix .= '_TAIL';
            $str = "\"$str\"";  # Will be a string constant
    }
    elsif ($flag eq 'first') {
        $str =~ s/ \\x ( .. ) .* /$1/x; # Get the two nibbles of the 1st byte
        $suffix .= '_FIRST_BYTE';
        $str = "0x$str";        # Is a numeric constant
    }
    else {
        die "Unknown flag at line $.: $_\n";
    }
    print $out_fh "#define ${name}$suffix $str    /* U+$cp */\n";
}

read_only_bottom_close_and_rename($out_fh);

__DATA__
0300
0301
0308
03B9 tail
03C5 tail
03B9 first
03C5 first
1100
1160
11A8
2010
