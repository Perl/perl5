
use strict ;
use warnings ;

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


print "1..166\n" ;

# Check zlib_version and ZLIB_VERSION are the same.
ok(1, Compress::Zlib::zlib_version eq ZLIB_VERSION) ;

# gzip tests
#===========

my $name = "test.gz" ;
my ($x, $uncomp) ;

ok(2, my $fil = gzopen($name, "wb")) ;

ok(3, $fil->gzwrite($hello) == $len) ;

ok(4, ! $fil->gzclose ) ;

ok(5, $fil = gzopen($name, "rb") ) ;

ok(6, ($x = $fil->gzread($uncomp)) == $len) ;

ok(7, ! $fil->gzclose ) ;

unlink $name ;

ok(8, $hello eq $uncomp) ;

# check that a number can be gzipped
my $number = 7603 ;
my $num_len = 4 ;

ok(9, $fil = gzopen($name, "wb")) ;

ok(10, $fil->gzwrite($number) == $num_len) ;

ok(11, ! $fil->gzclose ) ;

ok(12, $fil = gzopen($name, "rb") ) ;

ok(13, ($x = $fil->gzread($uncomp)) == $num_len) ;

ok(14, ! $fil->gzclose ) ;

unlink $name ;

ok(15, $number == $uncomp) ;
ok(16, $number eq $uncomp) ;


# now a bigger gzip test

my $text = 'text' ;
my $file = "$text.gz" ;

ok(17, my $f = gzopen($file, "wb")) ;

# generate a long random string
my $contents = '' ;
foreach (1 .. 5000)
  { $contents .= chr int rand 255 }

$len = length $contents ;

ok(18, $f->gzwrite($contents) == $len ) ;

ok(19, ! $f->gzclose );

ok(20, $f = gzopen($file, "rb")) ;
 
my $uncompressed ;
ok(21, $f->gzread($uncompressed, $len) == $len) ;

ok(22, $contents eq $uncompressed) ;

ok(23, ! $f->gzclose ) ;

unlink($file) ;

# gzip - readline tests
# ======================

# first create a small gzipped text file
$name = "test.gz" ;
my @text = (<<EOM, <<EOM, <<EOM, <<EOM) ;
this is line 1
EOM
the second line
EOM
the line after the previous line
EOM
the final line
EOM

$text = join("", @text) ;

ok(24, $fil = gzopen($name, "wb")) ;
ok(25, $fil->gzwrite($text) == length $text) ;
ok(26, ! $fil->gzclose ) ;

# now try to read it back in
ok(27, $fil = gzopen($name, "rb")) ;
my $aok = 1 ; 
my $remember = '';
my $line = '';
my $lines = 0 ;
while ($fil->gzreadline($line) > 0) {
    ($aok = 0), last
	if $line ne $text[$lines] ;
    $remember .= $line ;
    ++ $lines ;
}
ok(28, $aok) ;
ok(29, $remember eq $text) ;
ok(30, $lines == @text) ;
ok(31, ! $fil->gzclose ) ;
unlink($name) ;

# a text file with a very long line (bigger than the internal buffer)
my $line1 = ("abcdefghijklmnopq" x 2000) . "\n" ;
my $line2 = "second line\n" ;
$text = $line1 . $line2 ;
ok(32, $fil = gzopen($name, "wb")) ;
ok(33, $fil->gzwrite($text) == length $text) ;
ok(34, ! $fil->gzclose ) ;

# now try to read it back in
ok(35, $fil = gzopen($name, "rb")) ;
my $i = 0 ;
my @got = ();
while ($fil->gzreadline($line) > 0) {
    $got[$i] = $line ;    
    ++ $i ;
}
ok(36, $i == 2) ;
ok(37, $got[0] eq $line1 ) ;
ok(38, $got[1] eq $line2) ;

ok(39, ! $fil->gzclose ) ;

unlink $name ;

# a text file which is not termined by an EOL

$line1 = "hello hello, I'm back again\n" ;
$line2 = "there is no end in sight" ;

$text = $line1 . $line2 ;
ok(40, $fil = gzopen($name, "wb")) ;
ok(41, $fil->gzwrite($text) == length $text) ;
ok(42, ! $fil->gzclose ) ;

# now try to read it back in
ok(43, $fil = gzopen($name, "rb")) ;
@got = () ; $i = 0 ;
while ($fil->gzreadline($line) > 0) {
    $got[$i] = $line ;    
    ++ $i ;
}
ok(44, $i == 2) ;
ok(45, $got[0] eq $line1 ) ;
ok(46, $got[1] eq $line2) ;

