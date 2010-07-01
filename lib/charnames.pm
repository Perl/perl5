package charnames;
use strict;
use warnings;
use File::Spec;
our $VERSION = '1.11';

use bytes ();		# for $bytes::hint_bits

my %system_aliases = (
                # Icky 3.2 names with parentheses.
                'LINE FEED'             => 0x0A, # LINE FEED (LF)
                'FORM FEED'             => 0x0C, # FORM FEED (FF)
                'CARRIAGE RETURN'       => 0x0D, # CARRIAGE RETURN (CR)
                'NEXT LINE'             => 0x85, # NEXT LINE (NEL)

                # Some variant names from Wikipedia
                'SINGLE-SHIFT 2'                => 0x8E,
                'SINGLE-SHIFT 3'                => 0x8F,
                'PRIVATE USE 1'                 => 0x91,
                'PRIVATE USE 2'                 => 0x92,
                'START OF PROTECTED AREA'       => 0x96,
                'END OF PROTECTED AREA'         => 0x97,

                # Convenience.  Standard abbreviations for the controls
                'NUL'           => 0x00, # NULL
                'SOH'           => 0x01, # START OF HEADING
                'STX'           => 0x02, # START OF TEXT
                'ETX'           => 0x03, # END OF TEXT
                'EOT'           => 0x04, # END OF TRANSMISSION
                'ENQ'           => 0x05, # ENQUIRY
                'ACK'           => 0x06, # ACKNOWLEDGE
                'BEL'           => 0x07, # BELL
                'BS'            => 0x08, # BACKSPACE
                'HT'            => 0x09, # HORIZONTAL TABULATION
                'LF'            => 0x0A, # LINE FEED (LF)
                'VT'            => 0x0B, # VERTICAL TABULATION
                'FF'            => 0x0C, # FORM FEED (FF)
                'CR'            => 0x0D, # CARRIAGE RETURN (CR)
                'SO'            => 0x0E, # SHIFT OUT
                'SI'            => 0x0F, # SHIFT IN
                'DLE'           => 0x10, # DATA LINK ESCAPE
                'DC1'           => 0x11, # DEVICE CONTROL ONE
                'DC2'           => 0x12, # DEVICE CONTROL TWO
                'DC3'           => 0x13, # DEVICE CONTROL THREE
                'DC4'           => 0x14, # DEVICE CONTROL FOUR
                'NAK'           => 0x15, # NEGATIVE ACKNOWLEDGE
                'SYN'           => 0x16, # SYNCHRONOUS IDLE
                'ETB'           => 0x17, # END OF TRANSMISSION BLOCK
                'CAN'           => 0x18, # CANCEL
                'EOM'           => 0x19, # END OF MEDIUM
                'SUB'           => 0x1A, # SUBSTITUTE
                'ESC'           => 0x1B, # ESCAPE
                'FS'            => 0x1C, # FILE SEPARATOR
                'GS'            => 0x1D, # GROUP SEPARATOR
                'RS'            => 0x1E, # RECORD SEPARATOR
                'US'            => 0x1F, # UNIT SEPARATOR
                'DEL'           => 0x7F, # DELETE
                'BPH'           => 0x82, # BREAK PERMITTED HERE
                'NBH'           => 0x83, # NO BREAK HERE
                'NEL'           => 0x85, # NEXT LINE (NEL)
                'SSA'           => 0x86, # START OF SELECTED AREA
                'ESA'           => 0x87, # END OF SELECTED AREA
                'HTS'           => 0x88, # CHARACTER TABULATION SET
                'HTJ'           => 0x89, # CHARACTER TABULATION WITH JUSTIFICATION
                'VTS'           => 0x8A, # LINE TABULATION SET
                'PLD'           => 0x8B, # PARTIAL LINE FORWARD
                'PLU'           => 0x8C, # PARTIAL LINE BACKWARD
                'RI '           => 0x8D, # REVERSE LINE FEED
                'SS2'           => 0x8E, # SINGLE SHIFT TWO
                'SS3'           => 0x8F, # SINGLE SHIFT THREE
                'DCS'           => 0x90, # DEVICE CONTROL STRING
                'PU1'           => 0x91, # PRIVATE USE ONE
                'PU2'           => 0x92, # PRIVATE USE TWO
                'STS'           => 0x93, # SET TRANSMIT STATE
                'CCH'           => 0x94, # CANCEL CHARACTER
                'MW '           => 0x95, # MESSAGE WAITING
                'SPA'           => 0x96, # START OF GUARDED AREA
                'EPA'           => 0x97, # END OF GUARDED AREA
                'SOS'           => 0x98, # START OF STRING
                'SCI'           => 0x9A, # SINGLE CHARACTER INTRODUCER
                'CSI'           => 0x9B, # CONTROL SEQUENCE INTRODUCER
                'ST '           => 0x9C, # STRING TERMINATOR
                'OSC'           => 0x9D, # OPERATING SYSTEM COMMAND
                'PM '           => 0x9E, # PRIVACY MESSAGE
                'APC'           => 0x9F, # APPLICATION PROGRAM COMMAND

                # There are no names for these in the Unicode standard;
                # perhaps should be deprecated, but then again there are
                # no alternative names, so am not deprecating.  And if
                # did, the code would have to change to not recommend an
                # alternative for these.
                'PADDING CHARACTER'                     => 0x80,
                'PAD'                                   => 0x80,
                'HIGH OCTET PRESET'                     => 0x81,
                'HOP'                                   => 0x81,
                'INDEX'                                 => 0x84,
                'IND'                                   => 0x84,
                'SINGLE GRAPHIC CHARACTER INTRODUCER'   => 0x99,
                'SGC'                                   => 0x99,

                # More convenience.  For further convenience,
                # it is suggested some way of using the NamesList
                # aliases be implemented, but there are ambiguities in
                # NamesList.txt
                'BOM'   => 0xFEFF, # BYTE ORDER MARK
                'BYTE ORDER MARK'=> 0xFEFF,
                'CGJ'   => 0x034F, # COMBINING GRAPHEME JOINER
                'FVS1'  => 0x180B, # MONGOLIAN FREE VARIATION SELECTOR ONE
                'FVS2'  => 0x180C, # MONGOLIAN FREE VARIATION SELECTOR TWO
                'FVS3'  => 0x180D, # MONGOLIAN FREE VARIATION SELECTOR THREE
                'LRE'   => 0x202A, # LEFT-TO-RIGHT EMBEDDING
                'LRM'   => 0x200E, # LEFT-TO-RIGHT MARK
                'LRO'   => 0x202D, # LEFT-TO-RIGHT OVERRIDE
                'MMSP'  => 0x205F, # MEDIUM MATHEMATICAL SPACE
                'MVS'   => 0x180E, # MONGOLIAN VOWEL SEPARATOR
                'NBSP'  => 0x00A0, # NO-BREAK SPACE
                'NNBSP' => 0x202F, # NARROW NO-BREAK SPACE
                'PDF'   => 0x202C, # POP DIRECTIONAL FORMATTING
                'RLE'   => 0x202B, # RIGHT-TO-LEFT EMBEDDING
                'RLM'   => 0x200F, # RIGHT-TO-LEFT MARK
                'RLO'   => 0x202E, # RIGHT-TO-LEFT OVERRIDE
                'SHY'   => 0x00AD, # SOFT HYPHEN
                'VS1'   => 0xFE00, # VARIATION SELECTOR-1
                'VS2'   => 0xFE01, # VARIATION SELECTOR-2
                'VS3'   => 0xFE02, # VARIATION SELECTOR-3
                'VS4'   => 0xFE03, # VARIATION SELECTOR-4
                'VS5'   => 0xFE04, # VARIATION SELECTOR-5
                'VS6'   => 0xFE05, # VARIATION SELECTOR-6
                'VS7'   => 0xFE06, # VARIATION SELECTOR-7
                'VS8'   => 0xFE07, # VARIATION SELECTOR-8
                'VS9'   => 0xFE08, # VARIATION SELECTOR-9
                'VS10'  => 0xFE09, # VARIATION SELECTOR-10
                'VS11'  => 0xFE0A, # VARIATION SELECTOR-11
                'VS12'  => 0xFE0B, # VARIATION SELECTOR-12
                'VS13'  => 0xFE0C, # VARIATION SELECTOR-13
                'VS14'  => 0xFE0D, # VARIATION SELECTOR-14
                'VS15'  => 0xFE0E, # VARIATION SELECTOR-15
                'VS16'  => 0xFE0F, # VARIATION SELECTOR-16
                'VS17'  => 0xE0100, # VARIATION SELECTOR-17
                'VS18'  => 0xE0101, # VARIATION SELECTOR-18
                'VS19'  => 0xE0102, # VARIATION SELECTOR-19
                'VS20'  => 0xE0103, # VARIATION SELECTOR-20
                'VS21'  => 0xE0104, # VARIATION SELECTOR-21
                'VS22'  => 0xE0105, # VARIATION SELECTOR-22
                'VS23'  => 0xE0106, # VARIATION SELECTOR-23
                'VS24'  => 0xE0107, # VARIATION SELECTOR-24
                'VS25'  => 0xE0108, # VARIATION SELECTOR-25
                'VS26'  => 0xE0109, # VARIATION SELECTOR-26
                'VS27'  => 0xE010A, # VARIATION SELECTOR-27
                'VS28'  => 0xE010B, # VARIATION SELECTOR-28
                'VS29'  => 0xE010C, # VARIATION SELECTOR-29
                'VS30'  => 0xE010D, # VARIATION SELECTOR-30
                'VS31'  => 0xE010E, # VARIATION SELECTOR-31
                'VS32'  => 0xE010F, # VARIATION SELECTOR-32
                'VS33'  => 0xE0110, # VARIATION SELECTOR-33
                'VS34'  => 0xE0111, # VARIATION SELECTOR-34
                'VS35'  => 0xE0112, # VARIATION SELECTOR-35
                'VS36'  => 0xE0113, # VARIATION SELECTOR-36
                'VS37'  => 0xE0114, # VARIATION SELECTOR-37
                'VS38'  => 0xE0115, # VARIATION SELECTOR-38
                'VS39'  => 0xE0116, # VARIATION SELECTOR-39
                'VS40'  => 0xE0117, # VARIATION SELECTOR-40
                'VS41'  => 0xE0118, # VARIATION SELECTOR-41
                'VS42'  => 0xE0119, # VARIATION SELECTOR-42
                'VS43'  => 0xE011A, # VARIATION SELECTOR-43
                'VS44'  => 0xE011B, # VARIATION SELECTOR-44
                'VS45'  => 0xE011C, # VARIATION SELECTOR-45
                'VS46'  => 0xE011D, # VARIATION SELECTOR-46
                'VS47'  => 0xE011E, # VARIATION SELECTOR-47
                'VS48'  => 0xE011F, # VARIATION SELECTOR-48
                'VS49'  => 0xE0120, # VARIATION SELECTOR-49
                'VS50'  => 0xE0121, # VARIATION SELECTOR-50
                'VS51'  => 0xE0122, # VARIATION SELECTOR-51
                'VS52'  => 0xE0123, # VARIATION SELECTOR-52
                'VS53'  => 0xE0124, # VARIATION SELECTOR-53
                'VS54'  => 0xE0125, # VARIATION SELECTOR-54
                'VS55'  => 0xE0126, # VARIATION SELECTOR-55
                'VS56'  => 0xE0127, # VARIATION SELECTOR-56
                'VS57'  => 0xE0128, # VARIATION SELECTOR-57
                'VS58'  => 0xE0129, # VARIATION SELECTOR-58
                'VS59'  => 0xE012A, # VARIATION SELECTOR-59
                'VS60'  => 0xE012B, # VARIATION SELECTOR-60
                'VS61'  => 0xE012C, # VARIATION SELECTOR-61
                'VS62'  => 0xE012D, # VARIATION SELECTOR-62
                'VS63'  => 0xE012E, # VARIATION SELECTOR-63
                'VS64'  => 0xE012F, # VARIATION SELECTOR-64
                'VS65'  => 0xE0130, # VARIATION SELECTOR-65
                'VS66'  => 0xE0131, # VARIATION SELECTOR-66
                'VS67'  => 0xE0132, # VARIATION SELECTOR-67
                'VS68'  => 0xE0133, # VARIATION SELECTOR-68
                'VS69'  => 0xE0134, # VARIATION SELECTOR-69
                'VS70'  => 0xE0135, # VARIATION SELECTOR-70
                'VS71'  => 0xE0136, # VARIATION SELECTOR-71
                'VS72'  => 0xE0137, # VARIATION SELECTOR-72
                'VS73'  => 0xE0138, # VARIATION SELECTOR-73
                'VS74'  => 0xE0139, # VARIATION SELECTOR-74
                'VS75'  => 0xE013A, # VARIATION SELECTOR-75
                'VS76'  => 0xE013B, # VARIATION SELECTOR-76
                'VS77'  => 0xE013C, # VARIATION SELECTOR-77
                'VS78'  => 0xE013D, # VARIATION SELECTOR-78
                'VS79'  => 0xE013E, # VARIATION SELECTOR-79
                'VS80'  => 0xE013F, # VARIATION SELECTOR-80
                'VS81'  => 0xE0140, # VARIATION SELECTOR-81
                'VS82'  => 0xE0141, # VARIATION SELECTOR-82
                'VS83'  => 0xE0142, # VARIATION SELECTOR-83
                'VS84'  => 0xE0143, # VARIATION SELECTOR-84
                'VS85'  => 0xE0144, # VARIATION SELECTOR-85
                'VS86'  => 0xE0145, # VARIATION SELECTOR-86
                'VS87'  => 0xE0146, # VARIATION SELECTOR-87
                'VS88'  => 0xE0147, # VARIATION SELECTOR-88
                'VS89'  => 0xE0148, # VARIATION SELECTOR-89
                'VS90'  => 0xE0149, # VARIATION SELECTOR-90
                'VS91'  => 0xE014A, # VARIATION SELECTOR-91
                'VS92'  => 0xE014B, # VARIATION SELECTOR-92
                'VS93'  => 0xE014C, # VARIATION SELECTOR-93
                'VS94'  => 0xE014D, # VARIATION SELECTOR-94
                'VS95'  => 0xE014E, # VARIATION SELECTOR-95
                'VS96'  => 0xE014F, # VARIATION SELECTOR-96
                'VS97'  => 0xE0150, # VARIATION SELECTOR-97
                'VS98'  => 0xE0151, # VARIATION SELECTOR-98
                'VS99'  => 0xE0152, # VARIATION SELECTOR-99
                'VS100' => 0xE0153, # VARIATION SELECTOR-100
                'VS101' => 0xE0154, # VARIATION SELECTOR-101
                'VS102' => 0xE0155, # VARIATION SELECTOR-102
                'VS103' => 0xE0156, # VARIATION SELECTOR-103
                'VS104' => 0xE0157, # VARIATION SELECTOR-104
                'VS105' => 0xE0158, # VARIATION SELECTOR-105
                'VS106' => 0xE0159, # VARIATION SELECTOR-106
                'VS107' => 0xE015A, # VARIATION SELECTOR-107
                'VS108' => 0xE015B, # VARIATION SELECTOR-108
                'VS109' => 0xE015C, # VARIATION SELECTOR-109
                'VS110' => 0xE015D, # VARIATION SELECTOR-110
                'VS111' => 0xE015E, # VARIATION SELECTOR-111
                'VS112' => 0xE015F, # VARIATION SELECTOR-112
                'VS113' => 0xE0160, # VARIATION SELECTOR-113
                'VS114' => 0xE0161, # VARIATION SELECTOR-114
                'VS115' => 0xE0162, # VARIATION SELECTOR-115
                'VS116' => 0xE0163, # VARIATION SELECTOR-116
                'VS117' => 0xE0164, # VARIATION SELECTOR-117
                'VS118' => 0xE0165, # VARIATION SELECTOR-118
                'VS119' => 0xE0166, # VARIATION SELECTOR-119
                'VS120' => 0xE0167, # VARIATION SELECTOR-120
                'VS121' => 0xE0168, # VARIATION SELECTOR-121
                'VS122' => 0xE0169, # VARIATION SELECTOR-122
                'VS123' => 0xE016A, # VARIATION SELECTOR-123
                'VS124' => 0xE016B, # VARIATION SELECTOR-124
                'VS125' => 0xE016C, # VARIATION SELECTOR-125
                'VS126' => 0xE016D, # VARIATION SELECTOR-126
                'VS127' => 0xE016E, # VARIATION SELECTOR-127
                'VS128' => 0xE016F, # VARIATION SELECTOR-128
                'VS129' => 0xE0170, # VARIATION SELECTOR-129
                'VS130' => 0xE0171, # VARIATION SELECTOR-130
                'VS131' => 0xE0172, # VARIATION SELECTOR-131
                'VS132' => 0xE0173, # VARIATION SELECTOR-132
                'VS133' => 0xE0174, # VARIATION SELECTOR-133
                'VS134' => 0xE0175, # VARIATION SELECTOR-134
                'VS135' => 0xE0176, # VARIATION SELECTOR-135
                'VS136' => 0xE0177, # VARIATION SELECTOR-136
                'VS137' => 0xE0178, # VARIATION SELECTOR-137
                'VS138' => 0xE0179, # VARIATION SELECTOR-138
                'VS139' => 0xE017A, # VARIATION SELECTOR-139
                'VS140' => 0xE017B, # VARIATION SELECTOR-140
                'VS141' => 0xE017C, # VARIATION SELECTOR-141
                'VS142' => 0xE017D, # VARIATION SELECTOR-142
                'VS143' => 0xE017E, # VARIATION SELECTOR-143
                'VS144' => 0xE017F, # VARIATION SELECTOR-144
                'VS145' => 0xE0180, # VARIATION SELECTOR-145
                'VS146' => 0xE0181, # VARIATION SELECTOR-146
                'VS147' => 0xE0182, # VARIATION SELECTOR-147
                'VS148' => 0xE0183, # VARIATION SELECTOR-148
                'VS149' => 0xE0184, # VARIATION SELECTOR-149
                'VS150' => 0xE0185, # VARIATION SELECTOR-150
                'VS151' => 0xE0186, # VARIATION SELECTOR-151
                'VS152' => 0xE0187, # VARIATION SELECTOR-152
                'VS153' => 0xE0188, # VARIATION SELECTOR-153
                'VS154' => 0xE0189, # VARIATION SELECTOR-154
                'VS155' => 0xE018A, # VARIATION SELECTOR-155
                'VS156' => 0xE018B, # VARIATION SELECTOR-156
                'VS157' => 0xE018C, # VARIATION SELECTOR-157
                'VS158' => 0xE018D, # VARIATION SELECTOR-158
                'VS159' => 0xE018E, # VARIATION SELECTOR-159
                'VS160' => 0xE018F, # VARIATION SELECTOR-160
                'VS161' => 0xE0190, # VARIATION SELECTOR-161
                'VS162' => 0xE0191, # VARIATION SELECTOR-162
                'VS163' => 0xE0192, # VARIATION SELECTOR-163
                'VS164' => 0xE0193, # VARIATION SELECTOR-164
                'VS165' => 0xE0194, # VARIATION SELECTOR-165
                'VS166' => 0xE0195, # VARIATION SELECTOR-166
                'VS167' => 0xE0196, # VARIATION SELECTOR-167
                'VS168' => 0xE0197, # VARIATION SELECTOR-168
                'VS169' => 0xE0198, # VARIATION SELECTOR-169
                'VS170' => 0xE0199, # VARIATION SELECTOR-170
                'VS171' => 0xE019A, # VARIATION SELECTOR-171
                'VS172' => 0xE019B, # VARIATION SELECTOR-172
                'VS173' => 0xE019C, # VARIATION SELECTOR-173
                'VS174' => 0xE019D, # VARIATION SELECTOR-174
                'VS175' => 0xE019E, # VARIATION SELECTOR-175
                'VS176' => 0xE019F, # VARIATION SELECTOR-176
                'VS177' => 0xE01A0, # VARIATION SELECTOR-177
                'VS178' => 0xE01A1, # VARIATION SELECTOR-178
                'VS179' => 0xE01A2, # VARIATION SELECTOR-179
                'VS180' => 0xE01A3, # VARIATION SELECTOR-180
                'VS181' => 0xE01A4, # VARIATION SELECTOR-181
                'VS182' => 0xE01A5, # VARIATION SELECTOR-182
                'VS183' => 0xE01A6, # VARIATION SELECTOR-183
                'VS184' => 0xE01A7, # VARIATION SELECTOR-184
                'VS185' => 0xE01A8, # VARIATION SELECTOR-185
                'VS186' => 0xE01A9, # VARIATION SELECTOR-186
                'VS187' => 0xE01AA, # VARIATION SELECTOR-187
                'VS188' => 0xE01AB, # VARIATION SELECTOR-188
                'VS189' => 0xE01AC, # VARIATION SELECTOR-189
                'VS190' => 0xE01AD, # VARIATION SELECTOR-190
                'VS191' => 0xE01AE, # VARIATION SELECTOR-191
                'VS192' => 0xE01AF, # VARIATION SELECTOR-192
                'VS193' => 0xE01B0, # VARIATION SELECTOR-193
                'VS194' => 0xE01B1, # VARIATION SELECTOR-194
                'VS195' => 0xE01B2, # VARIATION SELECTOR-195
                'VS196' => 0xE01B3, # VARIATION SELECTOR-196
                'VS197' => 0xE01B4, # VARIATION SELECTOR-197
                'VS198' => 0xE01B5, # VARIATION SELECTOR-198
                'VS199' => 0xE01B6, # VARIATION SELECTOR-199
                'VS200' => 0xE01B7, # VARIATION SELECTOR-200
                'VS201' => 0xE01B8, # VARIATION SELECTOR-201
                'VS202' => 0xE01B9, # VARIATION SELECTOR-202
                'VS203' => 0xE01BA, # VARIATION SELECTOR-203
                'VS204' => 0xE01BB, # VARIATION SELECTOR-204
                'VS205' => 0xE01BC, # VARIATION SELECTOR-205
                'VS206' => 0xE01BD, # VARIATION SELECTOR-206
                'VS207' => 0xE01BE, # VARIATION SELECTOR-207
                'VS208' => 0xE01BF, # VARIATION SELECTOR-208
                'VS209' => 0xE01C0, # VARIATION SELECTOR-209
                'VS210' => 0xE01C1, # VARIATION SELECTOR-210
                'VS211' => 0xE01C2, # VARIATION SELECTOR-211
                'VS212' => 0xE01C3, # VARIATION SELECTOR-212
                'VS213' => 0xE01C4, # VARIATION SELECTOR-213
                'VS214' => 0xE01C5, # VARIATION SELECTOR-214
                'VS215' => 0xE01C6, # VARIATION SELECTOR-215
                'VS216' => 0xE01C7, # VARIATION SELECTOR-216
                'VS217' => 0xE01C8, # VARIATION SELECTOR-217
                'VS218' => 0xE01C9, # VARIATION SELECTOR-218
                'VS219' => 0xE01CA, # VARIATION SELECTOR-219
                'VS220' => 0xE01CB, # VARIATION SELECTOR-220
                'VS221' => 0xE01CC, # VARIATION SELECTOR-221
                'VS222' => 0xE01CD, # VARIATION SELECTOR-222
                'VS223' => 0xE01CE, # VARIATION SELECTOR-223
                'VS224' => 0xE01CF, # VARIATION SELECTOR-224
                'VS225' => 0xE01D0, # VARIATION SELECTOR-225
                'VS226' => 0xE01D1, # VARIATION SELECTOR-226
                'VS227' => 0xE01D2, # VARIATION SELECTOR-227
                'VS228' => 0xE01D3, # VARIATION SELECTOR-228
                'VS229' => 0xE01D4, # VARIATION SELECTOR-229
                'VS230' => 0xE01D5, # VARIATION SELECTOR-230
                'VS231' => 0xE01D6, # VARIATION SELECTOR-231
                'VS232' => 0xE01D7, # VARIATION SELECTOR-232
                'VS233' => 0xE01D8, # VARIATION SELECTOR-233
                'VS234' => 0xE01D9, # VARIATION SELECTOR-234
                'VS235' => 0xE01DA, # VARIATION SELECTOR-235
                'VS236' => 0xE01DB, # VARIATION SELECTOR-236
                'VS237' => 0xE01DC, # VARIATION SELECTOR-237
                'VS238' => 0xE01DD, # VARIATION SELECTOR-238
                'VS239' => 0xE01DE, # VARIATION SELECTOR-239
                'VS240' => 0xE01DF, # VARIATION SELECTOR-240
                'VS241' => 0xE01E0, # VARIATION SELECTOR-241
                'VS242' => 0xE01E1, # VARIATION SELECTOR-242
                'VS243' => 0xE01E2, # VARIATION SELECTOR-243
                'VS244' => 0xE01E3, # VARIATION SELECTOR-244
                'VS245' => 0xE01E4, # VARIATION SELECTOR-245
                'VS246' => 0xE01E5, # VARIATION SELECTOR-246
                'VS247' => 0xE01E6, # VARIATION SELECTOR-247
                'VS248' => 0xE01E7, # VARIATION SELECTOR-248
                'VS249' => 0xE01E8, # VARIATION SELECTOR-249
                'VS250' => 0xE01E9, # VARIATION SELECTOR-250
                'VS251' => 0xE01EA, # VARIATION SELECTOR-251
                'VS252' => 0xE01EB, # VARIATION SELECTOR-252
                'VS253' => 0xE01EC, # VARIATION SELECTOR-253
                'VS254' => 0xE01ED, # VARIATION SELECTOR-254
                'VS255' => 0xE01EE, # VARIATION SELECTOR-255
                'VS256' => 0xE01EF, # VARIATION SELECTOR-256
                'WJ'    => 0x2060, # WORD JOINER
                'ZWJ'   => 0x200D, # ZERO WIDTH JOINER
                'ZWNJ'  => 0x200C, # ZERO WIDTH NON-JOINER
                'ZWSP'  => 0x200B, # ZERO WIDTH SPACE
            );

