package ExtUtils::MakeMaker;

$Version = 4.16; # Last edited $Date: 1995/06/18 16:04:00 $ by Tim Bunce

$Version_OK = 4.13;	# Makefiles older than $Version_OK will die
			# (Will be checked from MakeMaker version 4.13 onwards)

# $Id: MakeMaker.pm,v 1.21 1995/06/06 06:14:16 k Exp k $

use Config;
use Carp;
use Cwd;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(&WriteMakefile $Verbose &prompt);
@EXPORT_OK = qw($Version &Version_check %att %skip %Recognized_Att_Keys
	@MM_Sections %MM_Sections
	&help &neatvalue &mkbootstrap &mksymlists);

$Is_VMS = $Config{'osname'} eq 'VMS';
require ExtUtils::MM_VMS if $Is_VMS;

use strict qw(refs);

$Version = $Version;# avoid typo warning
$Verbose = 0;
$^W=1;

sub prompt {
    my($mess,$def)=@_;
    local $\="";
    local $/="\n";
    local $|=1;
    die "prompt function called without an argument" unless defined $mess;
    $def = "" unless defined $def;
    my $dispdef = "[$def] ";
    print "$mess $dispdef";
    chop(my $ans = <STDIN>);
    $ans || $def;
}

sub check_hints {
    # We allow extension-specific hints files.

    # First we look for the best hintsfile we have
    my(@goodhints);
    my($hint)="$Config{'osname'}_$Config{'osvers'}";
    $hint =~ s/\./_/g;
    $hint =~ s/_$//;
    local(*DIR);
    opendir DIR, "hints";
    while (defined ($_ = readdir DIR)) {
	next if /^\./;
	next unless s/\.pl$//;
	next unless /^$Config{'osname'}/;
	# Don't trust a hintfile for a later OS version:
	next if $_ gt $hint;
	push @goodhints, $_;
	if ($_ eq $hint){
	    @goodhints=$_;
	    last;
	}
    }
    closedir DIR;
    return unless @goodhints; # There was no hintsfile
    # the last one in lexical ordering is our choice:
    $hint=(sort @goodhints)[-1];

    # execute the hintsfile:
    open HINTS, "hints/$hint.pl";
    @goodhints = <HINTS>;
    close HINTS;
    print STDOUT "Processing hints file hints/$hint.pl";
    eval join('',@goodhints);
    print STDOUT $@ if $@;
}

# Setup dummy package:
# MY exists for overriding methods to be defined within
unshift(@MY::ISA, qw(MM));

# Dummy package MM inherits actual methods from OS-specific
# default packages.  We use this intermediate package so
# MY->func() can call MM->func() and get the proper
# default routine without having to know under what OS
# it's running.
unshift(@MM::ISA, $Is_VMS ? qw(ExtUtils::MM_VMS MM_Unix) : qw(MM_Unix));

$Attrib_Help = <<'END';
 NAME:		Perl module name for this extension (DBD::Oracle)
		This will default to the directory name but should
		be explicitly defined in the Makefile.PL.

 DISTNAME:	Your name for distributing the package (by tar file)
		This defaults to NAME above.

 VERSION:	Your version number for distributing the package.
		This defaults to 0.1.

 INST_LIB:	Perl library directory to directly install
		into during 'make'.

 INSTALLPRIVLIB:Used by 'make install', which sets INST_LIB to this value.

 INST_ARCHLIB:	Perl architecture-dependent library to directly install
		into during 'make'.

 INSTALLARCHLIB:Used by 'make install', which sets INST_ARCHLIB to this value.

 INST_EXE:	Directory, where executable scripts should be installed during
		'make'. Defaults to "./blib", just to have a dummy location
		during testing. C<make install> will set INST_EXE to INSTALLBIN.

 INSTALLBIN:	Used by 'make install' which sets INST_EXE to this value.

 PERL_LIB:	Directory containing the Perl library to use.

 PERL_ARCHLIB:	Architectur dependent directory containing the Perl library to use.

 PERL_SRC:	Directory containing the Perl source code
		(use of this should be avoided, it may be undefined)

 INC:		Include file dirs eg: '-I/usr/5include -I/path/to/inc'

 DEFINE:	something like "-DHAVE_UNISTD_H"

 OBJECT:	List of object files, defaults to '$(BASEEXT).o',
		but can be a long string containing all object files,
		    e.g. "tkpBind.o tkpButton.o tkpCanvas.o"

 MYEXTLIB:	If the extension links to a library that it builds
		set this to the name of the library (see SDBM_File)

 LIBS:		An anonymous array of alternative library specifications
		to be searched for (in order) until at least one library
		is found.
		  'LIBS' => [ "-lgdbm", "-ldbm -lfoo", "-L/path -ldbm.nfs" ]
		Mind, that any element of the array contains a complete
		set of arguments for the ld command. So do not specify
		  'LIBS' => ["-ltcl", "-ltk", "-lX11" ], #wrong
		See ODBM_File/Makefile.PL for an example, where an
		array is needed. If you specify a scalar as in
		  'LIBS' => "-ltcl -ltk -lX11"
		MakeMaker will turn it into an array with one element.

 LDFROM:	defaults to "$(OBJECT)" and is used in the ld command
		to specify what files to link/load from
		(also see dynamic_lib below for how to specify ld flags)

 DIR:		Ref to array of subdirectories containing Makefile.PLs
		e.g. [ 'sdbm' ] in ext/SDBM_File

 PMLIBDIRS:	Ref to array of subdirectories containing library files.
		Defaults to [ 'lib', $(BASEEXT) ]. The directories will
		be scanned and any files they contain will
		be installed in the corresponding location in the library.
		A MY::libscan() function can be used to alter the behaviour.
		Defining PM in the Makefile.PL will override PMLIBDIRS.

 PM:		Hashref of .pm files and *.pl files to be installed.
		e.g. { 'name_of_file.pm' => '$(INST_LIBDIR)/install_as.pm' }
		By default this will include *.pm and *.pl. If a lib directory
		exists and is not listed in DIR (above) then any *.pm and
		*.pl files it contains will also be included by default.
		Defining PM in the Makefile.PL will override PMLIBDIRS.

 XS:		Hashref of .xs files. MakeMaker will default this.
		e.g. { 'name_of_file.xs' => 'name_of_file.c' }
		The .c files will automatically be included in the list
		of files deleted by a make clean.

 C:		Ref to array of *.c file names. Initialised from a directory scan
		and the values portion of the XS attribute hash. This is not
		currently used by MakeMaker but may be handy in Makefile.PLs.

 H:		Ref to array of *.h file names. Similar to C: above.

 PL_FILES:      Ref to hash of files to be processed as perl programs. MakeMaker
		will default to any found C<*.PL> file (except C<Makefile.PL>) being
		keys and the basename of the file being the value. E.g.
		C<{ 'foobar.PL' => 'foobar' }>. The C<*.PL> files are expected to
		produce output to the target files themselves.

 EXE_FILES:	Ref to array of executable files. The files will be copied to 
		the INST_EXE directory. Make realclean will delete them from
		there again.

 LINKTYPE:	=>'static' or 'dynamic' (default unless usedl=undef in config.sh)
		Should only be used to force static linking (also see linkext below).

 DL_FUNCS:	Hashref of symbol names for routines to be made available as
		universal symbols.  Each key/value pair consists of the package
		name and an array of routine names in that package.  Used only
		under AIX (export lists) and VMS (linker options) at present.
		The routine names supplied will be expanded in the same way
		as XSUB names are expanded by the XS() macro.
		Defaults to { "$(NAME)" => [ "boot_$(NAME)" ] }.
		(e.g. { "RPC" => [qw( boot_rpcb rpcb_gettime getnetconfigent )],
		        "NetconfigPtr" => [ 'DESTROY'] } )

 DL_VARS:	Array of symbol names for variables to be made available as
		universal symbols.  Used only under AIX (export lists) and VMS
		(linker options) at present.  Defaults to [].
		(e.g. [ qw( Foo_version Foo_numstreams Foo_tree ) ])

 CONFIG:	=>[qw(archname manext)] defines ARCHNAME & MANEXT from config.sh

 SKIP:  	=>[qw(name1 name2)] skip (do not write) sections of the Makefile

 MAP_TARGET:	If it is intended, that a new perl binary be produced, this variable
		may hold a name for that binary. Defaults to C<perl>

 LIBPERL_A: 	The filename of the perllibrary that will be used together
		with this extension. Defaults to C<libperl.a>.

 PERL:
 FULLPERL:

Additional lowercase attributes can be used to pass parameters to the
methods which implement that part of the Makefile. These are not
normally required:

 macro:		{ANY_MACRO => ANY_VALUE, ...}
 installpm:	{SPLITLIB => '$(INST_LIB)' (default) or '$(INST_ARCHLIB)'}
 linkext:	{LINKTYPE => 'static', 'dynamic' or ''}
 dynamic_lib:	{ARMAYBE => 'ar', OTHERLDFLAGS => '...'}
 clean:		{FILES => "*.xyz foo"}
 realclean:	{FILES => '$(INST_ARCHAUTODIR)/*.xyz'}
 dist:		{TARFLAGS=>'cvfF', COMPRESS=>'gzip', SUFFIX=>'gz', SHAR=>'shar -m'}
 tool_autosplit:	{MAXLEN => 8}
END

sub help {print $Attrib_Help;}

@MM_Sections_spec = (
    'post_initialize'	=> {},
    'const_config'	=> {},
    'constants'		=> {},
    'const_loadlibs'	=> {},
    'const_cccmd'	=> {},
    'tool_autosplit'	=> {},
    'tool_xsubpp'	=> {},
    'tools_other'	=> {},
    'macro'		=> {},
    'post_constants'	=> {},
    'pasthru'		=> {},
    'c_o'		=> {},
    'xs_c'		=> {},
    'xs_o'		=> {},
    'top_targets'	=> {},
    'linkext'		=> {},
    'dlsyms'		=> {},
    'dynamic'		=> {},
    'dynamic_bs'	=> {},
    'dynamic_lib'	=> {},
    'static'		=> {},
    'static_lib'	=> {},
    'installpm'		=> {},
    'processPL'		=> {},
    'installbin'	=> {},
    'subdirs'		=> {},
    'clean'		=> {},
    'realclean'		=> {},
    'dist'		=> {},
    'install'		=> {},
    'force'		=> {},
    'perldepend'	=> {},
    'makefile'		=> {},
    'staticmake'	=> {},	# Sadly this defines more macros
    'test'		=> {},
    'postamble'		=> {},	# should always be last
);
%MM_Sections = @MM_Sections_spec; # looses section ordering
@MM_Sections = grep(!ref, @MM_Sections_spec); # keeps order

%Recognized_Att_Keys = %MM_Sections; # All sections are valid keys.
foreach(split(/\n/,$Attrib_Help)){
    chomp;
    next unless m/^\s*(\w+):\s*(.*)/;
    $Recognized_Att_Keys{$1} = $2;
    print "Attribute '$1' => '$2'\n" if ($Verbose >= 2);
}

%att  = ();
%skip = ();

sub skipcheck{
    my($section) = @_;
    if ($section eq 'dynamic') {
	print STDOUT "Warning (non-fatal): Target 'dynamic' depends on targets "
	  . "in skipped section 'dynamic_bs'\n"
            if $skip{'dynamic_bs'} && $Verbose;
        print STDOUT "Warning (non-fatal): Target 'dynamic' depends on targets "
	  . "in skipped section 'dynamic_lib'\n"
            if $skip{'dynamic_lib'} && $Verbose;
    }
    if ($section eq 'dynamic_lib') {
        print STDOUT "Warning (non-fatal): Target '\$(INST_DYNAMIC)' depends on "
	  . "targets in skipped section 'dynamic_bs'\n"
            if $skip{'dynamic_bs'} && $Verbose;
    }
    if ($section eq 'static') {
        print STDOUT "Warning (non-fatal): Target 'static' depends on targets "
	  . "in skipped section 'static_lib'\n"
            if $skip{'static_lib'} && $Verbose;
    }
    return 'skipped' if $skip{$section};
    return '';
}


