# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub setuid {
    unimpl "setuid(xxx)", caller if @_ != 123;
    setuid($_[0]);
}

1;
