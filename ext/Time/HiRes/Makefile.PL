
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
#

require 5.002;

use Config;
use ExtUtils::MakeMaker;
use strict;

my $VERBOSE = $ENV{VERBOSE};
my $DEFINE;
my $LIBS;
my $XSOPT;

unless($ENV{PERL_CORE}) { # This trick from Encode/Makefile.PL.
    $ENV{PERL_CORE} = 1 if ($^X =~ m{\bminiperl[^/\\\]>:]*$}o);
}

# Perls 5.002 and 5.003 did not have File::Spec, fake what we need.

sub my_dirsep {
    $^O eq 'VMS' ? '.' :
	$^O =~ /mswin32|netware|djgpp/i ? '\\' :
	    $^O eq 'MacOS' ? ':'
		: '/';
}

sub my_catdir {
    shift;
    my $catdir = join(my_dirsep, @_);
    $^O eq 'VMS' ? "[$catdir]" : $catdir;
}

sub my_updir {
    shift;
    $^O eq 'VMS' ? "-" : "..";
}

BEGIN {
    eval { require File::Spec };
    if ($@) {
	*File::Spec::catdir = \&my_catdir;
	*File::Spec::updir  = \&my_updir;
    }
}

# Avoid 'used only once' warnings.
my $nop1 = *File::Spec::catdir;
my $nop2 = *File::Spec::updir;

# if you have 5.004_03 (and some slightly older versions?), xsubpp
# tries to generate line numbers in the C code generated from the .xs.
# unfortunately, it is a little buggy around #ifdef'd code.
# my choice is leave it in and have people with old perls complain 
# about the "Usage" bug, or leave it out and be unable to compile myself
# without changing it, and then I'd always forget to change it before a 
# release. Sorry, Edward :)

sub TMPDIR {
    my $TMPDIR =
	(grep(defined $_ && -d $_ && -w _,
	      ((defined $ENV{'TMPDIR'} ? $ENV{'TMPDIR'} : undef),
	       qw(/var/tmp /usr/tmp /tmp))))[0];
    $TMPDIR || die "Cannot find writable temporary directory.\n";
}

sub try_compile_and_link {
    my ($c, %args) = @_;

    my ($ok) = 0;
    my ($tmp) = (($^O eq 'VMS') ? "sys\$scratch:tmp$$" : TMPDIR() . '/' . "tmp$$");
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
	    $COREincdir = File::Spec->catdir(($updir) x 3);
	} else {
	    $COREincdir = File::Spec->catdir($Config{'archlibexp'}, 'CORE');
	}

	my $ccflags = $Config{'ccflags'} . ' ' . "-I$COREincdir";

	if ($^O eq 'VMS') {
	    if ($ENV{PERL_CORE}) {
		# Fragile if the extensions change hierachy within
		# the Perl core but this should do for now.
                $cccmd = "$Config{'cc'} /include=([---]) $tmp.c";
	    } else {
		my $perl_core = $Config{'installarchlib'};
		$perl_core =~ s/\]$/.CORE]/;
                $cccmd = "$Config{'cc'} /include=(perl_root:[000000],$perl_core) $tmp.c";
	    }
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
	    for ("$tmp.c", "$tmp$obj_ext", "$tmp.com", "$tmp$Config{exe_ext}") { 
		1 while unlink $_;
	    }
        }
        else
        {
	    printf "cccmd = $cccmd\n" if $VERBOSE;
	    system($cccmd);
	    $ok = -s $tmp && -x _;
	    unlink("$tmp.c", $tmp);
        }
    }
    
    $ok;
}

sub has_gettimeofday {
    # confusing but true (if condition true ==> -DHAS_GETTIMEOFDAY already)
    return 0 if $Config{'d_gettimeod'} eq 'define';
    return 1 if try_compile_and_link(<<EOM);
#include "EXTERN.h" 
#include "perl.h" 
#include "XSUB.h" 
#ifdef I_SYS_TYPES 
#   include <sys/types.h>
#endif

#ifdef I_SYS_TIME
#   include <sys/time.h>
#endif

#ifdef I_SYS_SELECT
#   include <sys/select.h>	/* struct timeval might be hidden in here */
#endif
static int foo()
{
    struct timeval tv;
    gettimeofday(&tv, 0);
}
int main _((int argc, char** argv, char** env))
{
    foo();
}
EOM
    return 0;
}

sub has_x {
    my ($x, %args) = @_;

    return 1 if
    try_compile_and_link(<<EOM, %args);
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef I_UNISTD
#   include <unistd.h>
#endif

#ifdef I_SYS_TYPES
#   include <sys/types.h>
#endif

#ifdef I_SYS_TIME
#   include <sys/time.h>
#endif

int main _((int argc, char** argv, char** env))
{
	$x;
}
EOM
    return 0;
}

