#   MM_VMS.pm
#   MakeMaker default methods for VMS
#   This package is inserted into @ISA of MakeMaker's MM before the
#   built-in MM_Unix methods if MakeMaker.pm is run under VMS.
#
#   Version: 4.15
#   Author:  Charles Bailey  bailey@genetics.upenn.edu
#   Revised: 11-Jun-1995

package ExtUtils::MM_VMS;

use Config;
require Exporter;
use VMS::Filespec;
use File::Basename;

Exporter::import('ExtUtils::MakeMaker',
	qw(%att %skip %Recognized_Att_Keys $Verbose &neatvalue));


sub eliminate_macros {
    my($path) = unixify(@_);
    my($head,$macro,$tail);

    while (($head,$macro,$tail) = ($path =~ m#(.*?)\$\((\S+?)\)/(.*)#)) { 
        ($macro = unixify($att{$macro})) =~ s#/$##;
        $path = "$head$macro/$tail";
    }
    $path;
}

sub fixpath {
    my($path) = @_;
    return $path if $path =~ /^[^\)\/]+\)?[\w\-\.]*/;
    vmsify(eliminate_macros(@_));
}

sub catdir {
    my($self,$path,$dir) = @_;
    vmspath(eliminate_macros($path).'/'.eliminate_macros($dir));
}

sub catfile {
    my($self,$path,$file) = @_;
    if ( $path =~ /^[^\)\]\/:>]+\)$/ ) { "$path$file"; }
    else { vmsify(eliminate_macros($path)."/$file"); }
}


sub find_perl{
    my($self, $ver, $names, $dirs, $trace) = @_;
    my($name, $dir,$vmsfile);
    if ($trace){
	print "Looking for perl $ver by these names: ";
	print "@$names, ";
	print "in these dirs:";
	print "@$dirs";
    }
    foreach $dir (@$dirs){
	next unless defined $dir; # $att{PERL_SRC} may be undefined
	foreach $name (@$names){
	    $name .= ".exe" unless -x "$dir/$name";
	    $vmsfile = vmsify("$dir/$name");
	    print "Checking $vmsfile" if ($trace >= 2);
	    next unless -x "$vmsfile";
	    print "Executing $vmsfile" if ($trace >= 2);
	    if (`MCR $vmsfile -e "require $ver; print ""VER_OK\n"""` =~ /VER_OK/) {
		print "Using PERL=MCR $vmsfile" if $trace;
		return "MCR $vmsfile"
	    }
	}
    }
    print STDOUT "Unable to find a perl $ver (by these names: @$names, in these dirs: @$dirs)\n";
    0; # false and not empty
}


# $att{NAME} is taken from the directory name if it's not passed in.
# Since VMS filenames are case-insensitive, we actually look in the
# extension files to find the Mixed-case name
sub init_main {
    my($self) = @_;

    if (!$att{NAME}) {
        my($defname,$defpm);
        local *PM;
        $defname = $ENV{'DEFAULT'};
        $defname =~ s:.*?([^.\]]+)\]:$1: unless ($defname =~ s:.*[.\[]ext\.(.*)\]:$1:i);
        $defname =~ s#[.\]]#::#g;
        ($defpm = $defname) =~ s/.*:://;
        if (open(PM,"${defpm}.pm")){
            while (<PM>) {
                if (/^\s*package\s+($defname)/oi) {
                   $att{NAME} = $1;
                   last;
                }
            }
            close PM;
            print STDOUT "Warning (non-fatal): Couldn't find package name in ${defpm}.pm;\n\t",
                         "defaulting package name to $defname\n" unless $att{NAME};
        }
        else {
            print STDOUT "Warning (non-fatal): Couldn't find ${defpm}.pm;\n\t",
                         "defaulting package name to $defname\n" unless $att{NAME};
        }
        $att{NAME} = $defname unless $att{NAME};
    }
    MM_Unix::init_main(@_);
}

sub init_others {
    &MM_Unix::init_others;
    $att{NOOP} = "\tContinue";
    $att{MAKEFILE} = '$(MAKEFILE)';
    $att{RM_F} = '$(PERL) -e "foreach (@ARGV) { -d $_ ? rmdir $_ : unlink $_}"';
    $att{RM_RF} = '$(PERL) -e "use File::Path; use VMS::Filespec; @dirs = map(unixify($_),@ARGV); rmtree(\@dirs,0,0)"';
    $att{TOUCH} = '$(PERL) -e "$t=time; foreach (@ARGV) { -e $_ ? utime($t,$t,@ARGV) : (open(F,"">$_""),close F)"';
    $att{CHMOD} = '$(PERL) -e "chmod @ARGV"';  # expect Unix syntax from MakeMaker
    $att{CP} = 'Copy/NoConfirm';
    $att{MV} = 'Rename/NoConfirm';
}

