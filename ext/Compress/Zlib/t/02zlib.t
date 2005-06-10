

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


print "1..239\n" ;

# Check zlib_version and ZLIB_VERSION are the same.
ok(1, Compress::Zlib::zlib_version eq ZLIB_VERSION) ;

# gzip tests
#===========

my $name = "test.gz" ;
my ($x, $uncomp) ;

ok(2, my $fil = gzopen($name, "wb")) ;

ok(3, $gzerrno == 0);

ok(4, $fil->gzwrite($hello) == $len) ;

ok(5, ! $fil->gzclose ) ;

ok(6, $fil = gzopen($name, "rb") ) ;

ok(7, $gzerrno == 0);

ok(8, ($x = $fil->gzread($uncomp)) == $len) ;

ok(9, ! $fil->gzclose ) ;

unlink $name ;

ok(10, $hello eq $uncomp) ;

# check that a number can be gzipped
my $number = 7603 ;
my $num_len = 4 ;

ok(11, $fil = gzopen($name, "wb")) ;

ok(12, $gzerrno == 0);

ok(13, $fil->gzwrite($number) == $num_len) ;

ok(14, $gzerrno == 0);

ok(15, ! $fil->gzclose ) ;

ok(16, $gzerrno == 0);

ok(17, $fil = gzopen($name, "rb") ) ;

ok(18, ($x = $fil->gzread($uncomp)) == $num_len) ;

ok(19, $gzerrno == 0 || $gzerrno == Z_STREAM_END);

ok(20, ! $fil->gzclose ) ;

ok(21, $gzerrno == 0);

unlink $name ;

ok(22, $number == $uncomp) ;
ok(23, $number eq $uncomp) ;


# now a bigger gzip test

my $text = 'text' ;
my $file = "$text.gz" ;

ok(24, my $f = gzopen($file, "wb")) ;

# generate a long random string
my $contents = '' ;
foreach (1 .. 5000)
  { $contents .= chr int rand 256 }

$len = length $contents ;

ok(25, $f->gzwrite($contents) == $len ) ;

ok(26, ! $f->gzclose );

ok(27, $f = gzopen($file, "rb")) ;
 
my $uncompressed ;
ok(28, $f->gzread($uncompressed, $len) == $len) ;

ok(29, $contents eq $uncompressed) ;

ok(30, ! $f->gzclose ) ;

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

ok(31, $fil = gzopen($name, "wb")) ;
ok(32, $fil->gzwrite($text) == length $text) ;
ok(33, ! $fil->gzclose ) ;

# now try to read it back in
ok(34, $fil = gzopen($name, "rb")) ;
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
ok(35, $aok) ;
ok(36, $remember eq $text) ;
ok(37, $lines == @text) ;
ok(38, ! $fil->gzclose ) ;
unlink($name) ;

# a text file with a very long line (bigger than the internal buffer)
my $line1 = ("abcdefghijklmnopq" x 2000) . "\n" ;
my $line2 = "second line\n" ;
$text = $line1 . $line2 ;
ok(39, $fil = gzopen($name, "wb")) ;
ok(40, $fil->gzwrite($text) == length $text) ;
ok(41, ! $fil->gzclose ) ;

# now try to read it back in
ok(42, $fil = gzopen($name, "rb")) ;
my $i = 0 ;
my @got = ();
while ($fil->gzreadline($line) > 0) {
    $got[$i] = $line ;    
    ++ $i ;
}
ok(43, $i == 2) ;
ok(44, $got[0] eq $line1 ) ;
ok(45, $got[1] eq $line2) ;

ok(46, ! $fil->gzclose ) ;

unlink $name ;

# a text file which is not termined by an EOL

$line1 = "hello hello, I'm back again\n" ;
$line2 = "there is no end in sight" ;

$text = $line1 . $line2 ;
ok(47, $fil = gzopen($name, "wb")) ;
ok(48, $fil->gzwrite($text) == length $text) ;
ok(49, ! $fil->gzclose ) ;

# now try to read it back in
ok(50, $fil = gzopen($name, "rb")) ;
@got = () ; $i = 0 ;
while ($fil->gzreadline($line) > 0) {
    $got[$i] = $line ;    
    ++ $i ;
}
ok(51, $i == 2) ;
ok(52, $got[0] eq $line1 ) ;
ok(53, $got[1] eq $line2) ;

