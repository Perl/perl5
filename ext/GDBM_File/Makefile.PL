use ExtUtils::MakeMaker;
WriteMakefile(
    LIBS => ["-L/usr/local/lib -lgdbm", "-ldbm"],
    MAN3PODS 	=> ' ', 	# Pods will be built by installman.
    XSPROTOARG => '-noprototypes', 		# XXX remove later?
    VERSION_FROM => 'GDBM_File.pm',
);
