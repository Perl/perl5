use ExtUtils::MakeMaker;
WriteMakefile(
    LIBS => ["-L/usr/local/lib -lndbm", "-ldbm -lucb"],
    MAN3PODS 	=> ' ', 	# Pods will be built by installman.
    XSPROTOARG => '-noprototypes', 		# XXX remove later?
    VERSION_FROM => 'NDBM_File.pm',
);
