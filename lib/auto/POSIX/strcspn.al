# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub strcspn {
    unimpl "strcspn(xxx)", caller if @_ != 123;
    strcspn($_[0]);
}

1;
