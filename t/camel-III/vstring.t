# See if the things Camel-III says are true.
BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}
use Test;
plan test => 5;

# Chapter 2 pp67/68
my $vs = v1.20.300.4000;
ok($vs,"\x{1}\x{14}\x{12c}\x{fa0}","v-string ne \\x{}");
ok($vs,chr(1).chr(20).chr(300).chr(4000),"v-string ne chr()");
ok('foo',((chr(193) eq 'A') ? v134.150.150 : v102.111.111),"v-string ne ''");

# Chapter 15, pp403

# See if sane addr and gethostbyaddr() work
eval { require Socket; gethostbyaddr(v127.0.0.1,Socket::AF_INET()) };
if ($@)
 {
  # No - so don't test insane fails.
  skip("No Socket",'');
 }
else
 {
  my $ip   = v2004.148.0.1;
  my $host;
  eval { $host = gethostbyaddr($ip,Socket::AF_INET()) };
  ok($@ =~ /Wide character/,1,"Non-bytes leak to gethostbyaddr");
 }

# Chapter 28, pp671
ok(v5.6.0 lt v5.7.0,1,"v5.6.0 lt v5.7.0 fails");

# floating point too messy
# my $v = ord($^V)+ord(substr($^V,1,1))/1000+ord(substr($^V,2,1))/1000000;
# ok($v,$],"\$^V and \$] do not match");
