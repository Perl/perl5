# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub tmpnam {
    unimpl "tmpnam(xxx)", caller if @_ != 123;
    tmpnam($_[0]);
}

1;
