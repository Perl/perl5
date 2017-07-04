#!perl -w

# Test handling of various UTF-8 malformations

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

my @warnings;

use warnings 'utf8';
local $SIG{__WARN__} = sub { push @warnings, @_ };

my $I8c = $::I8c;

my $REPLACEMENT = 0xFFFD;

# Now test the malformations.  All these raise category utf8 warnings.
my @malformations = (
    # ($testname, $bytes, $length, $allow_flags, $expected_error_flags,
    #  $allowed_uv, $expected_len, $needed_to_discern_len, $message )

# Now considered a program bug, and asserted against
    #[ "zero length string malformation", "", 0,
    #    $::UTF8_ALLOW_EMPTY, $::UTF8_GOT_EMPTY, $REPLACEMENT, 0, 0,
    #    qr/empty string/
    #],
    [ "orphan continuation byte malformation", I8_to_native("${I8c}a"), 2,
        $::UTF8_ALLOW_CONTINUATION, $::UTF8_GOT_CONTINUATION, $REPLACEMENT,
        1, 1,
        qr/unexpected continuation byte/
    ],
    [ "premature next character malformation (immediate)",
        (isASCII) ? "\xc2\xc2\x80" : I8_to_native("\xc5\xc5\xa0"),
        3,
        $::UTF8_ALLOW_NON_CONTINUATION, $::UTF8_GOT_NON_CONTINUATION, $REPLACEMENT,
        1, 2,
        qr/unexpected non-continuation byte.*immediately after start byte/
    ],
    [ "premature next character malformation (non-immediate)",
        I8_to_native("\xef${I8c}a"), 3,
        $::UTF8_ALLOW_NON_CONTINUATION, $::UTF8_GOT_NON_CONTINUATION, $REPLACEMENT,
        2, 3,
        qr/unexpected non-continuation byte .* 2 bytes after start byte/
    ],
    [ "too short malformation", I8_to_native("\xf1${I8c}a"), 2,
        # Having the 'a' after this, but saying there are only 2 bytes also
        # tests that we pay attention to the passed in length
        $::UTF8_ALLOW_SHORT, $::UTF8_GOT_SHORT, $REPLACEMENT,
        2, 2,
        qr/2 bytes available, need 4/
    ],
    [ "overlong malformation, lowest 2-byte",
        (isASCII) ? "\xc0\x80" : I8_to_native("\xc0\xa0"),
        2,
        $::UTF8_ALLOW_LONG, $::UTF8_GOT_LONG,
        0,   # NUL
        2, 1,
        qr/overlong/
    ],
    [ "overlong malformation, highest 2-byte",
        (isASCII) ? "\xc1\xbf" : I8_to_native("\xc4\xbf"),
        2,
        $::UTF8_ALLOW_LONG, $::UTF8_GOT_LONG,
        (isASCII) ? 0x7F : utf8::unicode_to_native(0x9F),
        2, 1,
        qr/overlong/
    ],
    [ "overlong malformation, lowest 3-byte",
        (isASCII) ? "\xe0\x80\x80" : I8_to_native("\xe0\xa0\xa0"),
        3,
        $::UTF8_ALLOW_LONG, $::UTF8_GOT_LONG,
        0,   # NUL
        3, (isASCII) ? 2 : 1,
        qr/overlong/
    ],
    [ "overlong malformation, highest 3-byte",
        (isASCII) ? "\xe0\x9f\xbf" : I8_to_native("\xe0\xbf\xbf"),
        3,
        $::UTF8_ALLOW_LONG, $::UTF8_GOT_LONG,
        (isASCII) ? 0x7FF : 0x3FF,
        3, (isASCII) ? 2 : 1,
        qr/overlong/
    ],
    [ "overlong malformation, lowest 4-byte",
        (isASCII) ? "\xf0\x80\x80\x80" : I8_to_native("\xf0\xa0\xa0\xa0"),
        4,
        $::UTF8_ALLOW_LONG, $::UTF8_GOT_LONG,
        0,   # NUL
        4, 2,
        qr/overlong/
    ],
    [ "overlong malformation, highest 4-byte",
        (isASCII) ? "\xf0\x8F\xbf\xbf" : I8_to_native("\xf0\xaf\xbf\xbf"),
        4,
        $::UTF8_ALLOW_LONG, $::UTF8_GOT_LONG,
        (isASCII) ? 0xFFFF : 0x3FFF,
        4, 2,
        qr/overlong/
    ],
    [ "overlong malformation, lowest 5-byte",
        (isASCII)
         ?              "\xf8\x80\x80\x80\x80"
         : I8_to_native("\xf8\xa0\xa0\xa0\xa0"),
        5,
        $::UTF8_ALLOW_LONG, $::UTF8_GOT_LONG,
        0,   # NUL
        5, 2,
        qr/overlong/
    ],
    [ "overlong malformation, highest 5-byte",
        (isASCII)
         ?              "\xf8\x87\xbf\xbf\xbf"
         : I8_to_native("\xf8\xa7\xbf\xbf\xbf"),
        5,
        $::UTF8_ALLOW_LONG, $::UTF8_GOT_LONG,
        (isASCII) ? 0x1FFFFF : 0x3FFFF,
        5, 2,
        qr/overlong/
    ],
    [ "overlong malformation, lowest 6-byte",
        (isASCII)
         ?              "\xfc\x80\x80\x80\x80\x80"
         : I8_to_native("\xfc\xa0\xa0\xa0\xa0\xa0"),
        6,
        $::UTF8_ALLOW_LONG, $::UTF8_GOT_LONG,
        0,   # NUL
        6, 2,
        qr/overlong/
    ],
    [ "overlong malformation, highest 6-byte",
        (isASCII)
         ?              "\xfc\x83\xbf\xbf\xbf\xbf"
         : I8_to_native("\xfc\xa3\xbf\xbf\xbf\xbf"),
        6,
        $::UTF8_ALLOW_LONG, $::UTF8_GOT_LONG,
        (isASCII) ? 0x3FFFFFF : 0x3FFFFF,
        6, 2,
        qr/overlong/
    ],
    [ "overlong malformation, lowest 7-byte",
        (isASCII)
         ?              "\xfe\x80\x80\x80\x80\x80\x80"
         : I8_to_native("\xfe\xa0\xa0\xa0\xa0\xa0\xa0"),
        7,
        $::UTF8_ALLOW_LONG, $::UTF8_GOT_LONG,
        0,   # NUL
        7, 2,
        qr/overlong/
    ],
    [ "overlong malformation, highest 7-byte",
        (isASCII)
         ?              "\xfe\x81\xbf\xbf\xbf\xbf\xbf"
         : I8_to_native("\xfe\xa1\xbf\xbf\xbf\xbf\xbf"),
        7,
        $::UTF8_ALLOW_LONG, $::UTF8_GOT_LONG,
        (isASCII) ? 0x7FFFFFFF : 0x3FFFFFF,
        7, 2,
        qr/overlong/
    ],
);

