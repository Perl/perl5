package ExtUtils::MakeMaker;

$Version = 4.01; # Last edited 25th Jan 1995 by Tim Bunce

use Config;
use Carp;
use Cwd;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(&WriteMakefile &mkbootstrap $Verbose);
@EXPORT_OK = qw($Version %att %skip %Recognized_Att_Keys
	@MM_Sections %MM_Sections
	&help &lsdir);

$Is_VMS = $Config{'osname'} eq 'VMS';
require ExtUtils::MM_VMS if $Is_VMS;

use strict qw(refs);

$Version = $Version;# avoid typo warning
$Verbose = 0;
$^W=1;


=head1 NAME

ExtUtils::MakeMaker - create an extension Makefile

=head1 SYNOPSIS

use ExtUtils::MakeMaker;

WriteMakefile( ATTRIBUTE => VALUE [, ...] );

=head1 DESCRIPTION

This utility is designed to write a Makefile for an extension module
from a Makefile.PL. It is based on the Makefile.SH model provided by
Andy Dougherty and the perl5-porters.

It splits the task of generating the Makefile into several subroutines
that can be individually overridden.  Each subroutine returns the text
it wishes to have written to the Makefile.

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

The macros in the produced Makefile may be overriden on the command
line to the make call like:

  make INST_LIB=/some/where INST_ARCHLIB=/some/where

Note, that this is a solution provided by C<make> in general, so tilde
expansion will probably not be available and INST_ARCHLIB will not be
set automatically when INST_LIB is given as argument.

(This section is yet to be completed ...)

=head2 Determination of Perl Library and Installation Locations

MakeMaker needs to know, or to guess, where certain things are located.
Especially INST_LIB, INST_ARCHLIB, PERL_LIB, PERL_ARCHLIB and PERL_SRC.

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

INST_LIBDIR = $(INST_LIB)$(ROOTEXT)

INST_AUTODIR = $(INST_LIB)/auto/$(FULLEXT)

INST_ARCHAUTODIR = $(INST_ARCHLIB)/auto/$(FULLEXT)

=head2 Customizing The Generated Makefile

If the Makefile generated does not fit your purpose you can change it
using the mechanisms described below.

=head2 Using Attributes (and Parameters)

The following attributes can be specified as arguments to WriteMakefile()
or as NAME=VALUE pairs on the command line:

This description is not yet documented; you can get at the description
with the command
    perl Makefile.PL help    (if you already have a basic Makefile.PL)
or  perl -e 'use ExtUtils::MakeMaker qw(&help); &help;'

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
perl5-porters@nicoh.com or comp.lang.perl as appropriate.


=head1 AUTHORS

Andy Dougherty <doughera@lafcol.lafayette.edu>, Andreas Koenig
<k@franz.ww.TU-Berlin.DE>, Tim Bunce <Tim.Bunce@ig.co.uk>

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

- Introduces ./blib as the directory, where the ready-to-use module
will live for the time of the building process if PERL_SRC/lib is not
available. ./blib is turned into an absolute pathname and gets passed
to subdirectories when writing the Makefile.

- INST_ARCHLIB will now be set equal to INST_LIB if we cannot
determine it with the methods near line 620 (in the intialize
subroutine).

- Introduced the install subroutine, that calls another make
recursively with INST_LIB, and INST_ARCHLIB set according to the local
conventions.

- Since version 3.6 all *.al and *.ix files are installed into
$installprivlib. In perl5.000 they were installed into
$installarchlib. Version 3.8 takes precautions to delete old *.{al,ix}
files that are left over in $installarchlib. Installperl is also
patched to both delete old *.al and *.ix files, that were put into
$installarchlib, and to install them properly from now on.

- h2xs is patched by Dean Roehrich to reintroduce the C<-A> option and
reconsiders the use of the AutoLoader. Also podifies h2xs.

- Patches to {DB_File,Fcntl,GDBM_File,POSIX,Socket}.pm, eliminating
AutoLoader from @ISA (by Dean Roehrich).

- A patch to AutoSplit.pm makes sure, the target directory of the
split exists.

- installperl now installs all *.h files into $installarchlib/CORE.

- added a simple help function

