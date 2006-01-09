package IO::Compress::Zip ;

use strict ;
use warnings;

use Compress::Zlib::Common qw(createSelfTiedObject);
use CompressPlugin::Deflate;
use CompressPlugin::Identity;
use IO::Compress::RawDeflate;

require Exporter ;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS, $ZipError);

$VERSION = '2.000_04';
$ZipError = '';

@ISA = qw(Exporter IO::Compress::RawDeflate);
@EXPORT_OK = qw( $ZipError zip ) ;
%EXPORT_TAGS = %IO::Compress::RawDeflate::DEFLATE_CONSTANTS ;
push @{ $EXPORT_TAGS{all} }, @EXPORT_OK ;
Exporter::export_ok_tags('all');


sub new
{
    my $class = shift ;

    my $obj = createSelfTiedObject($class, \$ZipError);    
    $obj->_create(undef, @_);
}

sub zip
{
    my $obj = createSelfTiedObject(undef, \$ZipError);    
    return $obj->_def(@_);
}

sub mkComp
{
    my $self = shift ;
    my $class = shift ;
    my $got = shift ;

    my ($obj, $errstr, $errno) ;

    if (*$self->{ZipData}{Store}) {
        #return CompressPlugin::Deflate::mkCompObject($self, $class, $got)
        ($obj, $errstr, $errno) = CompressPlugin::Identity::mkCompObject(
                                                 $got->value('CRC32'),
                                                 $got->value('Adler32'),
                                                 $got->value('Level'),
                                                 $got->value('Strategy')
                                                 );
    }
    else {
        #return CompressPlugin::Deflate::mkCompObject($self, $class, $got)
        ($obj, $errstr, $errno) = CompressPlugin::Deflate::mkCompObject(
                                                 $got->value('CRC32'),
                                                 $got->value('Adler32'),
                                                 $got->value('Level'),
                                                 $got->value('Strategy')
                                                 );
    }

   return $self->saveErrorString(undef, $errstr, $errno)
       if ! defined $obj;

   return $obj;    
}



sub mkHeader
{
    my $self  = shift;
    my $param = shift ;
    
    my $filename = '';
    $filename = $param->value('Name') || '';

    my $comment = '';
    $comment = $param->value('Comment') || '';

    my $extract = $param->value('OS_Code') << 8 + 20 ;
    my $hdr = '';

    my $time = _unixToDosTime($param->value('Time'));
    *$self->{ZipData}{StartOffset} = *$self->{ZipData}{Offset} ;

    my $strm = *$self->{ZipData}{Stream} ? 8 : 0 ;
    my $method = *$self->{ZipData}{Store} ? 0 : 8 ;

    $hdr .= pack "V", 0x04034b50 ; # signature
    $hdr .= pack 'v', $extract   ; # extract Version & OS
    $hdr .= pack 'v', $strm      ; # general purpose flag (set streaming mode)
    $hdr .= pack 'v', $method    ; # compression method (deflate)
    $hdr .= pack 'V', $time      ; # last mod date/time
    $hdr .= pack 'V', 0          ; # crc32               - 0 when streaming
    $hdr .= pack 'V', 0          ; # compressed length   - 0 when streaming
    $hdr .= pack 'V', 0          ; # uncompressed length - 0 when streaming
    $hdr .= pack 'v', length $filename ; # filename length
    $hdr .= pack 'v', 0          ; # extra length
    
    $hdr .= $filename ;


    my $ctl = '';

    $ctl .= pack "V", 0x02014b50 ; # signature
    $ctl .= pack 'v', $extract   ; # version made by
    $ctl .= pack 'v', $extract   ; # extract Version
    $ctl .= pack 'v', $strm      ; # general purpose flag (streaming mode)
    $ctl .= pack 'v', $method    ; # compression method (deflate)
    $ctl .= pack 'V', $time      ; # last mod date/time
    $ctl .= pack 'V', 0          ; # crc32
    $ctl .= pack 'V', 0          ; # compressed length
    $ctl .= pack 'V', 0          ; # uncompressed length
    $ctl .= pack 'v', length $filename ; # filename length
    $ctl .= pack 'v', 0          ; # extra length
    $ctl .= pack 'v', length $comment ;  # file comment length
    $ctl .= pack 'v', 0          ; # disk number start 
    $ctl .= pack 'v', 0          ; # internal file attributes
    $ctl .= pack 'V', 0          ; # external file attributes
    $ctl .= pack 'V', *$self->{ZipData}{Offset}  ; # offset to local header
    
    $ctl .= $filename ;
    #$ctl .= $extra ;
    $ctl .= $comment ;

    *$self->{ZipData}{Offset} += length $hdr ;

    *$self->{ZipData}{CentralHeader} = $ctl;

    return $hdr;
}

sub mkTrailer
{
    my $self = shift ;

    my $crc32             = *$self->{Compress}->crc32();
    my $compressedBytes   = *$self->{Compress}->compressedBytes();
    my $uncompressedBytes = *$self->{Compress}->uncompressedBytes();

    my $data ;
    $data .= pack "V", $crc32 ;                           # CRC32
    $data .= pack "V", $compressedBytes   ;               # Compressed Size
    $data .= pack "V", $uncompressedBytes;                # Uncompressed Size

    my $hdr = '';

    if (*$self->{ZipData}{Stream}) {
        $hdr  = pack "V", 0x08074b50 ;                       # signature
        $hdr .= $data ;
    }
    else {
        $self->writeAt(*$self->{ZipData}{StartOffset} + 14, $data)
            or return undef;
    }

    my $ctl = *$self->{ZipData}{CentralHeader} ;
    substr($ctl, 16, 12) = $data ;
    #substr($ctl, 16, 4) = pack "V", $crc32 ;             # CRC32
    #substr($ctl, 20, 4) = pack "V", $compressedBytes   ; # Compressed Size
    #substr($ctl, 24, 4) = pack "V", $uncompressedBytes ; # Uncompressed Size

    *$self->{ZipData}{Offset} += length($hdr) + $compressedBytes;
    push @{ *$self->{ZipData}{CentralDir} }, $ctl ;

    return $hdr;
}

sub mkFinalTrailer
{
    my $self = shift ;

    my $entries = @{ *$self->{ZipData}{CentralDir} };
    my $cd = join '', @{ *$self->{ZipData}{CentralDir} };

    my $ecd = '';
    $ecd .= pack "V", 0x06054b50 ; # signature
    $ecd .= pack 'v', 0          ; # number of disk
    $ecd .= pack 'v', 0          ; # number if disk with central dir
    $ecd .= pack 'v', $entries   ; # entries in central dir on this disk
    $ecd .= pack 'v', $entries   ; # entries in central dir
    $ecd .= pack 'V', length $cd ; # size of central dir
    $ecd .= pack 'V', *$self->{ZipData}{Offset} ; # offset to start central dir
    $ecd .= pack 'v', 0          ; # zipfile comment length
    #$ecd .= $comment;

    return $cd . $ecd ;
}

sub ckParams
{
    my $self = shift ;
    my $got = shift;
    
    $got->value('CRC32' => 1);

    if (! $got->parsed('Time') ) {
        # Modification time defaults to now.
        $got->value('Time' => time) ;
    }

    *$self->{ZipData}{Stream} = $got->value('Stream');
    *$self->{ZipData}{Store} = $got->value('Store');
    *$self->{ZipData}{StartOffset} = *$self->{ZipData}{Offset} = 0;

    return 1 ;
}

#sub newHeader
#{
#    my $self = shift ;
#
#    return $self->mkHeader(*$self->{Got});
#}

sub getExtraParams
{
    my $self = shift ;

    use Compress::Zlib::ParseParameters;
    use Compress::Zlib qw(Z_DEFLATED Z_DEFAULT_COMPRESSION Z_DEFAULT_STRATEGY);

    
    return (
            # zlib behaviour
            $self->getZlibParams(),

            'Stream'    => [1, 1, Parse_boolean,   1],
            'Store'     => [0, 1, Parse_boolean,   0],
            
#            # Zip header fields
#           'Minimal'   => [0, 1, Parse_boolean,   0],
            'Comment'   => [0, 1, Parse_any,       undef],
            'ZipComment'=> [0, 1, Parse_any,       undef],
            'Name'      => [0, 1, Parse_any,       undef],
            'Time'      => [0, 1, Parse_any,       undef],
            'OS_Code'   => [0, 1, Parse_unsigned,  $Compress::Zlib::gzip_os_code],
            
#           'TextFlag'  => [0, 1, Parse_boolean,   0],
#           'ExtraField'=> [0, 1, Parse_string,    undef],
        );
}

sub getInverseClass
{
    return ('IO::Uncompress::Unzip',
                \$IO::Uncompress::Unzip::UnzipError);
}

sub getFileInfo
{
    my $self = shift ;
    my $params = shift;
    my $filename = shift ;

    my $defaultTime = (stat($filename))[9] ;

    $params->value('Name' => $filename)
        if ! $params->parsed('Name') ;

    $params->value('Time' => $defaultTime) 
        if ! $params->parsed('Time') ;
    
    
}

# from Archive::Zip
sub _unixToDosTime    # Archive::Zip::Member
{
	my $time_t = shift;
    # TODO - add something to cope with unix time < 1980 
	my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime($time_t);
	my $dt = 0;
	$dt += ( $sec >> 1 );
	$dt += ( $min << 5 );
	$dt += ( $hour << 11 );
	$dt += ( $mday << 16 );
	$dt += ( ( $mon + 1 ) << 21 );
	$dt += ( ( $year - 80 ) << 25 );
	return $dt;
}

1;

__END__
