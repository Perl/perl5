#!../perl

use strict;
use Encode::CN;
use Encode::JP;
use Encode::KR;
use Encode::TW;

my %a2c;

BEGIN {
	%a2c = (
		'ascii'    => 'US-ascii',
		'cyrillic' => 'iso-8859-5',
		'arabic'   => 'iso-8859-6',
		'greek'    => 'iso-8859-7',
		'hebrew'   => 'iso-8859-8',
		'thai'     => 'iso-8859-11',
		'tis620'   => 'iso-8859-11',
		'ja_JP.euc'	=> 'euc-jp',
		'x-euc-jp'	=> 'euc-jp',
		'zh_CN.euc'	=> 'euc-cn',
		'x-euc-cn'	=> 'euc-cn',
		'ko_KR.euc'	=> 'euc-kr',
		'x-euc-kr'	=> 'euc-kr',
		'ujis'		=> 'euc-jp',
		'Shift_JIS'	=> 'shiftjis',
		'x-sjis'	=> 'shiftjis',
		'jis'		=> '7bit-jis',
		'big-5'		=> 'big5',
		'zh_TW.Big5'	=> 'big5',
		'big5-hk'	=> 'big5-hkscs',
		'WinLatin1'     => 'cp1252',
		'WinLatin2'     => 'cp1250',
		'WinCyrillic'   => 'cp1251',
		'WinGreek'      => 'cp1253',
		'WinTurkish'    => 'cp1254',
		'WinHebrew'     => 'cp1255',
		'WinArabic'     => 'cp1256',
		'WinBaltic'     => 'cp1257',
		'WinVietnamese' => 'cp1258',
		);

	for my $i (1..11,13..16){
	    $a2c{"ISO 8859 $i"} = "iso-8859-$i";
	}
	for my $i (1..10){
	    $a2c{"ISO Latin $i"} = "iso-8859-$Encode::Alias::Latin2iso[$i]";
	}
	for my $k (keys %Encode::Alias::Winlatin2cp){
	    my $v = $Encode::Alias::Winlatin2cp{$k};
	    $a2c{"Win" . ucfirst($k)} = "cp" . $v;
	    $a2c{"IBM-$v"} = "cp" . $v;
	    $a2c{"MS-$v"} = "cp" . $v;
	}
}

use Test::More tests => (scalar keys %a2c) * 2;

print "# alias test\n";

foreach my $a (keys %a2c){	     
    my $e = Encode::find_encoding($a);
    is((defined($e) and $e->name), $a2c{$a});
}

# now we override some of the aliases and see if it works fine

Encode::define_alias( qr/shift.*jis$/i  => '"macjapan"' );
Encode::define_alias( qr/sjis$/i        => '"cp932"' );

@a2c{qw(Shift_JIS x-sjis)} = qw(macjapan cp932);

print "# alias test with alias overrides\n";

foreach my $a (keys %a2c){	     
    my $e = Encode::find_encoding($a);
    is((defined($e) and $e->name), $a2c{$a});
}

__END__
for (my $i = 0; $i < @Encode::Alias::Alias; $i+=2){
    my ($k, $v) = @Encode::Alias::Alias[$i, $i+1];
    print "$k => $v\n";
}


