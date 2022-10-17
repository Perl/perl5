#!perl

use v5.36;

use Test::More;
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
