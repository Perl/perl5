#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    unless (defined &perlio::import) {
	print "1..0 # Skip: not perlio\n";
	exit 0;
    }
}

$| = 1;
print "1..25\n";

open(F,"+>:utf8",'a');
print F chr(0x100).'£';
print '#'.tell(F)."\n";
print "not " unless tell(F) == 4;
print "ok 1\n";
print F "\n";
print '#'.tell(F)."\n";
print "not " unless tell(F) >= 5;
print "ok 2\n";
seek(F,0,0);
print "not " unless getc(F) eq chr(0x100);
print "ok 3\n";
print "not " unless getc(F) eq "£";
print "ok 4\n";
print "not " unless getc(F) eq "\n";
print "ok 5\n";
seek(F,0,0);
binmode(F,":bytes");
print "not " unless getc(F) eq chr(0xc4);
print "ok 6\n";
print "not " unless getc(F) eq chr(0x80);
print "ok 7\n";
print "not " unless getc(F) eq chr(0xc2);
print "ok 8\n";
print "not " unless getc(F) eq chr(0xa3);
print "ok 9\n";
print "not " unless getc(F) eq "\n";
print "ok 10\n";
seek(F,0,0);
binmode(F,":utf8");
print "not " unless scalar(<F>) eq "\x{100}£\n";
print "ok 11\n";
seek(F,0,0);
$buf = chr(0x200);
$count = read(F,$buf,2,1);
print "not " unless $count == 2;
print "ok 12\n";
print "not " unless $buf eq "\x{200}\x{100}£";
print "ok 13\n";
close(F);

{
$a = chr(300); # This *is* UTF-encoded
$b = chr(130); # This is not.

open F, ">:utf8", 'a' or die $!;
print F $a,"\n";
close F;

open F, "<:utf8", 'a' or die $!;
$x = <F>;
chomp($x);
print "not " unless $x eq chr(300);
print "ok 14\n";

open F, "a" or die $!; # Not UTF
$x = <F>;
chomp($x);
print "not " unless $x eq chr(196).chr(172);
print "ok 15\n";
close F;

open F, ">:utf8", 'a' or die $!;
binmode(F);  # we write a "\n" and then tell() - avoid CRLF issues.
print F $a;
my $y;
{ my $x = tell(F);
    { use bytes; $y = length($a);}
    print "not " unless $x == $y;
    print "ok 16\n";
}

{ # Check byte length of $b
use bytes; my $y = length($b);
print "not " unless $y == 1;
print "ok 17\n";
}

print F $b,"\n"; # Don't upgrades $b

{ # Check byte length of $b
use bytes; my $y = length($b);
print "not ($y) " unless $y == 1;
print "ok 18\n";
}

{ my $x = tell(F);
    { use bytes; $y += 3;}
    print "not ($x,$y) " unless $x == $y;
    print "ok 19\n";
}

close F;

open F, "a" or die $!; # Not UTF
$x = <F>;
chomp($x);
printf "not (%vd) ", $x unless $x eq v196.172.194.130;
print "ok 20\n";

open F, "<:utf8", "a" or die $!;
$x = <F>;
chomp($x);
close F;
printf "not (%vd) ", $x unless $x eq chr(300).chr(130);
print "ok 21\n";

# Now let's make it suffer.
open F, ">", "a" or die $!;
eval { print F $a; };
print "not " unless $@ and $@ =~ /Wide character in print/i;
print "ok 22\n";
}

# Hm. Time to get more evil.
open F, ">:utf8", "a" or die $!;
print F $a;
binmode(F, ":bytes");
print F chr(130)."\n";
close F;

open F, "<", "a" or die $!;
$x = <F>; chomp $x;
print "not " unless $x eq v196.172.130;
print "ok 23\n";

# Right.
open F, ">:utf8", "a" or die $!;
print F $a;
close F;
open F, ">>", "a" or die $!;
print F chr(130)."\n";
close F;

open F, "<", "a" or die $!;
$x = <F>; chomp $x;
print "not " unless $x eq v196.172.130;
print "ok 24\n";

# Now we have a deformed file.
open F, "<:utf8", "a" or die $!;
$x = <F>; chomp $x;
{ local $SIG{__WARN__} = sub { print "ok 25\n"; };
eval { sprintf "%vd\n", $x; }
}

unlink('a');

