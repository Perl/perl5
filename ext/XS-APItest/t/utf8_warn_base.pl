#!perl -w

# This is a base file to be used by various .t's in its directory

use strict;
use Test::More;

BEGIN {
    use_ok('XS::APItest');
    require 'charset_tools.pl';
    require './t/utf8_setup.pl';
};

$|=1;

no warnings 'deprecated'; # Some of the below are above IV_MAX on 32 bit
                          # machines, and that is tested elsewhere

use XS::APItest;
use Data::Dumper;

my @warnings_gotten;

use warnings 'utf8';
local $SIG{__WARN__} = sub { my @copy = @_;
                             push @warnings_gotten, map { chomp; $_ } @copy;
                           };

sub nonportable_regex ($) {

    # Returns a pattern that matches the non-portable message raised either
    # for the specific input code point, or the one generated when there
    # is some malformation that precludes the message containing the specific
    # code point

    my $code_point = shift;

    my $string = sprintf '(Code point 0x%X is not Unicode, and'
                       . '|Any UTF-8 sequence that starts with'
                       . ' "(\\\x[[:xdigit:]]{2})+" is for a'
                       . ' non-Unicode code point, and is) not portable',
                    $code_point;
    return qr/$string/;
}

# Now test the cases where a legal code point is generated, but may or may not
# be allowed/warned on.
my @tests = (
     # ($testname, $bytes, $controlling_warning_category,
     #  $allowed_uv, $needed_to_discern_len )
    [ "lowest surrogate",
        (isASCII) ? "\xed\xa0\x80" : I8_to_native("\xf1\xb6\xa0\xa0"),
        'surrogate', 0xD800,
    ],
    [ "a middle surrogate",
        (isASCII) ? "\xed\xa4\x8d" : I8_to_native("\xf1\xb6\xa8\xad"),
        'surrogate', 0xD90D,
    ],
    [ "highest surrogate",
        (isASCII) ? "\xed\xbf\xbf" : I8_to_native("\xf1\xb7\xbf\xbf"),
        'surrogate', 0xDFFF,
    ],
    [ "first non_unicode",
        (isASCII) ? "\xf4\x90\x80\x80" : I8_to_native("\xf9\xa2\xa0\xa0\xa0"),
        'non_unicode', 0x110000,
        2,
    ],
    [ "non_unicode whose first byte tells that",
        (isASCII) ? "\xf5\x80\x80\x80" : I8_to_native("\xfa\xa0\xa0\xa0\xa0"),
        'non_unicode',
        (isASCII) ? 0x140000 : 0x200000,
        1,
    ],
    [ "first of 32 consecutive non-character code points",
        (isASCII) ? "\xef\xb7\x90" : I8_to_native("\xf1\xbf\xae\xb0"),
        'nonchar', 0xFDD0,
    ],
    [ "a mid non-character code point of the 32 consecutive ones",
        (isASCII) ? "\xef\xb7\xa0" : I8_to_native("\xf1\xbf\xaf\xa0"),
        'nonchar', 0xFDE0,
    ],
    [ "final of 32 consecutive non-character code points",
        (isASCII) ? "\xef\xb7\xaf" : I8_to_native("\xf1\xbf\xaf\xaf"),
        'nonchar', 0xFDEF,
    ],
    [ "non-character code point U+FFFE",
        (isASCII) ? "\xef\xbf\xbe" : I8_to_native("\xf1\xbf\xbf\xbe"),
        'nonchar', 0xFFFE,
    ],
    [ "non-character code point U+FFFF",
        (isASCII) ? "\xef\xbf\xbf" : I8_to_native("\xf1\xbf\xbf\xbf"),
        'nonchar', 0xFFFF,
    ],
    [ "non-character code point U+1FFFE",
        (isASCII) ? "\xf0\x9f\xbf\xbe" : I8_to_native("\xf3\xbf\xbf\xbe"),
        'nonchar', 0x1FFFE,
    ],
    [ "non-character code point U+1FFFF",
        (isASCII) ? "\xf0\x9f\xbf\xbf" : I8_to_native("\xf3\xbf\xbf\xbf"),
        'nonchar', 0x1FFFF,
    ],
    [ "non-character code point U+2FFFE",
        (isASCII) ? "\xf0\xaf\xbf\xbe" : I8_to_native("\xf5\xbf\xbf\xbe"),
        'nonchar', 0x2FFFE,
    ],
    [ "non-character code point U+2FFFF",
        (isASCII) ? "\xf0\xaf\xbf\xbf" : I8_to_native("\xf5\xbf\xbf\xbf"),
        'nonchar', 0x2FFFF,
    ],
    [ "non-character code point U+3FFFE",
        (isASCII) ? "\xf0\xbf\xbf\xbe" : I8_to_native("\xf7\xbf\xbf\xbe"),
        'nonchar', 0x3FFFE,
    ],
    [ "non-character code point U+3FFFF",
        (isASCII) ? "\xf0\xbf\xbf\xbf" : I8_to_native("\xf7\xbf\xbf\xbf"),
        'nonchar', 0x3FFFF,
    ],
    [ "non-character code point U+4FFFE",
        (isASCII) ? "\xf1\x8f\xbf\xbe" : I8_to_native("\xf8\xa9\xbf\xbf\xbe"),
        'nonchar', 0x4FFFE,
    ],
    [ "non-character code point U+4FFFF",
        (isASCII) ? "\xf1\x8f\xbf\xbf" : I8_to_native("\xf8\xa9\xbf\xbf\xbf"),
        'nonchar', 0x4FFFF,
    ],
    [ "non-character code point U+5FFFE",
        (isASCII) ? "\xf1\x9f\xbf\xbe" : I8_to_native("\xf8\xab\xbf\xbf\xbe"),
        'nonchar', 0x5FFFE,
    ],
    [ "non-character code point U+5FFFF",
        (isASCII) ? "\xf1\x9f\xbf\xbf" : I8_to_native("\xf8\xab\xbf\xbf\xbf"),
        'nonchar', 0x5FFFF,
    ],
    [ "non-character code point U+6FFFE",
        (isASCII) ? "\xf1\xaf\xbf\xbe" : I8_to_native("\xf8\xad\xbf\xbf\xbe"),
        'nonchar', 0x6FFFE,
    ],
    [ "non-character code point U+6FFFF",
        (isASCII) ? "\xf1\xaf\xbf\xbf" : I8_to_native("\xf8\xad\xbf\xbf\xbf"),
        'nonchar', 0x6FFFF,
    ],
    [ "non-character code point U+7FFFE",
        (isASCII) ? "\xf1\xbf\xbf\xbe" : I8_to_native("\xf8\xaf\xbf\xbf\xbe"),
        'nonchar', 0x7FFFE,
    ],
    [ "non-character code point U+7FFFF",
        (isASCII) ? "\xf1\xbf\xbf\xbf" : I8_to_native("\xf8\xaf\xbf\xbf\xbf"),
        'nonchar', 0x7FFFF,
    ],
    [ "non-character code point U+8FFFE",
        (isASCII) ? "\xf2\x8f\xbf\xbe" : I8_to_native("\xf8\xb1\xbf\xbf\xbe"),
        'nonchar', 0x8FFFE,
    ],
    [ "non-character code point U+8FFFF",
        (isASCII) ? "\xf2\x8f\xbf\xbf" : I8_to_native("\xf8\xb1\xbf\xbf\xbf"),
        'nonchar', 0x8FFFF,
    ],
    [ "non-character code point U+9FFFE",
        (isASCII) ? "\xf2\x9f\xbf\xbe" : I8_to_native("\xf8\xb3\xbf\xbf\xbe"),
        'nonchar', 0x9FFFE,
    ],
    [ "non-character code point U+9FFFF",
        (isASCII) ? "\xf2\x9f\xbf\xbf" : I8_to_native("\xf8\xb3\xbf\xbf\xbf"),
        'nonchar', 0x9FFFF,
    ],
    [ "non-character code point U+AFFFE",
        (isASCII) ? "\xf2\xaf\xbf\xbe" : I8_to_native("\xf8\xb5\xbf\xbf\xbe"),
        'nonchar', 0xAFFFE,
    ],
    [ "non-character code point U+AFFFF",
        (isASCII) ? "\xf2\xaf\xbf\xbf" : I8_to_native("\xf8\xb5\xbf\xbf\xbf"),
        'nonchar', 0xAFFFF,
    ],
    [ "non-character code point U+BFFFE",
        (isASCII) ? "\xf2\xbf\xbf\xbe" : I8_to_native("\xf8\xb7\xbf\xbf\xbe"),
        'nonchar', 0xBFFFE,
    ],
    [ "non-character code point U+BFFFF",
        (isASCII) ? "\xf2\xbf\xbf\xbf" : I8_to_native("\xf8\xb7\xbf\xbf\xbf"),
        'nonchar', 0xBFFFF,
    ],
    [ "non-character code point U+CFFFE",
        (isASCII) ? "\xf3\x8f\xbf\xbe" : I8_to_native("\xf8\xb9\xbf\xbf\xbe"),
        'nonchar', 0xCFFFE,
    ],
    [ "non-character code point U+CFFFF",
        (isASCII) ? "\xf3\x8f\xbf\xbf" : I8_to_native("\xf8\xb9\xbf\xbf\xbf"),
        'nonchar', 0xCFFFF,
    ],
    [ "non-character code point U+DFFFE",
        (isASCII) ? "\xf3\x9f\xbf\xbe" : I8_to_native("\xf8\xbb\xbf\xbf\xbe"),
        'nonchar', 0xDFFFE,
    ],
    [ "non-character code point U+DFFFF",
        (isASCII) ? "\xf3\x9f\xbf\xbf" : I8_to_native("\xf8\xbb\xbf\xbf\xbf"),
        'nonchar', 0xDFFFF,
    ],
    [ "non-character code point U+EFFFE",
        (isASCII) ? "\xf3\xaf\xbf\xbe" : I8_to_native("\xf8\xbd\xbf\xbf\xbe"),
        'nonchar', 0xEFFFE,
    ],
    [ "non-character code point U+EFFFF",
        (isASCII) ? "\xf3\xaf\xbf\xbf" : I8_to_native("\xf8\xbd\xbf\xbf\xbf"),
        'nonchar', 0xEFFFF,
    ],
    [ "non-character code point U+FFFFE",
        (isASCII) ? "\xf3\xbf\xbf\xbe" : I8_to_native("\xf8\xbf\xbf\xbf\xbe"),
        'nonchar', 0xFFFFE,
    ],
    [ "non-character code point U+FFFFF",
        (isASCII) ? "\xf3\xbf\xbf\xbf" : I8_to_native("\xf8\xbf\xbf\xbf\xbf"),
        'nonchar', 0xFFFFF,
    ],
    [ "non-character code point U+10FFFE",
        (isASCII) ? "\xf4\x8f\xbf\xbe" : I8_to_native("\xf9\xa1\xbf\xbf\xbe"),
        'nonchar', 0x10FFFE,
    ],
    [ "non-character code point U+10FFFF",
        (isASCII) ? "\xf4\x8f\xbf\xbf" : I8_to_native("\xf9\xa1\xbf\xbf\xbf"),
        'nonchar', 0x10FFFF,
    ],
    [ "requires at least 32 bits",
        (isASCII)
         ?  "\xfe\x82\x80\x80\x80\x80\x80"
         : I8_to_native(
            "\xff\xa0\xa0\xa0\xa0\xa0\xa0\xa2\xa0\xa0\xa0\xa0\xa0\xa0"),
        # This code point is chosen so that it is representable in a UV on
        # 32-bit machines
        'utf8', 0x80000000,
        (isASCII) ? 1 : 8,
    ],
    [ "highest 32 bit code point",
        (isASCII)
         ?  "\xfe\x83\xbf\xbf\xbf\xbf\xbf"
         : I8_to_native(
            "\xff\xa0\xa0\xa0\xa0\xa0\xa0\xa3\xbf\xbf\xbf\xbf\xbf\xbf"),
        'utf8', 0xFFFFFFFF,
        (isASCII) ? 1 : 8,
    ],
    [ "requires at least 32 bits, and use SUPER-type flags, instead of"
    . " ABOVE_31_BIT",
        (isASCII)
         ? "\xfe\x82\x80\x80\x80\x80\x80"
         : I8_to_native(
           "\xff\xa0\xa0\xa0\xa0\xa0\xa0\xa2\xa0\xa0\xa0\xa0\xa0\xa0"),
        'utf8', 0x80000000,
        1,
    ],
    [ "overflow with warnings/disallow for more than 31 bits",
        # This tests the interaction of WARN_ABOVE_31_BIT/DISALLOW_ABOVE_31_BIT
        # with overflow.  The overflow malformation is never allowed, so
        # preventing it takes precedence if the ABOVE_31_BIT options would
        # otherwise allow in an overflowing value.  The ASCII code points (1
        # for 32-bits; 1 for 64) were chosen because the old overflow
        # detection algorithm did not catch them; this means this test also
        # checks for that fix.  The EBCDIC are arbitrary overflowing ones
        # since we have no reports of failures with it.
       (($::is64bit)
        ? ((isASCII)
           ?    "\xff\x80\x90\x90\x90\xbf\xbf\xbf\xbf\xbf\xbf\xbf\xbf"
           : I8_to_native(
                "\xff\xB0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0"))
        : ((isASCII)
           ?    "\xfe\x86\x80\x80\x80\x80\x80"
           : I8_to_native(
                "\xff\xa0\xa0\xa0\xa0\xa0\xa0\xa4\xa0\xa0\xa0\xa0\xa0\xa0"))),
        'utf8', -1,
        (isASCII || $::is64bit) ? 2 : 8,
    ],
);

