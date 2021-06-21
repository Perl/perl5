use strict;
use ExtUtils::MakeMaker;

our @LIBS;
if( $^O eq 'msys' ) {
    @LIBS = ("-lgdbm -lgdbm_compat");
} else {
    @LIBS = ("-L/usr/local/lib -lndbm", "-ldbm -lucb");
};

WriteMakefile(
    NAME	=> 'NDBM_File',
    LIBS => \@LIBS,
    XSPROTOARG => '-noprototypes', 		# XXX remove later?
    VERSION_FROM => 'NDBM_File.pm',
);
