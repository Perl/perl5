# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub mbtowc {
    unimpl "mbtowc(xxx)", caller if @_ != 123;
    mbtowc($_[0]);
}

1;
