use strict;
use warnings;
BEGIN { require "t/tools.pl" };

use Test2::Hub::Interceptor;

my $one = Test2::Hub::Interceptor->new();

ok($one->isa('Test2::Hub'), "inheritence");;

my $e = exception { $one->terminate(55) };
ok($e->isa('Test2::Hub::Interceptor::Terminator'), "exception type");
is($$e, 55, "Scalar reference value");

done_testing;
