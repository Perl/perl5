# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub fgets {
    usage "fgets(filehandle)", caller if @_ != 1;
    local($handle) = @_;
    scalar <$handle>;
}

1;
