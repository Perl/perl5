
package IO::Uncompress::Gunzip ;

require 5.004 ;

# for RFC1952

use strict ;
use warnings;

require Exporter ;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS, $GunzipError);

@ISA    = qw(Exporter IO::BaseInflate);
@EXPORT_OK = qw( $GunzipError gunzip );
%EXPORT_TAGS = %IO::BaseInflate::EXPORT_TAGS ;
push @{ $EXPORT_TAGS{all} }, @EXPORT_OK ;
Exporter::export_ok_tags('all');


$GunzipError = '';

$VERSION = '2.000_05';

sub new
{
    my $pkg = shift ;
    return IO::BaseInflate::new($pkg, 'rfc1952', undef, \$GunzipError, 0, @_);
}

sub gunzip
{
    return IO::BaseInflate::_inf(__PACKAGE__, 'rfc1952', \$GunzipError, @_) ;
}

package IO::BaseInflate ;

use strict ;
use warnings;
use bytes;

our ($VERSION, @EXPORT_OK, %EXPORT_TAGS);

$VERSION = '2.000_03';

use Compress::Zlib 2 ;
use Compress::Zlib::Common ;
use Compress::Zlib::ParseParameters ;
use Compress::Gzip::Constants;
use Compress::Zlib::FileConstants;

use IO::File ;
use Symbol;
use Scalar::Util qw(readonly);
use List::Util qw(min);
use Carp ;

%EXPORT_TAGS = ( );
push @{ $EXPORT_TAGS{all} }, @EXPORT_OK ;
#Exporter::export_ok_tags('all') ;


use constant G_EOF => 0 ;
use constant G_ERR => -1 ;

sub smartRead
{
    my $self = $_[0];
    my $out = $_[1];
    my $size = $_[2];
    $$out = "" ;

    my $offset = 0 ;


    if ( length *$self->{Prime} ) {
        #$$out = substr(*$self->{Prime}, 0, $size, '') ;
        $$out = substr(*$self->{Prime}, 0, $size) ;
        substr(*$self->{Prime}, 0, $size) =  '' ;
        if (length $$out == $size) {
            #*$self->{InputLengthRemaining} -= length $$out;
            return length $$out ;
        }
        $offset = length $$out ;
    }

    my $get_size = $size - $offset ;

    if ( defined *$self->{InputLength} ) {
        #*$self->{InputLengthRemaining} += length *$self->{Prime} ;
        #*$self->{InputLengthRemaining} = *$self->{InputLength}
        #    if *$self->{InputLengthRemaining} > *$self->{InputLength};
        $get_size = min($get_size, *$self->{InputLengthRemaining});
    }

    if (defined *$self->{FH})
      { *$self->{FH}->read($$out, $get_size, $offset) }
    elsif (defined *$self->{InputEvent}) {
        my $got = 1 ;
        while (length $$out < $size) {
            last 
                if ($got = *$self->{InputEvent}->($$out, $get_size)) <= 0;
        }

        if (length $$out > $size ) {
            #*$self->{Prime} = substr($$out, $size, length($$out), '');
            *$self->{Prime} = substr($$out, $size, length($$out));
            substr($$out, $size, length($$out)) =  '';
        }

       *$self->{EventEof} = 1 if $got <= 0 ;
    }
    else {
       no warnings 'uninitialized';
       my $buf = *$self->{Buffer} ;
       $$buf = '' unless defined $$buf ;
       #$$out = '' unless defined $$out ;
       substr($$out, $offset) = substr($$buf, *$self->{BufferOffset}, $get_size);
       *$self->{BufferOffset} += length($$out) - $offset ;
    }

    *$self->{InputLengthRemaining} -= length $$out;
        
    $self->saveStatus(length $$out < 0 ? Z_DATA_ERROR : 0) ;

    return length $$out;
}

sub smartSeek
{
    my $self   = shift ;
    my $offset = shift ;
    my $truncate = shift;
    #print "smartSeek to $offset\n";

    if (defined *$self->{FH})
      { *$self->{FH}->seek($offset, SEEK_SET) }
    else {
        *$self->{BufferOffset} = $offset ;
        substr(${ *$self->{Buffer} }, *$self->{BufferOffset}) = ''
            if $truncate;
        return 1;
    }
}

sub smartWrite
{
    my $self   = shift ;
    my $out_data = shift ;

    if (defined *$self->{FH}) {
        # flush needed for 5.8.0 
        defined *$self->{FH}->write($out_data, length $out_data) &&
        defined *$self->{FH}->flush() ;
    }
    else {
       my $buf = *$self->{Buffer} ;
       substr($$buf, *$self->{BufferOffset}, length $out_data) = $out_data ;
       *$self->{BufferOffset} += length($out_data) ;
       return 1;
    }
}

sub smartReadExact
{
    return $_[0]->smartRead($_[1], $_[2]) == $_[2];
}

sub getTrailingBuffer
{
    my ($self) = $_[0];
    return "" if defined *$self->{FH} || defined *$self->{InputEvent} ; 

    my $buf = *$self->{Buffer} ;
    my $offset = *$self->{BufferOffset} ;
    return substr($$buf, $offset, -1) ;
}

sub smartEof
{
    my ($self) = $_[0];
    if (defined *$self->{FH})
     { *$self->{FH}->eof() }
    elsif (defined *$self->{InputEvent})
     { *$self->{EventEof} }
    else 
     { *$self->{BufferOffset} >= length(${ *$self->{Buffer} }) }
}

sub saveStatus
{
    my $self   = shift ;
    *$self->{ErrorNo}  = shift() + 0 ;
    ${ *$self->{Error} } = '' ;

    return *$self->{ErrorNo} ;
}


sub saveErrorString
{
    my $self   = shift ;
    my $retval = shift ;
    ${ *$self->{Error} } = shift ;
    *$self->{ErrorNo} = shift() + 0 if @_ ;

    #print "saveErrorString: " . ${ *$self->{Error} } . "\n" ;
    return $retval;
}

sub error
{
    my $self   = shift ;
    return ${ *$self->{Error} } ;
}

sub errorNo
{
    my $self   = shift ;
    return *$self->{ErrorNo};
}

sub HeaderError
{
    my ($self) = shift;
    return $self->saveErrorString(undef, "Header Error: $_[0]", Z_DATA_ERROR);
}

sub TrailerError
{
    my ($self) = shift;
    return $self->saveErrorString(G_ERR, "Trailer Error: $_[0]", Z_DATA_ERROR);
}

sub TruncatedHeader
{
    my ($self) = shift;
    return $self->HeaderError("Truncated in $_[0] Section");
}

sub isZipMagic
{
    my $buffer = shift ;
    return 0 if length $buffer < 4 ;
    my $sig = unpack("V", $buffer) ;
    return $sig == 0x04034b50 ;
}

sub isGzipMagic
{
    my $buffer = shift ;
    return 0 if length $buffer < GZIP_ID_SIZE ;
    my ($id1, $id2) = unpack("C C", $buffer) ;
    return $id1 == GZIP_ID1 && $id2 == GZIP_ID2 ;
}

sub isZlibMagic
{
    my $buffer = shift ;
    return 0 if length $buffer < ZLIB_HEADER_SIZE ;
    my $hdr = unpack("n", $buffer) ;
    return $hdr % 31 == 0 ;
}

sub _isRaw
{
    my $self   = shift ;
    my $magic = shift ;

    $magic = '' unless defined $magic ;

    my $buffer = '';

    $self->smartRead(\$buffer, *$self->{BlockSize}) >= 0  
        or return $self->saveErrorString(undef, "No data to read");

    my $temp_buf = $magic . $buffer ;
    *$self->{HeaderPending} = $temp_buf ;    
    $buffer = '';
    my $status = *$self->{Inflate}->inflate($temp_buf, $buffer) ;
    my $buf_len = *$self->{Inflate}->inflateCount();

    # zlib before 1.2 needs an extra byte after the compressed data
    # for RawDeflate
    if ($status == Z_OK && $self->smartEof()) {
        my $byte = ' ';
        $status = *$self->{Inflate}->inflate(\$byte, $buffer) ;
        return $self->saveErrorString(undef, "Inflation Error: $status", $status)
            unless $self->saveStatus($status) == Z_OK || $status == Z_STREAM_END ;
        $buf_len += *$self->{Inflate}->inflateCount();
    }

    return $self->saveErrorString(undef, "unexpected end of file", Z_DATA_ERROR)
        if $self->saveStatus($status) != Z_STREAM_END && $self->smartEof() ;

    return $self->saveErrorString(undef, "Inflation Error: $status", $status)
        unless $status == Z_OK || $status == Z_STREAM_END ;

    if ($status == Z_STREAM_END) {
        if (*$self->{MultiStream} 
                    && (length $temp_buf || ! $self->smartEof())){
            *$self->{NewStream} = 1 ;
            *$self->{EndStream} = 0 ;
            *$self->{Prime} = $temp_buf  . *$self->{Prime} ;
        }
        else {
            *$self->{EndStream} = 1 ;
            *$self->{Trailing} = $temp_buf . $self->getTrailingBuffer();
        }
    }
    *$self->{HeaderPending} = $buffer ;    
    *$self->{InflatedBytesRead} = $buf_len ;    
    *$self->{TotalInflatedBytesRead} += $buf_len ;    
    *$self->{Type} = 'rfc1951';

    $self->saveStatus(Z_OK);

    return {
        'Type'          => 'rfc1951',
        'HeaderLength'  => 0,
        'TrailerLength' => 0,
        'Header'        => ''
        };
}

