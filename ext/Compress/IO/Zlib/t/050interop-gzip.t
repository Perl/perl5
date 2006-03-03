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

my $GZIP ;

BEGIN {

    # Check external gzip is available
    my $name = 'gzip';
    for my $dir (split ":", $ENV{PATH})
    {
        $GZIP = "$dir/$name"
            if -x "$dir/$name" ;
    }

    plan(skip_all => "Cannot find $name")
        if ! $GZIP ;

    
    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 7 + $extra ;

    use_ok('IO::Compress::Gzip',     ':all') ;
    use_ok('IO::Uncompress::Gunzip', ':all') ;

}

use CompTestUtils;

sub readWithGzip
{
    my $file = shift ;

    my $comp = "$GZIP -dc" ;

    open F, "$comp $file |";
    local $/;
    $_[0] = <F>;
    close F;

    return $? ;
}

sub getGzipInfo
{
    my $file = shift ;
}

sub writeWithGzip
{
    my $file = shift ;
    my $content = shift ;
    my $options = shift || '';

    unlink $file ;
    my $gzip = "$GZIP -c $options >$file" ;

    open F, "| $gzip" ;
    print F $content ;
    close F ;

    return $? ;
}


{
    title "Test interop with $GZIP" ;

    my $file;
    my $file1;
    my $lex = new LexFile $file, $file1;
    my $content = "hello world\n" ;
    my $got;

    is writeWithGzip($file, $content), 0, "writeWithGzip ok";

    gunzip $file => \$got ;
    is $got, $content;


    gzip \$content => $file1;
    $got = '';
    is readWithGzip($file1, $got), 0, "readWithGzip returns 0";
    is $got, $content, "got content";
}


