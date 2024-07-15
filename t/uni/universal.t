#!./perl
#
# check UNIVERSAL
#

BEGIN {
    chdir 't' if -d 't';
    $| = 1;
    require "./test.pl";
    set_up_inc(qw '../lib ../dist/base/lib');
}

use utf8;
use open qw( :utf8 :std );

plan tests => 105;

$a = {};
bless $a, "Bòb";
ok $a->isa("Bòb");

package Hùmàn;
sub èàt {}

package Fèmàlè;
@ISA=qw(Hùmàn);

package Àlìcè;
@ISA=qw(Bòb Fèmàlè);
sub sìng;
sub drìnk { return "drinking " . $_[1]  }
sub nèw { bless {} }

$Àlìcè::VERSION = 2.718;

{
    package Cèdrìc;
    our @ISA;
    use base qw(Hùmàn);
}

{
    package Prògràmmèr;
    our $VERSION = 1.667;

    sub wrìtè_perl { 1 }
}

package main;

$a = nèw Àlìcè;

ok $a->isa("Àlìcè");
ok $a->isa("main::Àlìcè");    # check that alternate class names work
ok(("main::Àlìcè"->nèw)->isa("Àlìcè"));

ok $a->isa("Bòb");
ok $a->isa("main::Bòb");

ok $a->isa("Fèmàlè");

ok $a->isa("Hùmàn");

ok ! $a->isa("Màlè");

ok ! $a->isa('Prògràmmèr');

ok $a->isa("HASH");

ok $a->can("èàt");
ok ! $a->can("sleep");
ok my $ref = $a->can("drìnk");        # returns a coderef
is $a->$ref("tèà"), "drinking tèà"; # ... which works
ok $ref = $a->can("sìng");
eval { $a->$ref() };
ok $@;                                # ... but not if no actual subroutine

ok $a->can("VERSION");
cmp_ok eval { $a->VERSION }, '==', 2.718;
ok ! (eval { $a->VERSION(2.719) });
like $@, qr/^Àlìcè version 2.719 required--this is only version 2.718 at /u;

ok (!Cèdrìc->isa('Prògràmmèr'));

ok (Cèdrìc->isa('Hùmàn'));

push(@Cèdrìc::ISA,'Prògràmmèr');

ok (Cèdrìc->isa('Prògràmmèr'));

{
    package Àlìcè;
    base::->import('Prògràmmèr');
}

ok $a->isa('Prògràmmèr');
ok $a->isa("Fèmàlè");

@Cèdrìc::ISA = qw(Bòb);

ok (!Cèdrìc->isa('Prògràmmèr'));

my $b = 'abc';
my @refs = qw(SCALAR SCALAR     LVALUE      GLOB ARRAY HASH CODE);
my @vals = (  \$b,   \3.14, \substr($b,1,1), \*b,  [],  {}, sub {} );
for ($p=0; $p < @refs; $p++) {
    for ($q=0; $q < @vals; $q++) {
        is UNIVERSAL::isa($vals[$p], $refs[$q]), ($p==$q or $p+$q==1);
    };
};


ok UNIVERSAL::isa(Àlìcè => "UNIVERSAL");

cmp_ok UNIVERSAL::can(Àlìcè => "can"), '==', \&UNIVERSAL::can;

eval 'sub UNIVERSAL::slèèp {}';
ok $a->can("slèèp");

package Fòò;

sub DOES { 1 }

package Bàr;

@Bàr::ISA = 'Fòò';

package Bàz;

package main;
ok( Fòò->DOES( 'bàr' ), 'DOES() should call DOES() on class' );
ok( Bàr->DOES( 'Bàr' ), '... and should fall back to isa()' );
ok( Bàr->DOES( 'Fòò' ), '... even when inherited' );
ok( Bàz->DOES( 'Bàz' ), '... even without inheriting any other DOES()' );
ok( ! Bàz->DOES( 'Fòò' ), '... returning true or false appropriately' );

package Pìg;
package Bòdìnè;
Bòdìnè->isa('Pìg');

package main;
eval { UNIVERSAL::DOES([], "fòò") };
like( $@, qr/Can't call method "DOES" on unblessed reference/,
    'DOES call error message says DOES, not isa' );

# Tests for can seem to be split between here and method.t
# Add the verbatim perl code mentioned in the comments of
# http://www.xray.mpe.mpg.de/mailing-lists/perl5-porters/2001-05/msg01710.html
# but never actually tested.
is(UNIVERSAL->can("NòSùchPàckàgè::fòò"), undef);

@splàtt::ISA = 'zlòpp';
ok (splàtt->isa('zlòpp'));
ok (!splàtt->isa('plòp'));

# This should reset the ->isa lookup cache
@splàtt::ISA = 'plòp';
# And here is the new truth.
ok (!splàtt->isa('zlòpp'));
ok (splàtt->isa('plòp'));

#
# Check that ->can() can now accept a list of methods
#

package Parent {
    sub new { return bless {}, shift }
    sub foo { return __PACKAGE__ }
    sub bar { return __PACKAGE__ }
}
package Child {
    our @ISA = qw(Parent);
    sub bar { return __PACKAGE__ }
    sub baz { return __PACKAGE__ }
}

my $foo        = \&Parent::foo;
my $parent_bar = \&Parent::bar;
my $child_bar  = \&Child::bar;
my $baz        = \&Child::baz;

ok( my @methods = Child->can(qw(foo bar baz)) );
is(scalar @methods, 3, 'should return 3 methods');
is( builtin::refaddr($methods[0]), builtin::refaddr($foo), 'foo should return our parent method' );
is( builtin::refaddr($methods[1]), builtin::refaddr($child_bar), 'bar should return our child method');
is( builtin::refaddr($methods[2]), builtin::refaddr($baz), 'baz should return our child method' );
ok( Child->can(qw(foo bar baz)), 'can(@methods) in scalar content should return a true value' );

my $child = Child->new;
ok( @methods = $child->can(qw(bar baz)) );
is(scalar @methods, 2, 'should return 2 methods');
is( builtin::refaddr($methods[0]), builtin::refaddr($child_bar), 'bar should return our child method' );
is( builtin::refaddr($methods[1]), builtin::refaddr($baz), 'baz should return our child method' );
ok( scalar $child->can(qw(bar baz)), 'can(@methods) in scalar content should return a true value' );

ok( !Child->can(qw(foo baz no_such_method)), 'can(@methods) with non-existent methods should already return nothing' );
ok( !scalar Child->can(qw(foo baz no_such_method)), 'can(@methods) with non-existent methods should return false in scalar context' );

#
# Check that can() returns an empty list when called with missing methods
#
@methods = Child->can(qw(no_such_method));
ok( !@methods, 'can(@methods) with non-existent methods should already return nothing even when assigned to an array' );
@methods = $child->can(qw(no_such_method));
ok( !@methods, 'can(@methods) with non-existent methods should return even when assigned to an array' );
