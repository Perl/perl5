# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub free {
    unimpl "free(xxx)", caller if @_ != 123;
    free($_[0]);
}

1;
