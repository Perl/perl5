package ExtUtils::MakeMaker;

$Version = 4.06; # Last edited 10th Feb 1995 by Andreas Koenig

use Config;
check_hints();
use Carp;
use Cwd;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(&WriteMakefile &mkbootstrap &mksymlists $Verbose);
@EXPORT_OK = qw($Version %att %skip %Recognized_Att_Keys
	@MM_Sections %MM_Sections
	&help &lsdir &neatvalue);

$Is_VMS = $Config{'osname'} eq 'VMS';
require ExtUtils::MM_VMS if $Is_VMS;

use strict qw(refs);

$Version = $Version;# avoid typo warning
$Verbose = 0;
$^W=1;


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
extension (eg. C<next_3_2.sh>). They are simply C<eval>ed by MakeMaker
and can be used to execute commands as well as to include special
variables. If there is no hintsfile for the actual system, but for
some previous releases of the same operating system, the latest one of
those is used.

=head2 Default Makefile Behaviour

The automatically generated Makefile enables the user of the extension
to invoke

  perl Makefile.PL
  make
  make test
  make install # May need to invoke as root to write into INST_LIB

The Makefile to be produced may be altered by adding arguments of the
form C<KEY=VALUE>. If the user wants to have the extension installed
into a directory different from C<$Config{"installprivlib"}> it can be
done by specifying

  perl Makefile.PL INST_LIB=~/myperllib

Note, that in this example MakeMaker does the tilde expansion for you
and INST_ARCHLIB is set to either C<INST_LIB/$Config{"osname"}> if
that directory exists and otherwise to INST_LIB.

Other interesting targets in the generated Makefile are

  make config     # to check if the Makefile is up-to-date
  make clean      # delete local temporary files (Makefile gets renamed)
  make realclean  # delete all derived files (including installed files)
  make distclean  # produce a gzipped file ready for shipping

The macros in the produced Makefile may be overridden on the command
line to the make call as in the following example:

  make INST_LIB=/some/where INST_ARCHLIB=/some/where

Note, that this is a solution provided by C<make> in general, so tilde
expansion will probably not be available and INST_ARCHLIB will not be
set automatically when INST_LIB is given as argument.

The generated Makefile does not set any permissions. The installer has
to decide, which umask should be in effect.

=head2 Support to Link a New Perl Binary

An extension that is built with the above steps is ready to use on
systems supporting dynamic loading. On systems that do not support
dynamic loading, any newly created extension has to be linked together
with the available ressources. MakeMaker supports the linking process
by creating appropriate targets in the Makefile whenever an extension
is built. You can invoke the corresponding section of the makefile with

    make perl

That produces a new perl binary in the current directory with all
extensions that are present on the system (either in the current build
environment or in the perl library) linked in.

The binary can be installed into the directory where perl normally
resides on your machine with

    make inst_perl

Note, that there is a C<makeaperl> scipt available, that supports the
linking of a new perl binary in a similar fashion, but with more
options for those, that want to build perl binaries of the
not-quite-everyday type. 

Warning: The perl: and inst_perl: targets are new in MakeMaker v4.06,
and should be watched with care. Watch out for what it does and what
you want!

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
with the command

C<perl Makefile.PL help>    (if you already have a basic Makefile.PL)

or

C<perl -e 'use ExtUtils::MakeMaker qw(&help); &help;'>

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

=cut

