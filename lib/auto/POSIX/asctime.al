# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub asctime {
    unimpl "asctime(xxx)", caller if @_ != 123;
    asctime($_[0]);
}

1;