sub unixinit {
    $DEFINE = '';

    $LIBS = [];

    # this might break the link, try it if it can't find some things you 
    # honestly think should be in there...
    # $LIBS = ['-lucb -lbsd'];

    # ... but ucb is poison for Solaris, and probably Linux. honest.
    $LIBS = [] if $Config{'osname'} eq 'solaris';
    $LIBS = [] if $Config{'osname'} eq 'linux';
    $LIBS = ['-lm'] if $Config{'osname'} =~ /sco/i;
    $LIBS = ['-lc'] if $Config{'osname'} =~ /dynixptx/i;

    # For nanosleep
    push @$LIBS, '-lrt'		unless $Config{'osname'} =~ /irix/;
    push @$LIBS, '-lposix4'	;

    my @goodlibs;

    select(STDOUT);
    $| = 1;

    print "Checking for libraries...\n";
    my $lib;
    for $lib (@$LIBS) {
	print "Checking for $lib... ";
	$LIBS = [ $lib ];
	if ($Config{libs} =~ /\b$lib\b/ || has_x("time(0)")) {
	    push @goodlibs, $lib;
	    print "found.\n";
	} else {
	    print "NOT found.\n";
	}
    }
    $LIBS = [ @goodlibs ];
    print @$LIBS ?
	  "You have extra libraries: @$LIBS.\n" :
          "You have no applicable extra libraries.\n";

    print "Looking for gettimeofday()... ";
    my $has_gettimeofday;
    if ($Config{'d_gettimeod'}) {
	$has_gettimeofday++;
    } elsif (has_gettimeofday()) {
	$DEFINE .= ' -DHAS_GETTIMEOFDAY';
	$has_gettimeofday++;
    }

    if ($has_gettimeofday) {
	print "found.\n";
    } else {
	die <<EOD
Your operating system does not seem to have the gettimeofday() function.
(or, at least, I cannot find it)

There is no way Time::HiRes is going to work.

I am awfully sorry but I cannot go further.

Aborting configuration.

EOD
    }

    print "Looking for setitimer()... ";
    my $has_setitimer;
    if ($Config{d_setitimer}) {
        $has_setitimer++;
    } elsif (has_x("setitimer(ITIMER_REAL, 0, 0)")) {
        $has_setitimer++;
        $DEFINE .= ' -DHAS_SETITIMER';
    }

    if ($has_setitimer) {
        print "found.\n";
    } else {
	print "NOT found.\n";
    }

    print "Looking for getitimer()... ";
    my $has_getitimer;
    if ($Config{d_getitimer}) {
        $has_getitimer++;
    } elsif (has_x("getitimer(ITIMER_REAL, 0)")) {
        $has_getitimer++;
        $DEFINE .= ' -DHAS_GETITIMER';
    }

    if ($has_getitimer) {
        print "found.\n";
    } else {
	print "NOT found.\n";
    }

    if ($has_setitimer && $has_getitimer) {
	print "You have interval timers (both setitimer and setitimer).\n";
    } else {
	print "You do not have interval timers.\n";
    }

    print "Looking for ualarm()... ";
    my $has_ualarm;
    if ($Config{d_ualarm}) {
        $has_ualarm++;
    } elsif (has_x ("ualarm (0, 0)")) {
        $has_ualarm++;
	$DEFINE .= ' -DHAS_UALARM';
    }

    if ($has_ualarm) {
        print "found.\n";
    } else {
	print "NOT found.\n";
	if ($has_setitimer) {
	    print "But you have setitimer().\n";
	    print "We can make a Time::HiRes::ualarm().\n";
	}
    }

    print "Looking for usleep()... ";
    my $has_usleep;
    if ($Config{d_usleep}) {
	$has_usleep++;
    } elsif (has_x ("usleep (0)")) {
	$has_usleep++;
	$DEFINE .= ' -DHAS_USLEEP';
    }

    if ($has_usleep) {
	print "found.\n";
    } else {
	print "NOT found.\n";
        print "Let's see if you have select()... ";
        if ($Config{'d_select'} eq 'define') {
	    print "found.\n";
	    print "We can make a Time::HiRes::usleep().\n";
	} else {
	    print "NOT found.\n";
	    print "You won't have a Time::HiRes::usleep().\n";
	}
    }

    print "Looking for nanosleep()... ";
    my $has_nanosleep;
    if ($Config{d_nanosleep}) {
	$has_nanosleep++;
    } elsif (has_x ("nanosleep (NULL, NULL)")) {
	$has_nanosleep++;
	$DEFINE .= ' -DHAS_NANOSLEEP';
    }

    if ($has_nanosleep) {
	print "found.\n";
        print "You can mix subsecond sleeps with signals.\n";
    } else {
	print "NOT found.\n";
        print "You cannot mix subsecond sleeps with signals.\n";
    }

    if ($DEFINE) {
        $DEFINE =~ s/^\s+//;
        if (open(XDEFINE, ">xdefine")) {
	    print XDEFINE $DEFINE, "\n";
	    close(XDEFINE);
        }
    }
}

sub doMakefile {
    my @makefileopts = ();

    if ($] >= 5.005) {
	push (@makefileopts,
	    'AUTHOR'    => 'Jarkko Hietaniemi <jhi@iki.fi>',
	    'ABSTRACT_FROM' => 'HiRes.pm',
	);
	$DEFINE .= " -DATLEASTFIVEOHOHFIVE";
    }

    push (@makefileopts,
	'NAME'	=> 'Time::HiRes',
	'VERSION_FROM' => 'HiRes.pm', # finds $VERSION
	'LIBS'	=> $LIBS,   # e.g., '-lm' 
	'DEFINE'	=> $DEFINE,     # e.g., '-DHAS_SOMETHING' 
	'XSOPT'	=> $XSOPT,
    # do not even think about 'INC' => '-I/usr/ucbinclude', Solaris will avenge.
	'INC'	=> '',     # e.g., '-I/usr/include/other' 
	'INSTALLDIRS' => 'perl',
	'dist'      => {
	    'CI'       => 'ci -l',
	    'COMPRESS' => 'gzip -9f', 
	    'SUFFIX'   => 'gz',
	},
        clean => { FILES => "xdefine" },
    );

    WriteMakefile(@makefileopts);
}

sub main {
    print "Configuring Time::HiRes...\n";

    if ($^O =~ /Win32/i) {
      $DEFINE = '-DSELECT_IS_BROKEN';
      $LIBS = [''];
    } else {
      unixinit();
    }
    doMakefile;
    my $make = $Config{'make'} || "make";
    unless ($ENV{PERL_CORE}) {
	print  <<EOM;
Now you may issue '$make'.  Do not forget also '$make test'.
EOM
    }
}

&main;

# EOF
