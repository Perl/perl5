#!./perl

BEGIN {
    unless(grep /blib/, @INC) {
	chdir 't' if -d 't';
	@INC = '../lib';
    }
}

use Config;

BEGIN {
    if(-d "lib" && -f "TEST") {
        if ($Config{'extensions'} !~ /\bIO\b/ && $^O ne 'VMS') {
	    print "1..0\n";
	    exit 0;
        }
    }
}

use IO::File;
use IO::Seekable;

print "1..6\n";

$x = new_tmpfile IO::File or print "not ";
print "ok 1\n";
print $x "ok 2\n";
$x->seek(0,SEEK_SET);
print <$x>;

$x->seek(0,SEEK_SET);
print $x "not ok 3\n";
$p = $x->getpos;
print $x "ok 3\n";
$x->flush;
$x->setpos($p);
print scalar <$x>;

$! = 0;
$x->setpos(undef);
print $! ? "ok 4 # $!\n" : "not ok 4\n";

# These shenanigans are intended to make a perl IO pointing to C FILE *
# (or equivalent) on a closed file handle. Something that will fail fgetops()
# Might be easier to use STDIN if (-t STDIN || -P STDIN) if ttys/pipes on
# all platforms fail to fgetpos()
$fn = $x->fileno();
$y = new IO::File;
if ($y->fdopen ($fn, "r")) {
  print "ok 5\n";
  $x->close() or die $!;
  $!=0;
  $p = $y->getpos;
  if (defined $p) {
    print "not ok 6 # closed handle returned defined position, \$!='$!'\n";
  } else {
    print "ok 6 # $!\n";
  }
} else {
  print "not ok 5 # failed to duplicated file number $fd\n", "not ok 6\n";
}
