
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

    plan tests => 2374 + $extra;

}

sub run
{
    my $CompressClass   = identify();
    my $UncompressClass = getInverse($CompressClass);
    my $Error           = getErrorRef($CompressClass);
    my $UnError         = getErrorRef($UncompressClass);
    
    my $hello = <<EOM ;
hello world
this is a test
some more stuff on this line
and finally...
EOM

    my $blocksize = 10 ;


    my ($info, $compressed) = mkComplete($CompressClass, $hello);

    my $header_size  = $info->{HeaderLength};
    my $trailer_size = $info->{TrailerLength};
    my $fingerprint_size = $info->{FingerprintLength};
    ok 1, "Compressed size is " . length($compressed) ;
    ok 1, "Fingerprint size is $fingerprint_size" ;
    ok 1, "Header size is $header_size" ;
    ok 1, "Trailer size is $trailer_size" ;

    for my $trans ( 0 .. 1)
    {
        title "Truncating $CompressClass, Transparent $trans";


        foreach my $i (1 .. $fingerprint_size-1)
        {
            my $lex = new LexFile my $name ;
        
            title "Fingerprint Truncation - length $i";

            my $part = substr($compressed, 0, $i);
            writeFile($name, $part);

            my $gz = new $UncompressClass $name,
                                          -BlockSize   => $blocksize,
                                          -Transparent => $trans;
            if ($trans) {
                ok $gz;
                ok ! $gz->error() ;
                my $buff ;
                ok $gz->read($buff) == length($part) ;
                ok $buff eq $part ;
                ok $gz->eof() ;
                $gz->close();
            }
            else {
                ok !$gz;
            }

        }

        #
        # Any header corruption past the fingerprint is considered catastrophic
        # so even if Transparent is set, it should still fail
        #
        foreach my $i ($fingerprint_size .. $header_size -1)
        {
            my $lex = new LexFile my $name ;
        
            title "Header Truncation - length $i";

            my $part = substr($compressed, 0, $i);
            writeFile($name, $part);
            ok ! defined new $UncompressClass $name,
                                              -BlockSize   => $blocksize,
                                              -Transparent => $trans;
            #ok $gz->eof() ;
        }

        
        foreach my $i ($header_size .. length($compressed) - 1 - $trailer_size)
        {
            my $lex = new LexFile my $name ;
        
            title "Compressed Data Truncation - length $i";

            my $part = substr($compressed, 0, $i);
            writeFile($name, $part);
            ok my $gz = new $UncompressClass $name,
                                             -BlockSize   => $blocksize,
                                             -Transparent => $trans;
            my $un ;
            my $status = 0 ;
            $status = $gz->read($un) while $status >= 0 ;
            ok $status < 0 ;
            ok $gz->eof() ;
            ok $gz->error() ;
            $gz->close();
        }
        
        # RawDeflate does not have a trailer
        next if $CompressClass eq 'IO::Compress::RawDeflate' ;

        title "Compressed Trailer Truncation";
        foreach my $i (length($compressed) - $trailer_size .. length($compressed) -1 )
        {
            foreach my $lax (0, 1)
            {
                my $lex = new LexFile my $name ;
            
                ok 1, "Length $i, Lax $lax" ;
                my $part = substr($compressed, 0, $i);
                writeFile($name, $part);
                ok my $gz = new $UncompressClass $name,
                                                 -BlockSize   => $blocksize,
                                                 -Strict      => !$lax,
                                                 -Append      => 1,   
                                                 -Transparent => $trans;
                my $un = '';
                my $status = 1 ;
                $status = $gz->read($un) while $status > 0 ;

                if ($lax)
                {
                    is $un, $hello;
                    is $status, 0 
                        or diag "Status $status Error is " . $gz->error() ;
                    ok $gz->eof()
                        or diag "Status $status Error is " . $gz->error() ;
                    ok ! $gz->error() ;
                }
                else
                {
                    ok $status < 0 
                        or diag "Status $status Error is " . $gz->error() ;
                    ok $gz->eof()
                        or diag "Status $status Error is " . $gz->error() ;
                    ok $gz->error() ;
                }
                
                $gz->close();
            }
        }
    }
}

1;

__END__


foreach my $CompressClass ( 'IO::Compress::RawDeflate')
{
    my $UncompressClass = getInverse($CompressClass);
    my $Error = getErrorRef($UncompressClass);

    my $compressed ;
        ok( my $x = new IO::Compress::RawDeflate \$compressed);
        ok $x->write($hello) ;
        ok $x->close ;

                           
    my $cc = $compressed ;

    my $gz ;
    ok($gz = new $UncompressClass(\$cc,
                                  -Transparent => 0))
            or diag "$$Error\n";
    my $un;
    ok $gz->read($un) > 0 ;
    ok $gz->close();
    ok $un eq $hello ;
    
    for my $trans (0 .. 1)
    {
        title "Testing $CompressClass, Transparent = $trans";

        my $info = $gz->getHeaderInfo() ;
        my $header_size = $info->{HeaderLength};
        my $trailer_size = $info->{TrailerLength};
        ok 1, "Compressed size is " . length($compressed) ;
        ok 1, "Header size is $header_size" ;
        ok 1, "Trailer size is $trailer_size" ;

        
        title "Compressed Data Truncation";
        foreach my $i (0 .. $blocksize)
        {
        
            my $lex = new LexFile my $name ;
        
            ok 1, "Length $i" ;
            my $part = substr($compressed, 0, $i);
            writeFile($name, $part);
            my $gz = new $UncompressClass $name,
                                       -BlockSize   => $blocksize,
                                       -Transparent => $trans;
            if ($trans) {
                ok $gz;
                ok ! $gz->error() ;
                my $buff = '';
                is $gz->read($buff), length $part ;
                is $buff, $part ;
                ok $gz->eof() ;
                $gz->close();
            }
            else {
                ok !$gz;
            }
        }

        foreach my $i ($blocksize+1 .. length($compressed)-1)
        {
        
            my $lex = new LexFile my $name ;
        
            ok 1, "Length $i" ;
            my $part = substr($compressed, 0, $i);
            writeFile($name, $part);
            ok my $gz = new $UncompressClass $name,
                                             -BlockSize   => $blocksize,
                                             -Transparent => $trans;
            my $un ;
            my $status = 0 ;
            $status = $gz->read($un) while $status >= 0 ;
            ok $status < 0 ;
            ok $gz->eof() ;
            ok $gz->error() ;
            $gz->close();
        }
    }
    
}

