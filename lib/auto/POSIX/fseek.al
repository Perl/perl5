# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub fseek {
    unimpl "fseek() is C-specific--use seek instead", caller;
    unimpl "fseek(xxx)", caller if @_ != 123;
    fseek($_[0]);
}

1;
