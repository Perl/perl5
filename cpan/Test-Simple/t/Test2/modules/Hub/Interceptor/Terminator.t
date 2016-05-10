use strict;
use warnings;
BEGIN { require "t/tools.pl" };

use Test2::Hub::Interceptor::Terminator;

ok($INC{'Test2/Hub/Interceptor/Terminator.pm'}, "loaded");

done_testing;