sub constants {
    my($self) = @_;
    my(@m,$def);
    push @m, "
NAME = $att{NAME}
DISTNAME = $att{DISTNAME}
VERSION = $att{VERSION}
VERSION_SYM = $att{VERSION_SYM}

# In which library should we install this extension?
# This is typically the same as PERL_LIB.
# (also see INST_LIBDIR and relationship to ROOTEXT)
INST_LIB = ",vmspath($att{INST_LIB}),"
INST_ARCHLIB = ",vmspath($att{INST_ARCHLIB}),"
INST_EXE = ",vmspath($att{INST_EXE}),"

# AFS users will want to set the installation directories for
# the final 'make install' early without setting INST_LIB,
# INST_ARCHLIB, and INST_EXE for the testing phase
INSTALLPRIVLIB = ",vmspath($att{INSTALLPRIVLIB}),'
INSTALLARCHLIB = ',vmspath($att{INSTALLARCHLIB}),'
INSTALLBIN = ',vmspath($att{INSTALLBIN}),'

# Perl library to use when building the extension
PERL_LIB = ',vmspath($att{PERL_LIB}),'
PERL_ARCHLIB = ',vmspath($att{PERL_ARCHLIB}),'
LIBPERL_A = ',vmsify($att{LIBPERL_A}),'

MAKEMAKER = ',vmsify(unixpath($att{PERL_LIB}).'ExtUtils/MakeMaker.pm'),"
MM_VERSION = $ExtUtils::MakeMaker::Version
";

    # Define I_PERL_LIBS to include the required -Ipaths
    # To be cute we only include PERL_ARCHLIB if different
    # To be portable we add quotes for VMS
    #### Deprecated from Version 4.11: We want to avoid different
    #### behavior for variables with make(1) and perl(1)

    my(@i_perl_libs) = qw{-I$(PERL_ARCHLIB) -I$(PERL_LIB)};
    shift(@i_perl_libs) if ($att{PERL_ARCHLIB} eq $att{PERL_LIB});
    push @m, "I_PERL_LIBS = \"".join('" "',@i_perl_libs)."\"\n";
 
    if ($att{PERL_SRC}) {
         push @m, "
# Where is the perl source code located?
PERL_SRC = ",vmspath($att{PERL_SRC});
    }
    push @m,"
# Perl header files (will eventually be under PERL_LIB)
PERL_INC = ",vmspath($att{PERL_INC}),"
# Perl binaries
PERL = $att{PERL}
FULLPERL = $att{FULLPERL}

# FULLEXT = Pathname for extension directory (eg DBD/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT.
# ROOTEXT = Directory part of FULLEXT with leading slash (e.g /DBD)
FULLEXT = ",vmspath($att{FULLEXT}),"
BASEEXT = $att{BASEEXT}
ROOTEXT = ",($att{ROOTEXT} eq '') ? '[]' : vmspath($att{ROOTEXT}),"

INC = ";

    if ($att{'INC'}) {
	push @m,'/Include=(';
	my(@includes) = split(/\s+/,$att{INC});
	foreach (@includes) {
	    s/^-I//;
	    push @m,vmspath($_);
	}
	push @m, ")\n";
    }

    if ($att{DEFINE} ne '') {
	my(@defs) = split(/\s+/,$att{DEFINE});
	foreach $def (@defs) {
	    $def =~ s/^-D//;
	    $def = "\"$def\"" if $def =~ /=/;
	}
	$att{DEFINE} = join ',',@defs;
    }

    $att{OBJECT} =~ s#\.o\b#\.obj#;
    if ($att{OBJECT} =~ /\s/) {
	$att{OBJECT} =~ s/(\\)?\n+\s+/ /g;
	$att{OBJECT} = map(vmsify($_),split(/,?\s+/,$att{OBJECT}));
    }
    $att{LDFROM} = join(' ',map(fixpath($_),split(/,?\s+/,$att{LDFROM})));
    push @m,"
DEFINE = $att{DEFINE}
OBJECT = $att{OBJECT}
LDFROM = $att{LDFROM})
LINKTYPE = $att{LINKTYPE}

# Handy lists of source code files:
XS_FILES = ",join(', ', sort keys %{$att{XS}}),"
C_FILES  = ",join(', ', @{$att{C}}),"
O_FILES  = ",join(', ', map { s#\.o\b#\.obj#; $_ } @{$att{O_FILES}} ),"
H_FILES  = ",join(', ', @{$att{H}}),"

.SUFFIXES : .xs

# This extension may link to it's own library (see SDBM_File)";
    push @m,"
MYEXTLIB = ",vmsify($att{MYEXTLIB}),"

# Here is the Config.pm that we are using/depend on
CONFIGDEP = \$(PERL_ARCHLIB)Config.pm, \$(PERL_INC)config.h

# Where to put things:
INST_LIBDIR = ",($att{'INST_LIBDIR'} = vmspath(unixpath($att{INST_LIB}) . unixpath($att{ROOTEXT}))),"
INST_ARCHLIBDIR = ",($att{'INST_ARCHLIBDIR'} = vmspath(unixpath($att{INST_ARCHLIB}) . unixpath($att{ROOTEXT}))),"

INST_AUTODIR = ",($att{'INST_AUTODIR'} = vmspath(unixpath($att{INST_LIB}) . 'auto/' . unixpath($att{FULLEXT}))),'
INST_ARCHAUTODIR = ',($att{'INST_ARCHAUTODIR'} = vmspath(unixpath($att{INST_ARCHLIB}) . 'auto/' . unixpath($att{FULLEXT}))),'
';

    if ($self->needs_linking) {
	push @m,'
INST_STATIC = $(INST_ARCHAUTODIR)$(BASEEXT).olb
INST_DYNAMIC = $(INST_ARCHAUTODIR)$(BASEEXT).$(DLEXT)
INST_BOOT = $(INST_ARCHAUTODIR)$(BASEEXT).bs
';
    } else {
	push @m,'
INST_STATIC =
INST_DYNAMIC =
INST_BOOT =
';
    }

    push @m,'
INST_PM = ',join(', ',map(fixpath($_),sort values %{$att{PM}})),'
';

    join('',@m);
}


