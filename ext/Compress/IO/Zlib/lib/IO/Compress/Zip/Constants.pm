package IO::Compress::Zip::Constants;

use strict ;
use warnings;

require Exporter;

our ($VERSION, @ISA, @EXPORT, %GZIP_OS_Names);

$VERSION = '2.000_10';

@ISA = qw(Exporter);

@EXPORT= qw(

    ZIP_ID_SIZE
    GZIP_ID1
    GZIP_ID2

    GZIP_FLG_DEFAULT
    GZIP_FLG_FTEXT
    GZIP_FLG_FHCRC
    GZIP_FLG_FEXTRA
    GZIP_FLG_FNAME
    GZIP_FLG_FCOMMENT
    GZIP_FLG_RESERVED

    GZIP_CM_DEFLATED

    GZIP_MIN_HEADER_SIZE
    GZIP_TRAILER_SIZE

    GZIP_MTIME_DEFAULT
    GZIP_FEXTRA_DEFAULT
    GZIP_FEXTRA_HEADER_SIZE
    GZIP_FEXTRA_MAX_SIZE
    GZIP_FEXTRA_SUBFIELD_HEADER_SIZE
    GZIP_FEXTRA_SUBFIELD_ID_SIZE
    GZIP_FEXTRA_SUBFIELD_LEN_SIZE
    GZIP_FEXTRA_SUBFIELD_MAX_SIZE

    GZIP_FNAME_INVALID_CHAR_RE
    GZIP_FCOMMENT_INVALID_CHAR_RE

    GZIP_FHCRC_SIZE

    GZIP_ISIZE_MAX
    GZIP_ISIZE_MOD_VALUE


    GZIP_NULL_BYTE

    GZIP_OS_DEFAULT

    %GZIP_OS_Names

    GZIP_MINIMUM_HEADER

    );


# Constants for the Zip Local Header

use constant ZIP_ID_SIZE                        => 4 ;
use constant ZIP_LOCAL_ID                       => 0x02014B50;
use constant ZIP_LOCAL_ID1                      => 0x04;
use constant ZIP_LOCAL_ID2                      => 0x03;
use constant ZIP_LOCAL_ID3                      => 0x4B;
use constant ZIP_LOCAL_ID4                      => 0x50;

use constant ZIP_MIN_HEADER_SIZE                => 30 ;
use constant ZIP_TRAILER_SIZE                   => 0 ;


use constant GZIP_FLG_DEFAULT                   => 0x00 ;
use constant GZIP_FLG_FTEXT                     => 0x01 ;
use constant GZIP_FLG_FHCRC                     => 0x02 ; # called CONTINUATION in gzip
use constant GZIP_FLG_FEXTRA                    => 0x04 ;
use constant GZIP_FLG_FNAME                     => 0x08 ;
use constant GZIP_FLG_FCOMMENT                  => 0x10 ;
#use constant GZIP_FLG_ENCRYPTED                => 0x20 ; # documented in gzip sources
use constant GZIP_FLG_RESERVED                  => (0x20 | 0x40 | 0x80) ;

use constant GZIP_MTIME_DEFAULT                 => 0x00 ;
use constant GZIP_FEXTRA_DEFAULT                => 0x00 ;
use constant GZIP_FEXTRA_HEADER_SIZE            => 2 ;
use constant GZIP_FEXTRA_MAX_SIZE               => 0xFFFF ;
use constant GZIP_FEXTRA_SUBFIELD_HEADER_SIZE   => 4 ;
use constant GZIP_FEXTRA_SUBFIELD_ID_SIZE       => 2 ;
use constant GZIP_FEXTRA_SUBFIELD_LEN_SIZE      => 2 ;
use constant GZIP_FEXTRA_SUBFIELD_MAX_SIZE      => 0xFFFF ;

use constant GZIP_FNAME_INVALID_CHAR_RE         => qr/[\x00-\x1F\x7F-\x9F]/;
use constant GZIP_FCOMMENT_INVALID_CHAR_RE      => qr/[\x00-\x09\x11-\x1F\x7F-\x9F]/;

use constant GZIP_FHCRC_SIZE                    => 2 ; # aka CONTINUATION in gzip

use constant GZIP_CM_DEFLATED                   => 8 ;

use constant GZIP_NULL_BYTE                     => "\x00";
use constant GZIP_ISIZE_MAX                     => 0xFFFFFFFF ;
use constant GZIP_ISIZE_MOD_VALUE               => GZIP_ISIZE_MAX + 1 ;

# OS Names sourced from http://www.gzip.org/format.txt

use constant GZIP_OS_DEFAULT=> 0xFF ;
%ZIP_OS_Names = (
    0               => 'MS-DOS',
    1               => 'Amiga',
    2               => 'VMS',
    3               => 'Unix',
    4               => 'VM/CMS',
    5               => 'Atari TOS',
    6               => 'HPFS (OS/2, NT)',
    7               => 'Macintosh',
    8               => 'Z-System',
    9               => 'CP/M',
    10              => 'TOPS-20',
    11              => 'NTFS (NT)',
    12              => 'SMS QDOS',
    13              => 'Acorn RISCOS',
    14              => 'VFAT file system (Win95, NT)',
    15              => 'MVS',
    16              => 'BeOS',
    17              => 'Tandem/NSK',
    18              => 'THEOS',
    GZIP_OS_DEFAULT => 'Unknown',
    ) ;

use constant GZIP_MINIMUM_HEADER =>   pack("C4 V C C",  
    GZIP_ID1, GZIP_ID2, GZIP_CM_DEFLATED, GZIP_FLG_DEFAULT,
    GZIP_MTIME_DEFAULT, GZIP_FEXTRA_DEFAULT, GZIP_OS_DEFAULT) ;


1;