sub _guessCompression
{
    my $self = shift ;

    # Check raw first in case the first few bytes happen to match
    # the signatures of gzip/deflate.
    my $got = $self->_isRaw() ;
    return $got if defined $got ;

    *$self->{Prime} = *$self->{HeaderPending} . *$self->{Prime} ;
    *$self->{HeaderPending} = '';
    *$self->{Inflate}->inflateReset();

    my $magic = '' ;
    my $status ;
    $self->smartReadExact(\$magic, GZIP_ID_SIZE)
        or return $self->HeaderError("Minimum header size is " . 
                                     GZIP_ID_SIZE . " bytes") ;

    if (isGzipMagic($magic)) {
        $status = $self->_readGzipHeader($magic);
        delete *$self->{Transparent} if ! defined $status ;
        return $status ;
    }
    elsif ( $status = $self->_readDeflateHeader($magic) ) {
        return $status ;
    }

    *$self->{Prime} = $magic . *$self->{HeaderPending} . *$self->{Prime} ;
    *$self->{HeaderPending} = '';
    $self->saveErrorString(undef, "unknown compression format", Z_DATA_ERROR);
}

sub _readFullGzipHeader($)
{
    my ($self) = @_ ;
    my $magic = '' ;

    $self->smartReadExact(\$magic, GZIP_ID_SIZE);

    *$self->{HeaderPending} = $magic ;

    return $self->HeaderError("Minimum header size is " . 
                              GZIP_MIN_HEADER_SIZE . " bytes") 
        if length $magic != GZIP_ID_SIZE ;                                    


    return $self->HeaderError("Bad Magic")
        if ! isGzipMagic($magic) ;

    my $status = $self->_readGzipHeader($magic);
    delete *$self->{Transparent} if ! defined $status ;
    return $status ;
}

sub _readGzipHeader($)
{
    my ($self, $magic) = @_ ;
    my ($HeaderCRC) ;
    my ($buffer) = '' ;

    $self->smartReadExact(\$buffer, GZIP_MIN_HEADER_SIZE - GZIP_ID_SIZE)
        or return $self->HeaderError("Minimum header size is " . 
                                     GZIP_MIN_HEADER_SIZE . " bytes") ;

    my $keep = $magic . $buffer ;
    *$self->{HeaderPending} = $keep ;

    # now split out the various parts
    my ($cm, $flag, $mtime, $xfl, $os) = unpack("C C V C C", $buffer) ;

    $cm == GZIP_CM_DEFLATED 
        or return $self->HeaderError("Not Deflate (CM is $cm)") ;

    # check for use of reserved bits
    return $self->HeaderError("Use of Reserved Bits in FLG field.")
        if $flag & GZIP_FLG_RESERVED ; 

    my $EXTRA ;
    my @EXTRA = () ;
    if ($flag & GZIP_FLG_FEXTRA) {
        $EXTRA = "" ;
        $self->smartReadExact(\$buffer, GZIP_FEXTRA_HEADER_SIZE) 
            or return $self->TruncatedHeader("FEXTRA Length") ;

        my ($XLEN) = unpack("v", $buffer) ;
        $self->smartReadExact(\$EXTRA, $XLEN) 
            or return $self->TruncatedHeader("FEXTRA Body");
        $keep .= $buffer . $EXTRA ;

        if ($XLEN && *$self->{'ParseExtra'}) {
            my $offset = 0 ;
            while ($offset < $XLEN) {

                return $self->TruncatedHeader("FEXTRA Body")
                    if $offset + GZIP_FEXTRA_SUBFIELD_HEADER_SIZE > $XLEN ;

                my $id = substr($EXTRA, $offset, GZIP_FEXTRA_SUBFIELD_ID_SIZE);
                $offset += GZIP_FEXTRA_SUBFIELD_ID_SIZE ;

                return $self->HeaderError("SubField ID 2nd byte is 0x00")
                    if *$self->{Strict} && substr($id, 1, 1) eq "\x00" ;

                my ($subLen) = unpack("v", substr($EXTRA, $offset, 
                                        GZIP_FEXTRA_SUBFIELD_LEN_SIZE)) ;
                $offset += GZIP_FEXTRA_SUBFIELD_LEN_SIZE ;

                return $self->TruncatedHeader("FEXTRA Body")
                    if $offset + $subLen > $XLEN ;

                push @EXTRA, [$id => substr($EXTRA, $offset, $subLen)];
                $offset += $subLen ;
            }
        }
    }

    my $origname ;
    if ($flag & GZIP_FLG_FNAME) {
        $origname = "" ;
        while (1) {
            $self->smartReadExact(\$buffer, 1) 
                or return $self->TruncatedHeader("FNAME");
            last if $buffer eq GZIP_NULL_BYTE ;
            $origname .= $buffer 
        }
        $keep .= $origname . GZIP_NULL_BYTE ;

        return $self->HeaderError("Non ISO 8859-1 Character found in Name")
            if *$self->{Strict} && $origname =~ /$GZIP_FNAME_INVALID_CHAR_RE/o ;
    }

    my $comment ;
    if ($flag & GZIP_FLG_FCOMMENT) {
        $comment = "";
        while (1) {
            $self->smartReadExact(\$buffer, 1) 
                or return $self->TruncatedHeader("FCOMMENT");
            last if $buffer eq GZIP_NULL_BYTE ;
            $comment .= $buffer 
        }
        $keep .= $comment . GZIP_NULL_BYTE ;

        return $self->HeaderError("Non ISO 8859-1 Character found in Comment")
            if *$self->{Strict} && $comment =~ /$GZIP_FCOMMENT_INVALID_CHAR_RE/o ;
    }

    if ($flag & GZIP_FLG_FHCRC) {
        $self->smartReadExact(\$buffer, GZIP_FHCRC_SIZE) 
            or return $self->TruncatedHeader("FHCRC");

        $HeaderCRC = unpack("v", $buffer) ;
        my $crc16 = crc32($keep) & 0xFF ;

        return $self->HeaderError("CRC16 mismatch.")
            if *$self->{Strict} && $crc16 != $HeaderCRC;

        $keep .= $buffer ;
    }

    # Assume compression method is deflated for xfl tests
    #if ($xfl) {
    #}

    *$self->{Type} = 'rfc1952';

    return {
        'Type'          => 'rfc1952',
        'HeaderLength'  => length $keep,
        'TrailerLength' => GZIP_TRAILER_SIZE,
        'Header'        => $keep,
        'isMinimalHeader' => $keep eq GZIP_MINIMUM_HEADER ? 1 : 0,

        'MethodID'      => $cm,
        'MethodName'    => $cm == GZIP_CM_DEFLATED ? "Deflated" : "Unknown" ,
        'TextFlag'      => $flag & GZIP_FLG_FTEXT ? 1 : 0,
        'HeaderCRCFlag' => $flag & GZIP_FLG_FHCRC ? 1 : 0,
        'NameFlag'      => $flag & GZIP_FLG_FNAME ? 1 : 0,
        'CommentFlag'   => $flag & GZIP_FLG_FCOMMENT ? 1 : 0,
        'ExtraFlag'     => $flag & GZIP_FLG_FEXTRA ? 1 : 0,
        'Name'          => $origname,
        'Comment'       => $comment,
        'Time'          => $mtime,
        'OsID'          => $os,
        'OsName'        => defined $GZIP_OS_Names{$os} 
                                 ? $GZIP_OS_Names{$os} : "Unknown",
        'HeaderCRC'     => $HeaderCRC,
        'Flags'         => $flag,
        'ExtraFlags'    => $xfl,
        'ExtraFieldRaw' => $EXTRA,
        'ExtraField'    => [ @EXTRA ],


        #'CompSize'=> $compsize,
        #'CRC32'=> $CRC32,
        #'OrigSize'=> $ISIZE,
      }
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
        if ! isZipMagic($magic) ;

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

    my $extractVersion     = unpack ("v", substr($buffer, 4-4, 2));
    my $gpFlag             = unpack ("v", substr($buffer, 6-4, 2));
    my $compressedMethod   = unpack ("v", substr($buffer, 8-4, 2));
    my $lastModTime        = unpack ("v", substr($buffer, 10-4, 2));
    my $lastModDate        = unpack ("v", substr($buffer, 12-4, 2));
    my $crc32              = unpack ("v", substr($buffer, 14-4, 4));
    my $compressedLength   = unpack ("V", substr($buffer, 18-4, 4));
    my $uncompressedLength = unpack ("V", substr($buffer, 22-4, 4));
    my $filename_length    = unpack ("v", substr($buffer, 26-4, 2)); 
    my $extra_length       = unpack ("v", substr($buffer, 28-4, 2));

    my $filename;
    my $extraField;

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

    *$self->{Type} = 'zip';

    return {
        'Type'          => 'zip',
        'HeaderLength'  => length $keep,
        'TrailerLength' => $gpFlag & 0x08 ? 16  : 0,
        'Header'        => $keep,

#        'MethodID'      => $cm,
#        'MethodName'    => $cm == GZIP_CM_DEFLATED ? "Deflated" : "Unknown" ,
#        'TextFlag'      => $flag & GZIP_FLG_FTEXT ? 1 : 0,
#        'HeaderCRCFlag' => $flag & GZIP_FLG_FHCRC ? 1 : 0,
#        'NameFlag'      => $flag & GZIP_FLG_FNAME ? 1 : 0,
#        'CommentFlag'   => $flag & GZIP_FLG_FCOMMENT ? 1 : 0,
#        'ExtraFlag'     => $flag & GZIP_FLG_FEXTRA ? 1 : 0,
#        'Name'          => $origname,
#        'Comment'       => $comment,
#        'Time'          => $mtime,
#        'OsID'          => $os,
#        'OsName'        => defined $GZIP_OS_Names{$os} 
#                                 ? $GZIP_OS_Names{$os} : "Unknown",
#        'HeaderCRC'     => $HeaderCRC,
#        'Flags'         => $flag,
#        'ExtraFlags'    => $xfl,
#        'ExtraFieldRaw' => $EXTRA,
#        'ExtraField'    => [ @EXTRA ],


        #'CompSize'=> $compsize,
        #'CRC32'=> $CRC32,
        #'OrigSize'=> $ISIZE,
      }
}

