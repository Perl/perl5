# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub bsearch {
    unimpl "bsearch(xxx)", caller if @_ != 123;
    bsearch($_[0]);
}

1;
