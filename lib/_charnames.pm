# !!!!!!!   INTERNAL PERL USE ONLY   !!!!!!!
# This helper module is for internal use by core Perl only.  This module is
# subject to change or removal at any time without notice.  Don't use it
# directly.  Use the public <charnames> module instead.

package _charnames;
use strict;
use warnings;
use File::Spec;
our $VERSION = '1.28';
use unicore::Name;    # mktables-generated algorithmically-defined names

use bytes ();          # for $bytes::hint_bits
use re "/aa";          # Everything in here should be ASCII

$Carp::Internal{ (__PACKAGE__) } = 1;

# Translate between Unicode character names and their code points.  This is a
# submodule of package <charnames>, used to allow \N{...} to be autoloaded,
# but it was decided not to autoload the various functions in charnames; the
# splitting allows this behavior.
#
# The official names with their code points are stored in a table in
# lib/unicore/Name.pl which is read in as a large string (almost 3/4 Mb in
# Unicode 6.0).  Each code point/name combination is separated by a \n in the
# string.  (Some of the CJK and the Hangul syllable names are determined
# instead algorithmically via subroutines stored instead in
# lib/unicore/Name.pm).  Because of the large size of this table, it isn't
# converted into hashes for faster lookup.
#
# But, user defined aliases are stored in their own hashes, as are Perl
# extensions to the official names.  These are checked first before looking at
# the official table.
#
# Basically, the table is grepped for the input code point (viacode()) or
# name (the other functions), and the corresponding value on the same line is
# returned.  The grepping is done by turning the input into a regular
# expression.  Thus, the same table does double duty, used by both name and
# code point lookup.  (If we were to have hashes, we would need two, one for
# each lookup direction.)
#
# For loose name matching, the logical thing would be to have a table
# with all the ignorable characters squeezed out, and then grep it with the
# similiarly-squeezed input name.  (And this is in fact how the lookups are
# done with the small Perl extension hashes.)  But since we need to be able to
# go from code point to official name, the original table would still need to
# exist.  Due to the large size of the table, it was decided to not read
# another very large string into memory for a second table.  Instead, the
# regular expression of the input name is modified to have optional spaces and
# dashes between characters.  For example, in strict matching, the regular
# expression would be:
#   qr/\tDIGIT ONE$/m
# Under loose matching, the blank would be squeezed out, and the re would be:
#   qr/\tD[- ]?I[- ]?G[- ]?I[- ]?T[- ]?O[- ]?N[- ]?E$/m
# which matches a blank or dash between any characters in the official table.
#
# This is also how script lookup is done.  Basically the re looks like
#   qr/ (?:LATIN|GREEK|CYRILLIC) (?:SMALL )?LETTER $name/
# where $name is the loose or strict regex for the remainder of the name.

# The hashes are stored as utf8 strings.  This makes it easier to deal with
# sequences.  I (khw) also tried making Name.pl utf8, but it slowed things
# down by a factor of 7.  I then tried making Name.pl store the ut8
# equivalents but not calling them utf8.  That led to similar speed as leaving
# it alone, but since that is harder for a human to parse, I left it as-is.

