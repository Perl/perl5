#!../perl

BEGIN {
    if ($ENV{'PERL_CORE'}){
	chdir 't';
	unshift @INC, '../lib';
    }
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bEncode\b/) {
	print "1..0 # Skip: Encode was not built\n";
	    exit 0;
    }
}

use strict;
use Encode;
use Encode::Alias;
my %a2c;
my $ON_EBCDIC;

BEGIN{
    $ON_EBCDIC = ord("A") == 193;
    @ARGV and $ON_EBCDIC = $ARGV[0] eq 'EBCDIC';
    $Encode::ON_EBCDIC = $ON_EBCDIC;

    %a2c = (
	    'ascii'    => 'US-ascii',
	    'cyrillic' => 'iso-8859-5',
	    'arabic'   => 'iso-8859-6',
	    'greek'    => 'iso-8859-7',
	    'hebrew'   => 'iso-8859-8',
	    'thai'     => 'iso-8859-11',
	    'tis620'   => 'iso-8859-11',
	    'WinLatin1'     => 'cp1252',
	    'WinLatin2'     => 'cp1250',
	    'WinCyrillic'   => 'cp1251',
	    'WinGreek'      => 'cp1253',
	    'WinTurkish'    => 'cp1254',
	    'WinHebrew'     => 'cp1255',
	    'WinArabic'     => 'cp1256',
	    'WinBaltic'     => 'cp1257',
	    'WinVietnamese' => 'cp1258',
	    'ja_JP.euc'	    => $ON_EBCDIC ? '' : 'euc-jp',
	    'x-euc-jp'	    => $ON_EBCDIC ? '' : 'euc-jp',
	    'zh_CN.euc'	    => $ON_EBCDIC ? '' : 'euc-cn',
	    'x-euc-cn'	    => $ON_EBCDIC ? '' : 'euc-cn',
	    'ko_KR.euc'	    => $ON_EBCDIC ? '' : 'euc-kr',
	    'x-euc-kr'	    => $ON_EBCDIC ? '' : 'euc-kr',
	    'ujis'	    => $ON_EBCDIC ? '' : 'euc-jp',
	    'Shift_JIS'	    => $ON_EBCDIC ? '' : 'shiftjis',
	    'x-sjis'	    => $ON_EBCDIC ? '' : 'shiftjis',
	    'jis'	    => $ON_EBCDIC ? '' : '7bit-jis',
	    'big-5'	    => $ON_EBCDIC ? '' : 'big5',
	    'zh_TW.Big5'    => $ON_EBCDIC ? '' : 'big5',
	    'big5-hk'	    => $ON_EBCDIC ? '' : 'big5-hkscs',
	    'GB_2312-80'    => $ON_EBCDIC ? '' : 'euc-cn',
	    'gb2312-raw'    => $ON_EBCDIC ? '' : 'gb2312-raw',
	    'gb12345-raw'   => $ON_EBCDIC ? '' : 'gb12345-raw',
	    'KS_C_5601-1987'    => $ON_EBCDIC ? '' : 'cp949',
	    'ksc5601-raw'       => $ON_EBCDIC ? '' : 'ksc5601-raw',
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
	$a2c{"IBM-$v"} = $a2c{"MS-$v"} = "cp" . $v;
    }
}

if ($ON_EBCDIC){
    delete @Encode::ExtModule{
	qw(euc-cn gb2312 gb12345 gbk cp936 iso-ir-165
	   euc-jp iso-2022-jp 7bit-jis shiftjis MacJapanese cp932
	   euc-kr ksc5601 cp949
	   big5	big5-hkscs cp950
	   gb18030 big5plus euc-tw)
	};
}

use Test::More tests => (scalar keys %a2c) * 3;

print "# alias test;  \$ON_EBCDIC == $ON_EBCDIC\n";

foreach my $a (keys %a2c){	     
    my $e = Encode::find_encoding($a);
    is((defined($e) and $e->name), $a2c{$a});
}

# now we override some of the aliases and see if it works fine

define_alias(ascii    => 'WinLatin1',
	     cyrillic => 'WinCyrillic',
	     arabic   => 'WinArabic',
	     greek    => 'WinGreek',
	     hebrew   => 'WinHebrew');

@a2c{qw(ascii cyrillic arabic greek hebrew)} =
    qw(cp1252 cp1251 cp1256 cp1253 cp1255);

unless ($ON_EBCDIC){
    define_alias( qr/shift.*jis$/i  => '"MacJapanese"',
		  qr/sjis$/i        => '"cp932"' );
    @a2c{qw(Shift_JIS x-sjis)} = qw(MacJapanese cp932);
}

print "# alias test with alias overrides\n";

foreach my $a (keys %a2c){	     
    my $e = Encode::find_encoding($a);
    is((defined($e) and $e->name), $a2c{$a})
	or warn "alias was $a";
}

print "# alias undef test\n";

Encode::Alias->undef_aliases;
foreach my $a (keys %a2c){	     
    my $e = Encode::find_encoding($a);
    ok(!defined($e) || $e->name =~ /-raw$/o);
}

__END__
for (my $i = 0; $i < @Encode::Alias::Alias; $i+=2){
    my ($k, $v) = @Encode::Alias::Alias[$i, $i+1];
    print "$k => $v\n";
}


