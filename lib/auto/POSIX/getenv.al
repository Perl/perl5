# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub getenv {
    unimpl "getenv(xxx)", caller if @_ != 123;
    getenv($_[0]);
}

1;
