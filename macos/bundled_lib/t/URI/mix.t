print "1..6\n";

# Test mixing of URI and URI::WithBase objects
use URI;
use URI::WithBase;
use URI::URL;

$str = "http://www.sn.no";
$rel = "path/img.gif";

$u  = URI->new($str);
$uw = URI::WithBase->new($str, "http:");
$uu = URI::URL->new($str);

sub Dump
{
   require Data::Dumper;
   print Data::Dumper->Dump([$a, $b, $c, $d], [qw(a b c d)]);
}

$a = URI->new($rel, $u);
$b = URI->new($rel, $uw);
$c = URI->new($rel, $uu);
$d = URI->new($rel, $str);

#Dump();
print "not " unless $a->isa("URI") &&
                    ref($b) eq ref($uw) &&
                    ref($c) eq ref($uu) &&
                    $d->isa("URI");
print "ok 1\n";

print "not " if $b->base && $c->base;
print "ok 2\n";

$a = URI::URL->new($rel, $u);
$b = URI::URL->new($rel, $uw);
$c = URI::URL->new($rel, $uu);
$d = URI::URL->new($rel, $str);

print "not " unless ref($a) eq "URI::URL" &&
                    ref($b) eq "URI::URL" &&
                    ref($c) eq "URI::URL" &&
                    ref($d) eq "URI::URL";
print "ok 3\n";

print "not " unless ref($b->base) eq ref($uw) &&
                    $b->base eq $uw &&
                    ref($c->base) eq ref($uu) &&
                    $c->base eq $uu &&
                    $d->base eq $str;
print "ok 4\n";



$a = URI->new($uu, $u);
$b = URI->new($uu, $uw);
$c = URI->new($uu, $uu);
$d = URI->new($uu, $str);

#Dump();
print "not " unless ref($a) eq ref($b) &&
                    ref($b) eq ref($c) &&
                    ref($c) eq ref($d) &&
                    ref($d) eq ref($u);
print "ok 5\n";

$a = URI::URL->new($u, $u);
$b = URI::URL->new($u, $uw);
$c = URI::URL->new($u, $uu);
$d = URI::URL->new($u, $str);

print "not " unless ref($a) eq "URI::URL" &&
                    ref($b) eq "URI::URL" &&
                    ref($c) eq "URI::URL" &&
                    ref($d) eq "URI::URL";
print "ok 6\n";
