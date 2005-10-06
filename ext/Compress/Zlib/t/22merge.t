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

our ($extra);
use Compress::Zlib 2 ;

use IO::Compress::Gzip qw($GzipError);
use IO::Uncompress::Gunzip qw($GunzipError);

use IO::Compress::Deflate qw($DeflateError);
use IO::Uncompress::Inflate qw($InflateError);

use IO::Compress::RawDeflate qw($RawDeflateError);
use IO::Uncompress::RawInflate qw($RawInflateError);


BEGIN 
{ 
    plan(skip_all => "Merge needs Zlib 1.2.1 or better - you have Zlib "  
                . Compress::Zlib::zlib_version()) 
        if ZLIB_VERNUM() < 0x1210 ;

    # use Test::NoWarnings, if available
    $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 490 + $extra ;

}


# Check zlib_version and ZLIB_VERSION are the same.
is Compress::Zlib::zlib_version, ZLIB_VERSION, 
    "ZLIB_VERSION matches Compress::Zlib::zlib_version" ;

# Tests     
#   destination is a file that doesn't exist -- should work ok unless AnyDeflate
#   destination isn't compressed at all
#   destination is compressed but wrong format
#   destination is corrupt - error messages should be correct
#   use apend mode with old zlib - check that this is trapped
#   destination is not seekable, readable, writable - test for filename & handle

{
    title "Misc error cases";

    eval { new Compress::Zlib::InflateScan Bufsize => 0} ;
    like $@, mkErr("^Compress::Zlib::InflateScan::new: Bufsize must be >= 1, you specified 0"), "  catch bufsize == 0";

    eval { Compress::Zlib::inflateScanStream::createDeflateStream(undef, Bufsize => 0) } ;
    like $@, mkErr("^Compress::Zlib::InflateScan::createDeflateStream: Bufsize must be >= 1, you specified 0"), "  catch bufsize == 0";

}

# output file/handle not writable
foreach my $CompressClass ( map { "IO::Compress::$_" } qw( Gzip RawDeflate Deflate) )
{

    my $Error = getErrorRef($CompressClass);

    foreach my $to_file (0,1)
    {
        if ($to_file)
          { title "$CompressClass - Merge to filename that isn't writable" }
        else  
          { title "$CompressClass - Merge to filehandle that isn't writable" }

        my $out_file = 'abcde.out';
        my $lex = new LexFile($out_file) ;

        # create empty file
        open F, ">$out_file" ; print F "x"; close F;
        ok   -e $out_file, "  file exists" ;
        ok  !-z $out_file, "  and is not empty" ;
        
        # make unwritable
        is chmod(0444, $out_file), 1, "  chmod worked" ;
        ok   -e $out_file, "  still exists after chmod" ;

        SKIP:
        {
            skip "Cannot create non-writable file", 3 
                if -w $out_file ;

            ok ! -w $out_file, "  chmod made file unwritable" ;

            my $dest ;
            if ($to_file)
              { $dest = $out_file }
            else
              { $dest = new IO::File "<$out_file"  }

            my $gz = $CompressClass->new($dest, Merge => 1) ;
            
            ok ! $gz, "  Did not create $CompressClass object";

            {
                if ($to_file) {
                    is $$Error, "Output file '$out_file' is not writable",
                            "  Got non-writable filename message" ;
                }
                else {
                    is $$Error, "Output filehandle is not writable",
                            "  Got non-writable filehandle message" ;
                }
            }
        }

        chmod 0777, $out_file ;
    }
}

# output is not compressed at all
foreach my $CompressClass ( map { "IO::Compress::$_" } qw( Gzip RawDeflate Deflate) )
{

    my $Error = getErrorRef($CompressClass);

    my $out_file = 'abcde.out';
    my $lex = new LexFile($out_file) ;

    foreach my $to_file ( qw(buffer file handle ) )
    {
        title "$CompressClass to $to_file, content is not compressed";

        my $content = "abc" x 300 ;
        my $buffer ;
        my $disp_content = defined $content ? $content : '<undef>' ;
        my $str_content = defined $content ? $content : '' ;

        if ($to_file eq 'buffer')
        {
            $buffer = \$content ;
        }
        else
        {
            writeFile($out_file, $content);

            if ($to_file eq 'handle')
            {
                $buffer = new IO::File "+<$out_file" 
                    or die "# Cannot open $out_file: $!";
            }
            else
              { $buffer = $out_file }
        }

        ok ! $CompressClass->new($buffer, Merge => 1), "  constructor fails";
        {
            like $$Error, '/Cannot create InflateScan object: (Header Error|unexpected end of file)/', "  got Bad Magic" ;
        }

    }
}