sub const_cccmd {
    my($cmd) = $Config{'cc'};
    my($name,$sys,@m);

    ( $name = $att{NAME} . "_cflags" ) =~ s/:/_/g ;
    print STDOUT "Unix shell script ".$Config{"$att{'BASEEXT'}_cflags"}.
         " required to modify CC command for $att{'BASEEXT'}\n"
    if ($Config{$name});

    # Deal with $att{DEFINE} here since some C compilers pay attention
    # to only one /Define clause on command line, so we have to
    # conflate the ones from $Config{'cc'} and $att{DEFINE}
    if ($att{DEFINE} ne '') {
	if ($cmd =~ m:/define=\(?([^\(\/\)]+)\)?:i) {
	    $cmd = $` . "/Define=(" . $1 . ",$att{DEFINE})" . $';
	}
	else { $cmd .= "/Define=($att{DEFINE})" }
    }

   $sys = ($cmd =~ /^gcc/i) ? 'GNU_CC_Include:[VMS]' : 'Sys$Library';
        push @m,'
.FIRST
	@ If F$TrnLnm("Sys").eqs."" Then Define/NoLog SYS ',$sys,'

';
   push(@m, "CCCMD = $cmd\n");

   join('',@m);
}



sub const_loadlibs{
    my (@m);
    push @m, "
# $att{NAME} might depend on some other libraries.
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
EXTRALIBS  = ",map(vmsify($_) . ' ',$att{'EXTRALIBS'}),"
BSLOADLIBS = ",map(vmsify($_) . ' ',$att{'BSLOADLIBS'}),"
LDLOADLIBS = ",map(vmsify($_) . ' ',$att{'LDLOADLIBS'}),"\n";

    join('',@m);
}

# --- Tool Sections ---

sub tool_autosplit{
    my($self, %attribs) = @_;
    my($asl) = "";
    $asl = "\$AutoSplit::Maxlen=$attribs{MAXLEN};" if $attribs{MAXLEN};
    q{
# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(PERL) "-I$(PERL_LIB)" "-I$(PERL_ARCHLIB)" -e "use AutoSplit;}.$asl.q{ AutoSplit::autosplit($ARGV[0], $ARGV[1], 0, 1, 1) ;"
};
}

sub tool_xsubpp{
    my($xsdir) = unixpath($att{PERL_LIB}).'ExtUtils';
    # drop back to old location if xsubpp is not in new location yet
    $xsdir = unixpath($att{PERL_SRC}).'ext' unless (-f "$xsdir/xsubpp");
    my(@tmdeps) = '$(XSUBPPDIR)typemap';
    push(@tmdeps, "typemap") if -f "typemap";
    my(@tmargs) = map("-typemap $_", @tmdeps);
    "
XSUBPPDIR = ".vmspath($xsdir)."
XSUBPP = \$(PERL) \$(XSUBPPDIR)xsubpp
XSUBPPDEPS = @tmdeps
XSUBPPARGS = @tmargs
";
}

sub tools_other {
    "
# Assumes \$(MMS) invokes MMS or MMK
# (It is assumed in some cases later that the default makefile name
# (Descrip.MMS for MM[SK]) is used.)
USEMAKEFILE = /Descrip=
USEMACROS = /Macro=(
MACROEND = )
MAKEFILE = Descrip.MMS
SHELL = Posix
LD = $att{LD}
TOUCH = $att{TOUCH}
CP = $att{CP}
RM_F  = $att{RM_F}
RM_RF = $att{RM_RF}
MKPATH = Create/Directory
";
}


# --- Translation Sections ---

sub c_o {
    '
.c.obj :
	$(CCCMD) $(CCCDLFLAGS) /Include=($(PERL_INC)) $(INC) $(MMS$TARGET_NAME).c
';
}

sub xs_c {
    '
.xs.c :
	$(XSUBPP) $(XSUBPPARGS) $(MMS$TARGET_NAME).xs >$(MMS$TARGET)
';
}

sub xs_o {	# many makes are too dumb to use xs_c then c_o
    '
.xs.obj :
	$(XSUBPP) $(XSUBPPARGS) $(MMS$TARGET_NAME).xs >$(MMS$TARGET_NAME).c
	$(CCCMD) $(CCCDLFLAGS) /Include=($(PERL_INC)) $(INC) $(MMS$TARGET_NAME).c
';
}


# --- Target Sections ---

sub top_targets{
    my(@m);
    push @m, '
all ::	config linkext $(INST_PM)
'.$att{NOOP}.'

config :: '.$att{MAKEFILE}.'
	@ $(MKPATH) $(INST_LIBDIR), $(INST_ARCHAUTODIR)
';
    push @m, '
$(O_FILES) : $(H_FILES)
' if @{$att{O_FILES} || []} && @{$att{H} || []};
    join('',@m);
}

sub dlsyms {
    my($self,%attribs) = @_;
    my($funcs) = $attribs{DL_FUNCS} || $att{DL_FUNCS} || {};
    my($vars)  = $attribs{DL_VARS} || $att{DL_VARS} || [];
    my(@m);

    push(@m,'
dynamic :: $(INST_ARCHAUTODIR)perlshr.opt $(INST_ARCHAUTODIR)$(BASEEXT).opt
	',$att{NOOP},'

$(INST_ARCHAUTODIR)perlshr.opt : makefile.PL
	$(PERL) -e "open O,\'>perlshr.opt\'; print O ""PerlShr/Share\n""; close O"
	@ $(PERL) -e "open F,\'>>$(INST_ARCHAUTODIR).packlist\';print F \'$(MMS$TARGET)\';close F;"
') unless $skip{'dynamic'};

    push(@m,'
static :: $(INST_ARCHAUTODIR)$(BASEEXT).opt
	',$att{NOOP},'
') unless $skip{'static'};

    push(@m,'
$(INST_ARCHAUTODIR)$(BASEEXT).opt : $(BASEEXT).opt
	$(CP) $(MMS$SOURCE) $(MMS$TARGET)

$(BASEEXT).opt : makefile.PL
	$(PERL) "-I$(PERL_LIB)" "-I$(PERL_ARCHLIB)" -e "use ExtUtils::MakeMaker; mksymlists(DL_FUNCS => ',neatvalue($att{DL_FUNCS}),', DL_VARS => ',neatvalue($att{DL_VARS}),',NAME => \'',$att{NAME},'\')"
	$(PERL) -e "open OPT,\'>>$(MMS$TARGET)\'; print OPT ""$(INST_STATIC)/Include=$(BASEEXT)\n$(INST_STATIC)/Library\n"";close OPT"
	@ $(PERL) -e "open F,\'>>$(INST_ARCHAUTODIR).packlist\';print F \'$(MMS$TARGET)\';close F;"
');

    join('',@m);
}


# --- Dynamic Loading Sections ---

sub dynamic_lib {
    my($self, %attribs) = @_;
    my($otherldflags) = $attribs{OTHERLDFLAGS} || "";
    my(@m);
    push @m,"

OTHERLDFLAGS = $otherldflags

";
    push @m, '
$(INST_DYNAMIC) : $(INST_STATIC) $(PERL_INC)perlshr_attr.opt $(INST_ARCHAUTODIR)perlshr.opt $(INST_ARCHAUTODIR)$(BASEEXT).opt
	@ $(MKPATH) $(INST_ARCHAUTODIR)
	Link $(LDFLAGS) /Shareable=$(MMS$TARGET)$(OTHERLDFLAGS) $(INST_ARCHAUTODIR)$(BASEEXT).opt/Option,perlshr.opt/Option,$(PERL_INC)perlshr_attr.opt/Option
	$(CHMOD) 755 $(MMS$TARGET)
	@ $(PERL) -e "open F,\'>>$(INST_ARCHAUTODIR).packlist\';print F \'$(MMS$TARGET)\';close F;"
';

    join('',@m);
}

sub dynamic_bs {
    my($self, %attribs) = @_;
    '
BOOTSTRAP = '."$att{BASEEXT}.bs".'

# As MakeMaker mkbootstrap might not write a file (if none is required)
# we use touch to prevent make continually trying to remake it.
# The DynaLoader only reads a non-empty file.
$(BOOTSTRAP) : '."$att{MAKEFILE} $att{BOOTDEP}".'
	@ Write Sys$Output "Running mkbootstrap for $(NAME) ($(BSLOADLIBS))"
	@ $(PERL) "-I$(PERL_LIB)" "-I$(PERL_ARCHLIB)" -e "use ExtUtils::Mkbootstrap; Mkbootstrap(\'$(BASEEXT)\',\'$(BSLOADLIBS)\');"
	@ $(TOUCH) $(MMS$TARGET)
	$(CHMOD) 644 $(MMS$TARGET)
	@ $(PERL) -e "open F,\'>>$(INST_ARCHAUTODIR).packlist\';print F \'$(MMS$TARGET)\';close F;"

$(INST_BOOT) : $(BOOTSTRAP)
	@ '.$att{RM_RF}.' $(INST_BOOT)
	- $(CP) $(BOOTSTRAP) $(INST_BOOT)
	$(CHMOD) 644 $(MMS$TARGET)
	@ $(PERL) -e "open F,\'>>$(INST_ARCHAUTODIR).packlist\';print F \'$(MMS$TARGET)\';close F;"
';
}
# --- Static Loading Sections ---

sub static_lib {
    my(@m);
    push @m,'
$(INST_STATIC) : $(OBJECT) $(MYEXTLIB) $(INST_ARCHAUTODIR).exists
	If F$Search("$(MMS$TARGET)").eqs."" Then Library/Object/Create $(MMS$TARGET)
	Library/Object/Replace $(MMS$TARGET) $(MMS$SOURCE_LIST)
	$(CHMOD) 755 $(MMS$TARGET)
	@ $(PERL) -e "open F,\'>>$(INST_ARCHAUTODIR)extralibs.ld\';print F \'$(EXTRALIBS)\';close F;"
	@ $(PERL) -e "open F,\'>>$(INST_ARCHAUTODIR).packlist\';print F \'$(MMS$TARGET)\';close F;"
';
    push @m, MM->dir_target('$(INST_ARCHAUTODIR)');
    join('',@m);
}


sub installpm_x { # called by installpm perl file
    my($self, $dist, $inst, $splitlib) = @_;
    $inst = fixpath($inst);
    $dist = vmsify($dist);
    my($instdir) = $inst =~ /([^\)]+\))[^\)]*$/ ? $1 : dirname($inst);
    my(@m);

    push(@m, "
$inst : $dist $att{MAKEFILE} ${instdir}.exists
",'	@ $(RM_F) $(MMS$TARGET);*
	@ $(CP) $(MMS$SOURCE) $(MMS$TARGET)
	$(CHMOD) 644 $(MMS$TARGET)
	@ $(PERL) -e "open F,\'>>$(INST_ARCHAUTODIR).packlist\';print F \'$(MMS$TARGET)\';close F;"
');
    if ($splitlib and $inst =~ /\.pm$/) {
      my($attdir) = $splitlib;
      $attdir =~ s/\$\((.*)\)/$1/;
      $attdir = $att{$attdir} if $att{$attdir};

      push(@m, '	$(AUTOSPLITFILE) $(MMS$TARGET) ',
           vmspath(unixpath($attdir) . 'auto')."\n\n");
    }
    push(@m,MM->dir_target($instdir));

    join('',@m);
}

sub processPL {
    return "" unless $att{PL_FILES};
    my(@m, $plfile);
    foreach $plfile (sort keys %{$att{PL_FILES}}) {
	push @m, "
all :: $att{PL_FILES}->{$plfile}

$att{PL_FILES}->{$plfile} :: $plfile
",'	$(PERL) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)" "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" '," $plfile
";
    }
    join "", @m;
}


sub installbin {
    return "" unless $att{EXE_FILES} && ref $att{EXE_FILES} eq "ARRAY";
    my(@m, $from, $to, %fromto, @to, $line);
    for $from (@{$att{EXE_FILES}}) {
	local($_)= '$(INST_EXE)' . basename($from);
	$to = MY->exescan();
	print "exescan($from) => '$to'" if ($Verbose >=2);
	$fromto{$from}=$to;
    }
    @to   = values %fromto;
    push @m, "
EXE_FILES = @{$att{EXE_FILES}}

all :: @to

realclean ::
";
    $line = '';  #avoid unitialized var warning
    foreach $to (@to) {
	if (length($line) + length($to) > 150) {
	    push @m, "\t\$(RM_F) $line\n";
	    $line = $to;
	}
	else { $line .= " $to"; }
    }
    push @m, "\t\$(RM_F) $line\n\n";

    while (($from,$to) = each %fromto) {
	my $todir;
	if ($to =~ m#[/>:\]]#) { $todir = dirname($to); }
	else                   { ($todir = $to) =~ s/[^\)]+$//; }
	$todir = fixpath($todir);
	push @m, "
$to : $from $att{MAKEFILE} ${todir}.exists
	\$(CP) \$(MMS\$SOURCE_LIST) \$(MMS\$TARGET)

", MY->dir_target($todir);
    }
    join "", @m;
}

# --- Sub-directory Sections ---

sub subdir_x {
    my($self, $subdir) = @_;
    my(@m);
    $subdir = vmspath($subdir);
    # The intention is that the calling Makefile.PL should define the
    # $(SUBDIR_MAKEFILE_PL_ARGS) make macro to contain whatever
    # information needs to be passed down to the other Makefile.PL scripts.
    # If this does not suit your needs you'll need to write your own
    # MY::subdir_x() method to override this one.
    push @m, '
config :: ',$subdir,'$(MAKEFILE)
	olddef = F$Environment("Default")
	Set Default ',$subdir,'
	$(MMS) config $(PASTHRU1) $(SUBDIR_MAKEFILE_PL_ARGS)
	Set Default \'olddef\'

',$subdir,'$(MAKEFILE) : ',$subdir,'Makefile.PL, $(CONFIGDEP)
	@Write Sys$Output "Rebuilding $(MMS$TARGET) ..."
	$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -e "use ExtUtils::MakeMaker; MM->runsubdirpl(qw('.$subdir.'))" \\
	$(PASTHRU1) $(SUBDIR_MAKEFILE_PL_ARGS)
	@Write Sys$Output "Rebuild of $(MMS$TARGET) complete."

# The default clean, realclean and test targets in this Makefile
# have automatically been given entries for $subdir.

subdirs ::
	olddef = F$Environment("Default")
	Set Default ',$subdir,'
	$(MMS) all $(PASTHRU2)
	Set Default \'olddef\'
';
    join('',@m);
}


# --- Cleanup and Distribution Sections ---

sub clean {
    my($self, %attribs) = @_;
    my(@m);
    push @m, '
# Delete temporary files but do not touch installed files. We don\'t delete
# the Descrip.MMS here so that a later make realclean still has it to use.
clean ::
';
    foreach (@{$att{DIR}}) { # clean subdirectories first
	my($vmsdir) = vmspath($_);
	push( @m, '	If F$Search("'.$vmsdir.'$(MAKEFILE)") Then \\',"\n\t",
	      '$(PERL) -e "chdir ',"'$vmsdir'",'; print `$(MMS) clean`;"',"\n");
    }
    push @m, '	$(RM_F) *.Map;* *.lis;* *.cpp;* *.Obj;* *.Olb;* $(BOOTSTRAP);* $(BASEEXT).bso;*
';

    my(@otherfiles) = values %{$att{XS}}; # .c files from *.xs files
    push(@otherfiles, $attribs{FILES}) if $attribs{FILES};
    push(@otherfiles, "blib.dir");
    my($file,$line);
    $line = '';  #avoid unitialized var warning
    foreach $file (@otherfiles) {
	$file = fixpath($file);
	if (length($line) + length($file) > 150) {
	    push @m, "\t\$(RM_F) $line\n";
	    $line = "$file;*";
	}
	else { $line .= " $file;*"; }
    }
    push @m, "\t\$(RM_F) $line\n\n";
    # See realclean and ext/utils/make_ext for usage of Makefile.old
    push(@m, '	$(MV) $(MAKEFILE) $(MAKEFILE)_old');
    push(@m, "	$attribs{POSTOP}\n") if $attribs{POSTOP};
    join('', @m);
}


sub realclean {
    my($self, %attribs) = @_;
    my(@m);
    push(@m,'
# Delete temporary files (via clean) and also delete installed files
realclean :: clean
');
    foreach(@{$att{DIR}}){
	my($vmsdir) = vmspath($_);
	push(@m, '	If F$Search("'."$vmsdir$att{MAKEFILE}".'").nes."" Then \\',"\n\t",
	      '$(PERL) -e "chdir ',"'$vmsdir'",'; print `$(MMS) realclean`;"',"\n");
	push(@m, '	If F$Search("'."$vmsdir$att{MAKEFILE}".'_old").nes."" \\',"\n\t",
	      '$(PERL) -e "chdir ',"'$vmsdir'",'; print `$(MMS) $(USEMAKEFILE)$(MAKEFILE)_old realclean`;"'."\n");
    }
    push @m,'	$(RM_RF) $(INST_AUTODIR) $(INST_ARCHAUTODIR)
';
    my($file,$line);
    my(@files) = qw{ *.Opt $(INST_DYNAMIC) $(INST_STATIC) $(INST_BOOT) $(INST_PM) $(OBJECT) $(MAKEFILE) $(MAKEFILE)_old };
    $line = '';  #avoid unitialized var warning
    foreach $file (@files) {
	$file = fixpath($file);
	if (length($line) + length($file) > 150) {
	    push @m, "\t\$(RM_F) $line\n";
	    $line = "$file;*";
	}
	else { $line .= " $file;*"; }
    }
    push @m, "\t\$(RM_F) $line\n";
    if ($attribs{FILES} && ref $attribs{FILES} eq 'ARRAY') {
	foreach $file (@{$attribs{'FILES'}}) {
	    $file = unixify($file);
	    if (length($line) + length($file) > 150) {
		push @m, "\t\$(RM_RF) $line\n";
		$line = "$file;*";
	    }
	    else { $line .= " $file;*"; }
	}
    }
    push @m, "\t\$(RM_RF) $line\n";
    push(@m, "	$attribs{POSTOP}\n")                     if $attribs{POSTOP};
    join('', @m);
}


sub dist {
    my($self, %attribs) = @_;
    my(@m);
    if ($attribs{TARNAME}){
	print STDOUT "Error (fatal): Attribute TARNAME for target dist is deprecated
Please use DISTNAME and VERSION";
    }
    my($name)         = $attribs{NAME}          || '$(DISTNAME)-$(VERSION)';
    my($zip)          = $attribs{ZIP}           || 'zip';
    my($zipflags)     = $attribs{ZIPFLAGS}      || '-Vu';
    my($suffix)       = $attribs{SUFFIX}        || '';
    my($shar)         = $attribs{SHAR}          || 'vms_share';
    my($preop)        = $attribs{PREOP}         || '@ !'; # e.g., update MANIFEST
    my($postop)       = $attribs{POSTOP}        || '@ !';
    my($dist_default) = $attribs{DIST_DEFAULT}  || 'zipdist';
    my($mkfiles)  = join(' ', map("$_\$(MAKEFILE) $_\$(MAKEFILE)_old",map(vmspath($_),@{$att{'DIR'}})));

    my($src) = $name;
    $src = "[.$src]" unless $src =~ /\[/;
    $src =~ s#\]#...]#;
    $src .= '*.*' if $src =~ /\]$/;
    $suffix =~ s#\.#_#g;
    push @m,"
ZIP = $zip
ZIPFLAGS = $zipflags
SUFFIX = $suffix
SHARE = $shar
PREOP = $preop
POSTOP = $postop
DIST_DEFAULT = $dist_default
";

    push @m, '
distclean :: realclean distcheck

distcheck :
	$(PERL) "-I$(PERL_LIB)" -e "use ExtUtils:Manifest \'&fullcheck\'; &fullcheck;"

manifest :
	$(PERL) "-I$(PERL_LIB)" -e "use ExtUtils:Manifest \'&mkmanifest\'; &mkmanifest;"

dist : $(DIST_DEFAULT)

zipdist : ',"${name}.zip$suffix

${name}.zip_$suffix : distdir
	",'$(PREOP)
	$(ZIP) "$(ZIPFLAGS)" $(MMS$TARGET) ',$src,'
	$(RM_RF) ',$name,'
	$(POSTOP)

shdist : distdir
	$(PREOP)
	$(SHARE) ',"$src ${name}.share$suffix",'
	$(RM_RF) ',$name,'
	$(POSTOP)

distdir :
	$(RM_RF) ',$name,'
	$(PERL) "-I$(PERL_LIB)" -e use ExtUtils::Manifest \'/mani/\';" \\
	-e "manicopy(maniread(),',"'$name'",');
';

    join('',@m);
}

# --- Test and Installation Sections ---

sub test {
    my($self, %attribs) = @_;
    my($tests) = $attribs{TESTS} || ( -d 't' ? 't/*.t' : '');
    my(@m);
    push @m,'
TEST_VERBOSE = 0

test : all
' if $tests;
    push(@m,'	$(FULLPERL) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)" "-I$(PERL_LIB)" "-I$(PERL_ARCHLIB)" \\',"\n\t",
            '-e "use Test::Harness qw(&runtests $$verbose); $$verbose=$(TEST_VERBOSE); runtests @ARGV;" \\',"\n\t$tests\n")
      if $tests;
    push(@m,'	$(FULLPERL) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)" "-I$(PERL_LIB)" "-I$(PERL_ARCHLIB)" test.pl',"\n")
      if -f 'test.pl';
    foreach(@{$att{DIR}}){
      my($vmsdir) = vmspath($_);
      push(@m, '	If F$Search("',$vmsdir,'$(MAKEFILE)").nes."" Then $(PERL) -e "chdir ',"'$vmsdir'",
           '; print `$(MMS) $(PASTHRU2) test`'."\n");
    }
    push(@m, "\t\@echo 'No tests defined for \$(NAME) extension.'\n") unless @m > 1;

    join('',@m);
}

sub install {
    my($self, %attribs) = @_;
    my(@m);
    push @m, q{
doc_install ::
	@ $(PERL) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)" "-I$(PERL_LIB)" "_I$(PERL_ARCHLIB)"  \\
		-e "use ExtUtils::MakeMaker; MM->writedoc('Module', '$(NAME)', \\
		'LINKTYPE=$(LINKTYPE)', 'VERSION=$(VERSION)', 'EXE_FILES=$(EXE_FILES)')" \\
		>>$(INSTALLARCHLIB)perllocal.pod
};

    push(@m, "
install :: pure_install doc_install

pure_install :: all
");
    # install subdirectories first
    foreach(@{$att{DIR}}){
      my($vmsdir) = vmspath($_);
      push(@m, '	If F$Search("',$vmsdir,'$(MAKEFILE)").nes."" Then $(PERL) -e "chdir ',"'$vmsdir'",
           '; print `$(MMS) install`"'."\n");
    }

    push(@m, '
	@ $(PERL) -e "foreach (@ARGV){die qq{You do not have permissions to install into $$_\n} unless -w $$_}" $(INSTALLPRIVLIB) $(INSTALLARCHLIB)
	! perl5.000 and MM pre 3.8 used to autosplit into INST_ARCHLIB, we delete these old files here
	$(RM_F) ',fixpath('$(INSTALLARCHLIB)/auto/$(FULLEXT)/*.al;*'),' ',
	             fixpath('$(INSTALLARCHLIB)/auto/$(FULLEXT)/*.ix;*'),"
	\$(MMS) \$(USEMACROS)INST_LIB=$att{INSTALLPRIVLIB},INST_ARCHLIB=$att{INSTALLARCHLIB},INST_EXE=$att{INSTALLBIN}\$(MACROEND)",'
	@ $(PERL) -i_bak -lne "print unless $seen{$_}++" $(INST_ARCHAUTODIR).packlist
');

    push @m, '
#### UNINSTALL IS STILL EXPERIMENTAL ####
uninstall ::
';
    foreach(@{$att{DIR}}){
      my($vmsdir) = vmspath($_);
      push(@m, '	If F$Search("',$vmsdir,'$(MAKEFILE)").nes."" Then $(PERL) -e "chdir ',"'$vmsdir'",
           '; print `$(MMS) uninstall`"'."\n");
    }
    push @m, "\t".'$(PERL) -e "use File::Path; foreach (<>) {chomp;rmtree($_,1,0);}" $(INST_ARCHAUTODIR).packlist
';

    join("",@m);
}

sub perldepend {
    my(@m);

    push @m, '
$(OBJECT) : $(PERL_INC)EXTERN.h, $(PERL_INC)INTERN.h, $(PERL_INC)XSUB.h, $(PERL_INC)av.h
$(OBJECT) : $(PERL_INC)cop.h, $(PERL_INC)cv.h, $(PERL_INC)embed.h, $(PERL_INC)form.h
$(OBJECT) : $(PERL_INC)gv.h, $(PERL_INC)handy.h, $(PERL_INC)hv.h, $(PERL_INC)keywords.h
$(OBJECT) : $(PERL_INC)mg.h, $(PERL_INC)op.h, $(PERL_INC)opcode.h, $(PERL_INC)patchlevel.h
$(OBJECT) : $(PERL_INC)perl.h, $(PERL_INC)perly.h, $(PERL_INC)pp.h, $(PERL_INC)proto.h
$(OBJECT) : $(PERL_INC)regcomp.h, $(PERL_INC)regexp.h, $(PERL_INC)scope.h, $(PERL_INC)sv.h
$(OBJECT) : $(PERL_INC)vmsish.h, $(PERL_INC)util.h, $(PERL_INC)config.h

' if $att{OBJECT}; 

    push(@m,'
# Check for unpropogated config.sh changes. Should never happen.
# We do NOT just update config.h because that is not sufficient.
# An out of date config.h is not fatal but complains loudly!
$(PERL_INC)config.h : $(PERL_SRC)config.sh
	@ Write Sys$Error "Warning: $(PERL_INC)config.h out of date with $(PERL_SRC)config.sh"

$(PERL_ARCHLIB)Config.pm : $(PERL_SRC)config.sh
	@ Write Sys$Error "$(PERL_ARCHLIB)Config.pm may be out of date with $(PERL_SRC)config.sh"
	Set Default $(PERL_SRC)
	$(MMS) $(USEMAKEFILE)[.VMS]$(MAKEFILE) [.lib.',$Config{'arch'},']config.pm
') if $att{PERL_SRC};

    push(@m, join(" ", map(vmsify($_),values %{$att{XS}}))." : \$(XSUBPPDEPS)\n")
      if %{$att{XS}};

    join('',@m);
}

sub makefile {
    my(@m,@cmd);
    # We do not know what target was originally specified so we
    # must force a manual rerun to be sure. But as it should only
    # happen very rarely it is not a significant problem.
    push @m, '
$(OBJECT) : $(MAKEFILE)

# We take a very conservative approach here, but it\'s worth it.
# We move $(MAKEFILE) to $(MAKEFILE)_old here to avoid gnu make looping.
$(MAKEFILE) : Makefile.PL $(CONFIGDEP)
	@ Write Sys$Output "$(MAKEFILE) out-of-date with respect to $(MMS$SOURCE_LIST)"
	@ Write Sys$Output "Cleaning current config before rebuilding $(MAKEFILE) ..."
	- $(MV) $(MAKEFILE) $(MAKEFILE)_old
	- $(MMS) $(USEMAKEFILE)$(MAKEFILE)_old clean
	$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" Makefile.PL ',join(' ',@ARGV),'
	@ Write Sys$Output "Now you must rerun $(MMS)."
';

    join('',@m);
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
	my($vmsdir) = fixpath($dir);
	push @m, "
${vmsdir}.exists :: \$(PERL_INC)perl.h
	\@ \$(MKPATH) $vmsdir
	\@ \$(TOUCH) ${vmsdir}.exists
";
	$Dir_Target{$dir}++;
    }
    join "", @m;
}


sub makeaperl {
    my($self, %attribs) = @_;
    my($makefilename, $searchdirs, $static, $extra, $perlinc, $target, $tmp, $libperl) = 
      @attribs{qw(MAKE DIRS STAT EXTRA INCL TARGET TMP LIBPERL)};
    my(@m);
    my($linkcmd,@staticopts,@staticpkgs,$extralist,$target,$targdir,$libperldir);

    # The front matter of the linkcommand...
    $linkcmd = join ' ', $Config{'ld'},
	    grep($_, @Config{qw(large split ldflags ccdlflags)});
    $linkcmd =~ s/\s+/ /g;

    # Which *.olb files could we make use of...
    local(%olbs);
    $olbs{$att{INST_ARCHAUTODIR}} = "$att{BASEEXT}.olb";
    File::Find::find(sub {
	return unless m/\.olb$/;
	return if m/^libperl/;
	$olbs{$ENV{DEFAULT}} = $_;
    }, grep( -d $_, @{$searchdirs || []}), grep( -f $_, @{$static || []}) );

    $extra = [] unless $extra && ref $extra eq 'ARRAY';
    # Sort the object libraries in inverse order of
    # filespec length to try to insure that dependent extensions
    # will appear before their parents, so the linker will
    # search the parent library to resolve references.
    # (e.g. Intuit::DWIM will precede Intuit, so unresolved
    # references from [.intuit.dwim]dwim.obj can be found
    # in [.intuit]intuit.olb).
    for (sort keys %olbs) {
	next unless $olbs{$_} =~ /\.olb$/;
	my($dir) = vmspath($_);
	my($extralibs) = $dir . "extralibs.ld";
	my($extopt) = $dir . $olbs{$_};
	$extopt =~ s/\.olb$/.opt/;
	if (-f $extralibs ) {
	    open LIST,$extralibs or warn $!,next;
	    push @$extra, <LIST>;
	    close LIST;
	}
	if (-f $extopt) {
	    open OPT,$extopt or die $!;
	    while (<OPT>) {
		next unless /(?:UNIVERSAL|VECTOR)=boot_([\w_]+)/;
		# ExtUtils::Miniperl expects Unix paths
		(my($pkg) = "$2_$2.a") =~ s#_*#/#g;
		push @staticpkgs,$pkg;
	    }
	    push @staticopts, $extopt;
	}
    }

    $target = "Perl.Exe" unless $target;
    ($shrtarget,$targdir) = fileparse($target);
    $shrtarget =~ s/^([^.]*)/$1Shr/;
    $shrtarget = $targdir . $shrtarget;
    $target = "Perlshr$Config{'dlext'}" unless $target;
    $tmp = "[]" unless $tmp;
    $tmp = unixpath($tmp);
    if (@$extra) {
	$extralist = join(' ',@$extra);
	$extralist =~ s/[,\s\n]+/, /g;
    }
    else { $extralist = ''; }
    if ($libperl) {
	unless (-f $libperl || -f ($libperl = unixpath($Config{'installarchlib'})."CORE/$libperl")){
	    print STDOUT "Warning: $libperl not found";
	    undef $libperl;
	}
    }
    unless ($libperl) {
	if (defined $att{PERL_SRC}) {
	    $libperl = "$att{PERL_SRC}/libperl.olb";
	} elsif ( -f ( $libperl = unixpath($Config{'installarchlib'}).'CORE/libperl.olb' )) {
	} else {
	    print STDOUT "Warning: $libperl not found";
	}
    }
    $libperldir = vmspath((fileparse($libperl))[1]);

    push @m, '
# Fill in the target you want to produce if it\'s not perl
MAP_TARGET    = ',vmsify($target),'
MAP_SHRTARGET = ',vmsify($shrtarget),"
FULLPERL      = $att{'FULLPERL'}
MAP_LINKCMD   = $linkcmd
MAP_PERLINC   = ", $perlinc ? map('"-I'.vmspath($_).'" ',@{$perlinc}) : '$(I_PERL_LIB)','
# We use the linker options files created with each extension, rather than
#specifying the object files directly on the command line.
MAP_STATIC    = ',@staticopts ? join(' ', @staticopts) : '','
MAP_OPTS    = ',@staticopts ? ','.join(',', map($_.'/Option', @staticopts)) : '',"
MAP_EXTRA     = $extralist
MAP_LIBPERL = ",vmsify($libperl),'
';


    push @m,'
$(MAP_SHRTARGET) : $(MAP_LIBPERL) $(MAP_STATIC) ',"${libperldir}Perlshr_Attr.Opt",'
	$(MAP_LINKCMD)/Shareable=$(MMS$TARGET) $(MAP_OPTS), $(MAP_EXTRA), $(MAP_LIBPERL) ',"${libperldir}Perlshr_Attr.Opt",'
$(MAP_TARGET) : $(MAP_SHRTARGET) ',vmsify("${tmp}perlmain.obj"),' ',vmsify("${tmp}PerlShr.Opt"),'
	$(MAP_LINKCMD) ',vmsify("${tmp}perlmain.obj"),', PerlShr.Opt/Option
	@ Write Sys$Output "To install the new ""$(MAP_TARGET)"" binary, say"
	@ Write Sys$Output "    $(MMS)$(USEMAKEFILE)$(MAKEFILE) inst_perl $(USEMACROS)MAP_TARGET=$(MAP_TARGET)$(ENDMACRO)"
	@ Write Sys$Output "To remove the intermediate files, say
	@ Write Sys$Output "    $(MMS)$(USEMAKEFILE)$(MAKEFILE) map_clean"
';
    push @m,'
',vmsify("${tmp}perlmain.c"),' : $(MAKEFILE)
	@ $(PERL) $(MAP_PERLINC) -e "use ExtUtils::Miniperl; writemain(qw|',@staticpkgs,'|)" >$(MMS$TARGET)
';

    push @m, q{
doc_inst_perl :
	@ $(PERL) -e "use ExtUtils::MakeMaker; MM->writedoc('Perl binary','$(MAP_TARGET)','MAP_STATIC=$(MAP_STATIC)','MAP_EXTRA=$(MAP_EXTRA)','MAP_LIBPERL=$(MAP_LIBPERL)')"
};

    push @m, "
inst_perl : pure_inst_perl doc_inst_perl

pure_inst_perl : \$(MAP_TARGET)
	$att{CP} \$(MAP_SHRTARGET) ",vmspath($Config{'installbin'}),"
	$att{CP} \$(MAP_TARGET) ",vmspath($Config{'installbin'}),"

map_clean :
	$att{RM_F} ",vmsify("${tmp}perlmain.obj"),vmsify("${tmp}perlmain.c"),
                 vmsify("${tmp}PerlShr.Opt")," $makefilename
";

    join '', @m;
}
  
sub extliblist {
    '','','';
}

sub old_extliblist {
    '','',''
}

sub new_extliblist {
    '','',''
}

sub mksymlists {
    my($self,%attribs) = @_;

    MY->init_main() unless $att{BASEEXT};

    my($vars) = $attribs{DL_VARS} || $att{DL_VARS} || [];
    my($procs) = $attribs{DL_FUNCS} || $att{DL_FUNCS};
    my($package,$packprefix,$sym);
    if (!%$procs) {
        $package = $attribs{NAME} || $att{NAME};
        $package =~ s/\W/_/g;
        $procs = { $package => ["boot_$package"] };
    }
    my($isvax) = $Config{'arch'} =~ /VAX/i;

    # Options file declaring universal symbols
    # Used when linking shareable image for dynamic extension,
    # or when linking PerlShr into which we've added this package
    # as a static extension
    # We don't do anything to preserve order, so we won't relax
    # the GSMATCH criteria for a dynamic extension
    open OPT, ">$att{BASEEXT}.opt";
    foreach $package (keys %$procs) {
        ($packprefix = $package) =~ s/\W/_/g;
        foreach $sym (@{$$procs{$package}}) {
            $sym = "XS_${packprefix}_$sym" unless $sym =~ /^boot_/;
            if ($isvax) { print OPT "UNIVERSAL=$sym\n" }
            else        { print OPT "SYMBOL_VECTOR=($sym=PROCEDURE)\n"; }
        }
    }
    foreach $sym (@$vars) {
        print OPT "PSECT_ATTR=${sym},PIC,OVR,RD,NOEXE,WRT,NOSHR\n";
        if ($isvax) { print OPT "UNIVERSAL=$sym\n" }
        else        { print OPT "SYMBOL_VECTOR=($sym=DATA)\n"; }
    }
    close OPT;
}

# --- Output postprocessing section ---

sub nicetext {
    # Insure that colons marking targets are preceded by space -
    # most Unix Makes don't need this, but it's necessary under VMS
    # to distinguish the target delimiter from a colon appearing as
    # part of a filespec.

    my($self,$text) = @_;
    $text =~ s/([^\s:])(:+\s)/$1 $2/gs;
    $text;
}

1;

__END__
