#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require Config; import Config;
    if (! $Config{'usethreads'}) {
	print "1..0\n";
	exit 0;
    }
    $ENV{PERL_DESTRUCT_LEVEL} = 0;	# XXX known trouble with global destruction
}
$| = 1;
print "1..12\n";
use Thread;
print "ok 1\n";

sub content
{
 print shift;
 return shift;
}

# create a thread passing args and immedaietly wait for it.
my $t = new Thread \&content,("ok 2\n","ok 3\n");
print $t->join;

# check that lock works ...
{lock $foo;
 $t = new Thread sub { lock $foo; print "ok 5\n" };
 print "ok 4\n";
}
$t->join;

sub islocked
{
 use attrs 'locked';
 my $val = shift;
 my $ret;
 print $val;
 if (@_)
  {
   $ret = Thread->new(\&islocked, @_);
   join $ret;
  }
}

$t = new Thread \&islocked, map { "ok $_\n" } 6..10;
sleep 2;
join $t;

# test that sleep lets other thread run
$t = new Thread \&islocked,"ok 11\n";
sleep 6;
print "ok 12\n";
join $t;
