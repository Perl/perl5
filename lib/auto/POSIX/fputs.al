# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub fputs {
    unimpl "fputs() is C-specific--use print instead", caller;
    usage "fputs(string, handle)", caller if @_ != 2;
    local($handle) = pop;
    print $handle @_;
}

1;
