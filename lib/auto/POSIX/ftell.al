# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub ftell {
    unimpl "ftell() is C-specific--use tell instead", caller;
    unimpl "ftell(xxx)", caller if @_ != 123;
    ftell($_[0]);
}

1;
