use ExtUtils::MakeMaker;
WriteMakefile(
    NAME		=> 'File::Glob',
    VERSION_FROM	=> 'Glob.pm',
    MAN3PODS		=> {},     # Pods will be built by installman.
    OBJECT		=> 'bsd_glob$(OBJ_EXT) Glob$(OBJ_EXT)',

## uncomment for glob debugging (will cause make test to fail)
#   DEFINE		=> '-DGLOB_DEBUG',
#   OPTIMIZE		=> '-g',
);
