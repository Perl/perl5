# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub putchar {
    unimpl "putchar() is C-specific--use print instead", caller;
    unimpl "putchar(xxx)", caller if @_ != 123;
    putchar($_[0]);
}

1;
