# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub fdopen {
    unimpl "fdopen(xxx)", caller if @_ != 123;
    fdopen($_[0]);
}

1;