# output is empty
foreach my $CompressClass ( map { "IO::Compress::$_" } qw( Gzip RawDeflate Deflate) )
{

    my $Error = getErrorRef($CompressClass);

    my $out_file = 'abcde.out';
    my $lex = new LexFile($out_file) ;

    foreach my $to_file ( qw(buffer file handle ) )
    {
        title "$CompressClass to $to_file, content is empty";

        my $content = '';
        my $buffer ;
        my $dest ;

        if ($to_file eq 'buffer')
        {
            $dest = $buffer = \$content ;
        }
        else
        {
            writeFile($out_file, $content);
            $dest = $out_file;

            if ($to_file eq 'handle')
            {
                $buffer = new IO::File "+<$out_file" 
                    or die "# Cannot open $out_file: $!";
            }
            else
              { $buffer = $out_file }
        }

        ok my $gz = $CompressClass->new($buffer, Merge => 1, AutoClose => 1), "  constructor passes";

        $gz->write("FGHI");
        $gz->close();

        #hexDump($buffer);
        my $out = anyUncompress($dest);

        is $out, "FGHI", '  Merge OK';
    }
}

foreach my $CompressClass ( map { "IO::Compress::$_" } qw( Gzip RawDeflate Deflate) )
{
    my $Error = getErrorRef($CompressClass);

    title "$CompressClass - Merge to file that doesn't exist";

    my $out_file = 'abcd.out';
    my $lex = new LexFile($out_file) ;
    
    ok ! -e $out_file, "  Destination file, '$out_file', does not exist";

    ok my $gz1 = $CompressClass->new($out_file, Merge => 1)
        or die "# $CompressClass->new failed: $GzipError\n";
    #hexDump($buffer);
    $gz1->write("FGHI");
    $gz1->close();

    #hexDump($buffer);
    my $out = anyUncompress($out_file);

    is $out, "FGHI", '  Merged OK';
}

foreach my $CompressClass ( map { "IO::Compress::$_" } qw( Gzip RawDeflate Deflate) )
{
    my $Error = getErrorRef($CompressClass);

    my $out_file = 'abcde.out';
    my $lex = new LexFile($out_file) ;

    foreach my $to_file ( qw( buffer file handle ) )
    {
        foreach my $content (undef, '', 'x', 'abcde')
        {
            #next if ! defined $content && $to_file; 

            my $buffer ;
            my $disp_content = defined $content ? $content : '<undef>' ;
            my $str_content = defined $content ? $content : '' ;

            if ($to_file eq 'buffer')
            {
                my $x ;
                $buffer = \$x ;
                title "$CompressClass to Buffer, content is '$disp_content'";
            }
            else
            {
                $buffer = $out_file ;
                if ($to_file eq 'handle')
                {
                    title "$CompressClass to Filehandle, content is '$disp_content'";
                }
                else
                {
                    title "$CompressClass to File, content is '$disp_content'";
                }
            }

            my $gz = $CompressClass->new($buffer);
            my $len = defined $content ? length($content) : 0 ;
            is $gz->write($content), $len, "  write ok";
            ok $gz->close(), " close ok";

            #hexDump($buffer);
            is anyUncompress($buffer), $str_content, '  Destination is ok';

            #if ($corruption)
            #{
                #    next if $TopTypes eq 'RawDeflate' && $content eq '';
                #
                #}

            my $dest = $buffer ;    
            if ($to_file eq 'handle')
            {
                $dest = new IO::File "+<$buffer" ;
            }

            my $gz1 = $CompressClass->new($dest, Merge => 1, AutoClose => 1)
                or die "## $GzipError\n";
            #print "YYY\n";
            #hexDump($buffer);
            #print "XXX\n";
            is $gz1->write("FGHI"), 4, "  write returned 4";
            ok $gz1->close(), "  close ok";

            #hexDump($buffer);
            my $out = anyUncompress($buffer);

            is $out, $str_content . "FGHI", '  Merged OK';
            #exit;
        }
    }

}


foreach my $CompressClass ( map { "IO::Compress::$_" } qw( Gzip RawDeflate Deflate) )
{
    my $Error = getErrorRef($CompressClass);

    my $Func = getTopFuncRef($CompressClass);
    my $TopType = getTopFuncName($CompressClass);

    my $buffer ;

    my $out_file = 'abcde.out';
    my $lex = new LexFile($out_file) ;

    foreach my $to_file (0, 1)
    {
        foreach my $content (undef, '', 'x', 'abcde')
        {
            my $disp_content = defined $content ? $content : '<undef>' ;
            my $str_content = defined $content ? $content : '' ;
            my $buffer ;
            if ($to_file)
            {
                $buffer = $out_file ;
                title "$TopType to File, content is '$disp_content'";
            }
            else
            {
                my $x = '';
                $buffer = \$x ;
                title "$TopType to Buffer, content is '$disp_content'";
            }
            

            ok $Func->(\$content, $buffer), " Compress content";
            #hexDump($buffer);
            is anyUncompress($buffer), $str_content, '  Destination is ok';


            ok $Func->(\"FGHI", $buffer, Merge => 1), "  Merge content";

            #hexDump($buffer);
            my $out = anyUncompress($buffer);

            is $out, $str_content . "FGHI", '  Merged OK';
        }
    }

}



