

use strict ;
local ($^W) = 1; #use warnings ;

use Compress::Zlib ;

sub ok
{
    my ($no, $ok) = @_ ;

    #++ $total ;
    #++ $totalBad unless $ok ;

    print "ok $no\n" if $ok ;
    print "not ok $no\n" unless $ok ;
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

my $hello = <<EOM ;
hello world
this is a test
EOM

my $len   = length $hello ;


print "1..23\n" ;

# Check zlib_version and ZLIB_VERSION are the same.
ok(1, Compress::Zlib::zlib_version eq ZLIB_VERSION) ;


# gzip - filehandle tests
# ========================

{
  use IO::File ;
  my $filename = "fh.gz" ;
  my $hello = "hello, hello, I'm back again" ;
  my $len = length $hello ;

  my $f = new IO::File ">$filename" ;
  binmode $f ; # for OS/2

  ok(2, $f) ;

  my $line_one =  "first line\n" ;
  print $f $line_one;
  
  ok(3, my $fil = gzopen($f, "wb")) ;
 
  ok(4, $fil->gzwrite($hello) == $len) ;
 
  ok(5, ! $fil->gzclose ) ;

 
  ok(6, my $g = new IO::File "<$filename") ;
  binmode $g ; # for OS/2
 
  my $first ;
  my $ret = read($g, $first, length($line_one));
  ok(7, $ret == length($line_one));

  ok(8, $first eq $line_one) ;

  ok(9, $fil = gzopen($g, "rb") ) ;
  my $uncomp;
  ok(10, (my $x = $fil->gzread($uncomp)) == $len) ;
 
  ok(11, ! $fil->gzclose ) ;
 
  unlink $filename ;
 
  ok(12, $hello eq $uncomp) ;

}

{
  my $filename = "fh.gz" ;
  my $hello = "hello, hello, I'm back again" ;
  my $len = length $hello ;
  my $uncomp;
  local (*FH1) ;
  local (*FH2) ;
 
  ok(13, open FH1, ">$filename") ;
  binmode FH1; # for OS/2
 
  my $line_one =  "first line\n" ;
  print FH1 $line_one;
 
  ok(14, my $fil = gzopen(\*FH1, "wb")) ;
 
  ok(15, $fil->gzwrite($hello) == $len) ;
 
  ok(16, ! $fil->gzclose ) ;
 
 
  ok(17, my $g = open FH2, "<$filename") ;
  binmode FH2; # for OS/2
 
  my $first ;
  my $ret = read(FH2, $first, length($line_one));
  ok(18, $ret == length($line_one));
 
  ok(19, $first eq $line_one) ;
 
  ok(20, $fil = gzopen(*FH2, "rb") ) ;
  ok(21, (my $x = $fil->gzread($uncomp)) == $len) ;
 
  ok(22, ! $fil->gzclose ) ;
 
  unlink $filename ;
 
  ok(23, $hello eq $uncomp) ;
 
}

