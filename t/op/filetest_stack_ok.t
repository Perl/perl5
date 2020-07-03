#!./perl

# On platforms that don't support all of the filetest operators the code
# that faked the results of missing tests used to leave the test's
# argument on the stack.

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}

my @ops = split //, 'rwxoRWXOezsfdlpSbctugkTMBAC';

plan( tests => @ops * 6 + 1 );

package o { use overload '-X' => sub { 1 } }
my $o = bless [], 'o';

for my $op (@ops) {
    no warnings 'unopened';
    my @these_warnings = ();
    local $SIG{__WARN__} = sub { push @these_warnings, $_[0]; };
    ok( 1 == @{ [ eval "-$op 'TEST'" ] }, "-$op returns single value" );
    ok( 1 == @{ [ eval "-$op *TEST" ] }, "-$op *gv returns single value" );
    use warnings 'unopened';
    # -l generates a warning of category 'io'
    is(@these_warnings, ($op eq 'l') ? 1 : 0,
        "-$op got expected number of warnings: " . scalar(@these_warnings));
    @these_warnings = ();

    my $count = 0;
    my $t;
    for my $m ("a", "b") {
	if ($count == 0) {
        no warnings 'unopened';
	    $t = eval "-$op _" ? 0 : "foo";
	}
	elsif ($count == 1) {
	    is($m, "b", "-$op did not remove too many values from the stack");
	}
	$count++;
    }

    $count = 0;
    for my $m ("c", "d") {
	if ($count == 0) {
	    $t = eval "-$op -e \$^X" ? 0 : "bar";
	}
	elsif ($count == 1) {
	    is($m, "d", "-$op -e \$^X did not remove too many values from the stack");
	}
	$count++;
    }

    my @foo = eval "-$op \$o";
    is @foo, 1, "-$op \$overld did not leave \$overld on the stack";
}

{
    # [perl #129347] cope with stacked filetests where PL_op->op_next is null
    no warnings 'once';
    no warnings 'uninitialized';
    () = sort { -d -d } \*TEST0, \*TEST1;
    ok 1, "survived stacked filetests with null op_next";
}
