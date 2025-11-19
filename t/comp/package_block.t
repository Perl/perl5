#!./perl

print "1..5\n";

$main::result = "";
eval q{
    $main::result .= "a(".__PACKAGE__."/".eval("__PACKAGE__").")";
    package Foo {
	$main::result .= "b(".__PACKAGE__."/".eval("__PACKAGE__").")";
	package Bar::Baz {
	    $main::result .= "c(".__PACKAGE__."/".eval("__PACKAGE__").")";
	}
	$main::result .= "d(".__PACKAGE__."/".eval("__PACKAGE__").")";
    }
    $main::result .= "e(".__PACKAGE__."/".eval("__PACKAGE__").")";
};
print $main::result eq
	"a(main/main)b(Foo/Foo)c(Bar::Baz/Bar::Baz)d(Foo/Foo)e(main/main)" ?
    "ok 1\n" : "not ok 1\n";

$main::result = "";
eval q{
    $main::result .= "a($Foo::VERSION)";
    $main::result .= "b($Bar::VERSION)";
    package Foo 11 { ; }
    package Bar 22 {
	$main::result .= "c(".__PACKAGE__."/".eval("__PACKAGE__").")";
    }
};
print $main::result eq "a(11)b(22)c(Bar/Bar)" ? "ok 2\n" : "not ok 2\n";

$main::result = "";
eval q{
    $main::result .= "a(".__PACKAGE__."/".eval("__PACKAGE__").")";
    package Foo { }
    $main::result .= "b(".__PACKAGE__."/".eval("__PACKAGE__").")";
};
print $main::result eq "a(main/main)b(main/main)" ? "ok 3\n" : "not ok 3\n";

eval q[package Foo {];
print $@ =~ /\AMissing right curly / ? "ok 4\n" : "not ok 4\n";

$main::result = "";
eval q{
    $main::result .= "a(".__LINE__.")";
    package Foo {
	$main::result .= "b(".__LINE__.")";
	package Bar::Baz {
	    $main::result .= "c(".__LINE__.")";
	}
	$main::result .= "d(".__LINE__.")";
    }
    $main::result .= "e(".__LINE__.")";
    package Quux { }
    $main::result .= "f(".__LINE__.")";
};
print $main::result eq "a(2)b(4)c(6)d(8)e(10)f(12)" ? "ok 5\n" : "not ok 5\n";
