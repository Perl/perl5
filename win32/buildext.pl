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
require FindExt;
use Config;

# @ARGV with '!' at first position are exclusions
# @ARGV with '+' at first position are inclusions
# -- are long options.

my (%excl, %incl, %opts, @extspec, @pass_through);

foreach (@ARGV) {
    if (/^!(.*)$/) {
	$excl{$1} = 1;
    } elsif (/^\+(.*)$/) {
	$incl{$1} = 1;
    } elsif (/^--([\w\-]+)$/) {
	$opts{$1} = 1;
    } elsif (/^--([\w\-]+)=(.*)$/) {
	$opts{$1} = $2;
    } elsif (/=/) {
	push @pass_through, $_;
    } else {
	push @extspec, $_;
    }
}

my $static = $opts{static} || $opts{all};
my $dynamic = $opts{dynamic} || $opts{all};

my $makecmd = shift @pass_through;
unshift @pass_through, 'PERL_CORE=1';

my $dir  = $opts{dir} || 'ext';
my $target = $opts{target};
$target = 'all' unless defined $target;

my $make;
if (defined($makecmd) and $makecmd =~ /^MAKE=(.*)$/) {
	$make = $1;
}
else {
	print "$0:  WARNING:  Please include MAKE=\$(MAKE)\n";
	print "\tin your call to buildext.pl.  See buildext.pl for details.\n";
	exit(1);
}

# Strip whitespace at end of $make to ease passing of (potentially empty) parameters
$make =~ s/\s+$//;

# fallback to config.sh's MAKE
$make ||= $Config{make} || $ENV{MAKE};
my @run = $Config{run};
@run = () if not defined $run[0] or $run[0] eq '';

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

  build_extension($ext, "$ext\\$dir", $here, "$here\\..\\lib",
		  [@pass_through,
		   FindExt::is_static($dir) ? ('LINKTYPE=static') : ()]);
 }

sub build_extension {
    my ($ext, $ext_dir, $return_dir, $lib_dir, $pass_through) = @_;
    unless (chdir "$ext_dir") {
	warn "Cannot cd to $ext_dir: $!";
	return;
    }
    
    if (!-f 'Makefile') {
	print "\nRunning Makefile.PL in $ext_dir\n";

	# Presumably this can be simplified
	my @cross;
	if (defined $::Cross::platform) {
	    # Inherited from win32/buildext.pl
	    @cross = "-MCross=$::Cross::platform";
	} elsif ($opts{cross}) {
	    # Inherited from make_ext.pl
	    @cross = '-MCross';
	}
	    
	my @perl = (@run, $perl, "-I$lib_dir", @cross, 'Makefile.PL',
		    'INSTALLDIRS=perl', 'INSTALLMAN3DIR=none', 'PERL_CORE=1',
		    @$pass_through);
	print join(' ', @perl), "\n";
	my $code = system @perl;
	warn "$code from $ext_dir\'s Makefile.PL" if $code;
    }
    if (!$target or $target !~ /clean$/) {
	# Give makefile an opportunity to rewrite itself.
	# reassure users that life goes on...
	my @config = (@run, $make, 'config', @$pass_through);
	system @config and print "@config failed, continuing anyway...\n";
    }
    my @targ = (@run, $make, $target, @$pass_through);
    print "Making $target in $ext_dir\n@targ\n";
    my $code = system @targ;
    die "Unsuccessful make($ext_dir): code=$code" if $code != 0;

    chdir $return_dir || die "Cannot cd to $return_dir: $!";
}
