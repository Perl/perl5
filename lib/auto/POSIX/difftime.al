# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub difftime {
    unimpl "difftime(xxx)", caller if @_ != 123;
    difftime($_[0]);
}

1;
