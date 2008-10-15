package Overloaded;
# $Id: /mirror/googlecode/test-more-trunk/t/lib/MyOverload.pm 67132 2008-10-01T01:11:04.501643Z schwern  $

sub new {
    my $class = shift;
    bless { string => shift, num => shift }, $class;
}

package Overloaded::Compare;
use vars qw(@ISA);
@ISA = qw(Overloaded);

# Sometimes objects have only comparison ops overloaded and nothing else.
# For example, DateTime objects.
use overload
  q{eq} => sub { $_[0]->{string} eq $_[1] },
  q{==} => sub { $_[0]->{num} == $_[1] };

package Overloaded::Ify;
use vars qw(@ISA);
@ISA = qw(Overloaded);

use overload
  q{""} => sub { $_[0]->{string} },
  q{0+} => sub { $_[0]->{num} };

1;
