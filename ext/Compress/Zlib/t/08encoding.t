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

BEGIN
{
    plan skip_all => "Encode is not available"
        if $] < 5.006 ;

    eval { require Encode; Encode->import(); };

    plan skip_all => "Encode is not available"
        if $@ ;

    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 16 + $extra ;

    use_ok('Compress::Zlib', 2);
}




# Check zlib_version and ZLIB_VERSION are the same.
is Compress::Zlib::zlib_version, ZLIB_VERSION, 
    "ZLIB_VERSION matches Compress::Zlib::zlib_version" ;


if(0)
{
    # length of this string is 2 characters
    my $s = "\x{df}\x{100}"; 

    my $cs = Compress::Zlib::memGzip($s); 

    # length stored at end of gzip file should be 4
    my ($crc, $len) = unpack ("VV", substr($cs, -8, 8));
    
    is $len, 4, "length is 4";
}

{
    title "memGzip" ;
    # length of this string is 2 characters
    my $s = "\x{df}\x{100}"; 

    my $cs = Compress::Zlib::memGzip(Encode::encode_utf8($s));

    # length stored at end of gzip file should be 4
    my ($crc, $len) = unpack ("VV", substr($cs, -8, 8));
    
    is $len, 4, "  length is 4";
}

{
    title "compress/uncompress";

    my $s = "\x{df}\x{100}";                                   
    my $s_copy = $s ;

    #my $cs = compress($s);                      
    my $ces = compress(Encode::encode_utf8($s_copy));

    ok $ces, "  compressed ok" ;

    #is $s, $ces ;

    #my $un = uncompress($cs);
    #is $un, $s;
 
    my $un = Encode::decode_utf8(uncompress($ces));
    #my $un = uncompress($ces);
    is $un, $s, "  decode_utf8 ok";
 
    #$un = Encode::decode_utf8(uncompress($cs));
    #is $un, $s;

}

{
    title "gzopen" ;

    my $s = "\x{df}\x{100}";                                   
    my $byte_len = length( Encode::encode_utf8($s) );
    my ($uncomp) ;

    my $lex = new LexFile my $name ;
    ok my $fil = gzopen($name, "wb"), "  gzopen for write ok" ;

    is $fil->gzwrite(Encode::encode_utf8($s)), $byte_len, "  wrote $byte_len bytes" ;

    ok ! $fil->gzclose, "  gzclose ok" ;

    ok $fil = gzopen($name, "rb"), "  gzopen for read ok" ;

    is $fil->gzread($uncomp), $byte_len, "  read $byte_len bytes" ;
    is length($uncomp), $byte_len, "  uncompress is $byte_len bytes";

    ok ! $fil->gzclose, "gzclose ok" ;

    is $s, Encode::decode_utf8($uncomp), "  decode_utf8 ok" ;
}

# Add tests that check that the module traps use of wide chars

