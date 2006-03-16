#! perl -w

use strict ;
require 5.004 ;

use private::MakeUtil;
use ExtUtils::MakeMaker 5.16 ;

UpDowngrade(getPerlFiles('MANIFEST')) 
    unless $ENV{PERL_CORE};

WriteMakefile( 
    NAME         => 'Compress::Zlib',
    VERSION_FROM => 'lib/Compress/Zlib.pm',
    'dist'       => { COMPRESS     => 'gzip', 
                      TARFLAGS     => '-chvf',
                      SUFFIX       => 'gz',
                      DIST_DEFAULT => 'MyTrebleCheck tardist',
                    },

    (
      $ENV{SKIP_FOR_CORE}
        ? (MAN3PODS    => {})
	    : (PREREQ_PM   => { 'Compress::Raw::Zlib'           => 0,
		                    'IO::Compress::Base'            => 0,
		                    'IO::Compress::Base::Common'    => 0,
		                    'IO::Uncompress::Base'          => 0,
		                    'IO::Compress::Gzip'            => 0,
		                    'IO::Compress::Gzip::Constants' => 0,
		                    'IO::Uncompress::Gunzip'        => 0,
		                    'Scalar::Util'                  => 0,
                          }
	      )
    ),
       
    (
    $] >= 5.005
        ? (ABSTRACT_FROM => 'lib/Compress/Zlib.pm',
            AUTHOR       => 'Paul Marquess <pmqs@cpan.org>')
        : ()
    ),

) ;

# end of file Makefile.PL

