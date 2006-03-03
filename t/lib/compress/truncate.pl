
use lib 't';
use strict;
use warnings;
use bytes;

use Test::More ;
use CompTestUtils;

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
        
            title "Fingerprint Truncation - length $i, Transparent $trans";

            my $part = substr($compressed, 0, $i);
            writeFile($name, $part);

            my $gz = new $UncompressClass $name,
                                          -BlockSize   => $blocksize,
                                          -Transparent => $trans;
            if ($trans) {
                ok $gz;
                ok ! $gz->error() ;
                my $buff ;
                is $gz->read($buff), length($part) ;
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
        
            title "Header Truncation - length $i, Transparent $trans";

            my $part = substr($compressed, 0, $i);
            writeFile($name, $part);
            ok ! defined new $UncompressClass $name,
                                              -BlockSize   => $blocksize,
                                              -Transparent => $trans;
            #ok $gz->eof() ;
        }

        
        foreach my $i ($header_size .. length($compressed) - 1 - $trailer_size)
        {
            next if $i == 0 ;

            my $lex = new LexFile my $name ;
        
            title "Compressed Data Truncation - length $i, Transparent $trans";

            my $part = substr($compressed, 0, $i);
            writeFile($name, $part);
            ok my $gz = new $UncompressClass $name,
                                             -Strict      => 1,
                                             -BlockSize   => $blocksize,
                                             -Transparent => $trans
                 or diag $$UnError;

            my $un ;
            my $status = 1 ;
            $status = $gz->read($un) while $status > 0 ;
            cmp_ok $status, "<", 0 ;
            ok $gz->error() ;
            ok $gz->eof() ;
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
            
                ok 1, "Compressed Trailer Truncation - Length $i, Lax $lax, Transparent $trans" ;
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
                    cmp_ok $status, "<", 0 
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

