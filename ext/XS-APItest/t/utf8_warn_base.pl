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

my @warnings;

use warnings 'utf8';
local $SIG{__WARN__} = sub { push @warnings, @_ };

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
     # ($testname, $bytes, $warn_flags, $disallow_flags, $expected_error_flags,
     #  $category, $allowed_uv, $expected_len, $needed_to_discern_len, $message )
    [ "lowest surrogate",
        (isASCII) ? "\xed\xa0\x80" : I8_to_native("\xf1\xb6\xa0\xa0"),
        $::UTF8_WARN_SURROGATE, $::UTF8_DISALLOW_SURROGATE, $::UTF8_GOT_SURROGATE,
        'surrogate', 0xD800,
        (isASCII) ? 3 : 4,
        2,
        qr/surrogate/
    ],
    [ "a middle surrogate",
        (isASCII) ? "\xed\xa4\x8d" : I8_to_native("\xf1\xb6\xa8\xad"),
        $::UTF8_WARN_SURROGATE, $::UTF8_DISALLOW_SURROGATE, $::UTF8_GOT_SURROGATE,
        'surrogate', 0xD90D,
        (isASCII) ? 3 : 4,
        2,
        qr/surrogate/
    ],
    [ "highest surrogate",
        (isASCII) ? "\xed\xbf\xbf" : I8_to_native("\xf1\xb7\xbf\xbf"),
        $::UTF8_WARN_SURROGATE, $::UTF8_DISALLOW_SURROGATE, $::UTF8_GOT_SURROGATE,
        'surrogate', 0xDFFF,
        (isASCII) ? 3 : 4,
        2,
        qr/surrogate/
    ],
    [ "first non_unicode",
        (isASCII) ? "\xf4\x90\x80\x80" : I8_to_native("\xf9\xa2\xa0\xa0\xa0"),
        $::UTF8_WARN_SUPER, $::UTF8_DISALLOW_SUPER, $::UTF8_GOT_SUPER,
        'non_unicode', 0x110000,
        (isASCII) ? 4 : 5,
        2,
        qr/(not Unicode|for a non-Unicode code point).* may not be portable/
    ],
    [ "non_unicode whose first byte tells that",
        (isASCII) ? "\xf5\x80\x80\x80" : I8_to_native("\xfa\xa0\xa0\xa0\xa0"),
        $::UTF8_WARN_SUPER, $::UTF8_DISALLOW_SUPER, $::UTF8_GOT_SUPER,
        'non_unicode',
        (isASCII) ? 0x140000 : 0x200000,
        (isASCII) ? 4 : 5,
        1,
        qr/(not Unicode|for a non-Unicode code point).* may not be portable/
    ],
    [ "first of 32 consecutive non-character code points",
        (isASCII) ? "\xef\xb7\x90" : I8_to_native("\xf1\xbf\xae\xb0"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0xFDD0,
        (isASCII) ? 3 : 4,
        (isASCII) ? 3 : 4,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "a mid non-character code point of the 32 consecutive ones",
        (isASCII) ? "\xef\xb7\xa0" : I8_to_native("\xf1\xbf\xaf\xa0"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0xFDE0,
        (isASCII) ? 3 : 4,
        (isASCII) ? 3 : 4,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "final of 32 consecutive non-character code points",
        (isASCII) ? "\xef\xb7\xaf" : I8_to_native("\xf1\xbf\xaf\xaf"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0xFDEF,
        (isASCII) ? 3 : 4,
        (isASCII) ? 3 : 4,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+FFFE",
        (isASCII) ? "\xef\xbf\xbe" : I8_to_native("\xf1\xbf\xbf\xbe"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0xFFFE,
        (isASCII) ? 3 : 4,
        (isASCII) ? 3 : 4,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+FFFF",
        (isASCII) ? "\xef\xbf\xbf" : I8_to_native("\xf1\xbf\xbf\xbf"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0xFFFF,
        (isASCII) ? 3 : 4,
        (isASCII) ? 3 : 4,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+1FFFE",
        (isASCII) ? "\xf0\x9f\xbf\xbe" : I8_to_native("\xf3\xbf\xbf\xbe"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0x1FFFE,
        4, 4,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+1FFFF",
        (isASCII) ? "\xf0\x9f\xbf\xbf" : I8_to_native("\xf3\xbf\xbf\xbf"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0x1FFFF,
        4, 4,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+2FFFE",
        (isASCII) ? "\xf0\xaf\xbf\xbe" : I8_to_native("\xf5\xbf\xbf\xbe"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0x2FFFE,
        4, 4,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+2FFFF",
        (isASCII) ? "\xf0\xaf\xbf\xbf" : I8_to_native("\xf5\xbf\xbf\xbf"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0x2FFFF,
        4, 4,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+3FFFE",
        (isASCII) ? "\xf0\xbf\xbf\xbe" : I8_to_native("\xf7\xbf\xbf\xbe"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0x3FFFE,
        4, 4,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+3FFFF",
        (isASCII) ? "\xf0\xbf\xbf\xbf" : I8_to_native("\xf7\xbf\xbf\xbf"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0x3FFFF,
        4, 4,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+4FFFE",
        (isASCII) ? "\xf1\x8f\xbf\xbe" : I8_to_native("\xf8\xa9\xbf\xbf\xbe"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0x4FFFE,
        (isASCII) ? 4 : 5,
        (isASCII) ? 4 : 5,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+4FFFF",
        (isASCII) ? "\xf1\x8f\xbf\xbf" : I8_to_native("\xf8\xa9\xbf\xbf\xbf"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0x4FFFF,
        (isASCII) ? 4 : 5,
        (isASCII) ? 4 : 5,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+5FFFE",
        (isASCII) ? "\xf1\x9f\xbf\xbe" : I8_to_native("\xf8\xab\xbf\xbf\xbe"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0x5FFFE,
        (isASCII) ? 4 : 5,
        (isASCII) ? 4 : 5,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+5FFFF",
        (isASCII) ? "\xf1\x9f\xbf\xbf" : I8_to_native("\xf8\xab\xbf\xbf\xbf"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0x5FFFF,
        (isASCII) ? 4 : 5,
        (isASCII) ? 4 : 5,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+6FFFE",
        (isASCII) ? "\xf1\xaf\xbf\xbe" : I8_to_native("\xf8\xad\xbf\xbf\xbe"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0x6FFFE,
        (isASCII) ? 4 : 5,
        (isASCII) ? 4 : 5,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+6FFFF",
        (isASCII) ? "\xf1\xaf\xbf\xbf" : I8_to_native("\xf8\xad\xbf\xbf\xbf"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0x6FFFF,
        (isASCII) ? 4 : 5,
        (isASCII) ? 4 : 5,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+7FFFE",
        (isASCII) ? "\xf1\xbf\xbf\xbe" : I8_to_native("\xf8\xaf\xbf\xbf\xbe"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0x7FFFE,
        (isASCII) ? 4 : 5,
        (isASCII) ? 4 : 5,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+7FFFF",
        (isASCII) ? "\xf1\xbf\xbf\xbf" : I8_to_native("\xf8\xaf\xbf\xbf\xbf"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0x7FFFF,
        (isASCII) ? 4 : 5,
        (isASCII) ? 4 : 5,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+8FFFE",
        (isASCII) ? "\xf2\x8f\xbf\xbe" : I8_to_native("\xf8\xb1\xbf\xbf\xbe"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0x8FFFE,
        (isASCII) ? 4 : 5,
        (isASCII) ? 4 : 5,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+8FFFF",
        (isASCII) ? "\xf2\x8f\xbf\xbf" : I8_to_native("\xf8\xb1\xbf\xbf\xbf"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0x8FFFF,
        (isASCII) ? 4 : 5,
        (isASCII) ? 4 : 5,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+9FFFE",
        (isASCII) ? "\xf2\x9f\xbf\xbe" : I8_to_native("\xf8\xb3\xbf\xbf\xbe"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0x9FFFE,
        (isASCII) ? 4 : 5,
        (isASCII) ? 4 : 5,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+9FFFF",
        (isASCII) ? "\xf2\x9f\xbf\xbf" : I8_to_native("\xf8\xb3\xbf\xbf\xbf"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0x9FFFF,
        (isASCII) ? 4 : 5,
        (isASCII) ? 4 : 5,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+AFFFE",
        (isASCII) ? "\xf2\xaf\xbf\xbe" : I8_to_native("\xf8\xb5\xbf\xbf\xbe"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0xAFFFE,
        (isASCII) ? 4 : 5,
        (isASCII) ? 4 : 5,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+AFFFF",
        (isASCII) ? "\xf2\xaf\xbf\xbf" : I8_to_native("\xf8\xb5\xbf\xbf\xbf"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0xAFFFF,
        (isASCII) ? 4 : 5,
        (isASCII) ? 4 : 5,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+BFFFE",
        (isASCII) ? "\xf2\xbf\xbf\xbe" : I8_to_native("\xf8\xb7\xbf\xbf\xbe"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0xBFFFE,
        (isASCII) ? 4 : 5,
        (isASCII) ? 4 : 5,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+BFFFF",
        (isASCII) ? "\xf2\xbf\xbf\xbf" : I8_to_native("\xf8\xb7\xbf\xbf\xbf"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0xBFFFF,
        (isASCII) ? 4 : 5,
        (isASCII) ? 4 : 5,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+CFFFE",
        (isASCII) ? "\xf3\x8f\xbf\xbe" : I8_to_native("\xf8\xb9\xbf\xbf\xbe"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0xCFFFE,
        (isASCII) ? 4 : 5,
        (isASCII) ? 4 : 5,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+CFFFF",
        (isASCII) ? "\xf3\x8f\xbf\xbf" : I8_to_native("\xf8\xb9\xbf\xbf\xbf"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0xCFFFF,
        (isASCII) ? 4 : 5,
        (isASCII) ? 4 : 5,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+DFFFE",
        (isASCII) ? "\xf3\x9f\xbf\xbe" : I8_to_native("\xf8\xbb\xbf\xbf\xbe"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0xDFFFE,
        (isASCII) ? 4 : 5,
        (isASCII) ? 4 : 5,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+DFFFF",
        (isASCII) ? "\xf3\x9f\xbf\xbf" : I8_to_native("\xf8\xbb\xbf\xbf\xbf"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0xDFFFF,
        (isASCII) ? 4 : 5,
        (isASCII) ? 4 : 5,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+EFFFE",
        (isASCII) ? "\xf3\xaf\xbf\xbe" : I8_to_native("\xf8\xbd\xbf\xbf\xbe"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0xEFFFE,
        (isASCII) ? 4 : 5,
        (isASCII) ? 4 : 5,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+EFFFF",
        (isASCII) ? "\xf3\xaf\xbf\xbf" : I8_to_native("\xf8\xbd\xbf\xbf\xbf"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0xEFFFF,
        (isASCII) ? 4 : 5,
        (isASCII) ? 4 : 5,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+FFFFE",
        (isASCII) ? "\xf3\xbf\xbf\xbe" : I8_to_native("\xf8\xbf\xbf\xbf\xbe"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0xFFFFE,
        (isASCII) ? 4 : 5,
        (isASCII) ? 4 : 5,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+FFFFF",
        (isASCII) ? "\xf3\xbf\xbf\xbf" : I8_to_native("\xf8\xbf\xbf\xbf\xbf"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0xFFFFF,
        (isASCII) ? 4 : 5,
        (isASCII) ? 4 : 5,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+10FFFE",
        (isASCII) ? "\xf4\x8f\xbf\xbe" : I8_to_native("\xf9\xa1\xbf\xbf\xbe"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0x10FFFE,
        (isASCII) ? 4 : 5,
        (isASCII) ? 4 : 5,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
    [ "non-character code point U+10FFFF",
        (isASCII) ? "\xf4\x8f\xbf\xbf" : I8_to_native("\xf9\xa1\xbf\xbf\xbf"),
        $::UTF8_WARN_NONCHAR, $::UTF8_DISALLOW_NONCHAR, $::UTF8_GOT_NONCHAR,
        'nonchar', 0x10FFFF,
        (isASCII) ? 4 : 5,
        (isASCII) ? 4 : 5,
        qr/Unicode non-character.*is not recommended for open interchange/
    ],
);

if (! $::is64bit) {
    if (isASCII) {
        no warnings qw{portable overflow};
        push @tests,
            [ "Lowest 33 bit code point: overflow",
                "\xFE\x84\x80\x80\x80\x80\x80",
                $::UTF8_WARN_ABOVE_31_BIT, $::UTF8_DISALLOW_ABOVE_31_BIT,
                $::UTF8_GOT_ABOVE_31_BIT,
                'utf8', 0x100000000,
                7, 1,
                qr/and( is)? not portable/
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
            $::UTF8_WARN_ABOVE_31_BIT, $::UTF8_DISALLOW_ABOVE_31_BIT,
            $::UTF8_GOT_ABOVE_31_BIT,
            'utf8', 0x1000000000,
            $::max_bytes, (isASCII) ? 1 : 7,
            qr/and( is)? not portable/
        ];
        [ "requires at least 32 bits",
            (isASCII)
             ?  "\xfe\x82\x80\x80\x80\x80\x80"
             : I8_to_native(
                "\xff\xa0\xa0\xa0\xa0\xa0\xa0\xa2\xa0\xa0\xa0\xa0\xa0\xa0"),
            # This code point is chosen so that it is representable in a UV on
            # 32-bit machines
            $::UTF8_WARN_ABOVE_31_BIT, $::UTF8_DISALLOW_ABOVE_31_BIT,
            $::UTF8_GOT_ABOVE_31_BIT,
            'utf8', 0x80000000,
            (isASCII) ? 7 : $::max_bytes,
            (isASCII) ? 1 : 8,
            nonportable_regex(0x80000000)
        ],
        [ "highest 32 bit code point",
            (isASCII)
             ?  "\xfe\x83\xbf\xbf\xbf\xbf\xbf"
             : I8_to_native(
                "\xff\xa0\xa0\xa0\xa0\xa0\xa0\xa3\xbf\xbf\xbf\xbf\xbf\xbf"),
            $::UTF8_WARN_ABOVE_31_BIT, $::UTF8_DISALLOW_ABOVE_31_BIT,
            $::UTF8_GOT_ABOVE_31_BIT,
            'utf8', 0xFFFFFFFF,
            (isASCII) ? 7 : $::max_bytes,
            (isASCII) ? 1 : 8,
            nonportable_regex(0xffffffff)
        ],
        [ "requires at least 32 bits, and use SUPER-type flags, instead of"
        . " ABOVE_31_BIT",
            (isASCII)
             ? "\xfe\x82\x80\x80\x80\x80\x80"
             : I8_to_native(
               "\xff\xa0\xa0\xa0\xa0\xa0\xa0\xa2\xa0\xa0\xa0\xa0\xa0\xa0"),
            $::UTF8_WARN_SUPER, $::UTF8_DISALLOW_SUPER, $::UTF8_GOT_SUPER,
            'utf8', 0x80000000,
            (isASCII) ? 7 : $::max_bytes,
            1,
            nonportable_regex(0x80000000)
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
            ((isASCII)
               ?    "\xff\x80\x90\x90\x90\xbf\xbf\xbf\xbf\xbf\xbf\xbf\xbf"
               : I8_to_native(
                    "\xff\xB0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0")),
            $::UTF8_WARN_ABOVE_31_BIT,
            $::UTF8_DISALLOW_ABOVE_31_BIT,
            $::UTF8_GOT_ABOVE_31_BIT,
            'utf8', 0,
            (! isASCII || $::is64bit) ? $::max_bytes : 7,
            (isASCII || $::is64bit) ? 2 : 8,
            qr/overflows/
        ];

    if (! isASCII) {
        push @tests,   # These could falsely show wrongly in a naive
                       # implementation
            [ "requires at least 32 bits",
                I8_to_native(
                    "\xff\xa0\xa0\xa0\xa0\xa0\xa1\xa0\xa0\xa0\xa0\xa0\xa0\xa0"),
                $::UTF8_WARN_ABOVE_31_BIT,$::UTF8_DISALLOW_ABOVE_31_BIT,
                $::UTF8_GOT_ABOVE_31_BIT,
                'utf8', 0x800000000,
                $::max_bytes, 7,
                nonportable_regex(0x80000000)
            ],
            [ "requires at least 32 bits",
                I8_to_native(
                    "\xff\xa0\xa0\xa0\xa0\xa1\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0"),
                $::UTF8_WARN_ABOVE_31_BIT,$::UTF8_DISALLOW_ABOVE_31_BIT,
                $::UTF8_GOT_ABOVE_31_BIT,
                'utf8', 0x10000000000,
                $::max_bytes, 6,
                nonportable_regex(0x10000000000)
            ],
            [ "requires at least 32 bits",
                I8_to_native(
                    "\xff\xa0\xa0\xa0\xa1\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0"),
                $::UTF8_WARN_ABOVE_31_BIT,$::UTF8_DISALLOW_ABOVE_31_BIT,
                $::UTF8_GOT_ABOVE_31_BIT,
                'utf8', 0x200000000000,
                $::max_bytes, 5,
                nonportable_regex(0x20000000000)
            ],
            [ "requires at least 32 bits",
                I8_to_native(
                    "\xff\xa0\xa0\xa1\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0"),
                $::UTF8_WARN_ABOVE_31_BIT,$::UTF8_DISALLOW_ABOVE_31_BIT,
                $::UTF8_GOT_ABOVE_31_BIT,
                'utf8', 0x4000000000000,
                $::max_bytes, 4,
                nonportable_regex(0x4000000000000)
            ],
            [ "requires at least 32 bits",
                I8_to_native(
                    "\xff\xa0\xa1\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0"),
                $::UTF8_WARN_ABOVE_31_BIT,$::UTF8_DISALLOW_ABOVE_31_BIT,
                $::UTF8_GOT_ABOVE_31_BIT,
                'utf8', 0x80000000000000,
                $::max_bytes, 3,
                nonportable_regex(0x80000000000000)
            ],
            [ "requires at least 32 bits",
                I8_to_native(
                    "\xff\xa1\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0"),
                $::UTF8_WARN_ABOVE_31_BIT,$::UTF8_DISALLOW_ABOVE_31_BIT,
                $::UTF8_GOT_ABOVE_31_BIT,
                'utf8', 0x1000000000000000,
                $::max_bytes, 2,
                nonportable_regex(0x1000000000000000)
            ];
    }
}

# This test is split into this number of files.
my $num_test_files = $ENV{TEST_JOBS} || 1;
$num_test_files = 10 if $num_test_files > 10;

my $test_count = -1;
foreach my $test (@tests) {
    $test_count++;
    next if $test_count % $num_test_files != $::TEST_CHUNK;

    my ($testname, $bytes, $warn_flags, $disallow_flags, $expected_error_flags,
        $category, $allowed_uv, $expected_len, $needed_to_discern_len, $message
       ) = @$test;

    my $length = length $bytes;
    my $will_overflow = $testname =~ /overflow/ ? 'overflow' : "";

    {
        use warnings;
        undef @warnings;
        my $ret = test_isUTF8_CHAR($bytes, $length);
        my $ret_flags = test_isUTF8_CHAR_flags($bytes, $length, 0);
        if ($will_overflow) {
            is($ret, 0, "isUTF8_CHAR() $testname: returns 0");
            is($ret_flags, 0, "isUTF8_CHAR_flags() $testname: returns 0");
        }
        else {
            is($ret, $length,
               "isUTF8_CHAR() $testname: returns expected length: $length");
            is($ret_flags, $length, "isUTF8_CHAR_flags(...,0) $testname:"
                                  . " returns expected length: $length");
        }
        is(scalar @warnings, 0,
                "isUTF8_CHAR() and isUTF8_CHAR()_flags $testname: generated"
              . " no warnings")
          or output_warnings(@warnings);

        undef @warnings;
        $ret = test_isSTRICT_UTF8_CHAR($bytes, $length);
        if ($will_overflow) {
            is($ret, 0, "isSTRICT_UTF8_CHAR() $testname: returns 0");
        }
        else {
            my $expected_ret = (   $testname =~ /surrogate|non-character/
                                || $allowed_uv > 0x10FFFF)
                               ? 0
                               : $length;
            is($ret, $expected_ret, "isSTRICT_UTF8_CHAR() $testname: returns"
                                  . " expected length: $expected_ret");
            $ret = test_isUTF8_CHAR_flags($bytes, $length,
                                          $::UTF8_DISALLOW_ILLEGAL_INTERCHANGE);
            is($ret, $expected_ret,
                            "isUTF8_CHAR_flags('DISALLOW_ILLEGAL_INTERCHANGE')"
                          . " acts like isSTRICT_UTF8_CHAR");
        }
        is(scalar @warnings, 0,
                "isSTRICT_UTF8_CHAR() and isUTF8_CHAR_flags $testname:"
              . " generated no warnings")
          or output_warnings(@warnings);

        undef @warnings;
        $ret = test_isC9_STRICT_UTF8_CHAR($bytes, $length);
        if ($will_overflow) {
            is($ret, 0, "isC9_STRICT_UTF8_CHAR() $testname: returns 0");
        }
        else {
            my $expected_ret = (   $testname =~ /surrogate/
                                || $allowed_uv > 0x10FFFF)
                               ? 0
                               : $length;
            is($ret, $expected_ret, "isC9_STRICT_UTF8_CHAR() $testname:"
                                   ." returns expected length: $expected_ret");
            $ret = test_isUTF8_CHAR_flags($bytes, $length,
                                          $::UTF8_DISALLOW_ILLEGAL_C9_INTERCHANGE);
            is($ret, $expected_ret,
                          "isUTF8_CHAR_flags('DISALLOW_ILLEGAL_C9_INTERCHANGE')"
                        . " acts like isC9_STRICT_UTF8_CHAR");
        }
        is(scalar @warnings, 0,
                "isC9_STRICT_UTF8_CHAR() and isUTF8_CHAR_flags $testname:"
              . " generated no warnings")
          or output_warnings(@warnings);

        # Test partial character handling, for each byte not a full character
        for my $j (1.. $length - 1) {

            # Skip the test for the interaction between overflow and above-31
            # bit.  It is really testing other things than the partial
            # character tests, for which other tests in this file are
            # sufficient
            last if $testname =~ /overflow/;

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

                undef @warnings;

                $ret = test_is_utf8_valid_partial_char_flags($partial, $j,
                                                             $disallow_flag);
                is($ret, $ret_should_be,
                                "$testname: is_utf8_valid_partial_char_flags("
                                        . display_bytes($partial)
                                        . "), $comment: returns $ret_should_be");
                is(scalar @warnings, 0,
                        "$testname: is_utf8_valid_partial_char_flags()"
                      . " generated no warnings")
                  or output_warnings(@warnings);
            }
        }
    }

    # This is more complicated than the malformations tested earlier, as there
    # are several orthogonal variables involved.  We test all the subclasses
    # of utf8 warnings to verify they work with and without the utf8 class,
    # and don't have effects on other sublass warnings
    foreach my $warning ('utf8', 'surrogate', 'nonchar', 'non_unicode') {
      foreach my $warn_flag (0, $warn_flags) {
        foreach my $disallow_flag (0, $disallow_flags) {
          foreach my $do_warning (0, 1) {

            # We try each of the above with various combinations of
            # malformations that can occur on the same input sequence.
            foreach my $short ("", "short") {
              foreach my $unexpected_noncont ("",
                                              "unexpected non-continuation")
              {
                foreach my $overlong ("", "overlong") {

                    # If we're already at the longest possible, we
                    # can't create an overlong (which would be longer)
                    # can't handle anything larger.
                    next if $overlong && $expected_len >= $::max_bytes;

                    my @malformations;
                    my @expected_errors;
                    push @malformations, $short if $short;
                    push @malformations, $unexpected_noncont
                                                      if $unexpected_noncont;
                    push @malformations, $overlong if $overlong;

                    # The overflow malformation test in the input
                    # array is coerced into being treated like one of
                    # the others.
                    if ($will_overflow) {
                        push @malformations, 'overflow';
                        push @expected_errors, $::UTF8_GOT_OVERFLOW;
                    }

                    my $malformations_name = join "/", @malformations;
                    $malformations_name .= " malformation"
                                                if $malformations_name;
                    $malformations_name .= "s" if @malformations > 1;
                    my $this_bytes = $bytes;
                    my $this_length = $length;
                    my $expected_uv = $allowed_uv;
                    my $this_expected_len = $expected_len;
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
                            . (I8_to_native(chr $::first_continuation)
                            x ( $::max_bytes - 1 - length($this_bytes)))
                            . $this_bytes;
                            $this_length = length($this_bytes);
                            $this_needed_to_discern_len
                                 = $::max_bytes - ($this_expected_len
                                               - $this_needed_to_discern_len);
                            $this_expected_len = $::max_bytes;
                            push @expected_errors, $::UTF8_GOT_LONG;
                        }
                        if ($malformations_name =~ /short/) {

                            # Just tell the test to not look far
                            # enough into the input.
                            $this_length--;
                            $this_expected_len--;
                            push @expected_errors, $::UTF8_GOT_SHORT;
                        }
                        if ($malformations_name
                                                =~ /non-continuation/)
                        {
                            # Change the final continuation byte into
                            # a non one.
                            my $pos = ($short) ? -2 : -1;
                            substr($this_bytes, $pos, 1) = '?';
                            $this_expected_len--;
                            push @expected_errors,
                                            $::UTF8_GOT_NON_CONTINUATION;
                        }
                    }

                    my $eval_warn = $do_warning
                                ? "use warnings '$warning'"
                                : $warning eq "utf8"
                                    ? "no warnings 'utf8'"
                                    : ( "use warnings 'utf8';"
                                    . " no warnings '$warning'");

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

                    undef @warnings;
                    my $ret_ref;
                    my $display_bytes = display_bytes($this_bytes);
                    my $call = "    Call was: $eval_warn; \$ret_ref"
                            . " = test_utf8n_to_uvchr_error("
                            . "'$display_bytes', $this_length,"
                            . "$warn_flag"
                            . "|$disallow_flag)";
                    my $eval_text =      "$eval_warn; \$ret_ref"
                            . " = test_utf8n_to_uvchr_error("
                            . "'$this_bytes',"
                            . " $this_length, $warn_flag"
                            . "|$disallow_flag)";
                    eval "$eval_text";
                    if (! ok ("$@ eq ''",
                        "$this_name: eval succeeded"))
                    {
                        diag "\$!='$!'; eval'd=\"$call\"";
                        next;
                    }
                    if ($disallowed) {
                        is($ret_ref->[0], 0, "$this_name: Returns 0")
                          or diag $call;
                    }
                    else {
                        is($ret_ref->[0], $expected_uv,
                                "$this_name: Returns expected uv: "
                                . sprintf("0x%04X", $expected_uv))
                          or diag $call;
                    }
                    is($ret_ref->[1], $this_expected_len,
                                        "$this_name: Returns expected length:"
                                      . " $this_expected_len")
                      or diag $call;

                    my $errors = $ret_ref->[2];

                    for (my $i = @expected_errors - 1; $i >= 0; $i--) {
                        if (ok($expected_errors[$i] & $errors,
                            "Expected and got error bit return"
                            . " for $malformations[$i] malformation"))
                        {
                            $errors &= ~$expected_errors[$i];
                        }
                        splice @expected_errors, $i, 1;
                    }
                    is(scalar @expected_errors, 0,
                            "Got all the expected malformation errors")
                      or diag Dumper \@expected_errors;

                    if (   $this_expected_len >= $this_needed_to_discern_len
                        && ($warn_flag || $disallow_flag))
                    {
                        is($errors, $expected_error_flags,
                                "Got the correct error flag")
                          or diag $call;
                    }
                    else {
                        is($errors, 0, "Got no other error flag");
                    }

                    if (@malformations) {
                        if (! $do_warning && $warning eq 'utf8') {
                            goto no_warnings_expected;
                        }

                        # Check that each malformation generates a
                        # warning, removing that warning if found
                    MALFORMATION:
                        foreach my $malformation (@malformations) {
                            foreach (my $i = 0; $i < @warnings; $i++) {
                                if ($warnings[$i] =~ /$malformation/) {
                                    pass("Expected and got"
                                    . "'$malformation' warning");
                                    splice @warnings, $i, 1;
                                    next MALFORMATION;
                                }
                            }
                            fail("Expected '$malformation' warning"
                            . " but didn't get it");

                        }
                    }

                    # Any overflow will override any super or above-31
                    # warnings.
                    goto no_warnings_expected
                                if $will_overflow || $this_expected_len
                                        < $this_needed_to_discern_len;

                    if (    ! $do_warning
                        && (   $warning eq 'utf8'
                            || $warning eq $category))
                    {
                        goto no_warnings_expected;
                    }
                    elsif ($warn_flag) {
                        if (is(scalar @warnings, 1,
                            "$this_name: Got a single warning "))
                        {
                            like($warnings[0], $message,
                                    "$this_name: Got expected warning")
                                or diag $call;
                        }
                        else {
                            diag $call;
                            if (scalar @warnings) {
                                output_warnings(@warnings);
                            }
                        }
                    }
                    else {
                    no_warnings_expected:
                        unless (is(scalar @warnings, 0,
                                "$this_name: Got no warnings"))
                        {
                            diag $call;
                            output_warnings(@warnings);
                        }
                    }

                    # Check CHECK_ONLY results when the input is
                    # disallowed.  Do this when actually disallowed,
                    # not just when the $disallow_flag is set
                    if ($disallowed) {
                        undef @warnings;
                        $ret_ref = test_utf8n_to_uvchr_error(
                                    $this_bytes, $this_length,
                                    $disallow_flag|$::UTF8_CHECK_ONLY);
                        is($ret_ref->[0], 0,
                                        "$this_name, CHECK_ONLY: Returns 0")
                          or diag $call;
                        is($ret_ref->[1], -1,
                            "$this_name: CHECK_ONLY: returns -1 for length")
                          or diag $call;
                        if (! is(scalar @warnings, 0,
                            "$this_name, CHECK_ONLY: no warnings"
                        . " generated"))
                        {
                            diag $call;
                            output_warnings(@warnings);
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
                        if ($warn_flag == $::UTF8_WARN_SURROGATE) {
                            $uvchr_warn_flag = $::UNICODE_WARN_SURROGATE
                        }
                        elsif ($warn_flag == $::UTF8_WARN_NONCHAR) {
                            $uvchr_warn_flag = $::UNICODE_WARN_NONCHAR
                        }
                        elsif ($warn_flag == $::UTF8_WARN_SUPER) {
                            $uvchr_warn_flag = $::UNICODE_WARN_SUPER
                        }
                        elsif ($warn_flag == $::UTF8_WARN_ABOVE_31_BIT) {
                            $uvchr_warn_flag
                                        = $::UNICODE_WARN_ABOVE_31_BIT;
                        }
                        else {
                            fail(sprintf "Unexpected warn flag: %x",
                                $warn_flag);
                            next;
                        }
                    }
                    if ($disallow_flag) {
                        if ($disallow_flag == $::UTF8_DISALLOW_SURROGATE)
                        {
                            $uvchr_disallow_flag
                                        = $::UNICODE_DISALLOW_SURROGATE;
                        }
                        elsif ($disallow_flag == $::UTF8_DISALLOW_NONCHAR)
                        {
                            $uvchr_disallow_flag
                                        = $::UNICODE_DISALLOW_NONCHAR;
                        }
                        elsif ($disallow_flag == $::UTF8_DISALLOW_SUPER) {
                            $uvchr_disallow_flag
                                        = $::UNICODE_DISALLOW_SUPER;
                        }
                        elsif ($disallow_flag
                                        == $::UTF8_DISALLOW_ABOVE_31_BIT)
                        {
                            $uvchr_disallow_flag =
                                        $::UNICODE_DISALLOW_ABOVE_31_BIT;
                        }
                        else {
                            fail(sprintf "Unexpected disallow flag: %x",
                                $disallow_flag);
                            next;
                        }
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

                    undef @warnings;
                    my $ret;
                    my $warn_flag = sprintf "0x%x", $uvchr_warn_flag;
                    my $disallow_flag = sprintf "0x%x",
                                                $uvchr_disallow_flag;
                    $call = sprintf("    Call was: $eval_warn; \$ret"
                                . " = test_uvchr_to_utf8_flags("
                                . " 0x%x, $warn_flag|$disallow_flag)",
                                $allowed_uv);
                    $eval_text = "$eval_warn; \$ret ="
                            . " test_uvchr_to_utf8_flags("
                            . "$allowed_uv, $warn_flag|"
                            . "$disallow_flag)";
                    eval "$eval_text";
                    if (! ok ("$@ eq ''", "$this_name: eval succeeded"))
                    {
                        diag "\$!='$!'; eval'd=\"$eval_text\"";
                        next;
                    }
                    if ($disallowed) {
                        is($ret, undef, "$this_name: Returns undef")
                          or diag $call;
                    }
                    else {
                        is($ret, $bytes, "$this_name: Returns expected string")
                          or diag $call;
                    }
                    if (! $do_warning
                        && ($warning eq 'utf8' || $warning eq $category))
                    {
                        if (!is(scalar @warnings, 0,
                                "$this_name: No warnings generated"))
                        {
                            diag $call;
                            output_warnings(@warnings);
                        }
                    }
                    elsif (       $uvchr_warn_flag
                        && (   $warning eq 'utf8'
                            || $warning eq $category))
                    {
                        if (is(scalar @warnings, 1,
                            "$this_name: Got a single warning "))
                        {
                            like($warnings[0], $message,
                                    "$this_name: Got expected warning")
                                or diag $call;
                        }
                        else {
                            diag $call;
                            output_warnings(@warnings)
                                                if scalar @warnings;
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
