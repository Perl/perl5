require 5.004;
use strict;
use Config qw(%Config);
use ExtUtils::MakeMaker;

my @extra;
@extra = (DEFINE => "-DU32_ALIGNMENT_REQUIRED")
    if $Config{'byteorder'} ne '1234' ||
       $Config{'byteorder'} ne '4321' ||
       $^O eq 'VMS' ||
       $Config{u32_alignment_required};

WriteMakefile(
    'NAME'	   => 'Digest::MD5',
    'VERSION_FROM' => 'MD5.pm',
    @extra,
    'dist'         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
exit;