if (isASCII && ! $::is64bit) {    # 32-bit ASCII platform
    no warnings 'portable';
    push @malformations,
        [ "overflow malformation",
            "\xff\x80\x80\x80\x80\x80\x81\x80\x80\x80\x80\x80\x80",
            $::max_bytes,
            $::UTF8_ALLOW_OVERFLOW, $::UTF8_GOT_OVERFLOW,
            $REPLACEMENT,
            $::max_bytes, 1,
            qr/overflows/
        ];
}
else { # 64-bit ASCII, or EBCDIC of any size.
    # On EBCDIC platforms, another overlong test is needed even on 32-bit
    # systems, whereas it doesn't happen on ASCII except on 64-bit ones.

    no warnings 'portable';
    no warnings 'overflow'; # Doesn't run on 32-bit systems, but compiles
    push @malformations,
        [ "overlong malformation, lowest max-byte",
            (isASCII)
             ?      "\xff\x80\x80\x80\x80\x80\x80\x80\x80\x80\x80\x80\x80"
             : I8_to_native(
                    "\xff\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xa0"),
            $::max_bytes,
            $::UTF8_ALLOW_LONG, $::UTF8_GOT_LONG,
            0,   # NUL
            $::max_bytes, (isASCII) ? 7 : 8,
            qr/overlong/,
        ],
        [ "overlong malformation, highest max-byte",
            (isASCII)    # 2**36-1 on ASCII; 2**30-1 on EBCDIC
             ?      "\xff\x80\x80\x80\x80\x80\x80\xbf\xbf\xbf\xbf\xbf\xbf"
             : I8_to_native(
                    "\xff\xa0\xa0\xa0\xa0\xa0\xa0\xa0\xbf\xbf\xbf\xbf\xbf\xbf"),
            $::max_bytes,
            $::UTF8_ALLOW_LONG, $::UTF8_GOT_LONG,
            (isASCII) ? 0xFFFFFFFFF : 0x3FFFFFFF,
            $::max_bytes, (isASCII) ? 7 : 8,
            qr/overlong/,
        ];
}

