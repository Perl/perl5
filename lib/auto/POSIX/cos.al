# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub cos {
    usage "cos(x)", caller if @_ != 1;
    cos($_[0]);
}

1;
