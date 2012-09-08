#!./perl
#
# Tests for named prototypes
# 

my @warnings;

BEGIN {
    chdir 't' if -d 't';
    @INC = ('../lib','.');
    require './test.pl';
    $SIG{'__WARN__'} = sub { push @warnings, @_ };
    $| = 1;
}

use warnings;
use Scalar::Util qw(set_prototype);

BEGIN {
    plan tests => 18;  # Update this when adding/deleting tests.
}

# Not yet implemented: Greedy
# Arrays (@array = ()) silences the used only once warning)
sub greedyarray(@array){return $#array; @array = ();}
BEGIN {
    local $TODO = "Named arrays not yet implemented";
    is($#warnings,-1);
    print "# $warnings[0]" if $#warnings >= 0;
    my @array = qw(1 2 3);
    is(greedyarray(@array),2);
    is(greedyarray(1,2,3),2);
    @warnings = ();
}

# Hashes (%hash = ()) silences the used only once warning)
sub greedyhash(%hash){my @keys = sort keys %hash; return "@keys"; %hash = ();}
BEGIN {
    local $TODO = "Named hashes not yet implemented";
    is($#warnings,-1);
    print "# $warnings[0]" if $#warnings >= 0;
    my %hash = (c => 1, d => 2);
    is(greedyhash(%hash),"c d");
    is(greedyhash("c",1,"d",2),"c d");
    @warnings = ();
}

# Checking params
sub onep($one){ return "$one"; }
is(onep("A"), "A", "Checking one param");

sub twop($one,$two){ return "$one $two"; }
is(twop("A","B"), "A B", "Checking two param");

sub recc($a,$c){ return recc("$a $a",$c-1) if $c; return $a; }
is(recc("A", 2), "A A A A", "Checking recursive");
is($#warnings,-1,"No warnings checking params");
print "@warnings" if $#warnings != -1;

# Make sure whitespace doesn't matter
sub whitespace (  $a  ,  $b   ) { return $b; }
BEGIN {
    is($#warnings,-1,"No warnings with extra whitespace in the definition");
    print "# $warnings[0]" if $#warnings >= 0;
    @warnings = ();
}
is(whitespace(4,5),5,"Prototype ignores whitespace");


# Testing readonly
my $a = 5;
sub testro($a){ $a = 5; }
eval { testro($a); };
like($@,"read-only","Args should be passed read-only");

# Checking old prototype behavior
sub oldproto(*){ my $name = shift; return $name;}
is(oldproto STDOUT,"STDOUT", "Traditional prototype behavior still works");

sub manualproto($name){ return $name; }
BEGIN { set_prototype(\&manualproto,"*");}
is(manualproto STDOUT, "STDOUT", "Forcing it with set_prototype works");

sub manualrecproto($name){
    BEGIN { set_prototype(\&manualrecproto,"*");}
    return $name;
}
BEGIN {
    local $TODO = "Not sure how to use set_prototype for a recursive";
    is($#warnings,-1);
    print "# $warnings[0]" if $#warnings >= 0;
    @warnings = ();
}

sub ignoredproto(*);
sub ignoredproto($name){ return $name;}
BEGIN {
    is($#warnings,0,"Should have exactly one error");
    like($warnings[0],"vs none","ignoredproto should complain of a mismatch");
    @warnings = ();
}

# Test UTF-8

1;
