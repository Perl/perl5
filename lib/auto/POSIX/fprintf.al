# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub fprintf {
    unimpl "fprintf() is C-specific--use printf instead", caller;
}

1;
