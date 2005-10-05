
use lib 't';
 
use strict;
use warnings;
use bytes;

use Test::More ;
use ZlibTestUtils;

BEGIN {
    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 63 + $extra ;

    use_ok('Compress::Zlib', 2) ;

    use_ok('IO::Compress::Gzip', qw($GzipError)) ;
    use_ok('IO::Uncompress::Gunzip', qw($GunzipError)) ;

    use_ok('IO::Compress::Deflate', qw($DeflateError)) ;
    use_ok('IO::Uncompress::Inflate', qw($InflateError)) ;

    use_ok('IO::Compress::RawDeflate', qw($RawDeflateError)) ;
    use_ok('IO::Uncompress::RawInflate', qw($RawInflateError)) ;
    use_ok('IO::Uncompress::AnyInflate', qw($AnyInflateError)) ;
}

foreach my $Class ( map { "IO::Compress::$_" } qw( Gzip Deflate RawDeflate) )
{
    
    for my $trans ( 0, 1 )
    {
        title "AnyInflate(Transparent => $trans) with $Class" ;
        my $string = <<EOM;
some text
EOM

        my $buffer ;
        my $x = new $Class(\$buffer) ;
        ok $x, "  create $Class object" ;
        ok $x->write($string), "  write to object" ;
        ok $x->close, "  close ok" ;

        my $unc = new IO::Uncompress::AnyInflate \$buffer, Transparent => $trans  ;

        ok $unc, "  Created AnyInflate object" ;
        my $uncomp ;
        ok $unc->read($uncomp) > 0 
            or print "# $IO::Uncompress::AnyInflate::AnyInflateError\n";
        ok $unc->eof(), "  at eof" ;
        #ok $unc->type eq $Type;

        is $uncomp, $string, "  expected output" ;
    }

}

{
    title "AnyInflate with Non-compressed data" ;

    my $string = <<EOM;
This is not compressed data
EOM

    my $buffer = $string ;

    my $unc ;
    my $keep = $buffer ;
    $unc = new IO::Uncompress::AnyInflate \$buffer, -Transparent => 0 ;
    ok ! $unc,"  no AnyInflate object when -Transparent => 0" ;
    is $buffer, $keep ;

    $buffer = $keep ;
    $unc = new IO::Uncompress::AnyInflate \$buffer, -Transparent => 1 ;
    ok $unc, "  AnyInflate object when -Transparent => 1"  ;

    my $uncomp ;
    ok $unc->read($uncomp) > 0 ;
    ok $unc->eof() ;
    #ok $unc->type eq $Type;

    is $uncomp, $string ;
}