# For each overlong malformation in the list, we modify it, so that there are
# two tests.  The first one returns the replacement character given the input
# flags, and the second test adds a flag that causes the actual code point the
# malformation represents to be returned.
my @added_overlongs;
foreach my $test (@malformations) {
    my ($testname, $bytes, $length, $allow_flags, $expected_error_flags,
        $allowed_uv, $expected_len, $needed_to_discern_len, $message ) = @$test;
    next unless $testname =~ /overlong/;

    $test->[0] .= "; use REPLACEMENT CHAR";
    $test->[5] = $REPLACEMENT;

    push @added_overlongs,
        [ $testname . "; use actual value",
          $bytes, $length,
          $allow_flags | $::UTF8_ALLOW_LONG_AND_ITS_VALUE,
          $expected_error_flags, $allowed_uv, $expected_len,
          $needed_to_discern_len, $message
        ];
}
push @malformations, @added_overlongs;

foreach my $test (@malformations) {
    my ($testname, $bytes, $length, $allow_flags, $expected_error_flags,
        $allowed_uv, $expected_len, $needed_to_discern_len, $message ) = @$test;

    if (length($bytes) < $length) {
        fail("Internal test error: actual buffer length (" . length($bytes)
           . ") must be at least as high as how far we are allowed to read"
           . " into it ($length)");
        diag($testname);
        next;
    }

    undef @warnings;

    my $ret = test_isUTF8_CHAR($bytes, $length);
    is($ret, 0, "$testname: isUTF8_CHAR returns 0");
    is(scalar @warnings, 0, "$testname: isUTF8_CHAR() generated no warnings")
      or output_warnings(@warnings);

    undef @warnings;

    $ret = test_isUTF8_CHAR_flags($bytes, $length, 0);
    is($ret, 0, "$testname: isUTF8_CHAR_flags returns 0");
    is(scalar @warnings, 0, "$testname: isUTF8_CHAR_flags() generated no"
                          . " warnings")
      or output_warnings(@warnings);

    $ret = test_isSTRICT_UTF8_CHAR($bytes, $length);
    is($ret, 0, "$testname: isSTRICT_UTF8_CHAR returns 0");
    is(scalar @warnings, 0,
                    "$testname: isSTRICT_UTF8_CHAR() generated no warnings")
      or output_warnings(@warnings);

    $ret = test_isC9_STRICT_UTF8_CHAR($bytes, $length);
    is($ret, 0, "$testname: isC9_STRICT_UTF8_CHAR returns 0");
    is(scalar @warnings, 0,
               "$testname: isC9_STRICT_UTF8_CHAR() generated no warnings")
      or output_warnings(@warnings);

    for my $j (1 .. $length - 1) {
        my $partial = substr($bytes, 0, $j);

        undef @warnings;

        $ret = test_is_utf8_valid_partial_char_flags($bytes, $j, 0);

        my $ret_should_be = 0;
        my $comment = "";
        if ($j < $needed_to_discern_len) {
            $ret_should_be = 1;
            $comment = ", but need $needed_to_discern_len bytes to discern:";
        }

        is($ret, $ret_should_be, "$testname: is_utf8_valid_partial_char_flags("
                                . display_bytes($partial)
                                . ")$comment returns $ret_should_be");
        is(scalar @warnings, 0,
                "$testname: is_utf8_valid_partial_char_flags() generated"
              . " no warnings")
          or output_warnings(@warnings);
    }


    # Test what happens when this malformation is not allowed
    undef @warnings;
    my $ret_ref = test_utf8n_to_uvchr_error($bytes, $length, 0);
    is($ret_ref->[0], 0, "$testname: disallowed: Returns 0");
    is($ret_ref->[1], $expected_len,
       "$testname: utf8n_to_uvchr_error(), disallowed: Returns expected"
     . " length: $expected_len");
    if (is(scalar @warnings, 1,
           "$testname: disallowed: Got a single warning "))
    {
        like($warnings[0], $message,
             "$testname: disallowed: Got expected warning");
    }
    else {
        if (scalar @warnings) {
            output_warnings(@warnings);
        }
    }
    is($ret_ref->[2], $expected_error_flags,
       "$testname: utf8n_to_uvchr_error(), disallowed:"
     . " Returns expected error");

    {   # Next test when disallowed, and warnings are off.
        undef @warnings;
        no warnings 'utf8';
        my $ret_ref = test_utf8n_to_uvchr_error($bytes, $length, 0);
        is($ret_ref->[0], 0,
           "$testname: utf8n_to_uvchr_error(), disallowed: no warnings 'utf8':"
         . " Returns 0");
        is($ret_ref->[1], $expected_len,
           "$testname: utf8n_to_uvchr_error(), disallowed: no warnings 'utf8':"
         . " Returns expected length: $expected_len");
        if (!is(scalar @warnings, 0,
            "$testname: utf8n_to_uvchr_error(), disallowed: no warnings 'utf8':"
          . " no warnings generated"))
        {
            output_warnings(@warnings);
        }
        is($ret_ref->[2], $expected_error_flags,
           "$testname: utf8n_to_uvchr_error(), disallowed: Returns"
         . " expected error");
    }

    # Test with CHECK_ONLY
    undef @warnings;
    $ret_ref = test_utf8n_to_uvchr_error($bytes, $length, $::UTF8_CHECK_ONLY);
    is($ret_ref->[0], 0, "$testname: CHECK_ONLY: Returns 0");
    is($ret_ref->[1], -1, "$testname: CHECK_ONLY: returns -1 for length");
    if (! is(scalar @warnings, 0,
                               "$testname: CHECK_ONLY: no warnings generated"))
    {
        output_warnings(@warnings);
    }
    is($ret_ref->[2], $expected_error_flags,
       "$testname: utf8n_to_uvchr_error(), disallowed: Returns expected"
     . " error");

    next if $allow_flags == 0;    # Skip if can't allow this malformation

    # Test when the malformation is allowed
    undef @warnings;
    $ret_ref = test_utf8n_to_uvchr_error($bytes, $length, $allow_flags);
    is($ret_ref->[0], $allowed_uv,
       "$testname: utf8n_to_uvchr_error(), allowed: Returns expected uv: "
     . sprintf("0x%04X", $allowed_uv));
    is($ret_ref->[1], $expected_len,
       "$testname: utf8n_to_uvchr_error(), allowed: Returns expected length:"
     . " $expected_len");
    if (!is(scalar @warnings, 0,
            "$testname: utf8n_to_uvchr_error(), allowed: no warnings"
          . " generated"))
    {
        output_warnings(@warnings);
    }
    is($ret_ref->[2], $expected_error_flags,
       "$testname: utf8n_to_uvchr_error(), disallowed: Returns"
     . " expected error");
}

done_testing;
