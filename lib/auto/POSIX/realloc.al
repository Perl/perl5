# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub realloc {
    unimpl "realloc(xxx)", caller if @_ != 123;
    realloc($_[0]);
}

1;
