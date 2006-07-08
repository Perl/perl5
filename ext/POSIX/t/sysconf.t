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

sub check(@) {
    grep { eval "&$_;1" or $@!~/vendor has not defined POSIX macro/ } @_
}       

my @path_consts = check qw(
    _PC_CHOWN_RESTRICTED _PC_LINK_MAX _PC_NAME_MAX
    _PC_NO_TRUNC _PC_PATH_MAX
);

my @path_consts_terminal = check qw(
    _PC_MAX_CANON _PC_MAX_INPUT _PC_VDISABLE
);

my @path_consts_fifo = check qw(
    _PC_PIPE_BUF
);

my @sys_consts = check qw(
    _SC_ARG_MAX _SC_CHILD_MAX _SC_CLK_TCK _SC_JOB_CONTROL
    _SC_NGROUPS_MAX _SC_OPEN_MAX _SC_PAGESIZE _SC_SAVED_IDS
    _SC_STREAM_MAX _SC_TZNAME_MAX _SC_VERSION
);
my $tests=2 * 3 * @path_consts +
                  3 * @path_consts_terminal +
              2 * 3 * @path_consts_fifo +
                  3 * @sys_consts;
plan $tests 
     ? (tests => $tests) 
     : (skip_all => "No tests to run on this OS")
;

my $curdir = File::Spec->curdir;

my $r;

# testing fpathconf() on a non-terminal file
SKIP: {
    my $fd = POSIX::open($curdir, O_RDONLY)
        or skip "could not open current directory ($!)", 3 * @path_consts;

    for my $constant (@path_consts) {
        $r = eval { fpathconf( $fd, eval "$constant()" ) };
        is( $@, '', "calling fpathconf($fd, $constant) " );
        ok( defined $r, "\tchecking that the returned value is defined: $r" );
        ok( looks_like_number($r), "\tchecking that the returned value looks like a number" );
    }
    
    POSIX::close($fd);
}

# testing pathconf() on a non-terminal file
for my $constant (@path_consts) {
    $r = eval { pathconf( $curdir, eval "$constant()" ) };
    is( $@, '', qq[calling pathconf("$curdir", $constant)] );
    ok( defined $r, "\tchecking that the returned value is defined: $r" );
    ok( looks_like_number($r), "\tchecking that the returned value looks like a number" );
}

SKIP: {
    -c "/dev/tty"
	or skip("/dev/tty not a character file", 3 * @path_consts_terminal);

    # testing pathconf() on a terminal file
    for my $constant (@path_consts_terminal) {
	$r = eval { pathconf( "/dev/tty", eval "$constant()" ) };
	is( $@, '', qq[calling pathconf("/dev/tty", $constant)] );
	ok( defined $r, "\tchecking that the returned value is defined: $r" );
	ok( looks_like_number($r), "\tchecking that the returned value looks like a number" );
    }
}

my $fifo = "fifo$$";

SKIP: {
    eval { mkfifo($fifo, 0666) }
	or skip("could not create fifo $fifo ($!)", 2 * 3 * @path_consts_fifo);

  SKIP: {
      my $fd = POSIX::open($fifo, O_RDWR)
	  or skip("could not open $fifo ($!)", 3 * @path_consts_fifo);

      for my $constant (@path_consts_fifo) {
	  $r = eval { fpathconf( $fd, eval "$constant()" ) };
	  is( $@, '', "calling fpathconf($fd, $constant) " );
	  ok( defined $r, "\tchecking that the returned value is defined: $r" );
	  ok( looks_like_number($r), "\tchecking that the returned value looks like a number" );
      }
    
      POSIX::close($fd);
  }

  SKIP: {
      # testing pathconf() on a fifo file
      for my $constant (@path_consts_fifo) {
	  $r = eval { pathconf( $fifo, eval "$constant()" ) };
	  is( $@, '', qq[calling pathconf($fifo, $constant)] );
	  ok( defined $r, "\tchecking that the returned value is defined: $r" );
	  ok( looks_like_number($r), "\tchecking that the returned value looks like a number" );
      }
  }
}

unlink($fifo);

# testing sysconf()
for my $constant (@sys_consts) {
    $r = eval { sysconf( eval "$constant()" ) };
    is( $@, '', "calling sysconf($constant)" );
    ok( defined $r, "\tchecking that the returned value is defined: $r" );
    ok( looks_like_number($r), "\tchecking that the returned value looks like a number" );
}