ok(54, ! $fil->gzclose ) ;

unlink $name ;


# mix gzread and gzreadline <

# case 1: read a line, then a block. The block is
#         smaller than the internal block used by
#	  gzreadline
$line1 = "hello hello, I'm back again\n" ;
$line2 = "abc" x 200 ; 
my $line3 = "def" x 200 ;

$text = $line1 . $line2 . $line3 ;
ok(55, $fil = gzopen($name, "wb")) ;
ok(56, $fil->gzwrite($text) == length $text) ;
ok(57, ! $fil->gzclose ) ;

# now try to read it back in
ok(58, $fil = gzopen($name, "rb")) ;
ok(59, $fil->gzreadline($line) > 0) ;
ok(60, $line eq $line1) ;
ok(61, $fil->gzread($line, length $line2) > 0) ;
ok(62, $line eq $line2) ;
ok(63, $fil->gzread($line, length $line3) > 0) ;
ok(64, $line eq $line3) ;
ok(65, ! $fil->gzclose ) ;
unlink $name ;

# change $/ <<TODO



# compress/uncompress tests
# =========================

$hello = "hello mum" ;
my $keep_hello = $hello ;

my $compr = compress($hello) ;
ok(66, $compr ne "") ;

my $keep_compr = $compr ;

my $uncompr = uncompress ($compr) ;

ok(67, $hello eq $uncompr) ;

ok(68, $hello eq $keep_hello) ;
ok(69, $compr eq $keep_compr) ;

# compress a number
$hello = 7890 ;
$keep_hello = $hello ;

$compr = compress($hello) ;
ok(70, $compr ne "") ;

$keep_compr = $compr ;

$uncompr = uncompress ($compr) ;

ok(71, $hello eq $uncompr) ;

ok(72, $hello eq $keep_hello) ;
ok(73, $compr eq $keep_compr) ;

# bigger compress

$compr = compress ($contents) ;
ok(74, $compr ne "") ;

$uncompr = uncompress ($compr) ;

ok(75, $contents eq $uncompr) ;

# buffer reference

$compr = compress(\$hello) ;
ok(76, $compr ne "") ;


$uncompr = uncompress (\$compr) ;
ok(77, $hello eq $uncompr) ;

# bad level
$compr = compress($hello, 1000) ;
ok(78, ! defined $compr);

# change level
$compr = compress($hello, Z_BEST_COMPRESSION) ;
ok(79, defined $compr);
$uncompr = uncompress (\$compr) ;
ok(80, $hello eq $uncompr) ;

# deflate/inflate - small buffer
# ==============================

$hello = "I am a HAL 9000 computer" ;
my @hello = split('', $hello) ;
my ($err, $X, $status);
 
ok(81,  ($x, $err) = deflateInit( {-Bufsize => 1} ) ) ;
ok(82, $x) ;
ok(83, $err == Z_OK) ;
 
my $Answer = '';
foreach (@hello)
{
    ($X, $status) = $x->deflate($_) ;
    last unless $status == Z_OK ;

    $Answer .= $X ;
}
 
ok(84, $status == Z_OK) ;

ok(85,    (($X, $status) = $x->flush())[1] == Z_OK ) ;
$Answer .= $X ;
 
 
my @Answer = split('', $Answer) ;
 
my $k;
ok(86, ($k, $err) = inflateInit( {-Bufsize => 1}) ) ;
ok(87, $k) ;
ok(88, $err == Z_OK) ;
 
my $GOT = '';
my $Z;
foreach (@Answer)
{
    ($Z, $status) = $k->inflate($_) ;
    $GOT .= $Z ;
    last if $status == Z_STREAM_END or $status != Z_OK ;
 
}
 
ok(89, $status == Z_STREAM_END) ;
ok(90, $GOT eq $hello ) ;


# deflate/inflate - small buffer with a number
# ==============================

$hello = 6529 ;
 
ok(91,  ($x, $err) = deflateInit( {-Bufsize => 1} ) ) ;
ok(92, $x) ;
ok(93, $err == Z_OK) ;
 
$Answer = '';
{
    ($X, $status) = $x->deflate($hello) ;

    $Answer .= $X ;
}
 
ok(94, $status == Z_OK) ;

