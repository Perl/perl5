# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub siglongjmp {
    unimpl "siglongjmp() is C-specific: use die instead", caller;
}

1;
