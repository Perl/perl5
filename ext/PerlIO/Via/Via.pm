package PerlIO::Via;
our $VERSION = '0.01';
use XSLoader ();
XSLoader::load 'PerlIO::Via';
1;
__END__

=head1 NAME

PerlIO::Via - Helper class for PerlIO layers implemented in perl

=head1 SYNOPSIS

   use Some::Package;

   open($fh,"<:Via(Some::Package)",...);

=head1 DESCRIPTION

The package to be used as a layer should implement at least some of the
following methods. In the method descriptions below I<$fh> will be
a reference to a glob which can be treated as a perl file handle.
It refers to the layer below. I<$fh> is not passed if the layer
is at the bottom of the stack, for this reason and to maintain
some level of "compatibility" with TIEHANDLE classes it is passed
last.

=over 4

=item $class->PUSHED([$mode][,$fh])

Should return an object or the class. (Compare TIEHANDLE.)
Mandatory.

=item $obj->POPPED([$fh])

Optional - layer is about to be removed.

=item $class->OPEN($path,$mode[,$fh])

Not yet in use.

=item $class->FDOPEN($fd)

Not yet in use.

=item $class->SYSOPEN($path,$imode,$perm,$fh)

Not yet in use.

=item $obj->FILENO($fh)

Returns a numeric value for Unix-like file descriptor. Return -1 if
there isn't one.  Optional.  Default is fileno($fh).

=item $obj->READ($buffer,$len,$fh)

Returns the number of octets placed in $buffer (must be less than or
equal to $len).  Optional.  Default is to use FILL instead.

=item $obj->WRITE($buffer,$fh)

Returns the number of octets from buffer that have been sucessfully written.

=item $obj->FILL($fh)

Should return a string to be placed in the buffer.  Optional. If not
provided must provide READ or reject handles open for reading in
PUSHED.

=item $obj->CLOSE($fh)

Should return 0 on success, -1 on error.
Optional.

=item $obj->SEEK($posn,$whence,$fh)

Should return 0 on success, -1 on error.
Optional. Default is to fail, but that is likely to be changed.

=item $obj->TELL($fh)

Returns file postion.
Optional. Default to be determined.

=item $obj->UNREAD($buffer,$fh)

Returns the number of octets from buffer that have been sucessfully
saved to be returned on future FILL/READ calls.  Optional. Default is
to push data into a temporary layer above this one.

=item $obj->FLUSH($fh)

Flush any buffered write data.  May possibly be called on readable
handles too.  Should return 0 on success, -1 on error.

=item $obj->SETLINEBUF($fh)

Optional. No return.

=item $obj->CLEARERR($fh)

Optional. No return.

=item $obj->ERROR($fh)

Optional. Returns error state. Default is no error until a mechanism
to signal error (die?) is worked out.

=item $obj->EOF($fh)

Optional. Returns end-of-file state. Default is function of return
value of FILL or READ.

=back

=cut


