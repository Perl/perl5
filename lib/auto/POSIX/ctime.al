# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub ctime {
    unimpl "ctime(xxx)", caller if @_ != 123;
    ctime($_[0]);
}

1;
