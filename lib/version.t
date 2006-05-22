#! /usr/local/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test::More qw(no_plan);
require Test::Harness;
no warnings 'once';
*Verbose = \$Test::Harness::Verbose;

diag "Tests with base class" unless $ENV{PERL_CORE};

BEGIN {
    use_ok("version", 0.50); # If we made it this far, we are ok.
}

BaseTests("version");

diag "Tests with empty derived class" unless $ENV{PERL_CORE};

package version::Empty;
use base version;
$VERSION = 0.01;
no warnings 'redefine';
*::qv = sub { return bless version::qv(shift), __PACKAGE__; };

package version::Bad;
use base version;
sub new { my($self,$n)=@_;  bless \$n, $self }

package main;
my $testobj = version::Empty->new(1.002_003);
isa_ok( $testobj, "version::Empty" );
ok( $testobj->numify == 1.002003, "Numified correctly" );
ok( $testobj->stringify eq "1.002003", "Stringified correctly" );
ok( $testobj->normal eq "v1.2.3", "Normalified correctly" );

my $verobj = version->new("1.2.4");
ok( $verobj > $testobj, "Comparison vs parent class" );
ok( $verobj gt $testobj, "Comparison vs parent class" );
BaseTests("version::Empty");

diag "tests with bad subclass" unless $ENV{PERL_CORE};
$testobj = version::Bad->new(1.002_003);
isa_ok( $testobj, "version::Bad" );
eval { my $string = $testobj->numify };
like($@, qr/Invalid version object/,
    "Bad subclass numify");
eval { my $string = $testobj->normal };
like($@, qr/Invalid version object/,
    "Bad subclass normal");
eval { my $string = $testobj->stringify };
like($@, qr/Invalid version object/,
    "Bad subclass stringify");
eval { my $test = $testobj > 1.0 };
like($@, qr/Invalid version object/,
    "Bad subclass vcmp");

# dummy up a redundant call to satify David Wheeler
local $SIG{__WARN__} = sub { die $_[0] };
eval 'use version;';
unlike ($@, qr/^Subroutine main::qv redefined/,
    "Only export qv once per package (to prevent redefined warnings)."); 

