package GDBM_File;

require Carp;
require TieHash;
require Exporter;
require AutoLoader;
require DynaLoader;
@ISA = qw(TieHash Exporter DynaLoader);
@EXPORT = qw(
	GDBM_CACHESIZE
	GDBM_FAST
	GDBM_INSERT
	GDBM_NEWDB
	GDBM_READER
	GDBM_REPLACE
	GDBM_WRCREAT
	GDBM_WRITER
);

sub AUTOLOAD {
    local($constname);
    ($constname = $AUTOLOAD) =~ s/.*:://;
    $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    Carp::croak("Your vendor has not defined GDBM_File macro $constname, used");
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap GDBM_File;

# Preloaded methods go here.  Autoload methods go after __END__, and are
# processed by the autosplit program.

1;
__END__
