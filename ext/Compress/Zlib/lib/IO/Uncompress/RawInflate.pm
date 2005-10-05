package IO::Uncompress::RawInflate ;
# for RFC1951

use strict ;
use warnings;
use IO::Uncompress::Gunzip;

require Exporter ;
our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS, $RawInflateError);

$VERSION = '2.000_05';
$RawInflateError = '';

@ISA    = qw(Exporter IO::BaseInflate);
@EXPORT_OK = qw( $RawInflateError rawinflate ) ;
%EXPORT_TAGS = %IO::BaseInflate::EXPORT_TAGS ;
push @{ $EXPORT_TAGS{all} }, @EXPORT_OK ;
Exporter::export_ok_tags('all');




sub new
{
    my $pkg = shift ;
    return IO::BaseInflate::new($pkg, 'rfc1951', undef, \$RawInflateError, 0, @_);
}

sub rawinflate
{
    return IO::BaseInflate::_inf(__PACKAGE__, 'rfc1951', \$RawInflateError, @_);
}

1; 

__END__


=head1 NAME

IO::Uncompress::RawInflate - Perl interface to read RFC 1951 files/buffers

=head1 SYNOPSIS

    use IO::Uncompress::RawInflate qw(rawinflate $RawInflateError) ;

    my $status = rawinflate $input => $output [,OPTS]
        or die "rawinflate failed: $RawInflateError\n";

    my $z = new IO::Uncompress::RawInflate $input [OPTS] 
        or die "rawinflate failed: $RawInflateError\n";

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

    $RawInflateError ;

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
files/buffers that conform to RFC 1951.

For writing RFC 1951 files/buffers, see the companion module 
IO::Compress::RawDeflate.



=head1 Functional Interface

A top-level function, C<rawinflate>, is provided to carry out "one-shot"
uncompression between buffers and/or files. For finer control over the uncompression process, see the L</"OO Interface"> section.

    use IO::Uncompress::RawInflate qw(rawinflate $RawInflateError) ;

    rawinflate $input => $output [,OPTS] 
        or die "rawinflate failed: $RawInflateError\n";

    rawinflate \%hash [,OPTS] 
        or die "rawinflate failed: $RawInflateError\n";

The functional interface needs Perl5.005 or better.


=head2 rawinflate $input => $output [, OPTS]

If the first parameter is not a hash reference C<rawinflate> expects
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
element of the array in turn. The action taken by C<rawinflate> with
each element of the array will depend on the type of data stored
in it. You can mix and match any of the types defined in this list,
excluding other array or hash references. 
The complete array will be walked to ensure that it only
contains valid data types before any data is uncompressed.

=item An Input FileGlob string

If C<$input> is a string that is delimited by the characters "<" and ">"
C<rawinflate> will assume that it is an I<input fileglob string>. The
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
C<rawinflate> will assume that it is an I<output fileglob string>. The
output is the list of files that match the fileglob.

When C<$output> is an fileglob string, C<$input> must also be a fileglob
string. Anything else is an error.

=back

If the C<$output> parameter is any other type, C<undef> will be returned.

=head2 rawinflate \%hash [, OPTS]

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

Unless specified below, the optional parameters for C<rawinflate>,
C<OPTS>, are the same as those used with the OO interface defined in the
L</"Constructor Options"> section below.

=over 5

=item AutoClose =E<gt> 0|1

This option applies to any input or output data streams to C<rawinflate>
that are filehandles.

If C<AutoClose> is specified, and the value is true, it will result in all
input and/or output filehandles being closed once C<rawinflate> has
completed.

This parameter defaults to 0.



=item -Append =E<gt> 0|1

TODO



=back




=head2 Examples

To read the contents of the file C<file1.txt.1951> and write the
compressed data to the file C<file1.txt>.

    use strict ;
    use warnings ;
    use IO::Uncompress::RawInflate qw(rawinflate $RawInflateError) ;

    my $input = "file1.txt.1951";
    my $output = "file1.txt";
    rawinflate $input => $output
        or die "rawinflate failed: $RawInflateError\n";


