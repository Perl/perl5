# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub read {
    unimpl "read(xxx)", caller if @_ != 123;
    read($_[0]);
}

1;
