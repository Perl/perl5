# Module makefile for threads (using ExtUtils::MakeMaker)

require 5.008;

use strict;
use warnings;

use ExtUtils::MakeMaker;


# Used to check for a 'C' compiler
sub check_cc
{
    require File::Spec;

    my $cmd = $_[0];
    if (-x $cmd or MM->maybe_command($cmd)) {
        return (1);       # CC command found
    }
    for my $dir (File::Spec->path(), '.') {
        my $abs = File::Spec->catfile($dir, $cmd);
        if (-x $abs or MM->maybe_command($abs)) {
            return (1);   # CC command found
        }
    }
    return;
}

sub have_cc
{
    eval { require Config_m; };     # ExtUtils::FakeConfig (+ ActivePerl)
    if ($@) {
        eval { require Config; };   # Everyone else
    }
    my @chunks = split(/ /, $Config::Config{cc});
    # $Config{cc} may contain args; try to find out the program part
    while (@chunks) {
        if (check_cc("@chunks")) {
            return (1);   # CC command found
        }
        pop(@chunks);
    }
    return;
}


# Build options for different environments
my @conditional_params;
if (grep { $_ eq 'PERL_CORE=1' } @ARGV) {
    # Core
    push(@conditional_params, 'MAN3PODS' => {},
                              'NORECURS' => 1);
} else {
    # CPAN

    # Verify that a 'C' compiler is available
    if (! have_cc()) {
        die("No 'C' compiler found to build 'threads'\n");
    }

    push(@conditional_params, 'DEFINE' => '-DHAS_PPPORT_H');
}


# Create Makefile
WriteMakefile(
    'NAME'              => 'threads',
    'AUTHOR'            => 'Artur Bergman <sky AT crucially DOT net>',
    'VERSION_FROM'      => 'threads.pm',
    'ABSTRACT_FROM'     => 'threads.pm',
    'PM' => {
        'threads.pm'    => '$(INST_LIBDIR)/threads.pm',
    },
    'PREREQ_PM'         => {
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
