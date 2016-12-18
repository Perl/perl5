#!perl -w

BEGIN {
    require 'loc_tools.pl';   # Contains locales_enabled() and
                              # find_utf8_ctype_locale()
}

use strict;
use Test::More;
use Config;

use XS::APItest;

my $tab = " " x 4;  # Indent subsidiary tests this much

use Unicode::UCD qw(search_invlist prop_invmap prop_invlist);
my ($charname_list, $charname_map, $format, $default) = prop_invmap("Name Alias");

sub get_charname($) {
    my $cp = shift;

    # If there is a an abbreviation for the code point name, use it
    my $name_index = search_invlist(\@{$charname_list}, $cp);
    if (defined $name_index) {
        my $synonyms = $charname_map->[$name_index];
        if (ref $synonyms) {
            my $pat = qr/: abbreviation/;
            my @abbreviations = grep { $_ =~ $pat } @$synonyms;
            if (@abbreviations) {
                return $abbreviations[0] =~ s/$pat//r;
            }
        }
    }

    # Otherwise, use the full name
    use charnames ();
    return charnames::viacode($cp) // "No name";
}

sub truth($) {  # Converts values so is() works
    return (shift) ? 1 : 0;
}

my $base_locale;
my $utf8_locale;
if(locales_enabled('LC_ALL')) {
    require POSIX;
    $base_locale = POSIX::setlocale( &POSIX::LC_ALL, "C");
    if (defined $base_locale && $base_locale eq 'C') {
        use locale; # make \w work right in non-ASCII lands

        # Some locale implementations don't have the 128-255 characters all
        # mean nothing.  Skip the locale tests in that situation
        for my $i (128 .. 255) {
            if (chr(utf8::unicode_to_native($i)) =~ /[[:print:]]/) {
                undef $base_locale;
                last;
            }
        }

        $utf8_locale = find_utf8_ctype_locale() if $base_locale;
    }
}

sub get_display_locale_or_skip($$) {

    # Helper function intimately tied to its callers.  It knows the loop
    # iterates with a locale of "", meaning don't use locale; $base_locale
    # meaning to use a non-UTF-8 locale; and $utf8_locale.
    #
    # It checks to see if the current test should be skipped or executed,
    # returning an empty list for the former, and for the latter:
    #   ( 'locale display name',
    #     bool of is this a UTF-8 locale )
    #
    # The display name is the empty string if not using locale.  Functions
    # with _LC in their name are skipped unless in locale, and functions
    # without _LC are executed only outside locale.  However, if no locales at
    # all are on the system, the _LC functions are executed outside locale.

    my ($locale, $suffix) = @_;

    # The test should be skipped if the input is for a non-existent locale
    return unless defined $locale;

    # Here the input is defined, either a locale name or "".  If the test is
    # for not using locales, we want to do the test for non-LC functions,
    # and skip it for LC ones (except if there are no locales on the system,
    # we do it for LC ones as if they weren't LC).
    if ($locale eq "") {
        return ("", 0) if $suffix !~ /LC/ || ! defined $base_locale;
        return;
    }

    # Here the input is for a real locale.  We don't test the non-LC functions
    # for locales.
    return if $suffix !~ /LC/;

    # Here is for a LC function and a real locale.  The base locale is not
    # UTF-8.
    return (" ($locale locale)", 0) if $locale eq $base_locale;

    # The only other possibility is that we have a UTF-8 locale
    return (" ($locale)", 1);
}

my %properties = (
                   # name => Lookup-property name
                   alnum => 'Word',
                   wordchar => 'Word',
                   alphanumeric => 'Alnum',
                   alpha => 'XPosixAlpha',
                   ascii => 'ASCII',
                   blank => 'Blank',
                   cntrl => 'Control',
                   digit => 'Digit',
                   graph => 'Graph',
                   idfirst => '_Perl_IDStart',
                   idcont => '_Perl_IDCont',
                   lower => 'XPosixLower',
                   print => 'Print',
                   psxspc => 'XPosixSpace',
                   punct => 'XPosixPunct',
                   quotemeta => '_Perl_Quotemeta',
                   space => 'XPerlSpace',
                   vertws => 'VertSpace',
                   upper => 'XPosixUpper',
                   xdigit => 'XDigit',
                );

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };


foreach my $name (sort keys %properties, 'octal') {
    my @invlist;
    if ($name eq 'octal') {
        # Hand-roll an inversion list with 0-7 in it and nothing else.
        push @invlist, ord "0", ord "8";
    }
    else {
        my $property = $properties{$name};
        @invlist = prop_invlist($property, '_perl_core_internal_ok');
        if (! @invlist) {

            # An empty return could mean an unknown property, or merely that
            # it is empty.  Call in scalar context to differentiate
            if (! prop_invlist($property, '_perl_core_internal_ok')) {
                fail("No inversion list found for $property");
                next;
            }
        }
    }

    # Include all the Latin1 code points, plus 0x100.
    my @code_points = (0 .. 256);

    # Then include the next few boundaries above those from this property
    my $above_latins = 0;
    foreach my $range_start (@invlist) {
        next if $range_start < 257;
        push @code_points, $range_start - 1, $range_start;
        $above_latins++;
        last if $above_latins > 5;
    }

    # This makes sure we are using the Perl definition of idfirst and idcont,
    # and not the Unicode.  There are a few differences.
    push @code_points, ord "\N{ESTIMATED SYMBOL}" if $name =~ /^id(first|cont)/;
    if ($name eq "idcont") {    # And some that are continuation but not start
        push @code_points, ord("\N{GREEK ANO TELEIA}"),
                           ord("\N{COMBINING GRAVE ACCENT}");
    }

    # And finally one non-Unicode code point.
    push @code_points, 0x110000;    # Above Unicode, no prop should match
    no warnings 'non_unicode';

    for my $j (@code_points) {
        my $i = utf8::native_to_unicode($j);
        my $function = uc($name);

        is (@warnings, 0, "Got no unexpected warnings in previous iteration")
           or diag("@warnings");
        undef @warnings;

        my $matches = search_invlist(\@invlist, $i);
        if (! defined $matches) {
            $matches = 0;
        }
        else {
            $matches = truth(! ($matches % 2));
        }

        my $ret;
        my $char_name = get_charname($j);
        my $display_name = sprintf "\\x{%02X, %s}", $i, $char_name;
        my $display_call = "is${function}( $display_name )";

        foreach my $suffix ("", "_A", "_L1", "_LC", "_uni", "_uvchr",
                            "_LC_uvchr", "_utf8", "_LC_utf8")
        {

            # Not all possible macros have been defined
            if ($name eq 'vertws') {

                # vertws is always all of Unicode
                next if $suffix !~ / ^ _ ( uni | uvchr | utf8 ) $ /x;
            }
            elsif ($name eq 'alnum') {

                # ALNUM_A, ALNUM_L1, and ALNUM_uvchr are not defined as these
                # suffixes were added later, after WORDCHAR was created to be
                # a clearer synonym for ALNUM
                next if    $suffix eq '_A'
                        || $suffix eq '_L1'
                        || $suffix eq '_uvchr';
            }
            elsif ($name eq 'octal') {
                next if $suffix ne ""  && $suffix ne '_A' && $suffix ne '_L1';
            }
            elsif ($name eq 'quotemeta') {
                # There is only one macro for this, and is defined only for
                # Latin1 range
                next if $suffix ne ""
            }

            foreach my $locale ("", $base_locale, $utf8_locale) {

                my ($display_locale, $locale_is_utf8)
                                = get_display_locale_or_skip($locale, $suffix);
                next unless defined $display_locale;

                use if $locale, "locale";
                POSIX::setlocale( &POSIX::LC_ALL, $locale) if $locale;

                if ($suffix !~ /utf8/) {    # _utf8 has to handled specially
                    my $display_call
                       = "is${function}$suffix( $display_name )$display_locale";
                    $ret = truth eval "test_is${function}$suffix($i)";
                    if (is ($@, "", "$display_call didn't give error")) {
                        my $truth = $matches;
                        if ($truth) {

                            # The single byte functions are false for
                            # above-Latin1
                            if ($i >= 256) {
                                $truth = 0
                                        if $suffix=~ / ^ ( _A | _L [1C] )? $ /x;
                            }
                            elsif (   utf8::native_to_unicode($i) >= 128
                                   && $name ne 'quotemeta')
                            {

                                # The no-suffix and _A functions are false
                                # for non-ASCII.  So are  _LC  functions on a
                                # non-UTF-8 locale
                                $truth = 0 if    $suffix eq "_A"
                                              || $suffix eq ""
                                              || (     $suffix =~ /LC/
                                                  && ! $locale_is_utf8);
                            }
                        }

                        is ($ret, $truth, "${tab}And correctly returns $truth");
                    }
                }
                else {  # _utf8 suffix
                    my $char = chr($i);
                    utf8::upgrade($char);
                    $char = quotemeta $char if $char eq '\\' || $char eq "'";
                    my $truth;
                    if (   $suffix =~ /LC/
                        && ! $locale_is_utf8
                        && $i < 256
                        && utf8::native_to_unicode($i) >= 128)
                    {   # The C-locale _LC function returns FALSE for Latin1
                        # above ASCII
                        $truth = 0;
                    }
                    else {
                        $truth = $matches;
                    }

                        my $display_call = "is${function}$suffix("
                                         . " $display_name )$display_locale";
                        $ret = truth eval "test_is${function}$suffix('$char')";
                        if (is ($@, "", "$display_call didn't give error")) {
                            is ($ret, $truth,
                                "${tab}And correctly returned $truth");
                        }
                }
            }
        }
    }
}