if (! $::is64bit) {
    if (isASCII) {
        no warnings qw{portable overflow};
        push @tests,
            [ "Lowest 33 bit code point: overflow",
                "\xFE\x84\x80\x80\x80\x80\x80",
                'utf8', -1,
                1,
            ];
    }
}
else {
    no warnings qw{portable overflow};
    push @tests,
        [ "More than 32 bits",
            (isASCII)
            ?       "\xff\x80\x80\x80\x80\x80\x81\x80\x80\x80\x80\x80\x80"
            : I8_to_native(
                    "\xff\xa0\xa0\xa0\xa0\xa0\xa2\xa0\xa0\xa0\xa0\xa0\xa0\xa0"),
            'utf8', 0x1000000000,
            (isASCII) ? 1 : 7,
        ];
    if (! isASCII) {
        push @tests,   # These could falsely show wrongly in a naive
                       # implementation
            [ "requires at least 32 bits",
                I8_to_native(
                    "\xff\xa0\xa0\xa0\xa0\xa0\xa1\xa0\xa0\xa0\xa0\xa0\xa0\xa0"),
                'utf8', 0x800000000,
                7,
            ],
            [ "requires at least 32 bits",
                I8_to_native(
                    "\xff\xa0\xa0\xa0\xa0\xa1\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0"),
                'utf8', 0x10000000000,
                6,
            ],
            [ "requires at least 32 bits",
                I8_to_native(
                    "\xff\xa0\xa0\xa0\xa1\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0"),
                'utf8', 0x200000000000,
                5,
            ],
            [ "requires at least 32 bits",
                I8_to_native(
                    "\xff\xa0\xa0\xa1\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0"),
                'utf8', 0x4000000000000,
                4,
            ],
            [ "requires at least 32 bits",
                I8_to_native(
                    "\xff\xa0\xa1\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0"),
                'utf8', 0x80000000000000,
                3,
            ],
            [ "requires at least 32 bits",
                I8_to_native(
                    "\xff\xa1\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0"),
                'utf8', 0x1000000000000000,
                2,
            ];
    }
}

