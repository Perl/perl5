
use lib 't';
use strict;
use warnings;
use bytes;

use Test::More ;
use ZlibTestUtils;

BEGIN
{
    plan(skip_all => "Destroy not supported in Perl $]")
        if $] == 5.008 || ( $] >= 5.005 && $] < 5.006) ;

    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 23 + $extra ;

    use_ok('IO::Compress::Gzip', qw($GzipError)) ;
    use_ok('IO::Compress::Deflate', qw($DeflateError)) ;
    use_ok('IO::Uncompress::AnyInflate', qw($AnyInflateError)) ;
    use_ok('IO::Compress::RawDeflate', qw($RawDeflateError)) ;
    use_ok('IO::File') ;
}


foreach my $CompressClass ('IO::Compress::Gzip',     
                           'IO::Compress::Deflate', 
                           'IO::Compress::RawDeflate')
{
    title "Testing $CompressClass";


    {
        # Check that the class destructor will call close

        my $name = "test.gz" ;
        unlink $name ;
        my $lex = new LexFile $name ;

        my $hello = <<EOM ;
hello world
this is a test
EOM


        {
          ok my $x = new $CompressClass $name, -AutoClose => 1  ;

          ok $x->write($hello) ;
        }

        is anyUncompress($name), $hello ;
    }

    {
        # Tied filehandle destructor


        my $name = "test.gz" ;
        my $lex = new LexFile $name ;

        my $hello = <<EOM ;
hello world
this is a test
EOM

        my $fh = new IO::File "> $name" ;

        {
          ok my $x = new $CompressClass $fh, -AutoClose => 1  ;

          $x->write($hello) ;
        }

        ok anyUncompress($name) eq $hello ;
    }
}

