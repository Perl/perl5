#!perl -w

require Mail::Internet;
use Config;

print "1..3\n";
$|=1;

$head = <<EOF;
From from_\@localhost
To: Some perl administrator <$Config{perladmin}>
From: Somebody <$ENV{LOGNAME}\@localhost>
Subject: Mail::Internet test subject
EOF

$body = <<EOF;
This is a test message that was sent by the test suite of
Mail::Internet.

Testing.

one

From foo
four

>From bar
seven
EOF

$mail = "$head\n$body";
($mbox = $mail) =~ s/^(>*)From /$1>From /gm;
$mbox =~ s/^>From /From / or die;
$mbox .= "\n";
@mail = map { "$_\n" } split /\n/, $mail;

sub ok {
    my ($n, $result, @info) = @_;
    if ($result) {
    	print "ok $n\n";
    }
    else {
    	for (@info) {
	    s/^/# /mg;
	}
    	print "not ok $n\n", @info;
	print "\n" if @info && $info[-1] !~ /\n$/;
    }
}

ok 1, $i = new Mail::Internet \@mail, Modify => 0;
ok 2, $i->as_string eq $mail, $i->as_string;
ok 3, $i->as_mbox_string eq $mbox, $i->as_mbox_string;
#ok 4, $i->send;