sub flags_to_text($$)
{
    my ($flags, $flags_to_text_ref) = @_;

    # Returns a string containing a mnemonic representation of the bits that
    # are set in the $flags.  These are assumed to be flag bits.  The return
    # looks like "FOO|BAR|BAZ".  The second parameter is a reference to an
    # array that gives the textual representation of all the possible flags.
    # Element 0 is the text for the bit 0 flag; element 1 for bit 1; ....  If
    # no bits at all are set the string "0" is returned;

    my @flag_text;
    my $shift = 0;

    return "0" if $flags == 0;

    while ($flags) {
        #diag sprintf "%x", $flags;
        if ($flags & 1) {
            push @flag_text, $flags_to_text_ref->[$shift];
        }
        $shift++;
        $flags >>= 1;
    }

    return join "|", @flag_text;
}

# Possible flag returns from utf8n_to_uvchr_error().  These should have G_,
# instead of A_, D_, but the prefixes will be used in a a later commit, so
# minimize churn by having them here.
my @utf8n_flags_to_text =  ( qw(
        A_EMPTY
        A_CONTINUATION
        A_NON_CONTINUATION
        A_SHORT
        A_LONG
        A_LONG_AND_ITS_VALUE
        PLACEHOLDER
        A_OVERFLOW
        D_SURROGATE
        W_SURROGATE
        D_NONCHAR
        W_NONCHAR
        D_SUPER
        W_SUPER
        D_ABOVE_31_BIT
        W_ABOVE_31_BIT
        CHECK_ONLY
        NO_CONFIDENCE_IN_CURLEN_
    ) );

