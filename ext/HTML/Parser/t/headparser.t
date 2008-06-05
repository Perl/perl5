#!perl -w

use strict;
use Test::More tests => 11;

{ package H;
  sub new { bless {}, shift; }

  sub header {
     my $self = shift;
     my $key  = uc(shift);
     my $old = $self->{$key};
     if (@_) { $self->{$key} = shift; }
     $old;
  }

  sub push_header {
     my($self, $k, $v) = @_;
     $k = uc($k);
     if (exists $self->{$k}) {
        $self->{$k} = [ $self->{$k} ] unless ref $self->{$k};
	push(@{$self->{$k}}, $v);
     } else {
	$self->{$k} = $v;
     }
  }

  sub as_string {
     my $self = shift;
     my $str = "";
     for (sort keys %$self) {
         if (ref($self->{$_})) {
            my $v;
            for $v (@{$self->{$_}}) {
	        $str .= "$_: $v\n";
            }
         } else {
            $str .= "$_: $self->{$_}\n";
         }
     }
     $str;
  }
}


my $HTML = <<'EOT';

<title>&Aring være eller &#229; ikke være</title>
<meta http-equiv="Expires" content="Soon">
<meta http-equiv="Foo" content="Bar">
<link href="mailto:gisle@aas.no" rev=made title="Gisle Aas">

<script>

   "</script>"
    ignore this

</script>

<base href="http://www.sn.no">
<meta name="Keywords" content="test, test, test,...">
<meta name="Keywords" content="more">

Dette er vanlig tekst.  Denne teksten definerer også slutten på
&lt;head> delen av dokumentet.

<style>

   "</style>"
   ignore this too

</style>

<isindex>

Dette er også vanlig tekst som ikke skal blir parset i det hele tatt.

EOT

$| = 1;

#$HTML::HeadParser::DEBUG = 1;
require HTML::HeadParser;
my $p = HTML::HeadParser->new( H->new );

if ($p->parse($HTML)) {
    fail("Need more data which should not happen");
} else {
    #diag $p->as_string;
    pass();
}

like($p->header('Title'), qr/Å være eller å ikke være/);
is($p->header('Expires'), 'Soon');
is($p->header('Content-Base'), 'http://www.sn.no');
like($p->header('Link'), qr/<mailto:gisle\@aas.no>/);

# This header should not be present because the head ended
ok(!$p->header('Isindex'));


# Try feeding one char at a time
my $expected = $p->as_string;
my $nl = 1;
$p = HTML::HeadParser->new(H->new);
while ($HTML =~ /(.)/sg) {
    #print STDERR '#' if $nl;
    #print STDERR $1;
    $nl = $1 eq "\n";
    $p->parse($1) or last;
}
is($p->as_string, $expected);


# Try reading it from a file
my $file = "hptest$$.html";
die "$file already exists" if -e $file;

open(FILE, ">$file") or die "Can't create $file: $!";
binmode(FILE);
print FILE $HTML;
print FILE "<p>This is more content...</p>\n" x 2000;
print FILE "<title>Buuuh!</title>\n" x 200;
close FILE or die "Can't close $file: $!";

$p = HTML::HeadParser->new(H->new);
$p->parse_file($file);
unlink($file) or warn "Can't unlink $file: $!";

is($p->header("Title"), "Å være eller å ikke være");


# We got into an infinite loop on data without tags and no EOL.
# This was actually a HTML::Parser bug.
open(FILE, ">$file") or die "Can't create $file: $!";
print FILE "Foo";
close(FILE);

$p = HTML::HeadParser->new(H->new);
$p->parse_file($file);
unlink($file) or warn "Can't unlink $file: $!";

ok(!$p->as_string);

SKIP: {
  skip "Need Unicode support", 2 if $] < 5.008;

  # Test that the Unicode BOM does not confuse us?
  $p = HTML::HeadParser->new(H->new);
  ok($p->parse("\x{FEFF}\n<title>Hi <foo></title>"));
  $p->eof;

  is($p->header("title"), "Hi <foo>");
}
