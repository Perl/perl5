#!./perl

#From jhi@snakemail.hut.fi Mon May 16 10:36:46 1994
#Date: Sun, 15 May 1994 20:39:09 +0300
#From: Jarkko Hietaniemi <jhi@snakemail.hut.fi>

print "1..2\n";

$n = 1000;

$c = 0;
for (1..$n) {
    last if (rand() > 1 || rand() < 0);
    $c++;
}

if ($c == $n) {print "ok 1\n";} else {print "not ok 1\n"}

$c = 0;
for (1..$n) {
    last if (rand(10) > 10 || rand(10) < 0);
    $c++;
}

if ($c == $n) {print "ok 2\n";} else {print "not ok 2\n"}
