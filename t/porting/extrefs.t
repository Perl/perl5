#!./perl -w

# What does this test?
# Test that changes to perl header files don't cause external
# references by simplying #including them.  This breaks library probe
# code on CPAN, and can break cflags.SH.
#
# Why do we test this?
# See https://rt.perl.org/rt3/Ticket/Display.html?id=116989
#
# It's broken - how do I fix it?
# You added an initializer or static function to a header file that
# references some symbol you didn't define, you need to remove it.

use strict;
use warnings;

BEGIN {
  require "./test.pl";
  unshift @INC, ".." if -f "../TestInit.pm";
}

use TestInit qw(T A); # T is chdir to the top level, A makes paths absolute
use Config;
use File::Path 'rmtree';
use Cwd;

skip_all("we don't test this on Win32") if $^O eq "MSWin32";

plan(tests => 1);

ok(try_compile_and_link(<<'CODE'));
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

int main(int argc, char **argv) {
  return 0;
}
CODE


# from Time::HiRes's Makefile.PL with minor modifications
sub try_compile_and_link {
    my ($c, %args) = @_;

    my $LIBS = [];
    my $ld_exeext = ($^O eq 'cygwin' ||
                 $^O eq 'os2' && $Config{ldflags} =~ /-Zexe\b/) ? '.exe' :
                (($^O eq 'vos') ? $Config{exe_ext} : '');
    my $VERBOSE = 1;

    my ($ok) = 0;
    my $tempdir = tempfile();
    my $cwd = getcwd();
    mkdir $tempdir;
    chdir $tempdir;
    my ($tmp) = "temp";
    local(*TMPC);

    my $obj_ext = $Config{obj_ext} || ".o";
    unlink("$tmp.c", "$tmp$obj_ext");

    if (open(TMPC, ">$tmp.c")) {
	print TMPC $c;
	close(TMPC);

	my $cccmd = $args{cccmd};

	my $errornull;

	my $COREincdir;

	if ($ENV{PERL_CORE}) {
	    my $updir = File::Spec->updir;
	    $COREincdir = File::Spec->catdir($updir);
	} else {
	    $COREincdir = File::Spec->catdir($Config{'archlibexp'}, 'CORE');
	}

	if ($ENV{PERL_CORE}) {
	    unless (-f File::Spec->catfile($COREincdir, "EXTERN.h")) {
	        chdir($cwd);
	        rmtree($tempdir);
		die <<__EOD__;
Your environment variable PERL_CORE is '$ENV{PERL_CORE}' but there
is no EXTERN.h in $COREincdir.
Cannot continue, aborting.
__EOD__
            }
        }

	my $ccflags = $Config{'ccflags'} . ' ' . "-I$COREincdir"
	 . ' -DPERL_NO_INLINE_FUNCTIONS';

	if ($^O eq 'VMS') {
            $cccmd = "$Config{'cc'} /include=($COREincdir) $tmp.c";
        }

        if ($args{silent} || !$VERBOSE) {
	    $errornull = "2>/dev/null" unless defined $errornull;
	} else {
	    $errornull = '';
	}

        $cccmd = "$Config{'cc'} -o $tmp $ccflags $tmp.c @$LIBS $errornull"
	    unless defined $cccmd;

       if ($^O eq 'VMS') {
	    open( CMDFILE, ">$tmp.com" );
	    print CMDFILE "\$ SET MESSAGE/NOFACILITY/NOSEVERITY/NOIDENT/NOTEXT\n";
	    print CMDFILE "\$ $cccmd\n";
	    print CMDFILE "\$ IF \$SEVERITY .NE. 1 THEN EXIT 44\n"; # escalate
	    close CMDFILE;
	    system("\@ $tmp.com");
	    $ok = $?==0;
	    chdir($cwd);
	    rmtree($tempdir);
	    #for ("$tmp.c", "$tmp$obj_ext", "$tmp.com", "$tmp$Config{exe_ext}") {
		#1 while unlink $_;
	    #}
        }
        else
        {
	    my $tmp_exe = "$tmp$ld_exeext";
	    printf "cccmd = $cccmd\n" if $VERBOSE;
	    my $res = system($cccmd);
	    $ok = defined($res) && $res == 0 && -s $tmp_exe && -x _;

	    if ( $ok && exists $args{run} && $args{run}) {
		my $tmp_exe =
		    File::Spec->catfile(File::Spec->curdir, $tmp_exe);
		printf "Running $tmp_exe..." if $VERBOSE;
		if (system($tmp_exe) == 0) {
		    $ok = 1;
		} else {
		    $ok = 0;
		    my $errno = $? >> 8;
		    local $! = $errno;
		    printf <<EOF;

*** The test run of '$tmp_exe' failed: status $?
*** (the status means: errno = $errno or '$!')
*** DO NOT PANIC: this just means that *some* functionality will be missing.
EOF
		}
	    }
	    chdir($cwd);
	    rmtree($tempdir);
	    #unlink("$tmp.c", $tmp_exe);
        }
    }

    return $ok;
}
