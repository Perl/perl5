#!./perl -w

# This is bleadperl's fields.t test at 18784

# We skip this on anything older than 5.9.0 since some semantics changed
# when pseudo-hashes were removed.
if( $] < 5.009 ) {
    print "1..0 # skip fields.pm changed to restricted hashes in 5.9.0\n";
    exit;
}

my $w;

BEGIN {
   $SIG{__WARN__} = sub {
       if ($_[0] =~ /^Hides field 'b1' in base class/) {
           $w++;
           return;
       }
       print STDERR $_[0];
   };
}

use strict;
use warnings;
use vars qw($DEBUG);

use Test::More;


package B1;
use fields qw(b1 b2 b3);

package B2;
use fields '_b1';
use fields qw(b1 _b2 b2);

sub new { fields::new(shift); }

package D1;
use base 'B1';
use fields qw(d1 d2 d3);

package D2;
use base 'B1';
use fields qw(_d1 _d2);
use fields qw(d1 d2);

package D3;
use base 'B2';
use fields qw(b1 d1 _b1 _d1);  # hide b1

package D4;
use base 'D3';
use fields qw(_d3 d3);

package M;
sub m {}

package D5;
use base qw(M B2);

package Foo::Bar;
use base 'B1';

package Foo::Bar::Baz;
use base 'Foo::Bar';
use fields qw(foo bar baz);

# Test repeatability for when modules get reloaded.
package B1;
use fields qw(b1 b2 b3);

package D3;
use base 'B2';
use fields qw(b1 d1 _b1 _d1);  # hide b1

package main;

sub fstr {
   my $h = shift;
   my @tmp;
   for my $k (sort {$h->{$a} <=> $h->{$b}} keys %$h) {
	my $v = $h->{$k};
        push(@tmp, "$k:$v");
   }
   my $str = join(",", @tmp);
   print "$h => $str\n" if $DEBUG;
   $str;
}

my %expect = (
    B1 => "b1:1,b2:2,b3:3",
    B2 => "_b1:1,b1:2,_b2:3,b2:4",
    D1 => "b1:1,b2:2,b3:3,d1:4,d2:5,d3:6",
    D2 => "b1:1,b2:2,b3:3,_d1:4,_d2:5,d1:6,d2:7",
    D3 => "b2:4,b1:5,d1:6,_b1:7,_d1:8",
    D4 => "b2:4,b1:5,d1:6,_d3:9,d3:10",
    D5 => "b1:2,b2:4",
    'Foo::Bar::Baz' => 'b1:1,b2:2,b3:3,foo:4,bar:5,baz:6',
);

plan tests => keys(%expect) + 17;
my $testno = 0;
while (my($class, $exp) = each %expect) {
   no strict 'refs';
   my $fstr = fstr(\%{$class."::FIELDS"});
   is( $fstr, $exp, "\%FIELDS check for $class" );
}

# Did we get the appropriate amount of warnings?
is( $w, 1 );

# A simple object creation and AVHV attribute access test
my B2 $obj1 = D3->new;
$obj1->{b1} = "B2";
my D3 $obj2 = $obj1;
$obj2->{b1} = "D3";

# We should get compile time failures field name typos
eval q(my D3 $obj3 = $obj2; $obj3->{notthere} = "");
like $@, qr/^Attempt to access disallowed key 'notthere' in a restricted hash/;

# Slices
@$obj1{"_b1", "b1"} = (17, 29);
is_deeply($obj1, { b1 => 29, _b1 => 17 });

@$obj1{'_b1', 'b1'} = (44,28);
is_deeply($obj1, { b1 => 28, _b1 => 44 });

eval { fields::phash };
like $@, qr/^Pseudo-hashes have been removed from Perl/;

#fields::_dump();

# check if fields autovivify
{
    package Foo;
    use fields qw(foo bar);
    sub new { fields::new($_[0]) }

    package main;
    my Foo $a = Foo->new();
    $a->{foo} = ['a', 'ok', 'c'];
    $a->{bar} = { A => 'ok' };
    is( $a->{foo}[1],    'ok' );
    is( $a->{bar}->{A},, 'ok' );
}

# check if fields autovivify
{
    package Bar;
    use fields qw(foo bar);
    sub new { return fields::new($_[0]) }

    package main;
    my Bar $a = Bar::->new();
    $a->{foo} = ['a', 'ok', 'c'];
    $a->{bar} = { A => 'ok' };
    is( $a->{foo}[1], 'ok' );
    is( $a->{bar}->{A}, 'ok' );
}


# Test $VERSION bug
package No::Version;

use vars qw($Foo);
sub VERSION { 42 }

package Test::Version;

use base qw(No::Version);
::like( $No::Version::VERSION, qr/set by base.pm/ );

# Test Inverse of $VERSION bug base.pm should not clobber existing $VERSION
package Has::Version;

BEGIN { $Has::Version::VERSION = '42' };

package Test::Version2;

use base qw(Has::Version);
::is( $Has::Version::VERSION, 42 );

package main;

our $eval1 = q{
  {
    package Eval1;
    {
      package Eval2;
      use base 'Eval1';
      $Eval2::VERSION = "1.02";
    }
    $Eval1::VERSION = "1.01";
  }
};

eval $eval1;
is( $@, '' );

is( $Eval1::VERSION, 1.01 );

is( $Eval2::VERSION, 1.02 );


eval q{use base 'reallyReAlLyNotexists';};
like( $@, qr/^Base class package "reallyReAlLyNotexists" is empty./,
                                          'base with empty package');

eval q{use base 'reallyReAlLyNotexists';};
like( $@, qr/^Base class package "reallyReAlLyNotexists" is empty./,
                                          '  still empty on 2nd load');

BEGIN { $Has::Version_0::VERSION = 0 }

package Test::Version3;

use base qw(Has::Version_0);
::is( $Has::Version_0::VERSION, 0, '$VERSION==0 preserved' );