my %system_aliases = (
    # Synonyms for the icky 3.2 names that have parentheses.
    'LINE FEED'             => pack("U", 0x0A), # LINE FEED (LF)
    'FORM FEED'             => pack("U", 0x0C), # FORM FEED (FF)
    'CARRIAGE RETURN'       => pack("U", 0x0D), # CARRIAGE RETURN (CR)
    'NEXT LINE'             => pack("U", 0x85), # NEXT LINE (NEL)

    # Some variant names from Wikipedia
    'SINGLE-SHIFT 2'                => pack("U", 0x8E),
    'SINGLE-SHIFT 3'                => pack("U", 0x8F),
    'PRIVATE USE 1'                 => pack("U", 0x91),
    'PRIVATE USE 2'                 => pack("U", 0x92),
    'START OF PROTECTED AREA'       => pack("U", 0x96),
    'END OF PROTECTED AREA'         => pack("U", 0x97),

    # Convenience.  Standard abbreviations for the controls
    'NUL'           => pack("U", 0x00), # NULL
    'SOH'           => pack("U", 0x01), # START OF HEADING
    'STX'           => pack("U", 0x02), # START OF TEXT
    'ETX'           => pack("U", 0x03), # END OF TEXT
    'EOT'           => pack("U", 0x04), # END OF TRANSMISSION
    'ENQ'           => pack("U", 0x05), # ENQUIRY
    'ACK'           => pack("U", 0x06), # ACKNOWLEDGE
    'BEL'           => pack("U", 0x07), # ALERT; formerly BELL
    'BS'            => pack("U", 0x08), # BACKSPACE
    'HT'            => pack("U", 0x09), # HORIZONTAL TABULATION
    'LF'            => pack("U", 0x0A), # LINE FEED (LF)
    'VT'            => pack("U", 0x0B), # VERTICAL TABULATION
    'FF'            => pack("U", 0x0C), # FORM FEED (FF)
    'CR'            => pack("U", 0x0D), # CARRIAGE RETURN (CR)
    'SO'            => pack("U", 0x0E), # SHIFT OUT
    'SI'            => pack("U", 0x0F), # SHIFT IN
    'DLE'           => pack("U", 0x10), # DATA LINK ESCAPE
    'DC1'           => pack("U", 0x11), # DEVICE CONTROL ONE
    'DC2'           => pack("U", 0x12), # DEVICE CONTROL TWO
    'DC3'           => pack("U", 0x13), # DEVICE CONTROL THREE
    'DC4'           => pack("U", 0x14), # DEVICE CONTROL FOUR
    'NAK'           => pack("U", 0x15), # NEGATIVE ACKNOWLEDGE
    'SYN'           => pack("U", 0x16), # SYNCHRONOUS IDLE
    'ETB'           => pack("U", 0x17), # END OF TRANSMISSION BLOCK
    'CAN'           => pack("U", 0x18), # CANCEL
    'EOM'           => pack("U", 0x19), # END OF MEDIUM
    'SUB'           => pack("U", 0x1A), # SUBSTITUTE
    'ESC'           => pack("U", 0x1B), # ESCAPE
    'FS'            => pack("U", 0x1C), # FILE SEPARATOR
    'GS'            => pack("U", 0x1D), # GROUP SEPARATOR
    'RS'            => pack("U", 0x1E), # RECORD SEPARATOR
    'US'            => pack("U", 0x1F), # UNIT SEPARATOR
    'DEL'           => pack("U", 0x7F), # DELETE
    'BPH'           => pack("U", 0x82), # BREAK PERMITTED HERE
    'NBH'           => pack("U", 0x83), # NO BREAK HERE
    'NEL'           => pack("U", 0x85), # NEXT LINE (NEL)
    'SSA'           => pack("U", 0x86), # START OF SELECTED AREA
    'ESA'           => pack("U", 0x87), # END OF SELECTED AREA
    'HTS'           => pack("U", 0x88), # CHARACTER TABULATION SET
    'HTJ'           => pack("U", 0x89), # CHARACTER TABULATION WITH JUSTIFICATION
    'VTS'           => pack("U", 0x8A), # LINE TABULATION SET
    'PLD'           => pack("U", 0x8B), # PARTIAL LINE FORWARD
    'PLU'           => pack("U", 0x8C), # PARTIAL LINE BACKWARD
    'RI'            => pack("U", 0x8D), # REVERSE LINE FEED
    'SS2'           => pack("U", 0x8E), # SINGLE SHIFT TWO
    'SS3'           => pack("U", 0x8F), # SINGLE SHIFT THREE
    'DCS'           => pack("U", 0x90), # DEVICE CONTROL STRING
    'PU1'           => pack("U", 0x91), # PRIVATE USE ONE
    'PU2'           => pack("U", 0x92), # PRIVATE USE TWO
    'STS'           => pack("U", 0x93), # SET TRANSMIT STATE
    'CCH'           => pack("U", 0x94), # CANCEL CHARACTER
    'MW'            => pack("U", 0x95), # MESSAGE WAITING
    'SPA'           => pack("U", 0x96), # START OF GUARDED AREA
    'EPA'           => pack("U", 0x97), # END OF GUARDED AREA
    'SOS'           => pack("U", 0x98), # START OF STRING
    'SCI'           => pack("U", 0x9A), # SINGLE CHARACTER INTRODUCER
    'CSI'           => pack("U", 0x9B), # CONTROL SEQUENCE INTRODUCER
    'ST'            => pack("U", 0x9C), # STRING TERMINATOR
    'OSC'           => pack("U", 0x9D), # OPERATING SYSTEM COMMAND
    'PM'            => pack("U", 0x9E), # PRIVACY MESSAGE
    'APC'           => pack("U", 0x9F), # APPLICATION PROGRAM COMMAND

    # There are no names for these in the Unicode standard; perhaps should be
    # deprecated, but then again there are no alternative names, so am not
    # deprecating.  And if did, the code would have to change to not recommend
    # an alternative for these.
    'PADDING CHARACTER'                     => pack("U", 0x80),
    'PAD'                                   => pack("U", 0x80),
    'HIGH OCTET PRESET'                     => pack("U", 0x81),
    'HOP'                                   => pack("U", 0x81),
    'INDEX'                                 => pack("U", 0x84),
    'IND'                                   => pack("U", 0x84),
    'SINGLE GRAPHIC CHARACTER INTRODUCER'   => pack("U", 0x99),
    'SGC'                                   => pack("U", 0x99),

    # More convenience.  For further convenience, it is suggested some way of
    # using the NamesList aliases be implemented, but there are ambiguities in
    # NamesList.txt
    'BOM'   => pack("U", 0xFEFF), # BYTE ORDER MARK
    'BYTE ORDER MARK'=> pack("U", 0xFEFF),
    'CGJ'   => pack("U", 0x034F), # COMBINING GRAPHEME JOINER
    'FVS1'  => pack("U", 0x180B), # MONGOLIAN FREE VARIATION SELECTOR ONE
    'FVS2'  => pack("U", 0x180C), # MONGOLIAN FREE VARIATION SELECTOR TWO
    'FVS3'  => pack("U", 0x180D), # MONGOLIAN FREE VARIATION SELECTOR THREE
    'LRE'   => pack("U", 0x202A), # LEFT-TO-RIGHT EMBEDDING
    'LRM'   => pack("U", 0x200E), # LEFT-TO-RIGHT MARK
    'LRO'   => pack("U", 0x202D), # LEFT-TO-RIGHT OVERRIDE
    'MMSP'  => pack("U", 0x205F), # MEDIUM MATHEMATICAL SPACE
    'MVS'   => pack("U", 0x180E), # MONGOLIAN VOWEL SEPARATOR
    'NBSP'  => pack("U", 0x00A0), # NO-BREAK SPACE
    'NNBSP' => pack("U", 0x202F), # NARROW NO-BREAK SPACE
    'PDF'   => pack("U", 0x202C), # POP DIRECTIONAL FORMATTING
    'RLE'   => pack("U", 0x202B), # RIGHT-TO-LEFT EMBEDDING
    'RLM'   => pack("U", 0x200F), # RIGHT-TO-LEFT MARK
    'RLO'   => pack("U", 0x202E), # RIGHT-TO-LEFT OVERRIDE
    'SHY'   => pack("U", 0x00AD), # SOFT HYPHEN
    'VS1'   => pack("U", 0xFE00), # VARIATION SELECTOR-1
    'VS2'   => pack("U", 0xFE01), # VARIATION SELECTOR-2
    'VS3'   => pack("U", 0xFE02), # VARIATION SELECTOR-3
    'VS4'   => pack("U", 0xFE03), # VARIATION SELECTOR-4
    'VS5'   => pack("U", 0xFE04), # VARIATION SELECTOR-5
    'VS6'   => pack("U", 0xFE05), # VARIATION SELECTOR-6
    'VS7'   => pack("U", 0xFE06), # VARIATION SELECTOR-7
    'VS8'   => pack("U", 0xFE07), # VARIATION SELECTOR-8
    'VS9'   => pack("U", 0xFE08), # VARIATION SELECTOR-9
    'VS10'  => pack("U", 0xFE09), # VARIATION SELECTOR-10
    'VS11'  => pack("U", 0xFE0A), # VARIATION SELECTOR-11
    'VS12'  => pack("U", 0xFE0B), # VARIATION SELECTOR-12
    'VS13'  => pack("U", 0xFE0C), # VARIATION SELECTOR-13
    'VS14'  => pack("U", 0xFE0D), # VARIATION SELECTOR-14
    'VS15'  => pack("U", 0xFE0E), # VARIATION SELECTOR-15
    'VS16'  => pack("U", 0xFE0F), # VARIATION SELECTOR-16
    'VS17'  => pack("U", 0xE0100), # VARIATION SELECTOR-17
    'VS18'  => pack("U", 0xE0101), # VARIATION SELECTOR-18
    'VS19'  => pack("U", 0xE0102), # VARIATION SELECTOR-19
    'VS20'  => pack("U", 0xE0103), # VARIATION SELECTOR-20
    'VS21'  => pack("U", 0xE0104), # VARIATION SELECTOR-21
    'VS22'  => pack("U", 0xE0105), # VARIATION SELECTOR-22
    'VS23'  => pack("U", 0xE0106), # VARIATION SELECTOR-23
    'VS24'  => pack("U", 0xE0107), # VARIATION SELECTOR-24
    'VS25'  => pack("U", 0xE0108), # VARIATION SELECTOR-25
    'VS26'  => pack("U", 0xE0109), # VARIATION SELECTOR-26
    'VS27'  => pack("U", 0xE010A), # VARIATION SELECTOR-27
    'VS28'  => pack("U", 0xE010B), # VARIATION SELECTOR-28
    'VS29'  => pack("U", 0xE010C), # VARIATION SELECTOR-29
    'VS30'  => pack("U", 0xE010D), # VARIATION SELECTOR-30
    'VS31'  => pack("U", 0xE010E), # VARIATION SELECTOR-31
    'VS32'  => pack("U", 0xE010F), # VARIATION SELECTOR-32
    'VS33'  => pack("U", 0xE0110), # VARIATION SELECTOR-33
    'VS34'  => pack("U", 0xE0111), # VARIATION SELECTOR-34
    'VS35'  => pack("U", 0xE0112), # VARIATION SELECTOR-35
    'VS36'  => pack("U", 0xE0113), # VARIATION SELECTOR-36
    'VS37'  => pack("U", 0xE0114), # VARIATION SELECTOR-37
    'VS38'  => pack("U", 0xE0115), # VARIATION SELECTOR-38
    'VS39'  => pack("U", 0xE0116), # VARIATION SELECTOR-39
    'VS40'  => pack("U", 0xE0117), # VARIATION SELECTOR-40
    'VS41'  => pack("U", 0xE0118), # VARIATION SELECTOR-41
    'VS42'  => pack("U", 0xE0119), # VARIATION SELECTOR-42
    'VS43'  => pack("U", 0xE011A), # VARIATION SELECTOR-43
    'VS44'  => pack("U", 0xE011B), # VARIATION SELECTOR-44
    'VS45'  => pack("U", 0xE011C), # VARIATION SELECTOR-45
    'VS46'  => pack("U", 0xE011D), # VARIATION SELECTOR-46
    'VS47'  => pack("U", 0xE011E), # VARIATION SELECTOR-47
    'VS48'  => pack("U", 0xE011F), # VARIATION SELECTOR-48
    'VS49'  => pack("U", 0xE0120), # VARIATION SELECTOR-49
    'VS50'  => pack("U", 0xE0121), # VARIATION SELECTOR-50
    'VS51'  => pack("U", 0xE0122), # VARIATION SELECTOR-51
    'VS52'  => pack("U", 0xE0123), # VARIATION SELECTOR-52
    'VS53'  => pack("U", 0xE0124), # VARIATION SELECTOR-53
    'VS54'  => pack("U", 0xE0125), # VARIATION SELECTOR-54
    'VS55'  => pack("U", 0xE0126), # VARIATION SELECTOR-55
    'VS56'  => pack("U", 0xE0127), # VARIATION SELECTOR-56
    'VS57'  => pack("U", 0xE0128), # VARIATION SELECTOR-57
    'VS58'  => pack("U", 0xE0129), # VARIATION SELECTOR-58
    'VS59'  => pack("U", 0xE012A), # VARIATION SELECTOR-59
    'VS60'  => pack("U", 0xE012B), # VARIATION SELECTOR-60
    'VS61'  => pack("U", 0xE012C), # VARIATION SELECTOR-61
    'VS62'  => pack("U", 0xE012D), # VARIATION SELECTOR-62
    'VS63'  => pack("U", 0xE012E), # VARIATION SELECTOR-63
    'VS64'  => pack("U", 0xE012F), # VARIATION SELECTOR-64
    'VS65'  => pack("U", 0xE0130), # VARIATION SELECTOR-65
    'VS66'  => pack("U", 0xE0131), # VARIATION SELECTOR-66
    'VS67'  => pack("U", 0xE0132), # VARIATION SELECTOR-67
    'VS68'  => pack("U", 0xE0133), # VARIATION SELECTOR-68
    'VS69'  => pack("U", 0xE0134), # VARIATION SELECTOR-69
    'VS70'  => pack("U", 0xE0135), # VARIATION SELECTOR-70
    'VS71'  => pack("U", 0xE0136), # VARIATION SELECTOR-71
    'VS72'  => pack("U", 0xE0137), # VARIATION SELECTOR-72
    'VS73'  => pack("U", 0xE0138), # VARIATION SELECTOR-73
    'VS74'  => pack("U", 0xE0139), # VARIATION SELECTOR-74
    'VS75'  => pack("U", 0xE013A), # VARIATION SELECTOR-75
    'VS76'  => pack("U", 0xE013B), # VARIATION SELECTOR-76
    'VS77'  => pack("U", 0xE013C), # VARIATION SELECTOR-77
    'VS78'  => pack("U", 0xE013D), # VARIATION SELECTOR-78
    'VS79'  => pack("U", 0xE013E), # VARIATION SELECTOR-79
    'VS80'  => pack("U", 0xE013F), # VARIATION SELECTOR-80
    'VS81'  => pack("U", 0xE0140), # VARIATION SELECTOR-81
    'VS82'  => pack("U", 0xE0141), # VARIATION SELECTOR-82
    'VS83'  => pack("U", 0xE0142), # VARIATION SELECTOR-83
    'VS84'  => pack("U", 0xE0143), # VARIATION SELECTOR-84
    'VS85'  => pack("U", 0xE0144), # VARIATION SELECTOR-85
    'VS86'  => pack("U", 0xE0145), # VARIATION SELECTOR-86
    'VS87'  => pack("U", 0xE0146), # VARIATION SELECTOR-87
    'VS88'  => pack("U", 0xE0147), # VARIATION SELECTOR-88
    'VS89'  => pack("U", 0xE0148), # VARIATION SELECTOR-89
    'VS90'  => pack("U", 0xE0149), # VARIATION SELECTOR-90
    'VS91'  => pack("U", 0xE014A), # VARIATION SELECTOR-91
    'VS92'  => pack("U", 0xE014B), # VARIATION SELECTOR-92
    'VS93'  => pack("U", 0xE014C), # VARIATION SELECTOR-93
    'VS94'  => pack("U", 0xE014D), # VARIATION SELECTOR-94
    'VS95'  => pack("U", 0xE014E), # VARIATION SELECTOR-95
    'VS96'  => pack("U", 0xE014F), # VARIATION SELECTOR-96
    'VS97'  => pack("U", 0xE0150), # VARIATION SELECTOR-97
    'VS98'  => pack("U", 0xE0151), # VARIATION SELECTOR-98
    'VS99'  => pack("U", 0xE0152), # VARIATION SELECTOR-99
    'VS100' => pack("U", 0xE0153), # VARIATION SELECTOR-100
    'VS101' => pack("U", 0xE0154), # VARIATION SELECTOR-101
    'VS102' => pack("U", 0xE0155), # VARIATION SELECTOR-102
    'VS103' => pack("U", 0xE0156), # VARIATION SELECTOR-103
    'VS104' => pack("U", 0xE0157), # VARIATION SELECTOR-104
    'VS105' => pack("U", 0xE0158), # VARIATION SELECTOR-105
    'VS106' => pack("U", 0xE0159), # VARIATION SELECTOR-106
    'VS107' => pack("U", 0xE015A), # VARIATION SELECTOR-107
    'VS108' => pack("U", 0xE015B), # VARIATION SELECTOR-108
    'VS109' => pack("U", 0xE015C), # VARIATION SELECTOR-109
    'VS110' => pack("U", 0xE015D), # VARIATION SELECTOR-110
    'VS111' => pack("U", 0xE015E), # VARIATION SELECTOR-111
    'VS112' => pack("U", 0xE015F), # VARIATION SELECTOR-112
    'VS113' => pack("U", 0xE0160), # VARIATION SELECTOR-113
    'VS114' => pack("U", 0xE0161), # VARIATION SELECTOR-114
    'VS115' => pack("U", 0xE0162), # VARIATION SELECTOR-115
    'VS116' => pack("U", 0xE0163), # VARIATION SELECTOR-116
    'VS117' => pack("U", 0xE0164), # VARIATION SELECTOR-117
    'VS118' => pack("U", 0xE0165), # VARIATION SELECTOR-118
    'VS119' => pack("U", 0xE0166), # VARIATION SELECTOR-119
    'VS120' => pack("U", 0xE0167), # VARIATION SELECTOR-120
    'VS121' => pack("U", 0xE0168), # VARIATION SELECTOR-121
    'VS122' => pack("U", 0xE0169), # VARIATION SELECTOR-122
    'VS123' => pack("U", 0xE016A), # VARIATION SELECTOR-123
    'VS124' => pack("U", 0xE016B), # VARIATION SELECTOR-124
    'VS125' => pack("U", 0xE016C), # VARIATION SELECTOR-125
    'VS126' => pack("U", 0xE016D), # VARIATION SELECTOR-126
    'VS127' => pack("U", 0xE016E), # VARIATION SELECTOR-127
    'VS128' => pack("U", 0xE016F), # VARIATION SELECTOR-128
    'VS129' => pack("U", 0xE0170), # VARIATION SELECTOR-129
    'VS130' => pack("U", 0xE0171), # VARIATION SELECTOR-130
    'VS131' => pack("U", 0xE0172), # VARIATION SELECTOR-131
    'VS132' => pack("U", 0xE0173), # VARIATION SELECTOR-132
    'VS133' => pack("U", 0xE0174), # VARIATION SELECTOR-133
    'VS134' => pack("U", 0xE0175), # VARIATION SELECTOR-134
    'VS135' => pack("U", 0xE0176), # VARIATION SELECTOR-135
    'VS136' => pack("U", 0xE0177), # VARIATION SELECTOR-136
    'VS137' => pack("U", 0xE0178), # VARIATION SELECTOR-137
    'VS138' => pack("U", 0xE0179), # VARIATION SELECTOR-138
    'VS139' => pack("U", 0xE017A), # VARIATION SELECTOR-139
    'VS140' => pack("U", 0xE017B), # VARIATION SELECTOR-140
    'VS141' => pack("U", 0xE017C), # VARIATION SELECTOR-141
    'VS142' => pack("U", 0xE017D), # VARIATION SELECTOR-142
    'VS143' => pack("U", 0xE017E), # VARIATION SELECTOR-143
    'VS144' => pack("U", 0xE017F), # VARIATION SELECTOR-144
    'VS145' => pack("U", 0xE0180), # VARIATION SELECTOR-145
    'VS146' => pack("U", 0xE0181), # VARIATION SELECTOR-146
    'VS147' => pack("U", 0xE0182), # VARIATION SELECTOR-147
    'VS148' => pack("U", 0xE0183), # VARIATION SELECTOR-148
    'VS149' => pack("U", 0xE0184), # VARIATION SELECTOR-149
    'VS150' => pack("U", 0xE0185), # VARIATION SELECTOR-150
    'VS151' => pack("U", 0xE0186), # VARIATION SELECTOR-151
    'VS152' => pack("U", 0xE0187), # VARIATION SELECTOR-152
    'VS153' => pack("U", 0xE0188), # VARIATION SELECTOR-153
    'VS154' => pack("U", 0xE0189), # VARIATION SELECTOR-154
    'VS155' => pack("U", 0xE018A), # VARIATION SELECTOR-155
    'VS156' => pack("U", 0xE018B), # VARIATION SELECTOR-156
    'VS157' => pack("U", 0xE018C), # VARIATION SELECTOR-157
    'VS158' => pack("U", 0xE018D), # VARIATION SELECTOR-158
    'VS159' => pack("U", 0xE018E), # VARIATION SELECTOR-159
    'VS160' => pack("U", 0xE018F), # VARIATION SELECTOR-160
    'VS161' => pack("U", 0xE0190), # VARIATION SELECTOR-161
    'VS162' => pack("U", 0xE0191), # VARIATION SELECTOR-162
    'VS163' => pack("U", 0xE0192), # VARIATION SELECTOR-163
    'VS164' => pack("U", 0xE0193), # VARIATION SELECTOR-164
    'VS165' => pack("U", 0xE0194), # VARIATION SELECTOR-165
    'VS166' => pack("U", 0xE0195), # VARIATION SELECTOR-166
    'VS167' => pack("U", 0xE0196), # VARIATION SELECTOR-167
    'VS168' => pack("U", 0xE0197), # VARIATION SELECTOR-168
    'VS169' => pack("U", 0xE0198), # VARIATION SELECTOR-169
    'VS170' => pack("U", 0xE0199), # VARIATION SELECTOR-170
    'VS171' => pack("U", 0xE019A), # VARIATION SELECTOR-171
    'VS172' => pack("U", 0xE019B), # VARIATION SELECTOR-172
    'VS173' => pack("U", 0xE019C), # VARIATION SELECTOR-173
    'VS174' => pack("U", 0xE019D), # VARIATION SELECTOR-174
    'VS175' => pack("U", 0xE019E), # VARIATION SELECTOR-175
    'VS176' => pack("U", 0xE019F), # VARIATION SELECTOR-176
    'VS177' => pack("U", 0xE01A0), # VARIATION SELECTOR-177
    'VS178' => pack("U", 0xE01A1), # VARIATION SELECTOR-178
    'VS179' => pack("U", 0xE01A2), # VARIATION SELECTOR-179
    'VS180' => pack("U", 0xE01A3), # VARIATION SELECTOR-180
    'VS181' => pack("U", 0xE01A4), # VARIATION SELECTOR-181
    'VS182' => pack("U", 0xE01A5), # VARIATION SELECTOR-182
    'VS183' => pack("U", 0xE01A6), # VARIATION SELECTOR-183
    'VS184' => pack("U", 0xE01A7), # VARIATION SELECTOR-184
    'VS185' => pack("U", 0xE01A8), # VARIATION SELECTOR-185
    'VS186' => pack("U", 0xE01A9), # VARIATION SELECTOR-186
    'VS187' => pack("U", 0xE01AA), # VARIATION SELECTOR-187
    'VS188' => pack("U", 0xE01AB), # VARIATION SELECTOR-188
    'VS189' => pack("U", 0xE01AC), # VARIATION SELECTOR-189
    'VS190' => pack("U", 0xE01AD), # VARIATION SELECTOR-190
    'VS191' => pack("U", 0xE01AE), # VARIATION SELECTOR-191
    'VS192' => pack("U", 0xE01AF), # VARIATION SELECTOR-192
    'VS193' => pack("U", 0xE01B0), # VARIATION SELECTOR-193
    'VS194' => pack("U", 0xE01B1), # VARIATION SELECTOR-194
    'VS195' => pack("U", 0xE01B2), # VARIATION SELECTOR-195
    'VS196' => pack("U", 0xE01B3), # VARIATION SELECTOR-196
    'VS197' => pack("U", 0xE01B4), # VARIATION SELECTOR-197
    'VS198' => pack("U", 0xE01B5), # VARIATION SELECTOR-198
    'VS199' => pack("U", 0xE01B6), # VARIATION SELECTOR-199
    'VS200' => pack("U", 0xE01B7), # VARIATION SELECTOR-200
    'VS201' => pack("U", 0xE01B8), # VARIATION SELECTOR-201
    'VS202' => pack("U", 0xE01B9), # VARIATION SELECTOR-202
    'VS203' => pack("U", 0xE01BA), # VARIATION SELECTOR-203
    'VS204' => pack("U", 0xE01BB), # VARIATION SELECTOR-204
    'VS205' => pack("U", 0xE01BC), # VARIATION SELECTOR-205
    'VS206' => pack("U", 0xE01BD), # VARIATION SELECTOR-206
    'VS207' => pack("U", 0xE01BE), # VARIATION SELECTOR-207
    'VS208' => pack("U", 0xE01BF), # VARIATION SELECTOR-208
    'VS209' => pack("U", 0xE01C0), # VARIATION SELECTOR-209
    'VS210' => pack("U", 0xE01C1), # VARIATION SELECTOR-210
    'VS211' => pack("U", 0xE01C2), # VARIATION SELECTOR-211
    'VS212' => pack("U", 0xE01C3), # VARIATION SELECTOR-212
    'VS213' => pack("U", 0xE01C4), # VARIATION SELECTOR-213
    'VS214' => pack("U", 0xE01C5), # VARIATION SELECTOR-214
    'VS215' => pack("U", 0xE01C6), # VARIATION SELECTOR-215
    'VS216' => pack("U", 0xE01C7), # VARIATION SELECTOR-216
    'VS217' => pack("U", 0xE01C8), # VARIATION SELECTOR-217
    'VS218' => pack("U", 0xE01C9), # VARIATION SELECTOR-218
    'VS219' => pack("U", 0xE01CA), # VARIATION SELECTOR-219
    'VS220' => pack("U", 0xE01CB), # VARIATION SELECTOR-220
    'VS221' => pack("U", 0xE01CC), # VARIATION SELECTOR-221
    'VS222' => pack("U", 0xE01CD), # VARIATION SELECTOR-222
    'VS223' => pack("U", 0xE01CE), # VARIATION SELECTOR-223
    'VS224' => pack("U", 0xE01CF), # VARIATION SELECTOR-224
    'VS225' => pack("U", 0xE01D0), # VARIATION SELECTOR-225
    'VS226' => pack("U", 0xE01D1), # VARIATION SELECTOR-226
    'VS227' => pack("U", 0xE01D2), # VARIATION SELECTOR-227
    'VS228' => pack("U", 0xE01D3), # VARIATION SELECTOR-228
    'VS229' => pack("U", 0xE01D4), # VARIATION SELECTOR-229
    'VS230' => pack("U", 0xE01D5), # VARIATION SELECTOR-230
    'VS231' => pack("U", 0xE01D6), # VARIATION SELECTOR-231
    'VS232' => pack("U", 0xE01D7), # VARIATION SELECTOR-232
    'VS233' => pack("U", 0xE01D8), # VARIATION SELECTOR-233
    'VS234' => pack("U", 0xE01D9), # VARIATION SELECTOR-234
    'VS235' => pack("U", 0xE01DA), # VARIATION SELECTOR-235
    'VS236' => pack("U", 0xE01DB), # VARIATION SELECTOR-236
    'VS237' => pack("U", 0xE01DC), # VARIATION SELECTOR-237
    'VS238' => pack("U", 0xE01DD), # VARIATION SELECTOR-238
    'VS239' => pack("U", 0xE01DE), # VARIATION SELECTOR-239
    'VS240' => pack("U", 0xE01DF), # VARIATION SELECTOR-240
    'VS241' => pack("U", 0xE01E0), # VARIATION SELECTOR-241
    'VS242' => pack("U", 0xE01E1), # VARIATION SELECTOR-242
    'VS243' => pack("U", 0xE01E2), # VARIATION SELECTOR-243
    'VS244' => pack("U", 0xE01E3), # VARIATION SELECTOR-244
    'VS245' => pack("U", 0xE01E4), # VARIATION SELECTOR-245
    'VS246' => pack("U", 0xE01E5), # VARIATION SELECTOR-246
    'VS247' => pack("U", 0xE01E6), # VARIATION SELECTOR-247
    'VS248' => pack("U", 0xE01E7), # VARIATION SELECTOR-248
    'VS249' => pack("U", 0xE01E8), # VARIATION SELECTOR-249
    'VS250' => pack("U", 0xE01E9), # VARIATION SELECTOR-250
    'VS251' => pack("U", 0xE01EA), # VARIATION SELECTOR-251
    'VS252' => pack("U", 0xE01EB), # VARIATION SELECTOR-252
    'VS253' => pack("U", 0xE01EC), # VARIATION SELECTOR-253
    'VS254' => pack("U", 0xE01ED), # VARIATION SELECTOR-254
    'VS255' => pack("U", 0xE01EE), # VARIATION SELECTOR-255
    'VS256' => pack("U", 0xE01EF), # VARIATION SELECTOR-256
    'WJ'    => pack("U", 0x2060), # WORD JOINER
    'ZWJ'   => pack("U", 0x200D), # ZERO WIDTH JOINER
    'ZWNJ'  => pack("U", 0x200C), # ZERO WIDTH NON-JOINER
    'ZWSP'  => pack("U", 0x200B), # ZERO WIDTH SPACE
);

