# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub gets {
    usage "gets(handle)", caller if @_ != 1;
    local($handle) = shift;
    scalar <$handle>;
}

1;
