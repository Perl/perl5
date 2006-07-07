#!perl -T

BEGIN {
    if ($ENV{PERL_CORE}) {
        chdir 't';
        @INC = '../lib';
    }

    use Config;
    use Test::More;
    plan skip_all => "POSIX is unavailable" if $Config{'extensions'} !~ m!\bPOSIX\b!;
}

use strict;
use File::Spec;
use POSIX;
use Scalar::Util qw(looks_like_number);

my @path_consts = qw(
    _PC_CHOWN_RESTRICTED _PC_LINK_MAX _PC_MAX_CANON _PC_MAX_INPUT
    _PC_NAME_MAX _PC_NO_TRUNC _PC_PATH_MAX _PC_PIPE_BUF _PC_VDISABLE
);

my @sys_consts = qw(
    _SC_ARG_MAX _SC_CHILD_MAX _SC_CLK_TCK _SC_JOB_CONTROL
    _SC_NGROUPS_MAX _SC_OPEN_MAX _SC_PAGESIZE _SC_SAVED_IDS
    _SC_STREAM_MAX _SC_TZNAME_MAX _SC_VERSION
);

plan tests => 2 * 3 * @path_consts + 3 * @sys_consts;

my $r;

# testing fpathconf()
SKIP: {
    my $fd = POSIX::open(File::Spec->curdir, O_RDONLY)
        or skip "can't open current directory", 3 * @path_consts;

    for my $constant (@path_consts) {
        $r = eval { pathconf( File::Spec->curdir, eval "$constant()" ) };
        is( $@, '', "calling pathconf($constant)" );
        ok( defined $r, "\tchecking that the returned value is defined: $r" );
        ok( looks_like_number($r), "\tchecking that the returned value looks like a number" );
    }
}

# testing pathconf()
for my $constant (@path_consts) {
    $r = eval { pathconf( File::Spec->rootdir, eval "$constant()" ) };
    is( $@, '', "calling pathconf($constant)" );
    ok( defined $r, "\tchecking that the returned value is defined: $r" );
    ok( looks_like_number($r), "\tchecking that the returned value looks like a number" );
}

# testing sysconf()
for my $constant (@sys_consts) {
    $r = eval { sysconf( eval "$constant()" ) };
    is( $@, '', "calling sysconf($constant)" );
    ok( defined $r, "\tchecking that the returned value is defined: $r" );
    ok( looks_like_number($r), "\tchecking that the returned value looks like a number" );
}

