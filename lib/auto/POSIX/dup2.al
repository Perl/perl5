# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub dup2 {
    unimpl "dup2(xxx)", caller if @_ != 123;
    dup2($_[0]);
}

1;
