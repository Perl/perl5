# no 'use warnings;' here so the first block sees defaults
use strict;
use Test::More tests => 6;

use XS::APItest;

{
    local $^W = 0;
    XS::APItest::test_cop_warnings(0);
    ok 1, "standard warnings with \$^W = 0";
}

{
    local $^W = 1;
    XS::APItest::test_cop_warnings(1);
    ok 2, "standard warnings with \$^W = 1";
}

{
    use warnings;
    XS::APItest::test_cop_warnings(1);
    ok 3, "'use warnings'";
}

{
    no warnings;
    XS::APItest::test_cop_warnings(0);
    ok 4, "'no warnings'";
}
{
    no warnings;
    use warnings qw( once );
    XS::APItest::test_cop_warnings(0);
    ok 5, "'no warnings' + other";
}

{
    no warnings;
    use warnings qw( uninitialized );
    XS::APItest::test_cop_warnings(1);
    ok 6, "'use warnings uninitialized'";
}

1;
