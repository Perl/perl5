#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = ('../lib', 'lib');
    $INC{"feature.pm"} = 1; # so we don't attempt to load feature.pm
}

print "1..84\n";

# Can't require test.pl, as we're testing the use/require mechanism here.

my $test = 1;

sub _ok {
    my ($type, $got, $expected, $name) = @_;

    my $result;
    if ($type eq 'is') {
        $result = $got eq $expected;
    } elsif ($type eq 'isnt') {
        $result = $got ne $expected;
    } elsif ($type eq 'like') {
        $result = $got =~ $expected;
    } elsif ($type eq 'ok') {
        $result = not not $got;
    } else {
        die "Unexpected type '$type'$name";
    }
    if ($result) {
        if ($name) {
            print "ok $test - $name\n";
        } else {
            print "ok $test\n";
        }
    } else {
        if ($name) {
            print "not ok $test - $name\n";
        } else {
            print "not ok $test\n";
        }
        my @caller = caller(1);
        print "# Failed test at $caller[1] line $caller[2]\n";
        print "# Got      '$got'\n";
        if ($type eq 'is') {
            print "# Expected '$expected'\n";
        } elsif ($type eq 'isnt') {
            print "# Expected not '$expected'\n";
        } elsif ($type eq 'like') {
            print "# Expected $expected\n";
        } elsif ($type eq 'ok') {
            print "# Expected a true value\n";
        }
    }
    $test = $test + 1;
    return !!$result;
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
sub ok($;$) {
    _ok ('ok', shift, undef, @_);
}

my @bad = (
    'use v8', # not sure - need decision
    'use v6',
    'use v6.1',
    'use v6.0.1',
    'use 6.001',
    'no 6',
    'no v6',
    'use 66',
    'no 66',
    # use v7.*; # index('v7.')
    'use 7',
    'use 7.0',
    'use 7.42', # index('7')
    'use 5.10', # => 5.100
    'use 5.6', #  => 5.600
    'no v5',
    'use 5.34',
    'use v5.34',
    'use 5.33',
    'use v5.33',
);

my @good = (
    'use v7',
    'no v7',
    'use v5',
    'use v5.10',
    'use 5.010',
    'use v5.8.5',
    'use v5.14',
    'use v5.32',
);

foreach my $v ( @good ) {
    eval qq[ $v; ];
    is( $@, '', "'$v;' is valid" . ( $@ ? "# $@" : '' ) );
}

foreach my $v ( @bad ) {
    eval qq[ $v; ];
    isnt( $@, '', "'$v;' is invalid");
}

eval "use 5";
is ($@, '', "implicit semicolon");

eval "use 5;";
is ($@, '', "explicit semicolon");

eval "{use 5}";
is ($@, '', "[perl #70884] -> GH 9990");

eval "{use 5   }";
is ($@, '', "[perl #70884] -> GH 9990");

# new style version numbers

eval q{ use v5.5.630; };
is ($@, '', "3-part version number");

eval q{ use 10.0.2; };
like ($@, qr/^\QPerl v10.0.2 required--this is only \E$^V/,
    "Got expected error message: use 10.0.2;");

eval "use 5.000";
is ($@, '', "implicit semicolon - decimal version number");

eval "use 5.000;";
is ($@, '', "explicit semicolon - decimal version number");

eval "use 6.000;";
like ($@, qr/\Q'use 6' is not supported by Perl 7\E/,
    "Got expected error message: use 6.000");

eval "no 8.000;";
like ($@, qr{\QUnknown behavior for 'use 8'\E}, "No error for 'no 8.000'");

eval "no 5.000;";
like ($@, qr/Perls since v5\.0\.0 too modern--this is \Q$^V\E, stopped/,
    "Got expected error message: 'no 5.000'");

eval "use 5.6;";
like ($@, qr/Perl v5\.600\.0 required \(did you mean v5\.6\.0\?\)--this is only \Q$^V\E, stopped/,
    "Got expected error message: 'use 5.6;'");

eval "use 5.8;";
like ($@, qr/Perl v5\.800\.0 required \(did you mean v5\.8\.0\?\)--this is only \Q$^V\E, stopped/,
    "Got expected error message: 'use 5.8;'");

eval "use 5.9;";
like ($@, qr/Perl v5\.900\.0 required \(did you mean v5\.9\.0\?\)--this is only \Q$^V\E, stopped/,
    "Got expected error message: 'use 5.9;'");

eval "use 5.10;";
like ($@, qr/Perl v5\.100\.0 required \(did you mean v5\.10\.0\?\)--this is only \Q$^V\E, stopped/,
    "Got expected error message: 'use 5.10;'");

eval "use 5.8;";
like ($@, qr/Perl v5\.800\.0 required \(did you mean v5\.8\.0\?\)--this is only \Q$^V\E, stopped/,
    "Got expected error message: 'use 5.8;'");

my $fiveV = q[5.032000];

my $str;

eval( $str = sprintf "use %.6f;", $fiveV );
is ($@, '', "No error message on: '$str'");

eval( $str = sprintf "use %.6f;", $fiveV - 0.000001 );
is ($@, '', "No error message on: $str'");

eval( $str = sprintf("use %.6f;", $fiveV + 1) );
like ($@, qr/\Q'use 6.032' is not supported by Perl 7\E/,
    "Got expected error message: '$str'");

eval( $str = sprintf "use %.6f;", $fiveV + 0.00001 );
is( $@, '', "No error message on: '$str'");

eval( $str = sprintf "use %.6f;", $fiveV + 0.001001 );
like ($@, qr/Perl v5.\d+.\d+ required--this is only \Q$^V\E, stopped/a,
    "Got expected error message: '$str'");


# check that "use 5.11.0" (and higher) loads strictures
eval 'use 5.11.0; ${"foo"} = "bar";';
like ($@, qr/Can't use string \("foo"\) as a SCALAR ref while "strict refs" in use/,
    "5.11.0 (and higher) loads strictures");
# but that they can be disabled
eval 'use 5.11.0; no strict "refs"; ${"foo"} = "bar";';
is ($@, "", "... but strictures can be disabled");
# and they are properly scoped
eval '{use 5.11.0;} ${"foo"} = "bar";';
is ($@, "", "... and they are properly scoped");

eval 'no strict; use 5.012; ${"foo"} = "bar"';
is $@, "", 'explicit "no strict" overrides later ver decl';
eval 'use strict; use 5.01; ${"foo"} = "bar"';
like $@, qr/^Can't use string/,
    'explicit use strict overrides later use 5.01';
eval 'use strict "subs"; use 5.012; ${"foo"} = "bar"';
like $@, qr/^Can't use string/,
    'explicit use strict "subs" does not stop ver decl from enabling refs';
eval 'use 5.012; use 5.01; ${"foo"} = "bar"';
is $@, "", 'use 5.01 overrides implicit strict from prev ver decl';
eval 'no strict "subs"; use 5.012; ${"foo"} = "bar"';
ok $@, 'no strict subs allows ver decl to enable refs';
eval 'no strict "subs"; use 5.012; $nonexistent_pack_var';
ok $@, 'no strict subs allows ver decl to enable vars';
eval 'no strict "refs"; use 5.012; fancy_bareword';
ok $@, 'no strict refs allows ver decl to enable subs';
eval 'no strict "refs"; use 5.012; $nonexistent_pack_var';
ok $@, 'no strict refs allows ver decl to enable subs';
eval 'no strict "vars"; use 5.012; ${"foo"} = "bar"';
ok $@, 'no strict vars allows ver decl to enable refs';
eval 'no strict "vars"; use 5.012; ursine_word';
ok $@, 'no strict vars allows ver decl to enable subs';


{ use test_use }    # check that subparse saves pending tokens

use test_use { () };
is ref $test_use::got[0], 'HASH', 'use parses arguments in term lexing cx';

local $test_use::VERSION = 1.0;

eval "use test_use 0.9";
is ($@, '', "use test_use 0.9");

eval "use test_use 1.0";
is ($@, '', "use test_use 1.0");

eval "use test_use 1.01";
isnt ($@, '', 'use test_use 1.01');

eval "use test_use 0.9 qw(fred)";
is ($@, '', 'use test_use 0.9 qw(fred)');

is("@test_use::got", "fred", 'got fred');

eval "use test_use 1.0 qw(joe)";
is ($@, '', 'use test_use 1.0 qw(joe)');

is("@test_use::got", "joe", 'got joe');

eval "use test_use 1.01 qw(freda)";
isnt($@, '', 'use test_use 1.01 qw(freda)');

is("@test_use::got", "joe", 'got joe');

{
    local $test_use::VERSION = 35.36;
    eval "use test_use v33.55";
    is ($@, '', 'use test_use v33.55');

    eval "use test_use v100.105";
    like ($@, qr/test_use version v100.105.0 required--this is only version v35\.360\.0/,
        "Got expected error message: insufficient test_use version");

    eval "use test_use 33.55";
    is ($@, '', 'use test_use 33.55');

    eval "use test_use 100.105";
    like ($@, qr/test_use version 100.105 required--this is only version 35.36/,
        "Got expected error message:  insufficient test_use version");

    local $test_use::VERSION = '35.36';
    eval "use test_use v33.55";
    like ($@, '', 'use test_use v33.55');

    eval "use test_use v100.105";
    like ($@, qr/test_use version v100.105.0 required--this is only version v35\.360\.0/,
        "Got expected error message:  insufficient test_use version");

    eval "use test_use 33.55";
    is ($@, '', 'use test_use 33.55');

    eval "use test_use 100.105";
    like ($@, qr/test_use version 100.105 required--this is only version 35.36/,
        "Got expected error message:  insufficient test_use version");

    local $test_use::VERSION = v35.36;
    eval "use test_use v33.55";
    is ($@, '', 'use test_use v33.55');

    eval "use test_use v100.105";
    like ($@, qr/test_use version v100.105.0 required--this is only version v35\.36\.0/,
        "Got expected error message:  insufficient test_use version");

    eval "use test_use 33.55";
    is ($@, '', 'use test_use 33.55');

    eval "use test_use 100.105";
    like ($@, qr/test_use version 100.105 required--this is only version v35.36/,
        "Got expected error message:  insufficient test_use version");
}


{
    # Regression test for patch 14937:
    #   Check that a .pm file with no package or VERSION doesn't core.
    # (git commit 2658f4d9934aba5f8b23afcc078dc12b3a40223)
    eval "use test_use_14937 3";
    like ($@, qr/^test_use_14937 defines neither package nor VERSION--version check failed at/, "test_use_14937");
}

