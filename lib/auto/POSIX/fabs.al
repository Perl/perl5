# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub fabs {
    usage "fabs(x)", caller if @_ != 1;
    abs($_[0]);
}

1;