sub BaseTests {

	my ($CLASS, $no_qv) = @_;
	
	# Insert your test code below, the Test module is use()ed here so read
	# its man page ( perldoc Test ) for help writing this test script.
	
	# Test bare number processing
	diag "tests with bare numbers" if $Verbose;
	$version = $CLASS->new(5.005_03);
	is ( "$version" , "5.005030" , '5.005_03 eq 5.5.30' );
	$version = $CLASS->new(1.23);
	is ( "$version" , "1.230" , '1.23 eq "1.230"' );
	
	# Test quoted number processing
	diag "tests with quoted numbers" if $Verbose;
	$version = $CLASS->new("5.005_03");
	is ( "$version" , "5.005_030" , '"5.005_03" eq "5.005_030"' );
	$version = $CLASS->new("v1.23");
	is ( "$version" , "v1.23.0" , '"v1.23" eq "v1.23.0"' );
	
	# Test stringify operator
	diag "tests with stringify" if $Verbose;
	$version = $CLASS->new("5.005");
	is ( "$version" , "5.005" , '5.005 eq "5.005"' );
	$version = $CLASS->new("5.006.001");
	is ( "$version" , "v5.6.1" , '5.006.001 eq v5.6.1' );
	$version = $CLASS->new("1.2.3_4");
	is ( "$version" , "v1.2.3_4" , 'alpha version 1.2.3_4 eq v1.2.3_4' );
	
	# test illegal formats
	diag "test illegal formats" if $Verbose;
	eval {my $version = $CLASS->new("1.2_3_4")};
	like($@, qr/multiple underscores/,
	    "Invalid version format (multiple underscores)");
	
	eval {my $version = $CLASS->new("1.2_3.4")};
	like($@, qr/underscores before decimal/,
	    "Invalid version format (underscores before decimal)");
	
	eval {my $version = $CLASS->new("1_2")};
	like($@, qr/alpha without decimal/,
	    "Invalid version format (alpha without decimal)");

	# for this first test, just upgrade the warn() to die()
	eval {
	    local $SIG{__WARN__} = sub { die $_[0] };
	    $version = $CLASS->new("1.2b3");
	};
	my $warnregex = "Version string '.+' contains invalid data; ".
		"ignoring: '.+'";

	like($@, qr/$warnregex/,
	    "Version string contains invalid data; ignoring");

	# from here on out capture the warning and test independently
	my $warning;
	local $SIG{__WARN__} = sub { $warning = $_[0] };
 	$version = $CLASS->new("99 and 44/100 pure");

	like($warning, qr/$warnregex/,
	    "Version string contains invalid data; ignoring");
	ok ("$version" eq "99.000", '$version eq "99.000"');
	ok ($version->numify == 99.0, '$version->numify == 99.0');
	ok ($version->normal eq "v99.0.0", '$version->normal eq v99.0.0');
	
	$version = $CLASS->new("something");
	like($warning, qr/$warnregex/,
	    "Version string contains invalid data; ignoring");
	ok (defined $version, 'defined $version');
	
	# reset the test object to something reasonable
	$version = $CLASS->new("1.2.3");
	
	# Test boolean operator
	ok ($version, 'boolean');
	
	# Test class membership
	isa_ok ( $version, $CLASS );
	
	# Test comparison operators with self
	diag "tests with self" if $Verbose;
	ok ( $version eq $version, '$version eq $version' );
	is ( $version cmp $version, 0, '$version cmp $version == 0' );
	ok ( $version == $version, '$version == $version' );
	
	# test first with non-object
	$version = $CLASS->new("5.006.001");
	$new_version = "5.8.0";
	diag "tests with non-objects" if $Verbose;
	ok ( $version ne $new_version, '$version ne $new_version' );
	ok ( $version lt $new_version, '$version lt $new_version' );
	ok ( $new_version gt $version, '$new_version gt $version' );
	ok ( ref(\$new_version) eq 'SCALAR', 'no auto-upgrade');
	$new_version = "$version";
	ok ( $version eq $new_version, '$version eq $new_version' );
	ok ( $new_version eq $version, '$new_version eq $version' );
	
	# now test with existing object
	$new_version = $CLASS->new("5.8.0");
	diag "tests with objects" if $Verbose;
	ok ( $version ne $new_version, '$version ne $new_version' );
	ok ( $version lt $new_version, '$version lt $new_version' );
	ok ( $new_version gt $version, '$new_version gt $version' );
	$new_version = $CLASS->new("$version");
	ok ( $version eq $new_version, '$version eq $new_version' );
	
	# Test Numeric Comparison operators
	# test first with non-object
	$new_version = "5.8.0";
	diag "numeric tests with non-objects" if $Verbose;
	ok ( $version == $version, '$version == $version' );
	ok ( $version < $new_version, '$version < $new_version' );
	ok ( $new_version > $version, '$new_version > $version' );
	ok ( $version != $new_version, '$version != $new_version' );
	
	# now test with existing object
	$new_version = $CLASS->new($new_version);
	diag "numeric tests with objects" if $Verbose;
	ok ( $version < $new_version, '$version < $new_version' );
	ok ( $new_version > $version, '$new_version > $version' );
	ok ( $version != $new_version, '$version != $new_version' );
	
	# now test with actual numbers
	diag "numeric tests with numbers" if $Verbose;
	ok ( $version->numify() == 5.006001, '$version->numify() == 5.006001' );
	ok ( $version->numify() <= 5.006001, '$version->numify() <= 5.006001' );
	ok ( $version->numify() < 5.008, '$version->numify() < 5.008' );
	#ok ( $version->numify() > v5.005_02, '$version->numify() > 5.005_02' );
	
	# test with long decimals
	diag "Tests with extended decimal versions" if $Verbose;
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
	diag "tests with alpha-style non-objects" if $Verbose;
	ok ( $version lt $new_version, '$version lt $new_version' );
	ok ( $new_version gt $version, '$new_version gt $version' );
	ok ( $version ne $new_version, '$version ne $new_version' );
	
	$version = $CLASS->new("1.2.4");
	diag "numeric tests with alpha-style non-objects"
	    if $Verbose;
	ok ( $version > $new_version, '$version > $new_version' );
	ok ( $new_version < $version, '$new_version < $version' );
	ok ( $version != $new_version, '$version != $new_version' );
	
	# now test with alpha version form with object
	$version = $CLASS->new("1.2.3");
	$new_version = $CLASS->new("1.2.3_4");
	diag "tests with alpha-style objects" if $Verbose;
	ok ( $version < $new_version, '$version < $new_version' );
	ok ( $new_version > $version, '$new_version > $version' );
	ok ( $version != $new_version, '$version != $new_version' );
	ok ( !$version->is_alpha, '!$version->is_alpha');
	ok ( $new_version->is_alpha, '$new_version->is_alpha');
	
	$version = $CLASS->new("1.2.4");
	diag "tests with alpha-style objects" if $Verbose;
	ok ( $version > $new_version, '$version > $new_version' );
	ok ( $new_version < $version, '$new_version < $version' );
	ok ( $version != $new_version, '$version != $new_version' );
	
	$version = $CLASS->new("1.2.3.4");
	$new_version = $CLASS->new("1.2.3_4");
	diag "tests with alpha-style objects with same subversion"
	    if $Verbose;
	ok ( $version > $new_version, '$version > $new_version' );
	ok ( $new_version < $version, '$new_version < $version' );
	ok ( $version != $new_version, '$version != $new_version' );
	
	diag "test implicit [in]equality" if $Verbose;
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
	diag "forbidden operations" if $Verbose;
	ok ( !eval { ++$version }, "noop ++" );
	ok ( !eval { --$version }, "noop --" );
	ok ( !eval { $version/1 }, "noop /" );
	ok ( !eval { $version*3 }, "noop *" );
	ok ( !eval { abs($version) }, "noop abs" );

SKIP: {
	skip "version require'd instead of use'd, cannot test qv", 3
	    if defined $no_qv;
	# test the qv() sub
	diag "testing qv" if $Verbose;
	$version = qv("1.2");
	cmp_ok ( $version, "eq", "v1.2.0", 'qv("1.2") eq "1.2.0"' );
	$version = qv(1.2);
	cmp_ok ( $version, "eq", "v1.2.0", 'qv(1.2) eq "1.2.0"' );
	isa_ok( qv('5.008'), $CLASS );
}

	# test creation from existing version object
	diag "create new from existing version" if $Verbose;
	ok (eval {$new_version = $CLASS->new($version)},
		"new from existing object");
	ok ($new_version == $version, "class->new($version) identical");
	$new_version = $version->new();
	isa_ok ($new_version, $CLASS );
	is ($new_version, "0.000", "version->new() doesn't clone");
	$new_version = $version->new("1.2.3");
	is ($new_version, "v1.2.3" , '$version->new("1.2.3") works too');

	# test the CVS revision mode
	diag "testing CVS Revision" if $Verbose;
	$version = new $CLASS qw$Revision: 1.2$;
	ok ( $version eq "1.2.0", 'qw$Revision: 1.2$ eq 1.2.0' );
	$version = new $CLASS qw$Revision: 1.2.3.4$;
	ok ( $version eq "1.2.3.4", 'qw$Revision: 1.2.3.4$ eq 1.2.3.4' );
	
	# test the CPAN style reduced significant digit form
	diag "testing CPAN-style versions" if $Verbose;
	$version = $CLASS->new("1.23_01");
	is ( "$version" , "1.23_0100", "CPAN-style alpha version" );
	ok ( $version > 1.23, "1.23_01 > 1.23");
	ok ( $version < 1.24, "1.23_01 < 1.24");

	# test reformed UNIVERSAL::VERSION
	diag "Replacement UNIVERSAL::VERSION tests" if $Verbose;
	
	# we know this file is here since we require it ourselves
	$version = $Test::More::VERSION;
	eval "use Test::More $version";
	unlike($@, qr/Test::More version $version/,
		'Replacement eval works with exact version');
	
	# test as class method
	$new_version = Test::More->VERSION;
	cmp_ok($new_version,'cmp',$version, "Called as class method");

	# this should fail even with old UNIVERSAL::VERSION
	$version = $Test::More::VERSION+0.01;
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
	
	{ # dummy up some variously broken modules for testing
	    open F, ">xxx.pm" or die "Cannot open xxx.pm: $!\n";
	    print F "1;\n";
	    close F;
	    my $error_regex;
	    if ( $] < 5.008 ) {
		$error_regex = 'xxx does not define \$xxx::VERSION';
	    }
	    else {
		$error_regex = 'xxx defines neither package nor VERSION';
	    }

	    eval "use lib '.'; use xxx 3;";
	    like ($@, qr/$error_regex/,
		'Replacement handles modules without package or VERSION'); 
	    eval "use lib '.'; use xxx; $version = xxx->VERSION";
	    unlike ($@, qr/$error_regex/,
		'Replacement handles modules without package or VERSION'); 
	    is ($versiona, undef, "Called as class method");
	    unlink 'xxx.pm';
	}
    
	{ # dummy up some variously broken modules for testing
	    open F, ">yyy.pm" or die "Cannot open yyy.pm: $!\n";
	    print F "package yyy;\n#look ma no VERSION\n1;\n";
	    close F;
	    eval "use lib '.'; use yyy 3;";
	    like ($@, qr/^yyy does not define \$yyy::VERSION/,
		'Replacement handles modules without VERSION'); 
	    eval "use lib '.'; use yyy; print yyy->VERSION";
	    unlike ($@, qr/^yyy does not define \$yyy::VERSION/,
		'Replacement handles modules without VERSION'); 
	    unlink 'yyy.pm';
	}

	{ # dummy up some variously broken modules for testing
	    open F, ">zzz.pm" or die "Cannot open zzz.pm: $!\n";
	    print F "package zzz;\n\@VERSION = ();\n1;\n";
	    close F;
	    eval "use lib '.'; use zzz 3;";
	    like ($@, qr/^zzz does not define \$zzz::VERSION/,
		'Replacement handles modules without VERSION'); 
	    eval "use lib '.'; use zzz; print zzz->VERSION";
	    unlike ($@, qr/^zzz does not define \$zzz::VERSION/,
		'Replacement handles modules without VERSION'); 
	    unlink 'zzz.pm';
	}

