#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}

use strict;
use warnings;

package FetchStoreCounter {
    sub new { my $class = shift; return bless [@_], $class }
    sub TIESCALAR { return shift->new(@_) }
    sub FETCH { ${shift->[0]}++ }
    sub STORE { ${shift->[1]}++ }
}

# booleans
{
    use builtin qw( true false isbool );

    ok(true, 'true is true');
    ok(!false, 'false is false');

    ok(isbool(true), 'true is bool');
    ok(isbool(false), 'false is bool');
    ok(!isbool(undef), 'undef is not bool');
    ok(!isbool(1), '1 is not bool');
    ok(!isbool(""), 'empty is not bool');

    my $truevar  = (5 == 5);
    my $falsevar = (5 == 6);

    ok(isbool($truevar), '$truevar is bool');
    ok(isbool($falsevar), '$falsevar is bool');

    ok(isbool(isbool(true)), 'isbool true is bool');
    ok(isbool(isbool(123)),  'isbool false is bool');

    # Invokes magic

    tie my $tied, FetchStoreCounter => (\my $fetchcount, \my $storecount);

    my $_dummy = isbool($tied);
    is($fetchcount, 1, 'isbool() invokes FETCH magic');

    $tied = isbool(false);
    is($storecount, 1, 'isbool() TARG invokes STORE magic');
}

# weakrefs
{
    use builtin qw( isweak weaken unweaken );

    my $arr = [];
    my $ref = $arr;

    ok(!isweak($ref), 'ref is not weak initially');

    weaken($ref);
    ok(isweak($ref), 'ref is weak after weaken()');

    unweaken($ref);
    ok(!isweak($ref), 'ref is not weak after unweaken()');

    weaken($ref);
    undef $arr;
    ok(!defined $ref, 'ref is now undef after arr is cleared');
}

# reference queries
{
    use builtin qw( refaddr reftype blessed );

    my $arr = [];
    my $obj = bless [], "Object";

    is(refaddr($arr), $arr+0, 'refaddr yields same as ref in numeric context');
    ok(!defined refaddr("not a ref"), 'refaddr yields undef for non-reference');

    is(reftype($arr), "ARRAY", 'reftype yields type string');
    is(reftype($obj), "ARRAY", 'reftype yields basic container type for blessed object');
    ok(!defined reftype("not a ref"), 'reftype yields undef for non-reference');

    is(blessed($arr), undef, 'blessed yields undef for non-object');
    is(blessed($obj), "Object", 'blessed yields package name for object');
}

# imports are lexical; should not be visible here
{
    my $ok = eval 'true()'; my $e = $@;
    ok(!$ok, 'true() not visible outside of lexical scope');
    like($e, qr/^Undefined subroutine &main::true called at /, 'failure from true() not visible');
}

# lexical imports work fine in a variety of situations
{
    sub regularfunc {
        use builtin 'true';
        return true;
    }
    ok(regularfunc(), 'true in regular sub');

    my sub lexicalfunc {
        use builtin 'true';
        return true;
    }
    ok(lexicalfunc(), 'true in lexical sub');

    my $coderef = sub {
        use builtin 'true';
        return true;
    };
    ok($coderef->(), 'true in anon sub');

    sub recursefunc {
        use builtin 'true';
        return recursefunc() if @_;
        return true;
    }
    ok(recursefunc("rec"), 'true in self-recursive sub');

    my $recursecoderef = sub {
        use feature 'current_sub';
        use builtin 'true';
        return __SUB__->() if @_;
        return true;
    };
    ok($recursecoderef->("rec"), 'true in self-recursive anon sub');
}

done_testing();
