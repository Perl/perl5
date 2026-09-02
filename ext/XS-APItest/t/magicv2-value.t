use strict;
use warnings;
use feature 'signatures';

use Test::More;

use Config;
plan skip_all => "Your perl was built without taint (and therefore value magic) support"
    unless $Config{taint_support};

use XS::APItest;

# value magics drag MgAUXSV around
{
    my $auxsv;

    my $x;
    sv_magicv2_add($x, value => \$auxsv);
    is(Internals::SvREFCNT($auxsv), 2, '$auxsv has refcount 2 after add');

    # copy SV to SV
    {
        my $y = $x;
        ok(sv_magicv2_exists($y, 'value'), '$y has value magic after copy from $x');
        is(MgAUXSV($y, 'value'), \$auxsv, '$y has auxsv');
        is(Internals::SvREFCNT($auxsv), 3, '$auxsv has refcount 3 after copy');
    }

    # copy SV to AV elem
    {
        my @arr;
        $arr[0] = $x;
        ok(sv_magicv2_exists($arr[0], 'value'), '$arr[0] has value magic after copy from $x');
        is(MgAUXSV($arr[0], 'value'), \$auxsv, '$arr[0] has auxsv');
        is(Internals::SvREFCNT($auxsv), 3, '$auxsv has refcount 3 after copy');
    }

    # copy SV to HV elem
    {
        my %hash;
        $hash{key} = $x;
        ok(sv_magicv2_exists($hash{key}, 'value'), '$hash{key} has value magic after copy from $x');
        is(MgAUXSV($hash{key}, 'value'), \$auxsv, '$hash{key} has auxsv');
        is(Internals::SvREFCNT($auxsv), 3, '$auxsv has refcount 3 after copy');
    }

    # call/return
    {
        # pass by $_[0]
        (sub {
            ok(sv_magicv2_exists($_[0], 'value'), '$_[0] has value magic after copy from caller');
        })->($x);

        # pass by shift
        (sub {
            ok(sv_magicv2_exists(shift, 'value'), 'shift has value magic after copy from caller');
        })->($x);

        # pass by signature
        (sub ($y) {
            ok(sv_magicv2_exists($y, 'value'), 'signature var has value magic after copy from caller');
        })->($x);

        ok(sv_magicv2_exists((sub { return $x })->(), 'value'),
            'returned value has value magic');
    }
}

# value magics are removed when required
{
    my $src;
    sv_magicv2_add($src, value => undef);

    {
        my $x = $src;
        undef $x;
        ok(!sv_magicv2_exists($x, 'value'), '$x no longer has value magic after undef');
    }

    {
        my $x = $src;
        $x = undef;
        ok(!sv_magicv2_exists($x, 'value'), '$x no longer has value magic after overwrite with undef');
    }

    {
        my $x = $src;
        $x = 123;
        ok(!sv_magicv2_exists($x, 'value'), '$x no longer has value magic after overwrite with 123');
    }

    {
        my $x = $src;
        my $y = 456;
        $x = $y;
        ok(!sv_magicv2_exists($x, 'value'), '$x no longer has value magic after overwrite with SV');
    }
}

# Now we know that basic call/return works, we can use this to create more
# compact testing functions
#
# We do each test twice in a row to check that old values don't leak from
# e.g. pad temporaries

sub value_ok ( $code, $name, $input_value = undef )
{
    foreach my $round (qw( first second )) {
        my $inp = $input_value // "inp for $name";
        sv_magicv2_add($inp, value => \"test-val $round");

        my $out = $code->( $inp );
        is_deeply([MgAUXSV_values($out, 'value')], ["test-val $round"],
            "$name passes value magic");
    }
}

# array ops
value_ok(sub ($x) { my @arr; push @arr, $x; $arr[0] }, 'push');
value_ok(sub ($x) { my @arr; unshift @arr, $x; $arr[0] }, 'unshift');
value_ok(sub ($x) { my @arr = ( $x ); shift @arr }, 'shift');
value_ok(sub ($x) { my @arr = ( $x ); pop @arr }, 'pop');
value_ok(sub ($x) { my @arr; splice @arr, 0, 0, ( $x ); $arr[0] }, 'splice in');
value_ok(sub ($x) { my @arr = ( $x ); splice @arr, 0, 1 }, 'splice out');

