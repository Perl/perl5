# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub execvp {
    unimpl "execvp(xxx)", caller if @_ != 123;
    execvp($_[0]);
}

1;
