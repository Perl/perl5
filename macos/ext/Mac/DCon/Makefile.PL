use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> q(Mac::DCon),
	'VERSION_FROM'		=> 'DCon.pm',
	'LIBS'			=>  [':DCon:Libraries:DConCWPPC.lib DConDummyCFM68KLib'],
	'INC'			=> "-i :DCon:Headers"
);
