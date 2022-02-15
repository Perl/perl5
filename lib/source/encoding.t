#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl'; require './charset_tools.pl';
}

use strict;
use warnings;
use feature 'evalbytes';

# Below, the _N suffix indicates what I expect to be in a string:
#   1 - codepoints( U+41, U+FF )        - octets( 41, C3, BF )
#   2 - codepoints( U+41, U+79, U+308 ) - octets( 41, 79 CC 88 )
#   3 - codepoints( U+41, U+79, U+3A )  - octets( 41, 79 3A )
#   4 - codepoints( U+41, U+FF )        - octets( 41, U+FF )
my $str_1 = do { use source::encoding 'utf8'; "Aÿ" };
is($str_1, "\x{41}\x{FF}", "utf8, non-ASCII composed codepoint");

my $str_2 = do { use source::encoding 'utf8'; "Aÿ" };
is($str_2, "\x{41}\x{79}\x{308}", "utf8, non-ASCII, decomposed codepoint");

my $str_3 = do { "Ay:" };
is($str_3, "\x{41}\x{79}\x{3A}", "no encoding, ASCII");
is(do { use source::encoding 'utf8'; "Ay:" }, $str_3, "utf8, ASCII content");
is(do { use source::encoding 'ascii'; "Ay:" }, $str_3, "ASCII, ASCII content");

my $str_4 = evalbytes "'A\x{FF}'";
is($str_4, "\x{41}\x{FF}", "no encoding, non-7-bit clean");

{
  my $rv  = evalbytes "use source::encoding 'ascii'; '$str_4'";
  my $err = $@;
  is($rv, undef, "ascii, non-7-bit clean source: eval to q{}");
  ok(
    $err =~ /Use of non-ASCII character 0xFF illegal/,
    "ascii, non-7-bit clean source: error"
  );
}

{
  my $rv  = evalbytes <<~"END";
    use source::encoding 'ascii';
    '$str_3';
    no source::encoding;
    '$str_4';
    END

  my $err = $@;

  # Returns the final line
  isnt($rv, undef, "on-then-off encoding: non-7-bit is okay");

  is($err, '', "on-then-off encoding; no error");
}

done_testing();
