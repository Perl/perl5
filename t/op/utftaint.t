#!./perl -T
# tests whether tainting works with UTF-8

BEGIN {
    if ($ENV{PERL_CORE_MINITEST}) {
        print "1..0 # Skip: no dynamic loading on miniperl, no threads\n";
        exit 0;
    }
    chdir 't' if -d 't';
    @INC = qw(../lib);
}

use strict;
use Config;

BEGIN {
    if ($Config{extensions} !~ m(\bList/Util\b)) {
        print "1..0 # Skip: no Scalar::Util module\n";
        exit 0;
    }
}

use Scalar::Util qw(tainted);

use Test;
plan tests => 3*10;
my $cnt = 0;

my $arg = $ENV{PATH}; # a tainted value
use constant UTF8 => "\x{1234}";

for my $ary ([ascii => 'perl'], [latin1 => "\xB6"], [utf8 => "\x{100}"]) {
    my $encode = $ary->[0];
    my $string = $ary->[1];

    my $taint = $arg; substr($taint, 0) = $ary->[1];

    print tainted($taint) == tainted($arg)
	? "ok " : "not ok ", ++$cnt, " # tainted: $encode, before test\n";

    my $lconcat = $taint;
       $lconcat .= UTF8;
    print $lconcat eq $string."\x{1234}"
	? "ok " : "not ok ", ++$cnt, " # compare: $encode, concat left\n";

    print tainted($lconcat) == tainted($arg)
	? "ok " : "not ok ", ++$cnt, " # tainted: $encode, concat left\n";

    my $rconcat = UTF8;
       $rconcat .= $taint;
    print $rconcat eq "\x{1234}".$string
	? "ok " : "not ok ", ++$cnt, " # compare: $encode, concat right\n";

    print tainted($rconcat) == tainted($arg)
	? "ok " : "not ok ", ++$cnt, " # tainted: $encode, concat right\n";

    my $ljoin = join('!', $taint, UTF8);
    print $ljoin eq join('!', $string, UTF8)
	? "ok " : "not ok ", ++$cnt, " # compare: $encode, join left\n";

    print tainted($ljoin) == tainted($arg)
	? "ok " : "not ok ", ++$cnt, " # tainted: $encode, join left\n";

    my $rjoin = join('!', UTF8, $taint);
    print $rjoin eq join('!', UTF8, $string)
	? "ok " : "not ok ", ++$cnt, " # compare: $encode, join right\n";

    print tainted($rjoin) == tainted($arg)
	? "ok " : "not ok ", ++$cnt, " # tainted: $encode, join right\n";

    print tainted($taint) == tainted($arg)
	? "ok " : "not ok ", ++$cnt, " # tainted: $encode, after test\n";
}
