use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME => 'OS2::REXX',
	      VERSION => '0.2',
	      MAN3PODS 	=> ' ', 	# Pods will be built by installman.
	      XSPROTOARG => '-noprototypes',
);