To read from an existing Perl filehandle, C<$input>, and write the
uncompressed data to a buffer, C<$buffer>.

    use strict ;
    use warnings ;
    use IO::Uncompress::RawInflate qw(rawinflate $RawInflateError) ;
    use IO::File ;

    my $input = new IO::File "<file1.txt.1951"
        or die "Cannot open 'file1.txt.1951': $!\n" ;
    my $buffer ;
    rawinflate $input => \$buffer 
        or die "rawinflate failed: $RawInflateError\n";

To uncompress all files in the directory "/my/home" that match "*.txt.1951" and store the compressed data in the same directory

    use strict ;
    use warnings ;
    use IO::Uncompress::RawInflate qw(rawinflate $RawInflateError) ;

    rawinflate '</my/home/*.txt.1951>' => '</my/home/#1.txt>'
        or die "rawinflate failed: $RawInflateError\n";

and if you want to compress each file one at a time, this will do the trick

    use strict ;
    use warnings ;
    use IO::Uncompress::RawInflate qw(rawinflate $RawInflateError) ;

    for my $input ( glob "/my/home/*.txt.1951" )
    {
        my $output = $input;
        $output =~ s/.1951// ;
        rawinflate $input => $output 
            or die "Error compressing '$input': $RawInflateError\n";
    }

=head1 OO Interface

=head2 Constructor

The format of the constructor for IO::Uncompress::RawInflate is shown below


    my $z = new IO::Uncompress::RawInflate $input [OPTS]
        or die "IO::Uncompress::RawInflate failed: $RawInflateError\n";

Returns an C<IO::Uncompress::RawInflate> object on success and undef on failure.
The variable C<$RawInflateError> will contain an error message on failure.

If you are running Perl 5.005 or better the object, C<$z>, returned from 
IO::Uncompress::RawInflate can be used exactly like an L<IO::File|IO::File> filehandle. 
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
either the C<close> method is called or the IO::Uncompress::RawInflate object is
destroyed.

This parameter defaults to 0.

=item -MultiStream =E<gt> 0|1



This option is a no-op.



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

When reading the compressed input data, IO::Uncompress::RawInflate will read it in blocks
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



This option is a no-op.





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
the IO::Uncompress::RawInflate object is destroyed (either explicitly or by the
variable with the reference to the object going out of scope). The
exceptions are Perl versions 5.005 through 5.00504 and 5.8.0. In
these cases, the C<close> method will be called automatically, but
not until global destruction of all live objects when the program is
terminating.

Therefore, if you want your scripts to be able to run on all versions
of Perl, you should call C<close> explicitly and not rely on automatic
closing.

Returns true on success, otherwise 0.

If the C<AutoClose> option has been enabled when the IO::Uncompress::RawInflate
object was created, and the object is associated with a file, the
underlying file will also be closed.




=head1 Importing 

No symbolic constants are required by this IO::Uncompress::RawInflate at present. 

=over 5

=item :all

Imports C<rawinflate> and C<$RawInflateError>.
Same as doing this

    use IO::Uncompress::RawInflate qw(rawinflate $RawInflateError) ;

=back

=head1 EXAMPLES




=head1 SEE ALSO

L<Compress::Zlib>, L<IO::Compress::Gzip>, L<IO::Uncompress::Gunzip>, L<IO::Compress::Deflate>, L<IO::Uncompress::Inflate>, L<IO::Compress::RawDeflate>, L<IO::Uncompress::AnyInflate>

L<Compress::Zlib::FAQ|Compress::Zlib::FAQ>

L<File::GlobMapper|File::GlobMapper>, L<Archive::Tar|Archive::Zip>,
L<IO::Zlib|IO::Zlib>

For RFC 1950, 1951 and 1952 see 
F<http://www.faqs.org/rfcs/rfc1950.html>,
F<http://www.faqs.org/rfcs/rfc1951.html> and
F<http://www.faqs.org/rfcs/rfc1952.html>

The primary site for the gzip program is F<http://www.gzip.org>.

=head1 AUTHOR

The I<IO::Uncompress::RawInflate> module was written by Paul Marquess,
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



