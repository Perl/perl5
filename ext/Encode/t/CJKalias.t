use strict;
#use Test::More tests => 27;
use Test::More qw(no_plan);
use Encode::CN;
use Encode::JP;
use Encode::KR;
use Encode::TW;

print "# alias test\n";

my %a2c = qw(
	     ja_JP.euc	euc-jp
	     x-euc-jp   euc-jp
	     zh_CN.euc	euc-cn
	     x-euc-cn   euc-cn
	     ko_KR.euc	euc-kr
	     x-euc-kr   euc-kr
	     ujis       euc-jp
	     Shift_JIS  shiftjis
	     x-sjis     shiftjis
	     jis        7bit-jis
	     );

foreach my $a (keys %a2c){	     
    my $e = Encode::find_encoding($a);
    my $n =  $e->name || $e->{name};
    is($n, $a2c{$a});
}

