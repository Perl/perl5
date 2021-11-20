#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}

use strict;
use warnings;

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
