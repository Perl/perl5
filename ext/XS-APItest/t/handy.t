#!perl -w

use strict;
use Test::More;

use XS::APItest;

use Unicode::UCD qw(prop_invlist);

sub truth($) {  # Converts values so is() works
    return (shift) ? 1 : 0;
}

my %properties = (
                   # name => Lookup-property name
                   alnum => 'Word',
                   alnumc => 'Alnum',
                   alpha => 'Alpha',
                   ascii => 'ASCII',
                   blank => 'Blank',
                   cntrl => 'Control',
                   digit => 'Digit',
                   graph => 'Graph',
                   idfirst => '_Perl_IDStart',
                   lower => 'Lower',
                   print => 'Print',
                   psxspc => 'XPosixSpace',
                   punct => 'XPosixPunct',
                   quotemeta => '_Perl_Quotemeta',
                   space => 'XPerlSpace',
                   vertws => 'VertSpace',
                   upper => 'Upper',
                   xdigit => 'XDigit',
                );

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

use charnames ();
foreach my $name (sort keys %properties) {
    my $property = $properties{$name};
    my @invlist = prop_invlist($property, '_perl_core_internal_ok');
    if (! @invlist) {
        fail("No inversion list found for $property");
        next;
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

    # And finally one non-Unicode code point.
    push @code_points, 0x110000;    # Above Unicode, no prop should match

    for my $i (@code_points) {
        my $function = uc($name);

        my $matches = Unicode::UCD::_search_invlist(\@invlist, $i);
        if (! defined $matches) {
            $matches = 0;
        }
        else {
            $matches = truth(! ($matches % 2));
        }

        my $ret;
        my $char_name = charnames::viacode($i) // "No name";
        my $display_name = sprintf "\\N{U+%02X, %s}", $i, $char_name;

        if ($name eq 'quotemeta') { # There is only one macro for this, and is
                                    # defined only for Latin1 range
            $ret = truth eval "test_is${function}($i)";
            if ($@) {
                fail $@;
            }
            else {
                my $truth = truth($matches && $i < 256);
                is ($ret, $truth, "is${function}( $display_name ) == $truth");
            }
            next;
        }
        if ($name ne 'vertws') {
            $ret = truth eval "test_is${function}_A($i)";
            if ($@) {
                fail($@);
            }
            else {
                my $truth = truth($matches && $i < 128);
                is ($ret, $truth, "is${function}_A( $display_name ) == $truth");
            }
            $ret = truth eval "test_is${function}_L1($i)";
            if ($@) {
                fail($@);
            }
            else {
                my $truth = truth($matches && $i < 256);
                is ($ret, $truth, "is${function}_L1( $display_name ) == $truth");
            }
        }
        next if $name eq 'alnumc';

        $ret = truth eval "test_is${function}_uni($i)";
        if ($@) {
            fail($@);
        }
        else {
            is ($ret, $matches, "is${function}_uni( $display_name ) == $matches");
        }

        my $char = chr($i);
        utf8::upgrade($char);
        $char = quotemeta $char if $char eq '\\' || $char eq "'";
        $ret = truth eval "test_is${function}_utf8('$char')";
        if ($@) {
            fail($@);
        }
        else {
            is ($ret, $matches, "is${function}_utf8( $display_name ) == $matches");
        }
    }
}

# This is primarily to make sure that no non-Unicode warnings get generated
is(scalar @warnings, 0, "No warnings were generated " . join ", ", @warnings);

done_testing;
