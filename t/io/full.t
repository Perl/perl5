#!./perl
#
# Test for 'disk full' errors, if possible
# 20020416 mjd-perl-patch+@plover.com

unless (-c "/dev/full" && open FULL, "> /dev/full") {
  print "1..0\n"; exit 0;
}

my $z;
print "1..6\n";

print FULL "I like pie.\n" ? print "ok 1\n" : print "not ok 1\n";
# Should fail
$z = close(FULL);
print $z ? "not ok 2 # z=$z; $!\n" : "ok 2\n";
print $!{ENOSPC} ? "ok 3\n" : "not ok 3\n";
  
unless (open FULL, "> /dev/full") {
  print "# couldn't open /dev/full the second time: $!\n";
  print "not ok $_\n" for 4..6;
  exit 0;
}

select FULL;   $| = 1;  select STDOUT;

# Should fail
$z = print FULL "I like pie.\n";
print $z ? "not ok 4 # z=$z; $!\n" : "ok 4\n";
print $!{ENOSPC} ? "ok 5\n" : "not ok 5\n";
$z = close FULL;
print $z ? "ok 6\n" : "not ok 6 # z=$s; $!\n";
