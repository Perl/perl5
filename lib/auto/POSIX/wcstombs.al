# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub wcstombs {
    unimpl "wcstombs(xxx)", caller if @_ != 123;
    wcstombs($_[0]);
}

1;
