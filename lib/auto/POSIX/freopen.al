# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub freopen {
    unimpl "freopen() is C-specific--use open instead", caller;
    unimpl "freopen(xxx)", caller if @_ != 123;
    freopen($_[0]);
}

1;
