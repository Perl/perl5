# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub memset {
    unimpl "memset(xxx)", caller if @_ != 123;
    memset($_[0]);
}

1;
