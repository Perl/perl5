
use strict ;
local ($^W) = 1; #use warnings ;

BEGIN 
{

    eval { require Encode; Encode->import(); };
    
    if ($@) {
        print "1..0 #  Skip: Encode is not available\n";
        #exit 0;
        $::bomb_out = 1;
    }
}

exit 0 if $::bomb_out ;

use Compress::Zlib ;
#use Encode;

sub ok
{
    my ($no, $ok) = @_ ;

    #++ $total ;
    #++ $totalBad unless $ok ;

    print "ok $no\n" if $ok ;
    print "not ok $no\n" unless $ok ;
}

sub readFile
{
    my ($filename) = @_ ;
    my ($string) = '' ;
 
    open (F, "<$filename")
        or die "Cannot open $filename: $!\n" ;
    binmode(F);
    while (<F>)
      { $string .= $_ }
    close F ;
    $string ;
}     

print "1..15\n" ;

# Check zlib_version and ZLIB_VERSION are the same.
ok(1, Compress::Zlib::zlib_version eq ZLIB_VERSION) ;


{
    # length of this string is 2 characters
    my $s = "\x{df}\x{100}"; 

    my $cs = Compress::Zlib::memGzip($s); 

    # length stored at end of gzip file should be 4
    my ($crc, $len) = unpack ("VV", substr($cs, -8, 8));
    
    ok(2, $len == 4);
}

{
    # length of this string is 2 characters
    my $s = "\x{df}\x{100}"; 

    my $cs = Compress::Zlib::memGzip(Encode::encode_utf8($s));

    # length stored at end of gzip file should be 4
    my ($crc, $len) = unpack ("VV", substr($cs, -8, 8));
    
    ok(3, $len == 4);
}

{
    my $s = "\x{df}\x{100}";                                   
    my $s_copy = $s ;

    my $cs = compress($s);                      
    my $ces = compress(Encode::encode_utf8($s_copy));

    ok(4, $cs eq $ces);

    my $un = uncompress($cs);
    ok(5, $un ne $s);
 
    $un = uncompress($ces);
    ok(6, $un ne $s);
 
    $un = Encode::decode_utf8(uncompress($cs));
    ok(7, $un eq $s);

}

{
    my $name = "test.gz" ;
    my $s = "\x{df}\x{100}";                                   
    my $byte_len = length( Encode::encode_utf8($s) );
    my ($uncomp) ;

    ok(8, my $fil = gzopen($name, "wb")) ;

    ok(9, $fil->gzwrite($s) == $byte_len) ;

    ok(10, ! $fil->gzclose ) ;

    ok(11, $fil = gzopen($name, "rb") ) ;

    ok(12, $fil->gzread($uncomp) == $byte_len) ;
    ok(13, length($uncomp) == $byte_len);

    ok(14, ! $fil->gzclose ) ;

    unlink $name ;

    ok(15, $s eq Encode::decode_utf8($uncomp)) ;

}
