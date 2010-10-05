# core-only Makefile.PL
use strict;
use ExtUtils::MakeMaker;
require File::Copy;

my @scripts = qw(pod2man.PL pod2text.PL);
my $script_ext = $^O eq 'VMS' ? '.com' : '';
my %pod_scripts;

foreach (@scripts) {
    File::Copy::copy("scripts/$_", $_)
	    or die "Can't copy scripts/$_ to $_: $!";
    my $output = s/.PL$/$script_ext/r;
    $pod_scripts{$_} = $output;
}

my @exe_files = values %pod_scripts;

WriteMakefile (
    NAME          => 'Pod',
    DISTNAME      => 'podlators',
    VERSION_FROM  => 'VERSION',
    realclean     => { FILES => "@scripts" },
    PL_FILES      => \%pod_scripts,
    EXE_FILES     => \@exe_files,
    clean         => { FILES => "@exe_files" },
);
