=head1 NAME

buildext.pl - build extensions

=head1 SYNOPSIS

    buildext.pl "MAKE=make [-make_opts]" --dir=directory [--target=target] [--static|--dynamic|--all] +ext2 !ext1

E.g.

    buildext.pl "MAKE=nmake -nologo" --dir=..\ext

    buildext.pl "MAKE=nmake -nologo" --dir=..\ext --target=clean

    buildext.pl MAKE=dmake --dir=..\ext

    buildext.pl MAKE=dmake --dir=..\ext --target=clean

Will skip building extensions which are marked with an '!' char.
Mostly because they still not ported to specified platform.

If any extensions are listed with a '+' char then only those
extensions will be built, but only if they arent countermanded
by an '!ext' and are appropriate to the type of building being done.

If '--static' specified, only static extensions will be built.
If '--dynamic' specified, only dynamic extensions will be built.

=cut

use strict;
use Cwd;
use FindExt;
use Config;

# @ARGV with '!' at first position are exclusions
# @ARGV with '+' at first position are inclusions
# -- are long options.

my (%excl, %incl, %opts, @argv);

foreach (@ARGV) {
    if (/^!(.*)$/) {
	$excl{$1} = 1;
    } elsif (/^\+(.*)$/) {
	$incl{$1} = 1;
    } elsif (/^--([\w\-]+)$/) {
	$opts{$1} = 1;
    } elsif (/^--([\w\-]+)=(.*)$/) {
	$opts{$1} = $2;
    } else {
	push @argv, $_;
    }
}

my $static = $opts{static} || $opts{all};
my $dynamic = $opts{dynamic} || $opts{all};

my $makecmd = shift @argv;
my $dir  = $opts{dir} || 'ext';
my $targ = $opts{target};

my $make;
if (defined($makecmd) and $makecmd =~ /^MAKE=(.*)$/) {
	$make = $1;
}
else {
	print "$0:  WARNING:  Please include MAKE=\$(MAKE)\n";
	print "\tin your call to buildext.pl.  See buildext.pl for details.\n";
	exit(1);
}


(my $here = getcwd()) =~ s{/}{\\}g;
my $perl = $^X;
if ($perl =~ m#^\.\.#) {
    $perl = "$here\\$perl";
}
(my $topdir = $perl) =~ s/\\[^\\]+$//;
# miniperl needs to find perlglob and pl2bat
$ENV{PATH} = "$topdir;$topdir\\win32\\bin;$ENV{PATH}";
my $pl2bat = "$topdir\\win32\\bin\\pl2bat";
unless (-f "$pl2bat.bat") {
    my @args = ($perl, ("$pl2bat.pl") x 2);
    print "@args\n";
    system(@args) unless defined $::Cross::platform;
}

print "In ", getcwd();
chdir($dir) || die "Cannot cd to $dir\n";
(my $ext = getcwd()) =~ s{/}{\\}g;
my $code;
FindExt::scan_ext($ext);
FindExt::set_static_extensions(split ' ', $Config{static_ext});

my @ext;
push @ext, FindExt::static_ext() if $static;
push @ext, FindExt::dynamic_ext(), FindExt::nonxs_ext() if $dynamic;


foreach $dir (sort @ext)
 {
  if (%incl and !exists $incl{$dir}) {
    #warn "Skipping extension $ext\\$dir, not in inclusion list\n";
    next;
  }
  if (exists $excl{$dir}) {
    warn "Skipping extension $ext\\$dir, not ported to current platform";
    next;
  }
  if (chdir("$ext\\$dir"))
   {
    if (!-f 'Makefile')
     {
      print "\nRunning Makefile.PL in $dir\n";
      my @perl = ($perl, "-I$here\\..\\lib", 'Makefile.PL',
                  'INSTALLDIRS=perl', 'PERL_CORE=1',
		  (FindExt::is_static($dir)
                   ? ('LINKTYPE=static') : ()), # if ext is static
		);
      if (defined $::Cross::platform) {
	@perl = (@perl[0,1],"-MCross=$::Cross::platform",@perl[2..$#perl]);
      }
      print join(' ', @perl), "\n";
      $code = system(@perl);
      warn "$code from $dir\'s Makefile.PL" if $code;
     }  
    if (!$targ or $targ !~ /clean$/) {
	# Give makefile an opportunity to rewrite itself.
	# reassure users that life goes on...
	system("$make config")
	    and print "$make config failed, continuing anyway...\n";
    }
    if ($targ)
     {
      print "Making $targ in $dir\n$make $targ\n";
      $code = system("$make $targ");
      die "Unsuccessful make($dir): code=$code" if $code!=0;
     }
    else
     {
      print "Making $dir\n$make\n";
      $code = system($make);
      die "Unsuccessful make($dir): code=$code" if $code!=0;
     }
    chdir($here) || die "Cannot cd to $here:$!";
   }
  else
   {
    warn "Cannot cd to $ext\\$dir:$!";
   }
 }