sub check_hints {
    # We allow extension-specific hints files. If we find one we act as if Config.pm
    # had read the contents

    # First we look for the best hintsfile we have
    my(@goodhints);
    my($hint)="$Config{'osname'}_$Config{'osvers'}";
    $hint =~ s/\./_/g;
    $hint =~ s/_$//;
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
    $hint=(reverse sort @goodhints)[0];

    # execute the hintsfile:
    eval `cat hints/$hint.pl`;
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

 INST_LIB:	Perl library directory to install the module into.
 INST_ARCHLIB:	Perl architecture-dependent library to install into
		(defaults to INST_LIB)

 PERL_LIB:	Directory containing the Perl library to use.
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
		be scanned and any *.pm and *.pl files they contain will
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

 PERL:
 FULLPERL:

Additional lowercase attributes can be used to pass parameters to the
methods which implement that part of the Makefile. These are not
normally required:

 installpm:	{SPLITLIB => '$(INST_LIB)' (default) or '$(INST_ARCHLIB)'}
 linkext:	{LINKTYPE => 'static', 'dynamic' or ''}
 dynamic_lib:	{ARMAYBE => 'ar', OTHERLDFLAGS => '...'}
 clean:		{FILES => "*.xyz foo"}
 realclean:	{FILES => '$(INST_ARCHAUTODIR)/*.xyz'}
 distclean:	{TARNAME=>'MyTarFile', TARFLAGS=>'cvfF', COMPRESS=>'gzip'}
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
    'post_constants'	=> {},
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
    'subdirs'		=> {},
    'clean'		=> {},
    'realclean'		=> {},
    'distclean'		=> {},
    'test'		=> {},
    'install'		=> {},
    'force'		=> {},
    'perldepend'	=> {},
    'makefile'		=> {},
    'postamble'		=> {},
    'staticmake'	=> {},
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

    print STDOUT "MakeMaker" if $Verbose;

    parse_args(\%att, @ARGV);
    my(%initial_att) = %att; # record initial attributes

    MY->init_main();

    print STDOUT "Writing Makefile for $att{NAME}";

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

    foreach $section ( @MM_Sections ){
	print "Processing Makefile '$section' section" if ($Verbose >= 2);
	my($skipit) = skipcheck($section);
	if ($skipit){
	    print MAKE "\n# --- MakeMaker $section section $skipit.";
	} else {
	    my(%a) = %{$att{$section} || {}};
	    print MAKE "\n# --- MakeMaker $section section:";
	    print MAKE "# ",%a if $Verbose;
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


sub mkbootstrap{
    parse_args(\%att, @ARGV);
    MY->mkbootstrap(@_);
}

sub mksymlists{
    %att = @_;
    parse_args(\%att, @ARGV);
    MY->mksymlists(@_);
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
	    my($home) = ($1) ? (getpwnam($1))[7] : (getpwuid($>))[7];
	    $value =~ s/^~(\w+)?/$home/;
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
    require File::VMSspec;
    import File::VMSspec 'vmsify';
}


sub init_main {
    # Find out directory name.  This may contain the extension name.
    my($pwd) = fastcwd(); # from Cwd.pm

    # --- Initialize PERL_LIB, INST_LIB, PERL_SRC

    # *Real* information: where did we get these two from? ...
    $inc_config_dir = dirname($INC{'Config.pm'});
    $inc_carp_dir   = dirname($INC{'Carp.pm'});

    # Typically PERL_* and INST_* will be identical but that need
    # not be the case (e.g., installing into project libraries etc).

    # Perl Macro:    With source    No source
    # PERL_LIB       ../../lib      /usr/local/lib/perl5
    # PERL_ARCHLIB   ../../lib      /usr/local/lib/perl5/sun4-sunos
    # PERL_SRC       ../..          (undefined)

    # INST Macro:    Locally        Publically
    # INST_LIB       ../../lib      ./blib
    # INST_ARCHLIB   ../../lib      ./blib

    unless ($att{PERL_SRC}){
	foreach(qw(../.. ../../.. ../../../..)){
	    ($att{PERL_SRC}=$_, last) if -f "$_/config.sh";
	}
    }
    unless ($att{PERL_SRC}){
	# we should also consider $ENV{PERL5LIB} here
	$att{PERL_LIB}     = $Config{'privlib'} unless $att{PERL_LIB};
	$att{PERL_ARCHLIB} = $Config{'archlib'} unless $att{PERL_ARCHLIB};
	$att{PERL_INC}     = "$att{PERL_ARCHLIB}/CORE"; # wild guess for now
	die "Unable to locate Perl source. Try setting PERL_SRC in Makefile.PL or on command line.\n"
		unless (-f "$att{PERL_INC}/perl.h");
	print STDOUT "Using header files found in $att{PERL_INC}" if $Verbose;
    } else {
	$att{PERL_LIB}     = "$att{PERL_SRC}/lib" unless $att{PERL_LIB};
	$att{PERL_ARCHLIB} = $att{PERL_LIB};
	$att{PERL_INC}     = $att{PERL_SRC};
    }

    # INST_LIB typically pre-set if building an extension after
    # perl has been built and installed. Setting INST_LIB allows
    # you to build directly into privlib and avoid installperl.
    unless ($att{INST_LIB}){
	if (defined $att{PERL_SRC}) {
	    $att{INST_LIB} = $att{PERL_LIB};
	} else {
	    $att{INST_LIB} = "$pwd/blib";
	}
    }
    # Try to work out what INST_ARCHLIB should be if not set:
    unless ($att{INST_ARCHLIB}){
	my(%archmap) = (
	    "$pwd/blib" 	=> "$pwd/blib", # our private build lib
	    $att{PERL_LIB}	=> $att{PERL_ARCHLIB},
	    $Config{'privlib'}	=> $Config{'archlib'},
	    $Config{'installprivlib'}	=> $Config{'installarchlib'},
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

    # make a few simple checks
    die "PERL_LIB ($att{PERL_LIB}) is not a perl library directory"
	unless (-f "$att{PERL_LIB}/Exporter.pm");

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

    ($att{DISTNAME}=$att{NAME}) =~ s#(::)#-#g unless $att{DISTNAME};
    $att{VERSION} = "0.1" unless $att{VERSION};


    # --- Initialize Perl Binary Locations

    # Find Perl 5. The only contract here is that both 'PERL' and 'FULLPERL'
    # will be working versions of perl 5. miniperl has priority over perl
    # for PERL to ensure that $(PERL) is usable while building ./ext/*
    $att{'PERL'} = MY->find_perl(5.0, [ qw(miniperl perl) ],
	    [ grep defined $_, $att{PERL_SRC}, split(":", $ENV{PATH}), $Config{'bin'} ], $Verbose )
	unless ($att{'PERL'} && -x $att{'PERL'});

    # Define 'FULLPERL' to be a non-miniperl (used in test: target)
    ($att{'FULLPERL'} = $att{'PERL'}) =~ s/miniperl/perl/
	unless ($att{'FULLPERL'} && -x $att{'FULLPERL'});

    if ($Is_VMS) {
	$att{'PERL'} = 'MCR ' . vmsify($att{'PERL'});
	$att{'FULLPERL'} = 'MCR ' . vmsify($att{'FULLPERL'});
    }
}


sub init_dirscan {	# --- File and Directory Lists (.xs .pm etc)

    my($name, %dir, %xs, %c, %h, %ignore);
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
	    $c{$name} = 1;
	} elsif ($name =~ /\.h$/){
	    $h{$name} = 1;
	} elsif ($name =~ /\.p[ml]$/){
	    $pm{$name} = "\$(INST_LIBDIR)/$name";
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
		$prefix =  '$(INST_LIB)' if ($path =~ s:^lib/::);
		local($_) = "$prefix/$path";
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
}


sub libscan {
    $_;
}

sub init_others {	# --- Initialize Other Attributes

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
    foreach ( @{$att{'LIBS'}} ){
	s/^\s*(.*\S)\s*$/$1/; # remove leading and trailing whitespace
	my(@libs) = MY->extliblist($_);
	if ($libs[0] or $libs[1] or $libs[2]){
	    @att{EXTRALIBS, BSLOADLIBS, LDLOADLIBS} = @libs;
	    last;
	}
    }

    print STDOUT "CONFIG must be an array ref\n"
	if ($att{CONFIG} and ref $att{CONFIG} ne 'ARRAY');
    $att{CONFIG} = [] unless (ref $att{CONFIG});
    push(@{$att{CONFIG}},
	qw( cc libc ldflags lddlflags ccdlflags cccdlflags
	    ranlib so dlext dlsrc installprivlib installarchlib
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
    if ($trace){
	print "Looking for perl $ver by these names: ";
	print "@$names, ";
	print "in these dirs:";
	print "@$dirs";
    }
    foreach $dir (@$dirs){
	next unless defined $dir; # $att{PERL_SRC} may be undefined
	foreach $name (@$names){
	    print "checking $dir/$name" if ($trace >= 2);
	    if ($Is_VMS) {
	      $name .= ".exe" unless -x "$dir/$name";
	    }
	    next unless -x "$dir/$name";
	    print "Executing $dir/$name" if ($trace);
	    my($out);
	    if ($Is_VMS) {
	      my($vmscmd) = 'MCR ' . vmsify("$dir/$name");
	      $out = `$vmscmd -e "require $ver; print ""VER_OK\n"""`;
	    } else {
	      $out = `$dir/$name -e 'require $ver; print "VER_OK\n" ' 2>&1`;
	    }
	    return "$dir/$name" if $out =~ /VER_OK/;
	}
    }
    print STDOUT "Unable to find a perl $ver (by these names: @$names, in these dirs: @$dirs)\n";
    0; # false and not empty
}


sub post_initialize{
    "";
}


sub constants {
    my(@m);

    push @m, "
NAME = $att{NAME}
DISTNAME = $att{DISTNAME}
VERSION = $att{VERSION}

# In which library should we install this extension?
# This is typically the same as PERL_LIB.
# (also see INST_LIBDIR and relationship to ROOTEXT)
INST_LIB = $att{INST_LIB}
INST_ARCHLIB = $att{INST_ARCHLIB}

# Perl library to use when building the extension
PERL_LIB = $att{PERL_LIB}
PERL_ARCHLIB = $att{PERL_ARCHLIB}
";

    # Define I_PERL_LIBS to include the required -Ipaths
    # To be cute we only include PERL_ARCHLIB if different
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

    push @m, '
INST_STATIC  = $(INST_ARCHAUTODIR)/$(BASEEXT).a
INST_DYNAMIC = $(INST_ARCHAUTODIR)/$(BASEEXT).$(DLEXT)
INST_BOOT    = $(INST_ARCHAUTODIR)/$(BASEEXT).bs
INST_PM = '.join(" \\\n\t", sort values %{$att{PM}}).'
';

    join('',@m);
}


sub const_cccmd{
    # This is implemented in the same manner as extliblist,
    # e.g., do both and compare results during the transition period.
    my($cc,$ccflags,$optimize,$large,$split, $shflags)
	= @Config{qw(cc ccflags optimize large split shellflags)};
    $shflags = '' unless $shflags;
    my($prog, $old);

    chop($old = `cd $att{PERL_SRC}; sh $shflags ./cflags $att{BASEEXT}.c 2>/dev/null`)
	if $att{PERL_SRC};

    my($name);
    ( $name = $att{NAME} . "_cflags" ) =~ s/:/_/g ;
    if ($prog = $Config{$name}) {
	# Expand hints for this extension via the shell
	print STDOUT "Processing $name hint:\n" if $Verbose;
	my(@o)=`cc=\"$cc\"
	  ccflags=\"$ccflags\"
	  optimize=\"$optimize\"
	  large=\"$large\"
	  split=\"$split\"
	  eval '$prog'
	  echo cc=\$cc
	  echo ccflags=\$ccflags
	  echo optimize=\$optimize
	  echo large=\$large
	  echo split=\$split
	  `;
	my(%cflags);
	foreach $line (@o){
	    chomp $line;
	    if ($line =~ /(.*?)=\s*(.*)\s*$/){
		$cflags{$1} = $2;
		print STDOUT "	$1 = $2" if $Verbose;
	    } else {
		print STDOUT "Unrecognised result from hint: '$line'\n";
	    }
	}
	($cc,$ccflags,$optimize,$large,$split)=@cflags{qw(cc ccflags optimize large split)};
    }

    my($new) = "$cc -c $ccflags $optimize  $large $split";
    if (defined($old) and $new ne $old) {
	print STDOUT "Warning (non-fatal): cflags evaluation in MakeMaker differs from shell output\n"
	."   package: $att{NAME}\n"
	."   old: $old\n"
	."   new: $new\n"
	."   Using 'old' set.\n"
	."Please notify perl5-porters\@nicoh.com\n";
    }
    my($cccmd)=($old) ? $old : $new;
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
";
}


# --- Tool Sections ---

sub tool_autosplit{
    my($self, %attribs) = @_;
    my($asl) = "";
    $asl = "\$AutoSplit::Maxlen=$attribs{MAXLEN};" if $attribs{MAXLEN};
    q{
# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(PERL) $(I_PERL_LIBS) -e 'use AutoSplit;}.$asl.q{autosplit($$ARGV[0], $$ARGV[1], 0, 1, 1) ;'
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
".q{
# The following is a portable way to say mkdir -p
MKPATH = $(PERL) -wle '$$"="/"; foreach $$p (@ARGV){ next if -d $$p; my(@p); foreach(split(/\//,$$p)){ push(@p,$$_); next if -d "@p/"; print "mkdir @p"; mkdir("@p",0777)||die $$! }} exit 0;'
};
}


sub post_constants{
    "";
}


# --- Translation Sections ---

sub c_o {
    push @m, '
.c.o:
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $(INC) $*.c
';
    join "", @m;
}

sub xs_c {
    '
.xs.c:
	$(PERL) $(XSUBPP) $(XSUBPPARGS) $*.xs >$*.tc && mv $*.tc $@
';
}

sub xs_o {	# many makes are too dumb to use xs_c then c_o
    '
.xs.o:
	$(PERL) $(XSUBPP) $(XSUBPPARGS) $*.xs >xstmp.c && mv xstmp.c $*.c
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $(INC) $*.c
';
}


# --- Target Sections ---

sub top_targets{
    push @m, '
all ::	config linkext $(INST_PM)
'.$att{NOOP}.'

config :: '.$att{MAKEFILE}.'
	@ $(MKPATH) $(INST_LIBDIR) $(INST_ARCHAUTODIR)
';

    push @m, '
$(O_FILES): $(H_FILES)
' if @{$att{O_FILES} || []} && @{$att{H} || []};
    join('',@m);
}

sub linkext {
    my($self, %attribs) = @_;
    # LINKTYPE => static or dynamic
    my($linktype) = $attribs{LINKTYPE} || '$(LINKTYPE)';
    "
linkext :: $linktype
$att{NOOP}
";
}

sub dlsyms {
    my($self,%attribs) = @_;

    return '' if ($Config{'osname'} ne 'AIX');

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
",'	$(PERL) $(I_PERL_LIBS) -e \'use ExtUtils::MakeMaker; \\
	mksymlists(DL_FUNCS => ',
	%$funcs ? neatvalue($funcs) : "''",', DL_VARS => ',
	@$vars  ? neatvalue($vars)  : "''",")'
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
    '
BOOTSTRAP = '."$att{BASEEXT}.bs".'

# As MakeMaker mkbootstrap might not write a file (if none is required)
# we use touch to prevent make continually trying to remake it.
# The DynaLoader only reads a non-empty file.
$(BOOTSTRAP): '."$att{MAKEFILE} $att{BOOTDEP}".'
	$(PERL) $(I_PERL_LIBS) \
		-e \'use ExtUtils::MakeMaker; &mkbootstrap("$(BSLOADLIBS)");\' \
		INST_LIB=$(INST_LIB) INST_ARCHLIB=$(INST_ARCHLIB) PERL_SRC=$(PERL_SRC) NAME=$(NAME)
	@ $(TOUCH) $(BOOTSTRAP)

$(INST_BOOT): $(BOOTSTRAP)
	@ '.$att{RM_RF}.' $(INST_BOOT)
	- '.$att{CP}.' $(BOOTSTRAP) $(INST_BOOT)
';
}


sub dynamic_lib {
    my($self, %attribs) = @_;
    my($otherldflags) = $attribs{OTHERLDFLAGS} || "";
    my($armaybe) = $attribs{ARMAYBE} || $att{ARMAYBE} || ":";
    my($ldfrom) = '$(LDFROM)';
    my($osname) = $Config{'osname'};
    $armaybe = 'ar' if ($osname eq 'dec_osf' and $armaybe eq ':');
    my(@m);
    push(@m,'
# This section creates the dynamically loadable $(INST_DYNAMIC)
# from $(OBJECT) and possibly $(MYEXTLIB).
ARMAYBE = '.$armaybe.'
OTHERLDFLAGS = '.$otherldflags.'

$(INST_DYNAMIC): $(OBJECT) $(MYEXTLIB) $(BOOTSTRAP)
	@ $(MKPATH) $(INST_ARCHAUTODIR)
');
    if ($armaybe ne ':'){
	$ldfrom = "tmp.a";
	push(@m,'	$(ARMAYBE) cr '.$ldfrom.' $(OBJECT)'."\n");
	push(@m,'	$(RANLIB) '."$ldfrom\n");
    }
    $ldfrom = "-all $ldfrom -none" if ($osname eq 'dec_osf');
    push(@m,'	$(LD) -o $@ $(LDDLFLAGS) '.$ldfrom.
			' $(OTHERLDFLAGS) $(MYEXTLIB) $(LDLOADLIBS)'."\n");
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
    my(@m);
    push(@m, <<'END');
$(INST_STATIC): $(OBJECT) $(MYEXTLIB)
	@ $(MKPATH) $(INST_ARCHAUTODIR)
END
    # If this extension has it's own library (eg SDBM_File)
    # then copy that to $(INST_STATIC) and add $(OBJECT) into it.
    push(@m, "	$att{CP} \$(MYEXTLIB) \$\@\n") if $att{MYEXTLIB};

    push(@m, <<'END');
	@ $(MKPATH) $(INST_ARCHAUTODIR)
	ar cr $@ $(OBJECT) && $(RANLIB) $@
	@echo "$(EXTRALIBS)" > $(INST_ARCHAUTODIR)/extralibs.ld
END

# Old mechanism - still available:

    push(@m, <<'END') if $att{PERL_SRC};
	@ echo "$(EXTRALIBS)" >> $(PERL_SRC)/ext.libs
END
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
    my($instdir) = $inst =~ m|(.*)/|;
    my(@m);
    push(@m,"
$inst: $dist Makefile
".'	@ '.$att{RM_F}.' $@
	@ $(MKPATH) '.$instdir.'
	'."$att{CP} $dist".' $@
');
    push(@m, "\t\$(AUTOSPLITFILE) \$@ $splitlib/auto\n")
	if ($splitlib and $inst =~ m/\.pm$/);
    join('', @m);
}


# --- Sub-directory Sections ---

sub subdirs {
    my(@m);
    # This method provides a mechanism to automatically deal with
    # subdirectories containing further Makefile.PL scripts.
    # It calls the subdir_x() method for each subdirectory.
    foreach(<*/Makefile.PL>){
	s:/Makefile\.PL$:: ;
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
	cd $subdir ; \$(MAKE) config INST_LIB=\$(INST_LIB) INST_ARCHLIB=\$(INST_ARCHLIB)  LINKTYPE=\$(LINKTYPE)

$subdir/$att{MAKEFILE}: $subdir/Makefile.PL \$(CONFIGDEP)
}.'	@echo "Rebuilding $@ ..."
	$(PERL) $(I_PERL_LIBS) \\
		-e "use ExtUtils::MakeMaker; MM->runsubdirpl(qw('.$subdir.'))" \\
		INST_LIB=$(INST_LIB) INST_ARCHLIB=$(INST_ARCHLIB) $(SUBDIR_MAKEFILE_PL_ARGS)
	@echo "Rebuild of $@ complete."
'.qq{

subdirs ::
	cd $subdir ; \$(MAKE) all LINKTYPE=\$(LINKTYPE)

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
			."\$(BOOTSTRAP) \$(BASEEXT).bso @otherfiles\n");
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
    $sub = "\t-cd %s && test -f %s && \$(MAKE) %s realclean\n";
    foreach(@{$att{DIR}}){
	push(@m, sprintf($sub,$_,"$att{MAKEFILE}.old","-f $att{MAKEFILE}.old"));
	push(@m, sprintf($sub,$_,"$att{MAKEFILE}",''));
    }
    push(@m, "	$att{RM_RF} \$(INST_AUTODIR) \$(INST_ARCHAUTODIR)\n");
    push(@m, "	$att{RM_F} \$(INST_DYNAMIC) \$(INST_BOOT)\n");
    push(@m, "	$att{RM_F} \$(INST_STATIC) \$(INST_PM)\n");
    my(@otherfiles) = ($att{MAKEFILE}, 
		       "Perl.make", "$att{MAKEFILE}.old"); # Makefiles last
    push(@otherfiles, $attribs{FILES}) if $attribs{FILES};
    push(@m, "	$att{RM_RF} @otherfiles\n") if @otherfiles;
    push(@m, "	$attribs{POSTOP}\n")       if $attribs{POSTOP};
    join("", @m);
}


sub distclean {
    my($self, %attribs) = @_;
    # VERSION should be sanitised before use as a file name
    my($tarname)  = $attribs{TARNAME}  || '$(DISTNAME)-$(VERSION)';
    my($tarflags) = $attribs{TARFLAGS} || 'cvf';
    my($compress) = $attribs{COMPRESS} || 'compress'; # eg gzip
    my($preop)    = $attribs{PREOP}  || '@:'; # e.g., update MANIFEST
    my($postop)   = $attribs{POSTOP} || '@:';
    my($mkfiles)  = join(' ', map("$_/$att{MAKEFILE} $_/$att{MAKEFILE}.old", ".", @{$att{DIR}}));
    "
distclean:     clean
	$preop
	$att{RM_F} $mkfiles
	cd ..; tar $tarflags $tarname.tar \$(BASEEXT)
	cd ..; $compress $tarname.tar
	$postop
";
}


# --- Test and Installation Sections ---

sub test {
    my($self, %attribs) = @_;
    my($tests) = $attribs{TESTS} || (-d "t" ? "t/*.t" : "");
    my(@m);
    push(@m,"
test :: all
");
    push(@m, <<"END") if $tests;
	\$(FULLPERL) -I\$(INST_ARCHLIB) -I\$(INST_LIB) -I\$(PERL_ARCHLIB) -I\$(PERL_LIB) -e 'use Test::Harness; runtests \@ARGV;' $tests
END
    push(@m, <<'END') if -f "test.pl";
	$(FULLPERL) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) test.pl
END
    push(@m, map("\tcd $_ && test -f $att{MAKEFILE} && \$(MAKE) test LINKTYPE=\$(LINKTYPE)\n",@{$att{DIR}}));
    push(@m, "\t\@echo 'No tests defined for \$(NAME) extension.'\n") unless @m > 1;
    join("", @m);
}


sub install {
    my($self, %attribs) = @_;
    my(@m);
    push(@m, "
install :: all
");
    # install subdirectories first
    push(@m, map("\tcd $_ && test -f $att{MAKEFILE} && \$(MAKE) install\n",@{$att{DIR}}));

    push(@m, "\t: perl5.000 and MM pre 3.8 autosplit into INST_ARCHLIB, we delete these old files here
	$att{RM_F} $Config{'installarchlib'}/auto/\$(FULLEXT)/*.al $Config{'installarchlib'}/auto/\$(FULLEXT)/*.ix
	\$(MAKE) INST_LIB=$Config{'installprivlib'} INST_ARCHLIB=$Config{'installarchlib'}
");

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

$(OBJECT) : $(PERL_HDRS)
');

    push(@m,'
# Check for unpropogated config.sh changes. Should never happen.
# We do NOT just update config.h because that is not sufficient.
# An out of date config.h is not fatal but complains loudly!
$(PERL_INC)/config.h: $(PERL_SRC)/config.sh
	-@echo "Warning: $(PERL_INC)/config.h out of date with $(PERL_SRC)/config.sh"; false

$(PERL_ARCHLIB)/Config.pm: $(PERL_SRC)/config.sh
	@echo "Warning: $(PERL_ARCHLIB)/Config.pm may be out of date with $(PERL_SRC)/config.sh"
	cd $(PERL_SRC); $(MAKE) lib/Config.pm
') if $att{PERL_SRC};

    push(@m, join(" ", values %{$att{XS}})." : \$(XSUBPPDEPS)\n")
	if %{$att{XS}};
    join("\n",@m);
}


sub makefile {
    # We do not know what target was originally specified so we
    # must force a manual rerun to be sure. But as it should only
    # happen very rarely it is not a significant problem.
    '
$(OBJECT) : '.$att{MAKEFILE}.'

# We take a very conservative approach here, but it\'s worth it.
# We move Makefile to Makefile.old here to avoid gnu make looping.
'.$att{MAKEFILE}.':	Makefile.PL $(CONFIGDEP)
	@echo "Makefile out-of-date with respect to $?"
	@echo "Cleaning current config before rebuilding Makefile..."
	-@mv '."$att{MAKEFILE} $att{MAKEFILE}.old".'
	-$(MAKE) -f '.$att{MAKEFILE}.'.old clean >/dev/null 2>&1 || true
	$(PERL) $(I_PERL_LIBS) Makefile.PL
	@echo "Now you must rerun make."; false
';
}


sub postamble{
    "";
}

# --- Make-A-Perl section ---

sub staticmake {
    my($self, %attribs) = @_;

    my(%searchdirs)=($att{PERL_ARCHLIB} => 1,  $att{INST_ARCHLIB} => 1);
    my(@searchdirs)=keys %searchdirs;
    # And as it's not yet built, we add the current extension
    my(@static)="$att{INST_ARCHLIB}/auto/$att{FULLEXT}/$att{BASEEXT}.a";
    my(@extra);
    push(@extra, split(' ', $att{EXTRALIBS})) if defined $att{EXTRALIBS};
    my(@perlinc) = ($att{INST_ARCHLIB}, $att{INST_LIB}, $att{PERL_ARCHLIB}, $att{PERL_LIB});
    MY->makeaperl('MAKE' => $att{MAKEFILE}, 
			     'DIRS' => \@searchdirs, 
			     'STAT' => \@static, 
			     'EXTRA' => \@extra, 
			     'INCL' => \@perlinc,
			     'TARGET' => "perl",
			     'TMP' => "",
			     'LIBPERL' => "$att{PERL_INC}/libperl.a"
			     );
}

sub makeaperl {
    my($self, %attribs) = @_;
    my($makefilename, $searchdirs, $static, $extra, $perlinc, $target, $tmp, $libperl) = 
      @attribs{qw(MAKE DIRS STAT EXTRA INCL TARGET TMP LIBPERL)};
    my(@m);
    my($cccmd, $linkcmd, %map);

    # This emulates cflags to get the compiler invocation...
    $cccmd = MY->const_cccmd();
    $cccmd =~ s/^CCCMD\s*=\s*//;
    chomp $cccmd;
    $cccmd =~ s/\s/ -I$att{PERL_INC} /;
    $cccmd .= " $Config{'cccdlflags'}" if ($Config{'d_shrplib'});

    # The front matter of the linkcommand...
    $linkcmd = join ' ', $Config{'cc'},
	    grep($_, @Config{qw(large split ldflags ccdlflags)});
    $linkcmd =~ s/\s+/ /g;

    # Which *.a files could we make use of...
    local(%static,%libperl);
    File::Find::find(sub {
	return unless m/\.a$/;
	if (m/^libperl/) {
	    $libperl{$File::Find::name}++;
	    return;
	}
	$static{$File::Find::name}++;
    }, grep( -d $_, @{$searchdirs || []}) );

    $extra = [] unless $extra && ref $extra eq 'ARRAY';
    for (sort keys %static) {
	next unless /\.a$/;
	s#^#./# unless m#/#;        # Prepend "./" if it is in the current dir
	s#(.*/).*#$1extralibs.ld#;
	if (-f $_){
	    push @$extra, split(' ',`cat $_`);
	} else {
	    print STDOUT "$0: warning $_ not found";
	}
    }

    # These have been handed in explicitly, so we do not read extralibs.ld for them,
    # they might not even exist, and extralibs.ld might be outdated.
    @static{@{$static || []}} = (1) x @{$static || []};
    grep(s/^/-I/, @$perlinc);

    $target = "perl" unless $target;
    $tmp = "." unless $tmp;

    push @m, "
# Fill in the target you want to produce if it's not perl
MAP_TARGET    = $target
FULLPERL      = $att{'FULLPERL'}
MAP_LINKCMD   = $linkcmd
MAP_PERLINC   = @{$perlinc}
MAP_STATIC    = ",
join(" ", sort keys %static), "
MAP_EXTRA     = @{$extra}
MAP_PRELIBS   = $Config{'libs'} $Config{'cryptlib'}
";

    my(@libperl);
    if ($libperl) {
	@libperl = $libperl;
    } else {
	@libperl = sort keys %libperl;
	if (@libperl==0 && defined $att{PERL_SRC}) {
	    push @libperl, "$att{PERL_SRC}/libperl.a";
	}
	if (@libperl==0 && -f "$INC[0]/CORE/libperl.a") {
	    push @libperl, "$INC[0]/CORE/libperl.a";
	}
	if (@libperl==0){
	    push @m, "\nMAP_LIBPERL = ---NOT FOUND---\n\n";
	}
    }

    # if we have to work with other libraries than libperl.a...
    %map = (
		D =>   '-DDEBUGGING',
		E =>   '-DEMBED',
		DE =>  '-DDEBUGGING -DEMBED',
		M =>   '-DEMBED -DMULTIPLICITY',
		DM =>  '-DDEBUGGING -DEMBED -DMULTIPLICITY',
		);
    for (@libperl) {
	my($uc, $thiscccmd);
	( $uc = $_ ) =~ s!.*/libperl(\w*)\.a!uc($1)!e;

	# We have to tamper with the cccmd...
	$thiscccmd = $cccmd;
	# All perls of flavor D need a compilation with -g instead of 
	# whatever optimize was before
	if ($uc =~ /^D/) {
	    $thiscccmd =~ s/\B$Config{'optimize'}\b/-g/;
	}
	$thiscccmd .= $map{$uc} if $uc;
	$thiscccmd =~ s/\s+/ /g;

	# If we have to write the Makefile for only one
	# target, we do not need the variable $uc
	$uc = "" if @libperl == 1;

	push @m, "MAP_LIBPERL$uc = $_
$target$uc: $tmp/perlmain$uc.o \$(MAP_LIBPERL$uc) \$(MAP_STATIC)
	\$(MAP_LINKCMD) -o \$\@ $tmp/perlmain$uc.o \$(MAP_LIBPERL$uc) \$(MAP_STATIC) \$(MAP_EXTRA) \$(MAP_PRELIBS)

$tmp/perlmain$uc.o: $tmp/perlmain$uc.c
";
	push @m, "\tcd $tmp && $thiscccmd perlmain$uc.c\n";

	if ($uc) {
	    push @m, "$tmp/perlmain$uc.c: $tmp/perlmain.c
	cp \$< \$\@\n\n";
	}
    }

    push @m, qq{
$tmp/perlmain.c: $makefilename}, q{
	$(FULLPERL) $(MAP_PERLINC) -e 'use ExtUtils::Miniperl; \\
		writemain(grep s#.*/auto/##, qw|$(MAP_STATIC)|)' > $@

};

    push @m, qq{
inst_perl: \$(MAP_TARGET)
	$att{CP} \$(MAP_TARGET) $Config{'installbin'}/\$(MAP_TARGET)

};

    join '', @m;
}

# --- Determine libraries to use and how to use them ---

sub extliblist{
    my($self, $libs) = @_;
    return ("", "", "") unless $libs;
    print STDOUT "Potential libraries are '$libs':" if $Verbose;
    my(@new) = MY->new_extliblist($libs);

    if ($att{PERL_SRC}){
	my(@old) = MY->old_extliblist($libs);
	my($oldlibs) = join(" : ",@old);
	my($newlibs) = join(" : ",@new);
	print STDOUT "Warning (non-fatal): $att{NAME} extliblist consistency check failed:\n".
	    "  old: $oldlibs\n".
	    "  new: $newlibs\n".
	    "Using 'new' set. Please notify perl5-porters\@nicoh.com.\n"
		if ("$newlibs" ne "$oldlibs");
    }
    @new;
}


sub old_extliblist {
    my($self, $potential_libs)=@_;
    return ("", "", "") unless $potential_libs;
    die "old_extliblist requires PERL_SRC" unless $att{PERL_SRC};

    my(%attrib, @w);
    # Now run ext/util/extliblist to discover what *libs definitions
    # are required for the needs of $potential_libs
    $ENV{'potential_libs'} = $potential_libs;
    my(@o)=`. $att{PERL_SRC}/config.sh
	    . $att{PERL_SRC}/ext/util/extliblist;
	    echo EXTRALIBS=\$extralibs
	    echo BSLOADLIBS=\$dynaloadlibs
	    echo LDLOADLIBS=\$statloadlibs
	    `;
    foreach $line (@o){
	chomp $line;
	if ($line =~ /(.*)\s*=\s*(.*)\s*$/){
	    $attrib{$1} = $2;
	    print STDOUT "	$1 = $2" if $Verbose;
	}else{
	    push(@w, $line);
	}
    }
    print STDOUT "Messages from extliblist:\n", join("\n",@w,'')
       if @w ;
    @attrib{qw(EXTRALIBS BSLOADLIBS LDLOADLIBS)};
}


sub new_extliblist {
    my($self, $potential_libs)=@_;
    return ("", "", "") unless $potential_libs;

    my($so)   = $Config{'so'};
    my($libs) = $Config{'libs'};

    # compute $extralibs, $bsloadlibs and $ldloadlibs from
    # $potential_libs
    # this is a rewrite of Andy Dougherty's extliblist in perl
    # its home is in <distribution>/ext/util

    my(@searchpath); # from "-L/path" entries in $potential_libs
    my(@libpath) = split " ", $Config{'libpth'};
    my(@ldloadlibs);
    my(@bsloadlibs);
    my(@extralibs);
    my($fullname);
    my($pwd) = fastcwd(); # from Cwd.pm

    foreach $thislib (split ' ', $potential_libs){

	# Handle possible linker path arguments.
	if ($thislib =~ s/^(-[LR])//){	# save path flag type
	    my($ptype) = $1;
	    unless (-d $thislib){
		print STDOUT "$ptype$thislib ignored, directory does not exist\n"
			if $Verbose;
		next;
	    }
	    if ($thislib !~ m|^/|) {
	      print STDOUT "Warning: $ptype$thislib changed to $ptype$pwd/$thislib\n";
	      $thislib = "$pwd/$thislib";
	    }
	    push(@searchpath, $thislib);
	    push(@extralibs,  "$ptype$thislib");
	    push(@ldloadlibs, "$ptype$thislib");
	    next;
	}

	# Handle possible library arguments.
	unless ($thislib =~ s/^-l//){
	  print STDOUT "Unrecognized argument in LIBS ignored: '$thislib'\n";
	  next;
	}

	my($found_lib)=0;
	foreach $thispth (@searchpath, @libpath){

	    if (@fullname=<${thispth}/lib${thislib}.${so}.[0-9]*>){
		$fullname=$fullname[-1]; #ATTN: 10 looses against 9!
	    } elsif (-f ($fullname="$thispth/lib$thislib.$so")){
	    } elsif (-f ($fullname="$thispth/lib${thislib}_s.a")
		     && ($thislib .= "_s") ){ # we must explicitly ask for _s version
	    } elsif (-f ($fullname="$thispth/lib$thislib.a")){
	    } elsif (-f ($fullname="$thispth/Slib$thislib.a")){
	    } else {
		print STDOUT "$thislib not found in $thispth\n" if $Verbose;
		next;
	    }
	    print STDOUT "'-l$thislib' found at $fullname" if $Verbose;
	    $found_lib++;

	    # Now update library lists

	    # what do we know about this library...
	    my $is_dyna = ($fullname !~ /\.a$/);
	    my $in_perl = ($libs =~ /\B-l${thislib}\b/s);

	    # Do not add it into the list if it is already linked in
	    # with the main perl executable.
	    # We have to special-case the NeXT, because all the math is also in libsys_s
	    unless ( $in_perl || ($Config{'osname'} eq 'next' && $thislib eq 'm') ){
		push(@extralibs, "-l$thislib");
	    }


	    # We might be able to load this archive file dynamically
	    if ( $Config{'dlsrc'} =~ /dl_next|dl_dld/){
		# We push -l$thislib instead of $fullname because
		# it avoids hardwiring a fixed path into the .bs file.
		# mkbootstrap will automatically add dl_findfile() to
		# the .bs file if it sees a name in the -l format.
		# USE THIS LATER: push(@bsloadlibs, "-l$thislib"); # " $fullname";
		# USE THIS while checking results against old_extliblist
		push(@bsloadlibs, "$fullname");
	    } else {
		if ($is_dyna){
                    # For SunOS4, do not add in this shared library if
                    # it is already linked in the main perl executable
		    push(@ldloadlibs, "-l$thislib")
			unless ($in_perl and $Config{'osname'} eq 'sunos');
		} else {
		    push(@ldloadlibs, "-l$thislib");
		}
	    }
	    last;	# found one here so don't bother looking further
	}
	print STDOUT "Warning (non-fatal): No library found for -l$thislib\n" unless $found_lib>0;
    }
    ("@extralibs", "@bsloadlibs", "@ldloadlibs");
}


# --- Write a DynaLoader bootstrap file if required

sub mkbootstrap {

=head1 USEFUL SUBROUTINES

=head2 mkbootstrap()

Make a bootstrap file for use by this system's DynaLoader.  It
typically gets called from an extension Makefile.

There is no C<*.bs> file supplied with the extension. Instead a
C<*_BS> file which has code for the special cases, like posix for
berkeley db on the NeXT.

This file will get parsed, and produce a maybe empty
C<@DynaLoader::dl_resolve_using> array for the current architecture.
That will be extended by $BSLOADLIBS, which was computed by Andy's
extliblist script. If this array still is empty, we do nothing, else
we write a .bs file with an C<@DynaLoader::dl_resolve_using> array, but
without any C<if>s, because there is no longer a need to deal with
special cases.

The C<*_BS> file can put some code into the generated C<*.bs> file by placing
it in C<$bscode>. This is a handy 'escape' mechanism that may prove
useful in complex situations.

If @DynaLoader::dl_resolve_using contains C<-L*> or C<-l*> entries then
mkbootstrap will automatically add a dl_findfile() call to the
generated C<*.bs> file.

=cut

    my($self, @bsloadlibs)=@_;

    @bsloadlibs = grep($_, @bsloadlibs); # strip empty libs

    print STDOUT "	bsloadlibs=@bsloadlibs\n" if $Verbose;

    # We need DynaLoader here because we and/or the *_BS file may
    # call dl_findfile(). We don't say `use' here because when
    # first building perl extensions the DynaLoader will not have
    # been built when MakeMaker gets first used.
    require DynaLoader;
    import DynaLoader;

    init_main() unless defined $att{'BASEEXT'};

    rename "$att{BASEEXT}.bs", "$att{BASEEXT}.bso";

    if (-f "$att{BASEEXT}_BS"){
	$_ = "$att{BASEEXT}_BS";
	package DynaLoader; # execute code as if in DynaLoader
	local($osname, $dlsrc) = (); # avoid warnings
	($osname, $dlsrc) = @Config::Config{qw(osname dlsrc)};
	$bscode = "";
	unshift @INC, ".";
	require $_;
	shift @INC;
    }

    if ($Config{'dlsrc'} =~ /^dl_dld/){
	package DynaLoader;
	push(@dl_resolve_using, dl_findfile('-lc'));
    }

    my(@all) = (@bsloadlibs, @DynaLoader::dl_resolve_using);
    my($method) = '';
    if (@all){
	open BS, ">$att{BASEEXT}.bs"
		or die "Unable to open $att{BASEEXT}.bs: $!";
	print STDOUT "Writing $att{BASEEXT}.bs\n";
	print STDOUT "	containing: @all" if $Verbose;
	print BS "# $att{BASEEXT} DynaLoader bootstrap file for $Config{'osname'} architecture.\n";
	print BS "# Do not edit this file, changes will be lost.\n";
	print BS "# This file was automatically generated by the\n";
	print BS "# mkbootstrap routine in ExtUtils/MakeMaker.pm.\n";
	print BS "\@DynaLoader::dl_resolve_using = ";
	# If @all contains names in the form -lxxx or -Lxxx then it's asking for
	# runtime library location so we automatically add a call to dl_findfile()
	if (" @all" =~ m/ -[lLR]/){
	    print BS "  dl_findfile(qw(\n  @all\n  ));\n";
	}else{
	    print BS "  qw(@all);\n";
	}
	# write extra code if *_BS says so
	print BS $DynaLoader::bscode if $DynaLoader::bscode;
	print BS "\n1;\n";
	close BS;
    }
}

sub mksymlists {
    my($self) = shift;

    # only AIX requires a symbol list at this point
    # (so does VMS, but that's handled by the MM_VMS package)
    return '' unless $Config{'osname'} eq 'AIX';

    init_main(@ARGV) unless defined $att{'BASEEXT'};
    if (! %{$att{DL_FUNCS}}) {
       (my($bootfunc) = $att{NAME}) =~ s/\W/_/g;
       $att{DL_FUNCS} = {$att{BASEEXT} => ["boot_$bootfunc"]};
    }
    rename "$att{BASEEXT}.exp", "$att{BASEEXT}.exp_old";

    open(EXP,">$att{BASEEXT}.exp") or die $!;
    print EXP join("\n",@{$att{DL_VARS}}) if @{$att{DL_VARS}};
    foreach $pkg (keys %{$att{DL_FUNC}}) {
        (my($prefix) = $pkg) =~ s/\W/_/g;
        foreach $func (@{$att{DL_FUNC}->{$pkg}}) {
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

=head1 AUTHORS

Andy Dougherty F<E<lt>doughera@lafcol.lafayette.eduE<gt>>, Andreas
Koenig F<E<lt>k@franz.ww.TU-Berlin.DEE<gt>>, Tim Bunce
F<E<lt>Tim.Bunce@ig.co.ukE<gt>>.  VMS support by Charles Bailey
F<E<lt>bailey@HMIVAX.HUMGEN.UPENN.EDUE<gt>>.

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

miniperl now given preference when defining PERL. This improves the
reliability of ext/*/Makefile's recreating themselves if needed.
$(XS), $(C) and $(H) renamed to XS_FILES C_FILES and H_FILES.
INST_STATIC now INST_ARCHLIBDIR/BASEEXT.a (alongside INST_DYNAMIC).
Static lib no longer copied back to local directory.

v3.11 January 24th 1995 By Andreas Koenig

DynaLoader.c was not deleted by clean target, now fixed.
Added PMDIR attribute that allows directories to be named that contain
only *.p[pl] files to be installed into INST_LIB. Added some documentation.

v4.00 January 24th 1995 By Tim Bunce

Revised some of the documentation. Changed version number to 4.00 to
avoid problems caused by my earlier poor choice of 3.10!  Renamed PMDIR
to PMLIBDIRS and restructured find code to use inherited MY->libscan.
Added ability to say: "perl Makefile.PL help"  to get help.
Added ability to say: "perl Makefile.PL verbose"  to get debugging.
Added MakeMaker version number to generated Makefiles.

v4.01 January 25th 1995 By Tim Bunce

Changes in the section that deals with PMLIBDIRS: some pm files were
put into INST_LIB instead of INST_LIBDIR.

v4.02 January 29th 1995 By Andreas Koenig

Enabled the use of the XXX_cflags variable from Config.pm for nested
extensions: to change e.g. the $Config{"ccflags"} variable on the NeXT
for the nTk::pTk extension, say
    nTk__pTk_cflags='ccflags="-posix $ccflags"'
in the hints-file.

Hints may now be put in a hints/*.sh file within the the module's
directory tree. Any *.sh file in that directory acts as if it had been
parsed during the perl build process.

Added O_FILES, which is an array like C_FILES. Done so to add a
dependency O_FILES from H_FILES. This has the effect, that the
extension gets rebuilt after some headerfiles have changed.

Made life easier in some "I've just edited config.sh" situations and
reduce the risk of "MakeMaker is being pedantic" complaints by letting
the Makefile proceed with a warning if Config.pm is out of date (Tim's
suggestion).

$Verbose now passed to the findperl routine, to get debugging output
from there, too.

Make clean now also deletes the ./blib directory.

Added lots of ideas of Charles Bailey that enable VMS support.

v4.03 January 30th 1995 By Andreas Koenig

check_hints() now also called within runsubdirpl(). More VMS code
included. Trivial cosmetics.

v4.04 Februeary 5th 1995 By Andreas Koenig

Another VMS patch by Charles Bailey added. Documentation restructured.
ext/util/make_ext minor change. 

All *.pm and *.pl files are now touched when MakeMaker finds
them. This inhibits that make omits their installation in
circumstances, where an older version has recently been built.

installperl: perl.exp now goes into $installarchlib/CORE

New files: lib/File/Path.pm, minimod.PL, perllink, and
vms/ext/MM_VMS.pm while writemain.SH is gone. minimod.PL writes a
trivial module, ExtUtils::Miniperl, which has the writemain function
in it to write perlmain.c files. perllink was not in the 4.01 patch
(which was 0i in fact), but it was introduced in 3.10. It is much
smaller now than it was -- most of its code has gone into minimod.PL
and MakeMaker.

MakeMaker now writes a second Makefile that can be perused to make a
new perl binary from some extensions and some libperl libraries. This
Makefile has most likely to be adjusted to needs by hand, but it's a
quite reasonable starting point. The routines related to the writing
of the Makefile are also exploited by a new makeaperl script, that is
not in the patch, but distributed seperately.

v4.05 February 8th 1995 By Andreas Koenig

When searching for static extensions makeaperl() now ignores
inexistent directories. Updated documentation (check_hints() now uses
eval instead of running a shell script)

v4.06 February 10th 1995 By Andreas Koenig

Cleaning up the new interface. Suggestion to freeze now until 5.001.

=head1 NOTES

MakeMaker development work still to be done:

Needs more complete documentation.

Add a html: target when there has been found a general solution to
installing html files.

Create a perllocal.pod somewhere that documents what has been done 
on this system. (Thanks to Jarkko Hietaniemi for the idea)

=cut

# the following keeps AutoSplit happy
package ExtUtils::MakeMaker;
1;

__END__
