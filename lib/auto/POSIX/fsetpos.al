# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub fsetpos {
    unimpl "fsetpos() is C-specific--use seek instead", caller;
    unimpl "fsetpos(xxx)", caller if @_ != 123;
    fsetpos($_[0]);
}

1;
