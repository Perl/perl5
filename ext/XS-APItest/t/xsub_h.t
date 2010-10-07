#!perl -w
use strict;

use Test::More;

BEGIN { use_ok('XS::APItest') };

use vars qw($XS_VERSION $VERSION);

# This is what the code expects
my $real_version = $XS::APItest::VERSION;

sub default {
    return ($_[0], undef) if @_;
    return ($XS_VERSION, 'XS_VERSION') if defined $XS_VERSION;
    return ($VERSION, 'VERSION');
}

sub expect_good {
    my $package = $_[0];
    my $version = exists $_[1] ? ", $_[1]" : '';
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is_deeply([XS_VERSION_defined(@_)], [],
	      "Is good for $package$version");

    is_deeply([XS_VERSION_undef(@_)], [],
	      "Is good for $package$version with #undef XS_VERSION");
}

sub expect_bad {
    my $what = shift;
    my $package = $_[0];
    my $desc; # String to use in test descriptions

    if (defined $what) {
	$what = quotemeta('$' . $package . '::' . $what);
    } else {
	$what = 'bootstrap parameter';
    }
    if (exists $_[1]) {
	$desc = "$_[0], $_[1]";
    } else {
	$desc = $_[0];
    }

    is(eval {XS_VERSION_defined(@_); "Oops"}, undef, "Is bad for $desc");
    like($@,
	 qr/$package object version $real_version does not match $what/,
	 'expected error message');

    is_deeply([XS_VERSION_undef(@_)], [],
	      "but is good for $desc with #undef XS_VERSION");
}

# With neither $VERSION nor $XS_VERSION defined, no check is made if no version
# is passed in
expect_good('dummy_package');

foreach ($real_version, version->new($real_version)) {
    expect_good('dummy_package', $_);
}

foreach (3.14, version->new(3.14)) {
    expect_bad(undef, 'dummy_package', $_);
}

my @versions = ($real_version, version->new($real_version),
		3.14, version->new(3.14));

# Package variables
foreach $XS_VERSION (undef, @versions) {
    foreach $VERSION (undef, @versions) {
	my ($expect, $what) = default();
	if (defined $expect) {
	    if ($expect eq $real_version) {
		expect_good('main');
	    } else {
		expect_bad($what, 'main');
	    }
	}
	foreach my $param (@versions) {
	    my ($expect, $what) = default($param);
	    if ($expect eq $real_version) {
		expect_good('main', $param);
	    } else {
		expect_bad($what, 'main', $param);
	    }
	}
    }
}

done_testing();