- AutoSplit:

	Turned two constants into package variables.
	Modified the default for &autosplit to be $CheckModTime=1.
	Added warning and comment if auto dir does not exist.
	Enhanced AutoLoader check (POSIX.pm was not getting AutoSplit!)
	Improved logging if $Verbose>=2.

- MakeMaker:

	EXPORT_OK lsdir(), it's very handy.
	Deleted much of the early revision history.
	Changed LDTARGET (bad name) to LDFROM (better, but not great :)
	INST_ARCHLIB for ./blib found via mapping from INST_LIB ./blib
	  (this allows error message if INST_ARCHLIB still undefined)
	Added optional regex filter to &lsdir.
	Added cute auto handling of a ./$(BASEEXT)/*.pm directory as
	  per recent messages with Nick re ext/nTk/nTk/Text.pm
	Added NOOP, RM_F, RM_RF, TOUCH, CP to %att.
	NOOP is now "" on Unix, "<tab>" caused problems (see makefile section)
	RM_F etc now expanded when Makefile written.
	Old AUTOSPLITLIB definition deleted.
	See new dynamic_lib section for new ARMAYBE handling.
	install section now uses $(INSTALLPRIVLIB) because on some
	systems INSTALLPRIVLIB != PRIVLIB (ditto for archlib)

v3.9 January 19th 1995 By Tim Bunce

Added ~ processing to parse_args to allow perl Makefile.PL X=~/path.
Added warning about LDTARGET to LDFROM attribute name change.
Fallback INST_ARCHLIB is INST_LIB, or INST_LIB/$archname if it exists.
Tightened up dependency checking of Makefile against config.sh etc.
INST_STATIC is now INST_ARCHLIBDIR/BASEEXT.a for later make-a-perl.
AUTOSPLITFILE tidied up (AutoSplit patch included in this version).
MKPATH now skips inner loop if directory already exists.
The dynamic_lib section was revised with explicit dec_osf support added.
Make clean now renames Makefile to Makefile.old (make_ext also patched).
The large initialize function has been split into smaller pieces.
Added I_PERL_LIBS to simplify -I paths for PERL_*LIB.

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

=head1 NOTES

MakeMaker development work still to be done:

Needs more complete documentation.

Add method to take a list of files and wrap it in a Makefile
compatible way (<space><backslash><newline><tab>).

Add a html: target when there has been found a general solution to
installing html files.

=cut


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
    'constants'		=> {},
    'const_config'	=> {},
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
	    print STDERR "$msg changed to:\n\t'LIBS' => ['$$attr{potential_libs}']\n";
	} else {
	    print STDERR "$msg deleted.\n";
	}
	$$attr{LIBS} = [$$attr{'potential_libs'}];
	delete $$attr{'potential_libs'};
    }
    # catch old-style 'ARMAYBE' and inform user how to 'upgrade'
    if (defined $$attr{'ARMAYBE'}){
	my($armaybe) = $$attr{'ARMAYBE'};
	print STDERR "ARMAYBE => '$armaybe' should be changed to:\n",
			"\t'dynamic_lib' => {ARMAYBE => '$armaybe'}\n";
	my(%dl) = %{$$attr{'dynamic_lib'} || {}};
	$$attr{'dynamic_lib'} = { %dl, ARMAYBE => $armaybe};
	delete $$attr{'ARMAYBE'};
    }
    if (defined $$attr{'LDTARGET'}){
	print STDERR "LDTARGET should be changed to LDFROM\n";
	$$attr{'LDFROM'} = $$attr{'LDTARGET'};
	delete $$attr{'LDTARGET'};
    }
    foreach(sort keys %{$attr}){
	print STDOUT "	$_ => ".neatvalue($$attr{$_}) if ($Verbose);
	warn "'$_' is not a known MakeMaker parameter name.\n"
	    unless exists $Recognized_Att_Keys{$_};
    }
}


sub neatvalue{
    my($v) = @_;
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
	warn "Unable to locate perl source.\n";
	# we should also consider $ENV{PERL5LIB} here
	$att{PERL_LIB}     = $Config{'privlib'} unless $att{PERL_LIB};
	$att{PERL_ARCHLIB} = $Config{'archlib'} unless $att{PERL_ARCHLIB};
	$att{PERL_INC}     = "$att{PERL_ARCHLIB}/CORE"; # wild guess for now
	die "Try setting PERL_SRC in Makefile.PL or on command line.\n"
		unless (-f "$att{PERL_INC}/perl.h");
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
		warn "Defaulting INST_ARCHLIB to INST_LIB/$archname\n";
	    } else {
		$att{INST_ARCHLIB} = $att{INST_LIB};
		warn "Warning: Defaulting INST_ARCHLIB to INST_LIB ",
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
	  $name =~ s:.*?([^.\]]+)\]:$1: unless ($name =~ s:.*[.\[]ext\.::);
	  ($att{NAME}=$name) =~ s#[.\]]#::#g;
	} else {
	  $name =~ s:.*/:: unless ($name =~ s:^.*/ext/::);
	  ($att{NAME} =$name) =~ s#/#::#g;
	}
    }
    ($att{FULLEXT} =$att{NAME}) =~ s#::#/#g ;		#eg. BSD/Foo/Socket
    ($att{BASEEXT} =$att{NAME}) =~ s#.*::##;		#eg. Socket
    ($att{ROOTEXT} =$att{FULLEXT}) =~ s#/?\Q$att{BASEEXT}\E$## ; # eg. /BSD/Foo
    $att{ROOTEXT} = "/$att{ROOTEXT}" if $att{ROOTEXT};
    $att{ROOTEXT} = "" if $Is_VMS;

    ($att{DISTNAME}=$att{NAME}) =~ s#(::)#-#g;
    $att{VERSION} = "0.1" unless $att{VERSION};


    # --- Initialize Perl Binary Locations

    # Find Perl 5. The only contract here is that both 'PERL' and 'FULLPERL'
    # will be working versions of perl 5. miniperl has priority over perl
    # for PERL to ensure that $(PERL) is usable while building ./ext/*
    $att{'PERL'} = MY->find_perl(5.0, [ qw(miniperl perl) ],
	    [ $att{PERL_SRC}, split(":", $ENV{PATH}), $Config{'bin'} ], 0 )
	unless ($att{'PERL'} && -x $att{'PERL'});

    # Define 'FULLPERL' to be a non-miniperl (used in test: target)
    ($att{'FULLPERL'} = $att{'PERL'}) =~ s/miniperl/perl/
	unless ($att{'FULLPERL'} && -x $att{'FULLPERL'});

    if ($Is_VMS) {
	($att{'PERL'} = 'MCR ' . vmsify($att{'PERL'})) =~ s:.*/::;
	($att{'FULLPERL'} = 'MCR ' . vmsify($att{'FULLPERL'})) =~ s:.*/::;
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
		return unless m/\.p[ml]$/;
		my($path, $prefix) = ($File::Find::name, '$(INST_LIBDIR)');
		$prefix =  '$(INST_LIB)' if ($path =~ s:^lib/::);
		local($_) = "$prefix/$path";
		my($inst) = MY->libscan();
		print "libscan($path) => '$inst'" if ($Verbose >= 2);
		return unless $inst;
		$pm{$path} = "$inst";
	     }, @{$att{PMLIBDIRS}});
    }

    $att{DIR} = [sort keys %dir] unless $att{DIRS};
    $att{XS}  = \%xs             unless $att{XS};
    $att{PM}  = \%pm             unless $att{PM};
    $att{C}   = [sort keys %c]   unless $att{C};
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

    warn "CONFIG must be an array ref\n"
	if ($att{CONFIG} and ref $att{CONFIG} ne 'ARRAY');
    $att{CONFIG} = [] unless (ref $att{CONFIG});
    push(@{$att{CONFIG}},
	qw( cc libc ldflags lddlflags ccdlflags cccdlflags
	    ranlib so dlext dlsrc installprivlib installarchlib
	));
    push(@{$att{CONFIG}}, 'shellflags') if $Config{'shellflags'};

    if ($Is_VMS) {
      # This will not make other Makefile.PLs portable. Any Makefile.PL
      # which says OBJECT => "foo.o bar.o" will fail on VMS. It might
      # be better to fix the c_o section to produce .o files.
      $att{OBJECT} = '$(BASEEXT).obj' unless $att{OBJECT};
      $att{OBJECT} =~ s/[^,\s]\s+/, /g;
      $att{OBJECT} =~ s/\n+/, /g;
    } else {
      $att{OBJECT} = '$(BASEEXT).o' unless $att{OBJECT};
      $att{OBJECT} =~ s/\n+/ \\\n\t/g;
    }
    $att{BOOTDEP}  = (-f "$att{BASEEXT}_BS") ? "$att{BASEEXT}_BS" : "";
    $att{LD}       = ($Config{'ld'} || 'ld') unless $att{LD};
    $att{LDFROM} = '$(OBJECT)' unless $att{LDFROM};
    $att{LINKTYPE} = ($Config{'usedl'}) ? 'dynamic' : 'static'
	unless $att{LINKTYPE};

    # These get overridden for VMS and maybe some other systems
    $att{NOOP}  = "";
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
    print "Looking for perl $ver by these names: @$names, in these dirs: @$dirs\n"
	if ($trace);
    foreach $dir (@$dirs){
	next unless defined $dir; # $att{PERL_SRC} may be undefined
	foreach $name (@$names){
	    print "checking $dir/$name\n" if ($trace >= 2);
	    if ($Is_VMS) {
	      $name .= ".exe" unless -x "$dir/$name";
	    }
	    next unless -x "$dir/$name";
	    print "executing $dir/$name\n" if ($trace);
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
    warn "Unable to find a perl $ver (by these names: @$names, in these dirs: @$dirs)\n";
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
# Where is the perl source code located? (Eventually we should
# be able to build extensions without requiring the perl source
# but that's a way off yet).
PERL_SRC = $att{PERL_SRC}
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

    if ($prog = $Config{"$att{BASEEXT}_cflags"}) {
	# Expand hints for this extension via the shell
	print STDERR "Processing $att{BASEEXT}_cflags hint:\n" if $Verbose;
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
		print STDERR "	$1 = $2" if $Verbose;
	    } else {
		print STDERR "Unrecognised result from hint: '$line'\n";
	    }
	}
	($cc,$ccflags,$optimize,$large,$split)=@cflags{qw(cc ccflags optimize large split)};
    }

    my($new) = "$cc -c $ccflags $optimize  $large $split";
    if (defined($old) and $new ne $old) {
	warn "Warning (non-fatal): cflags evaluation in MakeMaker differs from shell output\n"
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
	warn "CONFIG key '$m' does not exist in Config.pm\n"
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
# Remark: the "" around the -I switches are helpful for the VMS support
AUTOSPLITFILE = $(PERL) $(I_PERL_LIBS) -e 'use AutoSplit;}.$asl.q{ autosplit($$ARGV[0], $$ARGV[1], 0, 1, 1) ;'
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
    '
.c.o:
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $(INC) $*.c
';
}

