print "1..1\n";

use strict;
use HTML::Parser ();

my $HTML = <<'EOT';

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
 "http://www.w3.org/TR/html40/strict.dtd">

<foo bar baz=3>heisan
</foo> <?process>
<!-- comment -->
<xmp>xmp</xmp>

EOT

my $p = HTML::Parser->new(api_version => 3);

my $sum_len = 0;
my $count = 0;
my $err;

$p->handler(default =>
	    sub {
		my($offset, $length, $offset_end, $line, $col, $text) = @_;
		my $copy = $text;
		$copy =~ s/\n/\\n/g;
		substr($copy, 30) = "..." if length($copy) > 32;
		printf ">>> %d.%d %s\n", $line, $col, $copy;
		if ($offset != $sum_len) {
		   print "offset mismatch $offset vs $sum_len\n";
		   $err++;
                }
		if ($offset_end != $offset + $length) {
		   print "offset_end $offset_end wrong\n";
		   $err++;
                }
		if ($length != length($text)) {
		   print "length mismatch\n";
		   $err++;
		}
                if (substr($HTML, $offset, $length) ne $text) {
		   print "content mismatch\n";
		   $err++;
		}
		$sum_len += $length;
		$count++;
	    },
	    'offset,length,offset_end,line,column,text');

for (split(//, $HTML)) {
   $p->parse($_);
}
$p->eof;

print "not " unless $count > 5 && !$err;
print "ok 1\n";


