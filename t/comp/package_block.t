#!./perl

print "1..4\n";

$main::result = "";
eval q{
	$main::result .= "a(".__PACKAGE__.")";
	package Foo {
		$main::result .= "b(".__PACKAGE__.")";
		package Bar::Baz {
			$main::result .= "c(".__PACKAGE__.")";
		}
		$main::result .= "d(".__PACKAGE__.")";
	}
	$main::result .= "e(".__PACKAGE__.")";
};
print $main::result eq "a(main)b(Foo)c(Bar::Baz)d(Foo)e(main)" ?
	"ok 1\n" : "not ok 1\n";

$main::result = "";
eval q{
	$main::result .= "a($Foo::VERSION)";
	$main::result .= "b($Bar::VERSION)";
	package Foo 11 { ; }
	package Bar 22 { $main::result .= "c(".__PACKAGE__.")"; }
};
print $main::result eq "a(11)b(22)c(Bar)" ? "ok 2\n" : "not ok 2\n";

$main::result = "";
eval q{
	$main::result .= "a(".__PACKAGE__.")";
	package Foo { }
	$main::result .= "b(".__PACKAGE__.")";
};
print $main::result eq "a(main)b(main)" ? "ok 3\n" : "not ok 3\n";

eval q[package Foo {];
print $@ =~ /\AMissing right curly / ? "ok 4\n" : "not ok 4\n";

1;
