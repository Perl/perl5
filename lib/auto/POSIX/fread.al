# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub fread {
    unimpl "fread() is C-specific--use read instead", caller;
    unimpl "fread(xxx)", caller if @_ != 123;
    fread($_[0]);
}

1;
