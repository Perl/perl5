# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub pipe {
    unimpl "pipe(xxx)", caller if @_ != 123;
    pipe($_[0]);
}

1;
