use ExtUtils::MakeMaker;
use ExtUtils::Constant 0.07 'WriteConstants';
WriteMakefile(
    NAME => 'GDBM_File',
    LIBS => ["-L/usr/local/lib -lgdbm", "-ldbm"],
    MAN3PODS 	=> {}, 	# Pods will be built by installman.
    XSPROTOARG => '-noprototypes', 		# XXX remove later?
    VERSION_FROM => 'GDBM_File.pm',
    realclean => {FILES=> 'constants.c constants.xs'},
);
WriteConstants(
    NAME => 'GDBM_File',
    DEFAULT_TYPE => 'IV',
    BREAKOUT_AT => 8,
    NAMES => [qw(GDBM_CACHESIZE GDBM_FAST GDBM_FASTMODE GDBM_INSERT GDBM_NEWDB
                 GDBM_NOLOCK GDBM_READER GDBM_REPLACE GDBM_WRCREAT
                 GDBM_WRITER)],
);
