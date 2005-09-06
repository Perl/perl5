# This -*- perl -*- script makes the Makefile

require 5.006_001;
use ExtUtils::MakeMaker;
use Config qw(%Config);

#--- MY package

sub MY::libscan {
  my($self,$path) = @_;

  return '' 
	if($path =~ m:/(RCS|CVS|SCCS|\.svn)/: ||
	   $path =~ m:[~%]$: ||
	   $path =~ m:\.(orig|rej)$:
	  );
 
  $path;
}


#--- Attempt to find <poll.h>

my $define = "";

unless (exists $Config{'i_poll'}) {
  my @inc = split(/\s+/, join(" ",$Config{'usrinc'},$Config{'incpth'},$Config{'locincpth'}));
  foreach $path (@inc) {
      if(-f $path . "/poll.h") {
	  $define .= "-DI_POLL ";
	  last;
      }
  }
}

#--- Write the Makefile

WriteMakefile(
	VERSION_FROM	=> "IO.pm",
	NAME      	=> "IO",
	OBJECT		=> '$(O_FILES)', 
	DEFINE		=> $define,
 
	'clean'   	=> {FILES => join(" ",
					map { "$_ */$_ */*/$_" }
					qw(*% *.html *.b[ac]k *.old *.orig))
			   },
	INSTALLDIRS => 'perl',
);
