# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub atoi {
    unimpl "atoi() is C-specific, stopped", caller;
}

1;
