# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub execve {
    unimpl "execve(xxx)", caller if @_ != 123;
    execve($_[0]);
}

1;
