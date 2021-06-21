use strict;
use ExtUtils::MakeMaker;

our @LIBS;
if( $^O eq 'msys' ) {
    @LIBS = ("-lgdbm -lgdbm_compat");
} else {
    @LIBS = ("-ldbm -lucb");
};

WriteMakefile(
    NAME	=> 'ODBM_File',
    LIBS => \@LIBS,
    XSPROTOARG => '-noprototypes', 		# XXX remove later?
    VERSION_FROM => 'ODBM_File.pm', 
);
