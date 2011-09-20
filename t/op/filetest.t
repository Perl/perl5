#!./perl

# There are few filetest operators that are portable enough to test.
# See pod/perlport.pod for details.

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

use Config;
plan(tests => 34 + 27*14);

ok( -d 'op' );
ok( -f 'TEST' );
ok( !-f 'op' );
ok( !-d 'TEST' );
ok( -r 'TEST' );

# Make a read only file
my $ro_file = tempfile();

{
    open my $fh, '>', $ro_file or die "open $fh: $!";
    close $fh or die "close $fh: $!";
}

chmod 0555, $ro_file or die "chmod 0555, '$ro_file' failed: $!";

$oldeuid = $>;		# root can read and write anything
eval '$> = 1';		# so switch uid (may not be implemented)

print "# oldeuid = $oldeuid, euid = $>\n";

SKIP: {
    if (!$Config{d_seteuid}) {
	skip('no seteuid');
    } 
    else {
	ok( !-w $ro_file );
    }
}

# Scripts are not -x everywhere so cannot test that.

eval '$> = $oldeuid';	# switch uid back (may not be implemented)

# this would fail for the euid 1
# (unless we have unpacked the source code as uid 1...)
ok( -r 'op' );

# this would fail for the euid 1
# (unless we have unpacked the source code as uid 1...)
SKIP: {
    if ($Config{d_seteuid}) {
	ok( -w 'op' );
    } else {
	skip('no seteuid');
    }
}

ok( -x 'op' ); # Hohum.  Are directories -x everywhere?

is( "@{[grep -r, qw(foo io noo op zoo)]}", "io op" );

# Test stackability of filetest operators

ok( defined( -f -d 'TEST' ) && ! -f -d _ );
ok( !defined( -e 'zoo' ) );
ok( !defined( -e -d 'zoo' ) );
ok( !defined( -f -e 'zoo' ) );
ok( -f -e 'TEST' );
ok( -e -f 'TEST' );
ok( defined(-d -e 'TEST') );
ok( defined(-e -d 'TEST') );
ok( ! -f -d 'op' );
ok( -x -d -x 'op' );
ok( (-s -f 'TEST' > 1), "-s returns real size" );
ok( -f -s 'TEST' == 1 );

# now with an empty file
my $tempfile = tempfile();
open my $fh, ">", $tempfile;
close $fh;
ok( -f $tempfile );
is( -s $tempfile, 0 );
is( -f -s $tempfile, 0 );
is( -s -f $tempfile, 0 );
unlink_all $tempfile;

# stacked -l
eval { -l -e "TEST" };
like $@, qr/^The stat preceding -l _ wasn't an lstat at /,
  'stacked -l non-lstat error with warnings off';
{
 local $^W = 1;
 eval { -l -e "TEST" };
 like $@, qr/^The stat preceding -l _ wasn't an lstat at /,
  'stacked -l non-lstat error with warnings on';
}
# Make sure -l is using the previous stat buffer, and not using the previ-
# ous op’s return value as a file name.
SKIP: {
 use Perl::OSType 'os_type';
 if (os_type ne 'Unix') { skip "Not Unix", 2 }
 if (-l "TEST") { skip "TEST is a symlink", 2 }
 chomp(my $ln = `which ln`);
 if ( ! -e $ln ) { skip "No ln"   , 2 }
 lstat "TEST";
 `ln -s TEST 1`;
 ok ! -l -e _, 'stacked -l uses previous stat, not previous retval';
 unlink 1;

 # Since we already have our skip block set up, we might as well put this
 # test here, too:
 # -l always treats a non-bareword argument as a file name
 system qw "ln -s TEST", \*foo;
 local $^W = 1;
 ok -l \*foo, '-l \*foo is a file name';
 unlink \*foo;
}

# test that _ is a bareword after filetest operators

-f 'TEST';
ok( -f _ );
sub _ { "this is not a file name" }
ok( -f _ );

