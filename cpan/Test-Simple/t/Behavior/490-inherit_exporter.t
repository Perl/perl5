use strict;
use warnings;


BEGIN {
    $INC{'My/Tester.pm'} = __FILE__;
    package My::Tester;
    use Test::More;
    use base 'Test::More';

    our @EXPORT    = (@Test::More::EXPORT, qw/foo/);
    our @EXPORT_OK = (@Test::More::EXPORT_OK);

    sub foo { goto &Test::More::ok }

    1;
}

use My::Tester;

can_ok(__PACKAGE__, qw/ok done_testing foo/);

foo(1, "This is just an ok");

done_testing;
