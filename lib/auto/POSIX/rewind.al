# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub rewind {
    unimpl "rewind(xxx)", caller if @_ != 123;
    rewind($_[0]);
}

1;
