require Mail::Header;

print "1..22\n";

$h = new Mail::Header;

$t = 0;

$h->header_hashref({hhrtest1 => 1, 
	hhrtest2 => [1, "this test line was written by TobiX\n"]});
$h->add(Date => "a test header");
$h->add(Date => "a longer test header");
$h->add(Date => "an even longer test header");

$h->print;
$str = $h->get(Date => 0);
print "#$str#\nnot "
	unless $str eq "a test header\n";
printf "ok %d\n",++$t;

$str = $h->get(Date => 1);
print "#$str#\nnot "
	unless $str eq "a longer test header\n";
printf "ok %d\n",++$t;

$str = $h->get(Date => 2);
print "#$str#\nnot "
	unless $str eq "an even longer test header\n";
printf "ok %d\n",++$t;

$str = $h->get('hhrtest2',1);
print "#$str#\nnot "
	unless $str eq "this test line was written by TobiX\n";
printf "ok %d\n",++$t;

$href=$h->header_hashref();

print "not "
	unless $href->{Date}->[0] eq "a test header\n";
printf "ok %d\n",++$t;

print "not "
	unless $href->{Hhrtest2}->[0];
printf "ok %d\n",++$t;

print "not "
	unless $href->{Hhrtest1}->[0];
printf "ok %d\n",++$t;


$h->fold(30);

print "not "
	unless $h->get(Date => 0) eq "a test header\n";
printf "ok %d\n",++$t;

print "not "
	unless $h->get(Date => 1) eq "a longer test header\n";
printf "ok %d\n",++$t;

print "not "
	unless $h->get(Date => 2) eq "an even longer test\n    header\n";
printf "ok %d\n",++$t;

$h->fold(20);

print "not "
	unless $h->get(Date => 0) eq "a test header\n";
printf "ok %d\n",++$t;

print "not "
	unless $h->get(Date => 1) eq "a longer\n    test header\n";
printf "ok %d\n",++$t;

print "not "
	unless $h->get(Date => 2) eq "an even\n    longer test\n    header\n";
printf "ok %d\n",++$t;

$h->unfold;

print "not "
	unless $h->get(Date => 0) eq "a test header\n";
printf "ok %d\n",++$t;

print "not "
	unless $h->get(Date => 1) eq "a longer test header\n";
printf "ok %d\n",++$t;

print "not "
	unless $h->get(Date => 2) eq "an even longer test header\n";
printf "ok %d\n",++$t;

$head = <<EOF;
From from_
To: to
From: from
Subject:subject
EOF
$body = "body\n";
$mail = "$head\n$body";
@mail = map { "$_\n" } split /\n/, $mail;

print "not "
	unless $h = new Mail::Header \@mail, Modify => 0;
printf "ok %d\n",++$t;

print "not "
	unless $h->as_string eq $head;
printf "ok %d\n",++$t;

print "not "
	unless $h->get('Subject') eq "subject\n";
printf "ok %d\n",++$t;

print "not "
	unless $h->get('To') eq "to\n";
printf "ok %d\n",++$t;

$headin = <<EOF;
Content-Type: multipart/mixed;
       boundary="---- =_NextPart_000_01BDBF1F.DA8F77EE"
Content-Type: multipart/mixed;
       boundary="---- =_NextPart_000_01BDBF1F.DA8F77EE"hkjhgkfhgfhgf"hfkjdhf fhjf fghjghf fdshjfhdsj" hgjhgfjk
Content-Type: multipart/mixed;
       boundary="---- =_NextPart_000_01BDBF1F.DA8F77EE"hkjhg kfhgfhgf"hfkjdhf fhjf fghjghf fdshjfhdsj" hgjhgfjk
Content-Type: multipart/mixed;
       boundary="---- =_NextPart_000_01BDBF1F.DA8F77EE"hhhhhhhhhhhhhhhhhhhhhhhhh fjsdhfkjsd fhdjsfhkj
Content-Type: multipart/mixed;
       boundary="---- =_NextPart_000_01BDBF1F.DA8F77EE" abc def ghfdgfdsgj fdshfgfsdgfdsg hfsdgjfsdg fgsfgjsg
mime-type: text/plain
test1: _abc _def _ghi _fdjhfd _fhdjkfh _dkhkjd _fdjkf _dshfdks _fhdjfdkhfk _dshfds _fdsjk _fdkhfdks _fdsjf _dkf
test1: _abc _def _ghi _fdjhfd _fhdjkfh _dkhaaaaaaaaaaakjdfdjkfdshfdksfhdjfdkhfkdshfdsfdsjkfdkhfdksfdsjf _dkf
EOF
$headout = <<EOF;
Content-Type: multipart/mixed;
    boundary="---- =_NextPart_000_01BDBF1F.DA8F77EE"
Content-Type: multipart/mixed;
    boundary="---- =_NextPart_000_01BDBF1F.DA8F77EE"hkjhgkfhgfhgf"hfkjdhf fhjf fghjghf fdshjfhdsj"
    hgjhgfjk
Content-Type: multipart/mixed;
    boundary="---- =_NextPart_000_01BDBF1F.DA8F77EE"hkjhg
    kfhgfhgf"hfkjdhf fhjf fghjghf fdshjfhdsj"
    hgjhgfjk
Content-Type: multipart/mixed;
    boundary="---- =_NextPart_000_01BDBF1F.DA8F77EE"hhhhhhhhhhhhhhhhhhhhhhhhh
    fjsdhfkjsd fhdjsfhkj
Content-Type: multipart/mixed;
    boundary="---- =_NextPart_000_01BDBF1F.DA8F77EE"
    abc def ghfdgfdsgj fdshfgfsdgfdsg hfsdgjfsdg fgsfgjsg
MIME-Type: text/plain
Test1: _abc _def _ghi _fdjhfd _fhdjkfh _dkhkjd _fdjkf _dshfdks _fhdjfdkhfk
    _dshfds _fdsjk _fdkhfdks _fdsjf _dkf
Test1: _abc _def _ghi _fdjhfd _fhdjkfh _dkhaaaaaaaaaaakjdfdjkfdshfdksfhdjf
    dkhfkdshfdsfdsjkfdkhfdksfdsjf _dkf
EOF
@mail = map { "$_\n" } split /\n/, $headin;

print "not "
	unless $h = new Mail::Header \@mail, Modify => 1;
printf "ok %d\n",++$t;

print $h->as_string,"\n----\n",$headout,"\nnot "
	unless $h->as_string eq $headout;
printf "ok %d\n",++$t;
