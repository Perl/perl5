use ExtUtils::MakeMaker;

WriteMakefile(
	NAME 	=> 'DB_File',
	LIBS 	=> ["-L/usr/local/lib -ldb"],
	#INC	=> '-I/usr/local/include',
	VERSION	=> 1.0,
	);

