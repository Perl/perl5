# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub tcsetpgrp {
    unimpl "tcsetpgrp(xxx)", caller if @_ != 123;
    tcsetpgrp($_[0]);
}

1;
