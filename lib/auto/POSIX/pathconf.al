# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub pathconf {
    unimpl "pathconf(xxx)", caller if @_ != 123;
    pathconf($_[0]);
}

1;
