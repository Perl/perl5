use ExtUtils::MakeMaker;
WriteMakefile(LIBS => ["-ldbm.nfs", "-ldbm -lucb"]);
