#!./perl

# $RCSfile: each.t,v $$Revision: 4.1 $$Date: 92/08/07 18:27:47 $

print "1..7\n";

$h{'abc'} = 'ABC';
$h{'def'} = 'DEF';
$h{'jkl','mno'} = "JKL\034MNO";
$h{'a',2,3,4,5} = join("\034",'A',2,3,4,5);
$h{'a'} = 'A';
$h{'b'} = 'B';
$h{'c'} = 'C';
$h{'d'} = 'D';
$h{'e'} = 'E';
$h{'f'} = 'F';
$h{'g'} = 'G';
$h{'h'} = 'H';
$h{'i'} = 'I';
$h{'j'} = 'J';
$h{'k'} = 'K';
$h{'l'} = 'L';
$h{'m'} = 'M';
$h{'n'} = 'N';
$h{'o'} = 'O';
$h{'p'} = 'P';
$h{'q'} = 'Q';
$h{'r'} = 'R';
$h{'s'} = 'S';
$h{'t'} = 'T';
$h{'u'} = 'U';
$h{'v'} = 'V';
$h{'w'} = 'W';
$h{'x'} = 'X';
$h{'y'} = 'Y';
$h{'z'} = 'Z';

@keys = keys %h;
@values = values %h;

if ($#keys == 29 && $#values == 29) {print "ok 1\n";} else {print "not ok 1\n";}

$i = 0;		# stop -w complaints

while (($key,$value) = each(%h)) {
    if ($key eq $keys[$i] && $value eq $values[$i] && $key eq lc($value)) {
	$key =~ y/a-z/A-Z/;
	$i++ if $key eq $value;
    }
}

if ($i == 30) {print "ok 2\n";} else {print "not ok 2\n";}

@keys = ('blurfl', keys(%h), 'dyick');
if ($#keys == 31) {print "ok 3\n";} else {print "not ok 3\n";}

$size = ((split('/',scalar %h))[1]);
keys %h = $size * 5;
$newsize = ((split('/',scalar %h))[1]);
if ($newsize == $size * 8) {print "ok 4\n";} else {print "not ok 4\n";}
keys %h = 1;
$size = ((split('/',scalar %h))[1]);
if ($size == $newsize) {print "ok 5\n";} else {print "not ok 5\n";}
%h = (1,1);
$size = ((split('/',scalar %h))[1]);
if ($size == $newsize) {print "ok 6\n";} else {print "not ok 6\n";}
undef %h;
%h = (1,1);
$size = ((split('/',scalar %h))[1]);
if ($size == 8) {print "ok 7\n";} else {print "not ok 7\n";}