# These are the aliases above that differ under :loose and :full matching
# because the :full versions have blanks or hyphens in them.
my %loose_system_aliases = (
    'LINEFEED'                         => pack("U", 0x0A),
    'FORMFEED'                         => pack("U", 0x0C),
    'CARRIAGERETURN'                   => pack("U", 0x0D),
    'NEXTLINE'                         => pack("U", 0x85),
    'SINGLESHIFT2'                     => pack("U", 0x8E),
    'SINGLESHIFT3'                     => pack("U", 0x8F),
    'PRIVATEUSE1'                      => pack("U", 0x91),
    'PRIVATEUSE2'                      => pack("U", 0x92),
    'STARTOFPROTECTEDAREA'             => pack("U", 0x96),
    'ENDOFPROTECTEDAREA'               => pack("U", 0x97),
    'PADDINGCHARACTER'                 => pack("U", 0x80),
    'HIGHOCTETPRESET'                  => pack("U", 0x81),
    'SINGLEGRAPHICCHARACTERINTRODUCER' => pack("U", 0x99),
    'BYTEORDERMARK'                    => pack("U", 0xFEFF),
);

my %deprecated_aliases = (
    # Pre-3.2 compatibility (only for the first 256 characters).
    # Use of these gives deprecated message.
    'HORIZONTAL TABULATION' => pack("U", 0x09), # CHARACTER TABULATION
    'VERTICAL TABULATION'   => pack("U", 0x0B), # LINE TABULATION
    'FILE SEPARATOR'        => pack("U", 0x1C), # INFORMATION SEPARATOR FOUR
    'GROUP SEPARATOR'       => pack("U", 0x1D), # INFORMATION SEPARATOR THREE
    'RECORD SEPARATOR'      => pack("U", 0x1E), # INFORMATION SEPARATOR TWO
    'UNIT SEPARATOR'        => pack("U", 0x1F), # INFORMATION SEPARATOR ONE
    'HORIZONTAL TABULATION SET' => pack("U", 0x88), # CHARACTER TABULATION SET
    'HORIZONTAL TABULATION WITH JUSTIFICATION' => pack("U", 0x89), # CHARACTER TABULATION WITH JUSTIFICATION
    'PARTIAL LINE DOWN'       => pack("U", 0x8B), # PARTIAL LINE FORWARD
    'PARTIAL LINE UP'         => pack("U", 0x8C), # PARTIAL LINE BACKWARD
    'VERTICAL TABULATION SET' => pack("U", 0x8A), # LINE TABULATION SET
    'REVERSE INDEX'           => pack("U", 0x8D), # REVERSE LINE FEED

    # Unicode 6.0 co-opted this for U+1F514, so deprecate it for now.
    'BELL'                    => pack("U", 0x07),
);

