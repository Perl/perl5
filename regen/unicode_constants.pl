use v5.16.0;
use strict;
use warnings;
no warnings 'experimental::regex_sets';
require './regen/regen_lib.pl';
require './regen/charset_translations.pl';
use Unicode::UCD qw(prop_invlist prop_invmap);
use charnames qw(:loose);
binmode(STDERR, ":utf8");

# Set this to 1 temporarily to get on stderr the complete list of paired
# string delimiters this generates.  This list is suitable for plugging into a
# pod.
my $output_lists = 0;

my $out_fh = open_new('unicode_constants.h', '>',
        {style => '*', by => $0,
                      from => "Unicode data"});

print $out_fh <<END;

#ifndef PERL_UNICODE_CONSTANTS_H_   /* Guard against nested #includes */
#define PERL_UNICODE_CONSTANTS_H_   1

/* This file contains #defines for the version of Unicode being used and
 * various Unicode code points.  The values the code point macros expand to
 * are the native Unicode code point, or all or portions of the UTF-8 encoding
 * for the code point.  In the former case, the macro name has the suffix
 * "_NATIVE"; otherwise, the suffix "_UTF8".
 *
 * The macros that have the suffix "_UTF8" may have further suffixes, as
 * follows:
 *  "_FIRST_BYTE" if the value is just the first byte of the UTF-8
 *                representation; the value will be a numeric constant.
 *  "_TAIL"       if instead it represents all but the first byte.  This, and
 *                with no additional suffix are both string constants */

/*
=for apidoc_section \$unicode

=for apidoc AmnU|const char *|BOM_UTF8

This is a macro that evaluates to a string constant of the  UTF-8 bytes that
define the Unicode BYTE ORDER MARK (U+FEFF) for the platform that perl
is compiled on.  This allows code to use a mnemonic for this character that
works on both ASCII and EBCDIC platforms.
S<C<sizeof(BOM_UTF8) - 1>> can be used to get its length in
bytes.

=for apidoc AmnU|const char *|REPLACEMENT_CHARACTER_UTF8

This is a macro that evaluates to a string constant of the  UTF-8 bytes that
define the Unicode REPLACEMENT CHARACTER (U+FFFD) for the platform that perl
is compiled on.  This allows code to use a mnemonic for this character that
works on both ASCII and EBCDIC platforms.
S<C<sizeof(REPLACEMENT_CHARACTER_UTF8) - 1>> can be used to get its length in
bytes.

=cut
*/

END

sub backslash_x_form($$;$) {
    # Output the code point represented by the byte string $bytes as a
    # sequence of \x{} constants.  $bytes should be the UTF-8 for the code
    # point if the final parameter is absent or empty.  Otherwise it should be
    # the Latin1 code point itself.
    #
    # The output is translated into the character set '$charset'.

    my ($bytes, $charset, $non_utf8) = @_;
    if ($non_utf8) {
        die "Must be utf8 if above 255" if $bytes > 255;
        my $a2n = get_a2n($charset);
        return sprintf "\\x%02X", $a2n->[$bytes];
    }
    else {
        return join "", map { sprintf "\\x%02X", ord $_ }
                        split //, cp_2_utfbytes($bytes, $charset);
    }
}


my %opposite_of = ( LEFT => 'RIGHT', RIGHT =>'LEFT' );

my $directional_re = qr/\b(LEFT|RIGHT)\b/;    # Make sure to capture $1