ok(95,    (($X, $status) = $x->flush())[1] == Z_OK ) ;
$Answer .= $X ;
 
 
@Answer = split('', $Answer) ;
 
ok(96, ($k, $err) = inflateInit( {-Bufsize => 1}) ) ;
ok(97, $k) ;
ok(98, $err == Z_OK) ;
 
$GOT = '';
foreach (@Answer)
{
    ($Z, $status) = $k->inflate($_) ;
    $GOT .= $Z ;
    last if $status == Z_STREAM_END or $status != Z_OK ;
 
}
 
ok(99, $status == Z_STREAM_END) ;
ok(100, $GOT eq $hello ) ;


 
# deflate/inflate - larger buffer
# ==============================


ok(101, $x = deflateInit() ) ;
 
ok(102, (($X, $status) = $x->deflate($contents))[1] == Z_OK) ;

my $Y = $X ;
 
 
ok(103, (($X, $status) = $x->flush() )[1] == Z_OK ) ;
$Y .= $X ;
 
 
 
ok(104, $k = inflateInit() ) ;
 
($Z, $status) = $k->inflate($Y) ;
 
ok(105, $status == Z_STREAM_END) ;
ok(106, $contents eq $Z ) ;

# deflate/inflate - preset dictionary
# ===================================

my $dictionary = "hello" ;
ok(107, $x = deflateInit({-Level => Z_BEST_COMPRESSION,
			 -Dictionary => $dictionary})) ;
 
my $dictID = $x->dict_adler() ;

($X, $status) = $x->deflate($hello) ;
ok(108, $status == Z_OK) ;
($Y, $status) = $x->flush() ;
ok(109, $status == Z_OK) ;
$X .= $Y ;
$x = 0 ;
 
ok(110, $k = inflateInit(-Dictionary => $dictionary) ) ;
 
($Z, $status) = $k->inflate($X);
ok(111, $status == Z_STREAM_END) ;
ok(112, $k->dict_adler() == $dictID);
ok(113, $hello eq $Z ) ;

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
    ok(114, $x = deflateInit(-Level => Z_BEST_COMPRESSION )) ;
 
    ($X, $status) = $x->deflate($hello) ;
    ok(115, $status == Z_OK) ;
    ($Y, $status) = $x->flush() ;
    ok(116, $status == Z_OK) ;
    $X .= $Y ;
    $x = 0 ;
 
    ok(117, $k = inflateInit() ) ;
 
    my $first = substr($X, 0, 2) ;
    my $last  = substr($X, 2) ;
    ($Z, $status) = $k->inflate($first);
    ok(118, $status == Z_OK) ;
    ok(119, $first eq "") ;

    $last .= "appendage" ;
    my ($T, $status) = $k->inflate($last);
    ok(120, $status == Z_STREAM_END) ;
    ok(121, $hello eq $Z . $T ) ;
    ok(122, $last eq "appendage") ;

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
    ok(123, length $dest) ;

    # write it to disk
    ok(124, open(FH, ">$name")) ;
    binmode(FH);
    print FH $dest ;
    close FH ;

    # uncompress with gzopen
    ok(125, my $fil = gzopen($name, "rb") ) ;
 
    ok(126, ($x = $fil->gzread($uncomp)) == $len) ;
 
    ok(127, ! $fil->gzclose ) ;

    ok(128, $uncomp eq $buffer) ;
 
    unlink $name ;

    # now check that memGunzip can deal with it.
    my $ungzip = Compress::Zlib::memGunzip($dest) ;
    ok(129, defined $ungzip) ;
    ok(130, $buffer eq $ungzip) ;
 
    # now do the same but use a reference 

    $dest = Compress::Zlib::memGzip(\$buffer) ; 
    ok(131, length $dest) ;

    # write it to disk
    ok(132, open(FH, ">$name")) ;
    binmode(FH);
    print FH $dest ;
    close FH ;

    # uncompress with gzopen
    ok(133, $fil = gzopen($name, "rb") ) ;
 
    ok(134, ($x = $fil->gzread($uncomp)) == $len) ;
 
    ok(135, ! $fil->gzclose ) ;

    ok(136, $uncomp eq $buffer) ;
 
    # now check that memGunzip can deal with it.
    my $keep = $dest;
    $ungzip = Compress::Zlib::memGunzip(\$dest) ;
    ok(137, defined $ungzip) ;
    ok(138, $buffer eq $ungzip) ;

    # check memGunzip can cope with missing gzip trailer
    my $minimal = substr($keep, 0, -1) ;
    $ungzip = Compress::Zlib::memGunzip(\$minimal) ;
    ok(139, defined $ungzip) ;
    ok(140, $buffer eq $ungzip) ;

    $minimal = substr($keep, 0, -2) ;
    $ungzip = Compress::Zlib::memGunzip(\$minimal) ;
    ok(141, defined $ungzip) ;
    ok(142, $buffer eq $ungzip) ;

    $minimal = substr($keep, 0, -3) ;
    $ungzip = Compress::Zlib::memGunzip(\$minimal) ;
    ok(143, defined $ungzip) ;
    ok(144, $buffer eq $ungzip) ;

    $minimal = substr($keep, 0, -4) ;
    $ungzip = Compress::Zlib::memGunzip(\$minimal) ;
    ok(145, defined $ungzip) ;
    ok(146, $buffer eq $ungzip) ;

    $minimal = substr($keep, 0, -5) ;
    $ungzip = Compress::Zlib::memGunzip(\$minimal) ;
    ok(147, defined $ungzip) ;
    ok(148, $buffer eq $ungzip) ;

    $minimal = substr($keep, 0, -6) ;
    $ungzip = Compress::Zlib::memGunzip(\$minimal) ;
    ok(149, defined $ungzip) ;
    ok(150, $buffer eq $ungzip) ;

    $minimal = substr($keep, 0, -7) ;
    $ungzip = Compress::Zlib::memGunzip(\$minimal) ;
    ok(151, defined $ungzip) ;
    ok(152, $buffer eq $ungzip) ;

    $minimal = substr($keep, 0, -8) ;
    $ungzip = Compress::Zlib::memGunzip(\$minimal) ;
    ok(153, defined $ungzip) ;
    ok(154, $buffer eq $ungzip) ;

    $minimal = substr($keep, 0, -9) ;
    $ungzip = Compress::Zlib::memGunzip(\$minimal) ;
    ok(155, ! defined $ungzip) ;

 
    unlink $name ;

    # check corrupt header -- too short
    $dest = "x" ;
    my $result = Compress::Zlib::memGunzip($dest) ;
    ok(156, !defined $result) ;

    # check corrupt header -- full of junk
    $dest = "x" x 200 ;
    $result = Compress::Zlib::memGunzip($dest) ;
    ok(157, !defined $result) ;
}

