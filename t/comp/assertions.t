#!./perl

my $i=1;
print "1..10\n";

sub callme ($) : assertion {
    return shift;
}


# 1
if (callme(1)) {
    print STDERR "assertions called by default";
    print "not ";
}
print "ok ", $i++, "\n";

# 2
use assertions::activate 'mine';
{
  package mine;
  sub callme ($) : assertion {
    return shift;
  }
  use assertions;
  unless (callme(1)) {
    print STDERR "'use assertions;' doesn't active assertions based on package name";
    print "not ";
  }
}
print "ok ", $i++, "\n";

# 3
use assertions 'foo';
if (callme(1)) {
    print STDERR "assertion deselection doesn't work";
    print "not ";
}
print "ok ", $i++, "\n";

# 4
use assertions::activate 'bar', 'doz';
use assertions 'bar';
unless (callme(1)) {
    print STDERR "assertion selection doesn't work";
    print "not ";
}
print "ok ", $i++, "\n";

# 5
use assertions '&', 'doz';
unless (callme(1)) {
    print STDERR "assertion activation filtering doesn't work";
    print "not ";
}
print "ok ", $i++, "\n";

# 6
use assertions '&', 'foo';
if (callme(1)) {
    print STDERR "assertion deactivation filtering doesn't work";
    print "not ";
}
print "ok ", $i++, "\n";

# 7
if (1) {
    use assertions 'bar';
}
if (callme(1)) {
    print STDERR "assertion scoping doesn't work";
    print "not ";
}
print "ok ", $i++, "\n";

# 8
use assertions::activate 're.*';
use assertions 'reassert';
unless (callme(1)) {
    print STDERR "assertion selection with re failed";
    print "not ";
}
print "ok ", $i++, "\n";

# 9
my $b=12;
{
    use assertions 'bar';
    callme(my $b=45);
    unless ($b == 45) {
	print STDERR "this shouldn't fail ever (b=$b)";
	print "not ";
    }
}
print "ok ", $i++, "\n";

# 10
{
    no assertions;
    callme(my $b=46);
    if (defined $b) {
	print STDERR "lexical declaration in assertion arg ignored";
	print "not ";
    }
}
print "ok ", $i++, "\n";
