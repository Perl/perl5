#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require "../t/test.pl";
    skip_all("No perlio") unless (find PerlIO::Layer 'perlio');
    plan (16);
}

use warnings 'layer';
my $warn;
my $file = "fail$$";
$SIG{__WARN__} = sub { $warn = shift };

END { 1 while unlink($file) }

ok(open(FH,">",$file),"Create works");
close(FH);
ok(open(FH,"<",$file),"Normal open works");

$warn = ''; $! = 0;
ok(!binmode(FH,":-)"),"All punctuation fails binmode");
like($!,'Invalid',"Got errno");
like($warn,qr/in layer/,"Got warning");

$warn = ''; $! = 0;
ok(!binmode(FH,":nonesuch"),"Bad package fails binmode");
like($!,'No such',"Got errno");
like($warn,qr/nonesuch/,"Got warning");
close(FH);

$warn = ''; $! = 0;
ok(!open(FH,"<:-)",$file),"All punctuation fails open");
like($!,"Invalid","Got errno");
like($warn,qr/in layer/,"Got warning");
isnt($!,"","Got errno");

$warn = ''; $! = 0;
ok(!open(FH,"<:nonesuch",$file),"Bad package fails open");
like($!,"No such","Got errno");
like($warn,qr/nonesuch/,"Got warning");

ok(open(FH,"<",$file),"Normal open (still) works");
close(FH);
