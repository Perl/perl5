BEGIN {
    if ($ENV{PERL_CORE}) {
	chdir 't' if -d 't';
	@INC = '../lib';
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

    plan tests => 10612 + $extra ;


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

foreach my $CompressClass ('IO::Compress::Gzip',
                           'IO::Compress::Deflate',
                           'IO::Compress::RawDeflate',
                          )
{
    my $UncompressClass = getInverse($CompressClass);


    print "#\n# Testing $UncompressClass\n#\n";

    my $compressed ;
    my $cc ;
    my $gz ;
    my $hsize ;
    if ($CompressClass eq 'IO::Compress::Gzip') {
        ok( my $x = new IO::Compress::Gzip \$compressed, 
                                 -Name       => "My name",
                                 -Comment    => "this is a comment",
                                 -ExtraField => [ 'ab' => "extra"],
                                 -HeaderCRC  => 1); 
        ok $x->write($hello) ;
        ok $x->close ;
        $cc = $compressed ;

	#hexDump($compressed) ;

        ok($gz = new IO::Uncompress::Gunzip \$cc,
                               #-Strict      => 1,
                                -Transparent => 0)
                or print "$GunzipError\n";
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
                or print "$GunzipError\n";
        my $un;
        ok $gz->read($un) > 0 ;
        ok $gz->close();
        ok $un eq $hello ;
    }

    for my $blocksize (1,2,13)
    {
        for my $i (0 .. length($compressed) - 1)
        {
            for my $useBuf (0 .. 1)
            {
                print "#\n# BlockSize $blocksize, Length $i, Buffer $useBuf\n#\n" ;
                my $name = "test.gz" ;
                unlink $name ;
                my $lex = new LexFile $name ;
        
                my $prime = substr($compressed, 0, $i);
                my $rest = substr($compressed, $i);
        
                my $start  ;
                if ($useBuf) {
                    $start = \$rest ;
                }
                else {
                    $start = $name ;
                    writeFile($name, $rest);
                }

                #my $gz = new $UncompressClass $name,
                my $gz = new $UncompressClass $start,
                                              -Append      => 1,
                                              -BlockSize   => $blocksize,
                                              -Prime       => $prime,
                                              -Transparent => 0
                                              ;
                ok $gz;
                ok ! $gz->error() ;
                my $un ;
                my $status = 1 ;
                $status = $gz->read($un) while $status > 0 ;
                ok $status == 0 
                    or print "status $status\n" ;
                ok ! $gz->error() 
                    or print "Error is '" . $gz->error() . "'\n";
                ok $un eq $hello 
                  or print "# got [$un]\n";
                ok $gz->eof() ;
                ok $gz->close() ;
            }
        }
    }
}
