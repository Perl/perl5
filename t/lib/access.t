#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

$| = 1;
print "1..15\n";

my $t = 1;

sub ok
{
 my $val = shift;
 if ($val)
  {
   print "ok $t\n";
  }
 else
  {
   my ($pack,$file,$line) = caller;
   print "not ok $t # $file:$line\n";
  }
 $t++;
}

my %hash = ( one => 1, two => 2);;
ok(!access::readonly(%hash));

ok(!access::readonly(%hash,1));

eval { $hash{'three'} = 3 };
#warn "$@";
ok($@ =~ /^Attempt to access to key 'three' in fixed hash/);

eval { print "# oops"  if $hash{'four'}};
#warn "$@";
ok($@ =~ /^Attempt to access to key 'four' in fixed hash/);

eval { $hash{"\x{2323}"} = 3 };
#warn "$@";
ok($@ =~ /^Attempt to access to key '(.*)' in fixed hash/);
#ok(ord($1) == 0x2323);

eval { delete $hash{'one'}};
#warn "$@";
ok($@ =~ /^Attempt to access to key 'one' in fixed hash/);

ok(exists $hash{'one'});

ok(!exists $hash{'three'});

ok(access::readonly(%hash,0));

ok(!access::readonly(%hash));

my $scalar = 1;
ok(!access::readonly($scalar));

ok(!access::readonly($scalar,1));

eval { $scalar++ };
#warn $@;
ok($@ =~ /^Modification of a read-only value attempted/);

ok(access::readonly($scalar,0));

ok(!access::readonly($scalar));


