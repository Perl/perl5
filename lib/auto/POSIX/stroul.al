# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub stroul {
    unimpl "stroul(xxx)", caller if @_ != 123;
    stroul($_[0]);
}

1;
