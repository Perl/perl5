# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub longjmp {
    unimpl "longjmp() is C-specific: use die instead", caller;
}

1;
