# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub wctomb {
    unimpl "wctomb(xxx)", caller if @_ != 123;
    wctomb($_[0]);
}

1;
