# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub fork {
    usage "fork()", caller if @_ != 0;
    fork;
}

1;
