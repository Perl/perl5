# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub atof {
    unimpl "atof() is C-specific, stopped", caller;
}

1;