sub WriteMakefile {
    %att = @_;
    local($\)="\n";

    print STDOUT "MakeMaker (v$Version)" if $Verbose;

    if ( Carp::longmess("") =~ "runsubdirpl" ){
	$Correct_relativ_directories++;
    } else {
	$Correct_relativ_directories=0;
    }

    if (-f "MANIFEST"){
	eval {require ExtUtils::Manifest};
	if ($@){
	    print STDOUT "Warning: you have not installed the ExtUtils::Manifest
         module -- skipping check of the MANIFEST file";
	} else {
	    print STDOUT "Checking if your kit is complete...";
	    $ExtUtils::Manifest::Quiet=$ExtUtils::Manifest::Quiet=1; #avoid warning
	    my(@missed)=ExtUtils::Manifest::manicheck();
	    if (@missed){
		print STDOUT "Warning: the following files are missing in your kit:";
		print "\t", join "\n\t", @missed;
		print STDOUT "Please inform the author.\n";
	    } else {
		print STDOUT "Looks good";
	    }
	}
    }

    parse_args(\%att, @ARGV);
    my(%initial_att) = %att; # record initial attributes

    check_hints();

    my($key);

    MY->init_main();

    print STDOUT "Writing Makefile for $att{NAME}";

    if (! $att{PERL_SRC} && 
	$INC{'Config.pm'} ne "$Config{'archlib'}/Config.pm"){
	(my $pthinks = $INC{'Config.pm'}) =~ s!/Config\.pm$!!;
	$pthinks =~ s!.*/!!;
	print STDOUT <<END;
Your perl and your Config.pm seem to have different ideas about the architecture
they are running on.
Perl thinks: $pthinks
Config says: $Config{"archname"}
This may or may not cause problems. Please check your installation of perl if you
have problems building this extension.
END
    }

    MY->init_dirscan();
    MY->init_others();

    unlink("Makefile", "MakeMaker.tmp", $Is_VMS ? 'Descrip.MMS' : '');
    open MAKE, ">MakeMaker.tmp" or die "Unable to open MakeMaker.tmp: $!";
    select MAKE; $|=1; select STDOUT;

    print MAKE "# This Makefile is for the $att{NAME} extension to perl.\n#";
    print MAKE "# It was generated automatically by MakeMaker version $Version from the contents";
    print MAKE "# of Makefile.PL. Don't edit this file, edit Makefile.PL instead.";
    print MAKE "#\n#	ANY CHANGES MADE HERE WILL BE LOST! \n#";
    print MAKE "#   MakeMaker Parameters: ";
    foreach $key (sort keys %initial_att){
	my($v) = neatvalue($initial_att{$key});
	$v =~ tr/\n/ /s;
	print MAKE "#	$key => $v";
    }

    # build hash for SKIP to make testing easy
    %skip = map( ($_,1), @{$att{'SKIP'} || []});

    my $section;
    foreach $section ( @MM_Sections ){
	print "Processing Makefile '$section' section" if ($Verbose >= 2);
	my($skipit) = skipcheck($section);
	if ($skipit){
	    print MAKE "\n# --- MakeMaker $section section $skipit.";
	} else {
	    my(%a) = %{$att{$section} || {}};
	    print MAKE "\n# --- MakeMaker $section section:";
	    print MAKE "# ", join ", ", %a if $Verbose;
	    print(MAKE MY->nicetext(MY->$section( %a )));
	}
    }

    if ($Verbose){
	print MAKE "\n# Full list of MakeMaker attribute values:";
	foreach $key (sort keys %att){
	    my($v) = neatvalue($att{$key});
	    $v =~ tr/\n/ /s;
	    print MAKE "#	$key => $v";
	}
    }

    print MAKE "\n# End.";
    close MAKE;
    my($finalname) = $Is_VMS ? "Descrip.MMS" : "Makefile";
    rename("MakeMaker.tmp", $finalname);

    chmod 0644, $finalname;
    system("$Config{'eunicefix'} $finalname") unless $Config{'eunicefix'} eq ":";

    1;
}

sub Version_check {
    my($checkversion) = @_;
    die "Your Makefile was built with ExtUtils::MakeMaker v $checkversion.
Current Version is $Version. There have been considerable changes in the meantime.
Please rerun 'perl Makefile.PL' to regenerate the Makefile.\n" if $checkversion < $Version_OK;
    print STDOUT "Makefile built with ExtUtils::MakeMaker v $checkversion. Current Version is $Version." unless $checkversion == $Version;
}

sub mksymlists{
    %att = @_;
    parse_args(\%att, @ARGV);
    MY->mksymlists(@_);
}

# The following mkbootstrap() is only for installations that are calling
# the pre-4.1 mkbootstrap() from their old Makefiles. This MakeMaker
# write Makefiles, that use ExtUtils::Mkbootstrap directly.
sub mkbootstrap{
    parse_args(\%att, @ARGV);
    MY->init_main() unless defined $att{BASEEXT};
    eval {require ExtUtils::Mkbootstrap};
    if ($@){
	# Very difficult to arrive here, I suppose
	carp "Error: $@\nVersion mismatch: This MakeMaker (v$Version) needs the ExtUtils::Mkbootstrap package. Please check your installation.";
    }
    ExtUtils::Mkbootstrap::Mkbootstrap($att{BASEEXT},@_);
}

sub parse_args{
    my($attr, @args) = @_;
    foreach (@args){
	unless (m/(.*?)=(.*)/){
	    help(),exit 1 if m/^help$/;
	    ++$Verbose if m/^verb/;
	    next;
	}
	my($name, $value) = ($1, $2);
	if ($value =~ m/^~(\w+)?/){ # tilde with optional username
	    $value =~ s [^~(\w*)]
		[$1 ? 
		 ((getpwnam($1))[7] || "~$1") : 
		 (getpwuid($>))[7]
		 ]ex;
	}
	if ($Correct_relativ_directories){
	    # This is experimental, so we don't care for efficiency
	    my @dirs = qw(INST_LIB INST_ARCHLIB INST_EXE);
	    my %dirs;
	    @dirs{@dirs}=@dirs;
	    if ($dirs{$name} && $value !~ m!^/!){ # a relativ directory
		$value = "../$value";
	    }
	}

	$$attr{$name} = $value;
    }
    # catch old-style 'potential_libs' and inform user how to 'upgrade'
    if (defined $$attr{'potential_libs'}){
	my($msg)="'potential_libs' => '$$attr{potential_libs}' should be";
	if ($$attr{'potential_libs'}){
	    print STDOUT "$msg changed to:\n\t'LIBS' => ['$$attr{potential_libs}']\n";
	} else {
	    print STDOUT "$msg deleted.\n";
	}
	$$attr{LIBS} = [$$attr{'potential_libs'}];
	delete $$attr{'potential_libs'};
    }
    # catch old-style 'ARMAYBE' and inform user how to 'upgrade'
    if (defined $$attr{'ARMAYBE'}){
	my($armaybe) = $$attr{'ARMAYBE'};
	print STDOUT "ARMAYBE => '$armaybe' should be changed to:\n",
			"\t'dynamic_lib' => {ARMAYBE => '$armaybe'}\n";
	my(%dl) = %{$$attr{'dynamic_lib'} || {}};
	$$attr{'dynamic_lib'} = { %dl, ARMAYBE => $armaybe};
	delete $$attr{'ARMAYBE'};
    }
    if (defined $$attr{'LDTARGET'}){
	print STDOUT "LDTARGET should be changed to LDFROM\n";
	$$attr{'LDFROM'} = $$attr{'LDTARGET'};
	delete $$attr{'LDTARGET'};
    }
    foreach(sort keys %{$attr}){
	print STDOUT "	$_ => ".neatvalue($$attr{$_}) if ($Verbose);
	print STDOUT "'$_' is not a known MakeMaker parameter name.\n"
	    unless exists $Recognized_Att_Keys{$_};
    }
}


sub neatvalue{
    my($v) = @_;
    return "undef" unless defined $v;
    my($t) = ref $v;
    return "'$v'" unless $t;
    return "[ ".join(', ',map("'$_'",@$v))." ]" if ($t eq 'ARRAY');
    return "$v" unless $t eq 'HASH';
    my(@m, $key, $val);
    push(@m,"$key=>".neatvalue($val)) while (($key,$val) = each %$v);
    return "{ ".join(', ',@m)." }";
}

# ------ Define the MakeMaker default methods in package MM_Unix ------

package MM_Unix;

use Config;
use Cwd;
use File::Basename;
require Exporter;

Exporter::import('ExtUtils::MakeMaker',
	qw(%att %skip %Recognized_Att_Keys $Verbose));

# These attributes cannot be overridden externally
@Other_Att_Keys{qw(EXTRALIBS BSLOADLIBS LDLOADLIBS)} = (1) x 3;

if ($Is_VMS = $Config{'osname'} eq 'VMS') {
    require VMS::Filespec;
    import VMS::Filespec 'vmsify';
}


sub init_main {
    my($self) = @_;

    # Find out directory name.  This may contain the extension name.
    my($pwd) = fastcwd(); # from Cwd.pm
    # --- Initialize Module Name and Paths

    # NAME    = The perl module name for this extension (eg DBD::Oracle).
    # FULLEXT = Pathname for extension directory (eg DBD/Oracle).
    # BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT.
    # ROOTEXT = Directory part of FULLEXT with leading /.
    unless($att{NAME}){ # we have to guess our name
	my($name) = $pwd;
	if ($Is_VMS) {
	  $name =~ s:.*?([^.\]]+)\]:$1: unless ($name =~ s:.*[.\[]ext\.(.*)\]:$1:i);
	  ($att{NAME}=$name) =~ s#[.\]]#::#g;
	} else {
	  $name =~ s:.*/:: unless ($name =~ s:^.*/ext/::);
	  ($att{NAME} =$name) =~ s#/#::#g;
	}
    }
    ($att{FULLEXT} =$att{NAME}) =~ s#::#/#g ;		#eg. BSD/Foo/Socket
    ($att{BASEEXT} =$att{NAME}) =~ s#.*::##;		#eg. Socket
    ($att{ROOTEXT} =$att{FULLEXT}) =~ s#/?\Q$att{BASEEXT}\E$## ; # eg. /BSD/Foo
    $att{ROOTEXT} = ($Is_VMS ? '' : '/') . $att{ROOTEXT} if $att{ROOTEXT};


    # --- Initialize PERL_LIB, INST_LIB, PERL_SRC

    # *Real* information: where did we get these two from? ...
    my $inc_config_dir = dirname($INC{'Config.pm'});
    my $inc_carp_dir   = dirname($INC{'Carp.pm'});

    # Typically PERL_* and INST_* will be identical but that need
    # not be the case (e.g., installing into project libraries etc).

    # Perl Macro:    With source    No source
    # PERL_LIB       ../../lib      /usr/local/lib/perl5
    # PERL_ARCHLIB   ../../lib      /usr/local/lib/perl5/sun4-sunos
    # PERL_SRC       ../..          (undefined)

    # INST Macro:    For standard   for any other
    #                modules        module
    # INST_LIB       ../../lib      ./blib
    # INST_ARCHLIB   ../../lib      ./blib

    unless ($att{PERL_SRC}){
	foreach (qw(../.. ../../.. ../../../..)){
	    if ( -f "$_/config.sh" 
		&& -f "$_/perl.h" 
		&& -f "$_/lib/Exporter.pm") {
		$att{PERL_SRC}=$_ ;
		last;
	    }
	}
    }
    unless ($att{PERL_SRC}){
	# we should also consider $ENV{PERL5LIB} here
	$att{PERL_LIB}     = $Config{'privlib'} unless $att{PERL_LIB};
	$att{PERL_ARCHLIB} = $Config{'archlib'} unless $att{PERL_ARCHLIB};
	$att{PERL_INC}     = "$att{PERL_ARCHLIB}/CORE"; # wild guess for now
	die <<EOM unless (-f "$att{PERL_INC}/perl.h");
Error: Unable to locate installed Perl libraries or Perl source code.

It is recommended that you install perl in a standard location before
building extensions. You can say:

    $^X Makefile.PL PERL_SRC=/path/to/perl/source/directory

if you have not yet installed perl but still want to build this
extension now.
EOM

	print STDOUT "Using header files found in $att{PERL_INC}" if $Verbose && $self->needs_linking;

    } else { # PERL_SRC is defined here...

	$att{PERL_LIB}     = "$att{PERL_SRC}/lib" unless $att{PERL_LIB};
	$att{PERL_ARCHLIB} = $att{PERL_LIB};
	$att{PERL_INC}     = $att{PERL_SRC};
	# catch an situation that has occurred a few times in the past:
	warn <<EOM unless -s "$att{PERL_SRC}/cflags";
You cannot build extensions below the perl source tree after executing
a 'make clean' in the perl source tree.

To rebuild extensions distributed with the perl source you should
simply Configure (to include those extensions) and then build perl as
normal. After installing perl the source tree can be deleted. It is not
needed for building extensions.

It is recommended that you unpack and build additional extensions away
from the perl source tree.
EOM
    }

    # INST_LIB typically pre-set if building an extension after
    # perl has been built and installed. Setting INST_LIB allows
    # you to build directly into, say $Config{'privlib'}.
    unless ($att{INST_LIB}){
	if (defined $att{PERL_SRC}) {
#	    require ExtUtils::Manifest;
#	    my $file;
	    my $standard = 0;
#	    my $mani = ExtUtils::Manifest::maniread("$att{PERL_SRC}/MANIFEST");
#	    foreach $file (keys %$mani){
#		if ($file =~ m!^ext/\Q$att{FULLEXT}!){
#		    $standard++;
#		    last;
#		}
#	    }

#### Temporary solution for perl5.001f:
$standard = 1;
#### This is just the same as was MakeMaker 4.094, but everything's prepared to
#### switch to a different behaviour after 5.001f

	    if ($standard){
		$att{INST_LIB} = $att{PERL_LIB};
	    } else {
		$att{INST_LIB} = "./blib";
		print STDOUT <<END;
Warning: The $att{NAME} extension will not be installed by 'make install' in the
perl source directory. Please install it with 'make install' from the
    $pwd
directory.
END
	    }
	} else {
	    $att{INST_LIB} = "./blib";
	}
    }
    # Try to work out what INST_ARCHLIB should be if not set:
    unless ($att{INST_ARCHLIB}){
	my(%archmap) = (
	    "./blib"		=> "./blib", # our private build lib
	    $att{PERL_LIB}	=> $att{PERL_ARCHLIB},
	    $Config{'privlib'}	=> $Config{'archlib'},
	    $inc_carp_dir	=> $inc_config_dir,
	);
	$att{INST_ARCHLIB} = $archmap{$att{INST_LIB}};
	unless($att{INST_ARCHLIB}){
	    # Oh dear, we'll have to default it and warn the user
	    my($archname) = $Config{'archname'};
	    if (-d "$att{INST_LIB}/$archname"){
		$att{INST_ARCHLIB} = "$att{INST_LIB}/$archname";
		print STDOUT "Defaulting INST_ARCHLIB to INST_LIB/$archname\n";
	    } else {
		$att{INST_ARCHLIB} = $att{INST_LIB};
		print STDOUT "Warning: Defaulting INST_ARCHLIB to INST_LIB ",
			"(not architecture independent).\n";
	    }
	}
    }
    $att{INST_EXE} = "./blib" unless $att{INST_EXE};

    if( $att{INSTALLPRIVLIB} && ! $att{INSTALLARCHLIB} ){
	my($archname) = $Config{'archname'};
	if (-d "$att{INSTALLPRIVLIB}/$archname"){
	    $att{INSTALLARCHLIB} = "$att{INSTALLPRIVLIB}/$archname";
	    print STDOUT "Defaulting INSTALLARCHLIB to INSTALLPRIVLIB/$archname\n";
	} else {
	    $att{INSTALLARCHLIB} = $att{INSTALLPRIVLIB};
	    print STDOUT "Warning: Defaulting INSTALLARCHLIB to INSTALLPRIVLIB ",
	    "(not architecture independent).\n";
	}
    }
    $att{INSTALLPRIVLIB} ||= $Config{'installprivlib'};
    $att{INSTALLARCHLIB} ||= $Config{'installarchlib'};
    $att{INSTALLBIN}     ||= $Config{'installbin'};

    $att{MAP_TARGET} = "perl" unless $att{MAP_TARGET};
    $att{LIBPERL_A} = $Is_VMS ? 'libperl.olb' : 'libperl.a'
	unless $att{LIBPERL_A};

    # make a few simple checks
    warn "Warning: PERL_LIB ($att{PERL_LIB}) seems not to be a perl library directory
        (Exporter.pm not found)"
	unless (-f "$att{PERL_LIB}/Exporter.pm");

    ($att{DISTNAME}=$att{NAME}) =~ s#(::)#-#g unless $att{DISTNAME};
    $att{VERSION} = "0.1" unless $att{VERSION};
    ($att{VERSION_SYM} = $att{VERSION}) =~ s/\W/_/g;


    # --- Initialize Perl Binary Locations

    # Find Perl 5. The only contract here is that both 'PERL' and 'FULLPERL'
    # will be working versions of perl 5. miniperl has priority over perl
    # for PERL to ensure that $(PERL) is usable while building ./ext/*
    $att{'PERL'} =
      MY->find_perl(5.0, ['miniperl','perl','perl5',"perl$]" ],
		    [ grep defined $_, $att{PERL_SRC}, split(":", $ENV{PATH}),
		     $Config{'bin'} ], $Verbose )
	unless ($att{'PERL'});	# don't check, if perl is executable, maybe they
				# they have decided to supply switches with perl

    # Define 'FULLPERL' to be a non-miniperl (used in test: target)
    ($att{'FULLPERL'} = $att{'PERL'}) =~ s/miniperl/perl/
	unless ($att{'FULLPERL'} && -x $att{'FULLPERL'});

    if ($Is_VMS) {
	$att{'PERL'} = 'MCR ' . vmsify($att{'PERL'});
	$att{'FULLPERL'} = 'MCR ' . vmsify($att{'FULLPERL'});
    }
}


