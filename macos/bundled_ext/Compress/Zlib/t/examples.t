use File::Spec::Functions;
use strict ;
use warnings ;

sub ok
{
    my ($no, $ok) = @_ ;

    #++ $total ;
    #++ $totalBad unless $ok ;

    print "ok $no\n" if $ok ;
    print "not ok $no\n" unless $ok ;
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
 

my $Inc = '' ;
foreach (@INC)
 { $Inc .= "-I$_ " }
 
my $Perl = '' ;
$Perl = ($ENV{'FULLPERL'} or $^X or 'perl') ;
 
$Perl = "$Perl -w" ;
my $examples = catdir(curdir(), "examples");

(my $hello1 = <<EOM) =~ s/\n/\012/g;
hello
this is 
a test
message
x ttttt
xuuuuuu
the end
EOM

my @hello1 = grep(s/$/\n/, split(/\n/, $hello1)) ;

(my $hello2 = <<EOM) =~ s/\n/\012/g;

Howdy
this is the
second
file
x ppppp
xuuuuuu
really the end
EOM

my @hello2 = grep(s/$/\n/, split(/\n/, $hello2)) ;

print "1..13\n" ;



# gzcat
# #####

my $file1 = "hello1.gz" ;
my $file2 = "hello2.gz" ;
unlink $file1, $file2 ;

my $hello1_uue = <<'EOM';
M'XL("(W#+3$" VAE;&QO,0#+2,W)R><JR<@L5@ BKD2%DM3B$J[<U.+BQ/14
;K@J%$A#@JB@% Z"Z5(74O!0N &D:".,V    
EOM

my $hello2_uue = <<'EOM';
M'XL("*[#+3$" VAE;&QO,@#C\L@O3ZGD*LG(+%8 HI*,5*[BU.3\O!2NM,R<
A5*X*A0(0X*HH!0.NHM3$G)Q*D#*%5* : #) E6<^    
EOM

# Write a test .gz file
{
    #local $^W = 0 ;
    writeFile($file1, unpack("u", $hello1_uue)) ;
    writeFile($file2, unpack("u", $hello2_uue)) ;
}

my $redir = $^O eq "MacOS" ? "" : "2>&1";
my $path = catfile($examples, "gzcat");
$a = `$Perl $Inc $path $file1 $file2 $redir` ;

ok(1, $? == 0) ;
ok(2, $a eq $hello1 . $hello2) ;
#print "? = $? [$a]\n";


# gzgrep
# ######

$path = catfile($examples, "gzgrep");
$a = ($^O eq 'MSWin32'
     ? `$Perl $Inc $path "^x" $file1 $file2 $redir`
     : `$Perl $Inc $path '^x' $file1 $file2 $redir`) ;
ok(3, $? == 0) ;

ok(4, $a eq join('', grep(/^x/, @hello1, @hello2))) ;
#print "? = $? [$a]\n";


unlink $file1, $file2 ;


# filtdef/filtinf
# ##############


my $stderr = "err.out" ;
unlink $stderr ;
writeFile($file1, $hello1) ;
writeFile($file2, $hello2) ;

# there's no way to set binmode on backticks in Win32 so we won't use $a later
my $redir2 = $^O eq "MacOS" ? "³$stderr" : "2>$stderr";
$path = catfile($examples, "filtdef");
$a = `$Perl $Inc $path $file1 $file2 $redir2` ;
ok(5, $? == 0) ;
ok(6, -s $stderr == 0) ;

unlink $stderr;
my $path2 = catfile($examples, "filtinf");
my $cmd = "$Perl $Inc $path $file1 $file2 | $Perl $Inc $path2 $redir2";
if ($^O eq "MacOS") {
    ok(7, 1);
    ok(8, 1);
    ok(9, 1);
    if (0) { # 1 for manual running
	print "Run manually:\n";
	print "$cmd\n";
	print "$hello1$hello2\n";
	exit;
    }
} else {
    $a = `$cmd`;
    ok(7, $? == 0) ;
    ok(8, -s $stderr == 0) ;
    ok(9, $a eq $hello1 . $hello2) ;
}

# gzstream
# ########

{
    writeFile($file1, $hello1) ;
    $path = catfile($examples, "gzstream");
    $a = `$Perl $Inc $path <$file1 >$file2 $redir2` ;
    ok(10, $? == 0) ;
    ok(11, -s $stderr == 0) ;

    $path = catfile($examples, "gzcat");
    my $b = `$Perl $Inc $path $file2 $redir` ;
    ok(12, $? == 0) ;
    ok(13, $b eq $hello1 ) ;
}


unlink $file1, $file2, $stderr ;
