# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub setjmp {
    unimpl "setjmp() is C-specific: use eval {} instead", caller;
}

1;