# hash ops
value_ok(sub ($x) { my %hash = ( key => $x ); ( values %hash )[0] }, 'values');
value_ok(sub ($x) { my %hash = ( key => $x ); delete $hash{key} }, 'delete');

# pp_anonhash uses newSVsv which has many different sub-cases to it
value_ok(sub ($x) { my $href = { key => $x }; $href->{key} }, 'anonhash (PV)' );
value_ok(sub ($x) { my $href = { key => $x }; $href->{key} }, 'anonhash (IV)',   123 );
value_ok(sub ($x) { my $href = { key => $x }; $href->{key} }, 'anonhash (NV)',   1.23 );
value_ok(sub ($x) { my $href = { key => $x }; $href->{key} }, 'anonhash (RV)',   \undef );
value_ok(sub ($x) { my $href = { key => $x }; $href->{key} }, 'anonhash (bool)', builtin::true );

# other control flow
value_ok(sub ($x) { my $ret = do { $x; }; $ret }, 'do BLOCK');
value_ok(sub ($x) { my $ret = eval { $x; }; $ret }, 'eval BLOCK');
value_ok(sub ($x) {
    use feature 'try';
    try { die $x; }
    catch ($e) { return $e; }
}, 'try/catch' );

# Value-returning UNOPs
sub unop_value_ok ( $inp, $code, $want_out, $name )
{
    foreach my $round (qw( first second )) {
        my @args = ($inp);
        sv_magicv2_add($args[0], value => \"test-val $name $round");

        my $got_out = $code->( @args );
        $round eq "first" and
            is($got_out, $want_out, "$name value hook yields correct result");

        is_deeply([MgAUXSV_values($got_out, 'value')], ["test-val $name $round"],
            "$name unop passes value hook");
    }
}

unop_value_ok(1, sub ($x) { -$x }, -1, "negate");
unop_value_ok(1, sub ($x) { ~$x }, ~1, "complement");
unop_value_ok("abc", sub ($x) { length $x }, 3, "length");

# OP_STRINGIFY is a listop despite only taking 1 argument
# OP_SUBSTR only copies value magic from the string argument, not the positions
# We can treat both as unops
unop_value_ok("xyz", sub ($x) { "$x" }, "xyz", "stringify");

unop_value_ok("xyz", sub ($x) { return substr $x, 1, 1 }, "y", "substr (3arg non-MOD)");
unop_value_ok("xyz", sub ($x) { return substr $x, 1, 1, "B" }, "y", "substr (4arg non-MOD)");
unop_value_ok("xyz", sub ($x) { my $ret = "ABC"; substr $ret, 1, 1, $x; $ret; }, "AxyzC", "substr (4arg non-MOD) mutation");
unop_value_ok("xyz", sub ($x) { my $ret = "ABC"; substr( $ret, 1, 1 ) = $x; $ret; }, "AxyzC", "substr (3arg MOD rewritten)");
# Perl will rewrite a simple  substr($x, $n, $c) = $y  into a 4-arg with
# reördered arguments, so we have to test true lvalue returns via $_
unop_value_ok("xyz", sub ($x) { my $ret = "ABC"; $_ = $x for substr( $ret, 1, 1 ); $ret; }, "AxyzC", "substr (3arg MOD)");

# OP_SUBSTR_LEFT kicks in if known non-lvalue, offset is constant zero and
# there is no replacement
unop_value_ok("xyz", sub ($x) { my $ret = substr $x, 0, 2; $ret; }, "xy", "substr_left");

# OP_SUBST has many corner-cases
unop_value_ok("one,two,three", sub ($x) { $x =~ s/,/-/; $x }, "one-two,three",
    'subst const' );
unop_value_ok("one,two,three", sub ($x) { $x =~ s/,/-/g; $x }, "one-two-three",
    'subst const global' );
