BEGIN {
#   chdir 't' if -d 't';
#   @INC = (-d '../../lib' ? '../lib';
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bEncode\b/) {
      print "1..0 # Skip: Encode was not built\n";
      exit 0;
    }
    $| = 1;
}
use Test::More tests => 22;
use Encode;
use File::Basename;
use File::Spec;
use File::Compare;
require_ok "Encode::Japanese";

ok(defined(my $enc = find_encoding('euc-jp')));
ok($enc->isa('Encode::XS'));
is($enc->name,'euc-jp');
my $dir = dirname(__FILE__);
my $euc = File::Spec->catfile($dir,"table.euc");
my $utf = File::Spec->catfile($dir,"table.utf8");
my $ref = File::Spec->catfile($dir,"table.ref");
my $rnd = File::Spec->catfile($dir,"table.rnd");
print "# Basic decode test\n";
open(my $src,"<",$euc) || die "Cannot open $euc:$!";
ok(defined($src) && fileno($src));
my $txt = join('',<$src>);
open(my $dst,">:utf8",$utf) || die "Cannot open $utf:$!";
ok(defined($dst) && fileno($dst));
my $uni = $enc->decode($txt,1);
ok(defined($uni));
is(length($txt),0);
print $dst $uni;
close($dst);
close($src);
ok(compare($utf,$ref) == 0);

print "# Basic encode test\n";
open(my $src,"<:utf8",$ref) || die "Cannot open $ref:$!";
ok(defined($src) && fileno($src));
my $uni = join('',<$src>);
open(my $dst,">",$rnd) || die "Cannot open $rnd:$!";
ok(defined($dst) && fileno($dst));
my $txt = $enc->encode($uni,1);
ok(defined($txt));
is(length($uni),0);
print $dst $txt;
close($dst);
close($src);
ok(compare($euc,$rnd) == 0);

is($enc->name,'euc-jp');

print "# src :encoding test\n";
open(my $src,"<encoding(euc-jp)",$euc) || die "Cannot open $euc:$!";
ok(defined($src) && fileno($src));
open(my $dst,">:utf8",$utf) || die "Cannot open $utf:$!";
ok(defined($dst) || fileno($dst));
$out = select($dst);
while (<$src>)
 {
  print;
 }
close($dst);
close($src);
ok(compare($utf,$ref) == 0);
select($out);

SKIP:
{
 skip "Multi-byte write is broken",3;
 print "# dst :encoding test\n";
 open(my $src,"<:utf8",$ref) || die "Cannot open $ref:$!";
 ok(defined($src) || fileno($src));
 open(my $dst,">encoding(euc-jp)",$rnd) || die "Cannot open $rnd:$!";
 ok(defined($dst) || fileno($dst));
 my $out = select($dst);
 while (<$src>)
  {
   print;
  }
 close($dst);
 close($src);
 ok(compare($euc,$rnd) == 0);
 select($out);
}

is($enc->name,'euc-jp');
END {
# unlink($utf,$rnd);

}
