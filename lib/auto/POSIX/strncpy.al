# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub strncpy {
    unimpl "strncpy(xxx)", caller if @_ != 123;
    strncpy($_[0]);
}

1;
