# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub strerror {
    unimpl "strerror(xxx)", caller if @_ != 123;
    strerror($_[0]);
}

1;
