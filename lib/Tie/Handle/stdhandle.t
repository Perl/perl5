#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use Test::More tests => 19;

use_ok('Tie::StdHandle');

tie *tst,Tie::StdHandle;

$f = 'tst';

unlink("afile.new") if -f "afile";

ok(open($f,"+>afile"), "open +>afile");
ok(open($f, "+<", "afile"), "open +<, afile");
ok(binmode($f), "binmode")
    or diag("binmode: $!\n");

ok(-f "afile", "-f afile");

ok(print($f "SomeData\n"), "print");
is(tell($f), 9, "tell");
ok(printf($f "Some %d value\n",1234), "printf");
ok(seek($f,0,0), "seek");

$b = <$f>;
is($b, "SomeData\n", "b eq SomeData");
ok(!eof($f), "!eof");

is(read($f,($b=''),4), 4, "read(4)");
is($b, 'Some', "b eq Some");
is(getc($f), ' ', "getc");

$b = <$f>;
ok(eof($f), "eof");
ok(seek($f,0,0), "seek");
is(read($f,($b='scrinches'),4,4), 4, "read(4,4)"); # with offset
is($b, 'scriSome', "b eq scriSome");

ok(close($f), "close");

unlink("afile");
