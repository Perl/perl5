# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub waitpid {
    usage "waitpid(pid, statusvariable, options)", caller if @_ != 3;
    local $result = waitpid($_[0], $_[2]);
    $_[1] = $?;
    $result;
}

1;
