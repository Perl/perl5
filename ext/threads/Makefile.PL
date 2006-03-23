# Module makefile for threads (using ExtUtils::MakeMaker)

require 5.008;

use strict;
use warnings;

use ExtUtils::MakeMaker;


# Build options for different environments
my @conditional_params;
if (grep { $_ eq 'PERL_CORE=1' } @ARGV) {
    # Core
    push(@conditional_params, 'MAN3PODS' => {},
                              'NORECURS' => 1);
} else {
    # CPAN
    push(@conditional_params, 'CCFLAGS'  => '-DHAS_PPPORT_H');
}


WriteMakefile(
    'NAME'              => 'threads',
    'AUTHOR'            => 'Artur Bergman <sky AT crucially DOT net>',
    'VERSION_FROM'      => 'threads.pm',
    'ABSTRACT_FROM'     => 'threads.pm',
    'PM' => {
        'threads.pm'    => '$(INST_LIBDIR)/threads.pm',
    },
    'PREREQ_PM'         => {
        'threads::shared' => 0,
        'XSLoader'        => 0,
    },
    'INSTALLDIRS'       => 'perl',

    ((ExtUtils::MakeMaker->VERSION() lt '6.25') ?
        ('PL_FILES' => { })            : ()),
    ((ExtUtils::MakeMaker->VERSION() gt '6.30') ?
        ('LICENSE'  => 'perl')         : ()),

    @conditional_params
);


# Add additional target(s) to Makefile for use by module maintainer
sub MY::postamble
{
    return <<'_EXTRAS_';
ppport:
	@( cd /tmp; perl -e 'use Devel::PPPort; Devel::PPPort::WriteFile("ppport.h");' )
	@if ! cmp -s ppport.h /tmp/ppport.h; then \
	    diff ppport.h /tmp/ppport.h ; \
	    echo; \
	    perl /tmp/ppport.h; \
	fi
_EXTRAS_
}

# EOF
