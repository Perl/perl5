# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub lseek {
    unimpl "lseek(xxx)", caller if @_ != 123;
    lseek($_[0]);
}

1;
