use ExtUtils::MakeMaker;
use Config qw(%Config);

#--- Attempt to find <poll.h>

my $define = "";

my @inc = split(/\s+/, join(" ",$Config{'usrinc'},$Config{'incpth'},$Config{'locincpth'}));
foreach $path (@inc) {
    if(-f $path . "/poll.h") {
	$define .= "-DI_POLL ";
	last;
    }
}

#--- Write the Makefile

WriteMakefile(
	VERSION_FROM	=> "IO.pm",
	NAME      	=> "IO",
	OBJECT		=> '$(O_FILES)', 
	DEFINE		=> $define,
	MAN3PODS	=> {},		# Pods will be built by installman.
);