sub xs_c {
    '
.xs.c:
	$(PERL) $(XSUBPP) $(XSUBPPARGS) $*.xs >xstmp.c && mv xstmp.c $@
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
    '
all ::	config linkext $(INST_PM)
'.$att{NOOP}.'

config :: Makefile
	@$(MKPATH) $(INST_LIBDIR) $(INST_ARCHAUTODIR)
';
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


# --- Dynamic Loading Sections ---

sub dynamic {
    '
# $(INST_PM) has been moved to the all: target.
# It remains here for awhile to allow for old usage: "make dynamic"
dynamic :: Makefile $(INST_DYNAMIC) $(INST_BOOT) $(INST_PM)
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
$(BOOTSTRAP): Makefile '.$att{BOOTDEP}.'
	$(PERL) $(I_PERL_LIBS) \
		-e \'use ExtUtils::MakeMaker; &mkbootstrap("$(BSLOADLIBS)");\' \
		INST_LIB=$(INST_LIB) INST_ARCHLIB=$(INST_ARCHLIB) PERL_SRC=$(PERL_SRC) NAME=$(NAME)
	@$(TOUCH) $(BOOTSTRAP)

$(INST_BOOT): $(BOOTSTRAP)
	@'.$att{RM_RF}.' $(INST_BOOT)
	'.$att{CP}.' $(BOOTSTRAP) $(INST_BOOT)
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
	@$(MKPATH) $(INST_ARCHAUTODIR)
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
static :: Makefile $(INST_STATIC) $(INST_PM) 
'.$att{NOOP}.'
';
}

sub static_lib{
    my(@m);
    push(@m, <<'END');
$(INST_STATIC): $(OBJECT) $(MYEXTLIB)
END
    # If this extension has it's own library (eg SDBM_File)
    # then copy that to $(INST_STATIC) and add $(OBJECT) into it.
    push(@m, "	$att{CP} \$(MYEXTLIB) \$\@\n") if $att{MYEXTLIB};

    push(@m, <<'END');
	ar cr $@ $(OBJECT) && $(RANLIB) $@
	@echo "$(EXTRALIBS)" > $(INST_ARCHAUTODIR)/extralibs.ld
END
    push(@m, <<'END') if $att{PERL_SRC};
	@: Old mechanism - still needed:
	@echo "$(EXTRALIBS)" >> $(PERL_SRC)/ext.libs
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
$inst: $dist
".'	@'.$att{RM_F}.' $@
	@$(MKPATH) '.$instdir.'
	'.$att{CP}.' $? $@
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
config :: $subdir/Makefile
	cd $subdir ; \$(MAKE) config INST_LIB=\$(INST_LIB) INST_ARCHLIB=\$(INST_ARCHLIB)  LINKTYPE=\$(LINKTYPE)

$subdir/Makefile: $subdir/Makefile.PL \$(CONFIGDEP)
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
    push(@m, map("\t-cd $_ && test -f Makefile && \$(MAKE) clean\n",@{$att{DIR}}));
    my(@otherfiles) = values %{$att{XS}}; # .c files from *.xs files
    push(@otherfiles, $attribs{FILES}) if $attribs{FILES};
    push(@m, "	-$att{RM_RF} *~ t/*~ *.o *.a mon.out core so_locations "
			."\$(BOOTSTRAP) \$(BASEEXT).bso @otherfiles\n");
    # See realclean and ext/utils/make_ext for usage of Makefile.old
    push(@m, "	-$att{MV} Makefile Makefile.old 2>/dev/null\n");
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
	push(@m, sprintf($sub,$_,'Makefile.old','-f Makefile.old'));
	push(@m, sprintf($sub,$_,'Makefile',''));
    }
    push(@m, "	$att{RM_RF} \$(INST_AUTODIR) \$(INST_ARCHAUTODIR)\n");
    push(@m, "	$att{RM_F} \$(INST_DYNAMIC) \$(INST_BOOT)\n");
    push(@m, "	$att{RM_F} \$(INST_STATIC) \$(INST_PM)\n");
    my(@otherfiles) = qw(Makefile Makefile.old); # Makefiles last
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
    my($mkfiles)  = join(' ', map("$_/Makefile", ".", @{$att{DIR}}));
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
	$(FULLPERL) -I$(INST_ARCHLIB) -I$(INST_LIB) $(I_PERL_LIBS) test.pl
END
    push(@m, map("\tcd $_ && test -f Makefile && \$(MAKE) test LINKTYPE=\$(LINKTYPE)\n",@{$att{DIR}}));
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
    push(@m, map("\tcd $_ && test -f Makefile && \$(MAKE) install\n",@{$att{DIR}}));

    push(@m, "\t: perl5.000 and MM pre 3.8 autosplit into INST_ARCHLIB, we delete these old files here
	$att{RM_F} \$(INSTALLARCHLIB)/auto/\$(FULLEXT)/*.al \$(INSTALLARCHLIB)/auto/\$(FULLEXT)/*.ix
	\$(MAKE) INST_LIB=\$(INSTALLPRIVLIB) INST_ARCHLIB=\$(INSTALLARCHLIB)
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

# An out of date Config.pm is fatal.
$(PERL_ARCHLIB)/Config.pm: $(PERL_SRC)/config.sh
	@echo "$(PERL_ARCHLIB)/Config.pm out of date with $(PERL_SRC)/config.sh"
	@false
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
$(OBJECT) : Makefile

# We take a very conservative approach here, but it\'s worth it.
# We move Makefile to Makefile.old here to avoid gnu make looping.
Makefile:	Makefile.PL $(CONFIGDEP) 
	@echo "Makefile out-of-date with respect to $?"
	@echo "Cleaning current config before rebuilding Makefile..."
	-@mv Makefile Makefile.old
	-$(MAKE) -f Makefile.old clean >/dev/null 2>&1 || true
	$(PERL) $(I_PERL_LIBS) Makefile.PL
	@echo "Now you must rerun make."; false
';
}


sub postamble{
    "";
}


# --- Determine libraries to use and how to use them ---

sub extliblist{
    my($self, $libs) = @_;
    return ("", "", "") unless $libs;
    print STDERR "Potential libraries are '$libs':" if $Verbose;
    my(@new) = MY->new_extliblist($libs);

    if ($att{PERL_SRC}){
	my(@old) = MY->old_extliblist($libs);
	my($oldlibs) = join(" : ",@old);
	my($newlibs) = join(" : ",@new);
	warn "Warning (non-fatal): $att{NAME} extliblist consistency check failed:\n".
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
	    print STDERR "	$1 = $2" if $Verbose;
	}else{
	    push(@w, $line);
	}
    }
    print STDERR "Messages from extliblist:\n", join("\n",@w,'')
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
		warn "$ptype$thislib ignored, directory does not exist\n"
			if $Verbose;
		next;
	    }
	    if ($thislib !~ m|^/|) {
	      warn "Warning: $ptype$thislib changed to $ptype$pwd/$thislib\n";
	      $thislib = "$pwd/$thislib";
	    }
	    push(@searchpath, $thislib);
	    push(@extralibs,  "$ptype$thislib");
	    push(@ldloadlibs, "$ptype$thislib");
	    next;
	}

	# Handle possible library arguments.
	unless ($thislib =~ s/^-l//){
	  warn "Unrecognized argument in LIBS ignored: '$thislib'\n";
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
		warn "$thislib not found in $thispth\n" if $Verbose;
		next;
	    }
	    warn "'-l$thislib' found at $fullname\n" if $Verbose;
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
	warn "Warning (non-fatal): No library found for -l$thislib\n" unless $found_lib>0;
    }
    ("@extralibs", "@bsloadlibs", "@ldloadlibs");
}


# --- Write a DynaLoader bootstrap file if required

sub mkbootstrap {

=head1 NAME

mkbootstrap

=head1 DESCRIPTION

Make a bootstrap file for use by this system's DynaLoader.
It typically gets called from an extension Makefile.

There is no .bs file supplied with the extension. Instead a _BS file
which has code for the special cases, like posix for berkeley db on the
NeXT.

This file will get parsed, and produce a maybe empty
@DynaLoader::dl_resolve_using array for the current architecture.
That will be extended by $BSLOADLIBS, which was computed by Andy's
extliblist script. If this array still is empty, we do nothing, else
we write a .bs file with an @DynaLoader::dl_resolve_using array, but
without any C<if>s, because there is no longer a need to deal with
special cases.

The _BS file can put some code into the generated .bs file by placing
it in $bscode. This is a handy 'escape' mechanism that may prove
useful in complex situations.

If @DynaLoader::dl_resolve_using contains C<-L*> or C<-l*> entries then
mkbootstrap will automatically add a dl_findfile() call to the
generated .bs file.

=head1 AUTHORS

Andreas Koenig <k@otto.ww.TU-Berlin.DE>, Tim Bunce
<Tim.Bunce@ig.co.uk>, Andy Dougherty <doughera@lafcol.lafayette.edu>

=cut

    my($self, @bsloadlibs)=@_;

    @bsloadlibs = grep($_, @bsloadlibs); # strip empty libs

    print STDERR "	bsloadlibs=@bsloadlibs\n" if $Verbose;

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

    # special handling for systems which needs a list of all global
    # symbols exported by a modules to be dynamically linked.
    if ($Config{'dlsrc'} =~ /^dl_aix/){
       my($bootfunc);
       ($bootfunc = $att{NAME}) =~ s/\W/_/g;
       open EXP, ">$att{BASEEXT}.exp";
       print EXP "#!\nboot_$bootfunc\n";
       close EXP;
    }
}


# --- Output postprocessing section ---
#nicetext is included to make VMS support easier
sub nicetext { # Just return the input - no action needed
    my($self,$text) = @_;
    $text;
}
 
# the following keeps AutoSplit happy
package ExtUtils::MakeMaker;
1;

__END__
