# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
# $Revision: 2.0 $

#########################

use Test::More tests => 60;
use_ok(version); # If we made it this far, we are ok.

my ($version, $new_version);
#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

# Test stringify operator
diag "tests with stringify" unless $ENV{PERL_CORE};
$version = new version "5.005";
is ( "$version" , "5.5" , '5.005 eq 5.5' );
$version = new version "5.005_03";
is ( "$version" , "5.5.30" , 'perl version 5.005_03 eq 5.5.30' );
$version = new version "5.006.001";
is ( "$version" , "5.6.1" , '5.006.001 eq 5.6.1' );
$version = new version "1.2.3_4";
is ( "$version" , "1.2.3_4" , 'beta version 1.2.3_4 eq 1.2.3_4' );

# test illegal formats
diag "test illegal formats" unless $ENV{PERL_CORE};
eval {my $version = new version "1.2_3_4";};
like($@, qr/multiple underscores/,
    "Invalid version format (multiple underscores)");

eval {my $version = new version "1.2_3.4";};
like($@, qr/underscores before decimal/,
    "Invalid version format (underscores before decimal)");

# Test boolean operator
ok ($version, 'boolean');

# Test ref operator
ok (ref($version) eq 'version','ref operator');

# Test comparison operators with self
diag "tests with self" unless $ENV{PERL_CORE};
ok ( $version eq $version, '$version eq $version' );
is ( $version cmp $version, 0, '$version cmp $version == 0' );
ok ( $version == $version, '$version == $version' );

# test first with non-object
$version = new version "5.006.001";
$new_version = "5.8.0";
diag "tests with non-objects" unless $ENV{PERL_CORE};
ok ( $version ne $new_version, '$version ne $new_version' );
ok ( $version lt $new_version, '$version lt $new_version' );
ok ( $new_version gt $version, '$new_version gt $version' );
ok ( ref(\$new_version) eq 'SCALAR', 'no auto-upgrade');
$new_version = "$version";
ok ( $version eq $new_version, '$version eq $new_version' );
ok ( $new_version eq $version, '$new_version eq $version' );

# now test with existing object
$new_version = new version "5.8.0";
diag "tests with objects" unless $ENV{PERL_CORE};
ok ( $version ne $new_version, '$version ne $new_version' );
ok ( $version lt $new_version, '$version lt $new_version' );
ok ( $new_version gt $version, '$new_version gt $version' );
$new_version = new version "$version";
ok ( $version eq $new_version, '$version eq $new_version' );

# Test Numeric Comparison operators
# test first with non-object
$new_version = "5.8.0";
diag "numeric tests with non-objects" unless $ENV{PERL_CORE};
ok ( $version == $version, '$version == $version' );
ok ( $version < $new_version, '$version < $new_version' );
ok ( $new_version > $version, '$new_version > $version' );
ok ( $version != $new_version, '$version != $new_version' );

# now test with existing object
$new_version = new version $new_version;
diag "numeric tests with objects" unless $ENV{PERL_CORE};
ok ( $version < $new_version, '$version < $new_version' );
ok ( $new_version > $version, '$new_version > $version' );
ok ( $version != $new_version, '$version != $new_version' );

# now test with actual numbers
diag "numeric tests with numbers" unless $ENV{PERL_CORE};
ok ( $version->numify() == 5.006001, '$version->numify() == 5.006001' );
ok ( $version->numify() <= 5.006001, '$version->numify() <= 5.006001' );
ok ( $version->numify() < 5.008, '$version->numify() < 5.008' );
#ok ( $version->numify() > v5.005_02, '$version->numify() > 5.005_02' );

# test with long decimals
diag "Tests with extended decimal versions" unless $ENV{PERL_CORE};
$version = new version 1.002003;
ok ( $version eq "1.2.3", '$version eq "1.2.3"');
ok ( $version->numify == 1.002003, '$version->numify == 1.002003');
$version = new version "2002.09.30.1";
ok ( $version eq "2002.9.30.1",'$version eq 2002.9.30.1');
ok ( $version->numify == 2002.009030001,
    '$version->numify == 2002.009030001');

# now test with Beta version form with string
$version = new version "1.2.3";
$new_version = "1.2.3_4";
diag "tests with beta-style non-objects" unless $ENV{PERL_CORE};
ok ( $version lt $new_version, '$version lt $new_version' );
ok ( $new_version gt $version, '$new_version gt $version' );
ok ( $version ne $new_version, '$version ne $new_version' );

$version = new version "1.2.4";
diag "numeric tests with beta-style non-objects" unless $ENV{PERL_CORE};
ok ( $version > $new_version, '$version > $new_version' );
ok ( $new_version < $version, '$new_version < $version' );
ok ( $version != $new_version, '$version != $new_version' );

# now test with Beta version form with object
$version = new version "1.2.3";
$new_version = new version "1.2.3_4";
diag "tests with beta-style objects" unless $ENV{PERL_CORE};
ok ( $version < $new_version, '$version < $new_version' );
ok ( $new_version > $version, '$new_version > $version' );
ok ( $version != $new_version, '$version != $new_version' );

$version = new version "1.2.4";
diag "tests with beta-style objects" unless $ENV{PERL_CORE};
ok ( $version > $new_version, '$version > $new_version' );
ok ( $new_version < $version, '$new_version < $version' );
ok ( $version != $new_version, '$version != $new_version' );

$version = new version "1.2.4";
$new_version = new version "1.2_4";
diag "tests with beta-style objects with same subversion" unless $ENV{PERL_CORE};
ok ( $version > $new_version, '$version > $new_version' );
ok ( $new_version < $version, '$new_version < $version' );
ok ( $version != $new_version, '$version != $new_version' );

# that which is not expressly permitted is forbidden
diag "forbidden operations" unless $ENV{PERL_CORE};
ok ( !eval { $version++ }, "noop ++" );
ok ( !eval { $version-- }, "noop --" );
ok ( !eval { $version/1 }, "noop /" );
ok ( !eval { $version*3 }, "noop *" );
ok ( !eval { abs($version) }, "noop abs" );

# test reformed UNIVERSAL::VERSION
diag "Replacement UNIVERSAL::VERSION tests" unless $ENV{PERL_CORE};

# we know this file is here since we require it ourselves
$version = $Test::More::VERSION;
eval "use Test::More $version";
unlike($@, qr/Test::More version $version required/,
	'Replacement eval works with exact version');

$version += 0.01; # this should fail even with old UNIVERSAL::VERSION
eval "use Test::More $version";
like($@, qr/Test::More version $version required/,
	'Replacement eval works with incremented version');

chop($version); # shorten by 1 digit, should still succeed
eval "use Test::More $version";
unlike($@, qr/Test::More version $version required/,
	'Replacement eval works with single digit');

$version += 0.1; # this would fail with old UNIVERSAL::VERSION
eval "use Test::More $version";
unlike($@, qr/Test::More version $version required/,
	'Replacement eval works with incremented digit');

