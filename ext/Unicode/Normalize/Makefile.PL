use ExtUtils::MakeMaker;

# This is not the CPAN Unicode::Normalize makefile
# that can handle XS-NOXS installing.  We do just XS.

do "mkheader";

unless($ENV{PERL_CORE}) {
    $ENV{PERL_CORE} = 1 if grep { $_ eq 'PERL_CORE=1' } @ARGV;
}
if ($ENV{PERL_CORE}) {
    # Pods will be built by installman.
    @coreopts = ( MAN3PODS => {} );
}
else {
    @coreopts = ();
}

WriteMakefile(
    'NAME'		=> 'Unicode::Normalize',
    'VERSION_FROM'	=> 'Normalize.pm', # finds $VERSION
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Normalize.pm', # retrieve abstract from module
       AUTHOR     => 'SADAHIRO Tomoyuki <SADAHIRO@cpan.org>') : ()),
    clean => {FILES=> 'unfcan.h unfcmb.h unfcmp.h unfcpt.h unfexc.h'},
    @coreopts,
);
