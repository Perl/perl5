require 5.004;
use strict;
use Config qw(%Config);
use ExtUtils::MakeMaker;

my @extra;
@extra = (DEFINE => "-DU32_ALIGNMENT_REQUIRED")
    if !($Config{'byteorder'} eq '1234' || $Config{'byteorder'} eq '4321') ||
       $^O eq 'VMS' ||
       $Config{d_u32align};

WriteMakefile(
    'NAME'	   => 'Digest::MD5',
    'VERSION_FROM' => 'MD5.pm',
    @extra,
    'dist'         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
exit;

