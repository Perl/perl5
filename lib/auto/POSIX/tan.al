# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub tan {
    usage "tan(x)", caller if @_ != 1;
    tan($_[0]);
}

1;
