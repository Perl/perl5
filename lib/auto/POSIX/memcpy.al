# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub memcpy {
    unimpl "memcpy(xxx)", caller if @_ != 123;
    memcpy($_[0]);
}

1;
