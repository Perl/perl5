# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub write {
    unimpl "write(xxx)", caller if @_ != 123;
    write($_[0]);
}

1;