sub bits
{
    my $data   = shift ;
    my $offset = shift ;
    my $mask  = shift ;

    ($data >> $offset ) & $mask & 0xFF ;
}


sub _readDeflateHeader
{
    my ($self, $buffer) = @_ ;

    if (! $buffer) {
        $self->smartReadExact(\$buffer, ZLIB_HEADER_SIZE);

        *$self->{HeaderPending} = $buffer ;

        return $self->HeaderError("Header size is " . 
                                            ZLIB_HEADER_SIZE . " bytes") 
            if length $buffer != ZLIB_HEADER_SIZE;

        return $self->HeaderError("CRC mismatch.")
            if ! isZlibMagic($buffer) ;
    }
                                        
    my ($CMF, $FLG) = unpack "C C", $buffer;
    my $FDICT = bits($FLG, ZLIB_FLG_FDICT_OFFSET,  ZLIB_FLG_FDICT_BITS ),

    my $cm = bits($CMF, ZLIB_CMF_CM_OFFSET, ZLIB_CMF_CM_BITS) ;
    $cm == ZLIB_CMF_CM_DEFLATED 
        or return $self->HeaderError("Not Deflate (CM is $cm)") ;

    my $DICTID;
    if ($FDICT) {
        $self->smartReadExact(\$buffer, ZLIB_FDICT_SIZE)
            or return $self->TruncatedHeader("FDICT");

        $DICTID = unpack("N", $buffer) ;
    }

    *$self->{Type} = 'rfc1950';

    return {
        'Type'          => 'rfc1950',
        'HeaderLength'  => ZLIB_HEADER_SIZE,
        'TrailerLength' => ZLIB_TRAILER_SIZE,
        'Header'        => $buffer,

        CMF     =>      $CMF                                               ,
        CM      => bits($CMF, ZLIB_CMF_CM_OFFSET,     ZLIB_CMF_CM_BITS    ),
        CINFO   => bits($CMF, ZLIB_CMF_CINFO_OFFSET,  ZLIB_CMF_CINFO_BITS ),
        FLG     =>      $FLG                                               ,
        FCHECK  => bits($FLG, ZLIB_FLG_FCHECK_OFFSET, ZLIB_FLG_FCHECK_BITS),
        FDICT   => bits($FLG, ZLIB_FLG_FDICT_OFFSET,  ZLIB_FLG_FDICT_BITS ),
        FLEVEL  => bits($FLG, ZLIB_FLG_LEVEL_OFFSET,  ZLIB_FLG_LEVEL_BITS ),
        DICTID  =>      $DICTID                                            ,

};
}


sub checkParams
{
    my $class = shift ;
    my $type = shift ;

    
    my $Valid = {
                    #'Input'        => [Parse_store_ref, undef],
        
                    'BlockSize'     => [Parse_unsigned, 16 * 1024],
                    'AutoClose'     => [Parse_boolean,  0],
                    'Strict'        => [Parse_boolean,  0],
                    #'Lax'           => [Parse_boolean,  1],
                    'Append'        => [Parse_boolean,  0],
                    'Prime'         => [Parse_any,      undef],
                    'MultiStream'   => [Parse_boolean,  0],
                    'Transparent'   => [Parse_any,      1],
                    'Scan'          => [Parse_boolean,  0],
                    'InputLength'   => [Parse_unsigned, undef],

                    #'Todo - Revert to ordinary file on end Z_STREAM_END'=> 0,
                    # ContinueAfterEof
                } ;

    $Valid->{'ParseExtra'} = [Parse_boolean,  0]
        if $type eq 'rfc1952' ;

    my $got = Compress::Zlib::ParseParameters::new();
        
    $got->parse($Valid, @_ ) 
        or croak "$class: $got->{Error}" ;

    return $got;
}

sub new
{
    my $class = shift ;
    my $type = shift ;
    my $got = shift;
    my $error_ref = shift ;
    my $append_mode = shift ;

    croak("$class: Missing Input parameter")
        if ! @_ && ! $got ;

    my $inValue = shift ;

    if (! $got)
    {
        $got = checkParams($class, $type, @_)
            or return undef ;
    }

    my $inType  = whatIsInput($inValue, 1);

    ckInputParam($class, $inValue, $error_ref, 1) 
        or return undef ;

    my $obj = bless Symbol::gensym(), ref($class) || $class;
    tie *$obj, $obj if $] >= 5.005;


    $$error_ref = '' ;
    *$obj->{Error} = $error_ref ;
    *$obj->{InNew} = 1;

    if ($inType eq 'buffer' || $inType eq 'code') {
        *$obj->{Buffer} = $inValue ;        
        *$obj->{InputEvent} = $inValue 
           if $inType eq 'code' ;
    }
    else {
        if ($inType eq 'handle') {
            *$obj->{FH} = $inValue ;
            *$obj->{Handle} = 1 ;
            # Need to rewind for Scan
            #seek(*$obj->{FH}, 0, SEEK_SET) if $got->value('Scan');
            *$obj->{FH}->seek(0, SEEK_SET) if $got->value('Scan');
        }  
        else {    
            my $mode = '<';
            $mode = '+<' if $got->value('Scan');
            *$obj->{StdIO} = ($inValue eq '-');
            *$obj->{FH} = new IO::File "$mode $inValue"
                or return $obj->saveErrorString(undef, "cannot open file '$inValue': $!", $!) ;
            *$obj->{LineNo} = 0;
        }
        # Setting STDIN to binmode causes grief
        setBinModeInput(*$obj->{FH}) ;

        my $buff = "" ;
        *$obj->{Buffer} = \$buff ;
    }


    *$obj->{InputLength}       = $got->parsed('InputLength') 
                                    ? $got->value('InputLength')
                                    : undef ;
    *$obj->{InputLengthRemaining} = $got->value('InputLength');
    *$obj->{BufferOffset}      = 0 ;
    *$obj->{AutoClose}         = $got->value('AutoClose');
    *$obj->{Strict}            = $got->value('Strict');
    #*$obj->{Strict}            = ! $got->value('Lax');
    *$obj->{BlockSize}         = $got->value('BlockSize');
    *$obj->{Append}            = $got->value('Append');
    *$obj->{AppendOutput}      = $append_mode || $got->value('Append');
    *$obj->{Transparent}       = $got->value('Transparent');
    *$obj->{MultiStream}       = $got->value('MultiStream');
    *$obj->{Scan}              = $got->value('Scan');
    *$obj->{ParseExtra}        = $got->value('ParseExtra') 
                                  || $got->value('Strict')  ;
                                  #|| ! $got->value('Lax')  ;
    *$obj->{Type}              = $type;
    *$obj->{Prime}             = $got->value('Prime') || '' ;
    *$obj->{Pending}           = '';
    *$obj->{Plain}             = 0;
    *$obj->{PlainBytesRead}    = 0;
    *$obj->{InflatedBytesRead} = 0;
    *$obj->{ISize}             = 0;
    *$obj->{TotalInflatedBytesRead} = 0;
    *$obj->{NewStream}         = 0 ;
    *$obj->{EventEof}          = 0 ;
    *$obj->{ClassName}         = $class ;

    my $status;

    if (*$obj->{Scan})
    {
        (*$obj->{Inflate}, $status) = new Compress::Zlib::InflateScan
                            -CRC32        => $type eq 'rfc1952' ||
                                             $type eq 'any',
                            -ADLER32      => $type eq 'rfc1950' ||
                                             $type eq 'any',
                            -WindowBits   => - MAX_WBITS ;
    }
    else
    {
        (*$obj->{Inflate}, $status) = new Compress::Zlib::Inflate
                            -AppendOutput => 1,
                            -CRC32        => $type eq 'rfc1952' ||
                                             $type eq 'any',
                            -ADLER32      => $type eq 'rfc1950' ||
                                             $type eq 'any',
                            -WindowBits   => - MAX_WBITS ;
    }

    return $obj->saveErrorString(undef, "Could not create Inflation object: $status") 
        if $obj->saveStatus($status) != Z_OK ;

    if ($type eq 'rfc1952')
    {
        *$obj->{Info} = $obj->_readFullGzipHeader() ;
    }
    elsif ($type eq 'zip')
    {
        *$obj->{Info} = $obj->_readFullZipHeader() ;
    }
    elsif ($type eq 'rfc1950')
    {
        *$obj->{Info} = $obj->_readDeflateHeader() ;
    }
    elsif ($type eq 'rfc1951')
    {
        *$obj->{Info} = $obj->_isRaw() ;
    }
    elsif ($type eq 'any')
    {
        *$obj->{Info} = $obj->_guessCompression() ;
    }

    if (! defined *$obj->{Info})
    {
        return undef unless *$obj->{Transparent};

        *$obj->{Type} = 'plain';
        *$obj->{Plain} = 1;
        *$obj->{PlainBytesRead} = length *$obj->{HeaderPending}  ;
    }

    push @{ *$obj->{InfoList} }, *$obj->{Info} ;
    *$obj->{Pending} = *$obj->{HeaderPending} 
        if *$obj->{Plain} || *$obj->{Type}  eq 'rfc1951';

    $obj->saveStatus(0) ;
    *$obj->{InNew} = 0;

    return $obj;
}