my %deprecated_aliases = (
                # Pre-3.2 compatibility (only for the first 256 characters).
                # Use of these gives deprecated message.
                'HORIZONTAL TABULATION' => 0x09, # CHARACTER TABULATION
                'VERTICAL TABULATION'   => 0x0B, # LINE TABULATION
                'FILE SEPARATOR'        => 0x1C, # INFORMATION SEPARATOR FOUR
                'GROUP SEPARATOR'       => 0x1D, # INFORMATION SEPARATOR THREE
                'RECORD SEPARATOR'      => 0x1E, # INFORMATION SEPARATOR TWO
                'UNIT SEPARATOR'        => 0x1F, # INFORMATION SEPARATOR ONE
                'HORIZONTAL TABULATION SET' => 0x88, # CHARACTER TABULATION SET
                'HORIZONTAL TABULATION WITH JUSTIFICATION' => 0x89, # CHARACTER TABULATION WITH JUSTIFICATION
                'PARTIAL LINE DOWN'       => 0x8B, # PARTIAL LINE FORWARD
                'PARTIAL LINE UP'         => 0x8C, # PARTIAL LINE BACKWARD
                'VERTICAL TABULATION SET' => 0x8A, # LINE TABULATION SET
                'REVERSE INDEX'           => 0x8D, # REVERSE LINE FEED
            );

