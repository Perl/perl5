#!./perl
#
# check UNIVERSAL
#

print "1..11\n";

$a = {};
bless $a, "Bob";
print "not " unless $a->isa("Bob");
print "ok 1\n";

package Human;
sub eat {}

package Female;
@ISA=qw(Human);

package Alice;
@ISA=qw(Bob Female);
sub drink {}
sub new { bless {} }

package main;
$a = new Alice;

print "not " unless $a->isa("Alice");
print "ok 2\n";

print "not " unless $a->isa("Bob");
print "ok 3\n";

print "not " unless $a->isa("Female");
print "ok 4\n";

print "not " unless $a->isa("Human");
print "ok 5\n";

print "not " if $a->isa("Male");
print "ok 6\n";

print "not " unless $a->can("drink");
print "ok 7\n";

print "not " unless $a->can("eat");
print "ok 8\n";

print "not " if $a->can("sleep");
print "ok 9\n";

print "not " unless UNIVERSAL::isa([], "ARRAY");
print "ok 10\n";

print "not " unless UNIVERSAL::isa({}, "HASH");
print "ok 11\n";
