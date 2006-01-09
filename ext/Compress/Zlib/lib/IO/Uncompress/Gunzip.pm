
package IO::Uncompress::Gunzip ;

require 5.004 ;

# for RFC1952

use strict ;
use warnings;

use IO::Uncompress::RawInflate ;

use Compress::Zlib qw( crc32 ) ;
use Compress::Zlib::Common qw(createSelfTiedObject);
use Compress::Gzip::Constants;

require Exporter ;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS, $GunzipError);

@ISA = qw( Exporter IO::Uncompress::RawInflate );
@EXPORT_OK = qw( $GunzipError gunzip );
%EXPORT_TAGS = %IO::Uncompress::RawInflate::DEFLATE_CONSTANTS ;
push @{ $EXPORT_TAGS{all} }, @EXPORT_OK ;
Exporter::export_ok_tags('all');

$GunzipError = '';

$VERSION = '2.000_07';

sub new
{
    my $class = shift ;
    $GunzipError = '';
    my $obj = createSelfTiedObject($class, \$GunzipError);

    $obj->_create(undef, 0, @_);
}

sub gunzip
{
    my $obj = createSelfTiedObject(undef, \$GunzipError);
    return $obj->_inf(@_) ;
}

sub getExtraParams
{
    use Compress::Zlib::ParseParameters ;
    return ( 'ParseExtra' => [1, 1, Parse_boolean,  0] ) ;
}

sub ckParams
{
    my $self = shift ;
    my $got = shift ;

    # gunzip always needs crc32
    $got->value('CRC32' => 1);

    return 1;
}

sub ckMagic
{
    my $self = shift;

    my $magic ;
    $self->smartReadExact(\$magic, GZIP_ID_SIZE);

    *$self->{HeaderPending} = $magic ;

    return $self->HeaderError("Minimum header size is " . 
                              GZIP_MIN_HEADER_SIZE . " bytes") 
        if length $magic != GZIP_ID_SIZE ;                                    

    return $self->HeaderError("Bad Magic")
        if ! isGzipMagic($magic) ;

    *$self->{Type} = 'rfc1952';

    return $magic ;
}

sub readHeader
{
    my $self = shift;
    my $magic = shift;

    return $self->_readGzipHeader($magic);
}

sub chkTrailer
{
    my $self = shift;
    my $trailer = shift;

    # Check CRC & ISIZE 
    my ($CRC32, $ISIZE) = unpack("V V", $trailer) ;
    *$self->{Info}{CRC32} = $CRC32;    
    *$self->{Info}{ISIZE} = $ISIZE;    

    if (*$self->{Strict}) {
        return $self->TrailerError("CRC mismatch")
            if $CRC32 != *$self->{Uncomp}->crc32() ;

        my $exp_isize = *$self->{Uncomp}->uncompressedBytes();
        return $self->TrailerError("ISIZE mismatch. Got $ISIZE"
                                  . ", expected $exp_isize")
            if $ISIZE != $exp_isize ;
    }

    return 1;
}