my %user_name_aliases = (
                # User defined aliases. Even more convenient :)
                # These are the ones that resolved to names
            );

my %user_numeric_aliases = (
                # And these resolve directly to code points.
            );
my %inverse_user_aliases = (
                # Map from code point to name
            );
my $txt;
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

sub alias (@)
{
  my $alias = ref $_[0] ? $_[0] : { @_ };
  foreach my $name (keys %$alias) {
    my $value = $alias->{$name};
    if ($value =~ $decimal_qr) {
        $user_numeric_aliases{$name} = $value;

        # Use a canonical form.
        $inverse_user_aliases{sprintf("%04X", $value)} = $name;
    }
    elsif ($value =~ $hex_qr) {
        my $decimal = CORE::hex $1;
        $user_numeric_aliases{$name} = $decimal;

        # Must convert to decimal and back to guarantee canonical form
        $inverse_user_aliases{sprintf("%04X", $decimal)} = $name;
    }
    else {
        $user_name_aliases{$name} = $value;
    }
  }
} # alias

sub alias_file ($)
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


sub lookup_name {
  my $name = shift;
  my $runtime = shift;  # compile vs run time

  # Finds the ordinal of a character name, first in the aliases, then in
  # the large table.  If not found, returns undef if runtime; complains
  # and returns the Unicode replacement if compile.
  # This is not optimized in any way yet

  my $ord;

  # User alias should be checked first or else can't override ours, and if we
  # add any, could conflict with theirs.
  if (exists $user_numeric_aliases{$name}) {
    $ord = $user_numeric_aliases{$name};
  }
  elsif (exists $user_name_aliases{$name}) {
    $name = $user_name_aliases{$name};
  }
  elsif (exists $system_aliases{$name}) {
    $ord = $system_aliases{$name};
  }
  elsif (exists $deprecated_aliases{$name}) {
    require warnings;
    warnings::warnif('deprecated', "Unicode character name \"$name\" is deprecated, use \"" . viacode($deprecated_aliases{$name}) . "\" instead");
    $ord = $deprecated_aliases{$name};
  }

  my @off;

  if (! defined $ord) {
    ## Suck in the code/name list as a big string.
    ## Lines look like:
    ##     "0052\t\tLATIN CAPITAL LETTER R\n"
    $txt = do "unicore/Name.pl" unless $txt;

    ## @off will hold the index into the code/name string of the start and
    ## end of the name as we find it.

    ## If :full, look for the name exactly; runtime implies full
    if (($runtime || $^H{charnames_full}) && $txt =~ /\t\t\Q$name\E$/m) {
      @off = ($-[0] + 2, $+[0]);    # The 2 is for the 2 tabs
    }

    ## If we didn't get above, and :short allowed, look for the short name.
    ## The short name is like "greek:Sigma"
    unless (@off) {
      if (($runtime || $^H{charnames_short}) && $name =~ /^(.+?):(.+)/s) {
       my ($script, $cname) = ($1, $2);
       my $case = $cname =~ /[[:upper:]]/ ? "CAPITAL" : "SMALL";
       if ($txt =~ m/\t\t\U$script\E (?:$case )?LETTER \U\Q$cname\E$/m) {
         @off = ($-[0] + 2, $+[0]);
       }
      }
    }

    ## If we still don't have it, check for the name among the loaded
    ## scripts.
    if (! $runtime && not @off) {
      my $case = $name =~ /[[:upper:]]/ ? "CAPITAL" : "SMALL";
      for my $script (@{$^H{charnames_scripts}}) {
        if ($txt =~ m/\t\t$script (?:$case )?LETTER \U\Q$name\E$/m) {
          @off = ($-[0] + 2, $+[0]);
          last;
        }
      }
    }

    ## If we don't have it by now, give up.
    unless (@off) {
      return if $runtime;
      carp "Unknown charname '$name'";
      return "\x{FFFD}";
    }

    # Get the official name in case need to output a message
    $name = substr($txt, $off[0], $off[1] - $off[0]);

    ##
    ## Now know where in the string the name starts.
    ## The code, in hex, is before that.
    ##
    ## The code can be 4-6 characters long, so we've got to sort of
    ## go look for it, just after the newline that comes before $off[0].
    ##
    ## This would be much easier if unicore/Name.pl had info in
    ## a name/code order, instead of code/name order.
    ##
    ## The +1 after the rindex() is to skip past the newline we're finding,
    ## or, if the rindex() fails, to put us to an offset of zero.
    ##
    my $hexstart = rindex($txt, "\n", $off[0]) + 1;

    ## we know where it starts, so turn into number -
    ## the ordinal for the char.
    $ord = CORE::hex substr($txt, $hexstart, $off[0] - 2 - $hexstart);
  }

  return $ord if $runtime || $ord <= 255 || ! ($^H & $bytes::hint_bits);

  # Here is compile time, "use bytes" is in effect, and the character
  # won't fit in a byte

  croak sprintf("Character 0x%04x with name '$name' is above 0xFF", $ord);
} # lookup_name

