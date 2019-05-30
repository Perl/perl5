#!./perl

BEGIN {
        require Config;
        if (($Config::Config{'extensions'} !~ /\bre\b/) ){
                print "1..0 # Skip -- Perl configured without re module\n";
                exit 0;
        }
}

use strict;

use Test::More;
BEGIN { require_ok( 're' ); }

{
    my $re = qr/(?:a(?:b|\d)*)*/;
    my $x = "abbb" x 2000 . "c";
    use re 'limit';
    local ${^RE_MEMORY_LIMIT} = 200;
    ok(!eval { $x =~ $re; 1 }, "exceed memory limit");
    local ${^RE_MEMORY_LIMIT} = 5000;
    ok(eval { $x =~ $re; 1 }, "within memory limit");
    local ${^RE_MEMORY_LIMIT} = undef;
    ok(eval { $x =~ $re; 1 }, "no memory limit");
    no re 'limit';
    local ${^RE_MEMORY_LIMIT} = 200;
    ok(eval { $x =~ $re; 1 }, "memory limit not enforced");
}

{
    my $re = qr/[ac]*[ae]*[df]/;
    my $x = "a" x 200 . "b";
    use re 'limit';
    local ${^RE_CPU_LIMIT} = 1_000_000;
    ok(!eval { $x =~ $re; 1 }, "exceed cpu limit");
    local ${^RE_CPU_LIMIT} = 20_000_000;
    ok(eval { $x =~ $re; 1 }, "within cpu limit");
    local ${^RE_CPU_LIMIT} = undef;
    ok(eval { $x =~ $re; 1 }, "no cpu limit");
    no re 'limit';
    local ${^RE_CPU_LIMIT} = 200;
    ok(eval { $x =~ $re; 1 }, "cpu limit not enforced");
}

done_testing();
