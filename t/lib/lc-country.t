#!./perl
#
# country.t - tests for Locale::Country
#

BEGIN {
        chdir 't' if -d 't';
        @INC = '../lib';
}

use Locale::Country;

#-----------------------------------------------------------------------
# This is an array of tests specs. Each spec is [TEST, OK_TO_DIE]
# Each TEST is eval'd as an expression.
# If it evaluates to FALSE, then "not ok N" is printed for the test,
# otherwise "ok N". If the eval dies, then the OK_TO_DIE flag is checked.
# If it is true (1), the test is treated as passing, otherwise it failed.
#-----------------------------------------------------------------------
@TESTS =
(
	#================================================
	# TESTS FOR code2country
	#================================================

 #---- selection of examples which should all result in undef -----------
 ['!defined code2country()', 0],                  # no argument
 ['!defined code2country(undef)', 0],             # undef argument
 ['!defined code2country("zz")', 0],              # illegal code
 ['!defined code2country("zz", LOCALE_CODE_ALPHA_2)', 0],        # illegal code
 ['!defined code2country("zz", LOCALE_CODE_ALPHA_3)', 0],        # illegal code
 ['!defined code2country("zz", LOCALE_CODE_NUMERIC)', 0],        # illegal code
 ['!defined code2country("ja")', 0],              # should be jp for country
 ['!defined code2country("uk")', 0],              # should be jp for country

 #---- some successful examples -----------------------------------------
 ['code2country("BO") eq "Bolivia"', 0],
 ['code2country("BO", LOCALE_CODE_ALPHA_2) eq "Bolivia"', 0],
 ['code2country("bol", LOCALE_CODE_ALPHA_3) eq "Bolivia"', 0],
 ['code2country("pk") eq "Pakistan"', 0],
 ['code2country("sn") eq "Senegal"', 0],
 ['code2country("us") eq "United States"', 0],
 ['code2country("ad") eq "Andorra"', 0],          # first in DATA segment
 ['code2country("ad", LOCALE_CODE_ALPHA_2) eq "Andorra"', 0],
 ['code2country("and", LOCALE_CODE_ALPHA_3) eq "Andorra"', 0],
 ['code2country("020", LOCALE_CODE_NUMERIC) eq "Andorra"', 0],
 ['code2country(48, LOCALE_CODE_NUMERIC) eq "Bahrain"', 0],
 ['code2country("zw") eq "Zimbabwe"', 0],         # last in DATA segment
 ['code2country("gb") eq "United Kingdom"', 0],   # United Kingdom is "gb", not "uk"

	#================================================
	# TESTS FOR country2code
	#================================================

 #---- selection of examples which should all result in undef -----------
 ['!defined code2country("BO", LOCALE_CODE_ALPHA_3)', 0],
 ['!defined code2country("BO", LOCALE_CODE_NUMERIC)', 0],
 ['!defined country2code()', 0],                  # no argument
 ['!defined country2code(undef)', 0],             # undef argument
 ['!defined country2code("Banana")', 0],          # illegal country name

 #---- some successful examples -----------------------------------------
 ['country2code("japan")          eq "jp"', 0],
 ['country2code("japan")          ne "ja"', 0],
 ['country2code("Japan")          eq "jp"', 0],
 ['country2code("United States")  eq "us"', 0],
 ['country2code("United Kingdom") eq "gb"', 0],
 ['country2code("Andorra")        eq "ad"', 0],    # first in DATA segment
 ['country2code("Zimbabwe")       eq "zw"', 0],    # last in DATA segment

	#================================================
	# TESTS FOR country_code2code
	#================================================

 #---- selection of examples which should all result in undef -----------
 ['!defined country_code2code("bo", LOCALE_CODE_ALPHA_3, LOCALE_CODE_ALPHA_3)', 0],
 ['!defined country_code2code("zz", LOCALE_CODE_ALPHA_2, LOCALE_CODE_ALPHA_3)', 0],
 ['!defined country_code2code("zz", LOCALE_CODE_ALPHA_3, LOCALE_CODE_ALPHA_3)', 0],
 ['!defined country_code2code("zz", LOCALE_CODE_ALPHA_2)', 1],
 ['!defined country_code2code("bo", LOCALE_CODE_ALPHA_2)', 1],
 ['!defined country_code2code()', 1],                  # no argument
 ['!defined country_code2code(undef)', 1],             # undef argument

 #---- some successful examples -----------------------------------------
 ['country_code2code("BO", LOCALE_CODE_ALPHA_2, LOCALE_CODE_ALPHA_3) eq "bol"', 0],
 ['country_code2code("bol", LOCALE_CODE_ALPHA_3, LOCALE_CODE_ALPHA_2) eq "bo"', 0],
 ['country_code2code("zwe", LOCALE_CODE_ALPHA_3, LOCALE_CODE_ALPHA_2) eq "zw"', 0],
 ['country_code2code("858", LOCALE_CODE_NUMERIC, LOCALE_CODE_ALPHA_3) eq "ury"', 0],
 ['country_code2code(858, LOCALE_CODE_NUMERIC, LOCALE_CODE_ALPHA_3) eq "ury"', 0],
 ['country_code2code("tr", LOCALE_CODE_ALPHA_2, LOCALE_CODE_NUMERIC) eq "792"', 0],

);

print "1..", int(@TESTS), "\n";

$testid = 1;
foreach $test (@TESTS)
{
    eval "print (($test->[0]) ? \"ok $testid\\n\" : \"not ok $testid\\n\" )";
    if ($@)
    {
	if (!$test->[1])
	{
	    print "not ok $testid\n";
	}
	else
	{
	    print "ok $testid\n";
	}
    }
    ++$testid;
}

exit 0;
