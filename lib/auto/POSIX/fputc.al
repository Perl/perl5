# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub fputc {
    unimpl "fputc() is C-specific--use print instead", caller;
}

1;