sub init_dirscan {	# --- File and Directory Lists (.xs .pm .pod etc)

    my($name, %dir, %xs, %c, %h, %ignore, %pl_files);
    local(%pm); #the sub in find() has to see this hash
    $ignore{'test.pl'} = 1;
    $ignore{'makefile.pl'} = 1 if $Is_VMS;
    foreach $name (lsdir(".")){
	next if ($name =~ /^\./ or $ignore{$name});
	if (-d $name){
	    $dir{$name} = $name if (-f "$name/Makefile.PL");
	} elsif ($name =~ /\.xs$/){
	    my($c); ($c = $name) =~ s/\.xs$/.c/;
	    $xs{$name} = $c;
	    $c{$c} = 1;
	} elsif ($name =~ /\.c$/){
	    $c{$name} = 1
		unless $name =~ m/perlmain\.c/; # See MAP_TARGET
	} elsif ($name =~ /\.h$/){
	    $h{$name} = 1;
	} elsif ($name =~ /\.(p[ml]|pod)$/){
	    $pm{$name} = "\$(INST_LIBDIR)/$name";
	} elsif ($name =~ /\.PL$/ && $name ne "Makefile.PL") {
	    ($pl_files{$name} = $name) =~ s/\.PL$// ;
	}
    }

    # Some larger extensions often wish to install a number of *.pm/pl
    # files into the library in various locations.

    # The attribute PMLIBDIRS holds an array reference which lists
    # subdirectories which we should search for library files to
    # install. PMLIBDIRS defaults to [ 'lib', $att{BASEEXT} ].
    # We recursively search through the named directories (skipping
    # any which don't exist or contain Makefile.PL files).

    # For each *.pm or *.pl file found MY->libscan() is called with
    # the default installation path in $_. The return value of libscan
    # defines the actual installation location.
    # The default libscan function simply returns $_.
    # The file is skipped if libscan returns false.

    # The default installation location passed to libscan in $_ is:
    #
    #  ./*.pm		=> $(INST_LIBDIR)/*.pm
    #  ./xyz/...	=> $(INST_LIBDIR)/xyz/...
    #  ./lib/...	=> $(INST_LIB)/...
    #
    # In this way the 'lib' directory is seen as the root of the actual
    # perl library whereas the others are relative to INST_LIBDIR
    # (which includes ROOTEXT). This is a subtle distinction but one
    # that's important for nested modules.

    $att{PMLIBDIRS} = [ 'lib', $att{BASEEXT} ] unless $att{PMLIBDIRS};

    #only existing directories that aren't in $dir are allowed
    @{$att{PMLIBDIRS}} = grep -d && !$dir{$_}, @{$att{PMLIBDIRS}};

    if (@{$att{PMLIBDIRS}}){
	print "Searching PMLIBDIRS: @{$att{PMLIBDIRS}}"
	    if ($Verbose >= 2);
	use File::Find;		# try changing to require !
	File::Find::find(sub {
# We now allow any file in PMLIBDIRS to be installed. nTk needs that, and
# we should allow it.
#               return unless m/\.p[ml]$/;
	        return if -d $_; # anything else that Can't be copied?
		my($path, $prefix) = ($File::Find::name, '$(INST_LIBDIR)');
		my $striplibpath;
		$prefix =  '$(INST_LIB)' if (($striplibpath = $path) =~ s:^lib/::);
		local($_) = "$prefix/$striplibpath";
		my($inst) = MY->libscan();
		print "libscan($path) => '$inst'" if ($Verbose >= 2);
		return unless $inst;
		$pm{$path} = $inst;
	     }, @{$att{PMLIBDIRS}});
    }

    $att{DIR} = [sort keys %dir] unless $att{DIRS};
    $att{XS}  = \%xs             unless $att{XS};
    $att{PM}  = \%pm             unless $att{PM};
    $att{C}   = [sort keys %c]   unless $att{C};
    my(@o_files) = @{$att{C}};
    my($sufx) = $Is_VMS ? '.obj' : '.o';
    $att{O_FILES} = [grep s/\.c$/$sufx/, @o_files] ;
    $att{H}   = [sort keys %h]   unless $att{H};
    $att{PL_FILES} = \%pl_files unless $att{PL_FILES};
}


sub libscan {
    return '' if m:/RCS/: ; # return undef triggered warnings with $Verbose>=2
    $_;
}

