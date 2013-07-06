use Config;
use Test::More;
BEGIN { plan skip_all => 'no threads' unless $Config{useithreads} }

plan tests => 2;

use XS::APItest;

ok test_alloccopstash;
ok test_allocfilegv;
