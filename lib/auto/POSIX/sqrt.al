# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub sqrt {
    usage "sqrt(x)", caller if @_ != 1;
    sqrt($_[0]);
}

1;
