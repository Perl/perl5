#! /usr/local/bin/perl -w


BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

BEGIN { print "1..20\n"; }

use NEXT;

print "ok 1\n";

package A;
sub A::method   { return ( 3, $_[0]->NEXT::method() ) }
sub A::DESTROY  { $_[0]->NEXT::DESTROY() }

package B;
use base qw( A );
sub B::AUTOLOAD { return ( 9, $_[0]->NEXT::AUTOLOAD() ) }
sub B::DESTROY  { $_[0]->NEXT::DESTROY() }

package C;
sub C::DESTROY  { print "ok 18\n"; $_[0]->NEXT::DESTROY() }

package D;
@D::ISA = qw( B C E );
sub D::method   { return ( 2, $_[0]->NEXT::method() ) }
sub D::AUTOLOAD { return ( 8, $_[0]->NEXT::AUTOLOAD() ) }
sub D::DESTROY  { print "ok 17\n"; $_[0]->NEXT::DESTROY() }
sub D::oops     { $_[0]->NEXT::method() }

package E;
@E::ISA = qw( F G );
sub E::method   { return ( 4,  $_[0]->NEXT::method(), $_[0]->NEXT::method() ) }
sub E::AUTOLOAD { return ( 10, $_[0]->NEXT::AUTOLOAD() ) }
sub E::DESTROY  { print "ok 19\n"; $_[0]->NEXT::DESTROY() }

package F;
sub F::method   { return ( 5  ) }
sub F::AUTOLOAD { return ( 11 ) }
sub F::DESTROY  { print "ok 20\n" }

package G;
sub G::method   { return ( 6 ) }
sub G::AUTOLOAD { print "not "; return }
sub G::DESTROY  { print "not ok 21"; return }

package main;

my $obj = bless {}, "D";

my @vals;

# TEST NORMAL REDISPATCH (ok 2..6)
@vals = $obj->method();
print map "ok $_\n", @vals;

# RETEST NORMAL REDISPATCH SHOULD BE THE SAME (ok 7)
@vals = $obj->method();
print "not " unless join("", @vals) == "23456";
print "ok 7\n";

# TEST AUTOLOAD REDISPATCH (ok 8..11)
@vals = $obj->missing_method();
print map "ok $_\n", @vals;

# NAMED METHOD CAN'T REDISPATCH TO NAMED METHOD OF DIFFERENT NAME (ok 12)
eval { $obj->oops() } && print "not ";
print "ok 12\n";

# AUTOLOAD'ED METHOD CAN'T REDISPATCH TO NAMED METHOD (ok 13)
eval q{
	package C;
	sub AUTOLOAD { $_[0]->NEXT::method() };
};
eval { $obj->missing_method(); } && print "not ";
print "ok 13\n";

# NAMED METHOD CAN'T REDISPATCH TO AUTOLOAD'ED METHOD (ok 14)
eval q{ 
	package C;
	sub method { $_[0]->NEXT::AUTOLOAD() };
};
eval { $obj->method(); } && print "not ";
print "ok 14\n";

# BASE CLASS METHODS ONLY REDISPATCHED WITHIN HIERARCHY (ok 15..16)
my $ob2 = bless {}, "B";
@val = $ob2->method();         
print "not " unless @val==1 && $val[0]==3;
print "ok 15\n";

@val = $ob2->missing_method(); 
print "not " unless @val==1 && $val[0]==9;
print "ok 16\n";

# CAN REDISPATCH DESTRUCTORS (ok 17..20)
