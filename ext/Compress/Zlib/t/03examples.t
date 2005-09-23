
use strict ;
use warnings ;

use Compress::Zlib;

my $count = 0 ;
sub ok
{
    my $ok = shift ;

    #++ $total ;
    #++ $totalBad unless $ok ;
    ++ $count;

    print "ok $count\n" if $ok ;
    print "not ok $count\n" unless $ok ;
    #printf "# Failed test at line %d\n", (caller)[2] unless $ok ;

    $ok;
}

sub writeFile
{
    my($filename, @strings) = @_ ;
    open (F, ">$filename") 
        or die "Cannot open $filename: $!\n" ;
    binmode(F);
    foreach (@strings)
      { print F }
    close F ;
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

sub diag
{
    my $msg = shift ;
    $msg =~ s/^/# /mg;
    #$msg =~ s/\n+$//;
    $msg .= "\n" unless $msg =~ /\n\Z/;
    print $msg;
}
 
sub check
{
    my $command = shift ;
    my $expected = shift ;

    my $stderr = 'err.out';
    unlink $stderr;

    my $cmd = "$command 2>$stderr";
    my $stdout = `$cmd` ;

    my $aok = 1 ;

    $aok &= ok $? == 0
        or diag "  exit status is $?" ;

    $aok &= ok readFile($stderr) eq ''
        or diag "Stderr is: " .  readFile($stderr);

    if (defined $expected ) {
        $aok &= ok $stdout eq $expected 
            or diag "got content:\n". $stdout;
    }

    if (! $aok) {
        diag "Command line: $cmd";
        my ($file, $line) = (caller)[1,2];
        diag "Test called from $file, line $line";
    }

    unlink $stderr;
}



my $Inc = join " ", map qq["-I$_"] => @INC;
$Inc = '"-MExtUtils::testlib"'
    if ! $ENV{PERL_CORE} && eval "require ExtUtils::testlib;" ;

my $Perl = '' ;
$Perl = ($ENV{'FULLPERL'} or $^X or 'perl') ;
$Perl = qq["$Perl"] if $^O eq 'MSWin32' ;
 
$Perl = "$Perl -w $Inc" ;
my $examples = $ENV{PERL_CORE} ? "../ext/Compress/Zlib/examples" 
                               : "./examples";

my $hello1 = <<EOM ;
hello
this is 
a test
message
x ttttt
xuuuuuu
the end
EOM

my @hello1 = grep(s/$/\n/, split(/\n/, $hello1)) ;

my $hello2 = <<EOM;

Howdy
this is the
second
file
x ppppp
xuuuuuu
really the end
EOM

my @hello2 = grep(s/$/\n/, split(/\n/, $hello2)) ;

my $file1 = "hello1.gz" ;
my $file2 = "hello2.gz" ;
my $stderr = "err.out" ;
unlink $stderr ;

my $gz = gzopen($file1, "wb");
$gz->gzwrite($hello1);
$gz->gzclose();

$gz = gzopen($file2, "wb");
$gz->gzwrite($hello2);
$gz->gzclose();

print "1..16\n" ;



# gzcat
# #####

check "$Perl ${examples}/gzcat $file1 $file2", $hello1 . $hello2 ;

# gzgrep
# ######

check "$Perl ${examples}/gzgrep the $file1 $file2",
        join('', grep(/the/, @hello1, @hello2));


unlink $file1, $file2 ;


# filtdef/filtinf
# ##############


writeFile($file1, $hello1) ;
writeFile($file2, $hello2) ;

# there's no way to set binmode on backticks in Win32 so we won't use $a later
check "$Perl ${examples}/filtdef $file1 $file2"; ;

check "$Perl ${examples}/filtdef $file1 $file2 | $Perl ${examples}/filtinf 2>$stderr", $hello1 . $hello2;

# gzstream
# ########

{
    writeFile($file1, $hello1) ;
    check "$Perl ${examples}/gzstream <$file1 >$file2" ;

    check "$Perl ${examples}/gzcat $file2", $hello1;

}


END
{
    for ($file1, $file2, $stderr) { 1 while unlink $_ } ;
}
