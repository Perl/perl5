# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub pause {
    unimpl "pause(xxx)", caller if @_ != 123;
    pause($_[0]);
}

1;