SKIP: 	{
	    skip 'Cannot test bare v-strings with Perl < 5.8.1', 4
		    if $] < 5.008_001; 
	    diag "Tests with v-strings" if $Verbose;
	    $version = $CLASS->new(1.2.3);
	    ok("$version" eq "v1.2.3", '"$version" eq 1.2.3');
	    $version = $CLASS->new(1.0.0);
	    $new_version = $CLASS->new(1);
	    ok($version == $new_version, '$version == $new_version');
	    ok($version eq $new_version, '$version eq $new_version');
	    skip "version require'd instead of use'd, cannot test qv", 1
		if defined $no_qv;
	    $version = qv(1.2.3);
	    ok("$version" eq "v1.2.3", 'v-string initialized qv()');
	}

	diag "Tests with real-world (malformed) data" if $Verbose;

	# trailing zero testing (reported by Andreas Koenig).
	$version = $CLASS->new("1");
	ok($version->numify eq "1.000", "trailing zeros preserved");
	$version = $CLASS->new("1.0");
	ok($version->numify eq "1.000", "trailing zeros preserved");
	$version = $CLASS->new("1.0.0");
	ok($version->numify eq "1.000000", "trailing zeros preserved");
	$version = $CLASS->new("1.0.0.0");
	ok($version->numify eq "1.000000000", "trailing zeros preserved");
	
	# leading zero testing (reported by Andreas Koenig).
	$version = $CLASS->new(".7");
	ok($version->numify eq "0.700", "leading zero inferred");

	# leading space testing (reported by Andreas Koenig).
	$version = $CLASS->new(" 1.7");
	ok($version->numify eq "1.700", "leading space ignored");

SKIP:	{

	    # dummy up a legal module for testing RT#19017
	    open F, ">www.pm" or die "Cannot open www.pm: $!\n";
	    print F <<"EOF";
package www;
use version; \$VERSION = qv('0.0.4');
1;
EOF
	    close F;

	    eval "use lib '.'; use www 0.000008;";
	    like ($@, qr/^www version 0.000008 \(v0.0.8\) required/,
		"Make sure very small versions don't freak"); 
	    eval "use lib '.'; use www 1;";
	    like ($@, qr/^www version 1.000 \(v1.0.0\) required/,
		"Comparing vs. version with no decimal"); 
	    eval "use lib '.'; use www 1.;";
	    like ($@, qr/^www version 1.000 \(v1.0.0\) required/,
		"Comparing "); 

	    skip 'Cannot "use" extended versions with Perl < 5.6.2', 1
		if $] < 5.006_002;
	    eval "use lib '.'; use www 0.0.8;";
	    like ($@, qr/^www version 0.000008 \(v0.0.8\) required/,
		"Make sure very small versions don't freak"); 

	    unlink 'www.pm';
	}
}

1;
