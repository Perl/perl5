# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub tcgetpgrp {
    unimpl "tcgetpgrp(xxx)", caller if @_ != 123;
    tcgetpgrp($_[0]);
}

1;
