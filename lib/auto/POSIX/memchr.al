# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub memchr {
    unimpl "memchr(xxx)", caller if @_ != 123;
    memchr($_[0]);
}

1;
