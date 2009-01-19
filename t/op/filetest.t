#!./perl

# There are few filetest operators that are portable enough to test.
# See pod/perlport.pod for details.

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

use Config;
plan(tests => 28 + 27*10);

ok( -d 'op' );
ok( -f 'TEST' );
ok( !-f 'op' );
ok( !-d 'TEST' );
ok( -r 'TEST' );

# make sure TEST is r-x
eval { chmod 0555, 'TEST' or die "chmod 0555, 'TEST' failed: $!" };
chomp ($bad_chmod = $@);

$oldeuid = $>;		# root can read and write anything
eval '$> = 1';		# so switch uid (may not be implemented)

print "# oldeuid = $oldeuid, euid = $>\n";

SKIP: {
    if (!$Config{d_seteuid}) {
	skip('no seteuid');
    } 
    elsif ($Config{config_args} =~/Dmksymlinks/) {
	skip('we cannot chmod symlinks');
    }
    elsif ($bad_chmod) {
	skip( $bad_chmod );
    }
    else {
	ok( !-w 'TEST' );
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
unlink $tempfile;

# test that _ is a bareword after filetest operators

-f 'TEST';
ok( -f _ );
sub _ { "this is not a file name" }
ok( -f _ );

my $over;
{
    package OverFtest;

    use overload -X => sub { 
        $over = [overload::StrVal($_[0]), $_[1]];
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

    # Need fallback. Previous veraions of perl required 'fallback' to do
    # -X operations on an object with no "" overload.
    use overload 
        '+' => sub { 1 },
        fallback => 1;
}

my $ft = bless [], "OverFtest";
my $ftstr = overload::StrVal($ft);
my $str = bless [], "OverString";
my $both = bless [], "OverBoth";
my $neither = bless [], "OverNeither";
my $nstr = overload::StrVal($neither);

for my $op (split //, "rwxoRWXOezsfdlpSbctugkTMBAC") {
    $over = [];
    ok( my $rv = eval "-$op \$ft",  "overloaded -$op succeeds" )
        or diag( $@ );
    is( $over->[0], $ftstr,         "correct object for overloaded -$op" );
    is( $over->[1], $op,            "correct op for overloaded -$op" );
    is( $rv,        "-$op",         "correct return value for overloaded -$op");

    $over = 0;
    $rv = eval "-$op \$str";
    ok( !$@,                        "-$op succeeds with string overloading" )
        or diag( $@ );
    is( $rv, eval "-$op 'TEST'",    "correct -$op on string overload" );
    is( $over,      1,              "string overload called for -$op" );

    $rv = eval "-$op \$both";
    is( $rv,        "-$op",         "correct -$op on string/-X overload" );

    $rv = eval "-$op \$neither";
    ok( !$@,                        "-$op succeeds with random overloading" )
        or diag( $@ );
    is( $rv, eval "-$op \$nstr",    "correct -$op with random overloading" );
}

is( -r -f $ft,  "-r",               "stacked overloaded -X" );
