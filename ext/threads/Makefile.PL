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
    push(@conditional_params, 'DEFINE'   => '-DHAS_PPPORT_H');
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

# EOF
