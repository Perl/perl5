# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub srand {
    unimpl "srand(xxx)", caller if @_ != 123;
    srand($_[0]);
}

1;