# memGunzip with a gzopen created file
{
    my $name = "test.gz" ;
    my $buffer = <<EOM;
some sample 
text

EOM

    ok(158, $fil = gzopen($name, "wb")) ;

    ok(159, $fil->gzwrite($buffer) == length $buffer) ;

    ok(160, ! $fil->gzclose ) ;

    my $compr = readFile($name);
    ok(161, length $compr) ;
    my $unc = Compress::Zlib::memGunzip($compr) ;
    ok(162, defined $unc) ;
    ok(163, $buffer eq $unc) ;
    unlink $name ;
}

{

    # Check - MAX_WBITS
    # =================
    
    $hello = "Test test test test test";
    @hello = split('', $hello) ;
     
    ok(164,  ($x, $err) = deflateInit( -Bufsize => 1, -WindowBits => -MAX_WBITS() ) ) ;
    ok(165, $x) ;
    ok(166, $err == Z_OK) ;
     
    $Answer = '';
    foreach (@hello)
    {
        ($X, $status) = $x->deflate($_) ;
        last unless $status == Z_OK ;
    
        $Answer .= $X ;
    }
     
    ok(167, $status == Z_OK) ;
    
    ok(168,    (($X, $status) = $x->flush())[1] == Z_OK ) ;
    $Answer .= $X ;
     
     
    @Answer = split('', $Answer) ;
    # Undocumented corner -- extra byte needed to get inflate to return 
    # Z_STREAM_END when done.  
    push @Answer, " " ; 
     
    ok(169, ($k, $err) = inflateInit(-Bufsize => 1, -WindowBits => -MAX_WBITS()) ) ;
    ok(170, $k) ;
    ok(171, $err == Z_OK) ;
     
    $GOT = '';
    foreach (@Answer)
    {
        ($Z, $status) = $k->inflate($_) ;
        $GOT .= $Z ;
        last if $status == Z_STREAM_END or $status != Z_OK ;
     
    }
     
    ok(172, $status == Z_STREAM_END) ;
    ok(173, $GOT eq $hello ) ;
    
}

