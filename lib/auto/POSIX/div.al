# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub div {
    unimpl "div(xxx)", caller if @_ != 123;
    div($_[0]);
}

1;
