use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME' 		=> q(MacPerl),
    	'LINKTYPE'	=> ['static'],
	SKIP		=> [qw(dynamic dynamic_lib dynamic_bs)],
	'OBJECT'   	=> 'MacPerl.c XL.c OSA.c',
	'INC' 		=> "-i :::::XL:"
);
