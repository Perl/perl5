# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub sigismember {
    unimpl "sigismember(xxx)", caller if @_ != 123;
    sigismember($_[0]);
}

1;
