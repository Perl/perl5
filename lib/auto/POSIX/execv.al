# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub execv {
    unimpl "execv(xxx)", caller if @_ != 123;
    execv($_[0]);
}

1;
