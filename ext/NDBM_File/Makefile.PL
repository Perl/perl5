use ExtUtils::MakeMaker;
WriteMakefile(LIBS => ["-L/usr/local/lib -lndbm", "-ldbm -lucb"]);