sub utf8n_display_call($)
{
    # Converts an eval string that calls test_utf8n_to_uvchr into a more human
    # readable form, and returns it.  Doesn't work if the byte string contains
    # an apostrophe.  The return will look something like:
    #   test_utf8n_to_uvchr_error('$bytes', $length, $flags)
    #diag $_[0];

    $_[0] =~ / ^ ( [^(]* \( ) ' ( [^']*? ) ' ( .+ , \D* ) ( \d+ ) \) $ /x;
    my $text1 = $1;     # Everything before the byte string
    my $bytes = $2;
    my $text2 = $3;     # Includes the length
    my $flags = $4;

    return $text1
         . display_bytes($bytes)
         . $text2
         . flags_to_text($flags, \@utf8n_flags_to_text)
         . ')';
}

sub uvchr_display_call($)
{
    # Converts an eval string that calls test_uvchr_to_utf8 into a more human
    # readable form, and returns it.  The return will look something like:
    #   test_uvchr_to_utf8n_flags($uv, $flags)
    #diag $_[0];

    my @flags_to_text =  ( qw(
            W_SURROGATE
            W_NONCHAR
            W_SUPER
            W_ABOVE_31_BIT
            D_SURROGATE
            D_NONCHAR
            D_SUPER
            D_ABOVE_31_BIT
       ) );

    $_[0] =~ / ^ ( [^(]* \( ) ( \d+ ) , \s* ( \d+ ) \) $ /x;
    my $text = $1;
    my $cp = sprintf "%X", $2;
    my $flags = $3;

    return "${text}0x$cp, " . flags_to_text($flags, \@flags_to_text) . ')';
}

# This test is split into this number of files.
my $num_test_files = $ENV{TEST_JOBS} || 1;
$num_test_files = 10 if $num_test_files > 10;

my $test_count = -1;
foreach my $test (@tests) {
    $test_count++;
    next if $test_count % $num_test_files != $::TEST_CHUNK;

    my ($testname, $bytes,
        $controlling_warning_category, $allowed_uv, $needed_to_discern_len
       ) = @$test;

    my $length = length $bytes;
    my $will_overflow = $allowed_uv < 0;

    my $uv_string = sprintf(($allowed_uv < 0x100) ? "%02X" : "%04X", $allowed_uv);

    my $utf8n_flag_to_warn;
    my $utf8n_flag_to_disallow;
    my $uvchr_flag_to_warn;
    my $uvchr_flag_to_disallow;

    # Many of the code points being tested are middling in that if code point
    # edge cases work, these are very likely to as well.  Because this test
    # file takes a while to execute, we skip testing the edge effects of code
    # points deemed middling, while testing their basics and continuing to
    # fully test the non-middling code points.
    my $skip_most_tests = 0;

    my $message;
    if ($will_overflow || $allowed_uv > 0x10FFFF) {

        $utf8n_flag_to_warn     = $::UTF8_WARN_SUPER;
        $utf8n_flag_to_disallow = $::UTF8_DISALLOW_SUPER;
        $uvchr_flag_to_warn     = $::UNICODE_WARN_SUPER;
        $uvchr_flag_to_disallow = $::UNICODE_DISALLOW_SUPER;;

        if ($will_overflow) {
            $message = qr/overflows/;
        }
        elsif ($allowed_uv > 0x7FFFFFFF) {
            $message = nonportable_regex($allowed_uv);
        }
        else  {
            $message = qr/(not Unicode|for a non-Unicode code point).* may not be portable/;
        }
    }
    elsif ($allowed_uv >= 0xD800 && $allowed_uv <= 0xDFFF) {
        $message = qr/surrogate/;
        $needed_to_discern_len = 2 unless defined $needed_to_discern_len;
        $skip_most_tests = 1 if $allowed_uv > 0xD800 && $allowed_uv < 0xDFFF;

        $utf8n_flag_to_warn     = $::UTF8_WARN_SURROGATE;
        $utf8n_flag_to_disallow = $::UTF8_DISALLOW_SURROGATE;
        $uvchr_flag_to_warn     = $::UNICODE_WARN_SURROGATE;
        $uvchr_flag_to_disallow = $::UNICODE_DISALLOW_SURROGATE;;
    }
    elsif (   ($allowed_uv >= 0xFDD0 && $allowed_uv <= 0xFDEF)
           || ($allowed_uv & 0xFFFE) == 0xFFFE)
    {
        $message = qr/Unicode non-character.*is not recommended for open interchange/;
        $needed_to_discern_len = $length unless defined $needed_to_discern_len;
        if (   ($allowed_uv > 0xFDD0 && $allowed_uv < 0xFDEF)
            || ($allowed_uv > 0xFFFF && $allowed_uv < 0x10FFFE))
        {
            $skip_most_tests = 1;
        }

        $utf8n_flag_to_warn     = $::UTF8_WARN_NONCHAR;
        $utf8n_flag_to_disallow = $::UTF8_DISALLOW_NONCHAR;
        $uvchr_flag_to_warn     = $::UNICODE_WARN_NONCHAR;
        $uvchr_flag_to_disallow = $::UNICODE_DISALLOW_NONCHAR;;
    }
    else {
        die "Can't figure out what type of warning to test for $testname"
    }

    die 'Didn\'t set $needed_to_discern_len for ' . $testname
                                        unless defined $needed_to_discern_len;
    my $disallow_flags = $utf8n_flag_to_disallow;
    my $warn_flags = $disallow_flags << 1;

    # The convention is that the got flag is the same value as the disallow
    # one, and the warn flag is the next bit over.  If this were violated, the
    # tests here should start failing.  We could do an eval under no strict to
    # be sure.
    my $expected_error_flags = $disallow_flags;

    {
        use warnings;
        undef @warnings_gotten;
        my $ret = test_isUTF8_CHAR($bytes, $length);
        my $ret_flags = test_isUTF8_CHAR_flags($bytes, $length, 0);
        if ($will_overflow) {
            is($ret, 0, "For $testname: isUTF8_CHAR() returns 0");
            is($ret_flags, 0, "    And isUTF8_CHAR_flags() returns 0");
        }
        else {
            is($ret, $length,
               "For $testname: isUTF8_CHAR() returns expected length: $length");
            is($ret_flags, $length, "    And isUTF8_CHAR_flags(...,0)"
                                  . " returns expected length: $length");
        }
        is(scalar @warnings_gotten, 0,
                "    And neither isUTF8_CHAR() nor isUTF8_CHAR()_flags generated"
              . " any warnings")
          or output_warnings(@warnings_gotten);

        undef @warnings_gotten;
        $ret = test_isSTRICT_UTF8_CHAR($bytes, $length);
        if ($will_overflow) {
            is($ret, 0, "    And isSTRICT_UTF8_CHAR() returns 0");
        }
        else {
            my $expected_ret = (   $testname =~ /surrogate|non-character/
                                || $allowed_uv > 0x10FFFF)
                               ? 0
                               : $length;
            is($ret, $expected_ret, "    And isSTRICT_UTF8_CHAR() returns"
                                  . " expected length: $expected_ret");
            $ret = test_isUTF8_CHAR_flags($bytes, $length,
                                          $::UTF8_DISALLOW_ILLEGAL_INTERCHANGE);
            is($ret, $expected_ret,
                    "    And isUTF8_CHAR_flags('DISALLOW_ILLEGAL_INTERCHANGE')"
                    . " acts like isSTRICT_UTF8_CHAR");
        }
        is(scalar @warnings_gotten, 0,
                "    And neither isSTRICT_UTF8_CHAR() nor isUTF8_CHAR_flags"
              . " generated any warnings")
          or output_warnings(@warnings_gotten);

        undef @warnings_gotten;
        $ret = test_isC9_STRICT_UTF8_CHAR($bytes, $length);
        if ($will_overflow) {
            is($ret, 0, "    And isC9_STRICT_UTF8_CHAR() returns 0");
        }
        else {
            my $expected_ret = (   $testname =~ /surrogate/
                                || $allowed_uv > 0x10FFFF)
                               ? 0
                               : $length;
            is($ret, $expected_ret, "    And isC9_STRICT_UTF8_CHAR()"
                                   ." returns expected length: $expected_ret");
            $ret = test_isUTF8_CHAR_flags($bytes, $length,
                                          $::UTF8_DISALLOW_ILLEGAL_C9_INTERCHANGE);
            is($ret, $expected_ret,
                  "    And isUTF8_CHAR_flags('DISALLOW_ILLEGAL_C9_INTERCHANGE')"
                . " acts like isC9_STRICT_UTF8_CHAR");
        }
        is(scalar @warnings_gotten, 0,
                "    And neither isC9_STRICT_UTF8_CHAR() nor isUTF8_CHAR_flags"
              . " generated any warnings")
          or output_warnings(@warnings_gotten);

        # Test partial character handling, for each byte not a full character
        for my $j (1.. $length - 1) {

            # Skip the test for the interaction between overflow and above-31
            # bit.  It is really testing other things than the partial
            # character tests, for which other tests in this file are
            # sufficient
            last if $will_overflow;

            foreach my $disallow_flag (0, $disallow_flags) {
                my $partial = substr($bytes, 0, $j);
                my $ret_should_be;
                my $comment;
                if ($disallow_flag) {
                    $ret_should_be = 0;
                    $comment = "disallowed";
                    if ($j < $needed_to_discern_len) {
                        $ret_should_be = 1;
                        $comment .= ", but need $needed_to_discern_len bytes"
                                 .  " to discern:";
                    }
                }
                else {
                    $ret_should_be = 1;
                    $comment = "allowed";
                }

                undef @warnings_gotten;

                $ret = test_is_utf8_valid_partial_char_flags($partial, $j,
                                                             $disallow_flag);
                is($ret, $ret_should_be,
                                "    And is_utf8_valid_partial_char_flags("
                              . display_bytes($partial)
                              . "), $comment: returns $ret_should_be");
                is(scalar @warnings_gotten, 0,
                        "    And is_utf8_valid_partial_char_flags()"
                      . " generated no warnings")
                  or output_warnings(@warnings_gotten);
            }
        }
    }

    # This is more complicated than the malformations tested earlier, as there
    # are several orthogonal variables involved.  We test all the subclasses
    # of utf8 warnings to verify they work with and without the utf8 class,
    # and don't have effects on other sublass warnings
    foreach my $trial_warning_category ('utf8', 'surrogate', 'nonchar', 'non_unicode') {
      next if $skip_most_tests && $trial_warning_category ne $controlling_warning_category;
      foreach my $warn_flag (0, $warn_flags) {
        next if $skip_most_tests && ! $warn_flag;
        foreach my $disallow_flag (0, $disallow_flags) {
          next if $skip_most_tests && ! $disallow_flag;
          foreach my $do_warning (0, 1) {
            next if $skip_most_tests && ! $do_warning;

            # We try each of the above with various combinations of
            # malformations that can occur on the same input sequence.
            foreach my $short ("", "short") {
              next if $skip_most_tests && $short;
              foreach my $unexpected_noncont ("",
                                              "unexpected non-continuation")
              {
                next if $skip_most_tests && $unexpected_noncont;
                foreach my $overlong ("", "overlong") {
                    next if $overlong && $skip_most_tests;

                    # If we're creating an overlong, it can't be longer than
                    # the maximum length, so skip if we're already at that
                    # length.
                    next if $overlong && $length >= $::max_bytes;

                    my @malformations;
                    my @expected_return_flags;
                    push @malformations, $short if $short;
                    push @malformations, $unexpected_noncont
                                                      if $unexpected_noncont;
                    push @malformations, $overlong if $overlong;

                    # The overflow malformation test in the input
                    # array is coerced into being treated like one of
                    # the others.
                    if ($will_overflow) {
                        push @malformations, 'overflow';
                        push @expected_return_flags, $::UTF8_GOT_OVERFLOW;
                    }

                    my $malformations_name = join "/", @malformations;
                    $malformations_name .= " malformation"
                                                if $malformations_name;
                    $malformations_name .= "s" if @malformations > 1;
                    my $this_bytes = $bytes;
                    my $this_length = $length;
                    my $expected_uv = $allowed_uv;
                    my $this_expected_len = $length;
                    my $this_needed_to_discern_len = $needed_to_discern_len;
                    if ($malformations_name) {
                        $expected_uv = 0;

                        # Coerce the input into the desired
                        # malformation
                        if ($malformations_name =~ /overlong/) {

                            # For an overlong, we convert the original
                            # start byte into a continuation byte with
                            # the same data bits as originally. ...
                            substr($this_bytes, 0, 1)
                                = start_byte_to_cont(substr($this_bytes,
                                                            0, 1));

                            # ... Then we prepend it with a known
                            # overlong sequence.  This should evaluate
                            # to the exact same code point as the
                            # original.
                            $this_bytes
                            = I8_to_native("\xff")
                            . (I8_to_native(chr $::lowest_continuation)
                            x ( $::max_bytes - 1 - length($this_bytes)))
                            . $this_bytes;
                            $this_length = length($this_bytes);
                            $this_needed_to_discern_len
                                 = $::max_bytes - ($this_expected_len
                                               - $this_needed_to_discern_len);
                            $this_expected_len = $::max_bytes;
                            push @expected_return_flags, $::UTF8_GOT_LONG;
                        }
                        if ($malformations_name =~ /short/) {

                            # Just tell the test to not look far
                            # enough into the input.
                            $this_length--;
                            $this_expected_len--;
                            push @expected_return_flags, $::UTF8_GOT_SHORT;
                        }
                        if ($malformations_name
                                                =~ /non-continuation/)
                        {
                            # Change the final continuation byte into
                            # a non one.
                            my $pos = ($short) ? -2 : -1;
                            substr($this_bytes, $pos, 1) = '?';
                            $this_expected_len--;
                            push @expected_return_flags,
                                            $::UTF8_GOT_NON_CONTINUATION;
                        }
                    }

                    my $eval_warn = $do_warning
                                ? "use warnings '$trial_warning_category'"
                                : $trial_warning_category eq "utf8"
                                    ? "no warnings 'utf8'"
                                    : ( "use warnings 'utf8';"
                                    . " no warnings '$trial_warning_category'");

                    # Is effectively disallowed if we've set up a
                    # malformation, even if the flag indicates it is
                    # allowed.  Fix up test name to indicate this as
                    # well
                    my $disallowed = $disallow_flag
                                || $malformations_name;
                    my $this_name = "utf8n_to_uvchr_error() $testname: "
                                                . (($disallow_flag)
                                                ? 'disallowed'
                                                : $disallowed
                                                    ? $disallowed
                                                    : 'allowed');
                    $this_name .= ", $eval_warn";
                    $this_name .= ", " . (($warn_flag)
                                        ? 'with warning flag'
                                        : 'no warning flag');

                    undef @warnings_gotten;
                    my $ret_ref;
                    my $this_flags = $warn_flag | $disallow_flag;
                    my $eval_text =      "$eval_warn; \$ret_ref"
                            . " = test_utf8n_to_uvchr_error("
                            . "'$this_bytes',"
                            . " $this_length, $this_flags)";
                    eval "$eval_text";
                    if (! ok ("$@ eq ''",
                        "$this_name: eval succeeded"))
                    {
                        diag "\$@='$@'; call was: "
                           . utf8n_display_call($eval_text);
                        next;
                    }
                    if ($disallowed) {
                        is($ret_ref->[0], 0, "    And returns 0")
                          or diag "Call was: " . utf8n_display_call($eval_text);
                    }
                    else {
                        is($ret_ref->[0], $expected_uv,
                                "    And returns expected uv: "
                              . $uv_string)
                          or diag "Call was: " . utf8n_display_call($eval_text);
                    }
                    is($ret_ref->[1], $this_expected_len,
                                        "    And returns expected length:"
                                      . " $this_expected_len")
                      or diag "Call was: " . utf8n_display_call($eval_text);

                    my $returned_flags = $ret_ref->[2];

                    for (my $i = @expected_return_flags - 1; $i >= 0; $i--) {
                        if (ok($expected_return_flags[$i] & $returned_flags,
                            "    Expected and got return flag"
                            . " for $malformations[$i] malformation"))
                        {
                            $returned_flags &= ~$expected_return_flags[$i];
                        }
                        splice @expected_return_flags, $i, 1;
                    }
                    is(scalar @expected_return_flags, 0,
                            "    Got all the expected malformation errors")
                      or diag Dumper \@expected_return_flags;

                    if (   $this_expected_len >= $this_needed_to_discern_len
                        && ($warn_flag || $disallow_flag))
                    {
                        is($returned_flags, $expected_error_flags,
                                "    Got the correct error flag")
                          or diag "Call was: " . utf8n_display_call($eval_text);
                    }
                    else {
                        is($returned_flags, 0, "    Got no other error flag")
                        or

                        # We strip off any prefixes from the flag names
                        diag "The unexpected flags were: "
                           . (flags_to_text($returned_flags,
                                            \@utf8n_flags_to_text)
                             =~ s/ \b [A-Z] _ //xgr);
                    }

                    if (@malformations) {
                        if (! $do_warning && $trial_warning_category eq 'utf8') {
                            goto no_warnings_expected;
                        }

                        # Check that each malformation generates a
                        # warning, removing that warning if found
                    MALFORMATION:
                        foreach my $malformation (@malformations) {
                            foreach (my $i = 0; $i < @warnings_gotten; $i++) {
                                if ($warnings_gotten[$i] =~ /$malformation/) {
                                    pass("    Expected and got"
                                    . "'$malformation' warning");
                                    splice @warnings_gotten, $i, 1;
                                    next MALFORMATION;
                                }
                            }
                            fail("    Expected '$malformation' warning"
                               . " but didn't get it");

                        }
                    }

                    # Any overflow will override any super or above-31
                    # warnings.
                    goto no_warnings_expected
                                if $will_overflow || $this_expected_len
                                        < $this_needed_to_discern_len;

                    if (    ! $do_warning
                        && (   $trial_warning_category eq 'utf8'
                            || $trial_warning_category eq $controlling_warning_category))
                    {
                        goto no_warnings_expected;
                    }
                    elsif ($warn_flag) {
                        if (is(scalar @warnings_gotten, 1,
                            "    Got a single warning "))
                        {
                            like($warnings_gotten[0], $message,
                                    "    Got expected warning")
                                or diag "Call was: "
                                      . utf8n_display_call($eval_text);
                        }
                        else {
                            diag "Call was: " . utf8n_display_call($eval_text);
                            if (scalar @warnings_gotten) {
                                output_warnings(@warnings_gotten);
                            }
                        }
                    }
                    else {

                    no_warnings_expected:
                        unless (is(scalar @warnings_gotten, 0,
                                "    Got no warnings"))
                        {
                            diag "Call was: " . utf8n_display_call($eval_text);
                            output_warnings(@warnings_gotten);
                        }
                    }

                    # Check CHECK_ONLY results when the input is
                    # disallowed.  Do this when actually disallowed,
                    # not just when the $disallow_flag is set
                    if ($disallowed) {
                        undef @warnings_gotten;
                        $this_flags = $disallow_flag|$::UTF8_CHECK_ONLY;
                        $eval_text = "\$ret_ref = test_utf8n_to_uvchr_error("
                                   . "'$this_bytes', $this_length, $this_flags)";
                        eval "$eval_text";
                        if (! ok ("$@ eq ''",
                            "    And eval succeeded with CHECK_ONLY"))
                        {
                            diag "\$@='$@'; Call was: "
                               . utf8n_display_call($eval_text);
                            next;
                        }
                        is($ret_ref->[0], 0, "    CHECK_ONLY: Returns 0")
                          or diag "Call was: " . utf8n_display_call($eval_text);
                        is($ret_ref->[1], -1,
                                       "    CHECK_ONLY: returns -1 for length")
                          or diag "Call was: " . utf8n_display_call($eval_text);
                        if (! is(scalar @warnings_gotten, 0,
                                      "    CHECK_ONLY: no warnings generated"))
                        {
                            diag "Call was: " . utf8n_display_call($eval_text);
                            output_warnings(@warnings_gotten);
                        }
                    }

                    # Now repeat some of the above, but for
                    # uvchr_to_utf8_flags().  Since this comes from an
                    # existing code point, it hasn't overflowed, and
                    # isn't malformed.
                    next if @malformations;

                    # The warning and disallow flags passed in are for
                    # utf8n_to_uvchr_error().  Convert them for
                    # uvchr_to_utf8_flags().
                    my $uvchr_warn_flag = 0;
                    my $uvchr_disallow_flag = 0;
                    if ($warn_flag) {
                        $uvchr_warn_flag = $uvchr_flag_to_warn;
                    }
                    if ($disallow_flag) {
                        $uvchr_disallow_flag = $uvchr_flag_to_disallow;
                    }

                    $disallowed = $uvchr_disallow_flag;

                    $this_name = "uvchr_to_utf8_flags() $testname: "
                                            . (($uvchr_disallow_flag)
                                                ? 'disallowed'
                                                : ($disallowed)
                                                ? 'ABOVE_31_BIT allowed'
                                                : 'allowed');
                    $this_name .= ", $eval_warn";
                    $this_name .= ", " . (($uvchr_warn_flag)
                                        ? 'with warning flag'
                                        : 'no warning flag');

                    undef @warnings_gotten;
                    my $ret;
                    $this_flags = $uvchr_warn_flag | $uvchr_disallow_flag;
                    $eval_text = "$eval_warn; \$ret ="
                            . " test_uvchr_to_utf8_flags("
                            . "$allowed_uv, $this_flags)";
                    eval "$eval_text";
                    if (! ok ("$@ eq ''", "$this_name: eval succeeded"))
                    {
                        diag "\$@='$@'; call was: "
                           . uvchr_display_call($eval_text);
                        next;
                    }
                    if ($disallowed) {
                        is($ret, undef, "    And returns undef")
                          or diag "Call was: " . uvchr_display_call($eval_text);
                    }
                    else {
                        is($ret, $this_bytes, "    And returns expected string")
                          or diag "Call was: " . uvchr_display_call($eval_text);
                    }
                    if (! $do_warning
                        && ($trial_warning_category eq 'utf8' || $trial_warning_category eq $controlling_warning_category))
                    {
                        if (!is(scalar @warnings_gotten, 0,
                                "    No warnings generated"))
                        {
                            diag "Call was: " . uvchr_display_call($eval_text);
                            output_warnings(@warnings_gotten);
                        }
                    }
                    elsif (       $uvchr_warn_flag
                        && (   $trial_warning_category eq 'utf8'
                            || $trial_warning_category eq $controlling_warning_category))
                    {
                        if (is(scalar @warnings_gotten, 1,
                            "    Got a single warning "))
                        {
                            like($warnings_gotten[0], $message,
                                    "    Got expected warning")
                                or diag "Call was: "
                                      . uvchr_display_call($eval_text);
                        }
                        else {
                            diag "Call was: " . uvchr_display_call($eval_text);
                            output_warnings(@warnings_gotten)
                                                if scalar @warnings_gotten;
                        }
                    }
                }
              }
            }
          }
        }
      }
    }
}

done_testing;
