# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub atexit {
    unimpl "atexit() is C-specific: use END {} instead", caller;
}

1;
