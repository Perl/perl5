# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub rmdir {
    usage "rmdir(directoryname)", caller if @_ != 1;
    rmdir($_[0]);
}

1;