my %loose_deprecated_aliases = (
    'HORIZONTALTABULATION'                  => pack("U", 0x09),
    'VERTICALTABULATION'                    => pack("U", 0x0B),
    'FILESEPARATOR'                         => pack("U", 0x1C),
    'GROUPSEPARATOR'                        => pack("U", 0x1D),
    'RECORDSEPARATOR'                       => pack("U", 0x1E),
    'UNITSEPARATOR'                         => pack("U", 0x1F),
    'HORIZONTALTABULATIONSET'               => pack("U", 0x88),
    'HORIZONTALTABULATIONWITHJUSTIFICATION' => pack("U", 0x89),
    'PARTIALLINEDOWN'                       => pack("U", 0x8B),
    'PARTIALLINEUP'                         => pack("U", 0x8C),
    'VERTICALTABULATIONSET'                 => pack("U", 0x8A),
    'REVERSEINDEX'                          => pack("U", 0x8D),
);

# These are special cased in :loose matching, differing only in a medial
# hyphen
my $HANGUL_JUNGSEONG_O_E_utf8 = pack("U", 0x1180);
my $HANGUL_JUNGSEONG_OE_utf8 = pack("U", 0x116C);


my $txt;  # The table of official character names

my %full_names_cache; # Holds already-looked-up names, so don't have to
# re-look them up again.  The previous versions of charnames had scoping
# bugs.  For example if we use script A in one scope and find and cache
# what Z resolves to, we can't use that cache in a different scope that
# uses script B instead of A, as Z might be an entirely different letter
# there; or there might be different aliases in effect in different
# scopes, or :short may be in effect or not effect in different scopes,
# or various combinations thereof.  This was solved in this version
# mostly by moving things to %^H.  But some things couldn't be moved
# there.  One of them was the cache of runtime looked-up names, in part
# because %^H is read-only at runtime.  I (khw) don't know why the cache
# was run-time only in the previous versions: perhaps oversight; perhaps
# that compile time looking doesn't happen in a loop so didn't think it
# was worthwhile; perhaps not wanting to make the cache too large.  But
# I decided to make it compile time as well; this could easily be
# changed.
# Anyway, this hash is not scoped, and is added to at runtime.  It
# doesn't have scoping problems because the data in it is restricted to
# official names, which are always invariant, and we only set it and
# look at it at during :full lookups, so is unaffected by any other
# scoped options.  I put this in to maintain parity with the older
# version.  If desired, a %short_names cache could also be made, as well
# as one for each script, say in %script_names_cache, with each key
# being a hash for a script named in a 'use charnames' statement.  I
# decided not to do that for now, just because it's added complication,
# and because I'm just trying to maintain parity, not extend it.

