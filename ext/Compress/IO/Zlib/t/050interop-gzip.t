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
    for my $dir (reverse split ":", $ENV{PATH})
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

    my $lex = new LexFile my $outfile;

    my $comp = "$GZIP -dc" ;

    #diag "$comp $file >$outfile" ;

    system("$comp $file >$outfile") == 0
        or die "'$comp' failed: $?";

    $_[0] = readFile($outfile);

    return 1 ;
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

    my $lex = new LexFile my $infile;
    writeFile($infile, $content);

    unlink $file ;
    my $gzip = "$GZIP -c $options $infile >$file" ;

    system($gzip) == 0 
        or die "'$gzip' failed: $?";

    return 1 ;
}


{
    title "Test interop with $GZIP" ;

    my $file;
    my $file1;
    my $lex = new LexFile $file, $file1;
    my $content = qq {
Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Ut tempus odio id
 dolor. Camelus perlus.  Larrius in lumen numen.  Dolor en quiquum filia
 est.  Quintus cenum parat.
};
    my $got;

    is writeWithGzip($file, $content), 1, "writeWithGzip ok";

    gunzip $file => \$got ;
    is $got, $content, "got content";


    gzip \$content => $file1;
    $got = '';
    is readWithGzip($file1, $got), 1, "readWithGzip ok";
    is $got, $content, "got content";
}


