# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub strstr {
    unimpl "strstr(xxx)", caller if @_ != 123;
    strstr($_[0]);
}

1;
