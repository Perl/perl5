# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub clearerr {
    usage "clearerr(filehandle)", caller if @_ != 1;
    seek($_[0], 0, 1);
}

1;
