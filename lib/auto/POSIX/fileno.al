# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub fileno {
    usage "fileno(filehandle)", caller if @_ != 1;
    fileno($_[0]);
}

1;
