use ExtUtils::MakeMaker;
WriteMakefile(LIBS => ["-lndbm", "-ldbm -lucb"]);
