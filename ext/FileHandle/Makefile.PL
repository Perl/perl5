use ExtUtils::MakeMaker;
WriteMakefile(
    MAN3PODS   => ' ',			# Pods will be built by installman.
    XSPROTOARG => '-noprototypes', 	# XXX remove later?
);
