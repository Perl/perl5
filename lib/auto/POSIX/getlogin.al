# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub getlogin {
    usage "getlogin(xxx)", caller if @_ != 0;
    getlogin();
}

1;
