# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub exp {
    usage "exp(x)", caller if @_ != 1;
    exp($_[0]);
}

1;