sub charnames {
  my $name = shift;

  # For \N{...}.  Looks up the character name and returns its ordinal if
  # found, undef otherwise.  If not in 'use bytes', forces into utf8

  my $ord = lookup_name($name, 0); # 0 means compile-time
  return unless defined $ord;
  return chr $ord if $^H & $bytes::hint_bits;

  no warnings 'utf8'; # allow even illegal characters
  return pack "U", $ord;
}

sub import
{
  shift; ## ignore class name

  if (not @_) {
    carp("`use charnames' needs explicit imports list");
  }
  $^H{charnames} = \&charnames ;

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
	$1 eq "full" || $1 eq "short" and
	  croak ":alias cannot use existing pragma :$1 (reversed order?)";
	alias_file ($1) and $promote = 1;
	next;
      }
      alias_file ($alias);
      next;
    }
    if (substr($arg, 0, 1) eq ':' and ! ($arg eq ":full" || $arg eq ":short")) {
      warn "unsupported special '$arg' in charnames";
      next;
    }
    push @args, $arg;
  }
  @args == 0 && $promote and @args = (":full");
  @h{@args} = (1) x @args;

  $^H{charnames_full} = delete $h{':full'};
  $^H{charnames_short} = delete $h{':short'};
  $^H{charnames_scripts} = [map uc, keys %h];

  ##
  ## If utf8? warnings are enabled, and some scripts were given,
  ## see if at least we can find one letter of each script.
  ##
  if (warnings::enabled('utf8') && @{$^H{charnames_scripts}}) {
    $txt = do "unicore/Name.pl" unless $txt;

    for my $script (@{$^H{charnames_scripts}}) {
      if (not $txt =~ m/\t\t$script (?:CAPITAL |SMALL )?LETTER /) {
	warnings::warn('utf8',  "No such script: '$script'");
      }
    }
  }
} # import

