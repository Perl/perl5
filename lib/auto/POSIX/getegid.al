# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub getegid {
    usage "getegid()", caller if @_ != 0;
    $) + 0;
}

1;
