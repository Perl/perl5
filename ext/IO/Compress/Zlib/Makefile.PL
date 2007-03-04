#! perl -w

use strict ;
require 5.004 ;

$::VERSION = '2.004' ;

use private::MakeUtil;
use ExtUtils::MakeMaker 5.16 ;

UpDowngrade(getPerlFiles('MANIFEST')) 
    unless $ENV{PERL_CORE};

WriteMakefile( 
    NAME         => 'IO::Compress::Zlib',
    VERSION_FROM => 'lib/IO/Compress/Gzip.pm',
    'dist'       => { COMPRESS     => 'gzip', 
                      TARFLAGS     => '-chvf',
                      SUFFIX       => 'gz',
                      DIST_DEFAULT => 'MyTrebleCheck tardist',
                    },

    (
      $ENV{SKIP_FOR_CORE}
        ? (MAN3PODS    => {})
	    : (PREREQ_PM   => { 'Compress::Raw::Zlib'  => $::VERSION,
		                    'IO::Compress::Base'   => $::VERSION,
		                    'IO::Uncompress::Base' => $::VERSION,
		                    $] >= 5.005 && $] < 5.006   
                                ? ('File::BSDGlob' => 0) 
                                : () }
	      )
    ),
       
    (
    $] >= 5.005
        ? (ABSTRACT => 'Perl interface to zlib',
            AUTHOR  => 'Paul Marquess <pmqs@cpan.org>')
        : ()
    ),

    ((ExtUtils::MakeMaker->VERSION() gt '6.30') ?
        ('LICENSE'  => 'perl')         : ()),    

) ;

# end of file Makefile.PL