#sub _inf
#{
#    my $class = shift ;
#    my $type = shift ;
#    my $error_ref = shift ;
#
#    my $name = (caller(1))[3] ;
#
#    croak "$name: expected at least 2 parameters\n"
#        unless @_ >= 2 ;
#
#    my $input = shift ;
#    my $output = shift ;
#
#    ckInOutParams($name, $input, $output, $error_ref) 
#        or return undef ;
#
#    my $outType = whatIs($output);
#
#    my $gunzip = new($class, $type, $error_ref, 1, $input, @_)
#        or return undef ;
#
#    my $fh ;
#    if ($outType eq 'filename') {
#        my $mode = '>' ;
#        $mode = '>>'
#            if *$gunzip->{Append} ;
#        $fh = new IO::File "$mode $output" 
#            or return $gunzip->saveErrorString(undef, "cannot open file '$output': $!", $!) ;
#    }
#
#    if ($outType eq 'handle') {
#        $fh = $output;
#        if (*$gunzip->{Append}) {
#            seek($fh, 0, SEEK_END)
#                or return $gunzip->saveErrorString(undef, "Cannot seek to end of output filehandle: $!", $!) ;
#        }
#    }
#
#    my $buff = '' ;
#    $buff = $output if $outType eq 'buffer' ;
#    my $status ;
#    while (($status = $gunzip->read($buff)) > 0) {
#        if ($fh) {
#            print $fh $buff 
#                or return $gunzip->saveErrorString(undef, "Error writing to output file: $!", $!);
#        }
#    }
#
#    return undef
#        if $status < 0 ;
#
#    $gunzip->close() 
#        or return undef ;
#
#    if (  $outType eq 'filename' || 
#         ($outType eq 'handle' && *$gunzip->{AutoClose})) {
#        $fh->close() 
#            or return $gunzip->saveErrorString(undef, $!, $!); 
#    }
#
#    return 1 ;
#}

sub _inf
{
    my $class = shift ;
    my $type = shift ;
    my $error_ref = shift ;

    my $name = (caller(1))[3] ;

    croak "$name: expected at least 1 parameters\n"
        unless @_ >= 1 ;

    my $input = shift ;
    my $haveOut = @_ ;
    my $output = shift ;

    my $x = new Validator($class, $type, $error_ref, $name, $input, $output)
        or return undef ;
    
    push @_, $output if $haveOut && $x->{Hash};
    
    my $got = checkParams($name, $type, @_)
        or return undef ;

    $x->{Got} = $got ;

    if ($x->{Hash})
    {
        while (my($k, $v) = each %$input)
        {
            $v = \$input->{$k} 
                unless defined $v ;

            _singleTarget($x, 1, $k, $v, @_)
                or return undef ;
        }

        return keys %$input ;
    }
    
    if ($x->{GlobMap})
    {
        $x->{oneInput} = 1 ;
        foreach my $pair (@{ $x->{Pairs} })
        {
            my ($from, $to) = @$pair ;
            _singleTarget($x, 1, $from, $to, @_)
                or return undef ;
        }

        return scalar @{ $x->{Pairs} } ;
    }

    #if ($x->{outType} eq 'array' || $x->{outType} eq 'hash')
    if (! $x->{oneOutput} )
    {
        my $inFile = ($x->{inType} eq 'filenames' 
                        || $x->{inType} eq 'filename');

        $x->{inType} = $inFile ? 'filename' : 'buffer';
        my $ot = $x->{outType} ;
        $x->{outType} = 'buffer';
        
        foreach my $in ($x->{oneInput} ? $input : @$input)
        {
            my $out ;
            $x->{oneInput} = 1 ;

            _singleTarget($x, $inFile, $in, \$out, @_)
                or return undef ;

            if ($ot eq 'array')
              { push @$output, \$out }
            else
              { $output->{$in} = \$out }
        }

        return 1 ;
    }

    # finally the 1 to 1 and n to 1
    return _singleTarget($x, 1, $input, $output, @_);

    croak "should not be here" ;
}

sub retErr
{
    my $x = shift ;
    my $string = shift ;

    ${ $x->{Error} } = $string ;

    return undef ;
}

sub _singleTarget
{
    my $x         = shift ;
    my $inputIsFilename = shift;
    my $input     = shift;
    my $output    = shift;
    
    $x->{buff} = '' ;

    my $fh ;
    if ($x->{outType} eq 'filename') {
        my $mode = '>' ;
        $mode = '>>'
            if $x->{Got}->value('Append') ;
        $x->{fh} = new IO::File "$mode $output" 
            or return retErr($x, "cannot open file '$output': $!") ;
        setBinModeOutput($x->{fh});

    }

    elsif ($x->{outType} eq 'handle') {
        $x->{fh} = $output;
        setBinModeOutput($x->{fh});
        if ($x->{Got}->value('Append')) {
                seek($x->{fh}, 0, SEEK_END)
                    or return retErr($x, "Cannot seek to end of output filehandle: $!") ;
            }
    }

    
    elsif ($x->{outType} eq 'buffer' )
    {
        $$output = '' 
            unless $x->{Got}->value('Append');
        $x->{buff} = $output ;
    }

    if ($x->{oneInput})
    {
        defined _rd2($x, $input, $inputIsFilename)
            or return undef; 
    }
    else
    {
        my $inputIsFilename = ($x->{inType} ne 'array');

        for my $element ( ($x->{inType} eq 'hash') ? keys %$input : @$input)
        {
            defined _rd2($x, $element, $inputIsFilename) 
                or return undef ;
        }
    }


    if ( ($x->{outType} eq 'filename' && $output ne '-') || 
         ($x->{outType} eq 'handle' && $x->{Got}->value('AutoClose'))) {
        $x->{fh}->close() 
            or return retErr($x, $!); 
            #or return $gunzip->saveErrorString(undef, $!, $!); 
        delete $x->{fh};
    }

    return 1 ;
}

sub _rd2
{
    my $x         = shift ;
    my $input     = shift;
    my $inputIsFilename = shift;
        
    my $gunzip = new($x->{Class}, $x->{Type}, $x->{Got}, $x->{Error}, 1, $input, @_)
        or return undef ;

    my $status ;
    my $fh = $x->{fh};
    
    while (($status = $gunzip->read($x->{buff})) > 0) {
        if ($fh) {
            print $fh $x->{buff} 
                or return $gunzip->saveErrorString(undef, "Error writing to output file: $!", $!);
            $x->{buff} = '' ;
        }
    }

    return undef
        if $status < 0 ;

    $gunzip->close() 
        or return undef ;

    return 1 ;
}

sub TIEHANDLE
{
    return $_[0] if ref($_[0]);
    die "OOPS\n" ;

}
  
sub UNTIE
{
    my $self = shift ;
}


sub getHeaderInfo
{
    my $self = shift ;
    return *$self->{Info};
}