my %viacode;    # Cache of already-found codes

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
  my $hex;
  if ($arg =~ $decimal_qr) {
    $hex = sprintf "%04X", $arg;
  } elsif ($arg =~ $hex_qr) {
    # Below is the line that differs from the _getcode() source
    $hex = sprintf "%04X", hex $1;
  } else {
    carp("unexpected arg \"$arg\" to charnames::viacode()");
    return;
  }

  return $viacode{$hex} if exists $viacode{$hex};

  # If the code point is above the max in the table, there's no point
  # looking through it.  Checking the length first is slightly faster
  if (length($hex) <= 5 || CORE::hex($hex) <= 0x10FFFF) {
    $txt = do "unicore/Name.pl" unless $txt;

    # Return the official name, if exists.  It's unclear to me (khw) at
    # this juncture if it is better to return a user-defined override, so
    # leaving it as is for now.
    if ($txt =~ m/^$hex\t\t(.+)/m) {
        $viacode{$hex} = $1;
        return $1;
    }
  }

  # See if there is a user name for it, before giving up completely.
  if (! exists $inverse_user_aliases{$hex}) {
    if (CORE::hex($hex) > 0x10FFFF) {
        carp "Unicode characters only allocated up to U+10FFFF (you asked for U+$hex)";
    }
    return;
  }

  $viacode{$hex} = $inverse_user_aliases{$hex};
  return $inverse_user_aliases{$hex};
} # viacode

