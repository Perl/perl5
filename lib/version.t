#! /usr/local/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test::More tests => 170;

diag "Tests with base class" unless $ENV{PERL_CORE};

use_ok("version"); # If we made it this far, we are ok.
BaseTests("version");

diag "Tests with empty derived class" unless $ENV{PERL_CORE};

package version::Empty;
use vars qw($VERSION @ISA);
use Exporter;
use version 0.30;
@ISA = qw(Exporter version);
$VERSION = 0.01;

package main;
my $testobj = new version::Empty 1.002_003;
isa_ok( $testobj, "version::Empty" );
ok( $testobj->numify == 1.002003, "Numified correctly" );
ok( $testobj->stringify eq "1.2.3", "Stringified correctly" );

my $verobj = new version "1.2.4";
ok( $verobj > $testobj, "Comparison vs parent class" );
ok( $verobj gt $testobj, "Comparison vs parent class" );
BaseTests("version::Empty");

sub BaseTests {

	my $CLASS = shift;
	
	# Insert your test code below, the Test module is use()ed here so read
	# its man page ( perldoc Test ) for help writing this test script.
	
	# Test bare number processing
	diag "tests with bare numbers" unless $ENV{PERL_CORE};
	$version = $CLASS->new(5.005_03);
	is ( "$version" , "5.5.30" , '5.005_03 eq 5.5.30' );
	$version = $CLASS->new(1.23);
	is ( "$version" , "1.230" , '1.23 eq "1.230"' );
	
	# Test quoted number processing
	diag "tests with quoted numbers" unless $ENV{PERL_CORE};
	$version = $CLASS->new("5.005_03");
	is ( "$version" , "5.5_30" , '"5.005_03" eq "5.5_30"' );
	$version = $CLASS->new("v1.23");
	is ( "$version" , "1.23.0" , '"v1.23" eq "1.23.0"' );
	
	# Test stringify operator
	diag "tests with stringify" unless $ENV{PERL_CORE};
	$version = $CLASS->new("5.005");
	is ( "$version" , "5.005" , '5.005 eq "5.005"' );
	$version = $CLASS->new("5.006.001");
	is ( "$version" , "5.6.1" , '5.006.001 eq 5.6.1' );
	$version = $CLASS->new("1.2.3_4");
	is ( "$version" , "1.2.3_4" , 'alpha version 1.2.3_4 eq 1.2.3_4' );
	
	# test illegal formats
	diag "test illegal formats" unless $ENV{PERL_CORE};
	eval {my $version = $CLASS->new("1.2_3_4")};
	like($@, qr/multiple underscores/,
	    "Invalid version format (multiple underscores)");
	
	eval {my $version = $CLASS->new("1.2_3.4")};
	like($@, qr/underscores before decimal/,
	    "Invalid version format (underscores before decimal)");
	
	$version = $CLASS->new("99 and 44/100 pure");
	ok ("$version" eq "99.000", '$version eq "99.000"');
	ok ($version->numify == 99.0, '$version->numify == 99.0');
	
	$version = $CLASS->new("something");
	ok (defined $version, 'defined $version');
	
	# reset the test object to something reasonable
	$version = $CLASS->new("1.2.3");
	
	# Test boolean operator
	ok ($version, 'boolean');
	
	# Test class membership
	isa_ok ( $version, "version" );
	
	# Test comparison operators with self
	diag "tests with self" unless $ENV{PERL_CORE};
	ok ( $version eq $version, '$version eq $version' );
	is ( $version cmp $version, 0, '$version cmp $version == 0' );
	ok ( $version == $version, '$version == $version' );
	
	# test first with non-object
	$version = $CLASS->new("5.006.001");
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
	$new_version = $CLASS->new("5.8.0");
	diag "tests with objects" unless $ENV{PERL_CORE};
	ok ( $version ne $new_version, '$version ne $new_version' );
	ok ( $version lt $new_version, '$version lt $new_version' );
	ok ( $new_version gt $version, '$new_version gt $version' );
	$new_version = $CLASS->new("$version");
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
	$new_version = $CLASS->new($new_version);
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
	$version = $CLASS->new(1.002003);
	ok ( $version eq "1.2.3", '$version eq "1.2.3"');
	ok ( $version->numify == 1.002003, '$version->numify == 1.002003');
	$version = $CLASS->new("2002.09.30.1");
	ok ( $version eq "2002.9.30.1",'$version eq 2002.9.30.1');
	ok ( $version->numify == 2002.009030001,
	    '$version->numify == 2002.009030001');
	
	# now test with alpha version form with string
	$version = $CLASS->new("1.2.3");
	$new_version = "1.2.3_4";
	diag "tests with alpha-style non-objects" unless $ENV{PERL_CORE};
	ok ( $version lt $new_version, '$version lt $new_version' );
	ok ( $new_version gt $version, '$new_version gt $version' );
	ok ( $version ne $new_version, '$version ne $new_version' );
	
	$version = $CLASS->new("1.2.4");
	diag "numeric tests with alpha-style non-objects" unless $ENV{PERL_CORE};
	ok ( $version > $new_version, '$version > $new_version' );
	ok ( $new_version < $version, '$new_version < $version' );
	ok ( $version != $new_version, '$version != $new_version' );
	
	# now test with alpha version form with object
	$version = $CLASS->new("1.2.3");
	$new_version = $CLASS->new("1.2.3_4");
	diag "tests with alpha-style objects" unless $ENV{PERL_CORE};
	ok ( $version < $new_version, '$version < $new_version' );
	ok ( $new_version > $version, '$new_version > $version' );
	ok ( $version != $new_version, '$version != $new_version' );
	ok ( !$version->is_alpha, '!$version->is_alpha');
	ok ( $new_version->is_alpha, '$new_version->is_alpha');
	
	$version = $CLASS->new("1.2.4");
	diag "tests with alpha-style objects" unless $ENV{PERL_CORE};
	ok ( $version > $new_version, '$version > $new_version' );
	ok ( $new_version < $version, '$new_version < $version' );
	ok ( $version != $new_version, '$version != $new_version' );
	
	$version = $CLASS->new("1.2.3.4");
	$new_version = $CLASS->new("1.2.3_4");
	diag "tests with alpha-style objects with same subversion" unless $ENV{PERL_CORE};
	ok ( $version > $new_version, '$version > $new_version' );
	ok ( $new_version < $version, '$new_version < $version' );
	ok ( $version != $new_version, '$version != $new_version' );
	
	diag "test implicit [in]equality" unless $ENV{PERL_CORE};
	$version = $CLASS->new("v1.2.3");
	$new_version = $CLASS->new("1.2.3.0");
	ok ( $version == $new_version, '$version == $new_version' );
	$new_version = $CLASS->new("1.2.3_0");
	ok ( $version == $new_version, '$version == $new_version' );
	$new_version = $CLASS->new("1.2.3.1");
	ok ( $version < $new_version, '$version < $new_version' );
	$new_version = $CLASS->new("1.2.3_1");
	ok ( $version < $new_version, '$version < $new_version' );
	$new_version = $CLASS->new("1.1.999");
	ok ( $version > $new_version, '$version > $new_version' );
	
	# that which is not expressly permitted is forbidden
	diag "forbidden operations" unless $ENV{PERL_CORE};
	ok ( !eval { ++$version }, "noop ++" );
	ok ( !eval { --$version }, "noop --" );
	ok ( !eval { $version/1 }, "noop /" );
	ok ( !eval { $version*3 }, "noop *" );
	ok ( !eval { abs($version) }, "noop abs" );

	# test the qv() sub
	diag "testing qv" unless $ENV{PERL_CORE};
	$version = qv("1.2");
	ok ( $version eq "1.2.0", 'qv("1.2") eq "1.2.0"' );
	$version = qv(1.2);
	ok ( $version eq "1.2.0", 'qv(1.2) eq "1.2.0"' );

	# test creation from existing version object
	diag "create new from existing version" unless $ENV{PERL_CORE};
	ok (eval {$new_version = version->new($version)},
		"new from existing object");
	ok ($new_version == $version, "duped object identical");

	# test the CVS revision mode
	diag "testing CVS Revision" unless $ENV{PERL_CORE};
	$version = new version qw$Revision: 1.2$;
	ok ( $version eq "1.2.0", 'qw$Revision: 1.2$ eq 1.2.0' );
	$version = new version qw$Revision: 1.2.3.4$;
	ok ( $version eq "1.2.3.4", 'qw$Revision: 1.2.3.4$ eq 1.2.3.4' );
	
	# test reformed UNIVERSAL::VERSION
	diag "Replacement UNIVERSAL::VERSION tests" unless $ENV{PERL_CORE};
	
	# we know this file is here since we require it ourselves
	$version = $Test::More::VERSION;
	eval "use Test::More $version";
	unlike($@, qr/Test::More version $version/,
		'Replacement eval works with exact version');
	
	$version = $Test::More::VERSION+0.01; # this should fail even with old UNIVERSAL::VERSION
	eval "use Test::More $version";
	like($@, qr/Test::More version $version/,
		'Replacement eval works with incremented version');
	
	$version =~ s/\.0$//; #convert to string and remove trailing '.0'
	chop($version);	# shorten by 1 digit, should still succeed
	eval "use Test::More $version";
	unlike($@, qr/Test::More version $version/,
		'Replacement eval works with single digit');
	
	$version += 0.1; # this would fail with old UNIVERSAL::VERSION
	eval "use Test::More $version";
	like($@, qr/Test::More version $version/,
		'Replacement eval works with incremented digit');
	
SKIP: 	{
	    skip 'Cannot test v-strings with Perl < 5.8.1', 4
		    if $] < 5.008_001; 
	    diag "Tests with v-strings" unless $ENV{PERL_CORE};
	    $version = $CLASS->new(1.2.3);
	    ok("$version" eq "1.2.3", '"$version" eq 1.2.3');
	    $version = $CLASS->new(1.0.0);
	    $new_version = $CLASS->new(1);
	    ok($version == $new_version, '$version == $new_version');
	    ok($version eq $new_version, '$version eq $new_version');
	    $version = qv(1.2.3);
	    ok("$version" eq "1.2.3", 'v-string initialized qv()');
	}
}
