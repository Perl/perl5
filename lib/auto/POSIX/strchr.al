# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub strchr {
    unimpl "strchr(xxx)", caller if @_ != 123;
    strchr($_[0]);
}

1;
