BEGIN {
    chdir 't' if -d 't' and $ENV{PWD} !~ m,/Encode[^/]*$,o;
    unshift @INC, '../lib';
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bEncode\b/) {
      print "1..0 # Skip: Encode was not built\n";
      exit 0;
    }
    unless (find PerlIO::Layer 'perlio') {
	print "1..0 # Skip: PerlIO was not built\n";
	exit 0;
    }
    if (ord("A") == 193) {
	print "1..0 # Skip: EBCDIC\n";
	exit 0;
    }
    $| = 1;
}
use strict;
use Test::More tests => 27;
#use Test::More qw(no_plan);
use Encode;
use File::Basename;
use File::Spec;
use File::Compare;
require_ok "Encode::JP";

my ($src, $uni, $dst, $txt, $euc, $utf, $ref, $rnd);

ok(defined(my $enc = find_encoding('euc-jp')));
ok($enc->isa('Encode::XS'));
is($enc->name,'euc-jp');
my $dir = dirname(__FILE__);

my @subcodings = qw(jisx0212 jisx0208);

for my $subcoding (@subcodings){
    $euc = File::Spec->catfile($dir,"$subcoding.euc");
    $utf = File::Spec->catfile($dir,"$$.utf8");
    $ref = File::Spec->catfile($dir,"$subcoding.ref");
    $rnd = File::Spec->catfile($dir,"$$.rnd");
    print "# Basic decode test\n";
    open($src,"<",$euc) || die "Cannot open $euc:$!";
    binmode($src);
    ok(defined($src) && fileno($src));
    $txt = join('',<$src>);
    open($dst,">:utf8",$utf) || die "Cannot open $utf:$!";
    binmode($dst);
    ok(defined($dst) && fileno($dst));
    eval{ $uni = $enc->decode($txt,1) };
    $@ and print $@;
    ok(defined($uni));
    is(length($txt),0);
    print $dst $uni;
    close($dst);
    close($src);
    ok(compare($utf,$ref) == 0);
}

print "# Basic encode test\n";
open($src,"<:utf8",$ref) || die "Cannot open $ref:$!";
binmode($src);
ok(defined($src) && fileno($src));
$uni = join('',<$src>);
open($dst,">",$rnd) || die "Cannot open $rnd:$!";
binmode($dst);
ok(defined($dst) && fileno($dst));
$txt = $enc->encode($uni,1);
ok(defined($txt));
is(length($uni),0);
print $dst $txt;
close($dst);
close($src);
ok(compare($euc,$rnd) == 0);

is($enc->name,'euc-jp');

print "# src :encoding test\n";
open($src,"<encoding(euc-jp)",$euc) || die "Cannot open $euc:$!";
binmode($src);
ok(defined($src) && fileno($src));
open($dst,">:utf8",$utf) || die "Cannot open $utf:$!";
binmode($dst);
ok(defined($dst) || fileno($dst));
my $out = select($dst);
while (<$src>)
 {
  print;
 }
close($dst);
close($src);

TODO:
{
  local $TODO = 'needs debugging on VMS' if $^O eq 'VMS';
  ok(compare($utf,$ref) == 0);
}
select($out);

SKIP:
{
 #skip "Multi-byte write is broken",3;
 print "# dst :encoding test\n";
 open($src,"<:utf8",$ref) || die "Cannot open $ref:$!";
 binmode($src);
 ok(defined($src) || fileno($src));
 open($dst,">encoding(euc-jp)",$rnd) || die "Cannot open $rnd:$!";
 binmode($dst);
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
 1 while unlink($utf,$rnd);
}
