# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub fopen {
    unimpl "fopen() is C-specific--use open instead", caller;
}

1;
