print "1..7\n";

use URI;

$u = URI->new("news:comp.lang.perl.misc");

print "not " unless $u->group eq "comp.lang.perl.misc" &&
                    !defined($u->message) &&
		    $u->port == 119 &&
		    $u eq "news:comp.lang.perl.misc";
print "ok 1\n";


$u->host("news.online.no");
print "not " unless $u->group eq "comp.lang.perl.misc" &&
                    $u->port == 119 &&
                    $u eq "news://news.online.no/comp.lang.perl.misc";
print "ok 2\n";

$u->group("no.perl", 1 => 10);
print "not " unless $u eq "news://news.online.no/no.perl/1-10";
print "ok 3\n";

@g = $u->group;
#print "G: @g\n";
print "not " unless @g == 3 && "@g" eq "no.perl 1 10";
print "ok 4\n";

$u->message('42@g.aas.no');
#print "$u\n";
print "not " unless $u->message eq '42@g.aas.no' &&
                    !defined($u->group) &&
                    $u eq 'news://news.online.no/42@g.aas.no';
print "ok 5\n";


$u = URI->new("nntp:no.perl");
print "not " unless $u->group eq "no.perl" &&
                    $u->port == 119;
print "ok 6\n";

$u = URI->new("snews://snews.online.no/no.perl");

print "not " unless $u->group eq "no.perl" &&
	            $u->host  eq "snews.online.no" &&
                    $u->port == 563;
print "ok 7\n";

