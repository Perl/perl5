#!./perl

use strict;
use warnings;

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use Test::More tests => 29;

use_ok('Tie::StdHandle');

{
    no warnings 'once';
    tie *tst, 'Tie::StdHandle';
}

our $f = 'tst';

unlink("afile") if -f "afile";

{
    no strict 'refs';
    ok(open($f, "+>", "afile"), "open +>, afile");
    ok(open($f, "+<", "afile"), "open +<, afile");
    ok(binmode($f), "binmode")
        or diag("binmode: $!\n");

    ok(-f "afile", "-f afile");

    # write some lines

    ok(print($f "SomeData\n"), "print SomeData");    # line 1
    is(tell($f), 9, "tell");
    ok(printf($f "Some %d value\n",1234), "printf"); # line 2
    ok(print($f "ABCDEF\n"), "print ABCDEF");        # line 3
    {
        local $\ = "X\n";
        ok(print($f "rhubarb"), "print rhubarb");    # line 4
    }

    ok(syswrite($f, "123456789\n", 3, 7), "syswrite");# line 5

    # read some lines back

    ok(seek($f,0,0), "seek");

    # line 1
    #
    my $beta = <$f>;
    is($beta, "SomeData\n", "b eq SomeData");
    ok(!eof($f), "!eof");

    #line 2

    is(read($f,($beta=''),4), 4, "read(4)");
    is($beta, 'Some', "b eq Some");
    is(getc($f), ' ', "getc");
    $beta = <$f>;
    is($beta, "1234 value\n", "b eq 1234 value");
    ok(!eof($f), "eof");

    # line 3

    is(read($f,($beta='scrinches'),4,4), 4, "read(4,4)"); # with offset
    is($beta, 'scriABCD', "b eq scriABCD");
    $beta = <$f>;
    is($beta, "EF\n", "EF");
    ok(!eof($f), "eof");

    # line 4

    $beta = <$f>;
    is($beta, "rhubarbX\n", "b eq rhubarbX");

    # line 5

    $beta = <$f>;
    is($beta, "89\n", "b eq 89");

    # binmode should pass through layer argument

    binmode $f, ':raw';
    ok !grep( $_ eq 'utf8', PerlIO::get_layers(tied(*$f)) ),
        'no utf8 in layers after binmode :raw';
    binmode $f, ':utf8';
    ok grep( $_ eq 'utf8', PerlIO::get_layers(tied(*$f)) ),
        'utf8 is in layers after binmode :utf8';

    # finish up

    ok(eof($f), "eof");
    ok(close($f), "close");
}

unlink("afile");
