# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub getppid {
    usage "getppid()", caller if @_ != 0;
    getppid;
}

1;
