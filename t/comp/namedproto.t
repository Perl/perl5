#!./perl
#
# Tests for named prototypes
# 

my @warnings;
my $test;

BEGIN {
    chdir 't' if -d 't';
    @INC = ('../lib','.');
    $SIG{'__WARN__'} = sub { push @warnings, @_ };
    $| = 1;
}

sub is_miniperl { !defined &DynaLoader::boot_DynaLoader }

sub failed {
    my ($got, $expected, $name) = @_;
    print "not ok $test - $name\n";
    my @caller = caller(1);
    print "# Failed test at $caller[1] line $caller[2]\n";
    if (defined $got) {
	print "# Got '$got'\n";
    } else {
	print "# Got undef\n";
    }
    print "# Expected $expected\n";
    return;
}

sub like {
    my ($got, $pattern, $name) = @_;
    $test = $test + 1;
    if ($::TODO) {
        $name .= " # TODO: $::TODO";
    }
    if (defined $got && $got =~ $pattern) {
	print "ok $test - $name\n";
	# Principle of least surprise - maintain the expected interface, even
	# though we aren't using it here (yet).
	return 1;
    }
    failed($got, $pattern, $name);
}

sub is {
    my ($got, $expect, $name) = @_;
    $test = $test + 1;
    if ($::TODO) {
        $name .= " # TODO: $::TODO";
    }
    if (defined $got && $got eq $expect) {
	print "ok $test - $name\n";
	return 1;
    }
    failed($got, "'$expect'", $name);
}

sub skip {
    my ($desc) = @_;
    $test = $test + 1;
    print "ok $test # SKIP $desc\n";
}

sub no_warnings {
    my ($desc) = @_;

    if (is_miniperl) {
        skip("warnings may not be available in miniperl");
    }
    else {
        is(scalar(@warnings), 0, "No warnings with $desc");
        print "# $warnings[0]" if $#warnings >= 0;
    }
    @warnings = ();
}

BEGIN {
    print "1..23\n";
    $test = 0;
    if (!is_miniperl) {
        require Scalar::Util;
        require warnings;
        warnings->import;
    }
}

# Not yet implemented: Greedy
# Arrays (@array = ()) silences the used only once warning)
sub greedyarray(@array){return $#array; @array = ();}
BEGIN {
    local $TODO = "Named arrays not yet implemented";
    no_warnings("named arrays");
    my @array = qw(1 2 3);
    is(greedyarray(@array),2);
    is(greedyarray(1,2,3),2);
}

# Hashes (%hash = ()) silences the used only once warning)
sub greedyhash(%hash){my @keys = sort keys %hash; return "@keys"; %hash = ();}
BEGIN {
    local $TODO = "Named hashes not yet implemented";
    no_warnings("named hashes");
    my %hash = (c => 1, d => 2);
    is(greedyhash(%hash),"c d");
    is(greedyhash("c",1,"d",2),"c d");
}

# Checking params
sub onep($one){ return "$one"; }
is(onep("A"), "A", "Checking one param");

sub twop($one,$two){ return "$one $two"; }
is(twop("A","B"), "A B", "Checking two param");

sub recc($a,$c){ return recc("$a $a",$c-1) if $c; return $a; }
is(recc("A", 2), "A A A A", "Checking recursive");
no_warnings("checking params");

# Make sure whitespace doesn't matter
sub whitespace (  $a  ,  $b   ) { return $b; }
BEGIN {
    no_warnings("extra whitespace in the definition");
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
BEGIN { if (!is_miniperl) { Scalar::Util::set_prototype(\&manualproto,"*") } }
if (is_miniperl) {
    skip("Scalar::Util may not be available in miniperl");
}
else {
    eval "is(manualproto STDOUT, 'STDOUT', 'Forcing it with set_prototype works'); 1" || die $@;
}

sub manualrecproto($name){
    BEGIN { if (!is_miniperl) { Scalar::Util::set_prototype(\&manualrecproto,"*") } }
    return $name;
}
BEGIN {
    local $TODO = "Not sure how to use set_prototype for a recursive";
    no_warnings("set_prototype on recursive function");
}

sub ignoredproto(*);
sub ignoredproto($name){ return $name;}
BEGIN {
    if (is_miniperl) {
        skip("warnings may not be available in miniperl");
        skip("warnings may not be available in miniperl");
    }
    else {
        is(scalar(@warnings), 1, "Should have exactly one warning");
        like($warnings[0], "vs none", "ignoredproto should complain of a mismatch");
    }
    @warnings = ();
}

{
    my $sub = sub ($x, $y) { $x * $y };

    is($sub->(3, 4), 12, "anonymous subs work");
}

{
    sub empty ($bar, $baz) { }
    BEGIN { no_warnings("empty sub body") }

    { local $TODO = "this doesn't work yet";
    is(scalar(empty(1, 2)), undef, "empty sub returns undef in scalar context");
    }
    my $ret = [empty(1, 2)];
    is(scalar(@$ret), 0, "empty sub returns nothing in list context");
}

# Test UTF-8

BEGIN { no_warnings("end of compile time") }

1;