sub init_others {	# --- Initialize Other Attributes
    my($key);
    for $key (keys(%Recognized_Att_Keys), keys(%Other_Att_Keys)){
	# avoid warnings for uninitialized vars
	next if exists $att{$key};
	$att{$key} = "";
    }

    # Compute EXTRALIBS, BSLOADLIBS and LDLOADLIBS from $att{'LIBS'}
    # Lets look at $att{LIBS} carefully: It may be an anon array, a string or
    # undefined. In any case we turn it into an anon array:
    $att{LIBS}=[] unless $att{LIBS};
    $att{LIBS}=[$att{LIBS}] if ref \$att{LIBS} eq SCALAR;
    $att{LD_RUN_PATH} = "";
    foreach ( @{$att{'LIBS'}} ){
	s/^\s*(.*\S)\s*$/$1/; # remove leading and trailing whitespace
	my(@libs) = MY->extliblist($_);
	if ($libs[0] or $libs[1] or $libs[2]){
	    @att{EXTRALIBS, BSLOADLIBS, LDLOADLIBS} = @libs;
	    if ($libs[2]) {
		$att{LD_RUN_PATH} = join(":",grep($_=~s/^-L//,split(" ", $libs[2])));
	    }
	    last;
	}
    }

    print STDOUT "CONFIG must be an array ref\n"
	if ($att{CONFIG} and ref $att{CONFIG} ne 'ARRAY');
    $att{CONFIG} = [] unless (ref $att{CONFIG});
    push(@{$att{CONFIG}},
	qw(cc libc ldflags lddlflags ccdlflags cccdlflags
	   ranlib so dlext dlsrc
	));
    push(@{$att{CONFIG}}, 'shellflags') if $Config{'shellflags'};

    if ($Is_VMS) {
      $att{OBJECT} = '$(BASEEXT).obj' unless $att{OBJECT};
      $att{OBJECT} =~ s/[^,\s]\s+/, /g;
      $att{OBJECT} =~ s/\n+/, /g;
      $att{OBJECT} =~ s#\.o,#\.obj,#;
    } else {
      $att{OBJECT} = '$(BASEEXT).o' unless $att{OBJECT};
      $att{OBJECT} =~ s/\n+/ \\\n\t/g;
    }
    $att{BOOTDEP}  = (-f "$att{BASEEXT}_BS") ? "$att{BASEEXT}_BS" : "";
    $att{LD}       = ($Config{'ld'} || 'ld') unless $att{LD};
    $att{LDFROM} = '$(OBJECT)' unless $att{LDFROM};
    # Sanity check: don't define LINKTYPE = dynamic if we're skipping
    # the 'dynamic' section of MM.  We don't have this problem with
    # 'static', since we either must use it (%Config says we can't
    # use dynamic loading) or the caller asked for it explicitly.
    if (!$att{LINKTYPE}) {
       $att{LINKTYPE} = grep(/dynamic/,@{$att{SKIP} || []})
                        ? 'static'
                        : ($Config{'usedl'} ? 'dynamic' : 'static');
    };

    # These get overridden for VMS and maybe some other systems
    $att{NOOP}  = "";
    $att{MAKEFILE} = "Makefile";
    $att{RM_F}  = "rm -f";
    $att{RM_RF} = "rm -rf";
    $att{TOUCH} = "touch";
    $att{CP} = "cp";
    $att{MV} = "mv";
    $att{CHMOD} = "chmod";
}


sub lsdir{
    my($dir, $regex) = @_;
    local(*DIR, @ls);
    opendir(DIR, $_[0] || ".") or die "opendir: $!";
    @ls = readdir(DIR);
    closedir(DIR);
    @ls = grep(/$regex/, @ls) if $regex;
    @ls;
}


sub find_perl{
    my($self, $ver, $names, $dirs, $trace) = @_;
    my($name, $dir);
    if ($trace >= 2){
	print "Looking for perl $ver by these names: ";
	print "@$names, ";
	print "in these dirs:";
	print "@$dirs";
    }
    foreach $dir (@$dirs){
	next unless defined $dir; # $att{PERL_SRC} may be undefined
	foreach $name (@$names){
	    print "Checking $dir/$name " if ($trace >= 2);
	    if ($Is_VMS) {
	      $name .= ".exe" unless -x "$dir/$name";
	    }
	    next unless -x "$dir/$name";
	    print "Executing $dir/$name" if ($trace >= 2);
	    my($out);
	    if ($Is_VMS) {
	      my($vmscmd) = 'MCR ' . vmsify("$dir/$name");
	      $out = `$vmscmd -e "require $ver; print ""VER_OK\n"""`;
	    } else {
	      $out = `$dir/$name -e 'require $ver; print "VER_OK\n" ' 2>&1`;
	    }
	    if ($out =~ /VER_OK/) {
		print "Using PERL=$dir/$name" if $trace;
		return "$dir/$name";
	    }
	}
    }
    print STDOUT "Unable to find a perl $ver (by these names: @$names, in these dirs: @$dirs)\n";
    0; # false and not empty
}


sub post_initialize{
    "";
}

sub needs_linking {	# Does this module need linking?
    return 1 if $att{OBJECT} or @{$att{C} || []} or $att{MYEXTLIB};
    return 0;
}

sub constants {
    my($self) = @_;
    my(@m);

    push @m, "
NAME = $att{NAME}
DISTNAME = $att{DISTNAME}
VERSION = $att{VERSION}
VERSION_SYM = $att{VERSION_SYM}

# In which directory should we put this extension during 'make'?
# This is typically ./blib.
# (also see INST_LIBDIR and relationship to ROOTEXT)
INST_LIB = $att{INST_LIB}
INST_ARCHLIB = $att{INST_ARCHLIB}
INST_EXE = $att{INST_EXE}

# AFS users will want to set the installation directories for
# the final 'make install' early without setting INST_LIB,
# INST_ARCHLIB, and INST_EXE for the testing phase
INSTALLPRIVLIB = $att{INSTALLPRIVLIB}
INSTALLARCHLIB = $att{INSTALLARCHLIB}
INSTALLBIN = $att{INSTALLBIN}

# Perl library to use when building the extension
PERL_LIB = $att{PERL_LIB}
PERL_ARCHLIB = $att{PERL_ARCHLIB}
LIBPERL_A = $att{LIBPERL_A}

MAKEMAKER = \$(PERL_LIB)/ExtUtils/MakeMaker.pm
MM_VERSION = $ExtUtils::MakeMaker::Version
";

    # Define I_PERL_LIBS to include the required -Ipaths
    # To be cute we only include PERL_ARCHLIB if different

    #### Deprecated from Version 4.11: We want to avoid different
    #### behavior for variables with make(1) and perl(1)

    # To be portable we add quotes for VMS
    my(@i_perl_libs) = qw{-I$(PERL_ARCHLIB) -I$(PERL_LIB)};
    shift(@i_perl_libs) if ($att{PERL_ARCHLIB} eq $att{PERL_LIB});
    if ($Is_VMS){
	push @m, "I_PERL_LIBS = \"".join('" "',@i_perl_libs)."\"\n";
    } else {
	push @m, "I_PERL_LIBS = ".join(' ',@i_perl_libs)."\n";
    }

    push @m, "
# Where is the perl source code located?
PERL_SRC = $att{PERL_SRC}\n" if $att{PERL_SRC};

    push @m, "
# Perl header files (will eventually be under PERL_LIB)
PERL_INC = $att{PERL_INC}
# Perl binaries
PERL = $att{'PERL'}
FULLPERL = $att{'FULLPERL'}
";
    push @m, "
# FULLEXT = Pathname for extension directory (eg DBD/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT.
# ROOTEXT = Directory part of FULLEXT with leading slash (eg /DBD)
FULLEXT = $att{FULLEXT}
BASEEXT = $att{BASEEXT}
ROOTEXT = $att{ROOTEXT}
";
    push @m, "
INC = $att{INC}
DEFINE = $att{DEFINE}
OBJECT = $att{OBJECT}
LDFROM = $att{LDFROM}
LINKTYPE = $att{LINKTYPE}

# Handy lists of source code files:
XS_FILES= ".join(" \\\n\t", sort keys %{$att{XS}})."
C_FILES = ".join(" \\\n\t", @{$att{C}})."
O_FILES = ".join(" \\\n\t", @{$att{O_FILES}})."
H_FILES = ".join(" \\\n\t", @{$att{H}})."

.SUFFIXES: .xs

.PRECIOUS: Makefile

.NO_PARALLEL:

.PHONY: all config static dynamic test linkext

# This extension may link to it's own library (see SDBM_File)
MYEXTLIB = $att{MYEXTLIB}

# Where is the Config information that we are using/depend on
CONFIGDEP = \$(PERL_ARCHLIB)/Config.pm \$(PERL_INC)/config.h
";

    push @m, '
# Where to put things:
INST_LIBDIR     = $(INST_LIB)$(ROOTEXT)
INST_ARCHLIBDIR = $(INST_ARCHLIB)$(ROOTEXT)

INST_AUTODIR      = $(INST_LIB)/auto/$(FULLEXT)
INST_ARCHAUTODIR  = $(INST_ARCHLIB)/auto/$(FULLEXT)
';

    if ($self->needs_linking) {
	push @m, '
INST_STATIC  = $(INST_ARCHAUTODIR)/$(BASEEXT).a
INST_DYNAMIC = $(INST_ARCHAUTODIR)/$(BASEEXT).$(DLEXT)
INST_BOOT    = $(INST_ARCHAUTODIR)/$(BASEEXT).bs
';
    } else {
	push @m, '
INST_STATIC  =
INST_DYNAMIC =
INST_BOOT    =
';
    }

    push @m, '
INST_PM = '.join(" \\\n\t", sort values %{$att{PM}}).'
';

    join('',@m);
}

$Const_cccmd=0; # package global

sub const_cccmd{
    my($self,$libperl)=@_;
    $libperl or $libperl = $att{LIBPERL_A} || "libperl.a" ;
    # This is implemented in the same manner as extliblist,
    # e.g., do both and compare results during the transition period.
    my($cc,$ccflags,$optimize,$large,$split, $shflags)
	= @Config{qw(cc ccflags optimize large split shellflags)};
    my($optdebug)="";

    $shflags = '' unless $shflags;
    my($prog, $old, $uc, $perltype);

    unless ($Const_cccmd++){
	chop($old = `cd $att{PERL_SRC}; sh $shflags ./cflags $libperl $att{BASEEXT}.c`)
	  if $att{PERL_SRC};
	$Const_cccmd++; # shut up typo warning
    }

    my(%map) =  (
		D =>   '-DDEBUGGING',
		E =>   '-DEMBED',
		DE =>  '-DDEBUGGING -DEMBED',
		M =>   '-DEMBED -DMULTIPLICITY',
		DM =>  '-DDEBUGGING -DEMBED -DMULTIPLICITY',
		);

    if ($libperl =~ /libperl(\w*)\.a/){
	$uc = uc($1);
    } else {
	$uc = ""; # avoid warning
    }
    $perltype = $map{$uc} ? $map{$uc} : "";

    if ($uc =~ /^D/) {
	$optdebug = "-g";
    }


    my($name);
    ( $name = $att{NAME} . "_cflags" ) =~ s/:/_/g ;
    if ($prog = $Config{$name}) {
	# Expand hints for this extension via the shell
	print STDOUT "Processing $name hint:\n" if $Verbose;
	my(@o)=`cc=\"$cc\"
	  ccflags=\"$ccflags\"
	  optimize=\"$optimize\"
	  perltype=\"$perltype\"
	  optdebug=\"$optdebug\"
	  large=\"$large\"
	  split=\"$split\"
	  eval '$prog'
	  echo cc=\$cc
	  echo ccflags=\$ccflags
	  echo optimize=\$optimize
	  echo perltype=\$perltype
	  echo optdebug=\$optdebug
	  echo large=\$large
	  echo split=\$split
	  `;
	my(%cflags,$line);
	foreach $line (@o){
	    chomp $line;
	    if ($line =~ /(.*?)=\s*(.*)\s*$/){
		$cflags{$1} = $2;
		print STDOUT "	$1 = $2" if $Verbose;
	    } else {
		print STDOUT "Unrecognised result from hint: '$line'\n";
	    }
	}
	(    $cc,$ccflags,$perltype,$optdebug,$optimize,$large,$split )=@cflags{
          qw( cc  ccflags  perltype  optdebug  optimize  large  split)};
    }

    if ($optdebug) {
	$optimize = $optdebug;
    }

    my($new) = "$cc -c $ccflags $optimize $perltype $large $split";
    $new =~ s/^\s+//; $new =~ s/\s+/ /g; $new =~ s/\s+$//;
    if (defined($old)){
	$old =~ s/^\s+//; $old =~ s/\s+/ /g; $old =~ s/\s+$//;
	if ($new ne $old) {
	    print STDOUT "Warning (non-fatal): cflags evaluation in "
	      ."MakeMaker ($ExtUtils::MakeMaker::Version) "
	      ."differs from shell output\n"
	      ."   package: $att{NAME}\n"
	      ."   old: $old\n"
	      ."   new: $new\n"
	      ."   Using 'old' set.\n"
	      . Config::myconfig()
	      ."\nPlease send these details to perl5-porters\@nicoh.com\n";
	}
    }
    my($cccmd)=($old) ? $old : $new;
    $cccmd =~ s/^\s*\Q$Config{'cc'}\E\s/\$(CC) /;
    "CCCMD = $cccmd\n";
}


# --- Constants Sections ---

sub const_config{
    my(@m,$m);
    push(@m,"\n# These definitions are from config.sh (via $INC{'Config.pm'})\n");
    my(%once_only);
    foreach $m (@{$att{'CONFIG'}}){
	next if $once_only{$m};
	print STDOUT "CONFIG key '$m' does not exist in Config.pm\n"
		unless exists $Config{$m};
	push @m, "\U$m\E = $Config{$m}\n";
	$once_only{$m} = 1;
    }
    join('', @m);
}


sub const_loadlibs{
    "
# $att{NAME} might depend on some other libraries:
# (These comments may need revising:)
#
# Dependent libraries can be linked in one of three ways:
#
#  1.  (For static extensions) by the ld command when the perl binary
#      is linked with the extension library. See EXTRALIBS below.
#
#  2.  (For dynamic extensions) by the ld command when the shared
#      object is built/linked. See LDLOADLIBS below.
#
#  3.  (For dynamic extensions) by the DynaLoader when the shared
#      object is loaded. See BSLOADLIBS below.
#
# EXTRALIBS =	List of libraries that need to be linked with when
#		linking a perl binary which includes this extension
#		Only those libraries that actually exist are included.
#		These are written to a file and used when linking perl.
#
# LDLOADLIBS =	List of those libraries which can or must be linked into
#		the shared library when created using ld. These may be
#		static or dynamic libraries.
#		LD_RUN_PATH is a colon separated list of the directories
#		in LDLOADLIBS. It is passed as an environment variable to
#		the process that links the shared library.
#
# BSLOADLIBS =	List of those libraries that are needed but can be
#		linked in dynamically at run time on this platform.
#		SunOS/Solaris does not need this because ld records
#		the information (from LDLOADLIBS) into the object file.
#		This list is used to create a .bs (bootstrap) file.
#
EXTRALIBS  = $att{'EXTRALIBS'}
LDLOADLIBS = $att{'LDLOADLIBS'}
BSLOADLIBS = $att{'BSLOADLIBS'}
LD_RUN_PATH= $att{'LD_RUN_PATH'}
";
}


# --- Tool Sections ---

sub tool_autosplit{
    my($self, %attribs) = @_;
    my($asl) = "";
    $asl = "\$AutoSplit::Maxlen=$attribs{MAXLEN};" if $attribs{MAXLEN};
    q{
# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -e 'use AutoSplit;}.$asl.q{autosplit($$ARGV[0], $$ARGV[1], 0, 1, 1) ;'
};
}


sub tool_xsubpp{
    my($xsdir)  = '$(PERL_LIB)/ExtUtils';
    # drop back to old location if xsubpp is not in new location yet
    $xsdir = '$(PERL_SRC)/ext' unless (-f "$att{PERL_LIB}/ExtUtils/xsubpp");
    my(@tmdeps) = ('$(XSUBPPDIR)/typemap');
    push(@tmdeps, "typemap") if -f "typemap";
    my(@tmargs) = map("-typemap $_", @tmdeps);
    "
XSUBPPDIR = $xsdir
XSUBPP = \$(XSUBPPDIR)/xsubpp
XSUBPPDEPS = @tmdeps
XSUBPPARGS = @tmargs
";
};


sub tools_other{
    "
SHELL = /bin/sh
LD = $att{LD}
TOUCH = $att{TOUCH}
CP = $att{CP}
MV = $att{MV}
RM_F  = $att{RM_F}
RM_RF = $att{RM_RF}
CHMOD = $att{CHMOD}
".q{
# The following is a portable way to say mkdir -p
MKPATH = $(PERL) -wle '$$"="/"; foreach $$p (@ARGV){ next if -d $$p; my(@p); foreach(split(/\//,$$p)){ push(@p,$$_); next if -d "@p/"; print "mkdir @p"; mkdir("@p",0777)||die $$! }} exit 0;'
};
}


sub post_constants{
    "";
}

sub macro {
    my($self,%attribs) = @_;
    my(@m,$key,$val);
    while (($key,$val) = each %attribs){
	push @m, "$key = $val\n";
    }
    join "", @m;
}

sub pasthru {
    my(@m,$key);
    # It has to be considered carefully, which variables are apt 
    # to be passed through, e.g. ALL RELATIV DIRECTORIES are
    # not suited for PASTHRU to subdirectories.
    # Moreover: No directories at all have a chance, because we
    # don't know yet, if the directories are absolute or relativ

    # PASTHRU2 is a conservative approach, that hardly changed
    # MakeMaker between version 4.086 and 4.09.

    # PASTHRU1 is a revolutionary approach :), it cares for having
    # a prepended "../" whenever runsubdirpl is called, but only
    # for the three crucial INST_* directories.

    my(@pasthru1,@pasthru2); # 1 for runsubdirpl, 2 for the rest

    foreach $key (qw(INST_LIB INST_ARCHLIB INST_EXE)){
	push @pasthru1, "$key=\"\$($key)\"";
    }

    foreach $key (qw(INSTALLPRIVLIB INSTALLARCHLIB INSTALLBIN LIBPERL_A LINKTYPE)){
	push @pasthru1, "$key=\"\$($key)\"";
	push @pasthru2, "$key=\"\$($key)\"";
    }

    push @m, "\nPASTHRU1 = ", join ("\\\n\t", @pasthru1), "\n";
    push @m, "\nPASTHRU2 = ", join ("\\\n\t", @pasthru2), "\n";
    join "", @m;
}

# --- Translation Sections ---

sub c_o {
    my(@m);
    push @m, '
.c.o:
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $(INC) $*.c
';
    join "", @m;
}

sub xs_c {
    '
.xs.c:
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSUBPPARGS) $*.xs >$*.tc && mv $*.tc $@
';
}

sub xs_o {	# many makes are too dumb to use xs_c then c_o
    '
.xs.o:
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSUBPPARGS) $*.xs >xstmp.c && mv xstmp.c $*.c
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $(INC) $*.c
';
}


# --- Target Sections ---

sub top_targets{
    my(@m);
    push @m, '
all ::	config linkext $(INST_PM)
'.$att{NOOP}.'

config :: '.$att{MAKEFILE}.' $(INST_LIBDIR)/.exists $(INST_ARCHAUTODIR)/.exists Version_check
';

    push @m, MM->dir_target('$(INST_LIBDIR)', '$(INST_ARCHAUTODIR)', '$(INST_EXE)');

    push @m, '
$(O_FILES): $(H_FILES)
' if @{$att{O_FILES} || []} && @{$att{H} || []};

    push @m, q{
help:
	$(PERL) -I$(PERL_LIB) -e 'use ExtUtils::MakeMaker "&help"; &help;'
};

    push @m, q{
Version_check:
	@$(PERL) -I$(PERL_LIB) -e 'use ExtUtils::MakeMaker qw($$Version &Version_check);' \
		-e '&Version_check($(MM_VERSION))'
};

    join('',@m);
}

sub linkext {
    my($self, %attribs) = @_;
    # LINKTYPE => static or dynamic or ''
    my($linktype) = defined $attribs{LINKTYPE} ? 
      $attribs{LINKTYPE} : '$(LINKTYPE)';
    "
linkext :: $linktype
$att{NOOP}
";
}

