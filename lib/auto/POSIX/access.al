# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub access {
    unimpl "access(xxx)", caller if @_ != 123;
    access($_[0]);
}

1;
