# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub atol {
    unimpl "atol() is C-specific, stopped", caller;
}

1;
