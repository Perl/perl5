# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub ferror {
    unimpl "ferror(xxx)", caller if @_ != 123;
    ferror($_[0]);
}

1;
