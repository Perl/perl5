#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require Config; import Config;
    unless ($Config{'useperlio'}) {
	print "1..0 # Skip: not perlio\n";
	exit 0;
    }
}

$| = 1;
print "1..13\n";

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

# unlink('a');