sub format_pairs_line($$) {
    my ($from, $to) = @_;

    # Format a line containing a character pair in preparation
    # for output, suitable for pod.

    my $lhs_name = charnames::viacode($from);
    my $lhs_hex = sprintf "%04X", $from;
    my $rhs_name;
    my $rhs_hex;
    my $name = $lhs_name;

    my $hanging_indent = 26;

    if (defined $to) {
        my $rhs_name = charnames::viacode($to);
        $rhs_hex = sprintf "%04X", $to;

        # Most of the names differ only in LEFT vs RIGHT; some in
        # LESS-THAN vs GREATER-THAN.  It takes less space, and is easier to
        # understand if they are displayed combined.
        if ($name =~ s/$directional_re/$opposite_of{$1}/gr eq $rhs_name) {
            $name =~ s,$directional_re,$1/$opposite_of{$1},g;
        }
        else {  # Otherwise, display them sequentially
            $name .= ",  " . $rhs_name;
        }
    }

    # Handle double-width characters, based on the East Asian Width property.
    # Add an extra space to non-wide ones so things stay vertically aligned.
    my $extra = 0;
    my $output_line = " "   # Indent in case output being used for verbatim
                            # pod
                    . chr $from;
    if (chr($from) =~ /[\p{EA=W}\p{EA=F}]/) {
        $extra++;       # The length() will be shorter than the displayed
                        # width
    }
    else {
        $output_line .= " ";
    }
    if (defined $to) {
        $output_line .= " " . chr $to;
        if (chr($to) =~ /[\p{EA=W}\p{EA=F}]/) {
            $extra++;
        }
        else {
            $output_line .= " ";
        }
    }
    else {
        $output_line .= "   ";
    }

    $output_line .= "   U+$lhs_hex";
    $output_line .= ", U+$rhs_hex" if defined $to;;
    my $cur_len = $extra + length $output_line;
    $output_line .= " " x ($hanging_indent - $cur_len);

    my $max_len = 74;   # Pod formatter will indent 4 spaces
    $cur_len = length $output_line;

    if ($cur_len + length $name <= $max_len) {
        $output_line .= $name;  # It will fit
    }
    else {  # It won't fit.  Append a segment that is unbreakable until would
            # exceed the available width; then start on a new line
            # Doesn't handle the case where the whole segment doesn't fit;
            # this just doesn't come up with the input data.
        while ($name =~ / ( .+? ) \b{lb} /xg) {
            my $segment = $1;
            my $added_length = length $segment;
            if ($cur_len + $added_length > $max_len) {
                $output_line =~ s/ +$//;
                $output_line .= "\n" . " " x $hanging_indent;
                $cur_len = $hanging_indent;
            }

            $output_line .= $segment;
            $cur_len += $added_length;
        }
    }

    return $output_line . "\n";
}

my $version = Unicode::UCD::UnicodeVersion();
my ($major, $dot, $dotdot) = $version =~ / (.*?) \. (.*?) (?: \. (.*) )? $ /x;
$dotdot = 0 unless defined $dotdot;

print $out_fh <<END;
#define UNICODE_MAJOR_VERSION   $major
#define UNICODE_DOT_VERSION     $dot
#define UNICODE_DOT_DOT_VERSION $dotdot

END

# Gather the characters in Unicode that have left/right symmetry suitable for
# paired string delimiters
my %paireds = ( ord '<' =>  ord '>' );     # We don't normally use math ones, but
                                        # this is traditionally included

# This property is the universe of all characters in Unicode which
# are of some import to the Bidirectional Algorithm, and for which there is
# another Unicode character that is a mirror of it.
my ($bmg_invlist, $bmg_invmap, $format, $bmg_default) =
                                            prop_invmap("Bidi_Mirroring_Glyph");

# The current list of characters that Perl considers to be paired
# opening/closing delimiters is quite conservative, consisting of those
# from the above property that other Unicode properties classify as
# opening/closing.

# Find the ones in the bmg list that Unicode thinks are opening ones.
for (my $i = 0; $i < $bmg_invlist->@*; $i++) {
    my $mirror_code_point = $bmg_invmap->[$i];
    next if $mirror_code_point eq $bmg_default;   # Doesn't map to a character.

    my $code_point = $bmg_invlist->[$i];

    # Bidi_Paired_Bracket_Type=Open and General_Category=Open_Punctuation are
    # definitely in the list.  It is language-dependent whether members of
    # General_Category=Initial_Punctuation are considered opening or closing;
    # we take what Unicode considers the more likely scenario.
    if (chr($code_point) =~ /(?[ \p{BPT=Open}
                               | \p{Gc=Open_Punctuation}
                               | \p{Gc=Initial_Punctuation}
                            ])/)
    {
        $paireds{$code_point} = $mirror_code_point;
    }
}

# There are several hundred characters other characters that clearly should be
# mirrors of each other, like LEFTWARDS ARROW and RIGHTWARDS ARROW.  Unicode
# did not bother to classify them as mirrors mostly because they aren't of
# import in the Bidirectional Algorithm.  Most of them are symbols.  These
# are not considered opening/closing by Perl for now.

# The rest of the data are at __DATA__  in this file.

my @data = <DATA>;

