use ExtUtils::MakeMaker;
WriteMakefile(
    VERSION => 1.5,
    MAN3PODS 	=> ' ', 	# Pods will be built by installman.
    XSPROTOARG => '-noprototypes', 		# XXX remove later?
);
