# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub strncmp {
    unimpl "strncmp(xxx)", caller if @_ != 123;
    strncmp($_[0]);
}

1;
