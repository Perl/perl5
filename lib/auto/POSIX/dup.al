# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub dup {
    unimpl "dup(xxx)", caller if @_ != 123;
    dup($_[0]);
}

1;
