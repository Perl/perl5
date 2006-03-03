BEGIN {
    if ($ENV{PERL_CORE}) {
	chdir 't' if -d 't';
	@INC = ("../lib", "lib/compress");
    }
}

use lib qw(t t/compress);
use strict;
use warnings;
use bytes;

use Test::More ;
use CompTestUtils;

BEGIN {
    plan(skip_all => "oneshot needs Perl 5.005 or better - you have Perl $]" )
        if $] < 5.005 ;


    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 95 + $extra ;

    use_ok('IO::Compress::Zip', qw(zip $ZipError)) ;
    use_ok('IO::Uncompress::Unzip', qw(unzip $UnzipError)) ;


}


sub zipGetHeader
{
    my $in = shift;
    my $content = shift ;
    my %opts = @_ ;

    my $out ;
    my $got ;

    ok zip($in, \$out, %opts), "  zip ok" ;
    ok unzip(\$out, \$got), "  unzip ok" 
        or diag $UnzipError ;
    is $got, $content, "  got expected content" ;

    my $gunz = new IO::Uncompress::Unzip \$out, Strict => 0
        or diag "UnzipError is $IO::Uncompress::Unzip::UnzipError" ;
    ok $gunz, "  Created IO::Uncompress::Unzip object";
    my $hdr = $gunz->getHeaderInfo();
    ok $hdr, "  got Header info";
    my $uncomp ;
    ok $gunz->read($uncomp), " read ok" ;
    is $uncomp, $content, "  got expected content";
    ok $gunz->close, "  closed ok" ;

    return $hdr ;
    
}

{
    title "Check zip header default NAME & MTIME settings" ;

    my $lex = new LexFile my $file1;

    my $content = "hello ";
    my $hdr ;
    my $mtime ;

    writeFile($file1, $content);
    $mtime = (stat($file1))[9];
    # make sure that the zip file isn't created in the same
    # second as the input file
    sleep 3 ; 
    $hdr = zipGetHeader($file1, $content);

    is $hdr->{Name}, $file1, "  Name is '$file1'";
    is $hdr->{Time}>>1, $mtime>>1, "  Time is ok";

    title "Override Name" ;

    writeFile($file1, $content);
    $mtime = (stat($file1))[9];
    sleep 3 ; 
    $hdr = zipGetHeader($file1, $content, Name => "abcde");

    is $hdr->{Name}, "abcde", "  Name is 'abcde'" ;
    is $hdr->{Time} >> 1, $mtime >> 1, "  Time is ok";

    title "Override Time" ;

    writeFile($file1, $content);
    my $useTime = time + 2000 ;
    $hdr = zipGetHeader($file1, $content, Time => $useTime);

    is $hdr->{Name}, $file1, "  Name is '$file1'" ;
    is $hdr->{Time} >> 1 , $useTime >> 1 ,  "  Time is $useTime";

    title "Override Name and Time" ;

    $useTime = time + 5000 ;
    writeFile($file1, $content);
    $hdr = zipGetHeader($file1, $content, Time => $useTime, Name => "abcde");

    is $hdr->{Name}, "abcde", "  Name is 'abcde'" ;
    is $hdr->{Time} >> 1 , $useTime >> 1 , "  Time is $useTime";

    title "Filehandle doesn't have default Name or Time" ;
    my $fh = new IO::File "< $file1"
        or diag "Cannot open '$file1': $!\n" ;
    sleep 3 ; 
    my $before = time ;
    $hdr = zipGetHeader($fh, $content);
    my $after = time ;

    ok ! defined $hdr->{Name}, "  Name is undef";
    cmp_ok $hdr->{Time} >> 1, '>=', $before >> 1, "  Time is ok";
    cmp_ok $hdr->{Time} >> 1, '<=', $after >> 1, "  Time is ok";

    $fh->close;

    title "Buffer doesn't have default Name or Time" ;
    my $buffer = $content;
    $before = time ;
    $hdr = zipGetHeader(\$buffer, $content);
    $after = time ;

    ok ! defined $hdr->{Name}, "  Name is undef";
    cmp_ok $hdr->{Time} >> 1, '>=', $before >> 1, "  Time is ok";
    cmp_ok $hdr->{Time} >> 1, '<=', $after >> 1, "  Time is ok";
}

for my $stream (0, 1)
{
    for my $store (0, 8)
    {
        title "Stream $stream, Store $store";

        my $lex = new LexFile my $file1;

        my $content = "hello ";
        writeFile($file1, $content);

        ok zip(\$content => $file1 , Store => !$store, Stream => $stream), " zip ok" 
            or diag $ZipError ;

        my $got ;
        if ($stream && ! $store) {
            #eval ' unzip($file1 => \$got) ';
            ok ! unzip($file1 => \$got), "  unzip fails"; 
            like $UnzipError, "/Streamed Stored content not supported/",
                "  Streamed Stored content not supported";
                next ;
        }

        ok unzip($file1 => \$got), "  unzip ok"
            or diag $UnzipError ;

        is $got, $content, "  content ok";

        my $u = new IO::Uncompress::Unzip $file1
            or diag $ZipError ;

        my $hdr = $u->getHeaderInfo();
        ok $hdr, "  got header";

        is $hdr->{Stream}, $stream, "  stream is $stream" ;
        is $hdr->{MethodID}, $store, "  MethodID is $store" ;
    }
}

# TODO add more error cases

