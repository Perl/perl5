#!./miniperl
use strict;
use warnings;
use Config;
use Cwd;

# This script acts as a simple interface for building extensions.

# It's actually a cut and shut of the Unix version ext/utils/makeext and the
# Windows version win32/build_ext.pl hence the two invocation styles.

# On Unix, it primarily used by the perl Makefile one extention at a time:
#
# d_dummy $(dynamic_ext): miniperl preplibrary FORCE
# 	@$(RUN) ./miniperl make_ext.pl --target=dynamic $@ MAKE=$(MAKE) LIBPERL_A=$(LIBPERL)
#
# On Windows,
# If '--static' is specified, static extensions will be built.
# If '--dynamic' is specified, dynamic (and nonxs) extensions will be built.
# If '--all' is specified, all extensions will be built.
#
#    make_ext.pl "MAKE=make [-make_opts]" --dir=directory [--target=target] [--static|--dynamic|--all] +ext2 !ext1
#
# E.g.
# 
#     make_ext.pl "MAKE=nmake -nologo" --dir=..\ext
# 
#     make_ext.pl "MAKE=nmake -nologo" --dir=..\ext --target=clean
# 
#     make_ext.pl MAKE=dmake --dir=..\ext
# 
#     make_ext.pl MAKE=dmake --dir=..\ext --target=clean
# 
# Will skip building extensions which are marked with an '!' char.
# Mostly because they still not ported to specified platform.
# 
# If any extensions are listed with a '+' char then only those
# extensions will be built, but only if they arent countermanded
# by an '!ext' and are appropriate to the type of building being done.

# It may be deleted in a later release of perl so try to
# avoid using it for other purposes.

my $is_Win32 = $^O eq 'MSWin32';
my $is_VMS = $^O eq 'VMS';
my $is_Unix = !$is_Win32 && !$is_VMS;

require FindExt if $is_Win32;

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
    } elsif (length) {
	push @extspec, $_;
    }
}

my $static = $opts{static} || $opts{all};
my $dynamic = $opts{dynamic} || $opts{all};

# The Perl Makefile.SH will expand all extensions to
#	lib/auto/X/X.a  (or lib/auto/X/Y/Y.a if nested)
# A user wishing to run make_ext might use
#	X (or X/Y or X::Y if nested)

# canonise into X/Y form (pname)

foreach (@extspec) {
    if (/^lib/) {
	# Remove lib/auto prefix and /*.* suffix
	s{^lib/auto/}{};
	s{[^/]*\.[^/]*$}{};
    } elsif (/^ext/) {
	# Remove ext/ prefix and /pm_to_blib suffix
	s{^ext/}{};
	s{/pm_to_blib$}{};
    } elsif (/::/) {
	# Convert :: to /
	s{::}{\/}g;
    } elsif (/\..*o$/) {
	s/\..*o//;
    }
}

my $makecmd  = shift @pass_through; # Should be something like MAKE=make
unshift @pass_through, 'PERL_CORE=1';

my $dir  = $opts{dir} || 'ext';
my $target   = $opts{target};
$target = 'all' unless defined $target;

# Previously, $make was taken from config.sh.  However, the user might
# instead be running a possibly incompatible make.  This might happen if
# the user types "gmake" instead of a plain "make", for example.  The
# correct current value of MAKE will come through from the main perl
# makefile as MAKE=/whatever/make in $makecmd.  We'll be cautious in
# case third party users of this script (are there any?) don't have the
# MAKE=$(MAKE) argument, which was added after 5.004_03.
unless(defined $makecmd and $makecmd =~ /^MAKE=(.*)$/) {
    die "$0:  WARNING:  Please include MAKE=\$(MAKE) in \@ARGV\n";
}

# This isn't going to cope with anything fancy, such as spaces inside command
# names, but neither did what it replaced. Once there is a use case that needs
# it, please supply patches. Until then, I'm sticking to KISS
my @make = split ' ', $1 || $Config{make} || $ENV{MAKE};
# Using an array of 0 or 1 elements makes the subsequent code simpler.
my @run = $Config{run};
@run = () if not defined $run[0] or $run[0] eq '';


