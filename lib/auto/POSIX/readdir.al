# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub readdir {
    usage "readdir(dirhandle)", caller if @_ != 1;
    readdir($_[0]);
}

1;
