#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '.';
    push @INC, '../lib';
}

print "1..27\n";

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
    if ($key eq $keys[$i] && $value eq $values[$i]
        && (('a' lt 'A' && $key lt $value) || $key gt $value)) {
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

# test scalar each
%hash = 1..20;
$total = 0;
$total += $key while $key = each %hash;
print "# Scalar each is bad.\nnot " unless $total == 100;
print "ok 8\n";

for (1..3) { @foo = each %hash }
keys %hash;
$total = 0;
$total += $key while $key = each %hash;
print "# Scalar keys isn't resetting the iterator.\nnot " if $total != 100;
print "ok 9\n";

for (1..3) { @foo = each %hash }
$total = 0;
$total += $key while $key = each %hash;
print "# Iterator of each isn't being maintained.\nnot " if $total == 100;
print "ok 10\n";

for (1..3) { @foo = each %hash }
values %hash;
$total = 0;
$total += $key while $key = each %hash;
print "# Scalar values isn't resetting the iterator.\nnot " if $total != 100;
print "ok 11\n";

$size = (split('/', scalar %hash))[1];
keys(%hash) = $size / 2;
print "not " if $size != (split('/', scalar %hash))[1];
print "ok 12\n";
keys(%hash) = $size + 100;
print "not " if $size == (split('/', scalar %hash))[1];
print "ok 13\n";

print "not " if keys(%hash) != 10;
print "ok 14\n";

print keys(hash) != 10 ? "not ok 15\n" : "ok 15\n";

$i = 0;
%h = (a => A, b => B, c=> C, d => D, abc => ABC);
@keys = keys(h);
@values = values(h);
while (($key, $value) = each(h)) {
	if ($key eq $keys[$i] && $value eq $values[$i] && $key eq lc($value)) {
		$i++;
	}
}
if ($i == 5) { print "ok 16\n" } else { print "not ok\n" }

{
    package Obj;
    sub DESTROY { print "ok 18\n"; }
    {
	my $h = { A => bless [], __PACKAGE__ };
        while (my($k,$v) = each %$h) {
	    print "ok 17\n" if $k eq 'A' and ref($v) eq 'Obj';
	}
    }
    print "ok 19\n";
}

# Check for Unicode hash keys.
%u = ("\x{12}", "f", "\x{123}", "fo", "\x{1234}",  "foo");
$u{"\x{12345}"}  = "bar";
@u{"\x{123456}"} = "zap";

foreach (keys %u) {
    unless (length() == 1) {
	print "not ";
	last;
    }
}
print "ok 20\n";

$a = "\xe3\x81\x82"; $A = "\x{3042}";
%b = ( $a => "non-utf8");
%u = ( $A => "utf8");

print "not " if exists $b{$A};
print "ok 21\n";
print "not " if exists $u{$a};
print "ok 22\n";
print "# $b{$_}\n" for keys %b; # Used to core dump before change #8056.
print "ok 23\n";
print "# $u{$_}\n" for keys %u; # Used to core dump before change #8056.
print "ok 24\n";

# on EBCDIC chars are mapped differently so pick something that needs encoding
# there too.
$d = pack("U*", 0xe3, 0x81, 0xAF);
{ use bytes; $ol = bytes::length($d) }
print "not " unless $ol > 3;
print "ok 25\n";
%u = ($d => "downgrade");
for (keys %u) {
    print "not " if length ne 3 or $_ ne "\xe3\x81\xAF";
    print "ok 26\n";
}
{
    { use bytes; print "not " if bytes::length($d) != $ol }
    print "ok 27\n";
}
