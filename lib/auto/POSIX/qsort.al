# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub qsort {
    unimpl "qsort(xxx)", caller if @_ != 123;
    qsort($_[0]);
}

1;
