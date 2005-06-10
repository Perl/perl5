

use strict ;
local ($^W) = 1; #use warnings ;

use Compress::Zlib ;

BEGIN
{
 
    my $ver = Compress::Zlib::zlib_version();
    print "ver $ver\n";
    if (defined $ver && $ver =~ /^(\d+)\.(\d+)\.(\d+)/ )
    {
        my $sum = $1 * 1000000 + $2 * 1000 + $3 ;
     
        if ($sum < 1_000_006) {
            print "1..0 #  Skip: gzsetparams needs zlib 1.0.6 or better. You have $ver\n";
            exit 0;
        }
    }
    else
    {
        print "1..0 #  Skip: gzsetparams needs zlib 1.0.6 or better.\n";
        exit 0;
    }
}
 
sub ok
{
    my ($no, $ok) = @_ ;

    #++ $total ;
    #++ $totalBad unless $ok ;

    print "ok $no\n" if $ok ;
    print "not ok $no\n" unless $ok ;
}

print "1..11\n" ;

# Check zlib_version and ZLIB_VERSION are the same.
ok(1, Compress::Zlib::zlib_version eq ZLIB_VERSION) ;


{
    # gzsetparams

    my $hello = "I am a HAL 9000 computer" x 2001 ;
    my $len_hello = length $hello ;
    my $goodbye = "Will I dream?" x 2010;
    my $len_goodbye = length $goodbye;

    my ($input, $err, $answer, $X, $status, $Answer);
     
    my $name = "test.gz" ;
    unlink $name ;
    ok(2, my $x = gzopen($name, "wb")) ;

    ok(3, $x->gzwrite($hello) == $len_hello) ;
    $input .= $hello;
    
    # error cases
    eval { $x->gzsetparams() };
    ok(4, $@ =~ /^Usage: Compress::Zlib::gzFile::gzsetparams\(file, level, strategy\) at/);

    # change both Level & Strategy
    $status = $x->gzsetparams(Z_BEST_SPEED, Z_HUFFMAN_ONLY) ;
    ok(5, $status == Z_OK) ;
    
    ok(6, $x->gzwrite($goodbye) == $len_goodbye) ;
    $input .= $goodbye;
    
    ok(7, ! $x->gzclose ) ;

    ok(8, my $k = gzopen($name, "rb")) ;
     
    my $len = length $input ;
    my $uncompressed;
    ok(9, $k->gzread($uncompressed, $len) == $len) ;

    ok(10, $uncompressed  eq $input ) ;
    ok(11, ! $k->gzclose ) ;
}
