use ExtUtils::MakeMaker;
WriteMakefile(LIBS => ["-L/usr/local/lib -lgdbm", "-ldbm"]);
