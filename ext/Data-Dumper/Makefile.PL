use ExtUtils::MakeMaker;
WriteMakefile(
	NAME		=> "Data::Dumper",
	VERSION_FROM	=> 'Dumper.pm',
	'dist'		=> {
			     COMPRESS	=> 'gzip -9f',
	      		     SUFFIX	=> 'gz',
	      		     DIST_DEFAULT => 'all tardist',
			   },
        (
            (grep { $_ eq 'PERL_CORE=1' } @ARGV)
                ? ()
                : ('DEFINE' => '-DUSE_PPPORT_H')
        ),
);
