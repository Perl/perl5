# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub perror {
    unimpl "perror() is C-specific--print $! instead", caller;
    unimpl "perror(xxx)", caller if @_ != 123;
    perror($_[0]);
}

1;
