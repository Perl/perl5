BEGIN {
    if ($ENV{'PERL_CORE'}){
        chdir 't';
        unshift @INC, '../lib';
    }
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bEncode\b/) {
      print "1..0 # Skip: Encode was not built\n";
      exit 0;
    }
    if (ord("A") == 193) {
	print "1..0 # Skip: EBCDIC\n";
	exit 0;
    }
    unless (PerlIO::Layer->find('perlio')){
	print "1..0 # Skip: PerlIO required\n";
	exit 0;
    }
    $| = 1;
}
use strict;
use Test::More tests => 11;
#use Test::More qw(no_plan);
use Encode;
use File::Basename;
use File::Spec;
use File::Compare qw(compare_text);
require_ok "Encode::KR";

my ($src, $uni, $dst, $txt, $euc, $utf, $ref, $rnd);

ok(defined(my $enc = find_encoding('euc-kr')));
ok($enc->isa('Encode::XS'));
is($enc->name,'euc-kr');
my $dir = dirname(__FILE__);

for my $charset (qw(ksc5601)){
    $euc = File::Spec->catfile($dir,"$charset.euc");
    $utf = File::Spec->catfile($dir,"$$.utf8");
    $ref = File::Spec->catfile($dir,"$charset.ref");
    $rnd = File::Spec->catfile($dir,"$$.rnd");

    open($src,"<",$euc) or die "Cannot open $euc:$!";
    binmode($src);
    $txt = join('',<$src>);
    close($src);
    
    eval{ $uni = $enc->decode($txt, 1) }; 
    $@ and print $@;
    ok(defined($uni),  "decode $charset");
    is(length($txt),0, "decode $charset completely");

    open($dst,">:utf8",$utf) or die "Cannot open $utf:$!";
    binmode($dst);
    print $dst $uni;
    close($dst); 
    is(compare_text($utf, $ref), 0, "$utf eq $ref");
    
    open $src, "<:utf8", $ref or die "$ref : $!";
    binmode($src);
    $uni = join('', <$src>);
    close $src;

    for my $canon (qw(euc-kr)){
	my $test = \&is;
	if   ($charset eq 'jisx0201'){
	    $canon eq 'iso-2022-jp'   and $test = \&isnt;
	    $canon eq 'iso-2022-jp-1' and $test = \&isnt;
	}elsif($charset eq 'jisx0212'){
	    $canon eq 'shiftjis'    and   $test = \&isnt;
	    $canon eq 'iso-2022-jp' and   $test = \&isnt;
	}
	my $rt = ($test eq \&is) ? 'RT' : 'non-RT';
	$test->($uni, decode($canon, encode($canon, $uni)), 
	      "$rt $charset $canon");
	
     }

    eval{ $txt = $enc->encode($uni,1) };    
    $@ and print $@;
    ok(defined($txt),   "encode $charset");
    is(length($uni), 0, "encode $charset completely");

    open($dst,">", $rnd) or die "Cannot open $utf:$!";
    binmode($dst);
    print $dst $txt;
    close($dst); 
    is(compare_text($euc, $rnd), 0 => "$rnd eq $euc");
}

END {
 1 while unlink($utf,$rnd);
}
