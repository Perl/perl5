# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub memcmp {
    unimpl "memcmp(xxx)", caller if @_ != 123;
    memcmp($_[0]);
}

1;
