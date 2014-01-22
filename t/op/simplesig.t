#!perl

BEGIN {
    chdir 't';
    @INC = '../lib';
    require './test.pl';
}
plan 90;

eval "#line 8 foo\nsub foo (\$) (\$a) { }";
is $@, "Experimental subroutine signatures not enabled at foo line 8.\n",
    "error when not enabled";

no warnings "illegalproto";
our $a = 123;
sub aaa ($a) { $a || "z" }
is prototype(\&aaa), "\$a", "(\$a) interpreted as protoype when not enabled";
is &aaa(456), 123, "(\$a) not signature when not enabled";
is $a, 123;

no warnings "experimental::simple_signatures";
use feature "simple_signatures";

sub bbb { $a || "z" }
is prototype(\&bbb), undef;
is &bbb(), 123;
is eval("bbb()"), 123;
is eval("bbb(456)"), 123;
is eval("bbb(456, 789)"), 123;
is $a, 123;

sub ccc () { $a || "z" }
is prototype(\&ccc), "";
is &ccc(), 123;
is eval("ccc()"), 123;
is eval("ccc(456)"), undef;
is eval("ccc(456, 789)"), undef;
is $a, 123;

sub ddd ($) { $a || "z" }
is prototype(\&ddd), "\$";
is &ddd(), 123;
is eval("ddd()"), undef;
is eval("ddd(456)"), 123;
is eval("ddd(456, 789)"), undef;
is $a, 123;

sub eee ($$) { $a || "z" }
is prototype(\&eee), "\$\$";
is &eee(), 123;
is &eee(456), 123;
is &eee(456,789), 123;
is eval("eee()"), undef;
is eval("eee(456)"), undef;
is eval("eee(456, 789)"), 123;
is $a, 123;

sub fff ( ) { $a || "z" }
is prototype(\&fff), undef;
is &fff(), 123;
is &fff(456), 123;
is &fff(456, 789), 123;
is eval("fff()"), 123;
is eval("fff(456)"), 123;
is eval("fff(456, 789)"), 123;
is $a, 123;

sub ggg ($a) { $a || "z" }
is prototype(\&ggg), undef;
is &ggg(), "z";
is &ggg(456), 456;
is &ggg(456, 789), 456;
is eval("ggg()"), "z";
is eval("ggg(456)"), 456;
is eval("ggg(456, 789)"), 456;
is $a, 123;

sub hhh ($) ($a) { $a || "z" }
is prototype(\&hhh), "\$";
is &hhh(), "z";
is &hhh(456), 456;
is &hhh(456, 789), 456;
is eval("hhh()"), undef;
is eval("hhh(456)"), 456;
is eval("hhh(456, 789)"), undef;
is $a, 123;

sub iii :method { $a || "z" }
is prototype(\&iii), undef;
is &iii(), 123;
is eval("iii()"), 123;
is eval("iii(456)"), 123;
is eval("iii(456, 789)"), 123;
is $a, 123;

sub jjj :method ( ) { $a || "z" }
is prototype(\&jjj), undef;
is &jjj(), 123;
is &jjj(456), 123;
is &jjj(456, 789), 123;
is eval("jjj()"), 123;
is eval("jjj(456)"), 123;
is eval("jjj(456, 789)"), 123;
is $a, 123;

sub kkk :method ($a) { $a || "z" }
is prototype(\&kkk), undef;
is &kkk(), "z";
is &kkk(456), 456;
is &kkk(456, 789), 456;
is eval("kkk()"), "z";
is eval("kkk(456)"), 456;
is eval("kkk(456, 789)"), 456;
is $a, 123;

sub lll ($) :method ($a) { $a || "z" }
is prototype(\&lll), "\$";
is &lll(), "z";
is &lll(456), 456;
is &lll(456, 789), 456;
is eval("lll()"), undef;
is eval("lll(456)"), 456;
is eval("lll(456, 789)"), undef;
is $a, 123;

sub mmm ($z, $a, $b) { "$z/$a/$b" }
is mmm(111,222,333,444), "111/222/333";
is $a, 123;

sub nnn ($a, undef, $b) { "$a/$b" }
is nnn(111,222,333,444), "111/333";

sub ooo ($a, undef, ${b},) { "$a/$b" }
is ooo(111,222,333,444), "111/333";

is eval('sub ppp ($a) { $a } ppp(456)'), 456;
is eval('sub qqq (${"a"}) { $a } 1'), undef;