sub _raw_read
{
    # return codes
    # >0 - ok, number of bytes read
    # =0 - ok, eof
    # <0 - not ok
    
    my $self = shift ;

    return G_EOF if *$self->{Closed} ;
    #return G_EOF if !length *$self->{Pending} && *$self->{EndStream} ;
    return G_EOF if *$self->{EndStream} ;

    my $buffer = shift ;
    my $scan_mode = shift ;

    if (*$self->{Plain}) {
        my $tmp_buff ;
        my $len = $self->smartRead(\$tmp_buff, *$self->{BlockSize}) ;
        
        return $self->saveErrorString(G_ERR, "Error reading data: $!", $!) 
                if $len < 0 ;

        if ($len == 0 ) {
            *$self->{EndStream} = 1 ;
        }
        else {
            *$self->{PlainBytesRead} += $len ;
            $$buffer .= $tmp_buff;
        }

        return $len ;
    }

    if (*$self->{NewStream}) {
        *$self->{NewStream} = 0 ;
        *$self->{EndStream} = 0 ;
        *$self->{Inflate}->inflateReset();

        if (*$self->{Type} eq 'rfc1952')
        {
            *$self->{Info} = $self->_readFullGzipHeader() ;
        }
        elsif (*$self->{Type} eq 'zip')
        {
            *$self->{Info} = $self->_readFullZipHeader() ;
        }
        elsif (*$self->{Type} eq 'rfc1950')
        {
            *$self->{Info} = $self->_readDeflateHeader() ;
        }
        elsif (*$self->{Type} eq 'rfc1951')
        {
            *$self->{Info} = $self->_isRaw() ;
            *$self->{Pending} = *$self->{HeaderPending} 
                if defined *$self->{Info} ;
        }

        return G_ERR unless defined *$self->{Info} ;

        push @{ *$self->{InfoList} }, *$self->{Info} ;

        if (*$self->{Type} eq 'rfc1951') {
            $$buffer .=  *$self->{Pending} ;
            my $len = length  *$self->{Pending} ;
            *$self->{Pending} = '';
            return $len; 
        }
    }

    my $temp_buf ;
    my $status = $self->smartRead(\$temp_buf, *$self->{BlockSize}) ;
    return $self->saveErrorString(G_ERR, "Error Reading Data")
        if $status < 0  ;

    if ($status == 0 ) {
        *$self->{Closed} = 1 ;
        *$self->{EndStream} = 1 ;
        return $self->saveErrorString(G_ERR, "unexpected end of file", Z_DATA_ERROR);
    }

    my $before_len = defined $$buffer ? length $$buffer : 0 ;
    $status = *$self->{Inflate}->inflate(\$temp_buf, $buffer) ;

    return $self->saveErrorString(G_ERR, "Inflation Error: $status")
        unless $self->saveStatus($status) == Z_OK || $status == Z_STREAM_END ;

    my $buf_len = *$self->{Inflate}->inflateCount();

    # zlib before 1.2 needs an extra byte after the compressed data
    # for RawDeflate
    if ($status == Z_OK && *$self->{Type} eq 'rfc1951' && $self->smartEof()) {
        my $byte = ' ';
        $status = *$self->{Inflate}->inflate(\$byte, $buffer) ;

        $buf_len += *$self->{Inflate}->inflateCount();

        return $self->saveErrorString(G_ERR, "Inflation Error: $status")
            unless $self->saveStatus($status) == Z_OK || $status == Z_STREAM_END ;
    }


    return $self->saveErrorString(G_ERR, "unexpected end of file", Z_DATA_ERROR)
        if $status != Z_STREAM_END && $self->smartEof() ;
    
    *$self->{InflatedBytesRead} += $buf_len ;
    *$self->{TotalInflatedBytesRead} += $buf_len ;
    my $rest = GZIP_ISIZE_MAX - *$self->{ISize} ;
    if ($buf_len > $rest) {
        *$self->{ISize} = $buf_len - $rest - 1;
    }
    else {
        *$self->{ISize} += $buf_len ;
    }

    if ($status == Z_STREAM_END) {

        *$self->{EndStream} = 1 ;

        if (*$self->{Type} eq 'rfc1951' || ! *$self->{Info}{TrailerLength})
        {
            *$self->{Trailing} = $temp_buf . $self->getTrailingBuffer();
        }
        else
        {
            # Only rfc1950 & 1952 have a trailer

            my $trailer_size = *$self->{Info}{TrailerLength} ;

            #if ($scan_mode) {
            #    my $offset = *$self->{Inflate}->getLastBufferOffset();
            #    substr($temp_buf, 0, $offset) = '' ;
            #}

            if (length $temp_buf < $trailer_size) {
                my $buff;
                my $want = $trailer_size - length $temp_buf;
                my $got = $self->smartRead(\$buff, $want) ;
                if ($got != $want && *$self->{Strict} ) {
                    my $len = length($temp_buf) + length($buff);
                    return $self->TrailerError("trailer truncated. Expected " . 
                      "$trailer_size bytes, got $len");
                }
                $temp_buf .= $buff;
            }
    
            if (length $temp_buf >= $trailer_size) {

                #my $trailer = substr($temp_buf, 0, $trailer_size, '') ;
                my $trailer = substr($temp_buf, 0, $trailer_size) ;
                substr($temp_buf, 0, $trailer_size) = '' ;

                if (*$self->{Type} eq 'rfc1952') {
                    # Check CRC & ISIZE 
                    my ($CRC32, $ISIZE) = unpack("V V", $trailer) ;
                    *$self->{Info}{CRC32} = $CRC32;    
                    *$self->{Info}{ISIZE} = $ISIZE;    

                    if (*$self->{Strict}) {
                        return $self->TrailerError("CRC mismatch")
                            if $CRC32 != *$self->{Inflate}->crc32() ;

                        my $exp_isize = *$self->{ISize}; 
                        return $self->TrailerError("ISIZE mismatch. Got $ISIZE"
                                                  . ", expected $exp_isize")
                            if $ISIZE != $exp_isize ;
                    }
                }
                elsif (*$self->{Type} eq 'zip') {
                    # Check CRC & ISIZE 
                    my ($sig, $CRC32, $cSize, $uSize) = unpack("V V V V", $trailer) ;
                    return $self->TrailerError("Data Descriptor signature")
                        if $sig != 0x08074b50;

                    if (*$self->{Strict}) {
                        return $self->TrailerError("CRC mismatch")
                            if $CRC32 != *$self->{Inflate}->crc32() ;

                    }
                }
                elsif (*$self->{Type} eq 'rfc1950') {
                    my $ADLER32 = unpack("N", $trailer) ;
                    *$self->{Info}{ADLER32} = $ADLER32;    
                    return $self->TrailerError("CRC mismatch")
                        if *$self->{Strict} && $ADLER32 != *$self->{Inflate}->adler32() ;

                }

                if (*$self->{MultiStream} 
                        && (length $temp_buf || ! $self->smartEof())){
                    *$self->{NewStream} = 1 ;
                    *$self->{EndStream} = 0 ;
                    *$self->{Prime} = $temp_buf  . *$self->{Prime} ;
                    return $buf_len ;
                }
            }

            *$self->{Trailing} = $temp_buf .$self->getTrailingBuffer();
        }
    }
    

    # return the number of uncompressed bytes read
    return $buf_len ;
}

#sub isEndStream
#{
#    my $self = shift ;
#    return *$self->{NewStream} ||
#           *$self->{EndStream} ;
#}

sub streamCount
{
    my $self = shift ;
    return 1 if ! defined *$self->{InfoList};
    return scalar @{ *$self->{InfoList} }  ;
}

sub read
{
    # return codes
    # >0 - ok, number of bytes read
    # =0 - ok, eof
    # <0 - not ok
    
    my $self = shift ;

    return G_EOF if *$self->{Closed} ;
    return G_EOF if !length *$self->{Pending} && *$self->{EndStream} ;

    my $buffer ;

    #croak(*$self->{ClassName} . "::read: buffer parameter is read-only")
    #    if Compress::Zlib::_readonly_ref($_[0]);

    if (ref $_[0] ) {
        croak(*$self->{ClassName} . "::read: buffer parameter is read-only")
            if readonly(${ $_[0] });

        croak *$self->{ClassName} . "::read: not a scalar reference $_[0]" 
            unless ref $_[0] eq 'SCALAR' ;
        $buffer = $_[0] ;
    }
    else {
        croak(*$self->{ClassName} . "::read: buffer parameter is read-only")
            if readonly($_[0]);

        $buffer = \$_[0] ;
    }

    my $length = $_[1] ;
    my $offset = $_[2] || 0;

    # the core read will return 0 if asked for 0 bytes
    return 0 if defined $length && $length == 0 ;

    $length = $length || 0;

    croak(*$self->{ClassName} . "::read: length parameter is negative")
        if $length < 0 ;

    $$buffer = '' unless *$self->{AppendOutput}  || $offset ;

    # Short-circuit if this is a simple read, with no length
    # or offset specified.
    unless ( $length || $offset) {
        if (length *$self->{Pending}) {
            $$buffer .= *$self->{Pending} ;
            my $len = length *$self->{Pending};
            *$self->{Pending} = '' ;
            return $len ;
        }
        else {
            my $len = 0;
            $len = $self->_raw_read($buffer) 
                while ! *$self->{EndStream} && $len == 0 ;
            return $len ;
        }
    }

    # Need to jump through more hoops - either length or offset 
    # or both are specified.
    #*$self->{Pending} = '' if ! length *$self->{Pending} ;
    my $out_buffer = \*$self->{Pending} ;

    while (! *$self->{EndStream} && length($$out_buffer) < $length)
    {
        my $buf_len = $self->_raw_read($out_buffer);
        return $buf_len 
            if $buf_len < 0 ;
    }

    $length = length $$out_buffer 
        if length($$out_buffer) < $length ;

    if ($offset) { 
        $$buffer .= "\x00" x ($offset - length($$buffer))
            if $offset > length($$buffer) ;
        #substr($$buffer, $offset) = substr($$out_buffer, 0, $length, '') ;
        substr($$buffer, $offset) = substr($$out_buffer, 0, $length) ;
        substr($$out_buffer, 0, $length) =  '' ;
    }
    else {
        #$$buffer .= substr($$out_buffer, 0, $length, '') ;
        $$buffer .= substr($$out_buffer, 0, $length) ;
        substr($$out_buffer, 0, $length) =  '' ;
    }

    return $length ;
}

