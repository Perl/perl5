# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub ungetc {
    unimpl "ungetc(xxx)", caller if @_ != 123;
    ungetc($_[0]);
}

1;
