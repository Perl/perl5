#!./perl

# $RCSfile: goto.t,v $$Revision: 4.1 $$Date: 92/08/07 18:27:56 $

print "1..5\n";

while ($?) {
    $foo = 1;
  label1:
    $foo = 2;
    goto label2;
} continue {
    $foo = 0;
    goto label4;
  label3:
    $foo = 4;
    goto label4;
}
goto label1;

$foo = 3;

label2:
print "#1\t:$foo: == 2\n";
if ($foo == 2) {print "ok 1\n";} else {print "not ok 1\n";}
goto label3;

label4:
print "#2\t:$foo: == 4\n";
if ($foo == 4) {print "ok 2\n";} else {print "not ok 2\n";}

$x = `./perl -e 'goto foo;' 2>&1`;
if ($x =~ /label/) {print "ok 3\n";} else {print "not ok 3\n";}

sub foo {
    goto bar;
    print "not ok 4\n";
    return;
bar:
    print "ok 4\n";
}

&foo;

sub bar {
    $x = 'exitcode';
    eval "goto $x";	# Do not take this as exemplary code!!!
}

&bar;
exit;
exitcode:
print "ok 5\n";
