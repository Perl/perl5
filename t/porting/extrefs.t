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

BEGIN {
  require "./test.pl";
  unshift @INC, ".." if -f "../TestInit.pm";
}

use TestInit qw(T A); # T is chdir to the top level, A makes paths absolute
use strict;
use warnings;
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

    my $ld_exeext = ($^O eq 'cygwin' ||
                 $^O eq 'os2' && $Config{ldflags} =~ /-Zexe\b/) ? '.exe' :
                (($^O eq 'vos') ? $Config{exe_ext} : '');
    my $VERBOSE = 0;

    my ($ok) = 0;
    my $tempdir = tempfile();
    my $cwd = getcwd();
    mkdir $tempdir;
    chdir $tempdir;
    my ($tmp) = "temp";

    my $obj_ext = $Config{obj_ext} || ".o";

    if (open(my $tmpc, ">$tmp.c")) {
	print $tmpc $c;
	unless (close($tmpc)) {
	    chdir($cwd);
	    rmtree($tempdir);
	    warn "Failing closing code file: $!\n" if $VERBOSE;
	    return 0;
	}

	my $COREincdir = File::Spec->catdir(File::Spec->updir);

	my $ccflags = $Config{'ccflags'} . ' ' . "-I$COREincdir"
	 . ' -DPERL_NO_INLINE_FUNCTIONS';

	my $errornull = $VERBOSE ? '' : "2>/dev/null";

        my $cccmd = "$Config{'cc'} -o $tmp $ccflags $tmp.c $errornull";

	if ($^O eq 'VMS') {
            $cccmd = "$Config{'cc'} /include=($COREincdir) $tmp.c";
        }

       if ($^O eq 'VMS') {
	    open( my $cmdfile, ">$tmp.com" );
	    print $cmdfile "\$ SET MESSAGE/NOFACILITY/NOSEVERITY/NOIDENT/NOTEXT\n";
	    print $cmdfile "\$ $cccmd\n";
	    print $cmdfile "\$ IF \$SEVERITY .NE. 1 THEN EXIT 44\n"; # escalate
	    close $cmdfile;
	    system("\@ $tmp.com");
	    $ok = $?==0;
	    chdir($cwd);
	    rmtree($tempdir);
        }
        else
        {
	    my $tmp_exe = "$tmp$ld_exeext";
	    printf "cccmd = $cccmd\n" if $VERBOSE;
	    my $res = system($cccmd);
	    $ok = defined($res) && $res == 0 && -s $tmp_exe && -x _;

	    chdir($cwd);
	    rmtree($tempdir);
        }
    }

    return $ok;
}
