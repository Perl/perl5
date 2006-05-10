#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

print "1..31\n";

# Can't require test.pl, as we're testing the use/require mechanism here.

my $test = 1;

sub _ok {
    my ($type, $got, $expected, $name) = @_;

    my @caller = caller(2);
    if ($name) {
	$name = " $name";
    }
    $name .= " at $caller[1] line $caller[2]";

    my $result;
    if ($type eq 'is') {
	$result = $got eq $expected;
    } elsif ($type eq 'isnt') {
	$result = $got ne $expected;
    } elsif ($type eq 'like') {
	$result = $got =~ $expected;
    } else {
	die "Unexpected type '$type'$name";
    }
    if ($result) {
	print "ok $test\n";
    } else {
	print "not ok $test\n";
	print "# Failed test $name\n";
	print "# Got      '$got'\n";
	if ($type eq 'is') {
	    print "# Expected '$expected'\n";
	} elsif ($type eq 'isnt') {
	    print "# Expected not '$expected'\n";
	} elsif ($type eq 'like') {
	    print "# Expected $expected\n";
	}
    }
    $test = $test + 1;
    $result;
}

sub like ($$;$) {
    _ok ('like', @_);
}
sub is ($$;$) {
    _ok ('is', @_);
}
sub isnt ($$;$) {
    _ok ('isnt', @_);
}

eval "use 5.000";	# implicit semicolon
is ($@, '');

eval "use 5.000;";
is ($@, '');

eval "use 6.000;";
like ($@, qr/Perl v6\.0\.0 required--this is only \Q$^V\E, stopped/);

eval "no 6.000;";
is ($@, '');

eval "no 5.000;";
like ($@, qr/Perls since v5\.0\.0 too modern--this is \Q$^V\E, stopped/);

eval sprintf "use %.6f;", $];
is ($@, '');


eval sprintf "use %.6f;", $] - 0.000001;
is ($@, '');

eval sprintf("use %.6f;", $] + 1);
like ($@, qr/Perl v6.\d+.\d+ required--this is only \Q$^V\E, stopped/);

eval sprintf "use %.6f;", $] + 0.00001;
like ($@, qr/Perl v5.\d+.\d+ required--this is only \Q$^V\E, stopped/);

{ use lib }	# check that subparse saves pending tokens

local $lib::VERSION = 1.0;

eval "use lib 0.9";
is ($@, '');

eval "use lib 1.0";
is ($@, '');

eval "use lib 1.01";
isnt ($@, '');


eval "use lib 0.9 qw(fred)";
is ($@, '');

if ($^O eq 'MacOS') {
    is($INC[0], ":fred:");
} else {
    is($INC[0], "fred");
}

eval "use lib 1.0 qw(joe)";
is ($@, '');


if ($^O eq 'MacOS') {
    is($INC[0], ":joe:");
} else {
    is($INC[0], "joe");
}


eval "use lib 1.01 qw(freda)";
isnt($@, '');

if ($^O eq 'MacOS') {
    isnt($INC[0], ":freda:");
} else {
    isnt($INC[0], "freda");
}

{
    local $lib::VERSION = 35.36;
    eval "use lib v33.55";
    is ($@, '');

    eval "use lib v100.105";
    like ($@, qr/lib version 100.105 \(v100\.105\.0\) required--this is only version 35.360 \(v35\.360\.0\)/);

    eval "use lib 33.55";
    is ($@, '');

    eval "use lib 100.105";
    like ($@, qr/lib version 100.105 \(v100\.105\.0\) required--this is only version 35.360 \(v35\.360\.0\)/);

    local $lib::VERSION = '35.36';
    eval "use lib v33.55";
    like ($@, '');

    eval "use lib v100.105";
    like ($@, qr/lib version 100.105 \(v100\.105\.0\) required--this is only version 35.360 \(v35\.360\.0\)/);

    eval "use lib 33.55";
    is ($@, '');

    eval "use lib 100.105";
    like ($@, qr/lib version 100.105 \(v100\.105\.0\) required--this is only version 35.360 \(v35\.360\.0\)/);

    local $lib::VERSION = v35.36;
    eval "use lib v33.55";
    is ($@, '');

    eval "use lib v100.105";
    like ($@, qr/lib version 100.105 \(v100\.105\.0\) required--this is only version 35.036000 \(v35\.36\.0\)/);

    eval "use lib 33.55";
    is ($@, '');

    eval "use lib 100.105";
    like ($@, qr/lib version 100.105 \(v100\.105\.0\) required--this is only version 35.036000 \(v35\.36\.0\)/);
}


{
    # Regression test for patch 14937: 
    #   Check that a .pm file with no package or VERSION doesn't core.
    open F, ">xxx.pm" or die "Cannot open xxx.pm: $!\n";
    print F "1;\n";
    close F;
    eval "use lib '.'; use xxx 3;";
    like ($@, qr/^xxx defines neither package nor VERSION--version check failed at/);
    unlink 'xxx.pm';
}