sub dlsyms {
    my($self,%attribs) = @_;

    return '' if ($Config{'osname'} ne 'aix');

    my($funcs) = $attribs{DL_FUNCS} || $att{DL_FUNCS} || {};
    my($vars)  = $attribs{DL_VARS} || $att{DL_VARS} || [];
    my(@m);

    push(@m,"
dynamic :: $att{BASEEXT}.exp

") unless $skip{'dynamic'};

    push(@m,"
static :: $att{BASEEXT}.exp

") unless $skip{'static'};

    push(@m,"
$att{BASEEXT}.exp: Makefile.PL
",'	$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -e \'use ExtUtils::MakeMaker qw(&mksymlists); \\
	&mksymlists(DL_FUNCS => ',
	%$funcs ? neatvalue($funcs) : '""',', DL_VARS => ',
	@$vars  ? neatvalue($vars)  : '""', ", NAME => \"$att{NAME}\")'
");

    join('',@m);
}

# --- Dynamic Loading Sections ---

sub dynamic {
    '
# $(INST_PM) has been moved to the all: target.
# It remains here for awhile to allow for old usage: "make dynamic"
dynamic :: '.$att{MAKEFILE}.' $(INST_DYNAMIC) $(INST_BOOT) $(INST_PM)
'.$att{NOOP}.'
';
}

sub dynamic_bs {
    my($self, %attribs) = @_;
    return '' unless $self->needs_linking;
    '
BOOTSTRAP = '."$att{BASEEXT}.bs".'

# As Mkbootstrap might not write a file (if none is required)
# we use touch to prevent make continually trying to remake it.
# The DynaLoader only reads a non-empty file.
$(BOOTSTRAP): '."$att{MAKEFILE} $att{BOOTDEP}".'
	@ echo "Running Mkbootstrap for $(NAME) ($(BSLOADLIBS))"
	@ $(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" \
		-e \'use ExtUtils::Mkbootstrap;\' \
		-e \'Mkbootstrap("$(BASEEXT)","$(BSLOADLIBS)");\'
	@ $(TOUCH) $(BOOTSTRAP)
	$(CHMOD) 644 $@
	@echo $@ >> $(INST_ARCHAUTODIR)/.packlist

$(INST_BOOT): $(BOOTSTRAP)
	@ '.$att{RM_RF}.' $(INST_BOOT)
	-'.$att{CP}.' $(BOOTSTRAP) $(INST_BOOT)
	$(CHMOD) 644 $@
	@echo $@ >> $(INST_ARCHAUTODIR)/.packlist
';
}


sub dynamic_lib {
    my($self, %attribs) = @_;
    my($otherldflags) = $attribs{OTHERLDFLAGS} || "";
    my($armaybe) = $attribs{ARMAYBE} || $att{ARMAYBE} || ":";
    my($ldfrom) = '$(LDFROM)';
    return '' unless $self->needs_linking;
    my($osname) = $Config{'osname'};
    $armaybe = 'ar' if ($osname eq 'dec_osf' and $armaybe eq ':');
    my(@m);
    push(@m,'
# This section creates the dynamically loadable $(INST_DYNAMIC)
# from $(OBJECT) and possibly $(MYEXTLIB).
ARMAYBE = '.$armaybe.'
OTHERLDFLAGS = '.$otherldflags.'

$(INST_DYNAMIC): $(OBJECT) $(MYEXTLIB) $(BOOTSTRAP) $(INST_ARCHAUTODIR)/.exists
');
    if ($armaybe ne ':'){
	$ldfrom = "tmp.a";
	push(@m,'	$(ARMAYBE) cr '.$ldfrom.' $(OBJECT)'."\n");
	push(@m,'	$(RANLIB) '."$ldfrom\n");
    }
    $ldfrom = "-all $ldfrom -none" if ($osname eq 'dec_osf');
    push(@m,'	LD_RUN_PATH="$(LD_RUN_PATH)" $(LD) -o $@ $(LDDLFLAGS) '.$ldfrom.
			' $(OTHERLDFLAGS) $(MYEXTLIB) $(LDLOADLIBS)');
    push @m, '
	$(CHMOD) 755 $@
	@echo $@ >> $(INST_ARCHAUTODIR)/.packlist
';

    push @m, MM->dir_target('$(INST_ARCHAUTODIR)');
    join('',@m);
}


# --- Static Loading Sections ---

sub static {
    '
# $(INST_PM) has been moved to the all: target.
# It remains here for awhile to allow for old usage: "make static"
static :: '.$att{MAKEFILE}.' $(INST_STATIC) $(INST_PM)
'.$att{NOOP}.'
';
}

sub static_lib{
    my($self) = @_;
    return '' unless $self->needs_linking;
    my(@m);
    push(@m, <<'END');
$(INST_STATIC): $(OBJECT) $(MYEXTLIB) $(INST_ARCHAUTODIR)/.exists
END
    # If this extension has it's own library (eg SDBM_File)
    # then copy that to $(INST_STATIC) and add $(OBJECT) into it.
    push(@m, "	$att{CP} \$(MYEXTLIB) \$\@\n") if $att{MYEXTLIB};

    push(@m, <<'END');
	ar cr $@ $(OBJECT) && $(RANLIB) $@
	@echo "$(EXTRALIBS)" > $(INST_ARCHAUTODIR)/extralibs.ld
	$(CHMOD) 755 $@
	@echo $@ >> $(INST_ARCHAUTODIR)/.packlist
END

# Old mechanism - still available:

    push(@m, <<'END') if $att{PERL_SRC};
	@ echo "$(EXTRALIBS)" >> $(PERL_SRC)/ext.libs
END

    push @m, MM->dir_target('$(INST_ARCHAUTODIR)');
    join('', "\n",@m);
}


sub installpm {
    my($self, %attribs) = @_;
    # By default .pm files are split into the architecture independent
    # library. This is a good thing. If a specific module requires that
    # it's .pm files are split into the architecture specific library
    # then it should use: installpm => {SPLITLIB=>'$(INST_ARCHLIB)'}
    # Note that installperl currently interferes with this (Config.pm)
    # User can disable split by saying: installpm => {SPLITLIB=>''}
    my($splitlib) = '$(INST_LIB)'; # NOT arch specific by default
    $splitlib = $attribs{SPLITLIB} if exists $attribs{SPLITLIB};
    my(@m, $dist);
    foreach $dist (sort keys %{$att{PM}}){
	my($inst) = $att{PM}->{$dist};
	push(@m, "\n# installpm: $dist => $inst, splitlib=$splitlib\n");
	push(@m, MY->installpm_x($dist, $inst, $splitlib));
	push(@m, "\n");
    }
    join('', @m);
}

sub installpm_x { # called by installpm per file
    my($self, $dist, $inst, $splitlib) = @_;
    warn "Warning: Most probably 'make' will have problems processing this file: $inst\n"
	if $inst =~ m![:#]!;
    my($instdir) = $inst =~ m|(.*)/|;
    my(@m);
    push(@m,"
$inst: $dist $att{MAKEFILE} $instdir/.exists
".'	@ '.$att{RM_F}.' $@
	'."$att{CP} $dist".' $@
	$(CHMOD) 644 $@
	@echo $@ >> $(INST_ARCHAUTODIR)/.packlist
');
    push(@m, "\t\@\$(AUTOSPLITFILE) \$@ $splitlib/auto\n")
	if ($splitlib and $inst =~ m/\.pm$/);

    push @m, MM->dir_target($instdir);
    join('', @m);
}

sub processPL {
    return "" unless $att{PL_FILES};
    my(@m, $plfile);
    foreach $plfile (sort keys %{$att{PL_FILES}}) {
	push @m, "
all :: $att{PL_FILES}->{$plfile}

$att{PL_FILES}->{$plfile} :: $plfile
	\$(PERL) -I\$(INST_ARCHLIB) -I\$(INST_LIB) -I\$(PERL_ARCHLIB) -I\$(PERL_LIB) $plfile
";
    }
    join "", @m;
}

sub installbin {
    return "" unless $att{EXE_FILES} && ref $att{EXE_FILES} eq "ARRAY";
    my(@m, $from, $to, %fromto, @to);
    for $from (@{$att{EXE_FILES}}) {
	local($_)= '$(INST_EXE)/' . basename($from);
	$to = MY->exescan();
	print "exescan($from) => '$to'" if ($Verbose >=2);
	$fromto{$from}=$to;
    }
    @to   = values %fromto;
    push(@m, "
EXE_FILES = @{$att{EXE_FILES}}

all :: @to

realclean ::
	$att{RM_F} @to
");

    while (($from,$to) = each %fromto) {
	my $todir = dirname($to);
	push @m, "
$to: $from $att{MAKEFILE} $todir/.exists
	$att{CP} $from $to
";
    }
    join "", @m;
}

sub exescan {
    $_;
}
# --- Sub-directory Sections ---

sub subdirs {
    my(@m);
    # This method provides a mechanism to automatically deal with
    # subdirectories containing further Makefile.PL scripts.
    # It calls the subdir_x() method for each subdirectory.
    foreach(grep -d, &lsdir()){
	next if /^\./;
	next unless -f "$_/Makefile\.PL" ;
	print "Including $_ subdirectory" if ($Verbose);
	push(@m, MY->subdir_x($_));
    }
    if (@m){
	unshift(@m, "
# The default clean, realclean and test targets in this Makefile
# have automatically been given entries for each subdir.

all :: subdirs
");
    } else {
	push(@m, "\n# none")
    }
    join('',@m);
}

sub runsubdirpl{	# Experimental! See subdir_x section
    my($self,$subdir) = @_;
    chdir($subdir) or die "chdir($subdir): $!";
    ExtUtils::MakeMaker::check_hints();
    package main;
    require "Makefile.PL";
}

sub subdir_x {
    my($self, $subdir) = @_;
    my(@m);
    # The intention is that the calling Makefile.PL should define the
    # $(SUBDIR_MAKEFILE_PL_ARGS) make macro to contain whatever
    # information needs to be passed down to the other Makefile.PL scripts.
    # If this does not suit your needs you'll need to write your own
    # MY::subdir_x() method to override this one.
    qq{
config :: $subdir/$att{MAKEFILE}
	cd $subdir && \$(MAKE) config \$(PASTHRU2) \$(SUBDIR_MAKEFILE_PL_ARGS)

$subdir/$att{MAKEFILE}: $subdir/Makefile.PL \$(CONFIGDEP)
}.'	@echo "Rebuilding $@ ..."
	@$(PERL) -I"$(PERL_ARCHLIB)" -I"$(PERL_LIB)" \\
		-e "use ExtUtils::MakeMaker; MM->runsubdirpl(qw('.$subdir.'))" \\
		$(PASTHRU1) $(SUBDIR_MAKEFILE_PL_ARGS)
	@echo "Rebuild of $@ complete."
'.qq{

subdirs ::
	cd $subdir && \$(MAKE) all \$(PASTHRU2)

};
}


# --- Cleanup and Distribution Sections ---

sub clean {
    my($self, %attribs) = @_;
    my(@m);
    push(@m, '
# Delete temporary files but do not touch installed files. We don\'t delete
# the Makefile here so a later make realclean still has a makefile to use.

clean ::
');
    # clean subdirectories first
    push(@m, map("\t-cd $_ && test -f $att{MAKEFILE} && \$(MAKE) clean\n",@{$att{DIR}}));
    my(@otherfiles) = values %{$att{XS}}; # .c files from *.xs files
    push(@otherfiles, $attribs{FILES}) if $attribs{FILES};
    push(@otherfiles, "./blib");
    push(@m, "	-$att{RM_RF} *~ t/*~ *.o *.a mon.out core so_locations "
			."\$(BOOTSTRAP) \$(BASEEXT).bso \$(BASEEXT).exp @otherfiles\n");
    # See realclean and ext/utils/make_ext for usage of Makefile.old
    push(@m, "	-$att{MV} $att{MAKEFILE} $att{MAKEFILE}.old 2>/dev/null\n");
    push(@m, "	$attribs{POSTOP}\n")   if $attribs{POSTOP};
    join("", @m);
}

sub realclean {
    my($self, %attribs) = @_;
    my(@m);
    push(@m,'
# Delete temporary files (via clean) and also delete installed files
realclean purge ::  clean
');
    # realclean subdirectories first (already cleaned)
    my $sub = "\t-cd %s && test -f %s && \$(MAKE) %s realclean\n";
    foreach(@{$att{DIR}}){
	push(@m, sprintf($sub,$_,"$att{MAKEFILE}.old","-f $att{MAKEFILE}.old"));
	push(@m, sprintf($sub,$_,"$att{MAKEFILE}",''));
    }
    push(@m, "	$att{RM_RF} \$(INST_AUTODIR) \$(INST_ARCHAUTODIR)\n");
    push(@m, "	$att{RM_F} \$(INST_DYNAMIC) \$(INST_BOOT)\n");
    push(@m, "	$att{RM_F} \$(INST_STATIC) \$(INST_PM)\n");
    my(@otherfiles) = ($att{MAKEFILE}, 
		       "$att{MAKEFILE}.old"); # Makefiles last
    push(@otherfiles, $attribs{FILES}) if $attribs{FILES};
    push(@m, "	$att{RM_RF} @otherfiles\n") if @otherfiles;
    push(@m, "	$attribs{POSTOP}\n")       if $attribs{POSTOP};
    join("", @m);
}


sub dist {
    my($self, %attribs) = @_;
    my(@m);
    # VERSION should be sanitised before use as a file name
    if ($attribs{TARNAME}){
	print STDOUT "Error (fatal): Attribute TARNAME for target dist is deprecated
Please use DISTNAME and VERSION";
    }
    my($name)     = $attribs{NAME}     || '$(DISTNAME)-$(VERSION)';            
    my($tar)      = $attribs{TAR}      || 'tar';        # eg /usr/bin/gnutar   
    my($tarflags) = $attribs{TARFLAGS} || 'cvf';                               
    my($compress) = $attribs{COMPRESS} || 'compress';   # eg gzip              
    my($suffix)   = $attribs{SUFFIX}   || 'Z';          # eg gz                
    my($shar)     = $attribs{SHAR}     || 'shar';       # eg "shar --gzip"     
    my($preop)    = $attribs{PREOP}    || '@ :';         # eg update MANIFEST   
    my($postop)   = $attribs{POSTOP}   || '@ :';         # eg remove the distdir
    my($ci)       = $attribs{CI}       || 'ci -u';
    my($rcs)      = $attribs{RCS}      || 'rcs -Nv$(VERSION_SYM):';
    my($dist_default) = $attribs{DIST_DEFAULT} || 'tardist';

    push @m, "
TAR  = $tar
TARFLAGS = $tarflags
COMPRESS = $compress
SUFFIX = $suffix
SHAR = $shar
PREOP = $preop
POSTOP = $postop
CI = $ci
RCS = $rcs
DIST_DEFAULT = $dist_default
";

    push @m, q{
distclean :: realclean distcheck

distcheck :
	$(PERL) -I$(PERL_LIB) -e 'use ExtUtils::Manifest "&fullcheck";' \\
		-e 'fullcheck();'

manifest :
	$(PERL) -I$(PERL_LIB) -e 'use ExtUtils::Manifest "&mkmanifest";' \\
		-e 'mkmanifest();'

dist : $(DIST_DEFAULT)

tardist : $(DISTNAME)-$(VERSION).tar.$(SUFFIX)

$(DISTNAME)-$(VERSION).tar.$(SUFFIX) : distdir
	$(PREOP)
	$(TAR) $(TARFLAGS) $(DISTNAME)-$(VERSION).tar $(DISTNAME)-$(VERSION)
	$(COMPRESS) $(DISTNAME)-$(VERSION).tar
	$(RM_RF) $(DISTNAME)-$(VERSION)
	$(POSTOP)

uutardist : $(DISTNAME)-$(VERSION).tar.$(SUFFIX)
	uuencode $(DISTNAME)-$(VERSION).tar.$(SUFFIX) \\
		$(DISTNAME)-$(VERSION).tar.$(SUFFIX) > \\
		$(DISTNAME)-$(VERSION).tar.$(SUFFIX).uu

shdist : distdir
	$(PREOP)
	$(SHAR) $(DISTNAME)-$(VERSION) > $(DISTNAME)-$(VERSION).shar
	$(RM_RF) $(DISTNAME)-$(VERSION)
	$(POSTOP)

distdir :
	$(RM_RF) $(DISTNAME)-$(VERSION)
	$(PERL) -I$(PERL_LIB) -e 'use ExtUtils::Manifest "/mani/";' \\
		-e 'manicopy(maniread(),"$(DISTNAME)-$(VERSION)");'


ci :
	$(PERL) -I$(PERL_LIB) -e 'use ExtUtils::Manifest "&maniread";' \\
		-e '@all = keys %{maniread()};' \\
		-e 'print("Executing $(CI) @all\n"); system("$(CI) @all");' \\
		-e 'print("Executing $(RCS) ...\n"); system("$(RCS) @all");'

};
    join "", @m;
}


# --- Test and Installation Sections ---

sub test {
    my($self, %attribs) = @_;
    my($tests) = $attribs{TESTS} || (-d "t" ? "t/*.t" : "");
    my(@m);
    push(@m,"
TEST_VERBOSE=0
TEST_TYPE=test_$att{LINKTYPE}

test :: \$(TEST_TYPE)
");
    push(@m, map("\tcd $_ && test -f $att{MAKEFILE} && \$(MAKE) test \$(PASTHRU2)\n",
		 @{$att{DIR}}));
    push(@m, "\t\@echo 'No tests defined for \$(NAME) extension.'\n")
	unless $tests or -f "test.pl" or @{$att{DIR}};
    push(@m, "\n");

    push(@m, "test_dynamic :: all\n");
    push(@m, $self->test_via_harness('$(FULLPERL)', $tests)) if $tests;
    push(@m, $self->test_via_script('$(FULLPERL)', 'test.pl')) if -f "test.pl";
    push(@m, "\n");

    push(@m, "test_static :: all \$(MAP_TARGET)\n");
    push(@m, $self->test_via_harness('./$(MAP_TARGET)', $tests)) if $tests;
    push(@m, $self->test_via_script('./$(MAP_TARGET)', 'test.pl')) if -f "test.pl";
    push(@m, "\n");

    join("", @m);
}

sub test_via_harness {
    my($self, $perl, $tests) = @_;
    "\t$perl".q! -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -e 'use Test::Harness qw(&runtests $$verbose); $$verbose=$(TEST_VERBOSE); runtests @ARGV;' !."$tests\n";
}

sub test_via_script {
    my($self, $perl, $script) = @_;
    "\t$perl".' -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) test.pl
';
}


sub install {
    my($self, %attribs) = @_;
    my(@m);
    push @m, q{
doc_install ::
	@ echo Appending installation info to $(INSTALLARCHLIB)/perllocal.pod
	@ $(PERL) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB)  \\
		-e "use ExtUtils::MakeMaker; MM->writedoc('Module', '$(NAME)', \\
		'LINKTYPE=$(LINKTYPE)', 'VERSION=$(VERSION)', \\
		'EXE_FILES=$(EXE_FILES)')" >> $(INSTALLARCHLIB)/perllocal.pod
};

    push(@m, "
install :: pure_install doc_install

pure_install ::
");
    # install subdirectories first
    push(@m, map("\tcd $_ && test -f $att{MAKEFILE} && \$(MAKE) install\n",
		 @{$att{DIR}}));

    push(@m, "\t\@\$(PERL) -e 'foreach (\@ARGV){die qq{You do not have permissions to install into \$\$_\\n} unless -w \$\$_}' \$(INSTALLPRIVLIB) \$(INSTALLARCHLIB)
	: perl5.000 and MM pre 3.8 autosplit into INST_ARCHLIB, we delete these old files here
	$att{RM_F} \$(INSTALLARCHLIB)/auto/\$(FULLEXT)/*.al
	$att{RM_F} \$(INSTALLARCHLIB)/auto/\$(FULLEXT)/*.ix
	\$(MAKE) INST_LIB=\$(INSTALLPRIVLIB) INST_ARCHLIB=\$(INSTALLARCHLIB) INST_EXE=\$(INSTALLBIN)
	\@\$(PERL) -i.bak -lne 'print unless \$\$seen{\$\$_}++' \$(INSTALLARCHLIB)/auto/\$(FULLEXT)/.packlist
");

    push @m, '
#### UNINSTALL IS STILL EXPERIMENTAL ####
uninstall ::
';

    push(@m, map("\tcd $_ && test -f $att{MAKEFILE} && \$(MAKE) uninstall\n",
		 @{$att{DIR}}));
    push @m, "\t".'$(RM_RF) `cat $(INSTALLARCHLIB)/auto/$(FULLEXT)/.packlist`
';

    join("",@m);
}

sub force {
    '# Phony target to force checking subdirectories.
FORCE:
';
}


sub perldepend {
    my(@m);
    push(@m,'
PERL_HDRS = $(PERL_INC)/EXTERN.h $(PERL_INC)/INTERN.h \
    $(PERL_INC)/XSUB.h	$(PERL_INC)/av.h	$(PERL_INC)/cop.h \
    $(PERL_INC)/cv.h	$(PERL_INC)/dosish.h	$(PERL_INC)/embed.h \
    $(PERL_INC)/form.h	$(PERL_INC)/gv.h	$(PERL_INC)/handy.h \
    $(PERL_INC)/hv.h	$(PERL_INC)/keywords.h	$(PERL_INC)/mg.h \
    $(PERL_INC)/op.h	$(PERL_INC)/opcode.h	$(PERL_INC)/patchlevel.h \
    $(PERL_INC)/perl.h	$(PERL_INC)/perly.h	$(PERL_INC)/pp.h \
    $(PERL_INC)/proto.h	$(PERL_INC)/regcomp.h	$(PERL_INC)/regexp.h \
    $(PERL_INC)/scope.h	$(PERL_INC)/sv.h	$(PERL_INC)/unixish.h \
    $(PERL_INC)/util.h	$(PERL_INC)/config.h

');

    push @m, '
$(OBJECT) : $(PERL_HDRS)
' if $att{OBJECT};

    push(@m,'
# Check for unpropogated config.sh changes. Should never happen.
# We do NOT just update config.h because that is not sufficient.
# An out of date config.h is not fatal but complains loudly!
$(PERL_INC)/config.h: $(PERL_SRC)/config.sh
	-@echo "Warning: $(PERL_INC)/config.h out of date with $(PERL_SRC)/config.sh"; false

$(PERL_ARCHLIB)/Config.pm: $(PERL_SRC)/config.sh
	@echo "Warning: $(PERL_ARCHLIB)/Config.pm may be out of date with $(PERL_SRC)/config.sh"
	cd $(PERL_SRC) && $(MAKE) lib/Config.pm
') if $att{PERL_SRC};

    push(@m, join(" ", values %{$att{XS}})." : \$(XSUBPPDEPS)\n")
	if %{$att{XS}};
    join("\n",@m);
}


sub makefile {
    my @m;
    # We do not know what target was originally specified so we
    # must force a manual rerun to be sure. But as it should only
    # happen very rarely it is not a significant problem.
    push @m, '
$(OBJECT) : '.$att{MAKEFILE}.'

# We take a very conservative approach here, but it\'s worth it.
# We move Makefile to Makefile.old here to avoid gnu make looping.
'.$att{MAKEFILE}.' :	Makefile.PL $(CONFIGDEP)
	@echo "Makefile out-of-date with respect to $?"
	@echo "Cleaning current config before rebuilding Makefile..."
	-@mv '."$att{MAKEFILE} $att{MAKEFILE}.old".'
	-$(MAKE) -f '.$att{MAKEFILE}.'.old clean >/dev/null 2>&1 || true
	$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" Makefile.PL '."@ARGV".'
	@echo "Now you must rerun make."; false
';

    join "", @m;
}

sub postamble{
    "";
}

# --- Make-Directories section (internal method) ---
# dir_target(@array) returns a Makefile entry for the file .exists in each
# named directory. Returns nothing, if the entry has already been processed.
# We're helpless though, if the same directory comes as $(FOO) _and_ as "bar".
# Both of them get an entry, that's why we use "::". I chose '$(PERL)' as the 
# prerequisite, because there has to be one, something that doesn't change 
# too often :)
%Dir_Target = (); # package global

sub dir_target {
    my($self,@dirs) = @_;
    my(@m,$dir);
    foreach $dir (@dirs) {
	next if $Dir_Target{$dir};
	push @m, "
$dir/.exists :: \$(PERL)
	\@ \$(MKPATH) $dir
	\@ \$(TOUCH) $dir/.exists
";
	$Dir_Target{$dir}++;
    }
    join "", @m;
}

# --- Make-A-Perl section ---

sub staticmake {
    my($self, %attribs) = @_;

    my(%searchdirs)=($att{PERL_ARCHLIB} => 1,  $att{INST_ARCHLIB} => 1);
    my(@searchdirs)=keys %searchdirs;
    # And as it's not yet built, we add the current extension
    my(@static)="$att{INST_ARCHLIB}/auto/$att{FULLEXT}/$att{BASEEXT}.a";
    my(@perlinc) = ($att{INST_ARCHLIB}, $att{INST_LIB}, $att{PERL_ARCHLIB}, $att{PERL_LIB});
    MY->makeaperl('MAKE' => $att{MAKEFILE}, 
			     'DIRS' => \@searchdirs, 
			     'STAT' => \@static, 
			     'INCL' => \@perlinc,
			     'TARGET' => $att{MAP_TARGET},
			     'TMP' => "",
			     'LIBPERL' => $att{LIBPERL_A}
			     );
}

sub makeaperl {
    my($self, %attribs) = @_;
    my($makefilename, $searchdirs, $static, $extra, $perlinc, $target, $tmp, $libperl) = 
      @attribs{qw(MAKE DIRS STAT EXTRA INCL TARGET TMP LIBPERL)};
    my(@m);
    my($cccmd, $linkcmd);

    # This emulates cflags to get the compiler invocation...
    $cccmd = MY->const_cccmd($libperl);
    $cccmd =~ s/^CCCMD\s*=\s*//;
    chomp $cccmd;
    $cccmd =~ s/\s/ -I$att{PERL_INC} /;
    $cccmd .= " $Config{'cccdlflags'}" if ($Config{'d_shrplib'});

    # The front matter of the linkcommand...
    $linkcmd = join ' ', "\$(CC)",
	    grep($_, @Config{qw(large split ldflags ccdlflags)});
    $linkcmd =~ s/\s+/ /g;

    # Which *.a files could we make use of...
    local(%static);
    File::Find::find(sub {
	return unless m/\.a$/;
	return if m/^libperl/;
	# don't include the installed version of this extension
	return if $File::Find::name =~ m:auto/$att{FULLEXT}/$att{BASEEXT}.a$:;
	$static{fastcwd() . "/" . $_}++;
    }, grep( -d $_, @{$searchdirs || []}) );

    # We trust that what has been handed in as argument, will be buildable
    $static = [] unless $static;
    @static{@{$static}} = (1) x @{$static};

    $extra = [] unless $extra && ref $extra eq 'ARRAY';
    for (sort keys %static) {
	next unless /\.a$/;
	$_ = dirname($_) . "/extralibs.ld";
	push @$extra, $_;
    }

    grep(s/^/-I/, @$perlinc);

    $target = "perl" unless $target;
    $tmp = "." unless $tmp;

    push @m, "
# --- MakeMaker makeaperl section ---
MAP_TARGET    = $target
FULLPERL      = $att{'FULLPERL'}
MAP_LINKCMD   = $linkcmd
MAP_PERLINC   = @{$perlinc}
MAP_STATIC    = ",
join(" ", sort keys %static), "
MAP_PRELIBS   = $Config{'libs'} $Config{'cryptlib'}
";

    unless ($libperl && -f $libperl) {
	my $dir = $att{PERL_SRC} || "$att{PERL_ARCHLIB}/CORE";
	$libperl ||= "libperl.a";
	$libperl = "$dir/$libperl";
	print STDOUT "Warning: $libperl not found"
		unless (-f $libperl || defined($att{PERL_SRC}));
    }

    push @m, "
MAP_LIBPERL = $libperl
";

    push @m, "
extralibs.ld: @$extra
	\@ $att{RM_F} \$\@
	\@ \$(TOUCH) \$\@
";

    foreach (@$extra){
	push @m, "\tcat $_ >> \$\@\n";
    }

    push @m, "
\$(MAP_TARGET): $tmp/perlmain.o \$(MAP_LIBPERL) \$(MAP_STATIC) extralibs.ld
	\$(MAP_LINKCMD) -o \$\@ $tmp/perlmain.o \$(MAP_LIBPERL) \$(MAP_STATIC) `cat extralibs.ld` \$(MAP_PRELIBS)
	@ echo 'To install the new \"\$(MAP_TARGET)\" binary, call'
	@ echo '    make -f $makefilename inst_perl MAP_TARGET=\$(MAP_TARGET)'
	@ echo 'To remove the intermediate files say'
	@ echo '    make -f $makefilename map_clean'

$tmp/perlmain.o: $tmp/perlmain.c
";
    push @m, "\tcd $tmp && $cccmd perlmain.c\n";

    push @m, qq{
$tmp/perlmain.c: $makefilename}, q{
	@ echo Writing $@
	@ $(FULLPERL) $(MAP_PERLINC) -e 'use ExtUtils::Miniperl; \\
		writemain(grep s#.*/auto/##, qw|$(MAP_STATIC)|)' > $@.tmp && mv $@.tmp $@

};

# We write EXTRA outside the perl program to have it eval'd by the shell
    push @m, q{
doc_inst_perl:
	@ echo Appending installation info to $(INSTALLARCHLIB)/perllocal.pod
	@ $(FULLPERL) -e 'use ExtUtils::MakeMaker; MM->writedoc("Perl binary",' \\
		-e '"$(MAP_TARGET)", "MAP_STATIC=$(MAP_STATIC)",' \\
		-e '"MAP_EXTRA=@ARGV", "MAP_LIBPERL=$(MAP_LIBPERL)")' \\
		-- `cat extralibs.ld` >> $(INSTALLARCHLIB)/perllocal.pod
};

    push @m, qq{
inst_perl: pure_inst_perl doc_inst_perl

pure_inst_perl: \$(MAP_TARGET)
	$att{CP} \$(MAP_TARGET) \$(INSTALLBIN)/\$(MAP_TARGET)

clean :: map_clean

map_clean :
	$att{RM_F} $tmp/perlmain.o $tmp/perlmain.c \$(MAP_TARGET) extralibs.ld
};

    join '', @m;
}

sub extliblist {
    my($self,$libs) = @_;
    require ExtUtils::Liblist;
    ExtUtils::Liblist::ext($libs, $Verbose);
}

sub mksymlists {
    my($self) = shift;
    my($pkg);

    # only AIX requires a symbol list at this point
    # (so does VMS, but that's handled by the MM_VMS package)
    return '' unless $Config{'osname'} eq 'aix';

    init_main(@ARGV) unless defined $att{'BASEEXT'};
    if (! $att{DL_FUNCS}) {
	my($bootfunc);
	($bootfunc = $att{NAME}) =~ s/\W/_/g;
	$att{DL_FUNCS} = {$att{BASEEXT} => ["boot_$bootfunc"]};
    }
    rename "$att{BASEEXT}.exp", "$att{BASEEXT}.exp_old";

    open(EXP,">$att{BASEEXT}.exp") or die $!;
    print EXP join("\n",@{$att{DL_VARS}}) if $att{DL_VARS};
    foreach $pkg (keys %{$att{DL_FUNCS}}) {
        (my($prefix) = $pkg) =~ s/\W/_/g;
	my $func;
        foreach $func (@{$att{DL_FUNCS}->{$pkg}}) {
            $func = "XS_${prefix}_$func" unless $func =~ /^boot_/;
            print EXP "$func\n";
        }
    }
    close EXP;
}

# --- Output postprocessing section ---
#nicetext is included to make VMS support easier
sub nicetext { # Just return the input - no action needed
    my($self,$text) = @_;
    $text;
}

# --- perllocal.pod section ---
sub writedoc {
    my($self,$what,$name,@attribs)=@_;
# the following would have to move to a ExtUtils::Perllocal.pm, if we want it
# it's dangerous wrt AFS, and it's against the philosophy that MakeMaker
# should never write to files. We write to stdout and append to the file
# during make install, but we cannot rely on '-f $Config{"installarchlib"},
# as there is a time window between the WriteMakefile and the make.
#    -w $Config{'installarchlib'} or die "No write permission to $Config{'installarchlib'}";
#    my($localpod) = "$Config{'installarchlib'}/perllocal.pod";
    my($time);
#    if (-f $localpod) {
#	print "Appending installation info to $localpod\n";
#	open POD, ">>$localpod" or die "Couldn't open $localpod";
#    } else {
#	print "Writing new file $localpod\n";
#	open POD, ">$localpod" or die "Couldn't open $localpod";
#	print POD "=head1 NAME
#
#perllocal - locally installed modules and perl binaries
#\n=head1 HISTORY OF LOCAL INSTALLATIONS
#
#";
#    }
    require "ctime.pl";
    chop($time = ctime(time));
    print "=head2 $time: $what C<$name>\n\n=over 4\n\n=item *\n\n";
    print join "\n\n=item *\n\n", map("C<$_>",@attribs);
    print "\n\n=back\n\n";
#    close POD;
}



# the following keeps AutoSplit happy
package ExtUtils::MakeMaker;
1;

__END__

=head1 NAME

ExtUtils::MakeMaker - create an extension Makefile

=head1 SYNOPSIS

C<use ExtUtils::MakeMaker;>

C<WriteMakefile( ATTRIBUTE =E<gt> VALUE [, ...] );>

=head1 DESCRIPTION

This utility is designed to write a Makefile for an extension module
from a Makefile.PL. It is based on the Makefile.SH model provided by
Andy Dougherty and the perl5-porters.

It splits the task of generating the Makefile into several subroutines
that can be individually overridden.  Each subroutine returns the text
it wishes to have written to the Makefile.

MakeMaker.pm uses the architecture specific information from
Config.pm. In addition the extension may contribute to the C<%Config>
hash table of Config.pm by supplying hints files in a C<hints/>
directory. The hints files are expected to be named like their
counterparts in C<PERL_SRC/hints>, but with an C<.pl> file name
extension (eg. C<next_3_2.pl>). They are simply C<eval>ed by MakeMaker
within the WriteMakefile() subroutine, and can be used to execute
commands as well as to include special variables. If there is no
hintsfile for the actual system, but for some previous releases of the
same operating system, the latest one of those is used.

=head2 Default Makefile Behaviour

The automatically generated Makefile enables the user of the extension
to invoke

  perl Makefile.PL # optionally "perl Makefile.PL verbose"
  make
  make test # optionally set TEST_VERBOSE=1
  make install # See below

The Makefile to be produced may be altered by adding arguments of the
form C<KEY=VALUE>. If the user wants to work with a different perl
than the default, this is achieved by specifying

  perl Makefile.PL PERL=/tmp/myperl5

Other interesting targets in the generated Makefile are

  make config     # to check if the Makefile is up-to-date
  make clean      # delete local temporary files (Makefile gets renamed)
  make realclean  # delete all derived files (including installed files)
  make dist       # see below the Distribution Support section

=head2 Special case C<make install>

C<make> alone puts all relevant files into directories that are named
by the macros INST_LIB, INST_ARCHLIB, and INST_EXE. All three default
to ./blib if you are I<not> building below the perl source directory. If
you I<are> building below the perl source, INST_LIB and INST_ARCHLIB
default to ../../lib, and INST_EXE is not defined.

The I<install> target of the generated Makefile is a recursive call to
make which sets

    INST_LIB     to INSTALLPRIVLIB
    INST_ARCHLIB to INSTALLARCHLIB
    INST_EXE     to INSTALLBIN

The three INSTALL... macros in turn default to
$Config{installprivlib}, $Config{installarchlib}, and
$Config{installbin} respectively.

The recommended way to proceed is to set only the INSTALL* macros, not
the INST_* targets. In doing so, you give room to the compilation
process without affecting important directories. Usually a 'make test'
will succeed after the make, and a 'make install' can finish the game.

MakeMaker gives you much more freedom than needed to configure
internal variables and get different results. It is worth to mention,
that make(1) also lets you configure most of the variables that are
used in the Makefile. But in the majority of situations this will not
be necessary, and should only be done, if the author of a package
recommends it.

The usual relationship between INSTALLPRIVLIB and INSTALLARCHLIB is
that the latter is a subdirectory of the former with the name
C<$Config{'archname'}>, MakeMaker supports the user who sets
INSTALLPRIVLIB. If INSTALLPRIVLIB is set, but INSTALLARCHLIB not, then
MakeMaker defaults the latter to be INSTALLPRIVLIB/ARCHNAME if that
directory exists, otherwise it defaults to INSTALLPRIVLIB.

Previous versions of MakeMaker suggested to use the INST_* macros. For
backwards compatibility, these are still supported but deprecated in
favor of the INSTALL* macros.

Here is the description, what they are used for: If the user specifies
the final destination for the INST_... macros, then there is no need
to call 'make install', because 'make' will already put all files in
place.

If there is a need to first build everything in the C<./blib>
directory and test the product, then it's appropriate to use the
INSTALL... macros. So the users have the choice to either say

    # case: trust the module
    perl Makefile.PL INST_LIB=~/perllib INST_EXE=~/bin
    make
    make test

or

    perl Makefile.PL INSTALLPRIVLIB=~/foo \
            INSTALLARCHLIB=~/foo/bar  INSTALLBIN=~/bin
    make
    make test
    make install

Note, that the tilde expansion is done by MakeMaker, not by perl by
default, nor by make. So be careful to use the tilde only with the
C<perl Makefile.PL> call.

It is important to know, that the INSTALL* macros should be absolute
paths, never relativ ones. Packages with multiple Makefile.PLs in
different directories get the contents of the INSTALL* macros
propagated verbatim. (The INST_* macros will be corrected, if they are
relativ paths, but not the INSTALL* macros.)

If the user has superuser privileges, and is not working on AFS
(Andrew File System) or relatives, then the defaults for
INSTALLPRIVLIB, INSTALLARCHLIB, and INSTALLBIN will be appropriate,
and this incantation will be the best:

    perl Makefile.PL; make; make test
    make install

(I<make test> is not necessarily supported for all modules.)

C<make install> per default writes some documentation of what has been
done into the file C<$Config{'installarchlib'}/perllocal.pod>. This is
an experimental feature. It can be bypassed by calling C<make
pure_install>.

=head2 Support to Link a new Perl Binary (eg dynamic loading not available)

An extension that is built with the above steps is ready to use on
systems supporting dynamic loading. On systems that do not support
dynamic loading, any newly created extension has to be linked together
with the available resources. MakeMaker supports the linking process
by creating appropriate targets in the Makefile whenever an extension
is built. You can invoke the corresponding section of the makefile with

    make perl

That produces a new perl binary in the current directory with all
extensions linked in that can be found in INST_ARCHLIB (usually
C<./blib>) and PERL_ARCHLIB.

The binary can be installed into the directory where perl normally
resides on your machine with

    make inst_perl

To produce a perl binary with a different name than C<perl>, either say

    perl Makefile.PL MAP_TARGET=myperl
    make myperl
    make inst_perl

or say

    perl Makefile.PL
    make myperl MAP_TARGET=myperl
    make inst_perl MAP_TARGET=myperl

In any case you will be prompted with the correct invocation of the
C<inst_perl> target that installs the new binary into INSTALLBIN.

Note, that there is a C<makeaperl> scipt in the perl distribution,
that supports the linking of a new perl binary in a similar fashion,
but with more options.

C<make inst_perl> per default writes some documentation of what has been
done into the file C<$Config{'installarchlib'}/perllocal.pod>. This
can be bypassed by calling C<make pure_inst_perl>.

Warning: the inst_perl: target is rather mighty and will probably
overwrite your existing perl binary. Use with care!

=head2 Determination of Perl Library and Installation Locations

MakeMaker needs to know, or to guess, where certain things are
located.  Especially INST_LIB and INST_ARCHLIB (where to install files
into), PERL_LIB and PERL_ARCHLIB (where to read existing modules
from), and PERL_INC (header files and C<libperl*.*>).

Extensions may be built either using the contents of the perl source
directory tree or from an installed copy of the perl library.

If an extension is being built below the C<ext/> directory of the perl
source then MakeMaker will set PERL_SRC automatically (e.g., C<../..>).
If PERL_SRC is defined then other variables default to the following:

  PERL_INC     = PERL_SRC
  PERL_LIB     = PERL_SRC/lib
  PERL_ARCHLIB = PERL_SRC/lib
  INST_LIB     = PERL_LIB
  INST_ARCHLIB = PERL_ARCHLIB

If an extension is being built away from the perl source then MakeMaker
will leave PERL_SRC undefined and default to using the installed copy
of the perl library. The other variables default to the following:

  PERL_INC     = $archlib/CORE
  PERL_LIB     = $privlib
  PERL_ARCHLIB = $archlib
  INST_LIB     = ./blib
  INST_ARCHLIB = ./blib

If perl has not yet been installed then PERL_SRC can be defined on the
command line as shown in the previous section.

=head2 Useful Default Makefile Macros

FULLEXT = Pathname for extension directory (eg DBD/Oracle).

BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT.

ROOTEXT = Directory part of FULLEXT with leading slash (eg /DBD)

PERL_LIB = Directory where we read the perl library files

PERL_ARCHLIB = Same as above for architecture dependent files

INST_LIB = Directory where we put library files of this extension
while building it. If we are building below PERL_SRC/ext
we default to PERL_SRC/lib, else we default to ./blib.

INST_ARCHLIB = Same as above for architecture dependent files

INST_LIBDIR = C<$(INST_LIB)$(ROOTEXT)>

INST_AUTODIR = C<$(INST_LIB)/auto/$(FULLEXT)>

INST_ARCHAUTODIR = C<$(INST_ARCHLIB)/auto/$(FULLEXT)>

=head2 Customizing The Generated Makefile

If the Makefile generated does not fit your purpose you can change it
using the mechanisms described below.

=head2 Using Attributes (and Parameters)

The following attributes can be specified as arguments to WriteMakefile()
or as NAME=VALUE pairs on the command line:

This description is not yet documented; you can get at the description
with one of the commands

=over 4

=item C<perl Makefile.PL help>
(if you already have a basic Makefile.PL)

=item C<make help>
(if you already have a Makefile)

=item C<perl -e 'use ExtUtils::MakeMaker "&help"; &help;'>
(if you have neither nor)

=back

=head2 Overriding MakeMaker Methods

If you cannot achieve the desired Makefile behaviour by specifying
attributes you may define private subroutines in the Makefile.PL.
Each subroutines returns the text it wishes to have written to
the Makefile. To override a section of the Makefile you can
either say:

	sub MY::c_o { "new literal text" }

or you can edit the default by saying something like:

	sub MY::c_o { $_=MM->c_o; s/old text/new text/; $_ }

If you still need a different solution, try to develop another
subroutine, that fits your needs and submit the diffs to
F<perl5-porters@nicoh.com> or F<comp.lang.perl> as appropriate.

=head2 Distribution Support

For authors of extensions MakeMaker provides several Makefile
targets. Most of the support comes from the ExtUtils::Manifest module,
where additional documentation can be found.

=over 4

=item    make distcheck
reports which files are below the build directory but not in the
MANIFEST file and vice versa. (See ExtUtils::Manifest::fullcheck() for
details)

=item    make distclean
does a realclean first and then the distcheck. Note that this is not
needed to build a new distribution as long as you are sure, that the
MANIFEST file is ok.

=item    make manifest
rewrites the MANIFEST file, adding all remaining files found (See
ExtUtils::Manifest::mkmanifest() for details)

=item    make distdir
Copies all the files that are in the MANIFEST file to a newly created
directory with the name C<$(DISTNAME)-$(VERSION)>. If that directory
exists, it will be removed first.

=item    make tardist
First does a command $(PREOP) which defaults to a null command. Does a
distdir next and runs C<tar> on that directory into a tarfile. Then
deletes the distdir. Finishes with a command $(POSTOP) which defaults
to a null command.

=item    make dist
Defaults to $(DIST_DEFAULT) which in turn defaults to tardist.

=item    make uutardist
Runs a tardist first and uuencodes the tarfile.

=item    make shdist
First does a command $(PREOP) which defaults to a null command. Does a
distdir next and runs C<shar> on that directory into a sharfile. Then
deletes the distdir. Finishes with a command $(POSTOP) which defaults
to a null command.  Note: For shdist to work properly a C<shar>
program that can handle directories is mandatory.

=item    make ci
Does a $(CI) (defaults to C<ci -u>) and a $(RCS) (C<rcs -q
-Nv$(VERSION_SYM):>) on all files in the MANIFEST file

Customization of the dist targets can be done by specifying a hash
reference to the dist attribute of the WriteMakefile call. The
following parameters are recognized:

    TAR          ('tar')
    TARFLAGS     ('cvf')
    COMPRESS     ('compress')
    SUFFIX       ('Z')
    SHAR         ('shar')
    PREOP        ('@ :')
    POSTOP       ('@ :')

An example:

    WriteMakefile( 'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" })

=back

=head1 AUTHORS

Andy Dougherty F<E<lt>doughera@lafcol.lafayette.eduE<gt>>, Andreas
Koenig F<E<lt>k@franz.ww.TU-Berlin.DEE<gt>>, Tim Bunce
F<E<lt>Tim.Bunce@ig.co.ukE<gt>>.  VMS support by Charles Bailey
F<E<lt>bailey@HMIVAX.HUMGEN.UPENN.EDUE<gt>>. Contact the makemaker
mailing list L<mailto:makemaker@franz.ww.tu-berlin.de>, if you have any
questions.

=head1 MODIFICATION HISTORY

v1, August 1994; by Andreas Koenig. Based on Andy Dougherty's Makefile.SH.
v2, September 1994 by Tim Bunce.
v3.0 October  1994 by Tim Bunce.
v3.1 November 11th 1994 by Tim Bunce.
v3.2 November 18th 1994 by Tim Bunce.
v3.3 November 27th 1994 by Andreas Koenig.
v3.4 December  7th 1994 by Andreas Koenig and Tim Bunce.
v3.5 December 15th 1994 by Tim Bunce.
v3.6 December 15th 1994 by Tim Bunce.
v3.7 December 30th 1994 By Tim Bunce
v3.8 January  17th 1995 By Andreas Koenig and Tim Bunce
v3.9 January 19th 1995 By Tim Bunce
v3.10 January 23rd 1995 By Tim Bunce
v3.11 January 24th 1995 By Andreas Koenig
v4.00 January 24th 1995 By Tim Bunce
v4.01 January 25th 1995 By Tim Bunce
v4.02 January 29th 1995 By Andreas Koenig
v4.03 January 30th 1995 By Andreas Koenig
v4.04 Februeary 5th 1995 By Andreas Koenig
v4.05 February 8th 1995 By Andreas Koenig
v4.06 February 10th 1995 By Andreas Koenig
v4.061 February 12th 1995 By Andreas Koenig
v4.08 - 4.085  February 14th-21st 1995 by Andreas Koenig
v4.086 March 9 1995 by Andy Dougherty
v4.09 March 31 1995 by Andreas Koenig
v4.091 April 3 1995 by Andy Dougherty
v4.092 April 11 1995 by Andreas Koenig
v4.093 April 12 1995 by Andy Dougherty
v4.094 April 12 1995 by Andy Dougherty

v4.100 May 10 1995 by Andreas Koenig

Broken out Mkbootstrap to make the file smaller and easier to manage,
and to speed up the build process.

Added ExtUtils::Manifest as an extra module that is used to streamline
distributions. (See pod section I<distribution support>).

Added a VERSION_SYM macro, that is derived from VERSION but all C<\W>
characters replaced by an underscore.

Moved the whole documentation below __END__ for easier maintanance.

linkext =E<gt> { LINKTYPE =E<gt> '' } should work now as expected.

Rechecked the use of INST_LIB, INST_ARCHLIB, and INST_EXE from the
perspective of an AFS user (thanks to Rudolph T Maceyko for the
hint). With full backward compatiblity it is now possible, to set
INSTALLPRIVLIB, INSTALLARCHLIB, and INSTALLBIN either with 'perl
Makefile.PL' or with 'make install'. A bare 'make' ignores these
settings.  The effect of this change is that it is no longer
recommended to set the INST_* attributes directly, although it doesn't
hurt, if they do so. The PASTHRU variables (now PASTHRU1 and PASTHRU2)
are fully aware of their duty: the INST_* attributes are only
propagated to runsubdirpl, not to 'cd subdir && make config' and 'cd
subdir && make all'.

Included Tim's "Unable to locate Perl library" patch.

Eliminated any excess of spaces in the $old/$new comparison in
const_cccmd().

Added a prompt function with usage $answer = prompt $message, $default.

Included Tim's patch that searches for perl5 and perl$] as well as
perl and miniperl.

Added .NO_PARALLEL for the time until I have a multiple cpu machine
myself :)

Introduced a macro() subroutine. WriteMakefile("macro" =E<gt> { FOO
=E<gt> BAR }) defines the macro FOO = BAR in the generated Makefile.

Rolled in Tim's patch for needs_linking.

writedoc now tries to be less clever. It was trying to determine, if a
perllocal.pod had to be created or appended to. As we have now the
possibility, that INSTALLARCHLIB is determined at make's runtime, we
cannot do this anymore. We append to that file in any case.

Added Kenneth's pod installation patch.

v4.110 May 19 1995 by Andreas Koenig

=head1 NEW in 4.11

MANIFEST.SKIP now contains only regular expressions. RCS directories
are no longer skipped by default, as this may be configured in the
SKIP file.

The manifest target now does no realclean anymore.

I_PERL_LIBS depreciated (no longer used). (unless you speak up, of
course)

I could not justify that we rebuild the Makefile when MakeMaker has
changed (as Kenneth suggested). If this is really a strong desire,
please convince me. But a minor change of the MakeMaker should not
trigger a 60 minutes rebuild of Tk, IMO.

Broken out extliblist into the new module ExtUtils::Liblist. Should
help extension writers for their own Configure scripts. The breaking
into pieces should be done now, I suppose.

Added an (experimenta!!) uninstall target that works with a
packlist. AutoSplit files are not yet in the packlist. This needs a
patch to AutoSplit, doesn't it? The packlist file is installed in
INST_ARCHAUTODIR/.packlist. It doesn't have means to decide, if a file
is architecture dependent or not, we just collect as much as we can
get. make -n recommended before actually executing. (I leave this
target undocumented in the pod section). Suggestions welcome!

Added basic chmod support. Nothing spectacular. *.so and *.a files get
permission 755, because I seem to recall, that some systems need
execute permissions in some weird constellations. The rest becomes
644. What else do we need to make this flexible?

Then I took Tim's word serious: no bloat. No turning all packages into
perl scripts. Leaving shar, tar, uu be what they are... Sorry,
Kenneth, we still have to convince Larry that a growing MakeMaker
makes sense :)

Added an extra check whenever they install below the perl source tree:
is this extension a standard extension? If it is, everything behaves
as we are used to. If it is not, the three INST_ macros are set to
./blib, and they get a warning that this extension has to be
installed manually with 'make install'.

Added a warning for targets that have a colon or a hashmark within
their names, because most make(1)s will not be able to process them.

Applied Hallvard's patch to ~user evaluation for cases where user does
not exist.

Added a ci target that checks in all files from the MANIFEST into rcs.

=head1 new in 4.12/4.13

"Please notify perl5-porters" message is now accompanied by
Config::myconfig().

(Manifest.pm) Change delimiter for the evaluation of the regexes from
MANIFEST.SKIP to from "!" to "/". I had overlooked the fact, that ! no
has a meaning in regular expressions.

Disabled the new logic that prevents non-standard extensions from
writing to PERL_SRC/lib to give Andy room for 5.001f.

Added a Version_check target that calls MakeMaker for a simple Version
control function on every invocation of 'make' in the future. Doesn't
have an effect currently.

Target dist is still defaulting to tardist, but the level of
indirection has changed. The Makefile macro DIST_DEFAULT takes it's
place. This allows me to make dist dependent from whatever I intend as
my standard distribution.

Made sure that INST_EXE is created for extensions that need it.

4.13 is just a cleanup/documentation patch. And it adds a MakeMaker FAQ :)

=head v4.14 June 5, 1995, by Andreas Koenig

Reintroduces the LD_RUN_PATH macro. LD_RUN_PATH is passed as an
environment variable to the ld run. It is needed on Sun OS, and does
no harm on other systems. It is a colon seperated list of the
directories in LDLOADLIBS.

=head v4.15 June 6, 1995, by Andreas Koenig

Add -I$(PERL_ARCHLIB) -I$(PERL_LIB) to calls to xsubpp.

=head v4.16 June 18, 1995, by Tim Bunce

Split test: target into test_static: and test_dynamic: with automatic
selection based on LINKTYPE. The test_static: target automatically
builds a local ./perl binary containing the extension and executes the
tests using that binary. This fixes problems that users were having
dealing with building and testing static extensions. It also simplifies
the process down to the standard: make + make test.

MakeMaker no longer incorrectly considers a perlmain.c file to be part
of an extensions source files. The map_clean target is now invoked by
clean not realclean and now deletes MAP_TARGET but does not delete
Makefile (since that's done properly elsewhere).

Since the staticmake section defines macros that the test target now
needs the test section is written into the makefile after the
staticmake section.  The postamble section has been made last again, as
it should be.

=head1 TODO

Needs more complete documentation.

Add a C<html:> target when there has been found a general solution to
installing html files.

Add a FLAVOR variable that makes it easier to build debugging,
embedded or multiplicity perls. Currently the easiest way to produce a
debugging perl seems to be (after haveing built perl):
    make clobber
    ./Configure -D"archname=IP22-irix-d" -des
    make perllib=libperld.a
    make test perllib=libperld.a
    mv /usr/local/bin/perl /usr/local/bin/perl/O_perl5.001e
    make install perllib=libperld.a
    cp /usr/local/bin/perl/O_perl5.001e /usr/local/bin/perl
It would be nice, if the Configure step could be dropped. Also nice, but 
maybe expensive, if 'make clobber' wouldn't be needed.

The uninstall target has to be completed, it's just a sketch.

Reconsider Makefile macros. The output of macro() should be the last
before PASTHRU and none should come after that -- tough work.

Think about Nick's desire, that the pTk subdirectory needs a special
treatment.

Find a way to have multiple MYEXTLIB archive files combined into
one. Actually I need some scenario, where this problem can be
illustrated. I currently don't see the problem.

Test if .NOPARALLEL can be omitted.

Don't let extensions write to PERL_SRC/lib anymore, build perl from
the extensions found below ext, run 'make test' and 'make install' on
each extension (giving room for letting them fail). Move some of the
tests from t/lib/* to the libraries.

Streamline the production of a new perl binary on systems that DO have
dynamic loading (especially make test needs further support, as test
most probably needs the new binary).

=cut
