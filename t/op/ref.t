#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = qw(. ../lib);
}

require 'test.pl';

plan (72);

# Test glob operations.

$bar = "ok 1\n";
$foo = "ok 2\n";
{
    local(*foo) = *bar;
    print $foo;
}
print $foo;

$baz = "ok 3\n";
$foo = "ok 4\n";
{
    local(*foo) = 'baz';
    print $foo;
}
print $foo;

$foo = "ok 6\n";
{
    local(*foo);
    print $foo;
    $foo = "ok 5\n";
    print $foo;
}
print $foo;

# Test fake references.

$baz = "ok 7\n";
$bar = 'baz';
$foo = 'bar';
print $$$foo;

# Test real references.

$FOO = \$BAR;
$BAR = \$BAZ;
$BAZ = "ok 8\n";
print $$$FOO;

# Test references to real arrays.

@ary = (9,10,11,12);
$ref[0] = \@a;
$ref[1] = \@b;
$ref[2] = \@c;
$ref[3] = \@d;
for $i (3,1,2,0) {
    push(@{$ref[$i]}, "ok $ary[$i]\n");
}
print @a;
print ${$ref[1]}[0];
print @{$ref[2]}[0];
print @{'d'};

# Test references to references.

$refref = \\$x;
$x = "ok 13\n";
print $$$refref;

# Test nested anonymous lists.

$ref = [[],2,[3,4,5,]];
print scalar @$ref == 3 ? "ok 14\n" : "not ok 14\n";
print $$ref[1] == 2 ? "ok 15\n" : "not ok 15\n";
print ${$$ref[2]}[2] == 5 ? "ok 16\n" : "not ok 16\n";
print scalar @{$$ref[0]} == 0 ? "ok 17\n" : "not ok 17\n";

print $ref->[1] == 2 ? "ok 18\n" : "not ok 18\n";
print $ref->[2]->[0] == 3 ? "ok 19\n" : "not ok 19\n";

# Test references to hashes of references.

$refref = \%whatever;
$refref->{"key"} = $ref;
print $refref->{"key"}->[2]->[0] == 3 ? "ok 20\n" : "not ok 20\n";

# Test to see if anonymous subarrays spring into existence.

$spring[5]->[0] = 123;
$spring[5]->[1] = 456;
push(@{$spring[5]}, 789);
print join(':',@{$spring[5]}) eq "123:456:789" ? "ok 21\n" : "not ok 21\n";

# Test to see if anonymous subhashes spring into existence.

@{$spring2{"foo"}} = (1,2,3);
$spring2{"foo"}->[3] = 4;
print join(':',@{$spring2{"foo"}}) eq "1:2:3:4" ? "ok 22\n" : "not ok 22\n";

# Test references to subroutines.

sub mysub { print "ok 23\n" }
$subref = \&mysub;
&$subref;

$subrefref = \\&mysub2;
$$subrefref->("ok 24\n");
sub mysub2 { print shift }

# Test the ref operator.

print ref $subref	eq CODE  ? "ok 25\n" : "not ok 25\n";
print ref $ref		eq ARRAY ? "ok 26\n" : "not ok 26\n";
print ref $refref	eq HASH  ? "ok 27\n" : "not ok 27\n";

# Test anonymous hash syntax.

$anonhash = {};
print ref $anonhash	eq HASH  ? "ok 28\n" : "not ok 28\n";
$anonhash2 = {FOO => BAR, ABC => XYZ,};
print join('', sort values %$anonhash2) eq BARXYZ ? "ok 29\n" : "not ok 29\n";

# Test bless operator.

package MYHASH;

$object = bless $main'anonhash2;
print ref $object	eq MYHASH  ? "ok 30\n" : "not ok 30\n";
print $object->{ABC}	eq XYZ     ? "ok 31\n" : "not ok 31\n";

$object2 = bless {};
print ref $object2	eq MYHASH  ? "ok 32\n" : "not ok 32\n";

# Test ordinary call on object method.

&mymethod($object,33);

sub mymethod {
    local($THIS, @ARGS) = @_;
    die 'Got a "' . ref($THIS). '" instead of a MYHASH'
	unless ref $THIS eq MYHASH;
    print $THIS->{FOO} eq BAR  ? "ok $ARGS[0]\n" : "not ok $ARGS[0]\n";
}

# Test automatic destructor call.

$string = "not ok 34\n";
$object = "foo";
$string = "ok 34\n";
$main'anonhash2 = "foo";
$string = "";

DESTROY {
    return unless $string;
    print $string;

    # Test that the object has not already been "cursed".
    print ref shift ne HASH ? "ok 35\n" : "not ok 35\n";
}

# Now test inheritance of methods.

package OBJ;

@ISA = (BASEOBJ);

$main'object = bless {FOO => foo, BAR => bar};

package main;
curr_test(36);

# Test arrow-style method invocation.

is ($object->doit("BAR"), bar);

# Test indirect-object-style method invocation.

$foo = doit $object "FOO";
main::is ($foo, foo);

sub BASEOBJ'doit {
    local $ref = shift;
    die "Not an OBJ" unless ref $ref eq OBJ;
    $ref->{shift()};
}

package UNIVERSAL;
@ISA = 'LASTCHANCE';

package LASTCHANCE;
sub foo { main::is ($_[1], 'works') }

package WHATEVER;
foo WHATEVER "works";

#
# test the \(@foo) construct
#
package main;
@foo = \(1..3);
@bar = \(@foo);
@baz = \(1,@foo,@bar);
is (scalar (@bar), 3);
is (scalar grep(ref($_), @bar), 3);
is (scalar (@baz), 3);

