# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub mblen {
    unimpl "mblen(xxx)", caller if @_ != 123;
    mblen($_[0]);
}

1;
