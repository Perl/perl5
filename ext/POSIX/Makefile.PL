use ExtUtils::MakeMaker;
use Config;
my @libs;
if ($^O ne 'MSWin32') {
    my $libs = "-lm -lposix -lcposix";
    $Config{gccversion} ne "" and $libs .= " -lgcc";
    @libs = ('LIBS' => [ $libs ]);
}
WriteMakefile(
    NAME	=> 'POSIX',
    @libs,
    MAN3PODS 	=> {}, 	# Pods will be built by installman.
    XSPROTOARG => '-noprototypes', 		# XXX remove later?
    VERSION_FROM => 'POSIX.pm', 
);
