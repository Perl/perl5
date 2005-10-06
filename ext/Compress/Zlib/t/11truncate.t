BEGIN {
    if ($ENV{PERL_CORE}) {
	chdir 't' if -d 't';
	@INC = ("../lib", "lib");
    }
}

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

    use_ok('Compress::Zlib', 2) ;

    use_ok('IO::Compress::Gzip', qw($GzipError)) ;
    use_ok('IO::Uncompress::Gunzip', qw($GunzipError)) ;

    use_ok('IO::Compress::Deflate', qw($DeflateError)) ;
    use_ok('IO::Uncompress::Inflate', qw($InflateError)) ;

    use_ok('IO::Compress::RawDeflate', qw($RawDeflateError)) ;
    use_ok('IO::Uncompress::RawInflate', qw($RawInflateError)) ;

}


my $hello = <<EOM ;
hello world
this is a test
some more stuff on this line
ad finally...
EOM

my $blocksize = 10 ;


foreach my $CompressClass ('IO::Compress::Gzip', 'IO::Compress::Deflate')
{
    my $UncompressClass = getInverse($CompressClass);


    my $compressed ;
    my $cc ;
    my $gz ;
    if ($CompressClass eq 'IO::Compress::Gzip') {
        ok( my $x = new IO::Compress::Gzip \$compressed, 
                                 -Name       => "My name",
                                 -Comment    => "a comment",
                                 -ExtraField => ['ab' => "extra"],
                                 -HeaderCRC  => 1); 
        ok $x->write($hello) ;
        ok $x->close ;
        $cc = $compressed ;

        ok($gz = new IO::Uncompress::Gunzip \$cc,
                                -Transparent => 0)
                or diag "$GunzipError";
        my $un;
        ok $gz->read($un) > 0 ;
        ok $gz->close();
        ok $un eq $hello ;
    }
    else {
        ok( my $x = new $CompressClass(\$compressed));
        ok $x->write($hello) ;
        ok $x->close ;
        $cc = $compressed ;

        ok($gz = new $UncompressClass(\$cc,
                                      -Transparent => 0))
                or diag "$GunzipError";
        my $un;
        ok $gz->read($un) > 0 ;
        ok $gz->close();
        ok $un eq $hello ;
    }

                           
    for my $trans ( 0 .. 1)
    {
        title "Testing $CompressClass, Transparent $trans";

        my $info = $gz->getHeaderInfo() ;
        my $header_size = $info->{HeaderLength};
        my $trailer_size = $info->{TrailerLength};
        ok 1, "Compressed size is " . length($compressed) ;
        ok 1, "Header size is $header_size" ;
        ok 1, "Trailer size is $trailer_size" ;

        title "Fingerprint Truncation";
        foreach my $i (1)
        {
            my $name = "test.gz" ;
            unlink $name ;
            my $lex = new LexFile $name ;
        
            ok 1, "Length $i" ;
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

        title "Header Truncation";
        #
        # Any header corruption past the fingerprint is considered catastrophic
        # so even if Transparent is set, it should still fail
        #
        foreach my $i (2 .. $header_size -1)
        {
            my $name = "test.gz" ;
            unlink $name ;
            my $lex = new LexFile $name ;
        
            ok 1, "Length $i" ;
            my $part = substr($compressed, 0, $i);
            writeFile($name, $part);
            ok ! defined new $UncompressClass $name,
                                              -BlockSize   => $blocksize,
                                              -Transparent => $trans;
            #ok $gz->eof() ;
        }
        
        title "Compressed Data Truncation";
        foreach my $i ($header_size .. length($compressed) - 1 - $trailer_size)
        {
        
            my $name = "test.gz" ;
            unlink $name ;
            my $lex = new LexFile $name ;
        
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
        
        # RawDeflate does not have a trailer
        next if $CompressClass eq 'IO::Compress::RawDeflate' ;

        title "Compressed Trailer Truncation";
        foreach my $i (length($compressed) - $trailer_size .. length($compressed) -1 )
        {
            foreach my $lax (0, 1)
            {
                my $name = "test.gz" ;
                unlink $name ;
                my $lex = new LexFile $name ;
            
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
        
            my $name = "test.gz" ;
            unlink $name ;
            my $lex = new LexFile $name ;
        
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
                ok $gz->read($buff) == length $part ;
                ok $buff eq $part ;
                ok $gz->eof() ;
                $gz->close();
            }
            else {
                ok !$gz;
            }
        }

        foreach my $i ($blocksize+1 .. length($compressed)-1)
        {
        
            my $name = "test.gz" ;
            unlink $name ;
            my $lex = new LexFile $name ;
        
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