sub isGzipMagic
{
    my $buffer = shift ;
    return 0 if length $buffer < GZIP_ID_SIZE ;
    my ($id1, $id2) = unpack("C C", $buffer) ;
    return $id1 == GZIP_ID1 && $id2 == GZIP_ID2 ;
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
        'FingerprintLength'  => 2,
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


1;

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

For writing RFC 1952 files/buffers, see the companion module IO::Compress::Gzip.



=head1 Functional Interface

A top-level function, C<gunzip>, is provided to carry out
"one-shot" uncompression between buffers and/or files. For finer
control over the uncompression process, see the L</"OO Interface">
section.

    use IO::Uncompress::Gunzip qw(gunzip $GunzipError) ;

    gunzip $input => $output [,OPTS] 
        or die "gunzip failed: $GunzipError\n";



The functional interface needs Perl5.005 or better.


=head2 gunzip $input => $output [, OPTS]


C<gunzip> expects at least two parameters, C<$input> and C<$output>.

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

If C<$input> is an array reference, each element in the array must be a
filename.

The input data will be read from each file in turn. 

The complete array will be walked to ensure that it only
contains valid filenames before any data is uncompressed.



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

If the C<$output> parameter is a simple scalar, it is assumed to be a
filename.  This file will be opened for writing and the uncompressed
data will be written to it.

=item A filehandle

If the C<$output> parameter is a filehandle, the uncompressed data
will be written to it.
The string '-' can be used as an alias for standard output.


=item A scalar reference 

If C<$output> is a scalar reference, the uncompressed data will be
stored in C<$$output>.



=item An Array Reference

If C<$output> is an array reference, the uncompressed data will be
pushed onto the array.

=item An Output FileGlob

If C<$output> is a string that is delimited by the characters "<" and ">"
C<gunzip> will assume that it is an I<output fileglob string>. The
output is the list of files that match the fileglob.

When C<$output> is an fileglob string, C<$input> must also be a fileglob
string. Anything else is an error.

=back

If the C<$output> parameter is any other type, C<undef> will be returned.



=head2 Notes

When C<$input> maps to multiple files/buffers and C<$output> is a single
file/buffer the uncompressed input files/buffers will all be stored
in C<$output> as a single uncompressed stream.



=head2 Optional Parameters

Unless specified below, the optional parameters for C<gunzip>,
C<OPTS>, are the same as those used with the OO interface defined in the
L</"Constructor Options"> section below.

=over 5

=item AutoClose =E<gt> 0|1

This option applies to any input or output data streams to 
C<gunzip> that are filehandles.

If C<AutoClose> is specified, and the value is true, it will result in all
input and/or output filehandles being closed once C<gunzip> has
completed.

This parameter defaults to 0.



=item BinModeOut =E<gt> 0|1

When writing to a file or filehandle, set C<binmode> before writing to the
file.

Defaults to 0.





=item -Append =E<gt> 0|1

TODO

=item -MultiStream =E<gt> 0|1

Creates a new stream after each file.

Defaults to 1.



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
This means that all normal input file operations can be carried out with
C<$z>.  For example, to read a line from a compressed file/buffer you can
use either of these forms

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
data begins without having to read the first few bytes. If this is the
case, the uncompression can be I<primed> with these bytes using this
option.

=item -Transparent =E<gt> 0|1

If this option is set and the input file or buffer is not compressed data,
the module will allow reading of it anyway.

This option defaults to 1.

=item -BlockSize =E<gt> $num

When reading the compressed input data, IO::Uncompress::Gunzip will read it in
blocks of C<$num> bytes.

This option defaults to 4096.

=item -InputLength =E<gt> $size

When present this option will limit the number of compressed bytes read
from the input file/buffer to C<$size>. This option can be used in the
situation where there is useful data directly after the compressed data
stream and you know beforehand the exact length of the compressed data
stream. 

This option is mostly used when reading from a filehandle, in which case
the file pointer will be left pointing to the first byte directly after the
compressed data stream.



This option defaults to off.

=item -Append =E<gt> 0|1

This option controls what the C<read> method does with uncompressed data.

If set to 1, all uncompressed data will be appended to the output parameter
of the C<read> method.

If set to 0, the contents of the output parameter of the C<read> method
will be overwritten by the uncompressed data.

Defaults to 0.

=item -Strict =E<gt> 0|1



This option controls whether the extra checks defined below are used when
carrying out the decompression. When Strict is on, the extra tests are
carried out, when Strict is off they are not.

The default for this option is off.









=over 5

=item 1 

If the FHCRC bit is set in the gzip FLG header byte, the CRC16 bytes in the
header must match the crc16 value of the gzip header actually read.

=item 2

If the gzip header contains a name field (FNAME) it consists solely of ISO
8859-1 characters.

=item 3

If the gzip header contains a comment field (FCOMMENT) it consists solely
of ISO 8859-1 characters plus line-feed.

=item 4

If the gzip FEXTRA header field is present it must conform to the sub-field
structure as defined in RFC1952.

=item 5

The CRC32 and ISIZE trailer fields must be present.

=item 6

The value of the CRC32 field read must match the crc32 value of the
uncompressed data actually contained in the gzip file.

=item 7

The value of the ISIZE fields read must match the length of the
uncompressed data actually read from the file.

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
writes any uncompressed data into C<$buffer>. If the C<Append> parameter is
set in the constructor, the uncompressed data will be appended to the
C<$buffer> parameter. Otherwise C<$buffer> will be overwritten.

Returns the number of uncompressed bytes written to C<$buffer>, zero if eof
or a negative number on error.

=head2 read

Usage is

    $status = $z->read($buffer, $length)
    $status = $z->read($buffer, $length, $offset)

    $status = read($z, $buffer, $length)
    $status = read($z, $buffer, $length, $offset)

Attempt to read C<$length> bytes of uncompressed data into C<$buffer>.

The main difference between this form of the C<read> method and the
previous one, is that this one will attempt to return I<exactly> C<$length>
bytes. The only circumstances that this function will not is if end-of-file
or an IO error is encountered.

Returns the number of uncompressed bytes written to C<$buffer>, zero if eof
or a negative number on error.


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

    $hdr  = $z->getHeaderInfo();
    @hdrs = $z->getHeaderInfo();

This method returns either a hash reference (in scalar context) or a list
or hash references (in array context) that contains information about each
of the header fields in the compressed data stream(s).



=over 5

=item Name

The contents of the Name header field, if present. If no name is
present, the value will be undef. Note this is different from a zero length
name, which will return an empty string.

=item Comment

The contents of the Comment header field, if present. If no comment is
present, the value will be undef. Note this is different from a zero length
comment, which will return an empty string.

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
 

Copyright (c) 2005-2006 Paul Marquess. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.



