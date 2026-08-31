#! perl -w

use strict ;
use warnings;
require 5.008 ;

$::VERSION = '2.224' ;
$::DEP_ZLIB_VERSION = '2.224';
$::DEP_BZIP2_VERSION = '2.224';

use lib '.';
use private::MakeUtil;
use ExtUtils::MakeMaker 5.16 ;

# Old ExtUtils::MakeMakers may have literal _ in their VERSIONs. Strip it out
# so we can use normal numeric comparisons: '6.57_02' -> 6.5702
(my $mm_version = ExtUtils::MakeMaker->VERSION) =~ tr/_//d;

WriteMakefile(
    NAME         => 'IO::Compress',
    VERSION_FROM => 'lib/IO/Compress/Base.pm',
    'dist'       => { COMPRESS     => 'gzip',
                      TARFLAGS     => '-chvf',
                      SUFFIX       => 'gz',
                      DIST_DEFAULT => 'MyTrebleCheck tardist',
                    },

    (
      $ENV{SKIP_FOR_CORE}
        ? ()
	    : (PREREQ_PM   => { 'Compress::Raw::Bzip2' => $::DEP_BZIP2_VERSION,
		                    'Compress::Raw::Zlib'  => $::DEP_ZLIB_VERSION,
		                    'Scalar::Util'  => 0,
                            'Encode'        => 0,
                            'Time::Local'   => 0,
                          }
	      )
    ),

    ABSTRACT => 'IO Interface to compressed data files/buffers',
    AUTHOR   => 'Paul Marquess <pmqs@cpan.org>',

    INSTALLDIRS => ($] >= 5.009 && $] < 5.011 ? 'perl' : 'site'),

    EXE_FILES => ['bin/zipdetails', 'bin/streamzip'],

    (
    $] >= 5.009 && $] <= 5.011001 && ! $ENV{PERL_CORE}
        ? (INSTALLPRIVLIB    => '$(INSTALLARCHLIB)')
        : ()
    ),

     ( $mm_version >= 6.46
        ? ( META_MERGE  => {

                "meta-spec" => { version => 2 },

                no_index => {
                    directory => [ 't', 'private' ],
                },

                resources   => {

                    bugtracker  => {
                        web     => 'https://github.com/pmqs/IO-Compress/issues'
                    },

                    homepage    => 'https://github.com/pmqs/IO-Compress',

                    repository  => {
                        type    => 'git',
                        url     => 'git://github.com/pmqs/IO-Compress.git',
                        web     => 'https://github.com/pmqs/IO-Compress',
                    },
                },
              }
            )
        : ()
    ),

    ($mm_version >= 6.30 ?
        ('LICENSE'  => 'perl')         : ()),

) ;

# end of file Makefile.PL