my %to_properties = (
                FOLD  => 'Case_Folding',
                LOWER => 'Lowercase_Mapping',
                TITLE => 'Titlecase_Mapping',
                UPPER => 'Uppercase_Mapping',
            );


foreach my $name (sort keys %to_properties) {
    my $property = $to_properties{$name};
    my ($list_ref, $map_ref, $format, $missing)
                                      = prop_invmap($property, );
    if (! $list_ref || ! $map_ref) {
        fail("No inversion map found for $property");
        next;
    }
    if ($format !~ / ^ a l? $ /x) {
        fail("Unexpected inversion map format ('$format') found for $property");
        next;
    }

    # Include all the Latin1 code points, plus 0x100.
    my @code_points = (0 .. 256);

    # Then include the next few multi-char folds above those from this
    # property, and include the next few single folds as well
    my $above_latins = 0;
    my $multi_char = 0;
    for my $i (0 .. @{$list_ref} - 1) {
        my $range_start = $list_ref->[$i];
        next if $range_start < 257;
        if (ref $map_ref->[$i] && $multi_char < 5)  {
            push @code_points, $range_start - 1
                                        if $code_points[-1] != $range_start - 1;
            push @code_points, $range_start;
            $multi_char++;
        }
        elsif ($above_latins < 5) {
            push @code_points, $range_start - 1
                                        if $code_points[-1] != $range_start - 1;
            push @code_points, $range_start;
            $above_latins++;
        }
        last if $above_latins >= 5 && $multi_char >= 5;
    }

    # And finally one non-Unicode code point.
    push @code_points, 0x110000;    # Above Unicode, no prop should match
    no warnings 'non_unicode';

    # $j is native; $i unicode.
    for my $j (@code_points) {
        my $i = utf8::native_to_unicode($j);
        my $function = $name;

        my $index = search_invlist(\@{$list_ref}, $j);

        my $ret;
        my $char_name = get_charname($j);
        my $display_name = sprintf "\\N{U+%02X, %s}", $i, $char_name;

        foreach my $suffix ("", "_L1", "_LC") {

            # This is the only macro defined for L1
            next if $suffix eq "_L1" && $function ne "LOWER";

          SKIP:
            foreach my $locale ("", $base_locale, $utf8_locale) {

                # titlecase is not defined in locales.
                next if $name eq 'TITLE' && $suffix eq "_LC";

                my ($display_locale, $locale_is_utf8)
                                = get_display_locale_or_skip($locale, $suffix);
                next unless defined $display_locale;

                skip("to${name}_LC does not work for LATIN SMALL LETTER SHARP S"
                  . "$display_locale", 1)
                            if  $i == 0xDF && $name =~ / FOLD | UPPER /x
                             && $suffix eq "_LC" && $locale_is_utf8;

                use if $locale, "locale";
                POSIX::setlocale( &POSIX::LC_ALL, $locale) if $locale;

                my $display_call = "to${function}$suffix("
                                 . " $display_name )$display_locale";
                $ret = eval "test_to${function}$suffix($j)";
                if (is ($@, "", "$display_call didn't give error")) {
                    my $should_be;
                    if ($i > 255) {
                        $should_be = $j;
                    }
                    elsif (    $i > 127
                            && (   $suffix eq ""
                                || ($suffix eq "_LC" && ! $locale_is_utf8)))
                    {
                        $should_be = $j;
                    }
                    elsif ($map_ref->[$index] != $missing) {
                        $should_be = $map_ref->[$index] + $j - $list_ref->[$index]
                    }
                    else {
                        $should_be = $j;
                    }

                    is ($ret, $should_be,
                        sprintf("${tab}And correctly returned 0x%02X",
                                                              $should_be));
                }
            }
        }

        # The _uni, uvchr, and _utf8 functions return both the ordinal of the
        # first code point of the result, and the result in utf8.  The .xs
        # tests return these in an array, in [0] and [1] respectively, with
        # [2] the length of the utf8 in bytes.
        my $utf8_should_be = "";
        my $first_ord_should_be;
        if (ref $map_ref->[$index]) {   # A multi-char result
            for my $j (0 .. @{$map_ref->[$index]} - 1) {
                $utf8_should_be .= chr $map_ref->[$index][$j];
            }

            $first_ord_should_be = $map_ref->[$index][0];
        }
        else {  # A single-char result
            $first_ord_should_be = ($map_ref->[$index] != $missing)
                                    ? $map_ref->[$index] + $j
                                                         - $list_ref->[$index]
                                    : $j;
            $utf8_should_be = chr $first_ord_should_be;
        }
        utf8::upgrade($utf8_should_be);

        # Test _uni, uvchr
        foreach my $suffix ('_uni', '_uvchr') {
            my $s;
            my $len;
            my $display_call = "to${function}$suffix( $display_name )";
            $ret = eval "test_to${function}$suffix($j)";
            if (is ($@, "", "$display_call didn't give error")) {
                is ($ret->[0], $first_ord_should_be,
                    sprintf("${tab}And correctly returned 0x%02X",
                                                    $first_ord_should_be));
                is ($ret->[1], $utf8_should_be, "${tab}Got correct utf8");
                use bytes;
                is ($ret->[2], length $utf8_should_be,
                    "${tab}Got correct number of bytes for utf8 length");
            }
        }

        # Test _utf8
        my $char = chr($j);
        utf8::upgrade($char);
        $char = quotemeta $char if $char eq '\\' || $char eq "'";
        {
            my $display_call = "to${function}_utf8($display_name )";
            $ret = eval   "test_to${function}_utf8('$char')";
            if (is ($@, "", "$display_call didn't give error")) {
                is ($ret->[0], $first_ord_should_be,
                    sprintf("${tab}And correctly returned 0x%02X",
                                                    $first_ord_should_be));
                is ($ret->[1], $utf8_should_be, "${tab}Got correct utf8");
                use bytes;
                is ($ret->[2], length $utf8_should_be,
                    "${tab}Got correct number of bytes for utf8 length");
            }
        }
    }
}

# This is primarily to make sure that no non-Unicode warnings get generated
is(scalar @warnings, 0, "No unexpected warnings were generated in the tests")
  or diag @warnings;

done_testing;
