package Fcntl;

require Exporter;
require AutoLoader;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default
# (move infrequently used names to @EXPORT_OK below)
@EXPORT =
  qw(
     F_DUPFD F_GETFD F_GETLK F_SETFD F_GETFL F_SETFL F_SETLK F_SETLKW
     FD_CLOEXEC F_RDLCK F_UNLCK F_WRLCK
     O_CREAT O_EXCL O_NOCTTY O_TRUNC
     O_APPEND O_NONBLOCK
     O_NDELAY
     O_RDONLY O_RDWR O_WRONLY
     );
# Other items we are prepared to export if requested
@EXPORT_OK = qw(
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
	    ($pack,$file,$line) = caller;
	    die "Your vendor has not defined Fcntl macro $constname, used at $file line $line.
";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap Fcntl;

# Preloaded methods go here.  Autoload methods go after __END__, and are
# processed by the autosplit program.
package Fcntl; # return to package Fcntl so AutoSplit is happy
1;
__END__
