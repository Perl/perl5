# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub tcdrain {
    unimpl "tcdrain(xxx)", caller if @_ != 123;
    tcdrain($_[0]);
}

1;