ok(47, ! $fil->gzclose ) ;

unlink $name ;


# mix gzread and gzreadline <

# case 1: read a line, then a block. The block is
#         smaller than the internal block used by
#	  gzreadline
$line1 = "hello hello, I'm back again\n" ;
$line2 = "abc" x 200 ; 
my $line3 = "def" x 200 ;

$text = $line1 . $line2 . $line3 ;
ok(48, $fil = gzopen($name, "wb")) ;
ok(49, $fil->gzwrite($text) == length $text) ;
ok(50, ! $fil->gzclose ) ;

# now try to read it back in
ok(51, $fil = gzopen($name, "rb")) ;
ok(52, $fil->gzreadline($line) > 0) ;
ok(53, $line eq $line1) ;
ok(54, $fil->gzread($line, length $line2) > 0) ;
ok(55, $line eq $line2) ;
ok(56, $fil->gzread($line, length $line3) > 0) ;
ok(57, $line eq $line3) ;
ok(58, ! $fil->gzclose ) ;
unlink $name ;

# change $/ <<TODO

# gzip - filehandle tests
# ========================

{
  use IO::File ;
  my $filename = "fh.gz" ;
  my $hello = "hello, hello, I'm back again" ;
  my $len = length $hello ;

  my $f = new IO::File ">$filename" ;
  binmode $f ; # for OS/2

  ok(59, $f) ;

  print $f "first line\n" ;
  
  ok(60, $fil = gzopen($f, "wb")) ;
 
  ok(61, $fil->gzwrite($hello) == $len) ;
 
  ok(62, ! $fil->gzclose ) ;

 
  ok(63, my $g = new IO::File "<$filename") ;
  binmode $g ; # for OS/2
 
  my $first = <$g> ;

  ok(64, $first eq "first line\n") ;

  ok(65, $fil = gzopen($g, "rb") ) ;
  ok(66, ($x = $fil->gzread($uncomp)) == $len) ;
 
  ok(67, ! $fil->gzclose ) ;
 
  unlink $filename ;
 
  ok(68, $hello eq $uncomp) ;

}

{
  my $filename = "fh.gz" ;
  my $hello = "hello, hello, I'm back again" ;
  my $len = length $hello ;
  local (*FH1) ;
  local (*FH2) ;
 
  ok(69, open FH1, ">$filename") ;
  binmode FH1; # for OS/2
 
  print FH1 "first line\n" ;
 
  ok(70, $fil = gzopen(\*FH1, "wb")) ;
 
  ok(71, $fil->gzwrite($hello) == $len) ;
 
  ok(72, ! $fil->gzclose ) ;
 
 
  ok(73, my $g = open FH2, "<$filename") ;
  binmode FH2; # for OS/2
 
  my $first = <FH2> ;
 
  ok(74, $first eq "first line\n") ;
 
  ok(75, $fil = gzopen(*FH2, "rb") ) ;
  ok(76, ($x = $fil->gzread($uncomp)) == $len) ;
 
  ok(77, ! $fil->gzclose ) ;
 
  unlink $filename ;
 
  ok(78, $hello eq $uncomp) ;
 
}


# compress/uncompress tests
# =========================

$hello = "hello mum" ;
my $keep_hello = $hello ;

my $compr = compress($hello) ;
ok(79, $compr ne "") ;

my $keep_compr = $compr ;

my $uncompr = uncompress ($compr) ;

ok(80, $hello eq $uncompr) ;

ok(81, $hello eq $keep_hello) ;
ok(82, $compr eq $keep_compr) ;

# compress a number
$hello = 7890 ;
$keep_hello = $hello ;

$compr = compress($hello) ;
ok(83, $compr ne "") ;

$keep_compr = $compr ;

$uncompr = uncompress ($compr) ;

ok(84, $hello eq $uncompr) ;

ok(85, $hello eq $keep_hello) ;
ok(86, $compr eq $keep_compr) ;

# bigger compress

$compr = compress ($contents) ;
ok(87, $compr ne "") ;

$uncompr = uncompress ($compr) ;

ok(88, $contents eq $uncompr) ;

# buffer reference

$compr = compress(\$hello) ;
ok(89, $compr ne "") ;


$uncompr = uncompress (\$compr) ;
ok(90, $hello eq $uncompr) ;

# deflate/inflate - small buffer
# ==============================

$hello = "I am a HAL 9000 computer" ;
my @hello = split('', $hello) ;
my ($err, $X, $status);
 
ok(91,  ($x, $err) = deflateInit( {-Bufsize => 1} ) ) ;
ok(92, $x) ;
ok(93, $err == Z_OK) ;
 
