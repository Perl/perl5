# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub ctermid {
    unimpl "ctermid(xxx)", caller if @_ != 123;
    ctermid($_[0]);
}

1;