{
    # inflateSync

    # create a deflate stream with flush points

    my $hello = "I am a HAL 9000 computer" x 2001 ;
    my $goodbye = "Will I dream?" x 2010;
    my ($err, $answer, $X, $status, $Answer);
     
    ok(174, ($x, $err) = deflateInit() ) ;
    ok(175, $x) ;
    ok(176, $err == Z_OK) ;
     
    ($Answer, $status) = $x->deflate($hello) ;
    ok(177, $status == Z_OK) ;
    
    # create a flush point
    ok(178, (($X, $status) = $x->flush(Z_FULL_FLUSH))[1] == Z_OK ) ;
    $Answer .= $X ;
     
    ($X, $status) = $x->deflate($goodbye) ;
    ok(179, $status == Z_OK) ;
    $Answer .= $X ;
    
    ok(180, (($X, $status) = $x->flush())[1] == Z_OK ) ;
    $Answer .= $X ;
     
    my ($first, @Answer) = split('', $Answer) ;
     
    my $k;
    ok(181, ($k, $err) = inflateInit()) ;
    ok(182, $k) ;
    ok(183, $err == Z_OK) ;
     
    ($Z, $status) = $k->inflate($first) ;
    ok(184, $status == Z_OK) ;

    # skip to the first flush point.
    while (@Answer)
    {
        my $byte = shift @Answer;
        $status = $k->inflateSync($byte) ;
        last unless $status == Z_DATA_ERROR;
     
    }

    ok(185, $status == Z_OK);
     
    my $GOT = '';
    my $Z = '';
    foreach (@Answer)
    {
        my $Z = '';
        ($Z, $status) = $k->inflate($_) ;
        $GOT .= $Z if defined $Z ;
        # print "x $status\n";
        last if $status == Z_STREAM_END or $status != Z_OK ;
     
    }
     
    # zlib 1.0.9 returns Z_STREAM_END here, all others return Z_DATA_ERROR
    ok(186, $status == Z_DATA_ERROR || $status == Z_STREAM_END) ;
    ok(187, $GOT eq $goodbye ) ;


    # Check inflateSync leaves good data in buffer
    $Answer =~ /^(.)(.*)$/ ;
    my ($initial, $rest) = ($1, $2);

    
    ok(188, ($k, $err) = inflateInit()) ;
    ok(189, $k) ;
    ok(190, $err == Z_OK) ;
     
    ($Z, $status) = $k->inflate($initial) ;
    ok(191, $status == Z_OK) ;

    $status = $k->inflateSync($rest) ;
    ok(192, $status == Z_OK);
     
    ($GOT, $status) = $k->inflate($rest) ;
     
    ok(193, $status == Z_DATA_ERROR) ;
    ok(194, $Z . $GOT eq $goodbye ) ;
}

