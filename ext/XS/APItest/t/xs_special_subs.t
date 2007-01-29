BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    push @INC, "::lib:$MacPerl::Architecture:" if $^O eq 'MacOS';
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bXS\/APItest\b/) {
        print "1..0 # Skip: XS::APItest was not built\n";
        exit 0;
    }
}

use strict;
use warnings;
use Test::More tests => 40;

# Doing this longhand cut&paste makes it clear
# BEGIN and INIT are FIFO, CHECK and END are LIFO
BEGIN {
    is($XS::APItest::BEGIN_called, undef, "BEGIN not yet called");
    is($XS::APItest::CHECK_called, undef, "CHECK not yet called");
    is($XS::APItest::INIT_called, undef, "INIT not yet called");
    is($XS::APItest::END_called, undef, "END not yet called");
}

CHECK {
    is($XS::APItest::BEGIN_called, 1, "BEGIN called");
    is($XS::APItest::CHECK_called, 1, "CHECK called");
    is($XS::APItest::INIT_called, undef, "INIT not yet called");
    is($XS::APItest::END_called, undef, "END not yet called");
}

INIT {
    is($XS::APItest::BEGIN_called, 1, "BEGIN called");
    is($XS::APItest::CHECK_called, 1, "CHECK called");
    is($XS::APItest::INIT_called, undef, "INIT not yet called");
    is($XS::APItest::END_called, undef, "END not yet called");
}

END {
    is($XS::APItest::BEGIN_called, 1, "BEGIN called");
    is($XS::APItest::CHECK_called, 1, "CHECK called");
    is($XS::APItest::INIT_called, 1, "INIT called");
    is($XS::APItest::END_called, 1, "END called");
}

is($XS::APItest::BEGIN_called, 1, "BEGIN called");
is($XS::APItest::CHECK_called, 1, "CHECK called");
is($XS::APItest::INIT_called, 1, "INIT called");
is($XS::APItest::END_called, undef, "END not yet called");

use XS::APItest;

is($XS::APItest::BEGIN_called, 1, "BEGIN called");
is($XS::APItest::CHECK_called, 1, "CHECK called");
is($XS::APItest::INIT_called, 1, "INIT called");
is($XS::APItest::END_called, undef, "END not yet called");

BEGIN {
    is($XS::APItest::BEGIN_called, 1, "BEGIN called");
    is($XS::APItest::CHECK_called, undef, "CHECK not yet called");
    is($XS::APItest::INIT_called, undef, "INIT not yet called");
    is($XS::APItest::END_called, undef, "END not yet called");
}

CHECK {
    is($XS::APItest::BEGIN_called, 1, "BEGIN called");
    is($XS::APItest::CHECK_called, undef, "CHECK not yet called");
    is($XS::APItest::INIT_called, undef, "INIT not yet called");
    is($XS::APItest::END_called, undef, "END not yet called");
}

INIT {
    is($XS::APItest::BEGIN_called, 1, "BEGIN called");
    is($XS::APItest::CHECK_called, 1, "CHECK called");
    is($XS::APItest::INIT_called, 1, "INIT called");
    is($XS::APItest::END_called, undef, "END not yet called");
}

END {
    is($XS::APItest::BEGIN_called, 1, "BEGIN called");
    is($XS::APItest::CHECK_called, 1, "CHECK called");
    is($XS::APItest::INIT_called, 1, "INIT called");
    is($XS::APItest::END_called, undef, "END not yet called");
}