sub _getline
{
    my $self = shift ;

    # Slurp Mode
    if ( ! defined $/ ) {
        my $data ;
        1 while $self->read($data) > 0 ;
        return \$data ;
    }

    # Paragraph Mode
    if ( ! length $/ ) {
        my $paragraph ;    
        while ($self->read($paragraph) > 0 ) {
            if ($paragraph =~ s/^(.*?\n\n+)//s) {
                *$self->{Pending}  = $paragraph ;
                my $par = $1 ;
              return \$par ;
            }
        }
        return \$paragraph;
    }

    # Line Mode
    {
        my $line ;    
        my $endl = quotemeta($/); # quote in case $/ contains RE meta chars
        while ($self->read($line) > 0 ) {
            if ($line =~ s/^(.*?$endl)//s) {
                *$self->{Pending} = $line ;
                $. = ++ *$self->{LineNo} ;
                my $l = $1 ;
                return \$l ;
            }
        }
        $. = ++ *$self->{LineNo} if defined($line);
        return \$line;
    }
}

sub getline
{
    my $self = shift;
    my $current_append = *$self->{AppendOutput} ;
    *$self->{AppendOutput} = 1;
    my $lineref = $self->_getline();
    *$self->{AppendOutput} = $current_append;
    return $$lineref ;
}

sub getlines
{
    my $self = shift;
    croak *$self->{ClassName} . "::getlines: called in scalar context\n" unless wantarray;
    my($line, @lines);
    push(@lines, $line) while defined($line = $self->getline);
    return @lines;
}

sub READLINE
{
    goto &getlines if wantarray;
    goto &getline;
}

sub getc
{
    my $self = shift;
    my $buf;
    return $buf if $self->read($buf, 1);
    return undef;
}

sub ungetc
{
    my $self = shift;
    *$self->{Pending} = ""  unless defined *$self->{Pending} ;    
    *$self->{Pending} = $_[0] . *$self->{Pending} ;    
}


sub trailingData
{
    my $self = shift ;
    return \"" if ! defined *$self->{Trailing} ;
    return \*$self->{Trailing} ;
}

sub inflateSync
{
    my $self = shift ;

    # inflateSync is a no-op in Plain mode
    return 1
        if *$self->{Plain} ;

    return 0 if *$self->{Closed} ;
    #return G_EOF if !length *$self->{Pending} && *$self->{EndStream} ;
    return 0 if ! length *$self->{Pending} && *$self->{EndStream} ;

    # Disable CRC check
    *$self->{Strict} = 0 ;

    my $status ;
    while (1)
    {
        my $temp_buf ;

        if (length *$self->{Pending} )
        {
            $temp_buf = *$self->{Pending} ;
            *$self->{Pending} = '';
        }
        else
        {
            $status = $self->smartRead(\$temp_buf, *$self->{BlockSize}) ;
            return $self->saveErrorString(0, "Error Reading Data")
                if $status < 0  ;

            if ($status == 0 ) {
                *$self->{EndStream} = 1 ;
                return $self->saveErrorString(0, "unexpected end of file", Z_DATA_ERROR);
            }
        }
        
        $status = *$self->{Inflate}->inflateSync($temp_buf) ;

        if ($status == Z_OK)
        {
            *$self->{Pending} .= $temp_buf ;
            return 1 ;
        }

        last unless $status = Z_DATA_ERROR ;
    }

    return 0;
}

sub eof
{
    my $self = shift ;

    return (*$self->{Closed} ||
              (!length *$self->{Pending} 
                && ( $self->smartEof() || *$self->{EndStream}))) ;
}

sub tell
{
    my $self = shift ;

    my $in ;
    if (*$self->{Plain}) {
        $in = *$self->{PlainBytesRead} ;
    }
    else {
        $in = *$self->{TotalInflatedBytesRead} ;
    }

    my $pending = length *$self->{Pending} ;

    return 0 if $pending > $in ;
    return $in - $pending ;
}

sub close
{
    # todo - what to do if close is called before the end of the gzip file
    #        do we remember any trailing data?
    my $self = shift ;

    return 1 if *$self->{Closed} ;

    untie *$self 
        if $] >= 5.008 ;

    my $status = 1 ;

    if (defined *$self->{FH}) {
        if ((! *$self->{Handle} || *$self->{AutoClose}) && ! *$self->{StdIO}) {
        #if ( *$self->{AutoClose}) {
            $! = 0 ;
            $status = *$self->{FH}->close();
            return $self->saveErrorString(0, $!, $!)
                if !*$self->{InNew} && $self->saveStatus($!) != 0 ;
        }
        delete *$self->{FH} ;
        $! = 0 ;
    }
    *$self->{Closed} = 1 ;

    return 1;
}

sub DESTROY
{
    my $self = shift ;
    $self->close() ;
}

sub seek
{
    my $self     = shift ;
    my $position = shift;
    my $whence   = shift ;

    my $here = $self->tell() ;
    my $target = 0 ;


    if ($whence == SEEK_SET) {
        $target = $position ;
    }
    elsif ($whence == SEEK_CUR) {
        $target = $here + $position ;
    }
    elsif ($whence == SEEK_END) {
        $target = $position ;
        croak *$self->{ClassName} . "::seek: SEEK_END not allowed" ;
    }
    else {
        croak *$self->{ClassName} ."::seek: unknown value, $whence, for whence parameter";
    }

    # short circuit if seeking to current offset
    return 1 if $target == $here ;    

    # Outlaw any attempt to seek backwards
    croak *$self->{ClassName} ."::seek: cannot seek backwards"
        if $target < $here ;

    # Walk the file to the new offset
    my $offset = $target - $here ;

    my $buffer ;
    $self->read($buffer, $offset) == $offset
        or return 0 ;

    return 1 ;
}

sub fileno
{
    my $self = shift ;
    return defined *$self->{FH} 
           ? fileno *$self->{FH} 
           : undef ;
}

sub binmode
{
    1;
#    my $self     = shift ;
#    return defined *$self->{FH} 
#            ? binmode *$self->{FH} 
#            : 1 ;
}

*BINMODE  = \&binmode;
*SEEK     = \&seek; 
*READ     = \&read;
*sysread  = \&read;
*TELL     = \&tell;
*EOF      = \&eof;

*FILENO   = \&fileno;
*CLOSE    = \&close;

sub _notAvailable
{
    my $name = shift ;
    #return sub { croak "$name Not Available" ; } ;
    return sub { croak "$name Not Available: File opened only for intput" ; } ;
}


*print    = _notAvailable('print');
*PRINT    = _notAvailable('print');
*printf   = _notAvailable('printf');
*PRINTF   = _notAvailable('printf');
*write    = _notAvailable('write');
*WRITE    = _notAvailable('write');

#*sysread  = \&read;
#*syswrite = \&_notAvailable;

#package IO::_infScan ;
#
#*_raw_read = \&IO::BaseInflate::_raw_read ;
#*smartRead = \&IO::BaseInflate::smartRead ;
#*smartWrite = \&IO::BaseInflate::smartWrite ;
#*smartSeek = \&IO::BaseInflate::smartSeek ;

sub scan
{
    my $self = shift ;

    return 1 if *$self->{Closed} ;
    return 1 if !length *$self->{Pending} && *$self->{EndStream} ;

    my $buffer = '' ;
    my $len = 0;

    $len = $self->_raw_read(\$buffer, 1) 
        while ! *$self->{EndStream} && $len >= 0 ;

    #return $len if $len < 0 ? $len : 0 ;
    return $len < 0 ? 0 : 1 ;
}

sub zap
{
    my $self  = shift ;

    my $headerLength = *$self->{Info}{HeaderLength};
    my $block_offset =  $headerLength + *$self->{Inflate}->getLastBlockOffset();
    $_[0] = $headerLength + *$self->{Inflate}->getEndOffset();
    #printf "# End $_[0], headerlen $headerLength \n";;

    #printf "# block_offset $block_offset %x\n", $block_offset;
    my $byte ;
    ( $self->smartSeek($block_offset) &&
      $self->smartRead(\$byte, 1) ) 
        or return $self->saveErrorString(0, $!, $!); 

    #printf "#byte is %x\n", unpack('C*',$byte);
    *$self->{Inflate}->resetLastBlockByte($byte);
    #printf "#to byte is %x\n", unpack('C*',$byte);

    ( $self->smartSeek($block_offset) && 
      $self->smartWrite($byte) )
        or return $self->saveErrorString(0, $!, $!); 

    #$self->smartSeek($end_offset, 1);

    return 1 ;
}

sub createDeflate
{
    my $self  = shift ;
    my ($status, $def) = *$self->{Inflate}->createDeflateStream(
                                    -AppendOutput   => 1,
                                    -WindowBits => - MAX_WBITS,
                                    -CRC32      => *$self->{Type} eq 'rfc1952'
                                            || *$self->{Type} eq 'zip',
                                    -ADLER32    => *$self->{Type} eq 'rfc1950',
                                );
    
    return wantarray ? ($status, $def) : $def ;                                
}


package IO::Uncompress::Gunzip ;

1 ;
__END__


=head1 NAME

