# $Id: enc_module.t,v 1.2 2003/03/09 17:32:43 dankogai Exp $
# This file is in euc-jp
BEGIN {
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bEncode\b/) {
      print "1..0 # Skip: Encode was not built\n";
      exit 0;
    }
    unless (find PerlIO::Layer 'perlio') {
	print "1..0 # Skip: PerlIO was not built\n";
	exit 0;
    }
    if (defined ${^UNICODE} and ${^UNICODE} != 0){
	print "1..0 # Skip: \${^UNICODE} == ${^UNICODE}\n";
	exit 0;
    }
    if (ord("A") == 193) {
	print "1..0 # encoding pragma does not support EBCDIC platforms\n";
	exit(0);
    }
}
use lib 't';
use lib qw(ext/Encode/t ../ext/Encode/t); # in case of perl core
use Mod_EUCJP;
use encoding "euc-jp";
use Test::More tests => 3;
use File::Basename;
use File::Spec;
use File::Compare qw(compare_text);

my $dir = dirname(__FILE__);
my $file0 = File::Spec->catfile($dir,"enc_module.enc");
my $file1 = File::Spec->catfile($dir,"$$.enc");

my $obj = Mod_EUCJP->new;
local $SIG{__WARN__} = sub{}; # to silence reopening STD(IN|OUT) w/o closing

open STDOUT, ">", $file1 or die "$file1:$!";
print $obj->str, "\n";
$obj->set("テスト文字列");
print $obj->str, "\n";
close STDOUT;

my $cmp = compare_text($file0, $file1);
is($cmp, 0, "encoding vs. STDOUT");
unlink $file1 unless $cmp;

my @cmp = qw/初期文字列 テスト文字列/;
open STDIN, "<", $file0 or die "$file0:$!";
$obj = Mod_EUCJP->new;
my $i = 0;
while(<STDIN>){
    chomp;
    is ($cmp[$i++], $_, "encoding vs. STDIN - $i");
}

__END__

