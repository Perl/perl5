# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub strftime {
    unimpl "strftime(xxx)", caller if @_ != 123;
    strftime($_[0]);
}

1;
