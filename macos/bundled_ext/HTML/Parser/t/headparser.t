print "1..4\n";

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


$HTML = <<'EOT';

<title>&Aring være eller &#229; ikke være</title>
<meta http-equiv="Expires" content="Soon">
<meta http-equiv="Foo" content="Bar">
<link href="mailto:gisle@aas.no" rev=made title="Gisle Aas">

<script>

    ignore this

</script>

<base href="http://www.sn.no">
<meta name="Keywords" content="test, test, test,...">
<meta name="Keywords" content="more">

Dette er vanlig tekst.  Denne teksten definerer også slutten på
&lt;head> delen av dokumentet.

<style>

   ignore this too

</style>

<isindex>

Dette er også vanlig tekst som ikke skal blir parset i det hele tatt.

EOT

$| = 1;

#$HTML::HeadParser::DEBUG = 1;
require HTML::HeadParser;
$p = HTML::HeadParser->new( H->new );

$bad = 0;

print "\n#### Parsing full text...\n";
if ($p->parse($HTML)) {
    $bad++;
    print "Need more data which should not happen\n";
} else {
    print $p->as_string;
}

$p->header('Title') =~ /Å være eller å ikke være/ or $bad++;
$p->header('Expires') eq 'Soon' or $bad++;
$p->header('Content-Base') eq 'http://www.sn.no' or $bad++;
$p->header('Link') =~ /<mailto:gisle\@aas.no>/ or $bad++;

# This header should not be present because the head ended
$p->header('Isindex') and $bad++;

print "not " if $bad;
print "ok 1\n";


# Try feeding one char at a time
print "\n\n#### Parsing once char at a time...\n";
$expected = $p->as_string;
$p = HTML::HeadParser->new(H->new);
while ($HTML =~ /(.)/sg) {
    print $1;
    $p->parse($1) or last;
}
print "«««« Enough!!\n";
$got = $p->as_string;
print "$got";
print "not " if $expected ne $got;
print "ok 2\n";


# Try reading it from a file
print "\n\n#### Parsing from file\n\n";
my $file = "hptest$$.html";
die "$file already exists" if -e $file;

open(FILE, ">$file") or die "Can't create $file: $!";
print FILE $HTML;
print FILE "<p>This is more content...</p>\n" x 2000;
print FILE "<title>Buuuh!</title>\n" x 200;
close FILE or die "Can't close $file: $!";

$p = HTML::HeadParser->new(H->new);
$p->parse_file($file);
unlink($file) or warn "Can't unlink $file: $!";

print $p->as_string;

print "not " if $p->header("Title") ne "Å være eller å ikke være";
print "ok 3\n";


# We got into an infinite loop on data without tags and no EOL.
# This was actually a HTML::Parser bug.
print "\n\n#### Try to reproduce bug with empty file\n\n";
open(FILE, ">$file") or die "Can't create $file: $!";
print FILE "Foo";
close(FILE);

$p = HTML::HeadParser->new(H->new);
$p->parse_file($file);
unlink($file) or warn "Can't unlink $file: $!";

print "not " if $p->as_string;
print "ok 4\n";


