use strict;
use Encode::CN;
use Encode::JP;
use Encode::KR;
use Encode::TW;

print "# alias test\n";

my %a2c;

BEGIN {
	%a2c = qw(
		  ja_JP.euc	euc-jp
		  x-euc-jp	euc-jp
		  zh_CN.euc	euc-cn
		  x-euc-cn	euc-cn
		  ko_KR.euc	euc-kr
		  x-euc-kr	euc-kr
		  ujis		euc-jp
		  Shift_JIS	shiftjis
		  x-sjis	shiftjis
		  jis		7bit-jis
		  big-5		big5
		  zh_TW.Big5	big5
		  big5-hk	big5-hkscs
		  );
}

use Test::More tests => scalar keys %a2c;

foreach my $a (keys %a2c){	     
    my $e = Encode::find_encoding($a);
    is($e->name, $a2c{$a});
}

