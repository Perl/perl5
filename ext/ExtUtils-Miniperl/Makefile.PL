#!perl -w

# Blatantly copied from ext/Pod-Functions/Makefile.PL
# If we think we want a third copy, then it's time to find a better way to do
# this. (Note, we have no ABSTRACT_FROM here)
# But for now, this replaces a bunch of platform specific special case code
# in the Makefiles for *nix, Win32 and VMS with one unified implementation.
# And in Perl, rather than 3+ different languages.

use strict;
use ExtUtils::MakeMaker;
use File::Spec::Functions;

WriteMakefile(NAME => 'ExtUtils::Miniperl',
	      VERSION_FROM => 'Miniperl_pm.PL',
	      LICENSE => 'perl',
	      PREREQ_PM => {},
	      AUTHOR => 'Perl 5 Porters <perlbug@perl.org>',
	      INSTALLDIRS => 'perl',
	      PL_FILES => {}, # Stop EU::MM defaulting this to run our PL
	      PM => {'Miniperl.pm' => '$(INST_LIBDIR)/Miniperl.pm'},
	      clean => {FILES => 'Miniperl.pm'},
	     );

# There doesn't seem to be any way to get ExtUtils::MakeMaker to add a
# dependency on another file (or target), and as it's using :: rules, not :
# rules, then we can't simply add a one line dependency. So we need to provide
# the entire thing. Fortunately, the same code in MM_Unix.pm is actually used
# for all platforms, so this code below should also be portable:

sub MY::postamble {
    my $main = catfile(updir, updir, 'miniperlmain.c');
    return <<"EOT";
all :: Miniperl.pm
	\$(NOECHO) \$(NOOP)

Miniperl.pm :: Miniperl_pm.PL $main
	\$(PERLRUN) Miniperl_pm.PL $main
EOT
}
