

require HTML::Parser;

package P; @ISA = qw(HTML::Parser);

my @result;
sub start
{
    my($self, $tag, $attr) = @_;
    print "START[$tag]\n";
    push @result, "START[$tag]";
    for (sort keys %$attr) {
	print "\t$_: $attr->{$_}\n";
        push @result, "\t$_: " . $attr->{$_};
    }
    $start++;
}

sub end
{
    my($self, $tag) = @_;
    print "END[$tag]\n";
    push @result, "END[$tag]";
    $end++;
}

sub text
{
    my $self = shift;
    print "TEXT[$_[0]]\n";
    push @result, "TEXT[$_[0]]";
    $text++;
}

sub comment
{
    my $self = shift;
    print "COMMENT[$_[0]]\n";
    push @result, "COMMENT[$_[0]]";
    $comment++;
}

sub declaration
{
    my $self = shift;
    print "DECLARATION[$_[0]]\n";
    push @result, "DECLARATION[$_[0]]";
    $declaration++;
}

package main;


@tests =
    (
     '<a ">' => ['START[a]', "\t\": \""],
     '<å >' => ['TEXT[<å]', 'TEXT[ >]'],
     '2 < 5' => ['TEXT[2 ]', 'TEXT[<]', 'TEXT[ 5]'],
     '2 <5> 2' => ['TEXT[2 ]', 'TEXT[<5>]', 'TEXT[ 2]'],
     '2 <a' => ['TEXT[2 ]', 'TEXT[<a]'],
     '2 <a> 2' => ['TEXT[2 ]', 'START[a]', 'TEXT[ 2]'],
     '2 <a href=foo' => ['TEXT[2 ]', 'TEXT[<a href=foo]'],
     "2 <a href='foo bar'> 2" =>
         ['TEXT[2 ]', 'START[a]', "\thref: foo bar", 'TEXT[ 2]'],
     '2 <a href=foo bar> 2' =>
         ['TEXT[2 ]', 'START[a]', "\tbar: bar", "\thref: foo", 'TEXT[ 2]'],
     '2 <a href="foo bar"> 2' =>
         ['TEXT[2 ]', 'START[a]', "\thref: foo bar", 'TEXT[ 2]'],
     '2 <a href="foo\'bar"> 2' =>
         ['TEXT[2 ]', 'START[a]', "\thref: foo'bar", 'TEXT[ 2]'],
     "2 <a href='foo\"bar'> 2" =>
         ['TEXT[2 ]', 'START[a]', "\thref: foo\"bar", 'TEXT[ 2]'],
     "2 <a href='foo&quot;bar'> 2" =>
         ['TEXT[2 ]', 'START[a]', "\thref: foo\"bar", 'TEXT[ 2]'],
     '2 <a.b> 2' => ['TEXT[2 ]', 'START[a.b]', 'TEXT[ 2]'],
     '2 <a.b-12 a.b = 2 a> 2' =>
         ['TEXT[2 ]', 'START[a.b-12]', "\ta: a", "\ta.b: 2", 'TEXT[ 2]'],
     '2 <a_b> 2' => ['TEXT[2 ]', 'START[a_b]', 'TEXT[ 2]'],
     '<!ENTITY nbsp   CDATA "&#160;" -- no-break space -->' =>
         ['DECLARATION[ENTITY nbsp   CDATA "&#160;" -- no-break space --]'],
     '<!-- comment -->' => ['COMMENT[ comment ]'],
     '<!-- comment -- --- comment -->' =>
         ['COMMENT[ comment ]', 'COMMENT[- comment ]'],
     '<!-- comment <!-- not comment --> comment -->' =>
         ['COMMENT[ comment <!]', 'COMMENT[> comment ]'],
     '<!-- <a href="foo"> -->' => ['COMMENT[ <a href="foo"> ]'],
     );
my $n = @tests / 2;
print "1..$n\n";

my ($html, $expected, $got, $i);
$i = 0;
while (@tests) {
    ++$i;
    ($html, $expected) = splice @tests, 0, 2;
    print "-" x 50, " $i\n";
    print "$html\n";
    print "-" x 50, " $i\n";
    @result = ();

   $p = new P;
   $p->strict_comment(1);
    $p->parse($html)->eof;
   
    foreach (@$expected) {
	$got = shift @result;
	if ($_ ne $got) {
	    print "Expected: $_\n",
	          "Got:      $got\n";
	    print( "not " );
	    last; 
	}
    }

   print "ok $i\n";
}
