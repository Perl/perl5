# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub fclose {
    unimpl "fclose() is C-specific--use close instead", caller;
}

1;