if ($target eq '') {
    die "make_ext: no make target specified (eg all or clean)\n";
} elsif ($target !~ /(?:^all|clean)$/) {
    # for the time being we are strict about what make_ext is used for
    die "$0: unknown make target '$target'\n";
}

if (!@extspec and !$static and !$dynamic)  {
    die "$0: no extension specified\n";
}

my $perl;
my %extra_passthrough;

if ($is_Win32) {
    (my $here = getcwd()) =~ s{/}{\\}g;
    $perl = $^X;
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

    foreach (sort @ext) {
	if (%incl and !exists $incl{$_}) {
	    #warn "Skipping extension $ext\\$_, not in inclusion list\n";
	    next;
	}
	if (exists $excl{$_}) {
	    warn "Skipping extension $ext\\$_, not ported to current platform";
	    next;
	}
	push @extspec, $_;
	if(FindExt::is_static($_)) {
	    push @{$extra_passthrough{$_}}, 'LINKTYPE=static';
	}
    }
    chdir '..'; # now in the Perl build directory
}

foreach my $spec (@extspec)  {
    my $mname = $spec;
    $mname =~ s!/!::!g;
    my $ext_pathname = "ext/$spec";
    my $up = $ext_pathname;
    $up =~ s![^/]+!..!g;

    if ($Config{osname} eq 'catamount') {
	# Snowball's chance of building extensions.
	die "This is $Config{osname}, not building $mname, sorry.\n";
    }

    print "\tMaking $mname ($target)\n";

    build_extension('ext', $ext_pathname, $up, $perl || "$up/miniperl",
		    "$up/lib",
		    [@pass_through, @{$extra_passthrough{$spec} || []}]);
}

sub build_extension {
    my ($ext, $ext_dir, $return_dir, $perl, $lib_dir, $pass_through) = @_;
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
		    'INSTALLDIRS=perl', 'INSTALLMAN3DIR=none',
		    @$pass_through);
	print join(' ', @perl), "\n";
	my $code = system @perl;
	warn "$code from $ext_dir\'s Makefile.PL" if $code;

	# Right. The reason for this little hack is that we're sitting inside
	# a program run by ./miniperl, but there are tasks we need to perform
	# when the 'realclean', 'distclean' or 'veryclean' targets are run.
	# Unfortunately, they can be run *after* 'clean', which deletes
	# ./miniperl
	# So we do our best to leave a set of instructions identical to what
	# we would do if we are run directly as 'realclean' etc
	# Whilst we're perfect, unfortunately the targets we call are not, as
	# some of them rely on a $(PERL) for their own distclean targets.
	# But this always used to be a problem with the old /bin/sh version of
	# this.
	if ($is_Unix) {
	    my $suffix = '.sh';
	    foreach my $clean_target ('realclean', 'veryclean') {
		my $file = "$return_dir/$clean_target$suffix";
		open my $fh, '>>', $file or die "open $file: $!";
		# Quite possible that we're being run in parallel here.
		# Can't use Fcntl this early to get the LOCK_EX
		flock $fh, 2 or warn "flock $file: $!";
		print $fh <<"EOS";
cd $ext_dir
if test ! -f Makefile -a -f Makefile.old; then
    echo "Note: Using Makefile.old"
    make -f Makefile.old $clean_target MAKE='@make' @pass_through
else
    if test ! -f Makefile ; then
	echo "Warning: No Makefile!"
    fi
    make $clean_target MAKE='@make' @pass_through
fi
cd $return_dir
EOS
		close $fh or die "close $file: $!";
	    }
	}
    }

    if (not -f 'Makefile') {
	print "Warning: No Makefile!\n";
    }

    if (!$target or $target !~ /clean$/) {
	# Give makefile an opportunity to rewrite itself.
	# reassure users that life goes on...
	my @config = (@run, @make, 'config', @$pass_through);
	system @config and print "@config failed, continuing anyway...\n";
    }
    my @targ = (@run, @make, $target, @$pass_through);
    print "Making $target in $ext_dir\n@targ\n";
    my $code = system @targ;
    die "Unsuccessful make($ext_dir): code=$code" if $code != 0;

    chdir $return_dir || die "Cannot cd to $return_dir: $!";
}