# Like %full_names_cache, but for use when :loose is in effect.  There needs
# to be two caches because :loose may not be in effect for a scope, and a
# loose name could inappropriately be returned when only exact matching is
# called for.
my %loose_names_cache;

# Designed so that test decimal first, and then hex.  Leading zeros
# imply non-decimal, as do non-[0-9]
my $decimal_qr = qr/^[1-9]\d*$/;

# Returns the hex number in $1.
my $hex_qr = qr/^(?:[Uu]\+|0[xX])?([[:xdigit:]]+)$/;

sub croak
{
  require Carp; goto &Carp::croak;
} # croak

sub carp
{
  require Carp; goto &Carp::carp;
} # carp

sub alias (@) # Set up a single alias
{
  my $alias = ref $_[0] ? $_[0] : { @_ };
  foreach my $name (keys %$alias) {
    my $value = $alias->{$name};
    next unless defined $value;          # Omit if screwed up.

    # Is slightly slower to just after this statement see if it is
    # decimal, since we already know it is after having converted from
    # hex, but makes the code easier to maintain, and is called
    # infrequently, only at compile-time
    if ($value !~ $decimal_qr && $value =~ $hex_qr) {
      $value = CORE::hex $1;
    }
    if ($value =~ $decimal_qr) {
        no warnings qw(non_unicode surrogate nonchar); # Allow any non-malformed
        $^H{charnames_ord_aliases}{$name} = pack("U", $value);

        # Use a canonical form.
        $^H{charnames_inverse_ords}{sprintf("%05X", $value)} = $name;
    }
    else {
        # XXX validate syntax when deprecation cycle complete. ie. start
        # with an alpha only, etc.
        $^H{charnames_name_aliases}{$name} = $value;
    }
  }
} # alias