foreach my $charset (get_supported_code_pages()) {
    print $out_fh "\n" . get_conditional_compile_line_start($charset);

    my @a2n = @{get_a2n($charset)};

    for ( @data ) {
        chomp;

        # Convert any '#' comments to /* ... */; empty lines and comments are
        # output as blank lines
        if ($_ =~ m/ ^ \s* (?: \# ( .* ) )? $ /x) {
            my $comment_body = $1 // "";
            if ($comment_body ne "") {
                print $out_fh "/* $comment_body */\n";
            }
            else {
                print $out_fh "\n";
            }
            next;
        }

        unless ($_ =~ m/ ^ ( [^\ ]* )           # Name or code point token
                        (?: [\ ]+ ( [^ ]* ) )?  # optional flag
                        (?: [\ ]+ ( .* ) )?  # name if unnamed; flag is required
                    /x)
        {
            die "Unexpected syntax at line $.: $_\n";
        }

        my $name_or_cp = $1;
        my $flag = $2;
        my $desired_name = $3;

        my $name;
        my $cp;
        my $U_cp;   # code point in Unicode (not-native) terms

        if ($name_or_cp =~ /^U\+(.*)/) {
            $U_cp = hex $1;
            $name = charnames::viacode($name_or_cp);
            if (! defined $name) {
                next if $flag =~ /skip_if_undef/;
                die "Unknown code point '$name_or_cp' at line $.: $_\n" unless $desired_name;
                $name = "";
            }
        }
        else {
            $name = $name_or_cp;
            die "Unknown name '$name' at line $.: $_\n" unless defined $name;
            $U_cp = charnames::vianame($name =~ s/_/ /gr);
        }

        $cp = ($U_cp < 256)
            ? $a2n[$U_cp]
            : $U_cp;

        $name = $desired_name if $name eq "" && $desired_name;
        $name =~ s/[- ]/_/g;   # The macro name can have no blanks nor dashes

        my $str;
        my $suffix;
        if (defined $flag && $flag eq 'native') {
            die "Are you sure you want to run this on an above-Latin1 code point?" if $cp > 0xff;
            $suffix = '_NATIVE';
            $str = sprintf "0x%02X", $cp;        # Is a numeric constant
        }
        else {
            $str = backslash_x_form($U_cp, $charset);

            $suffix = '_UTF8';
            if (! defined $flag || $flag =~ /^ string (_skip_if_undef)? $/x) {
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
        }
        printf $out_fh "#   define %s%s  %s    /* U+%04X */\n", $name, $suffix, $str, $U_cp;
    }

    # Now output the strings of opening/closing delimiters.  The Unicode
    # values were earlier entered into %paireds
    my $utf8_opening = "";
    my $utf8_closing = "";
    my $non_utf8_opening = "";
    my $non_utf8_closing = "";
    my $deprecated_if_not_mirrored = "";
    my $non_utf8_deprecated_if_not_mirrored = "";

    for my $from (sort { $a <=> $b } keys %paireds) {
        my $to = $paireds{$from};
        my $utf8_from_backslashed = backslash_x_form($from, $charset);
        my $utf8_to_backslashed   = backslash_x_form($to, $charset);
        my $non_utf8_from_backslashed;
        my $non_utf8_to_backslashed;

        $utf8_opening .= $utf8_from_backslashed;
        $utf8_closing .= $utf8_to_backslashed;

        if ($from < 256) {
            $non_utf8_from_backslashed =
                                  backslash_x_form($from, $charset, 'not_utf8');
            $non_utf8_to_backslashed =
                                  backslash_x_form($to, $charset, 'not_utf8');

            $non_utf8_opening .= $non_utf8_from_backslashed;
            $non_utf8_closing .= $non_utf8_to_backslashed;
        }

        # Only the ASCII range paired delimiters have traditionally been
        # accepted.  Until the feature is considered standard, the non-ASCII
        # opening ones must be deprecated when the feature isn't in effect, so
        # as to warn about behavior that is planned to change.
        if ($from > 127) {
            $deprecated_if_not_mirrored .= $utf8_from_backslashed;
            $non_utf8_deprecated_if_not_mirrored .=
                                    $non_utf8_from_backslashed if $from < 256;
        }

        # The implementing code in toke.c assumes that the byte length of each
        # opening delimiter is the same as its mirrored closing one.  This
        # makes sure of that by checking upon each iteration of the loop.
        if (length $utf8_opening != length $utf8_closing) {
            die "Byte length of representation of '"
              .  charnames::viacode($from)
              . " differs from its mapping '"
              .  charnames::viacode($to)
              .  "'";
        }

        print STDERR format_pairs_line($from, $to) if $output_lists;
    }
    $output_lists = 0;  # Only output in first iteration

    print $out_fh <<~"EOT";

        #   ifdef PERL_IN_TOKE_C
               /* Paired characters for quote-like operators, in UTF-8 */
        #      define EXTRA_OPENING_UTF8_BRACKETS "$utf8_opening"
        #      define EXTRA_CLOSING_UTF8_BRACKETS "$utf8_closing"

               /* And not in UTF-8 */
        #      define EXTRA_OPENING_NON_UTF8_BRACKETS "$non_utf8_opening"
        #      define EXTRA_CLOSING_NON_UTF8_BRACKETS "$non_utf8_closing"

               /* And what's deprecated */
        #      define DEPRECATED_OPENING_UTF8_BRACKETS "$deprecated_if_not_mirrored"
        #      define DEPRECATED_OPENING_NON_UTF8_BRACKETS "$non_utf8_deprecated_if_not_mirrored"
        #   endif
        EOT

    my $max_PRINT_A = 0;
    for my $i (0x20 .. 0x7E) {
        $max_PRINT_A = $a2n[$i] if $a2n[$i] > $max_PRINT_A;
    }
    $max_PRINT_A = sprintf "0x%02X", $max_PRINT_A;
    print $out_fh <<"EOT";

#   ifdef PERL_IN_REGCOMP_C
#     define MAX_PRINT_A  $max_PRINT_A   /* The max code point that isPRINT_A */
#   endif
EOT

    print $out_fh get_conditional_compile_line_end();

}

my $count = 0;
my @other_invlist = prop_invlist("Other");
for (my $i = 0; $i < @other_invlist; $i += 2) {
    $count += ((defined $other_invlist[$i+1])
              ? $other_invlist[$i+1]
              : 0x110000)
              - $other_invlist[$i];
}
$count = 0x110000 - $count;
print $out_fh <<~"EOT";

    /* The number of code points not matching \\pC */
    #ifdef PERL_IN_REGCOMP_C
    #  define NON_OTHER_COUNT  $count
    #endif
    EOT

# If this release has both the CWCM and CWCF properties, find the highest code
# point which changes under any case change.  We can use this to short-circuit
# code
my @cwcm = prop_invlist('CWCM');
if (@cwcm) {
    my @cwcf = prop_invlist('CWCF');
    if (@cwcf) {
        my $max = ($cwcm[-1] < $cwcf[-1])
                  ? $cwcf[-1]
                  : $cwcm[-1];
        $max = sprintf "0x%X", $max - 1;
        print $out_fh <<~"EOS";

            /* The highest code point that has any type of case change */
            #ifdef PERL_IN_UTF8_C
            #  define HIGHEST_CASE_CHANGING_CP  $max
            #endif
            EOS
    }
}

print $out_fh "\n#endif /* PERL_UNICODE_CONSTANTS_H_ */\n";

read_only_bottom_close_and_rename($out_fh);

# DATA FORMAT
#
# Note that any apidoc comments you want in the file need to be added to one
# of the prints above
#
# A blank line is output as-is.
# Comments (lines whose first non-blank is a '#') are converted to C-style,
# though empty comments are converted to blank lines.  Otherwise, each line
# represents one #define, and begins with either a Unicode character name with
# the blanks and dashes in it squeezed out or replaced by underscores; or it
# may be a hexadecimal Unicode code point of the form U+xxxx.  In the latter
# case, the name will be looked-up to use as the name of the macro.  In either
# case, the macro name will have suffixes as listed above, and all blanks and
# dashes will be replaced by underscores.
#
# Each line may optionally have one of the following flags on it, separated by
# white space from the initial token.
#   string  indicates that the output is to be of the string form
#           described in the comments above that are placed in the file.
#   string_skip_ifundef  is the same as 'string', but instead of dying if the
#           code point doesn't exist, the line is just skipped: no output is
#           generated for it
#   first   indicates that the output is to be of the FIRST_BYTE form.
#   tail    indicates that the output is of the _TAIL form.
#   native  indicates that the output is the code point, converted to the
#           platform's native character set if applicable
#
# If the code point has no official name, the desired name may be appended
# after the flag, which will be ignored if there is an official name.
#
# This program is used to make it convenient to create compile time constants
# of UTF-8, and to generate proper EBCDIC as well as ASCII without manually
# having to figure things out.

__DATA__
U+017F string

U+0300 string
U+0307 string

U+1E9E string_skip_if_undef

U+FB05 string
U+FB06 string
U+0130 string
U+0131 string

U+2010 string
BOM first
BOM tail

BOM string

U+FFFD string

U+10FFFF string MAX_UNICODE

NBSP native
NBSP string

DEL native
CR  native
LF  native
VT  native
ESC native
U+00DF native
U+00DF string
U+00E5 native
U+00C5 native
U+00FF native
U+00B5 native
U+00B5 string
