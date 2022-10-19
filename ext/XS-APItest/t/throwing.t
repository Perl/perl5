#!perl

use v5.36;

# Test::More doesn't have fresh_perl_is() yet

BEGIN {
    require '../../t/test.pl';
};

use XS::APItest;

package RunOnDestruct {
    sub DESTROY { $_[0]->[0]->() }
}
sub run_on_destruct :prototype(&) {
    return bless [@_], "RunOnDestruct";
}

# PL_throwing quiescently
{
    my $throwing = XS::APItest::PL_throwing;
    ok(defined $throwing, 'PL_throwing is defined initially');
    ok(!$throwing,        'PL_throwing is false initially');
}

# PL_throwing during normal leave
{
    my $var;
    {
        my $guard = run_on_destruct { $var = 0 + XS::APItest::PL_throwing };
    }
    is($var, 0, 'var is false after normal scope leave');
}

# PL_throwing during normal eval leave
{
    my $var;
    eval {
        my $guard = run_on_destruct { $var = 0 + XS::APItest::PL_throwing };
    };
    is($var, 0, 'var is false after normal eval leave');
    ok(!XS::APItest::PL_throwing, 'PL_throwing false after eval returned');
}

# PL_throwing during exceptional eval leave
{
    my $var;
    eval {
        my $guard = run_on_destruct { $var = 0 + XS::APItest::PL_throwing };
        die "Oopsie";
    }; # ignore the error
    is($var, 1, 'var is true after die in eval');
    ok(!XS::APItest::PL_throwing, 'PL_throwing false after eval returned');
}

# PL_throwing during string-eval()
{
    my $var;
    eval q(
        my $guard = run_on_destruct { $var = 0 + XS::APItest::PL_throwing };
        die "Oopsie";
    ); # ignore the error
    is($var, 1, 'var is true after die in string-eval');
    ok(!XS::APItest::PL_throwing, 'PL_throwing false after string-eval returned');
}

# It's (probably) not possible to observe PL_throwing=true during a BEGIN,
# CHECK or INIT phaser, but we can test END
fresh_perl_is(
    <<'EOF',
use strict;
use XS::APItest;
END { printf "PL_throwing=%s\n", XS::APItest::PL_throwing ? "true" : "false" }
die "Oopsie\n";
EOF
    "Oopsie\nPL_throwing=true",
    { stderr => 1 },
    'PL_throwing during END block');

# PL_throwing during normal defer
{
    use experimental 'defer';

    my $var;
    eval {
        defer { $var = 0 + XS::APItest::PL_throwing; }
    };
    is($var, 0, 'var is true during normal defer');
    ok(!XS::APItest::PL_throwing, 'PL_throwing false after eval');
}

# PL_throwing during exceptional defer
{
    use experimental 'defer';

    my $var;
    eval {
        defer { $var = 0 + XS::APItest::PL_throwing; }
        die "Oopsie";
    }; # ignore the error
    is($var, 1, 'var is true during exceptional defer');
    ok(!XS::APItest::PL_throwing, 'PL_throwing false after eval');
}

# PL_throwing at top-level defer
fresh_perl_is(
    <<'EOF',
use strict;
use experimental 'defer';
use XS::APItest;
defer { printf "PL_throwing=%s\n", XS::APItest::PL_throwing ? "true" : "false" }
die "Oopsie\n";
EOF
    "Oopsie\nPL_throwing=true",
    { stderr => 1 },
    'PL_throwing during toplevel defer {}');

# PL_throwing during caught finally
{
    use experimental 'try';

    my $var;
    eval {
        try {
            die "Oopsie";
        }
        catch ($e) {
            # ignore it
        }
        finally {
            $var = 0 + XS::APItest::PL_throwing;
        }
    };
    is($var, 0, 'var is caught during caught finally');
    ok(!XS::APItest::PL_throwing, 'PL_throwing false after eval');
}

# PL_throwing during throwing finally
{
    use experimental 'try';

    my $var;
    eval {
        try {
            die "Oopsie";
        }
        catch ($e) {
            die $e; # rethrow
        }
        finally {
            $var = 0 + XS::APItest::PL_throwing;
        }
    }; # ignore the error
    is($var, 1, 'var is true during throwing finally');
    ok(!XS::APItest::PL_throwing, 'PL_throwing false after eval');
}

done_testing;
