# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub opendir {
    usage "opendir(directory)", caller if @_ != 1;
    local($dirhandle) = &gensym;
    opendir($dirhandle, $_[0])
	? $dirhandle
	: (ungensym($dirhandle), undef);
}

1;
