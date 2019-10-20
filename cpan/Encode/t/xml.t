use strict;
use warnings;

use Encode;
use Test::More;

my $content = String->new("--\x{30c6}--");
my $text = Encode::encode('latin1', $content, Encode::FB_XMLCREF);
is $text, "--&#x30c6;--";

done_testing;

package String;
use overload
  '""' => sub { ${$_[0]} }, fallback => 1;

sub new {
    my($class, $str) = @_;
    bless \$str, $class;
}

1;