sub not_legal_use_bytes_msg {
  my ($name, $utf8) = @_;
  my $return;

  if (length($utf8) == 1) {
    $return = sprintf("Character 0x%04x with name '%s' is", ord $utf8, $name);
  } else {
    $return = sprintf("String with name '%s' (and ordinals %s) contains character(s)", $name, join(" ", map { sprintf "0x%04X", ord $_ } split(//, $utf8)));
  }
  return $return . " above 0xFF with 'use bytes' in effect";
}

sub alias_file ($)  # Reads a file containing alias definitions
{
  my ($arg, $file) = @_;
  if (-f $arg && File::Spec->file_name_is_absolute ($arg)) {
    $file = $arg;
  }
  elsif ($arg =~ m/^\w+$/) {
    $file = "unicore/${arg}_alias.pl";
  }
  else {
    croak "Charnames alias files can only have identifier characters";
  }
  if (my @alias = do $file) {
    @alias == 1 && !defined $alias[0] and
      croak "$file cannot be used as alias file for charnames";
    @alias % 2 and
      croak "$file did not return a (valid) list of alias pairs";
    alias (@alias);
    return (1);
  }
  0;
} # alias_file

# For use when don't import anything.  This structure must be kept in
# sync with the one that import() fills up.
my %dummy_H = (
                charnames_stringified_names => "",
                charnames_stringified_ords => "",
                charnames_scripts => "",
                charnames_full => 1,
                charnames_loose => 0,
                charnames_short => 0,
              );


sub lookup_name ($$$) {
  my ($name, $wants_ord, $runtime) = @_;

  # Lookup the name or sequence $name in the tables.  If $wants_ord is false,
  # returns the string equivalent of $name; if true, returns the ordinal value
  # instead, but in this case $name must not be a sequence; otherwise undef is
  # returned and a warning raised.  $runtime is 0 if compiletime, otherwise
  # gives the number of stack frames to go back to get the application caller
  # info.
  # If $name is not found, returns undef in runtime with no warning; and in
  # compiletime, the Unicode replacement character, with a warning.

  # It looks first in the aliases, then in the large table of official Unicode
  # names.

  my $utf8;       # The string result
  my $save_input;

  if ($runtime) {

    my $hints_ref = (caller($runtime))[10];

    # If we didn't import anything (which happens with 'use charnames ()',
    # substitute a dummy structure.
    $hints_ref = \%dummy_H if ! defined $hints_ref
                              || (! defined $hints_ref->{charnames_full}
                                  && ! defined $hints_ref->{charnames_loose});

    # At runtime, but currently not at compile time, $^H gets
    # stringified, so un-stringify back to the original data structures.
    # These get thrown away by perl before the next invocation
    # Also fill in the hash with the non-stringified data.
    # N.B.  New fields must be also added to %dummy_H

    %{$^H{charnames_name_aliases}} = split ',',
                                      $hints_ref->{charnames_stringified_names};
    %{$^H{charnames_ord_aliases}} = split ',',
                                      $hints_ref->{charnames_stringified_ords};
    $^H{charnames_scripts} = $hints_ref->{charnames_scripts};
    $^H{charnames_full} = $hints_ref->{charnames_full};
    $^H{charnames_loose} = $hints_ref->{charnames_loose};
    $^H{charnames_short} = $hints_ref->{charnames_short};
  }

  my $loose = $^H{charnames_loose};
  my $lookup_name;  # Input name suitably modified for grepping for in the
                    # table

  # User alias should be checked first or else can't override ours, and if we
  # were to add any, could conflict with theirs.
  if (exists $^H{charnames_ord_aliases}{$name}) {
    $utf8 = $^H{charnames_ord_aliases}{$name};
  }
  elsif (exists $^H{charnames_name_aliases}{$name}) {
    $name = $^H{charnames_name_aliases}{$name};
    $save_input = $lookup_name = $name;  # Cache the result for any error
                                         # message
    # The aliases are documented to not match loosely, so change loose match
    # into full.
    if ($loose) {
      $loose = 0;
      $^H{charnames_full} = 1;
    }
  }
  else {

    # Here, not a user alias.  That means that loose matching may be in
    # effect; will have to modify the input name.
    $lookup_name = $name;
    if ($loose) {
      $lookup_name = uc $lookup_name;

      # Squeeze out all underscores
      $lookup_name =~ s/_//g;

      # Remove all medial hyphens
      $lookup_name =~ s/ (?<= \S  ) - (?= \S  )//gx;

      # Squeeze out all spaces
      $lookup_name =~ s/\s//g;
    }

    # Here, $lookup_name has been modified as necessary for looking in the
    # hashes.  Check the system alias files next.  Most of these aliases are
    # the same for both strict and loose matching.  To save space, the ones
    # which differ are in their own separate hash, which is checked if loose
    # matching is selected and the regular match fails.  To save time, the
    # loose hashes could be expanded to include all aliases, and there would
    # only have to be one check.  But if someone specifies :loose, they are
    # interested in convenience over speed, and the time for this second check
    # is miniscule compared to the rest of the routine.
    if (exists $system_aliases{$lookup_name}) {
      $utf8 = $system_aliases{$lookup_name};
    }
    elsif ($loose && exists $loose_system_aliases{$lookup_name}) {
      $utf8 = $loose_system_aliases{$lookup_name};
    }
    elsif (exists $deprecated_aliases{$lookup_name}) {
      require warnings;
      warnings::warnif('deprecated',
                       "Unicode character name \"$name\" is deprecated, use \""
                       . viacode(ord $deprecated_aliases{$lookup_name})
                       . "\" instead");
      $utf8 = $deprecated_aliases{$lookup_name};
    }
    elsif ($loose && exists $loose_deprecated_aliases{$lookup_name}) {
      require warnings;
      warnings::warnif('deprecated',
                       "Unicode character name \"$name\" is deprecated, use \""
                       . viacode(ord $loose_deprecated_aliases{$lookup_name})
                       . "\" instead");
      $utf8 = $loose_deprecated_aliases{$lookup_name};
    }
  }

  my @off;  # Offsets into table of pattern match begin and end

  # If haven't found it yet...
  if (! defined $utf8) {

    # See if has looked this input up earlier.
    if (! $loose && $^H{charnames_full} && exists $full_names_cache{$name}) {
      $utf8 = $full_names_cache{$name};
    }
    elsif ($loose && exists $loose_names_cache{$name}) {
      $utf8 = $loose_names_cache{$name};
    }
    else { # Here, must do a look-up

      # If full or loose matching succeeded, points to where to cache the
      # result
      my $cache_ref;

      ## Suck in the code/name list as a big string.
      ## Lines look like:
      ##     "00052\tLATIN CAPITAL LETTER R\n"
      # or
      #      "0052 0303\tLATIN CAPITAL LETTER R WITH TILDE\n"
      $txt = do "unicore/Name.pl" unless $txt;

      ## @off will hold the index into the code/name string of the start and
      ## end of the name as we find it.

      ## If :loose, look for a loose match; if :full, look for the name
      ## exactly
      # First, see if the name is one which is algorithmically determinable.
      # The subroutine is included in Name.pl.  The table contained in
      # $txt doesn't contain these.  Experiments show that checking
      # for these before checking for the regular names has no
      # noticeable impact on performance for the regular names, but
      # the other way around slows down finding these immensely.
      # Algorithmically determinables are not placed in the cache because
      # that uses up memory, and finding these again is fast.
      if (($loose || $^H{charnames_full})
          && (defined (my $ord = charnames::name_to_code_point_special($lookup_name, $loose))))
      {
        $utf8 = pack("U", $ord);
      }
      else {

        # Not algorithmically determinable; look up in the table.  The name
        # will be turned into a regex, so quote any meta characters.
        $lookup_name = quotemeta $lookup_name;

        if ($loose) {

          # For loose matches, $lookup_name has already squeezed out the
          # non-essential characters.  We have to add in code to make the
          # squeezed version match the non-squeezed equivalent in the table.
          # The only remaining hyphens are ones that start or end a word in
          # the original.  They have been quoted in $lookup_name so they look
          # like "\-".  Change all other characters except the backslash
          # quotes for any metacharacters, and the final character, so that
          # e.g., COLON gets transformed into: /C[- ]?O[- ]?L[- ]?O[- ]?N/
          $lookup_name =~ s/ (?! \\ -)    # Don't do this to the \- sequence
                             ( [^-\\] )   # Nor the "-" within that sequence,
                                          # nor the "\" that quotes metachars,
                                          # but otherwise put the char into $1
                             (?=.)        # And don't do it for the final char
                           /$1\[- \]?/gx; # And add an optional blank or
                                          # '-' after each $1 char

          # Those remaining hyphens were originally at the beginning or end of
          # a word, so they can match either a blank before or after, but not
          # both.  (Keep in mind that they have been quoted, so are a '\-'
          # sequence)
          $lookup_name =~ s/\\ -/(?:- | -)/xg;
        }

        # Do the lookup in the full table if asked for, and if succeeds
        # save the offsets and set where to cache the result.
        if (($loose || $^H{charnames_full}) && $txt =~ /\t$lookup_name$/m) {
          @off = ($-[0] + 1, $+[0]);    # The 1 is for the tab
          $cache_ref = ($loose) ? \%loose_names_cache : \%full_names_cache;
        }
        else {

          # Here, didn't look for, or didn't find the name.
          # If :short is allowed, see if input is like "greek:Sigma".
          # Keep in mind that $lookup_name has had the metas quoted.
          my $scripts_trie = "";
          my $name_has_uppercase;
          if (($^H{charnames_short})
              && $lookup_name =~ /^ (?: \\ \s)*   # Quoted space
                                    (.+?)         # $1 = the script
                                    (?: \\ \s)*
                                    \\ :          # Quoted colon
                                    (?: \\ \s)*
                                    (.+?)         # $2 = the name
                                    (?: \\ \s)* $
                                  /xs)
          {
              # Even in non-loose matching, the script traditionally has been
              # case insensitve
              $scripts_trie = "\U$1";
              $lookup_name = $2;

              # Use original name to find its input casing, but ignore the
              # script part of that to make the determination.
              $save_input = $name if ! defined $save_input;
              $name =~ s/.*?://;
              $name_has_uppercase = $name =~ /[[:upper:]]/;
          }
          else { # Otherwise look in allowed scripts
              $scripts_trie = $^H{charnames_scripts};

              # Use original name to find its input casing
              $name_has_uppercase = $name =~ /[[:upper:]]/;
          }

          my $case = $name_has_uppercase ? "CAPITAL" : "SMALL";
          if (! $scripts_trie
              || $txt !~
              /\t (?: $scripts_trie ) \ (?:$case\ )? LETTER \ \U$lookup_name $/xm)
          {
            # Here we still don't have it, give up.
            return if $runtime;

            # May have zapped input name, get it again.
            $name = (defined $save_input) ? $save_input : $_[0];
            carp "Unknown charname '$name'";
            return ($wants_ord) ? 0xFFFD : pack("U", 0xFFFD);
          }

          # Here have found the input name in the table.
          @off = ($-[0] + 1, $+[0]);  # The 1 is for the tab
        }

        # Here, the input name has been found; we haven't set up the output,
        # but we know where in the string
        # the name starts.  The string is set up so that for single characters
        # (and not named sequences), the name is preceded immediately by a
        # tab and 5 hex digits for its code, with a \n before those.  Named
        # sequences won't have the 7th preceding character be a \n.
        # (Actually, for the very first entry in the table this isn't strictly
        # true: subtracting 7 will yield -1, and the substr below will
        # therefore yield the very last character in the table, which should
        # also be a \n, so the statement works anyway.)
        if (substr($txt, $off[0] - 7, 1) eq "\n") {
          $utf8 = pack("U", CORE::hex substr($txt, $off[0] - 6, 5));

          # Handle the single loose matching special case, in which two names
          # differ only by a single medial hyphen.  If the original had a
          # hyphen (or more) in the right place, then it is that one.
          $utf8 = $HANGUL_JUNGSEONG_O_E_utf8
                  if $loose
                     && $utf8 eq $HANGUL_JUNGSEONG_OE_utf8
                     && $name =~ m/O \s* - [-\s]* E/ix;
                     # Note that this wouldn't work if there were a 2nd
                     # OE in the name
        }
        else {

          # Here, is a named sequence.  Need to go looking for the beginning,
          # which is just after the \n from the previous entry in the table.
          # The +1 skips past that newline, or, if the rindex() fails, to put
          # us to an offset of zero.
          my $charstart = rindex($txt, "\n", $off[0] - 7) + 1;
          $utf8 = pack("U*", map { CORE::hex }
              split " ", substr($txt, $charstart, $off[0] - $charstart - 1));
        }
      }

      # Cache the input so as to not have to search the large table
      # again, but only if it came from the one search that we cache.
      # (Haven't bothered with the pain of sorting out scoping issues for the
      # scripts searches.)
      $cache_ref->{$name} = $utf8 if defined $cache_ref;
    }
  }


  # Here, have the utf8.  If the return is to be an ord, must be any single
  # character.
  if ($wants_ord) {
    return ord($utf8) if length $utf8 == 1;
  }
  else {

    # Here, wants string output.  If utf8 is acceptable, just return what
    # we've got; otherwise attempt to convert it to non-utf8 and return that.
    my $in_bytes = ($runtime)
                   ? (caller $runtime)[8] & $bytes::hint_bits
                   : $^H & $bytes::hint_bits;
    return $utf8 if (! $in_bytes || utf8::downgrade($utf8, 1)) # The 1 arg
                                                  # means don't die on failure
  }

  # Here, there is an error:  either there are too many characters, or the
  # result string needs to be non-utf8, and at least one character requires
  # utf8.  Prefer any official name over the input one for the error message.
  if (@off) {
    $name = substr($txt, $off[0], $off[1] - $off[0]) if @off;
  }
  else {
    $name = (defined $save_input) ? $save_input : $_[0];
  }

  if ($wants_ord) {
    # Only way to get here in this case is if result too long.  Message
    # assumes that our only caller that requires single char result is
    # vianame.
    carp "charnames::vianame() doesn't handle named sequences ($name).  Use charnames::string_vianame() instead";
    return;
  }

  # Only other possible failure here is from use bytes.
  if ($runtime) {
    carp not_legal_use_bytes_msg($name, $utf8);
    return;
  } else {
    croak not_legal_use_bytes_msg($name, $utf8);
  }

} # lookup_name

sub charnames {

  # For \N{...}.  Looks up the character name and returns the string
  # representation of it.

  # The first 0 arg means wants a string returned; the second that we are in
  # compile time
  return lookup_name($_[0], 0, 0);
}

sub import
{
  shift; ## ignore class name

  if (not @_) {
    carp("'use charnames' needs explicit imports list");
  }
  $^H{charnames} = \&charnames ;
  $^H{charnames_ord_aliases} = {};
  $^H{charnames_name_aliases} = {};
  $^H{charnames_inverse_ords} = {};
  # New fields must be added to %dummy_H, and the code in lookup_name()
  # that copies fields from the runtime structure

  ##
  ## fill %h keys with our @_ args.
  ##
  my ($promote, %h, @args) = (0);
  while (my $arg = shift) {
    if ($arg eq ":alias") {
      @_ or
        croak ":alias needs an argument in charnames";
      my $alias = shift;
      if (ref $alias) {
        ref $alias eq "HASH" or
          croak "Only HASH reference supported as argument to :alias";
        alias ($alias);
        next;
      }
      if ($alias =~ m{:(\w+)$}) {
        $1 eq "full" || $1 eq "loose" || $1 eq "short" and
          croak ":alias cannot use existing pragma :$1 (reversed order?)";
        alias_file ($1) and $promote = 1;
        next;
      }
      alias_file ($alias);
      next;
    }
    if (substr($arg, 0, 1) eq ':'
      and ! ($arg eq ":full" || $arg eq ":short" || $arg eq ":loose"))
    {
      warn "unsupported special '$arg' in charnames";
      next;
    }
    push @args, $arg;
  }

  @args == 0 && $promote and @args = (":full");
  @h{@args} = (1) x @args;

  # Don't leave these undefined as are tested for in lookup_names
  $^H{charnames_full} = delete $h{':full'} || 0;
  $^H{charnames_loose} = delete $h{':loose'} || 0;
  $^H{charnames_short} = delete $h{':short'} || 0;
  my @scripts = map { uc quotemeta } keys %h;

  ##
  ## If utf8? warnings are enabled, and some scripts were given,
  ## see if at least we can find one letter from each script.
  ##
  if (warnings::enabled('utf8') && @scripts) {
    $txt = do "unicore/Name.pl" unless $txt;

    for my $script (@scripts) {
      if (not $txt =~ m/\t$script (?:CAPITAL |SMALL )?LETTER /) {
        warnings::warn('utf8',  "No such script: '$script'");
        $script = quotemeta $script;  # Escape it, for use in the re.
      }
    }
  }

  # %^H gets stringified, so serialize it ourselves so can extract the
  # real data back later.
  $^H{charnames_stringified_ords} = join ",", %{$^H{charnames_ord_aliases}};
  $^H{charnames_stringified_names} = join ",", %{$^H{charnames_name_aliases}};
  $^H{charnames_stringified_inverse_ords} = join ",", %{$^H{charnames_inverse_ords}};

  # Modify the input script names for loose name matching if that is also
  # specified, similar to the way the base character name is prepared.  They
  # don't (currently, and hopefully never will) have dashes.  These go into a
  # regex, and have already been uppercased and quotemeta'd.  Squeeze out all
  # input underscores, blanks, and dashes.  Then convert so will match a blank
  # between any characters.
  if ($^H{charnames_loose}) {
    for (my $i = 0; $i < @scripts; $i++) {
      $scripts[$i] =~ s/[_ -]//g;
      $scripts[$i] =~ s/ ( [^\\] ) (?= . ) /$1\\ ?/gx;
    }
  }

  $^H{charnames_scripts} = join "|", @scripts;  # Stringifiy them as a trie
} # import

# Cache of already looked-up values.  This is set to only contain
# official values, and user aliases can't override them, so scoping is
# not an issue.
my %viacode;

sub viacode {

  # Returns the name of the code point argument

  if (@_ != 1) {
    carp "charnames::viacode() expects one argument";
    return;
  }

  my $arg = shift;

  # This is derived from Unicode::UCD, where it is nearly the same as the
  # function _getcode(), but here it makes sure that even a hex argument
  # has the proper number of leading zeros, which is critical in
  # matching against $txt below
  # Must check if decimal first; see comments at that definition
  my $hex;
  if ($arg =~ $decimal_qr) {
    $hex = sprintf "%05X", $arg;
  } elsif ($arg =~ $hex_qr) {
    # Below is the line that differs from the _getcode() source
    $hex = sprintf "%05X", hex $1;
  } else {
    carp("unexpected arg \"$arg\" to charnames::viacode()");
    return;
  }

  return $viacode{$hex} if exists $viacode{$hex};

  # If the code point is above the max in the table, there's no point
  # looking through it.  Checking the length first is slightly faster
  if (length($hex) <= 5 || CORE::hex($hex) <= 0x10FFFF) {
    $txt = do "unicore/Name.pl" unless $txt;

    # See if the name is algorithmically determinable.
    my $algorithmic = charnames::code_point_to_name_special(CORE::hex $hex);
    if (defined $algorithmic) {
      $viacode{$hex} = $algorithmic;
      return $algorithmic;
    }

    # Return the official name, if exists.  It's unclear to me (khw) at
    # this juncture if it is better to return a user-defined override, so
    # leaving it as is for now.
    if ($txt =~ m/^$hex\t/m) {

        # The name starts with the next character and goes up to the
        # next new-line.  Using capturing parentheses above instead of
        # @+ more than doubles the execution time in Perl 5.13
        $viacode{$hex} = substr($txt, $+[0], index($txt, "\n", $+[0]) - $+[0]);
        return $viacode{$hex};
    }
  }

  # See if there is a user name for it, before giving up completely.
  # First get the scoped aliases, give up if have none.
  my $H_ref = (caller(1))[10];
  return if ! defined $H_ref
            || ! exists $H_ref->{charnames_stringified_inverse_ords};

  my %code_point_aliases = split ',',
                          $H_ref->{charnames_stringified_inverse_ords};
  if (! exists $code_point_aliases{$hex}) {
    if (CORE::hex($hex) > 0x10FFFF) {
        carp "Unicode characters only allocated up to U+10FFFF (you asked for U+$hex)";
    }
    return;
  }

  return $code_point_aliases{$hex};
} # _viacode

1;

# ex: set ts=8 sts=2 sw=2 et:
