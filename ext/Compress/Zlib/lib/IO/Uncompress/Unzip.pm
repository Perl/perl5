package IO::Uncompress::Unzip;

require 5.004 ;

# for RFC1952

use strict ;
use warnings;

use IO::Uncompress::RawInflate ;
use Compress::Zlib::Common qw(createSelfTiedObject);
use UncompressPlugin::Identity;

require Exporter ;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS, $UnzipError);

$VERSION = '2.000_05';
$UnzipError = '';

@ISA    = qw(Exporter IO::Uncompress::RawInflate);
@EXPORT_OK = qw( $UnzipError unzip );
%EXPORT_TAGS = %IO::Uncompress::RawInflate::EXPORT_TAGS ;
push @{ $EXPORT_TAGS{all} }, @EXPORT_OK ;
Exporter::export_ok_tags('all');


sub new
{
    my $class = shift ;
    my $obj = createSelfTiedObject($class, \$UnzipError);
    $obj->_create(undef, 0, @_);
}

sub unzip
{
    my $obj = createSelfTiedObject(undef, \$UnzipError);
    return $obj->_inf(@_) ;
}

sub getExtraParams
{
    use Compress::Zlib::ParseParameters;

    
    return (
#            # Zip header fields
            'Name'      => [1, 1, Parse_any,       undef],

#            'Streaming' => [1, 1, Parse_boolean,   1],
        );    
}

sub ckParams
{
    my $self = shift ;
    my $got = shift ;

    # unzip always needs crc32
    $got->value('CRC32' => 1);

    *$self->{UnzipData}{Name} = $got->value('Name');

    return 1;
}


sub ckMagic
{
    my $self = shift;

    my $magic ;
    $self->smartReadExact(\$magic, 4);

    *$self->{HeaderPending} = $magic ;

    return $self->HeaderError("Minimum header size is " . 
                              4 . " bytes") 
        if length $magic != 4 ;                                    

    return $self->HeaderError("Bad Magic")
        if ! _isZipMagic($magic) ;

    *$self->{Type} = 'zip';

    return $magic ;
}



sub readHeader
{
    my $self = shift;
    my $magic = shift ;

    my $name =  *$self->{UnzipData}{Name} ;
    my $status = $self->_readZipHeader($magic) ;

    while (defined $status)
    {
        if (! defined $name || $status->{Name} eq $name)
        {
            return $status ;
        }

        # skip the data
        my $c = $status->{CompressedLength};
        my $buffer;
        $self->smartReadExact(\$buffer, $c)
            or return $self->saveErrorString(undef, "Truncated file");

        # skip the trailer
        $c = $status->{TrailerLength};
        $self->smartReadExact(\$buffer, $c)
            or return $self->saveErrorString(undef, "Truncated file");

        $self->chkTrailer($buffer)
            or return $self->saveErrorString(undef, "Truncated file");

        $status = $self->_readFullZipHeader();

        return $self->saveErrorString(undef, "Cannot find '$name'")
            if $self->smartEof();
    }

    return undef;
}

sub chkTrailer
{
    my $self = shift;
    my $trailer = shift;

    my ($sig, $CRC32, $cSize, $uSize) ;
    if (*$self->{ZipData}{Streaming}) {
        ($sig, $CRC32, $cSize, $uSize) = unpack("V V V V", $trailer) ;
        return $self->TrailerError("Data Descriptor signature")
            if $sig != 0x08074b50;
    }
    else {
        ($CRC32, $cSize, $uSize) = 
            (*$self->{ZipData}{Crc32},
             *$self->{ZipData}{CompressedLen},
             *$self->{ZipData}{UnCompressedLen});
    }

    if (*$self->{Strict}) {
        #return $self->TrailerError("CRC mismatch")
        #    if $CRC32  != *$self->{Uncomp}->crc32() ;

        my $exp_isize = *$self->{Uncomp}->compressedBytes();
        return $self->TrailerError("CSIZE mismatch. Got $cSize"
                                  . ", expected $exp_isize")
            if $cSize != $exp_isize ;

        $exp_isize = *$self->{Uncomp}->uncompressedBytes();
        return $self->TrailerError("USIZE mismatch. Got $uSize"
                                  . ", expected $exp_isize")
            if $uSize != $exp_isize ;
    }

    # check for central directory or end of central directory
    while (1)
    {
        my $magic ;
        $self->smartReadExact(\$magic, 4);
        my $sig = unpack("V", $magic) ;

        if ($sig == 0x02014b50)
        {
            $self->skipCentralDirectory($magic);
        }
        elsif ($sig == 0x06054b50)
        {
            $self->skipEndCentralDirectory($magic);
            last;
        }
        else
        {
            # put the data back
            $self->pushBack($magic)  ;
            last;
        }
    }

    return 1 ;
}

sub skipCentralDirectory
{
    my $self = shift;
    my $magic = shift ;

    my $buffer;
    $self->smartReadExact(\$buffer, 46 - 4)
        or return $self->HeaderError("Minimum header size is " . 
                                     46 . " bytes") ;

    my $keep = $magic . $buffer ;
    *$self->{HeaderPending} = $keep ;

   #my $versionMadeBy      = unpack ("v", substr($buffer, 4-4,  2));
   #my $extractVersion     = unpack ("v", substr($buffer, 6-4,  2));
   #my $gpFlag             = unpack ("v", substr($buffer, 8-4,  2));
   #my $compressedMethod   = unpack ("v", substr($buffer, 10-4, 2));
   #my $lastModTime        = unpack ("V", substr($buffer, 12-4, 4));
   #my $crc32              = unpack ("V", substr($buffer, 16-4, 4));
   #my $compressedLength   = unpack ("V", substr($buffer, 20-4, 4));
   #my $uncompressedLength = unpack ("V", substr($buffer, 24-4, 4));
    my $filename_length    = unpack ("v", substr($buffer, 28-4, 2)); 
    my $extra_length       = unpack ("v", substr($buffer, 30-4, 2));
    my $comment_length     = unpack ("v", substr($buffer, 32-4, 2));
   #my $disk_start         = unpack ("v", substr($buffer, 34-4, 2));
   #my $int_file_attrib    = unpack ("v", substr($buffer, 36-4, 2));
   #my $ext_file_attrib    = unpack ("V", substr($buffer, 38-4, 2));
   #my $lcl_hdr_offset     = unpack ("V", substr($buffer, 42-4, 2));

    
    my $filename;
    my $extraField;
    my $comment ;
    if ($filename_length)
    {
        $self->smartReadExact(\$filename, $filename_length)
            or return $self->HeaderError("xxx");
        $keep .= $filename ;
    }

    if ($extra_length)
    {
        $self->smartReadExact(\$extraField, $extra_length)
            or return $self->HeaderError("xxx");
        $keep .= $extraField ;
    }

    if ($comment_length)
    {
        $self->smartReadExact(\$comment, $comment_length)
            or return $self->HeaderError("xxx");
        $keep .= $comment ;
    }

    return 1 ;
}

sub skipEndCentralDirectory
{
    my $self = shift;
    my $magic = shift ;

    my $buffer;
    $self->smartReadExact(\$buffer, 22 - 4)
        or return $self->HeaderError("Minimum header size is " . 
                                     22 . " bytes") ;

    my $keep = $magic . $buffer ;
    *$self->{HeaderPending} = $keep ;

   #my $diskNumber         = unpack ("v", substr($buffer, 4-4,  2));
   #my $cntrlDirDiskNo     = unpack ("v", substr($buffer, 6-4,  2));
   #my $entriesInThisCD    = unpack ("v", substr($buffer, 8-4,  2));
   #my $entriesInCD        = unpack ("v", substr($buffer, 10-4, 2));
   #my $sizeOfCD           = unpack ("V", substr($buffer, 12-4, 2));
   #my $offsetToCD         = unpack ("V", substr($buffer, 16-4, 2));
    my $comment_length     = unpack ("v", substr($buffer, 20-4, 2));

    
    my $comment ;
    if ($comment_length)
    {
        $self->smartReadExact(\$comment, $comment_length)
            or return $self->HeaderError("xxx");
        $keep .= $comment ;
    }

    return 1 ;
}




sub _isZipMagic
{
    my $buffer = shift ;
    return 0 if length $buffer < 4 ;
    my $sig = unpack("V", $buffer) ;
    return $sig == 0x04034b50 ;
}


sub _readFullZipHeader($)
{
    my ($self) = @_ ;
    my $magic = '' ;

    $self->smartReadExact(\$magic, 4);

    *$self->{HeaderPending} = $magic ;

    return $self->HeaderError("Minimum header size is " . 
                              30 . " bytes") 
        if length $magic != 4 ;                                    


    return $self->HeaderError("Bad Magic")
        if ! _isZipMagic($magic) ;

    my $status = $self->_readZipHeader($magic);
    delete *$self->{Transparent} if ! defined $status ;
    return $status ;
}

sub _readZipHeader($)
{
    my ($self, $magic) = @_ ;
    my ($HeaderCRC) ;
    my ($buffer) = '' ;

    $self->smartReadExact(\$buffer, 30 - 4)
        or return $self->HeaderError("Minimum header size is " . 
                                     30 . " bytes") ;

    my $keep = $magic . $buffer ;
    *$self->{HeaderPending} = $keep ;

    my $extractVersion     = unpack ("v", substr($buffer, 4-4,  2));
    my $gpFlag             = unpack ("v", substr($buffer, 6-4,  2));
    my $compressedMethod   = unpack ("v", substr($buffer, 8-4,  2));
    my $lastModTime        = unpack ("V", substr($buffer, 10-4, 4));
    my $crc32              = unpack ("V", substr($buffer, 14-4, 4));
    my $compressedLength   = unpack ("V", substr($buffer, 18-4, 4));
    my $uncompressedLength = unpack ("V", substr($buffer, 22-4, 4));
    my $filename_length    = unpack ("v", substr($buffer, 26-4, 2)); 
    my $extra_length       = unpack ("v", substr($buffer, 28-4, 2));

    my $filename;
    my $extraField;
    my $streamingMode = ($gpFlag & 0x08) ? 1 : 0 ;

    return $self->HeaderError("Streamed Stored content not supported")
        if $streamingMode && $compressedMethod == 0 ;

    *$self->{ZipData}{Streaming} = $streamingMode;

    if (! $streamingMode) {
        *$self->{ZipData}{Streaming} = 0;
        *$self->{ZipData}{Crc32} = $crc32;
        *$self->{ZipData}{CompressedLen} = $compressedLength;
        *$self->{ZipData}{UnCompressedLen} = $uncompressedLength;
    }

    if ($filename_length)
    {
        $self->smartReadExact(\$filename, $filename_length)
            or return $self->HeaderError("xxx");
        $keep .= $filename ;
    }

    if ($extra_length)
    {
        $self->smartReadExact(\$extraField, $extra_length)
            or return $self->HeaderError("xxx");
        $keep .= $extraField ;
    }

    *$self->{CompressedInputLengthRemaining} =
        *$self->{CompressedInputLength} = $compressedLength;

    if ($compressedMethod == 8)
    {
        *$self->{Type} = 'zip';
    }
    elsif ($compressedMethod == 0)
    {
        # TODO -- add support for reading uncompressed

        *$self->{Type} = 'zipStored';
        
        my $obj = UncompressPlugin::Identity::mkUncompObject(# $got->value('CRC32'),
                                                             # $got->value('ADLER32'),
                                                              );

        *$self->{Uncomp} = $obj;

    }
    else
    {
        return $self->HeaderError("Unsupported Compression format $compressedMethod");
    }

    return {
        'Type'               => 'zip',
        'FingerprintLength'  => 2,
        #'HeaderLength'       => $compressedMethod == 8 ? length $keep : 0,
        'HeaderLength'       => length $keep,
        'TrailerLength'      => $streamingMode ? 16  : 0,
        'Header'             => $keep,
        'CompressedLength'   => $compressedLength ,
        'UncompressedLength' => $uncompressedLength ,
        'CRC32'              => $crc32 ,
        'Name'               => $filename,
        'Time'               => _dosToUnixTime($lastModTime),
        'Stream'             => $streamingMode,

        'MethodID'           => $compressedMethod,
        'MethodName'         => $compressedMethod == 8 
                                 ? "Deflated" 
                                 : $compressedMethod == 0
                                     ? "Stored"
                                     : "Unknown" ,

#        'TextFlag'      => $flag & GZIP_FLG_FTEXT ? 1 : 0,
#        'HeaderCRCFlag' => $flag & GZIP_FLG_FHCRC ? 1 : 0,
#        'NameFlag'      => $flag & GZIP_FLG_FNAME ? 1 : 0,
#        'CommentFlag'   => $flag & GZIP_FLG_FCOMMENT ? 1 : 0,
#        'ExtraFlag'     => $flag & GZIP_FLG_FEXTRA ? 1 : 0,
#        'Comment'       => $comment,
#        'OsID'          => $os,
#        'OsName'        => defined $GZIP_OS_Names{$os} 
#                                 ? $GZIP_OS_Names{$os} : "Unknown",
#        'HeaderCRC'     => $HeaderCRC,
#        'Flags'         => $flag,
#        'ExtraFlags'    => $xfl,
#        'ExtraFieldRaw' => $EXTRA,
#        'ExtraField'    => [ @EXTRA ],


      }
}

# from Archive::Zip
sub _dosToUnixTime
{
    #use Time::Local 'timelocal_nocheck';
    use Time::Local 'timelocal';

	my $dt = shift;

	my $year = ( ( $dt >> 25 ) & 0x7f ) + 80;
	my $mon  = ( ( $dt >> 21 ) & 0x0f ) - 1;
	my $mday = ( ( $dt >> 16 ) & 0x1f );

	my $hour = ( ( $dt >> 11 ) & 0x1f );
	my $min  = ( ( $dt >> 5 ) & 0x3f );
	my $sec  = ( ( $dt << 1 ) & 0x3e );

	# catch errors
	my $time_t =
	  eval { timelocal( $sec, $min, $hour, $mday, $mon, $year ); };
	return 0 
        if $@;
	return $time_t;
}


1;

__END__

