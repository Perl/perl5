#! perl -w

use strict ;
require 5.004 ;

$::VERSION = '2.004' ;

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
	    : (PREREQ_PM   => { 'Compress::Raw::Zlib'           => $::VERSION,
		                    'IO::Compress::Base'            => $::VERSION,
		                    'IO::Compress::Base::Common'    => $::VERSION,
		                    'IO::Uncompress::Base'          => $::VERSION,
		                    'IO::Compress::Gzip'            => $::VERSION,
		                    'IO::Compress::Gzip::Constants' => $::VERSION,
		                    'IO::Uncompress::Gunzip'        => $::VERSION,
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

    ((ExtUtils::MakeMaker->VERSION() gt '6.30') ?
        ('LICENSE'  => 'perl')         : ()),    

) ;

# end of file Makefile.PL

