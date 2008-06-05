
use strict;
require HTML::Parser;

my $decl = '<!ENTITY nbsp   CDATA "&#160;" -- no-break space -->';
my $com1 = '<!-- Comment -->';
my $com2 = '<!-- Comment -- -- Comment -->';
my $start = '<a href="foo">';
my $end = '</a>';
my $empty = "<IMG SRC='foo'/>";
my $proc = '<? something completely different ?>';

my @argspec = qw( self offset length
		  event tagname tag token0
	          text
	          is_cdata dtext
	          tokens
	          tokenpos
	          attr
	          attrseq );

my @result = ();
my $p = HTML::Parser -> new(default_h => [\@result, join(',', @argspec)],
			    strict_comment => 1, xml_mode => 1);

my @tests =
    ( # string, expected results
      $decl  => [[$p, 0, 52, 'declaration', 'ENTITY', '!ENTITY', 'ENTITY',
		 '<!ENTITY nbsp   CDATA "&#160;" -- no-break space -->',
		 undef, undef,
	       ['ENTITY', 'nbsp', 'CDATA', '"&#160;"', '-- no-break space --'],
		 [2, 6, 9, 4, 16, 5, 22, 8, 31, 20],
		 undef, undef ]],
      $com1  => [[$p, 0, 16, 'comment', ' Comment ', '# Comment ', ' Comment ',
		 '<!-- Comment -->', 
		 undef, undef,
		 [' Comment '],
		 [4, 9],
		 undef, undef ]],
      $com2  => [[$p, 0, 30, 'comment', ' Comment ', '# Comment ', ' Comment ',
		 '<!-- Comment -- -- Comment -->',
		 undef, undef,
		 [' Comment ', ' Comment '],
		 [4, 9, 18, 9],
		 undef, undef ]],
      $start => [[$p, 0, 14, 'start', 'a', 'a', 'a',
		 '<a href="foo">', 
		 undef, undef,
		 ['a', 'href', '"foo"'],
		 [1, 1, 3, 4, 8, 5],
		 {'href', 'foo'}, ['href'] ]],
      $end   => [[$p, 0, 4, 'end', 'a', '/a', 'a',
		 '</a>',
		 undef, undef,
		 ['a'],
		 [2, 1],
		 undef, undef ]],
      $empty => [[$p, 0, 16, 'start', 'IMG', 'IMG', 'IMG',
		  "<IMG SRC='foo'/>",
		  undef, undef,
		  ['IMG', 'SRC', "'foo'"],
		  [1, 3, 5, 3, 9, 5],
		  {'SRC', 'foo'}, ['SRC'] ],
		 [$p, 16, 0, 'end', 'IMG', '/IMG', 'IMG',
		  '',
		  undef, undef,
		  ['IMG'],
		  undef,
		  undef, undef ],
		 ],
       $proc  => [[$p, 0, 36, 'process', ' something completely different ',
		  '? something completely different ',
		  ' something completely different ',
		  '<? something completely different ?>',
		  undef, undef,
		  [' something completely different '],
		  [2, 32],
		  undef, undef ]],
      "$end\n$end"   => [[$p, 0, 4, 'end', 'a', '/a', 'a',
			  '</a>',
			  undef, undef,
			  ['a'],
			  [2, 1],
			  undef, undef],
			 [$p, 4, 1, 'text', undef, undef, undef,
			  "\n",
			  '', "\n",
			  undef,
			  undef,
			  undef, undef],
			 [$p, 5, 4, 'end', 'a', '/a', 'a',
			  '</a>',
			  undef, undef,
			  ['a'],
			  [2, 1],
			  undef, undef ]],
      );

use Test::More;
plan tests => @tests / 2;

sub string_tag {
    my (@pieces) = @_;
    my $part;
    foreach $part ( @pieces ) {
	if (!defined $part) {
	    $part = 'undef';
	}
	elsif (!ref $part) {
	    $part = "'$part'" if $part !~ /^\d+$/;
	}
	elsif ('ARRAY' eq ref $part ) {
	    $part = '[' . join(', ', string_tag(@$part)) . ']';
	}
	elsif ('HASH' eq ref $part ) {
	    $part = '{' . join(',', string_tag(%$part)) . '}';
	}
	else {
	    $part = '<' . ref($part) . '>';
	}
    }
    return join(", ", @pieces );
}

my $i = 0;
TEST:
while (@tests) {
    my($html, $expected) = splice @tests, 0, 2;
    ++$i;

    @result = ();
    $p->parse($html)->eof;

    shift(@result) if $result[0][3] eq "start_document";
    pop(@result)   if $result[-1][3] eq "end_document";

    # Compare results for each element expected
    foreach (@$expected) {
	my $want = string_tag($_);
	my $got = string_tag(shift @result);
	if ($want ne $got) {
           is($want, $got);
           next TEST;
        }
    }

    pass;
}