my $Answer = '';
foreach (@hello)
{
    ($X, $status) = $x->deflate($_) ;
    last unless $status == Z_OK ;

    $Answer .= $X ;
}
 
ok(94, $status == Z_OK) ;

ok(95,    (($X, $status) = $x->flush())[1] == Z_OK ) ;
$Answer .= $X ;
 
 
my @Answer = split('', $Answer) ;
 
my $k;
ok(96, ($k, $err) = inflateInit( {-Bufsize => 1}) ) ;
ok(97, $k) ;
ok(98, $err == Z_OK) ;
 
my $GOT = '';
my $Z;
foreach (@Answer)
{
    ($Z, $status) = $k->inflate($_) ;
    $GOT .= $Z ;
    last if $status == Z_STREAM_END or $status != Z_OK ;
 
}
 
ok(99, $status == Z_STREAM_END) ;
ok(100, $GOT eq $hello ) ;


# deflate/inflate - small buffer with a number
# ==============================

$hello = 6529 ;
 
ok(101,  ($x, $err) = deflateInit( {-Bufsize => 1} ) ) ;
ok(102, $x) ;
ok(103, $err == Z_OK) ;
 
$Answer = '';
{
    ($X, $status) = $x->deflate($hello) ;

    $Answer .= $X ;
}
 
ok(104, $status == Z_OK) ;

ok(105,    (($X, $status) = $x->flush())[1] == Z_OK ) ;
$Answer .= $X ;
 
 
@Answer = split('', $Answer) ;
 
ok(106, ($k, $err) = inflateInit( {-Bufsize => 1}) ) ;
ok(107, $k) ;
ok(108, $err == Z_OK) ;
 
$GOT = '';
foreach (@Answer)
{
    ($Z, $status) = $k->inflate($_) ;
    $GOT .= $Z ;
    last if $status == Z_STREAM_END or $status != Z_OK ;
 
}
 
ok(109, $status == Z_STREAM_END) ;
ok(110, $GOT eq $hello ) ;


 
# deflate/inflate - larger buffer
# ==============================


ok(111, $x = deflateInit() ) ;
 
ok(112, (($X, $status) = $x->deflate($contents))[1] == Z_OK) ;

my $Y = $X ;
 
 
ok(113, (($X, $status) = $x->flush() )[1] == Z_OK ) ;
$Y .= $X ;
 
 
 
ok(114, $k = inflateInit() ) ;
 
($Z, $status) = $k->inflate($Y) ;
 
ok(115, $status == Z_STREAM_END) ;
ok(116, $contents eq $Z ) ;

# deflate/inflate - preset dictionary
# ===================================

my $dictionary = "hello" ;
ok(117, $x = deflateInit({-Level => Z_BEST_COMPRESSION,
			 -Dictionary => $dictionary})) ;
 
my $dictID = $x->dict_adler() ;

($X, $status) = $x->deflate($hello) ;
ok(118, $status == Z_OK) ;
($Y, $status) = $x->flush() ;
ok(119, $status == Z_OK) ;
$X .= $Y ;
$x = 0 ;
 
ok(120, $k = inflateInit(-Dictionary => $dictionary) ) ;
 
($Z, $status) = $k->inflate($X);
ok(121, $status == Z_STREAM_END) ;
ok(122, $k->dict_adler() == $dictID);
ok(123, $hello eq $Z ) ;

##ok(76, $k->inflateSetDictionary($dictionary) == Z_OK);
# 
#$Z='';
#while (1) {
#    ($Z, $status) = $k->inflate($X) ;
#    last if $status == Z_STREAM_END or $status != Z_OK ;
#print "status=[$status] hello=[$hello] Z=[$Z]\n";
#}
#ok(77, $status == Z_STREAM_END) ;
#ok(78, $hello eq $Z ) ;
#print "status=[$status] hello=[$hello] Z=[$Z]\n";
#
#
## all done.
#
#
#


# inflate - check remaining buffer after Z_STREAM_END
# ===================================================
 
{
    ok(124, $x = deflateInit(-Level => Z_BEST_COMPRESSION )) ;
 
    ($X, $status) = $x->deflate($hello) ;
    ok(125, $status == Z_OK) ;
    ($Y, $status) = $x->flush() ;
    ok(126, $status == Z_OK) ;
    $X .= $Y ;
    $x = 0 ;
 
    ok(127, $k = inflateInit() ) ;
 
    my $first = substr($X, 0, 2) ;
    my $last  = substr($X, 2) ;
    ($Z, $status) = $k->inflate($first);
    ok(128, $status == Z_OK) ;
    ok(129, $first eq "") ;

    $last .= "appendage" ;
    my ($T, $status) = $k->inflate($last);
    ok(130, $status == Z_STREAM_END) ;
    ok(131, $hello eq $Z . $T ) ;
    ok(132, $last eq "appendage") ;

}

