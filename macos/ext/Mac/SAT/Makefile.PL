use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> q(Mac::SAT),
	'VERSION_FROM'		=> 'SAT.pm',
	'LIBS'			=> [':SAT:lib:SAT(PPC).lib SATDummyCFM68KLib'],
	TYPEMAPS		=> '::QuickDraw:typemap',
	'INC'			=> "-i :SAT:include"
);