my %vianame;    # Cache of already-found names

sub vianame
{
  if (@_ != 1) {
    carp "charnames::vianame() expects one name argument";
    return ()
  }

  # Looks up the character name and returns its ordinal if
  # found, undef otherwise.

  my $arg = shift;

  if ($arg =~ /^U\+([0-9a-fA-F]+)$/) {

    # khw claims that this is bad.  The function should return either a
    # an ord or a chr for all inputs; not be bipolar.  Also, under 'use
    # bytes', can create a chr above 255.
    return chr CORE::hex $1;
  }

  if (! exists $vianame{$arg}) {
    $vianame{$arg} = lookup_name($arg, 1); # 1 means run-time
  }

  return $vianame{$arg};
} # vianame


1;
__END__

=head1 NAME

charnames - define character names for C<\N{named}> string literal escapes

=head1 SYNOPSIS

  use charnames ':full';
  print "\N{GREEK SMALL LETTER SIGMA} is called sigma.\n";

  use charnames ':short';
  print "\N{greek:Sigma} is an upper-case sigma.\n";

  use charnames qw(cyrillic greek);
  print "\N{sigma} is Greek sigma, and \N{be} is Cyrillic b.\n";

  use charnames ":full", ":alias" => {
    e_ACUTE => "LATIN SMALL LETTER E WITH ACUTE",
    mychar => 0xE8000,  # Private use area
  };
  print "\N{e_ACUTE} is a small letter e with an acute.\n";
  print "\\N{mychar} allows me to name and use private use characters.\n";

  use charnames ();
  print charnames::viacode(0x1234); # prints "ETHIOPIC SYLLABLE SEE"
  printf "%04X", charnames::vianame("GOTHIC LETTER AHSA"); # prints
                                                           # "10330"

