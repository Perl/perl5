# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub sin {
    usage "sin(x)", caller if @_ != 1;
    sin($_[0]);
}

1;