{
    # deflateParams

    my $hello = "I am a HAL 9000 computer" x 2001 ;
    my $goodbye = "Will I dream?" x 2010;
    my ($input, $err, $answer, $X, $status, $Answer);
     
    ok(195, ($x, $err) = deflateInit(-Level    => Z_BEST_COMPRESSION,
                                     -Strategy => Z_DEFAULT_STRATEGY) ) ;
    ok(196, $x) ;
    ok(197, $err == Z_OK) ;

    ok(198, $x->get_Level()    == Z_BEST_COMPRESSION);
    ok(199, $x->get_Strategy() == Z_DEFAULT_STRATEGY);
     
    ($Answer, $status) = $x->deflate($hello) ;
    ok(200, $status == Z_OK) ;
    $input .= $hello;
    
    # error cases
    eval { $x->deflateParams() };
    ok(201, $@ =~ m#^deflateParams needs Level and/or Strategy#);

    eval { $x->deflateParams(-Joe => 3) };
    ok(202, $@ =~ /^unknown key value\(s\) Joe at/);

    ok(203, $x->get_Level()    == Z_BEST_COMPRESSION);
    ok(204, $x->get_Strategy() == Z_DEFAULT_STRATEGY);
     
    # change both Level & Strategy
    $status = $x->deflateParams(-Level => Z_BEST_SPEED, -Strategy => Z_HUFFMAN_ONLY) ;
    ok(205, $status == Z_OK) ;
    
    ok(206, $x->get_Level()    == Z_BEST_SPEED);
    ok(207, $x->get_Strategy() == Z_HUFFMAN_ONLY);
     
    ($X, $status) = $x->deflate($goodbye) ;
    ok(208, $status == Z_OK) ;
    $Answer .= $X ;
    $input .= $goodbye;
    
    # change only Level 
    $status = $x->deflateParams(-Level => Z_NO_COMPRESSION) ;
    ok(209, $status == Z_OK) ;
    
    ok(210, $x->get_Level()    == Z_NO_COMPRESSION);
    ok(211, $x->get_Strategy() == Z_HUFFMAN_ONLY);
     
    ($X, $status) = $x->deflate($goodbye) ;
    ok(212, $status == Z_OK) ;
    $Answer .= $X ;
    $input .= $goodbye;
    
    # change only Strategy
    $status = $x->deflateParams(-Strategy => Z_FILTERED) ;
    ok(213, $status == Z_OK) ;
    
    ok(214, $x->get_Level()    == Z_NO_COMPRESSION);
    ok(215, $x->get_Strategy() == Z_FILTERED);
     
    ($X, $status) = $x->deflate($goodbye) ;
    ok(216, $status == Z_OK) ;
    $Answer .= $X ;
    $input .= $goodbye;
    
    ok(217, (($X, $status) = $x->flush())[1] == Z_OK ) ;
    $Answer .= $X ;
     
    my ($first, @Answer) = split('', $Answer) ;
     
    my $k;
    ok(218, ($k, $err) = inflateInit()) ;
    ok(219, $k) ;
    ok(220, $err == Z_OK) ;
     
    ($Z, $status) = $k->inflate($Answer) ;

    ok(221, $status == Z_STREAM_END) ;
    ok(222, $Z  eq $input ) ;
}

{
    # error cases

    eval { deflateInit(-Level) };
    ok(223, $@ =~ /^Compress::Zlib::deflateInit: parameter is not a reference to a hash at/);

    eval { inflateInit(-Level) };
    ok(224, $@ =~ /^Compress::Zlib::inflateInit: parameter is not a reference to a hash at/);

    eval { deflateInit(-Joe => 1) };
    ok(225, $@ =~ /^unknown key value\(s\) Joe at/);

    eval { inflateInit(-Joe => 1) };
    ok(226, $@ =~ /^unknown key value\(s\) Joe at/);

    eval { deflateInit(-Bufsize => 0) };
    ok(227, $@ =~ /^.*?: Bufsize must be >= 1, you specified 0 at/);

    eval { inflateInit(-Bufsize => 0) };
    ok(228, $@ =~ /^.*?: Bufsize must be >= 1, you specified 0 at/);

    eval { deflateInit(-Bufsize => -1) };
    ok(229, $@ =~ /^.*?: Bufsize must be >= 1, you specified -1 at/);

    eval { inflateInit(-Bufsize => -1) };
    ok(230, $@ =~ /^.*?: Bufsize must be >= 1, you specified -1 at/);

    eval { deflateInit(-Bufsize => "xxx") };
    ok(231, $@ =~ /^.*?: Bufsize must be >= 1, you specified xxx at/);

    eval { inflateInit(-Bufsize => "xxx") };
    ok(232, $@ =~ /^.*?: Bufsize must be >= 1, you specified xxx at/);

}

{
    # test inflate with a substr

    ok(233, my $x = deflateInit() ) ;
     
    ok(234, (my ($X, $status) = $x->deflate($contents))[1] == Z_OK) ;
    
    my $Y = $X ;

     
     
    ok(235, (($X, $status) = $x->flush() )[1] == Z_OK ) ;
    $Y .= $X ;
     
    my $append = "Appended" ;
    $Y .= $append ;
     
    ok(236, $k = inflateInit() ) ;
     
    ($Z, $status) = $k->inflate(substr($Y, 0, -1)) ;
     
    ok(237, $status == Z_STREAM_END) ;
    #print "status $status Y [$Y]\n" ;
    ok(238, $contents eq $Z ) ;
    ok(239, $Y eq $append);
    
}