=head1 DESCRIPTION

Pragma C<use charnames> enables the use of C<\N{CHARNAME}> sequences to
insert a Unicode character into a string based on its name.  (However,
you don't need this pragma to use C<\N{U+...}> where the C<...> is a
hexadecimal ordinal number.)

The pragma supports arguments C<:full>, C<:short>, script names and
customized aliases.  If C<:full> is present, for expansion of
C<\N{CHARNAME}>, the string C<CHARNAME> is first looked up in the list of
standard Unicode character names.  If C<:short> is present, and
C<CHARNAME> has the form C<SCRIPT:CNAME>, then C<CNAME> is looked up
as a letter in script C<SCRIPT>.  If pragma C<use charnames> is used
with script name arguments, then for C<\N{CHARNAME}> the name
C<CHARNAME> is looked up as a letter in the given scripts (in the
specified order). Customized aliases can override these, and are explained in
L</CUSTOM ALIASES>.

For lookup of C<CHARNAME> inside a given script C<SCRIPTNAME>
this pragma looks for the names

  SCRIPTNAME CAPITAL LETTER CHARNAME
  SCRIPTNAME SMALL LETTER CHARNAME
  SCRIPTNAME LETTER CHARNAME

in the table of standard Unicode names.  If C<CHARNAME> is lowercase,
then the C<CAPITAL> variant is ignored, otherwise the C<SMALL> variant
is ignored.

Note that C<\N{...}> is compile-time, it's a special form of string
constant used inside double-quoted strings: in other words, you cannot
use variables inside the C<\N{...}>.  If you want similar run-time
functionality, use charnames::vianame().

For the C0 and C1 control characters (U+0000..U+001F, U+0080..U+009F)
as of Unicode 3.1, there are no official Unicode names but you can use
instead the ISO 6429 names (LINE FEED, ESCAPE, and so forth, and their
abbreviations, LF, ESC, ...).  In
Unicode 3.2 (as of Perl 5.8) some naming changes take place ISO 6429
has been updated, see L</ALIASES>.

Since the Unicode standard uses "U+HHHH", so can you: "\N{U+263a}"
is the Unicode smiley face, or "\N{WHITE SMILING FACE}".

If the input name is unknown, C<\N{NAME}> raises a warning and
substitutes the Unicode REPLACEMENT CHARACTER (U+FFFD).

It is a fatal error if C<use bytes> is in effect and the input name is
that of a character that won't fit into a byte (i.e., whose ordinal is
above 255).

=head1 ALIASES

A few aliases have been defined for convenience: instead of having
to use the official names

    LINE FEED (LF)
    FORM FEED (FF)
    CARRIAGE RETURN (CR)
    NEXT LINE (NEL)

(yes, with parentheses), one can use

    LINE FEED
    FORM FEED
    CARRIAGE RETURN
    NEXT LINE
    LF
    FF
    CR
    NEL

All the other standard abbreviations for the controls, such as C<ACK> for
C<ACKNOWLEDGE> also can be used.

One can also use

    BYTE ORDER MARK
    BOM

and these abbreviations

    Abbreviation        Full Name

    CGJ                 COMBINING GRAPHEME JOINER
    FVS1                MONGOLIAN FREE VARIATION SELECTOR ONE
    FVS2                MONGOLIAN FREE VARIATION SELECTOR TWO
    FVS3                MONGOLIAN FREE VARIATION SELECTOR THREE
    LRE                 LEFT-TO-RIGHT EMBEDDING
    LRM                 LEFT-TO-RIGHT MARK
    LRO                 LEFT-TO-RIGHT OVERRIDE
    MMSP                MEDIUM MATHEMATICAL SPACE
    MVS                 MONGOLIAN VOWEL SEPARATOR
    NBSP                NO-BREAK SPACE
    NNBSP               NARROW NO-BREAK SPACE
    PDF                 POP DIRECTIONAL FORMATTING
    RLE                 RIGHT-TO-LEFT EMBEDDING
    RLM                 RIGHT-TO-LEFT MARK
    RLO                 RIGHT-TO-LEFT OVERRIDE
    SHY                 SOFT HYPHEN
    VS1                 VARIATION SELECTOR-1
    .
    .
    .
    VS256               VARIATION SELECTOR-256
    WJ                  WORD JOINER
    ZWJ                 ZERO WIDTH JOINER
    ZWNJ                ZERO WIDTH NON-JOINER
    ZWSP                ZERO WIDTH SPACE

For backward compatibility one can use the old names for
certain C0 and C1 controls

    old                         new

    FILE SEPARATOR              INFORMATION SEPARATOR FOUR
    GROUP SEPARATOR             INFORMATION SEPARATOR THREE
    HORIZONTAL TABULATION       CHARACTER TABULATION
    HORIZONTAL TABULATION SET   CHARACTER TABULATION SET
    HORIZONTAL TABULATION WITH JUSTIFICATION    CHARACTER TABULATION
                                                WITH JUSTIFICATION
    PARTIAL LINE DOWN           PARTIAL LINE FORWARD
    PARTIAL LINE UP             PARTIAL LINE BACKWARD
    RECORD SEPARATOR            INFORMATION SEPARATOR TWO
    REVERSE INDEX               REVERSE LINE FEED
    UNIT SEPARATOR              INFORMATION SEPARATOR ONE
    VERTICAL TABULATION         LINE TABULATION
    VERTICAL TABULATION SET     LINE TABULATION SET