my(@fuu) = \(1..2,3);
my(@baa) = \(@fuu);
my(@bzz) = \(1,@fuu,@baa);
is (scalar (@baa), 3);
is (scalar grep(ref($_), @baa), 3);
is (scalar (@bzz), 3);

# also, it can't be an lvalue
eval '\\($x, $y) = (1, 2);';
like ($@, qr/Can\'t modify.*ref.*in.*assignment/);

# test for proper destruction of lexical objects
my $test = curr_test();
sub larry::DESTROY { print "# larry\nok $test\n"; }
sub curly::DESTROY { print "# curly\nok ", $test + 1, "\n"; }
sub moe::DESTROY   { print "# moe\nok ", $test + 2, "\n"; }

{
    my ($joe, @curly, %larry);
    my $moe = bless \$joe, 'moe';
    my $curly = bless \@curly, 'curly';
    my $larry = bless \%larry, 'larry';
    print "# leaving block\n";
}

print "# left block\n";
curr_test($test + 3);

# another glob test


$foo = "garbage";
{ local(*bar) = "foo" }
$bar = "glob 3";
local(*bar) = *bar;
is ($bar, "glob 3");

$var = "glob 4";
$_   = \$var;
is ($$_, 'glob 4');


# test if reblessing during destruction results in more destruction
$test = curr_test();
{
    package A;
    sub new { bless {}, shift }
    DESTROY { print "# destroying 'A'\nok ", $test + 1, "\n" }
    package _B;
    sub new { bless {}, shift }
    DESTROY { print "# destroying '_B'\nok $test\n"; bless shift, 'A' }
    package main;
    my $b = _B->new;
}
curr_test($test + 2);

# test if $_[0] is properly protected in DESTROY()

{
    my $test = curr_test();
    my $i = 0;
    local $SIG{'__DIE__'} = sub {
	my $m = shift;
	if ($i++ > 4) {
	    print "# infinite recursion, bailing\nnot ok $test\n";
	    exit 1;
        }
	like ($m, qr/^Modification of a read-only/);
    };
    package C;
    sub new { bless {}, shift }
    DESTROY { $_[0] = 'foo' }
    {
	print "# should generate an error...\n";
	my $c = C->new;
    }
    print "# good, didn't recurse\n";
}

# test if refgen behaves with autoviv magic
{
    my @a;
    $a[1] = "good";
    my $got;
    for (@a) {
	$got .= ${\$_};
	$got .= ';';
    }
    is ($got, ";good;");
}

# This test is the reason for postponed destruction in sv_unref
$a = [1,2,3];
$a = $a->[1];
is ($a, 2);

# This test used to coredump. The BEGIN block is important as it causes the
# op that created the constant reference to be freed. Hence the only
# reference to the constant string "pass" is in $a. The hack that made
# sure $a = $a->[1] would work didn't work with references to constants.


foreach my $lexical ('', 'my $a; ') {
  my $expect = "pass\n";
  my $result = runperl (switches => ['-wl'], stderr => 1,
    prog => $lexical . 'BEGIN {$a = \q{pass}}; $a = $$a; print $a');

  is ($?, 0);
  is ($result, $expect);
}

my $test = curr_test();
sub x::DESTROY {print "ok ", $test + shift->[0], "\n"}
{ my $a1 = bless [3],"x";
  my $a2 = bless [2],"x";
  { my $a3 = bless [1],"x";
    my $a4 = bless [0],"x";
    567;
  }
}
curr_test($test+4);

is (runperl (switches=>['-l'],
	     prog=> 'print 1; print qq-*$\*-;print 1;'),
    "1\n*\n*\n1\n");

# bug #21347

runperl(prog => 'sub UNIVERSAL::AUTOLOAD { qr// } a->p' );
is ($?, 0, 'UNIVERSAL::AUTOLOAD called when freeing qr//');

runperl(prog => 'sub UNIVERSAL::DESTROY { warn } bless \$a, A', stderr => 1);
is ($?, 0, 'warn called inside UNIVERSAL::DESTROY');


# bug #22719

runperl(prog => 'sub f { my $x = shift; *z = $x; } f({}); f();');
is ($?, 0, 'coredump on typeglob = (SvRV && !SvROK)');

# bug #27268: freeing self-referential typeglobs could trigger
# "Attempt to free unreferenced scalar" warnings

is (runperl(
    prog => 'use Symbol;my $x=bless \gensym,"t"; print;*$$x=$x',
    stderr => 1
), '', 'freeing self-referential typeglob');

# using a regex in the destructor for STDOUT segfaulted because the
# REGEX pad had already been freed (ithreads build only). The
# object is required to trigger the early freeing of GV refs to to STDOUT

like (runperl(
    prog => '$x=bless[]; sub IO::Handle::DESTROY{$_="bad";s/bad/ok/;print}',
    stderr => 1
      ), qr/^(ok)+$/, 'STDOUT destructor');

# Bit of a hack to make test.pl happy. There are 3 more tests after it leaves.
$test = curr_test();
curr_test($test + 3);
# test global destruction

my $test1 = $test + 1;
my $test2 = $test + 2;

package FINALE;

{
    $ref3 = bless ["ok $test2\n"];	# package destruction
    my $ref2 = bless ["ok $test1\n"];	# lexical destruction
    local $ref1 = bless ["ok $test\n"];	# dynamic destruction
    1;					# flush any temp values on stack
}

DESTROY {
    print $_[0][0];
}