my $over;
{
    package OverFtest;

    use overload 
	fallback => 1,
        -X => sub { 
            $over = [qq($_[0]), $_[1]];
            "-$_[1]"; 
        };
}
{
    package OverString;

    # No fallback. -X should fall back to string overload even without
    # it.
    use overload q/""/ => sub { $over = 1; "TEST" };
}
{
    package OverBoth;

    use overload
        q/""/   => sub { "TEST" },
        -X      => sub { "-$_[1]" };
}
{
    package OverNeither;

    # Need fallback. Previous versions of perl required 'fallback' to do
    # -X operations on an object with no "" overload.
    use overload 
        '+' => sub { 1 },
        fallback => 1;
}

my $ft = bless [], "OverFtest";
my $ftstr = qq($ft);
my $str = bless [], "OverString";
my $both = bless [], "OverBoth";
my $neither = bless [], "OverNeither";
my $nstr = qq($neither);

open my $gv, "<", "TEST";
bless $gv, "OverString";
open my $io, "<", "TEST";
$io = *{$io}{IO};
bless $io, "OverString";

my $fcntl_not_available;
eval { require Fcntl } or $fcntl_not_available = 1;

for my $op (split //, "rwxoRWXOezsfdlpSbctugkTMBAC") {
    $over = [];
    ok( my $rv = eval "-$op \$ft",  "overloaded -$op succeeds" )
        or diag( $@ );
    is( $over->[0], $ftstr,         "correct object for overloaded -$op" );
    is( $over->[1], $op,            "correct op for overloaded -$op" );
    is( $rv,        "-$op",         "correct return value for overloaded -$op");

    my ($exp, $is) = (1, "is");
    if (
	!$fcntl_not_available and (
        $op eq "u" and not eval { Fcntl::S_ISUID() } or
        $op eq "g" and not eval { Fcntl::S_ISGID() } or
        $op eq "k" and not eval { Fcntl::S_ISVTX() }
	)
    ) {
        ($exp, $is) = (0, "not");
    }

    $over = 0;
    $rv = eval "-$op \$str";
    ok( !$@,                        "-$op succeeds with string overloading" )
        or diag( $@ );
    is( $rv, eval "-$op 'TEST'",    "correct -$op on string overload" );
    is( $over,      $exp,           "string overload $is called for -$op" );

    ($exp, $is) = $op eq "l" ? (1, "is") : (0, "not");

    $over = 0;
    eval "-$op \$gv";
    is( $over,      $exp,   "string overload $is called for -$op on GLOB" );

    # IO refs always get string overload called. This might be a bug.
    $op eq "t" || $op eq "T" || $op eq "B"
        and ($exp, $is) = (1, "is");

    $over = 0;
    eval "-$op \$io";
    is( $over,      $exp,   "string overload $is called for -$op on IO");

    $rv = eval "-$op \$both";
    is( $rv,        "-$op",         "correct -$op on string/-X overload" );

    $rv = eval "-$op \$neither";
    ok( !$@,                        "-$op succeeds with random overloading" )
        or diag( $@ );
    is( $rv, eval "-$op \$nstr",    "correct -$op with random overloading" );

    is( eval "-r -$op \$ft", "-r",      "stacked overloaded -$op" );
    is( eval "-$op -r \$ft", "-$op",    "overloaded stacked -$op" );
}

# -l stack corruption: this bug occurred from 5.8 to 5.14
{
 push my @foo, "bar", -l baz;
 is $foo[0], "bar", '-l bareword does not corrupt the stack';
}

# File test ops should not call get-magic on the topmost SV on the stack if
# it belongs to another op.
{
  my $w;
  sub oon::TIESCALAR{bless[],'oon'}
  sub oon::FETCH{$w++}
  tie my $t, 'oon';
  push my @a, $t, -t;
  is $w, 1, 'file test does not call FETCH on stack item not its own';
}
