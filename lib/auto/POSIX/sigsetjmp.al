# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub sigsetjmp {
    unimpl "sigsetjmp() is C-specific: use eval {} instead", caller;
}

1;
