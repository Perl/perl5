# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub labs {
    unimpl "labs(xxx)", caller if @_ != 123;
    labs($_[0]);
}

1;
