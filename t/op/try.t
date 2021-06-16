#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
    require Config;
}

use strict;
use warnings;
use feature 'try';

{
    my $warnings;
    BEGIN { $SIG{__WARN__} = sub { $warnings .= shift; }; }

    my $x;
    my ($ltry, $lcatch) = (__LINE__+1, __LINE__+4);
    try {
        $x .= "try";
    }
    catch ($e) {
        $x .= "catch";
    }
    is($x, "try", 'successful try/catch runs try but not catch');

    is($warnings, "try/catch is experimental at $0 line $ltry.\n" .
                  "try/catch is experimental at $0 line $lcatch.\n",
        'compiletime warnings');
    BEGIN { undef $SIG{__WARN__}; }
}


no warnings 'experimental::try';

{
    my $x;
    try {
        $x .= "try";
    }
    catch ($e) {
        $x .= "catch";
    }
    is($x, "try", 'successful try/catch runs try but not catch');
}

{
    my $x;
    my $caught;
    try {
        $x .= "try";
        die "Oopsie\n";
    }
    catch ($e) {
        $x .= "catch";
        $caught = $e;
        is($@, "", '$@ is empty within catch block');
    }
    is($x, "trycatch", 'die in try runs catch block');
    is($caught, "Oopsie\n", 'catch block saw exception value');
}

# return inside try {} makes containing function return
{
    sub f
    {
        try {
            return "return inside try";
        }
        catch ($e) { }
        return "return from func";
    }
    is(f(), "return inside try", 'return inside try');
}

# eval next/last inside try
{
    no warnings "exiting";
    my $result = "";
    try {
        {
            $result .= "a";
            eval "next";
            $result .= "b";
        }
    } catch ($e) {
        $result .= "c";
    }

    is($result, "a", 'eval "next" (inner block) inside try');

    $result = "";
    {
        try {
            $result .= "d";
            eval "last";
            $result .= "e";
        } catch ($e) {
            $result .= "f";
        }
        $result .= "skipped";
    }

    is($result, "d", 'eval "last" (outer block) inside try');
}

# eval a try
{
    my $result = "";
    eval 'try { $result = "try"; die "dying"; } catch($e) { $result .= " and catch"; }';

    is($result, "try and catch", 'eval a try');
}

# eval a try that eval a try
{
    my $result = "";
    my $eval_a_try = 'try { $result .= " and try inside"; die "dying"; } catch($e) { $result .= " and catch inside"; }';
    eval 'try { $result .= "try outside"; eval "$eval_a_try"; die "dying"; } catch($e) { $result .= " and catch ouside"; }';

    is($result, "try outside and try inside and catch inside and catch ouside", 'eval a try that eval a try');
}

# try try try try
{
    my $result = "";
    try {
        $result .= "0";
        try {
            $result .= "1";
            try {
                $result .= "2";
                try {
                    $result .= "3";
                    die "horribly";
                } catch($e) { $result .= "a"; die "again"; }
            } catch($e) { $result .= "b"; die "propagate"; }
        } catch ($e) { $result .= "c"; } # Do not propagate
    } catch ($e) { $result .= "d"; }

    is($result, "0123abc", "try try try try");
}

# Signal in try
SKIP:
{
    skip("Different behaviour of kill") if ($^O eq 'MSWin32' || $^O eq 'NetWare' || $^O eq 'VMS');
    my $result = "";
    local $SIG{INT} = sub { $result .= "INT"; die "propagate"; };
    try {
        try {
            kill INT => $$;
            try { } catch ($e) { $result .= "not this one"; }
        } catch ($e) {
	    $result .= " and catch";
        }
    } catch ($e) {
        $result .= "not this one";
    }

    is($result, "INT and catch", "signal in try");
}


# wantarray inside try
{
    my $context;
    sub whatcontext
    {
        try {
            $context = wantarray ? "list" :
                defined wantarray ? "scalar" : "void";
        }
        catch ($e) { }
    }

    whatcontext();
    is($context, "void", 'sub {try} in void');

    my $scalar = whatcontext();
    is($context, "scalar", 'sub {try} in scalar');

    my @array = whatcontext();
    is($context, "list", 'sub {try} in list');
}

# Loop controls inside try {} do not emit warnings
{
    my $warnings = "";
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };

    {
        try {
            last;
        }
        catch ($e) { }
    }

    {
        try {
            next;
        }
        catch ($e) { }
    }

    my $count = 0;
    {
        try {
            $count++;
            redo if $count < 2;
        }
        catch ($e) { }
    }

    is($warnings, "", 'No warnings emitted by next/last/redo inside try');

    $warnings = "";

    LOOP_L: {
        try {
            last LOOP_L;
        }
        catch ($e) { }
    }

    LOOP_N: {
        try {
            next LOOP_N;
        }
        catch ($e) { }
    }

    $count = 0;
    LOOP_R: {
        try {
            $count++;
            redo LOOP_R if $count < 2;
        }
        catch ($e) { }
    }

    is($warnings, "", 'No warnings emitted by next/last/redo LABEL inside try');
}

