# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub wait {
    usage "wait(statusvariable)", caller if @_ != 1;
    local $result = wait();
    $_[0] = $?;
    $result;
}

1;
