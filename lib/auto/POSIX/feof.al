# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub feof {
    usage "feof(filehandle)", caller if @_ != 1;
    eof($_[0]);
}

1;
