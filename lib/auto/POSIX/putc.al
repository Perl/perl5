# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub putc {
    unimpl "putc() is C-specific--use print instead", caller;
    unimpl "putc(xxx)", caller if @_ != 123;
    putc($_[0]);
}

1;
