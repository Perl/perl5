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

sub ok {
    my ($got, $name) = @_;
    $test = $test + 1;
    if ($::TODO) {
        $name .= " # TODO: $::TODO";
    }
    if ($got) {
	print "ok $test - $name\n";
	return 1;
    }
    failed($got, "a true value", $name);
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
    $test = 0;
    if (!is_miniperl) {
        require Scalar::Util;
        require warnings;
        warnings->import;
    }
}

use feature 'experimental::sub_signature';

{
    no feature 'experimental::sub_signature';
    eval 'sub a($foo){} a(5);';
    like($@, "Not enough arguments", "no feature should force old style processing $@");
    like($warnings[0], "Illegal character", "The warning should be on as well");
    @warnings = ();
    eval 'sub b($ foo $){}';
    like($warnings[0], "\\\$foo\\\$", "It should still be removing spaces");
    @warnings = ();
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

{
    sub arg_length ($foo, $bar) {
        return ($foo // 'undef') . ($bar // 'undef');
    }

    is(arg_length, 'undefundef', "no args passed");
    is(arg_length('FOO2'), 'FOO2undef', "one arg passed");
    is(arg_length('FOO3', 'BAR3'), 'FOO3BAR3', "two args passed");
    is(arg_length('FOO4', 'BAR4', 'BAZ4'), 'FOO4BAR4', "three args passed");

    my @foo;
    is(arg_length(@foo), 'undefundef', "no args passed");
    @foo = ('2FOO');
    is(arg_length(@foo), '2FOOundef', "one arg passed");
    @foo = ('3FOO', '3BAR');
    is(arg_length(@foo), '3FOO3BAR', "two args passed");
    @foo = ('4FOO', '4BAR', '4BAZ');
    is(arg_length(@foo), '4FOO4BAR', "three args passed");
}

{
    my $x = 10;

    sub closure1 ($y) {
        return $x * $y;
    }

    is(closure1(3), 30, "closures work");
}

{
    my $x = 10;

    sub shadowing1 ($x) {
        return $x + 5;
    }
    BEGIN { no_warnings("variable shadowing") } # XXX or do we want one?

    is(shadowing1(3), 8, "variable shadowing works");
}

{
    sub shadowing2 ($x) {
        my $x = 10;
        return $x + 5;
    }
    BEGIN { no_warnings("variable shadowing") } # XXX or do we want one?

    is(shadowing2(3), 15, "variable shadowing works");
}

{ local $TODO = "slurpy parameters not supported yet";
{
    my $failed = !eval 'sub bad_slurpy_array (@foo, $bar) { }; 1';
    my $err = $@;
    ok($failed, "slurpies must come last");
    like($err, qr/slurpy/, "slurpies must come last"); # XXX better regex
}

{
    my $failed = !eval 'sub bad_slurpy_hash (%foo, $bar) { }; 1';
    my $err = $@;
    ok($failed, "slurpies must come last");
    like($err, qr/slurpy/, "slurpies must come last"); # XXX better regex
}
no_warnings("invalid slurpy parameters");
}

# Ban @_ inside the sub if it has a named proto
{
    my ($legal, $failed);
    my $err = "Cannot use \@_ in a sub with a signature\n";
    $legal = eval 'sub not_banned1 { $#_ }; 1';
    ok($legal, "No changes to \$#_ within traditional subs");
    $legal = eval 'sub not_banned2 { @_; }; 1';
    ok($legal, "No changes to \@_ within traditional subs");
    $failed = !eval 'sub banned1 ($foo){ $#_ }; 1';
    ok($failed, "Cannot use a literal \$#_ with subroutine signatures");
    is($@,$err, "Died for the right reason");
    $failed = !eval 'sub banned2 ($foo){ @_ }; 1';
    ok($failed, "Cannot use a literal \@_ with subroutine signatures");
    is($@,$err, "Died for the right reason");
    $legal = eval 'sub banned3 ($foo){ sub not_banned3 { $#_ }; }; 1';
    ok($legal, "\$#_ restriction doesn't apply to nested subs");
    $legal = eval 'sub banned4 ($foo){ sub not_banned4 { @_ }; }; 1';
    ok($legal, "\@_ restriction doesn't apply to nested subs");

    # Test aliases too
    *globb = *main::_;
    $legal = eval 'sub banned5 ($foo) { $#globb;}; 1';
    ok($legal, "Using an alias compiles fine - count");
    no_warnings("using a global alias - count");
    $legal = eval 'sub banned6 ($foo) { my ($a) = @globb; }; 1';
    ok($legal, "Using an alias compiles fine - assignment");
    no_warnings("using a global alias - assignment");
    $legal = eval 'sub banned7 ($foo) { $globb[0]; }; 1';
    ok($legal, "Using an alias compiles fine - direct access");
    no_warnings("using a global alias - direct access");
    $failed = !eval 'banned5(); 1';
    ok($failed, "An alias to \$#_ dies in execution - () syntax");
    is($@,$err, "Died for the right reason");
    $failed = !eval '&banned5; 1';
    ok($failed, "An alias to \$#_ dies in execution - & syntax");
    is($@,$err, "Died for the right reason");
    @normal = qw(1 2 3);
    *globb = *normal;
    $legal = eval 'banned5(); 1';
    ok($legal, "globb is fine again - ()");
    $legal = eval '&banned5; 1';
    ok($legal, "globb is fine again - &");
}

# Test UTF-8

BEGIN { no_warnings("end of compile time") }
no_warnings("end of runtime");

END { print "1..$test\n" }
