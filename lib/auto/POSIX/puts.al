# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub puts {
    unimpl "puts() is C-specific--use print instead", caller;
    unimpl "puts(xxx)", caller if @_ != 123;
    puts($_[0]);
}

1;
