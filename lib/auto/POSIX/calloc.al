# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub calloc {
    unimpl "calloc(xxx)", caller if @_ != 123;
    calloc($_[0]);
}

1;
