# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub getgid {
    usage "getgid()", caller if @_ != 0;
    $( + 0;
}

1;
