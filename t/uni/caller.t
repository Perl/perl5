#!./perl
# Tests for caller()

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}

use Config;
use utf8;
use open qw( :utf8 :std );

plan( tests => 19 );

package ｍａｉｎ;

{
    local $@;
    eval 'ok(1);';
    ::like $@, qr/Undefined subroutine &ｍａｉｎ::ok called at/u;
}
my @c;

sub { @c = caller(0) } -> ();
::is( $c[3], "ｍａｉｎ::__ANON__", "anonymous subroutine name" );
::ok( $c[4], "hasargs true with anon sub" );

# Bug 20020517.003 (#9367), used to dump core
sub ｆｏｏ { @c = caller(0) }
# The subroutine only gets anonymised if it is relying on a real GV
# for its name.
() = *{"ｆｏｏ"}; # with quotes so that the op tree doesn’t reference the GV
my $fooref = delete $ｍａｉｎ::{ｆｏｏ};
$fooref -> ();
::is( $c[3], "ｍａｉｎ::__ANON__", "deleted subroutine name" );
::ok( $c[4], "hasargs true with deleted sub" );

print "# Tests with caller(1)\n";

sub ｆ { @c = caller(1) }

sub ｃａｌｌｆ { ｆ(); }
ｃａｌｌｆ();
::is( $c[3], "ｍａｉｎ::ｃａｌｌｆ", "subroutine name" );
::ok( $c[4], "hasargs true with ｃａｌｌｆ()" );
&ｃａｌｌｆ;
::ok( !$c[4], "hasargs false with &ｃａｌｌｆ" );

eval { ｆ() };
::is( $c[3], "(eval)", "subroutine name in an eval {}" );
::ok( !$c[4], "hasargs false in an eval {}" );

eval q{ ｆ() };
::is( $c[3], "(eval)", "subroutine name in an eval ''" );
::ok( !$c[4], "hasargs false in an eval ''" );

sub { ｆ() } -> ();
::is( $c[3], "ｍａｉｎ::__ANON__", "anonymous subroutine name" );
::ok( $c[4], "hasargs true with anon sub" );

sub ｆｏｏ2 { ｆ() }
() = *{"ｆｏｏ2"}; # see ｆｏｏ notes above
my $fooref2 = delete $ｍａｉｎ::{ｆｏｏ2};
$fooref2 -> ();
::is( $c[3], "ｍａｉｎ::__ANON__", "deleted subroutine name" );
::ok( $c[4], "hasargs true with deleted sub" );

sub ｐｂ { return (caller(0))[3] }

::is( eval 'ｐｂ()', 'ｍａｉｎ::ｐｂ', "actually return the right function name" );

my $saved_perldb = $^P;
$^P = 16;
$^P = $saved_perldb;

::is( eval 'ｐｂ()', 'ｍａｉｎ::ｐｂ', 'actually return the right function name even if $^P had been on at some point' );

# Skip the OS signal/exception from this faux-SEGV
# code is from cpan/Test-Harness/t/harness.t
SKIP: {
    ::skip "No SIGSEGV on $^O", 1
        if $^O ne 'MSWin32' && $Config::Config{'sig_name'} !~ m/SEGV/;
    #line below not in cpan/Test-Harness/t/harness.t
    ::skip "No SIGTRAP on $^O", 1
        if $^O ne 'MSWin32' && $Config::Config{'sig_name'} !~ m/TRAP/;

    # some people -Dcc="somecc -fsanitize=..." or -Doptimize="-fsanitize=..."
    ::skip "ASAN doesn't passthrough SEGV", 1
      if "$Config{cc} $Config{ccflags} $Config{optimize}" =~ /-fsanitize\b/;

    my $out_str = ::fresh_perl('BEGIN { chdir \'t\' if -d \'t\';'
    .'require \'./test.pl\';set_up_inc(\'../lib\',\'../../lib\');}'
    .'use XS::APItest;XS::APItest::test_C_BP_breakpoint();');

    # On machines where 'ulimit -c' does not return '0', a perl.core
    # file is created here.  We don't need to examine it, and it's
    # annoying to have it subsequently show up as an untracked file in
    # `git status`, so simply get rid of it per suggestion by Karen
    # Etheridge.
    END { unlink 'perl.core' }


    ::like($out_str, qr/panic: C breakpoint hit file/,
           'C_BP macro and C breakpoint works');
}
