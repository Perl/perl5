BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Locale::Maketext 1.01;
print "# Perl v$], Locale::Maketext v$Locale::Maketext::VERSION\n";
$loaded = 1;
print "ok 1\n";
{
  package Woozle;
  @ISA = ('Locale::Maketext');
  sub dubbil { return $_[1] * 2 }
}
{
  package Woozle::elx;
  @ISA = ('Woozle');
  %Lexicon = (
   'd2' => 'hum [dubbil,_1]',
  );
}

$lh = Woozle->get_handle('elx');
if($lh) {
  print "ok 2\n";
  my $x = $lh->maketext('d2', 7);
  if($x eq "hum 14") {
    print "ok 3\n";
  } else {
    print "not ok 3\n  (got \"$x\")\n";
  }
} else {
  print "not ok 2\n";
}
#Shazam!