# try/catch should localise $@
{
    eval { die "Value before\n"; };

    try { die "Localized value\n" } catch ($e) {}

    is($@, "Value before\n", 'try/catch localized $@');
}

# try/catch is not confused by false values
{
    my $caught;
    try {
        die 0;
    }
    catch ($e) {
        $caught++;
    }

    ok( $caught, 'catch{} sees a false exception' );
}

# try/catch is not confused by always-false objects
{
    my $caught;
    try {
        die FALSE->new;
    }
    catch ($e) {
        $caught++;
    }

    ok( $caught, 'catch{} sees a false-overload exception object' );

    {
        package FALSE;
        use overload 'bool' => sub { 0 };
        sub new { bless [], shift }
    }
}

# return from try is correct even for :lvalue subs
#   https://github.com/Perl/perl5/issues/18553
{
    my $scalar;
    sub fscalar :lvalue
    {
        try { return $scalar }
        catch ($e) { }
    }

    fscalar = 123;
    is($scalar, 123, 'try { return } in :lvalue sub in scalar context' );

    my @array;
    sub flist :lvalue
    {
        try { return @array }
        catch ($e) { }
    }

    (flist) = (4, 5, 6);
    ok(eq_array(\@array, [4, 5, 6]), 'try { return } in :lvalue sub in list context' );
}

# try as final expression yields correct value
{
    my $scalar = do {
        try { 123 }
        catch ($e) { 456 }
    };
    is($scalar, 123, 'do { try } in scalar context');

    my @list = do {
        try { 1, 2, 3 }
        catch ($e) { 4, 5, 6 }
    };
    ok(eq_array(\@list, [1, 2, 3]), 'do { try } in list context');

    # Regression test related to
    #   https://github.com/Perl/perl5/issues/18855
    $scalar = do {
        try { my $x = 123; 456 }
        catch ($e) { 789 }
    };
    is($scalar, 456, 'do { try } with multiple statements');
}

# catch as final expression yields correct value
{
    my $scalar = do {
        try { die "Oops" }
        catch ($e) { 456 }
    };
    is($scalar, 456, 'do { try/catch } in scalar context');

    my @list = do {
        try { die "Oops" }
        catch ($e) { 4, 5, 6 }
    };
    ok(eq_array(\@list, [4, 5, 6]), 'do { try/catch } in list context');

    # Regression test 
    #   https://github.com/Perl/perl5/issues/18855
    $scalar = do {
        try { die "Oops" }
        catch ($e) { my $x = 123; "result" }
    };
    is($scalar, "result", 'do { try/catch } with multiple statements');
}

# try{} blocks should be invisible to caller()
{
    my $caller;
    sub A { $caller = sprintf "%s (%s line %d)", (caller 1)[3,1,2]; }

    sub B {
        try { A(); }
        catch ($e) {}
    }

    my $LINE = __LINE__+1;
    B();

    is($caller, "main::B ($0 line $LINE)", 'try {} block is invisible to caller()');
}

# try/catch/finally
{
    my $x;
    try {
        $x .= "try";
    }
    catch ($e) {
        $x .= "catch";
    }
    finally {
        $x .= "finally";
    }
    is($x, "tryfinally", 'successful try/catch/finally runs try+finally but not catch');
}

{
    my $x;
    try {
        $x .= "try";
        die "Oopsie\n";
    }
    catch ($e) {
        $x .= "catch";
    }
    finally {
        $x .= "finally";
    }
    is($x, "trycatchfinally", 'try/catch/finally runs try+catch+finally on failure');
}

{
    my $finally_invoked;
    sub ff
    {
        try {
            return "return inside try+finally";
        }
        catch ($e) {}
        finally { $finally_invoked++; "last value" }
        return "return from func";
    }
    is(ff(), "return inside try+finally", 'return inside try+finally');
    ok($finally_invoked, 'finally block still invoked for side-effects');
}

# Complaints about forbidden control flow talk about "finally" blocks, not "defer"
{
    my $e;

    $e = defined eval {
        try {} catch ($e) {} finally { return "123" }
        1;
    } ? undef : $@;
    like($e, qr/^Can't "return" out of a "finally" block /,
        'Cannot return out of finally block');

    $e = defined eval {
        try {} catch ($e) {} finally { goto HERE; }
        HERE: 1;
    } ? undef : $@;
    like($e, qr/^Can't "goto" out of a "finally" block /,
        'Cannot goto out of finally block');

    $e = defined eval {
        LOOP: { try {} catch ($e) {} finally { last LOOP; } }
        1;
    } ? undef : $@;
    like($e, qr/^Can't "last" out of a "finally" block /,
        'Cannot last out of finally block');
}

# Nicer compiletime errors
{
    my $e;

    $e = defined eval 'try { A() } catch { B() }; 1;' ? undef : $@;
    like($e, qr/^catch block requires a \(VAR\) at /,
        'Parse error for catch without (VAR)');
}

done_testing;
