use encoding 'euc-jp';
use Test::More tests => 1;

my @a;

while (<DATA>) {
  chomp;
  tr/ぁ-んァ-ン/ァ-ンぁ-ん/;
  push @a, $_;
}

SKIP: {
  skip("pre-5.8.1 does not do utf8 DATA", 1) if $] < 5.008001;
  ok(@a == 3 &&
     $a[0] eq "コレハDATAふぁいるはんどるノてすとデス。" &&
     $a[1] eq "日本語ガチャント変換デキルカ" &&
     $a[2] eq "ドウカノてすとヲシテイマス。",
     "utf8 (euc-jp) DATA")
}

__DATA__
これはDATAファイルハンドルのテストです。
日本語がちゃんと変換できるか
どうかのテストをしています。