IO::Uncompress::Gunzip - Perl interface to read RFC 1952 files/buffers

=head1 SYNOPSIS

    use IO::Uncompress::Gunzip qw(gunzip $GunzipError) ;

    my $status = gunzip $input => $output [,OPTS]
        or die "gunzip failed: $GunzipError\n";

    my $z = new IO::Uncompress::Gunzip $input [OPTS] 
        or die "gunzip failed: $GunzipError\n";

    $status = $z->read($buffer)
    $status = $z->read($buffer, $length)
    $status = $z->read($buffer, $length, $offset)
    $line = $z->getline()
    $char = $z->getc()
    $char = $z->ungetc()
    $status = $z->inflateSync()
    $z->trailingData()
    $data = $z->getHeaderInfo()
    $z->tell()
    $z->seek($position, $whence)
    $z->binmode()
    $z->fileno()
    $z->eof()
    $z->close()

    $GunzipError ;

    # IO::File mode

    <$z>
    read($z, $buffer);
    read($z, $buffer, $length);
    read($z, $buffer, $length, $offset);
    tell($z)
    seek($z, $position, $whence)
    binmode($z)
    fileno($z)
    eof($z)
    close($z)


=head1 DESCRIPTION



B<WARNING -- This is a Beta release>. 

=over 5

=item * DO NOT use in production code.

=item * The documentation is incomplete in places.

=item * Parts of the interface defined here are tentative.

=item * Please report any problems you find.

=back





This module provides a Perl interface that allows the reading of 
files/buffers that conform to RFC 1952.

For writing RFC 1952 files/buffers, see the companion module 
IO::Compress::Gzip.



=head1 Functional Interface

A top-level function, C<gunzip>, is provided to carry out "one-shot"
uncompression between buffers and/or files. For finer control over the uncompression process, see the L</"OO Interface"> section.

    use IO::Uncompress::Gunzip qw(gunzip $GunzipError) ;

    gunzip $input => $output [,OPTS] 
        or die "gunzip failed: $GunzipError\n";

    gunzip \%hash [,OPTS] 
        or die "gunzip failed: $GunzipError\n";

The functional interface needs Perl5.005 or better.


=head2 gunzip $input => $output [, OPTS]

If the first parameter is not a hash reference C<gunzip> expects
at least two parameters, C<$input> and C<$output>.

=head3 The C<$input> parameter

The parameter, C<$input>, is used to define the source of
the compressed data. 

It can take one of the following forms:

=over 5

=item A filename

If the C<$input> parameter is a simple scalar, it is assumed to be a
filename. This file will be opened for reading and the input data
will be read from it.

=item A filehandle

If the C<$input> parameter is a filehandle, the input data will be
read from it.
The string '-' can be used as an alias for standard input.

=item A scalar reference 

If C<$input> is a scalar reference, the input data will be read
from C<$$input>.

=item An array reference 

If C<$input> is an array reference, the input data will be read from each
element of the array in turn. The action taken by C<gunzip> with
each element of the array will depend on the type of data stored
in it. You can mix and match any of the types defined in this list,
excluding other array or hash references. 
The complete array will be walked to ensure that it only
contains valid data types before any data is uncompressed.

=item An Input FileGlob string

If C<$input> is a string that is delimited by the characters "<" and ">"
C<gunzip> will assume that it is an I<input fileglob string>. The
input is the list of files that match the fileglob.

If the fileglob does not match any files ...

See L<File::GlobMapper|File::GlobMapper> for more details.


=back

If the C<$input> parameter is any other type, C<undef> will be returned.



=head3 The C<$output> parameter

The parameter C<$output> is used to control the destination of the
uncompressed data. This parameter can take one of these forms.

=over 5

=item A filename

If the C<$output> parameter is a simple scalar, it is assumed to be a filename.
This file will be opened for writing and the uncompressed data will be
written to it.

=item A filehandle

If the C<$output> parameter is a filehandle, the uncompressed data will
be written to it.  
The string '-' can be used as an alias for standard output.


=item A scalar reference 

If C<$output> is a scalar reference, the uncompressed data will be stored
in C<$$output>.


=item A Hash Reference

If C<$output> is a hash reference, the uncompressed data will be written
to C<$output{$input}> as a scalar reference.

When C<$output> is a hash reference, C<$input> must be either a filename or
list of filenames. Anything else is an error.


=item An Array Reference

If C<$output> is an array reference, the uncompressed data will be pushed
onto the array.

=item An Output FileGlob

If C<$output> is a string that is delimited by the characters "<" and ">"
C<gunzip> will assume that it is an I<output fileglob string>. The
output is the list of files that match the fileglob.

When C<$output> is an fileglob string, C<$input> must also be a fileglob
string. Anything else is an error.

=back

If the C<$output> parameter is any other type, C<undef> will be returned.

=head2 gunzip \%hash [, OPTS]

If the first parameter is a hash reference, C<\%hash>, this will be used to
define both the source of compressed data and to control where the
uncompressed data is output. Each key/value pair in the hash defines a
mapping between an input filename, stored in the key, and an output
file/buffer, stored in the value. Although the input can only be a filename,
there is more flexibility to control the destination of the uncompressed
data. This is determined by the type of the value. Valid types are

=over 5

=item undef

If the value is C<undef> the uncompressed data will be written to the
value as a scalar reference.

=item A filename

If the value is a simple scalar, it is assumed to be a filename. This file will
be opened for writing and the uncompressed data will be written to it.

=item A filehandle

If the value is a filehandle, the uncompressed data will be
written to it. 
The string '-' can be used as an alias for standard output.


=item A scalar reference 

If the value is a scalar reference, the uncompressed data will be stored
in the buffer that is referenced by the scalar.


=item A Hash Reference

If the value is a hash reference, the uncompressed data will be written
to C<$hash{$input}> as a scalar reference.

=item An Array Reference

If C<$output> is an array reference, the uncompressed data will be pushed
onto the array.

=back

Any other type is a error.

=head2 Notes

When C<$input> maps to multiple files/buffers and C<$output> is a single
file/buffer the uncompressed input files/buffers will all be stored in
C<$output> as a single uncompressed stream.



=head2 Optional Parameters

Unless specified below, the optional parameters for C<gunzip>,
C<OPTS>, are the same as those used with the OO interface defined in the
L</"Constructor Options"> section below.

=over 5

=item AutoClose =E<gt> 0|1

This option applies to any input or output data streams to C<gunzip>
that are filehandles.

If C<AutoClose> is specified, and the value is true, it will result in all
input and/or output filehandles being closed once C<gunzip> has
completed.

This parameter defaults to 0.



=item -Append =E<gt> 0|1

TODO



=back




=head2 Examples

To read the contents of the file C<file1.txt.gz> and write the
compressed data to the file C<file1.txt>.

    use strict ;
    use warnings ;
    use IO::Uncompress::Gunzip qw(gunzip $GunzipError) ;

    my $input = "file1.txt.gz";
    my $output = "file1.txt";
    gunzip $input => $output
        or die "gunzip failed: $GunzipError\n";


To read from an existing Perl filehandle, C<$input>, and write the
uncompressed data to a buffer, C<$buffer>.

    use strict ;
    use warnings ;
    use IO::Uncompress::Gunzip qw(gunzip $GunzipError) ;
    use IO::File ;

    my $input = new IO::File "<file1.txt.gz"
        or die "Cannot open 'file1.txt.gz': $!\n" ;
    my $buffer ;
    gunzip $input => \$buffer 
        or die "gunzip failed: $GunzipError\n";

To uncompress all files in the directory "/my/home" that match "*.txt.gz" and store the compressed data in the same directory

    use strict ;
    use warnings ;
    use IO::Uncompress::Gunzip qw(gunzip $GunzipError) ;

    gunzip '</my/home/*.txt.gz>' => '</my/home/#1.txt>'
        or die "gunzip failed: $GunzipError\n";

and if you want to compress each file one at a time, this will do the trick

    use strict ;
    use warnings ;
    use IO::Uncompress::Gunzip qw(gunzip $GunzipError) ;

    for my $input ( glob "/my/home/*.txt.gz" )
    {
        my $output = $input;
        $output =~ s/.gz// ;
        gunzip $input => $output 
            or die "Error compressing '$input': $GunzipError\n";
    }

=head1 OO Interface

=head2 Constructor

The format of the constructor for IO::Uncompress::Gunzip is shown below


    my $z = new IO::Uncompress::Gunzip $input [OPTS]
        or die "IO::Uncompress::Gunzip failed: $GunzipError\n";

Returns an C<IO::Uncompress::Gunzip> object on success and undef on failure.
The variable C<$GunzipError> will contain an error message on failure.

If you are running Perl 5.005 or better the object, C<$z>, returned from 
IO::Uncompress::Gunzip can be used exactly like an L<IO::File|IO::File> filehandle. 
This means that all normal input file operations can be carried out with C<$z>. 
For example, to read a line from a compressed file/buffer you can use either 
of these forms

    $line = $z->getline();
    $line = <$z>;

The mandatory parameter C<$input> is used to determine the source of the
compressed data. This parameter can take one of three forms.

=over 5

=item A filename

If the C<$input> parameter is a scalar, it is assumed to be a filename. This
file will be opened for reading and the compressed data will be read from it.