but the old names in addition to giving the character
will also give a warning about being deprecated.

And finally, certain published variants are usable, including some for
controls that have no Unicode names:

    END OF PROTECTED AREA
    HIGH OCTET PRESET
    HOP
    IND
    INDEX
    PAD
    PADDING CHARACTER
    PRIVATE USE 1
    PRIVATE USE 2
    SGC
    SINGLE GRAPHIC CHARACTER INTRODUCER
    SINGLE-SHIFT 2
    SINGLE-SHIFT 3
    START OF PROTECTED AREA

=head1 CUSTOM ALIASES

This version of charnames supports three mechanisms of adding local
or customized aliases to standard Unicode naming conventions (:full).
The aliases override any standard definitions, so, if you're twisted
enough, you can change C<"\N{LATIN CAPITAL LETTER A}"> to mean C<"B">,
etc.

Note that an alias should not be something that is a legal curly
brace-enclosed quantifier (see L<perlreref/QUANTIFIERS>).  For example
C<\N{123}> means to match 123 non-newline characters, and is not treated as a
charnames alias.  Aliases are discouraged from beginning with anything
other than an alphabetic character and from containing anything other
than alphanumerics, spaces, dashes, parentheses, and underscores.
Currently they must be ASCII.

An alias can map to either an official Unicode character name or to a
numeric code point (ordinal).  The latter is useful for assigning names
to code points in Unicode private use areas such as U+E800 through
U+F8FF.  The number must look like an unsigned decimal integer, or a
hexadecimal constant beginning with C<0x>, or C<U+>.

=head2 Anonymous hashes

    use charnames ":full", ":alias" => {
        e_ACUTE => "LATIN SMALL LETTER E WITH ACUTE",
        mychar1 => 0xE8000,
        };
    my $str = "\N{e_ACUTE}";

=head2 Alias file

    use charnames ":full", ":alias" => "pro";

    will try to read "unicore/pro_alias.pl" from the @INC path. This
    file should return a list in plain perl:

    (
    A_GRAVE         => "LATIN CAPITAL LETTER A WITH GRAVE",
    A_CIRCUM        => "LATIN CAPITAL LETTER A WITH CIRCUMFLEX",
    A_DIAERES       => "LATIN CAPITAL LETTER A WITH DIAERESIS",
    A_TILDE         => "LATIN CAPITAL LETTER A WITH TILDE",
    A_BREVE         => "LATIN CAPITAL LETTER A WITH BREVE",
    A_RING          => "LATIN CAPITAL LETTER A WITH RING ABOVE",
    A_MACRON        => "LATIN CAPITAL LETTER A WITH MACRON",
    mychar2         => U+E8001,
    );

=head2 Alias shortcut

    use charnames ":alias" => ":pro";

works exactly the same as the alias pairs, only this time,
":full" is inserted automatically as the first argument (if no
other argument is given).

=head1 charnames::viacode(code)

Returns the full name of the character indicated by the numeric code.
The example

    print charnames::viacode(0x2722);

prints "FOUR TEARDROP-SPOKED ASTERISK".

Returns undef if no name is known for the code.

The name returned is the official name for the code point, if
available, otherwise your custom alias for it.  This means that your
alias will only be returned for code points that don't have an official
Unicode name (nor Unicode version 1 name), such as private use code
points, and the 4 control characters U+0080, U+0081, U+0084, and U+0099.

Notice that the name returned for of U+FEFF is "ZERO WIDTH NO-BREAK
SPACE", not "BYTE ORDER MARK".

=head1 charnames::vianame(name)

Returns the code point indicated by the name.
The example

    printf "%04X", charnames::vianame("FOUR TEARDROP-SPOKED ASTERISK");

prints "2722".

Returns undef if the name is unknown.

This works only for the standard names, and does not yet apply
to custom translators.

=head1 CUSTOM TRANSLATORS

The mechanism of translation of C<\N{...}> escapes is general and not
hardwired into F<charnames.pm>.  A module can install custom
translations (inside the scope which C<use>s the module) with the
following magic incantation:

    sub import {
	shift;
	$^H{charnames} = \&translator;
    }

Here translator() is a subroutine which takes C<CHARNAME> as an
argument, and returns text to insert into the string instead of the
C<\N{CHARNAME}> escape.  Since the text to insert should be different
in C<bytes> mode and out of it, the function should check the current
state of C<bytes>-flag as in:

    use bytes ();			# for $bytes::hint_bits
    sub translator {
	if ($^H & $bytes::hint_bits) {
	    return bytes_translator(@_);
	}
	else {
	    return utf8_translator(@_);
	}
    }

See L</CUSTOM ALIASES> above for restrictions on C<CHARNAME>.

=head1 ILLEGAL CHARACTERS

If you ask by name for a character that does not exist, a warning is given and
the Unicode I<replacement character> "\x{FFFD}" is returned.

If you ask by code (C<charnames::viacode()>) for a character that is
unassigned, no warning is given and C<undef> is returned.  In Unicode
the proper name of these is the empty string, which C<undef> stringifies
to.  (If you ask for a code point past the legal Unicode maximum of
U+10FFFF you do get C<undef> and a warning.)

=head1 BUGS

vianame returns a chr if the input name is of the form C<U+...>, and an ord
otherwise.  It is proposed to change this to always return an ord.  Send email
to C<perl5-porters@perl.org> to comment on this proposal.

None of the functions work on almost all the Hangul syllable and CJK Unicode
characters that have their code points as part of their names.

Names must be ASCII characters only, which means that you are out of luck if
you want to create aliases in a language where some or all the characters of
the desired aliases are non-ASCII.

Unicode standard named sequences are not recognized, such as
C<LATIN CAPITAL LETTER A WITH MACRON AND GRAVE>
(which should mean C<LATIN CAPITAL LETTER A WITH MACRON> with an additional
C<COMBINING GRAVE ACCENT>).

Since evaluation of the translation function happens in the middle of
compilation (of a string literal), the translation function should not
do any C<eval>s or C<require>s.  This restriction should be lifted in
a future version of Perl.

=cut
