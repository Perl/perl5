# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub fgetc {
    usage "fgetc(filehandle)", caller if @_ != 1;
    getc($_[0]);
}

1;
