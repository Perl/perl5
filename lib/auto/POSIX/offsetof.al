# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub offsetof {
    unimpl "offsetof() is C-specific, stopped", caller;
}

1;
