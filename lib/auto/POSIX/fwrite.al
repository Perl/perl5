# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub fwrite {
    unimpl "fwrite() is C-specific--use print instead", caller;
    unimpl "fwrite(xxx)", caller if @_ != 123;
    fwrite($_[0]);
}

1;