unop_value_ok("one,two,three", sub ($x) { $x =~ s/,//; $x }, "onetwo,three",
    'subst const shorter' );
unop_value_ok("one,two,three", sub ($x) { $x =~ s/,/--/; $x }, "one--two,three",
    'subst const longer' );
unop_value_ok("one,two,three", sub ($x) { $x =~ s/,/-/r }, "one-two,three",
    'subst const non-destruct' );
unop_value_ok("one,two,three", sub ($x) { $x =~ s/,/-/gr }, "one-two-three",
    'subst const global non-destruct' );
unop_value_ok("one,two,three", sub ($x) { $x =~ s/,//r }, "onetwo,three",
    'subst const non-destruct longer' );
unop_value_ok("one,two,three", sub ($x) { $x =~ s/,/--/r }, "one--two,three",
    'subst const non-destruct shorter' );
unop_value_ok("one,two,three", sub ($x) { $x =~ s/,...,/-two-/; $x }, "one-two-three",
    'subst const variable-pattern' );
unop_value_ok("one,two,three", sub ($x) { $x =~ s/,...,/-two-/r }, "one-two-three",
    'subst const variable-pattern non-destruct' );
unop_value_ok("one,two,three", sub ($x) { "$x" =~ s/,/-/gr }, "one-two-three",
    'subst const global non-destruct OPf_STACKED' );
unop_value_ok("one,two,three", sub ($x) { $_ = $x; s/,/-/g; $_ }, "one-two-three",
    'subst const global on defsv' );
unop_value_ok("one,two,three", sub ($x) { my $s = "four,five"; $s =~ s/.*/$x/; $s }, "one,two,three",
    'subst expr[padsv]' );
unop_value_ok("one,two,three", sub ($x) { my $s = "four,five"; $s =~ s/.*/$x/r }, "one,two,three",
    'subst expr[padsv] non-destruct' );
unop_value_ok("one,two,three", sub ($x) { $_ = "four,five"; s/.*/$x/; $_ }, "one,two,three",
    'subst expr[padsv] on defsv' );
unop_value_ok("one,two,three", sub ($x) { $_ = "four,five"; s/.*/($x)/; $_ }, "(one,two,three)",
    'subst expr[multiconcat] on defsv' );
unop_value_ok("one,two,three", sub ($x) { "four,five" =~ s/.*/($x)/r }, "(one,two,three)",
    'subst expr[multiconcat] non-destruct' );
# TODO: There may be other combinations as yet untested that have subtle weird
# behaviours

# subst with a constant should -not- obtain magic if it fails to match
{
    my $repl = "repl"; sv_magicv2_add($repl, value => \"ignore-me" );

    my $x = "abcd"; $x =~ s/xyz/$repl/;
    is_deeply( [MgAUXSV_values($x, 'value') ], [],
        'var remains unmagic after unsuccessful subst' );

    my $y = "abcd" =~ s/xyz/$repl/r;
    is_deeply( [MgAUXSV_values($x, 'value') ], [],
        'result remains unmagic after unsuccessful subst non-destruct' );
}

# Inplace-mutating UNOPs; check variable also
sub mut_unop_value_ok ( $inp, $code, $want_out, $want_outvar, $name )
{
    foreach my $round (qw( first second )) {
        my @args = ($inp);
        sv_magicv2_add($args[0], value => \"test-val $name $round");

        my ($got_out, $got_outvar) = $code->( @args );
        $round eq "first" and do {
            is($got_out, $want_out, "$name value hook yields correct result");
            is($got_outvar, $want_outvar, "$name value hook yields correct mutation");
        };

        is_deeply([MgAUXSV_values($got_out, 'value')], ["test-val $name $round"],
            "$name mutating unop passes value hook");
        is_deeply([MgAUXSV_values($got_outvar, 'value')], ["test-val $name $round"],
            "$name mutating unop preserves value hook");
    }
}

mut_unop_value_ok(1,       sub ($x) { my $ret = ++$x;     $ret, $x }, 2, 2, "preinc");
mut_unop_value_ok(1,       sub ($x) { my $ret = --$x;     $ret, $x }, 0, 0, "predec");
mut_unop_value_ok(1,       sub ($x) { my $ret = $x++;     $ret, $x }, 1, 2, "postinc");
mut_unop_value_ok(1,       sub ($x) { my $ret = $x--;     $ret, $x }, 1, 0, "postdec");
mut_unop_value_ok("abc",   sub ($x) { my $ret = chop $x;  $ret, $x }, "c", "ab", "chop");
mut_unop_value_ok("abc\n", sub ($x) { my $ret = chomp $x; $ret, $x }, "1", "abc", "chomp");

# Base-or-UNOPs; which might operate on $_
sub base_or_unop_value_ok( $inp, $code, $want_out, $name )
{
    foreach my $round (qw( first second )) {
        my @args = ($inp);
        sv_magicv2_add($args[0], value => \"test-val $name $round");

        my ($got_base, $got_un) = $code->( ( local $_ ) = @args );
        $round eq "first" and do {
            is($got_base, $want_out, "$name as baseop value hook yields correct result");
            is($got_un, $want_out, "$name as unop value hook yields correct result");
        };

        is_deeply([MgAUXSV_values($got_base, 'value')], ["test-val $name $round"],
            "$name as baseop passes value hook");
        is_deeply([MgAUXSV_values($got_un, 'value')], ["test-val $name $round"],
            "$name as unop passes value hook");
    }
}

use feature 'fc';
base_or_unop_value_ok("xyz", sub ($x) { uc,      uc $x },      "XYZ", "uc");
base_or_unop_value_ok("xyz", sub ($x) { ucfirst, ucfirst $x }, "Xyz", "ucfirst");
base_or_unop_value_ok("XYZ", sub ($x) { lc,      lc $x },      "xyz", "lc");
base_or_unop_value_ok("XYZ", sub ($x) { lcfirst, lcfirst $x }, "xYZ", "lcfirst");
base_or_unop_value_ok("xyz", sub ($x) { fc,      fc $x },      fc "xyz", "fc");
base_or_unop_value_ok("a",   sub ($x) { ord,     ord $x },     ord "a", "ord");
base_or_unop_value_ok(65,    sub ($x) { chr,     chr $x },     chr 65,  "chr");

sub binop_value_ok( $in1, $in2, $code, $want_out, $name )
{
    foreach my $round (qw( first second )) {
        my @args;
        my $got_out;

        # Just LHS
        @args = ( $in1, $in2 );
        sv_magicv2_add($args[0], value => \"test-val $name LHS $round");

        $got_out = $code->( @args );
        $round eq "first" and
            is($got_out, $want_out, "$name value hook yields correct result");

        is_deeply([MgAUXSV_values($got_out, 'value')], ["test-val $name LHS $round"],
            "$name binop passes value hook from LHS");

        # Just RHS
        @args = ( $in1, $in2 );
        sv_magicv2_add($args[1], value => \"test-val $name RHS $round");

        $got_out = $code->( @args );
        is_deeply([MgAUXSV_values($got_out, 'value')], ["test-val $name RHS $round"],
            "$name binop passes value hook from RHS");

        # Both
        @args = ( $in1, $in2 );
        sv_magicv2_add($args[0], value => \"test-val $name ALLLHS $round");
        sv_magicv2_add($args[1], value => \"test-val $name ALLRHS $round");

        $got_out = $code->( @args );
        is_deeply([sort +MgAUXSV_values($got_out, 'value')],
                  ["test-val $name ALLLHS $round", "test-val $name ALLRHS $round"],
            "$name binop passes value hook from both args simultaneously");
    }
}

binop_value_ok(1, 1, sub ($x, $y) { $x +  $y },      2, "add" );
binop_value_ok(1, 1, sub ($x, $y) { $x += $y; $x },  2, "add mutating" );
binop_value_ok(1, 1, sub ($x, $y) { $x -  $y },      0, "subtract" );
binop_value_ok(1, 1, sub ($x, $y) { $x -= $y; $x },  0, "subtract mutating" );
binop_value_ok(1, 1, sub ($x, $y) { $x *  $y },      1, "multiply" );
binop_value_ok(1, 1, sub ($x, $y) { $x *= $y; $x },  1, "multiply mutating" );
binop_value_ok(1, 1, sub ($x, $y) { $x /  $y },      1, "divide" );
binop_value_ok(1, 1, sub ($x, $y) { $x /= $y; $x },  1, "divide mutating" );
binop_value_ok(1, 1, sub ($x, $y) { $x %  $y },      0, "modulo" );
binop_value_ok(1, 1, sub ($x, $y) { $x %= $y; $x },  0, "modulo mutating" );
binop_value_ok(1, 1, sub ($x, $y) { $x **  $y },     1, "power" );
binop_value_ok(1, 1, sub ($x, $y) { $x **= $y; $x }, 1, "power mutating" );
binop_value_ok(1, 1, sub ($x, $y) { $x <<  $y },     2, "left-shift" );
binop_value_ok(1, 1, sub ($x, $y) { $x <<= $y; $x }, 2, "left-shift mutating" );
binop_value_ok(1, 1, sub ($x, $y) { $x >>  $y },     0, "right-shift" );
binop_value_ok(1, 1, sub ($x, $y) { $x >>= $y; $x }, 0, "right-shift mutating" );

binop_value_ok(1, 1, sub ($x, $y) { $x &  $y },     1, "bitwise-and" );
binop_value_ok(1, 1, sub ($x, $y) { $x &= $y; $x }, 1, "bitwise-and mutating" );
binop_value_ok(1, 1, sub ($x, $y) { $x |  $y },     1, "bitwise-or" );
binop_value_ok(1, 1, sub ($x, $y) { $x |= $y; $x }, 1, "bitwise-or mutating" );
binop_value_ok(1, 1, sub ($x, $y) { $x ^  $y },     0, "bitwise-xor" );
binop_value_ok(1, 1, sub ($x, $y) { $x ^= $y; $x }, 0, "bitwise-xor mutating" );

binop_value_ok(1, 1, sub ($x, $y) { $x .  $y },         "11", "concat" );
binop_value_ok(1, 1, sub ($x, $y) { $x .= $y; $x },     "11", "concat mutating" );
binop_value_ok(1, 1, sub ($x, $y) { $y = $x . $y; $y }, "11", "concat reuse right" );

{
    my $x = -12;
    my $y = 456;
    sv_magicv2_add($y, value => \"SVt_IV fast-path test");

    $x += $y;

    is_deeply([MgAUXSV_values($x, 'value')], ["SVt_IV fast-path test"],
        'found annotations after SVt_IV fast path');
}

{
    my $x = 123;
    my $y = 456;
    sv_magicv2_add($y, value => \"SVt_UV fast-path test");

    $x += $y;

    is_deeply([MgAUXSV_values($x, 'value')], ["SVt_UV fast-path test"],
        'found annotations after SVt_UV fast path');
}

{
    my $x = 1.23;
    my $y = 456;
    sv_magicv2_add($y, value => \"SVt_NV fast-path test");

    $x += $y;

    is_deeply([MgAUXSV_values($x, 'value')], ["SVt_NV fast-path test"],
        'found annotations after SVt_NV fast path');
}

sub listop_value_ok ( $argspec, $code, $want_out, $name )
{
    my @argspec = split m//, $argspec;
    my $argc = @argspec;

    foreach my $round (qw( first second )) {
        foreach my $idx ( 0 .. $#argspec ) {
            next unless $argspec[$idx] eq "V";

            my @args = ( "xyz" ) x $argc;
            sv_magicv2_add($args[$idx], value => \"test-val $name ARG$idx $round");

            my $got_out = $code->( @args );
            $round eq "first" and
                is($got_out, $want_out, "$name value hook yields correct result");

            is_deeply([MgAUXSV_values($got_out, 'value')], ["test-val $name ARG$idx $round"],
                "$name listop passes value hook from arg[$idx]");
        }

        # Now once more with all args annotated
        if( $argc > 1 ) {
            my @args = ( "xyz" ) x $argc;
            sv_magicv2_add($args[$_], value => \"test-val $name ALLARG$_ $round") for 0 .. $#argspec;

            my $got_out = $code->( @args );

            is_deeply([sort +MgAUXSV_values($got_out, 'value')], [map { "test-val $name ALLARG$_ $round" } ( 0 .. $#argspec )],
                "$name listop passes all value hooks");
        }
    }
}

listop_value_ok( "VVV", sub ($sep, @s) { join $sep, @s }, "xyzxyzxyz", "join" );

# OP_MULTICONCAT has many forms
listop_value_ok( "VV", sub ($x, $y) { "paste ($x) and ($y)" }, "paste (xyz) and (xyz)",
    "multiconcat (padtmp)" );
listop_value_ok( "VV", sub ($x, $y) { my $ret = "paste ($x) and ($y)"; $ret }, "paste (xyz) and (xyz)",
    "multiconcat (my \$lex)" );
listop_value_ok( "VV", sub ($x, $y) { my $ret; $ret = "paste ($x) and ($y)"; $ret }, "paste (xyz) and (xyz)",
    "multiconcat (\$lex)" );
listop_value_ok( "VV", sub ($x, $y) { my @ret; $ret[0] = "paste ($x) and ($y)"; $ret[0] }, "paste (xyz) and (xyz)",
    "multiconcat (\$lex)" );
listop_value_ok( "VVV", sub ($pre, $x, $y) { my $ret = $pre; $ret .= " and ($x) and ($y)"; $ret }, "xyz and (xyz) and (xyz)",
    "multiconcat (\$lex append)" );

# Perl will turn a simple sprintf with just %s into an OP_MULTICONCAT so we
# have to be more subtle here
listop_value_ok( "VV", sub ($x, $y) { sprintf "format with %3s and %3s", $x, $y }, "format with xyz and xyz",
    "sprintf" );

sub listret_value_ok ( $inp, $code, $want_out, $name )
{
    foreach my $round (qw( first second )) {
        my @args = ($inp);
        sv_magicv2_add($args[0], value => \"test-val $name $round");

        my $got_out = [ $code->( @args ) ];
        $round eq "first" and
            is_deeply($got_out, $want_out, "$name value hook yields correct result list");

        foreach my $gotidx ( 0 .. $#$got_out ) {
            is_deeply([MgAUXSV_values($got_out->[$gotidx], 'value')], ["test-val $name $round"],
                "$name op passes value hook in result $gotidx");
        }
    }
}

listret_value_ok("one,two,three", sub ($x) { split m/,/, $x }, [qw( one two three )],
    "split");

listret_value_ok("one,two,three", sub ($x) { ( "$x" =~ m/(.*),(.*),(.*)/ )[0,1,2] }, [qw( one two three )], "match OPf_STACKED+OPf_LIST" );
listret_value_ok("one,two,three", sub ($x) { ( $x =~ m/(.*),(.*),(.*)/ )[0,1,2] }, [qw( one two three )], "match OPf_LIST" );
listret_value_ok("one,two,three", sub ($x) { $x =~ m/(.*),(.*),(.*)/ }, [qw( one two three )], "match unknown context" );
listret_value_ok("one,two,three", sub ($x) { $_ = $x; m/(.*),(.*),(.*)/ }, [qw( one two three )], "match unknown context on defsv" );

# Tests of regexp -> dollardigit copy
listret_value_ok(
    "one,two,three", sub ($x) {
        $x =~ m/(.*),(.*),(.*)/;
        ( $1, $2, $3 )
    }, [qw( one two three )],
    'basic match capture buffers' );

listret_value_ok(
    "one,two,three", sub ($x) {
        $x =~ m/(.*),(.*),(.*)/;
        { "another" =~ m/(.*)/; }
        ( $1, $2, $3 )
    }, [qw( one two three )],
    'match capture buffers are localised per block' );

{
    my $inp = "input string";
    sv_magicv2_add($inp, value => \"test-val");

    $inp =~ m/(.*)/; my $dollar1 = $1;
    "another string" =~ m/(.*)/; $dollar1 = $1;

    is_deeply([MgAUXSV_values($1, 'value')], [],
        'second match in block clears value annotations of first');
}

# overloading preserves magic annotations

package StringifiesAsElem0 {
    use overload '""' => sub { return (shift)->[0] };
}

value_ok(
    sub ( $x ) {
        my $obj = bless [$x], "StringifiesAsElem0";
        return "$obj";
    },
    'stringification overloading' );

package NumifiesAsElem0 {
    use overload '0+' => sub { return (shift)->[0] };
}

value_ok(
    sub ( $x ) {
        my $obj = bless [$x], "NumifiesAsElem0";
        return int($obj);  # int() invokes numify overload
    },
    'numification overloading',
    123 );

done_testing;