# memGzip & memGunzip
{
    my $name = "test.gz" ;
    my $buffer = <<EOM;
some sample 
text

EOM

    my $len = length $buffer ;
    my ($x, $uncomp) ;


    # create an in-memory gzip file
    my $dest = Compress::Zlib::memGzip($buffer) ;
    ok(133, length $dest) ;

    # write it to disk
    ok(134, open(FH, ">$name")) ;
    print FH $dest ;
    close FH ;

    # uncompress with gzopen
    ok(135, my $fil = gzopen($name, "rb") ) ;
 
    ok(136, ($x = $fil->gzread($uncomp)) == $len) ;
 
    ok(137, ! $fil->gzclose ) ;

    ok(138, $uncomp eq $buffer) ;
 
    unlink $name ;

    # now check that memGunzip can deal with it.
    my $ungzip = Compress::Zlib::memGunzip($dest) ;
    ok(139, defined $ungzip) ;
    ok(140, $buffer eq $ungzip) ;
 
    # now do the same but use a reference 

    $dest = Compress::Zlib::memGzip(\$buffer) ; 
    ok(141, length $dest) ;

    # write it to disk
    ok(142, open(FH, ">$name")) ;
    print FH $dest ;
    close FH ;

    # uncompress with gzopen
    ok(143, $fil = gzopen($name, "rb") ) ;
 
    ok(144, ($x = $fil->gzread($uncomp)) == $len) ;
 
    ok(145, ! $fil->gzclose ) ;

    ok(146, $uncomp eq $buffer) ;
 
    # now check that memGunzip can deal with it.
    $ungzip = Compress::Zlib::memGunzip(\$dest) ;
    ok(147, defined $ungzip) ;
    ok(148, $buffer eq $ungzip) ;
 
    unlink $name ;

    # check corrupt header -- too short
    $dest = "x" ;
    my $result = Compress::Zlib::memGunzip($dest) ;
    ok(149, !defined $result) ;

    # check corrupt header -- full of junk
    $dest = "x" x 200 ;
    $result = Compress::Zlib::memGunzip($dest) ;
    ok(150, !defined $result) ;
}

# memGunzip with a gzopen created file
{
    my $name = "test.gz" ;
    my $buffer = <<EOM;
some sample 
text

EOM

    ok(151, $fil = gzopen($name, "wb")) ;

    ok(152, $fil->gzwrite($buffer) == length $buffer) ;

    ok(153, ! $fil->gzclose ) ;

    my $compr = readFile($name);
    ok(154, length $compr) ;
    my $unc = Compress::Zlib::memGunzip($compr) ;
    ok(155, defined $unc) ;
    ok(156, $buffer eq $unc) ;
    unlink $name ;
}

{

    # Check - MAX_WBITS
    # =================
    
    $hello = "Test test test test test";
    @hello = split('', $hello) ;
     
    ok(157,  ($x, $err) = deflateInit( -Bufsize => 1, -WindowBits => -MAX_WBITS() ) ) ;
    ok(158, $x) ;
    ok(159, $err == Z_OK) ;
     
    $Answer = '';
    foreach (@hello)
    {
        ($X, $status) = $x->deflate($_) ;
        last unless $status == Z_OK ;
    
        $Answer .= $X ;
    }
     
    ok(160, $status == Z_OK) ;
    
    ok(161,    (($X, $status) = $x->flush())[1] == Z_OK ) ;
    $Answer .= $X ;
     
     
    @Answer = split('', $Answer) ;
    # Undocumented corner -- extra byte needed to get inflate to return 
    # Z_STREAM_END when done.  
    push @Answer, " " ; 
     
    ok(162, ($k, $err) = inflateInit(-Bufsize => 1, -WindowBits => -MAX_WBITS()) ) ;
    ok(163, $k) ;
    ok(164, $err == Z_OK) ;
     
    $GOT = '';
    foreach (@Answer)
    {
        ($Z, $status) = $k->inflate($_) ;
        $GOT .= $Z ;
        last if $status == Z_STREAM_END or $status != Z_OK ;
     
    }
     
    ok(165, $status == Z_STREAM_END) ;
    ok(166, $GOT eq $hello ) ;
    
}
