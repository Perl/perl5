use ExtUtils::MakeMaker;
WriteMakefile(
	NAME		=> "Encode",
	VERSION_FROM	=> 'Encode.pm',
	'dist'		=> {
			     COMPRESS	=> 'gzip -9f',
	      		     SUFFIX	=> 'gz',
	      		     DIST_DEFAULT => 'all tardist',
			   },
	MAN3PODS	=> {},
);