=item A filehandle

If the C<$input> parameter is a filehandle, the compressed data will be
read from it.
The string '-' can be used as an alias for standard input.


=item A scalar reference 

If C<$input> is a scalar reference, the compressed data will be read from
C<$$output>.

=back

=head2 Constructor Options


The option names defined below are case insensitive and can be optionally
prefixed by a '-'.  So all of the following are valid

    -AutoClose
    -autoclose
    AUTOCLOSE
    autoclose

OPTS is a combination of the following options:

=over 5

=item -AutoClose =E<gt> 0|1

This option is only valid when the C<$input> parameter is a filehandle. If
specified, and the value is true, it will result in the file being closed once
either the C<close> method is called or the IO::Uncompress::Gunzip object is
destroyed.

This parameter defaults to 0.

=item -MultiStream =E<gt> 0|1



Allows multiple concatenated compressed streams to be treated as a single
compressed stream. Decompression will stop once either the end of the
file/buffer is reached, an error is encountered (premature eof, corrupt
compressed data) or the end of a stream is not immediately followed by the
start of another stream.

This parameter defaults to 0.



=item -Prime =E<gt> $string

This option will uncompress the contents of C<$string> before processing the
input file/buffer.

This option can be useful when the compressed data is embedded in another
file/data structure and it is not possible to work out where the compressed
data begins without having to read the first few bytes. If this is the case,
the uncompression can be I<primed> with these bytes using this option.

=item -Transparent =E<gt> 0|1

If this option is set and the input file or buffer is not compressed data,
the module will allow reading of it anyway.

This option defaults to 1.

=item -BlockSize =E<gt> $num

When reading the compressed input data, IO::Uncompress::Gunzip will read it in blocks
of C<$num> bytes.

This option defaults to 4096.

=item -InputLength =E<gt> $size

When present this option will limit the number of compressed bytes read from
the input file/buffer to C<$size>. This option can be used in the situation
where there is useful data directly after the compressed data stream and you
know beforehand the exact length of the compressed data stream. 

This option is mostly used when reading from a filehandle, in which case the
file pointer will be left pointing to the first byte directly after the
compressed data stream.



This option defaults to off.

=item -Append =E<gt> 0|1

This option controls what the C<read> method does with uncompressed data.

If set to 1, all uncompressed data will be appended to the output parameter of
the C<read> method.

If set to 0, the contents of the output parameter of the C<read> method will be
overwritten by the uncompressed data.

Defaults to 0.

=item -Strict =E<gt> 0|1



This option controls whether the extra checks defined below are used when
carrying out the decompression. When Strict is on, the extra tests are carried
out, when Strict is off they are not.

The default for this option is off.









=over 5

=item 1 

If the FHCRC bit is set in the gzip FLG header byte, the CRC16 bytes in the
header must match the crc16 value of the gzip header actually read.

=item 2

If the gzip header contains a name field (FNAME) it consists solely of ISO
8859-1 characters.

=item 3

If the gzip header contains a comment field (FCOMMENT) it consists solely of
ISO 8859-1 characters plus line-feed.

=item 4

If the gzip FEXTRA header field is present it must conform to the sub-field
structure as defined in RFC1952.

=item 5

The CRC32 and ISIZE trailer fields must be present.

=item 6

The value of the CRC32 field read must match the crc32 value of the
uncompressed data actually contained in the gzip file.

=item 7

The value of the ISIZE fields read must match the length of the uncompressed
data actually read from the file.

=back






=item -ParseExtra =E<gt> 0|1

If the gzip FEXTRA header field is present and this option is set, it will
force the module to check that it conforms to the sub-field structure as
defined in RFC1952.

If the C<Strict> is on it will automatically enable this option.

Defaults to 0.



=back

=head2 Examples

TODO

=head1 Methods 

=head2 read

Usage is

    $status = $z->read($buffer)

Reads a block of compressed data (the size the the compressed block is
determined by the C<Buffer> option in the constructor), uncompresses it and
writes any uncompressed data into C<$buffer>. If the C<Append> parameter is set
in the constructor, the uncompressed data will be appended to the C<$buffer>
parameter. Otherwise C<$buffer> will be overwritten.

Returns the number of uncompressed bytes written to C<$buffer>, zero if eof or
a negative number on error.

=head2 read

Usage is

    $status = $z->read($buffer, $length)
    $status = $z->read($buffer, $length, $offset)

    $status = read($z, $buffer, $length)
    $status = read($z, $buffer, $length, $offset)

Attempt to read C<$length> bytes of uncompressed data into C<$buffer>.

The main difference between this form of the C<read> method and the previous
one, is that this one will attempt to return I<exactly> C<$length> bytes. The
only circumstances that this function will not is if end-of-file or an IO error
is encountered.

Returns the number of uncompressed bytes written to C<$buffer>, zero if eof or
a negative number on error.


=head2 getline

Usage is

    $line = $z->getline()
    $line = <$z>

Reads a single line. 

This method fully supports the use of of the variable C<$/>
(or C<$INPUT_RECORD_SEPARATOR> or C<$RS> when C<English> is in use) to
determine what constitutes an end of line. Both paragraph mode and file
slurp mode are supported. 


=head2 getc

Usage is 

    $char = $z->getc()

Read a single character.

=head2 ungetc

Usage is

    $char = $z->ungetc($string)


=head2 inflateSync

Usage is

    $status = $z->inflateSync()

TODO

=head2 getHeaderInfo

Usage is

    $hdr = $z->getHeaderInfo()

TODO





This method returns a hash reference that contains the contents of each of the
header fields defined in RFC1952.






=over 5

=item Comment

The contents of the Comment header field, if present. If no comment is present,
the value will be undef. Note this is different from a zero length comment,
which will return an empty string.

=back




=head2 tell

Usage is

    $z->tell()
    tell $z

Returns the uncompressed file offset.

=head2 eof

Usage is

    $z->eof();
    eof($z);



Returns true if the end of the compressed input stream has been reached.



=head2 seek

    $z->seek($position, $whence);
    seek($z, $position, $whence);




Provides a sub-set of the C<seek> functionality, with the restriction
that it is only legal to seek forward in the input file/buffer.
It is a fatal error to attempt to seek backward.



The C<$whence> parameter takes one the usual values, namely SEEK_SET,
SEEK_CUR or SEEK_END.

Returns 1 on success, 0 on failure.

=head2 binmode

Usage is

    $z->binmode
    binmode $z ;

This is a noop provided for completeness.

=head2 fileno

    $z->fileno()
    fileno($z)

If the C<$z> object is associated with a file, this method will return
the underlying filehandle.

If the C<$z> object is is associated with a buffer, this method will
return undef.

=head2 close

    $z->close() ;
    close $z ;



Closes the output file/buffer. 



For most versions of Perl this method will be automatically invoked if
the IO::Uncompress::Gunzip object is destroyed (either explicitly or by the
variable with the reference to the object going out of scope). The
exceptions are Perl versions 5.005 through 5.00504 and 5.8.0. In
these cases, the C<close> method will be called automatically, but
not until global destruction of all live objects when the program is
terminating.

Therefore, if you want your scripts to be able to run on all versions
of Perl, you should call C<close> explicitly and not rely on automatic
closing.

Returns true on success, otherwise 0.

If the C<AutoClose> option has been enabled when the IO::Uncompress::Gunzip
object was created, and the object is associated with a file, the
underlying file will also be closed.




=head1 Importing 

No symbolic constants are required by this IO::Uncompress::Gunzip at present. 

=over 5

=item :all

Imports C<gunzip> and C<$GunzipError>.
Same as doing this

    use IO::Uncompress::Gunzip qw(gunzip $GunzipError) ;

=back

=head1 EXAMPLES




=head1 SEE ALSO

L<Compress::Zlib>, L<IO::Compress::Gzip>, L<IO::Compress::Deflate>, L<IO::Uncompress::Inflate>, L<IO::Compress::RawDeflate>, L<IO::Uncompress::RawInflate>, L<IO::Uncompress::AnyInflate>

L<Compress::Zlib::FAQ|Compress::Zlib::FAQ>

L<File::GlobMapper|File::GlobMapper>, L<Archive::Tar|Archive::Zip>,
L<IO::Zlib|IO::Zlib>

For RFC 1950, 1951 and 1952 see 
F<http://www.faqs.org/rfcs/rfc1950.html>,
F<http://www.faqs.org/rfcs/rfc1951.html> and
F<http://www.faqs.org/rfcs/rfc1952.html>

The primary site for the gzip program is F<http://www.gzip.org>.

=head1 AUTHOR

The I<IO::Uncompress::Gunzip> module was written by Paul Marquess,
F<pmqs@cpan.org>. The latest copy of the module can be
found on CPAN in F<modules/by-module/Compress/Compress-Zlib-x.x.tar.gz>.

The I<zlib> compression library was written by Jean-loup Gailly
F<gzip@prep.ai.mit.edu> and Mark Adler F<madler@alumni.caltech.edu>.

The primary site for the I<zlib> compression library is
F<http://www.zlib.org>.

=head1 MODIFICATION HISTORY

See the Changes file.

=head1 COPYRIGHT AND LICENSE
 

Copyright (c) 2005 Paul Marquess. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.



