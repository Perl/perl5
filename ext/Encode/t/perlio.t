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
    require Encode;
    eval { require PerlIO::encoding };
    unless ($INC{"PerlIO/encoding.pm"}
	    and PerlIO::encoding->VERSION >= 0.02
	   ){
	print "1..0 # Skip:: PerlIO::encoding 0.02 or better required\n";
	exit 0;
    }
    # warn "PerlIO::encoding->VERSION == ", PerlIO::encoding->VERSION, "\n";
    $| = 1;
}

use strict;
use File::Basename;
use File::Spec;
use File::Compare;
use FileHandle;

#use Test::More qw(no_plan);
use Test::More tests => 20;

our $DEBUG = 0;

{
    no warnings;
    @ARGV and $DEBUG = shift;
    require Encode::JP::JIS7;
    $Encode::JP::JIS7::DEBUG = $DEBUG;
}

Encode->import(":all");

my $dir = dirname(__FILE__);
my $ufile = File::Spec->catfile($dir,"jisx0208.ref");
open my $fh, "<:utf8", $ufile or die "$ufile : $!";
my @uline = <$fh>;
my $utext = join('' => @uline);
close $fh;

for my $e (qw/euc-jp shiftjis 7bit-jis iso-2022-jp iso-2022-jp-1/){
    my $sfile = File::Spec->catfile($dir,"$$.sio");
    my $pfile = File::Spec->catfile($dir,"$$.pio");

    # first create a file without perlio
    open $fh, ">", $sfile or die "$sfile :$!";
    binmode $fh;
    print $fh &encode($e, $utext, 0);
    close $fh;

    # then create a file via perlio without autoflush
	
 TODO:{
	todo_skip "$e: !perlio_ok", 1  unless perlio_ok($e);
	open $fh, ">:encoding($e)", $pfile or die "$sfile : $!";
	$fh->autoflush(0);
	print $fh $utext;
	close $fh;
	ok(compare($sfile, $pfile) == 0 => ">:encoding($e)");
    }
	
    # this time print line by line.
    # works even for ISO-2022!
    open $fh, ">:encoding($e)", $pfile or die "$sfile : $!";
    $fh->autoflush(1);
    for my $l (@uline) {
	print $fh $l;
    }
    close $fh;
    is(compare($sfile, $pfile), 0 => ">:encoding($e); line-by-line");

 TODO:{
	todo_skip "$e: !perlio_ok", 2 unless perlio_ok($e);
	open $fh, "<:encoding($e)", $pfile or die "$pfile : $!";
	$fh->autoflush(0);
	my $dtext = join('' => <$fh>);
	close $fh;
	ok($utext eq $dtext, "<:encoding($e)");
	$dtext = '';
	open $fh, "<:encoding($e)", $pfile or die "$pfile : $!";
	while(defined(my $l = <$fh>)) {
	    $dtext .= $l;
	}
	close $fh;
	ok($utext eq $dtext, "<:encoding($e); line-by-line");
    }
    $DEBUG or unlink ($sfile, $pfile);
}

