# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub remove {
    unimpl "remove(xxx)", caller if @_ != 123;
    remove($_[0]);
}

1;
