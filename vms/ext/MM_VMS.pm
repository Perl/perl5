#   MM_VMS.pm
#   MakeMaker default methods for VMS
#   This package is inserted into @ISA of MakeMaker's MM before the
#   built-in MM_Unix methods if MakeMaker.pm is run under VMS.
#
#   Version: 4.03
#   Author:  Charles Bailey  bailey@genetics.upenn.edu
#   Revised: 30-Jan-1995

package ExtUtils::MM_VMS;

use Config;
require Exporter;
use File::VMSspec;
use File::Basename;

Exporter::import('ExtUtils::MakeMaker',
	qw(%att %skip %Recognized_Att_Keys $Verbose &neatvalue));


sub fixpath {
    my($path) = @_;
    my($head,$macro,$tail);

    while (($head,$macro,$tail) = ($path =~ m#(.*?)\$\((\S+?)\)/(.*)#)) { 
        ($macro = unixify($att{$macro})) =~ s#/$##;
        $path = "$head$macro/$tail";
    }
    vmsify($path);
}


sub init_others {
    &MM_Unix::init_others;
    $att{NOOP} = "\tContinue";
    $att{MAKEFILE} = '$(MAKEFILE)';
    $att{RM_F} = '$(PERL) -e "foreach (@ARGV) { -d $_ ? rmdir $_ : unlink $_}"';
    $att{RM_RF} = '$(FULLPERL) -e "use File::Path; use File::VMSspec; @dirs = map(unixify($_),@ARGV); rmtree(\@dirs,0,0)"';
    $att{TOUCH} = '$(PERL) -e "$t=time; utime $t,$t,@ARGV"';
    $att{CP} = 'Copy/NoConfirm';
    $att{MV} = 'Rename/NoConfirm';
}

sub constants {
    my(@m,$def);
    push @m, "
NAME = $att{NAME}
DISTNAME = $att{DISTNAME}
VERSION = $att{VERSION}

# In which library should we install this extension?
# This is typically the same as PERL_LIB.
# (also see INST_LIBDIR and relationship to ROOTEXT)
INST_LIB = ",vmspath($att{INST_LIB}),"
INST_ARCHLIB = ",vmspath($att{INST_ARCHLIB}),"

# Perl library to use when building the extension
PERL_LIB = ",vmspath($att{PERL_LIB}),"
PERL_ARCHLIB = ",vmspath($att{PERL_ARCHLIB}),"
";

# Define I_PERL_LIBS to include the required -Ipaths
# To be cute we only include PERL_ARCHLIB if different
# To be portable we add quotes for VMS
my(@i_perl_libs) = qw{-I$(PERL_ARCHLIB) -I$(PERL_LIB)};
shift(@i_perl_libs) if ($att{PERL_ARCHLIB} eq $att{PERL_LIB});
push @m, "I_PERL_LIBS = \"".join('" "',@i_perl_libs)."\"\n";
 
     push @m, "
# Where is the perl source code located? (Eventually we should
# be able to build extensions without requiring the perl source
# but that's a long way off yet).
PERL_SRC = ",vmspath($att{PERL_SRC}),"
# Perl header files (will eventually be under PERL_LIB)
PERL_INC = ",vmspath($att{PERL_INC}),"
# Perl binaries
PERL = $att{PERL}
FULLPERL = $att{FULLPERL}

# FULLEXT = Pathname for extension directory (eg DBD/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT.
# ROOTEXT = Directory part of FULLEXT with leading slash (e.g /DBD)
FULLEXT = ",vmsify($att{FULLEXT}),"
BASEEXT = $att{BASEEXT}
ROOTEXT = ",$att{ROOTEXT} eq '' ? '[]' : vmspath($att{ROOTEXT}),"

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

    push @m,"
DEFINE = $att{DEFINE}
OBJECT = ",vmsify($att{OBJECT}),"
LDFROM = ",vmsify($att{LDFROM}),"
LINKTYPE = $att{LINKTYPE}

# Handy lists of source code files:
XS_FILES = ",join(', ', sort keys %{$att{XS}}),"
C_FILES  = ",join(', ', @{$att{C}}),"
O_FILES  = ",join(', ', @{$att{O_FILES}}),"
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

INST_STATIC = $(INST_ARCHLIBDIR)$(BASEEXT).olb
INST_DYNAMIC = $(INST_ARCHAUTODIR)$(BASEEXT).$(DLEXT)
INST_BOOT = $(INST_ARCHAUTODIR)$(BASEEXT).bs
INST_PM = ',join(', ',map(fixpath($_),sort values %{$att{PM}})),'
';

    join('',@m);
}


sub const_cccmd {
    my($cmd) = $Config{'cc'};
    my($name,$sys,@m);

    ( $name = $att{NAME} . "_cflags" ) =~ s/:/_/g ;
    warn "Unix shell script ".$Config{"$att{'BASEEXT'}_cflags"}.
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
#
# Dependent libraries are linked in either by the Link command
# at build time or by the DynaLoader at bootstrap time.
#
# These comments may need revising:
#
# EXTRALIBS =	Full list of libraries needed for static linking.
#		Only those libraries that actually exist are included.
#
# BSLOADLIBS =	List of those libraries that are needed but can be
#		linked in dynamically.
#
# LDLOADLIBS =	List of those libraries which must be statically
#		linked into the shared library.
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
AUTOSPLITFILE = $(PERL) $(I_PERL_LIBS) -e "use AutoSplit;}.$asl.q{ AutoSplit::autosplit($ARGV[0], $ARGV[1], 0, 1, 1) ;"
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
    '
all ::	config linkext $(INST_PM)
'.$att{NOOP}.'

config :: '.$att{MAKEFILE}.'
	@ $(MKPATH) $(INST_LIBDIR), $(INST_ARCHAUTODIR)
';
}

sub dlsyms {
    my($self,%attribs) = @_;
    my($funcs) = $attribs{DL_FUNCS} || $att{DL_FUNCS} || {};
    my($vars)  = $attribs{DL_VARS} || $att{DL_VARS} || [];
    my(@m);

    push(@m,'
dynamic :: perlshr.opt $(BASEEXT).opt
	',$att{NOOP},'

perlshr.opt : makefile.PL
	$(FULLPERL) $(I_PERL_LIBS) -e "use ExtUtils::MakeMaker; mksymlists(DL_FUNCS => ',
	%$funcs ? neatvalue($funcs) : "' '",', DL_VARS => ',
	@$vars  ? neatvalue($vars) : "' '",')"
') unless $skip{'dynamic'};

    push(@m,'
static :: $(BASEEXT).opt
	',$att{NOOP},'
') unless $skip{'static'};

    push(@m,'
$(BASEEXT).opt : makefile.PL
	$(FULLPERL) $(I_PERL_LIBS) -e "use ExtUtils::MakeMaker; mksymlists(DL_FUNCS => ',neatvalue($att{DL_FUNCS}),', DL_VARS => ',neatvalue($att{DL_VARS}),')"
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
$(INST_DYNAMIC) : $(OBJECT) $(MYEXTLIB) $(PERL_INC)perlshr_attr.opt $(PERL_INC)crtl.opt perlshr.opt $(BASEEXT).opt
	@ $(MKPATH) $(INST_ARCHAUTODIR)
	Link $(LDFLAGS) /Shareable/Executable=$(MMS$TARGET)$(OTHERLDFLAGS) $(OBJECT),$(PERL_INC)perlshr_attr.opt/Option,$(PERL_INC)crtl.opt/Option,[]perlshr.opt/Option,[]$(BASEEXT).opt/Option
';

    join('',@m);
}

# --- Static Loading Sections ---

sub static_lib {
    my(@m);
    push @m, <<'END';
$(INST_STATIC) : $(OBJECT), $(MYEXTLIB)
	If F$Search("$(MMS$TARGET)").eqs."" Then Library/Object/Create $(MMS$TARGET)
	Library/Object/Replace $(MMS$TARGET) $(MMS$SOURCE_LIST)
END
    push @m,"
	$att{CP}",'$(MMS$SOURCE) $(INST_ARCHAUTODIR)
	$(PERL) -e "print ""$(MMS$TARGET)\n""" >$(INST_ARCHAUTODIR)extralibs.ld
';
    push @m, <<'END' if $att{PERL_SRC};
	@! Old mechanism - still needed:
	$(PERL) -e "print ""$(MMS$TARGET)\n""" >>$(PERL_SRC)ext.libs
END

    join('',@m);
}


sub installpm_x { # called by installpm perl file
    my($self, $dist, $inst, $splitlib) = @_;
    $inst = fixpath($inst);
    $dist = vmsify($dist);
    my($instdir) = dirname($inst);
    my(@m);

    push(@m, "
$inst : $dist
",'	@ ',$att{RM_F},' $(MMS$TARGET);*
	@ $(MKPATH) ',$instdir,'
	@ ',$att{CP},' $(MMS$SOURCE) $(MMS$TARGET)
');
    if ($splitlib and $inst =~ /\.pm$/) {
      my($attdir) = $splitlib;
      $attdir =~ s/\$\((.*)\)/$1/;
      $attdir = $att{$attdir} if $att{$attdir};

      push(@m, '	$(AUTOSPLITFILE) $(MMS$TARGET) ',
           vmspath(unixpath($attdir) . 'auto')."\n");
      push(@m,"\n");
    }

    join('',@m);
}


# --- Sub-directory Sections ---

sub subdir_x {
    my($self, $subdir) = @_;
    my(@m);
    # The intention is that the calling Makefile.PL should define the
    # $(SUBDIR_MAKEFILE_PL_ARGS) make macro to contain whatever
    # information needs to be passed down to the other Makefile.PL scripts.
    # If this does not suit your needs you'll need to write your own
    # MY::subdir_x() method to override this one.
    push @m, '
config :: ',vmspath($subdir) . '$(MAKEFILE)
	$(MMS) $(USEMAKEFILE) $(MMS$SOURCE) config $(USEMACROS)(INST_LIB=$(INST_LIB),INST_ARCHLIB=$(INST_ARCHLIB),LINKTYPE=$(LINKTYPE)$(MACROEND)

',vmspath($subdir),'$(MAKEFILE) : ',vmspath($subdir),'Makefile.PL, $(CONFIGDEP)
	@Write Sys$Output "Rebuilding $(MMS$TARGET) ..."
	$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -e "use ExtUtils::MakeMaker; MM->runsubdirpl(qw('.$subdir.'))" \\
	$(SUBDIR_MAKEFILE_PL_ARGS) INST_LIB=$(INST_LIB) INST_ARCHLIB=$(INST_ARCHLIB)
	@Write Sys$Output "Rebuild of $(MMS$TARGET) complete."

# The default clean, realclean and test targets in this Makefile
# have automatically been given entries for $subdir.

subdirs ::
	Set Default ',vmspath($subdir),'
	$(MMS) all $(USEMACROS)LINKTYPE=$(LINKTYPE)$(MACROEND)
';
    join('',@m);
}


# --- Cleanup and Distribution Sections ---

sub clean {
    my($self, %attribs) = @_;
    my(@m);
    push @m, '
# Delete temporary files but do not touch installed files
# We don\'t delete the Makefile here so that a
# later make realclean still has a makefile to work from
clean ::
';
    foreach (@{$att{DIR}}) { # clean subdirectories first
	my($vmsdir) = vmspath($_);
	push( @m, '	If F$Search("'.$vmsdir.'$(MAKEFILE)") Then $(MMS) $(USEMAKEFILE)'.$vmsdir.'$(MAKEFILE) clean'."\n");
    }
    push @m, "
	$att{RM_F} *.Map;* *.lis;* *.cpp;* *.Obj;* *.Olb;* \$(BOOTSTRAP);* \$(BASEEXT).bso;*
";

    my(@otherfiles) = values %{$att{XS}}; # .c files from *.xs files
    push(@otherfiles, $attribs{FILES}) if $attribs{FILES};
    push(@otherfiles, "blib.dir");
    push(@m, "	$att{RM_F} ".join(";* ", map(fixpath($_),@otherfiles)),";*\n");
    # See realclean and ext/utils/make_ext for usage of Makefile.old
    push(@m, "	$att{MV} $att{MAKEFILE} $att{MAKEFILE}_old");
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
	push(@m, '	If F$Search("'."$vmsdir$att{MAKEFILE}".'").nes."" Then $(MMS) $(USEMAKEFILE)'."$vmsdir$att{MAKEFILE}".' realclean'."\n");
	push(@m, '	If F$Search("'."$vmsdir$att{MAKEFILE}".'_old").nes."" Then $(MMS) $(USEMAKEFILE)'."$vmsdir$att{MAKEFILE}".'_old realclean'."\n");
    }
    push @m,'
	',$att{RM_RF},' $(INST_AUTODIR) $(INST_ARCHAUTODIR)
	',$att{RM_F},' *.Opt;* $(INST_DYNAMIC);* $(INST_STATIC);* $(INST_BOOT);* $(INST_PM);*
	',$att{RM_F},' $(OBJECT);* $(MAKEFILE);* $(MAKEFILE)_old;*
';
    push(@m, "	$att{RM_RF} ".join(";* ", map(fixpath($_),$attribs{'FILES'})),";*\n") if $attribs{'FILES'};
    push(@m, "	$attribs{POSTOP}\n")                     if $attribs{POSTOP};
    join('', @m);
}


sub distclean {
    my($self, %attribs) = @_;
    my($preop)    = $attribs{PREOP}  || '@ !'; # e.g., update MANIFEST
    my($zipname)  = $attribs{ZIPNAME}  || '$(DISTNAME)-$(VERSION)';
    my($zipflags) = $attribs{ZIPFLAGS} || '-Vu';
    my($postop)   = $attribs{POSTOP} || "";
    my(@mkfildirs)  = map(vmspath($_),@{$att{'DIR'}});
    my(@m,$dir);

    push @m,'
distclean : realclean
	',$preop,'
	If F$Search("$(MAKEFILE)").nes."" Then ',$att{RM_F},' $(MAKEFILE);*
';
    foreach $dir (@mkfildirs) {
      push(@m,'If F$Search("',$dir,'$(MAKEFILE)") Then Delete/Log/NoConfirm ',
              $dir,'$(MAKEFILE);*',"\n");
    }

    push(@m,"	Zip \"$zipflags\" $zipname \$(BASEEXT).* Makefile.PL
	$postop
");

    join('',@m);
}


# --- Test and Installation Sections ---

sub test {
    my($self, %attribs) = @_;
    my($tests) = $attribs{TESTS} || ( -d 't' ? 't/*.t' : '');
    my(@m);
    push @m,'
test : all
';
    push(@m,'	$(FULLPERL) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)" $(I_PERL_LIBS) -e "use Test::Harness; runtests @ARGV;" '.$tests."\n")
      if $tests;
    push(@m,'	$(FULLPERL) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)" "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" test.pl',"\n")
      if -f 'test.pl';
    foreach(@{$att{DIR}}){
      my($vmsdir) = vmspath($_);
      push(@m, '	If F$Search("',$vmsdir,'$(MAKEFILE)").nes."" Then $(PERL) -e "chdir \'',$vmsdir,
           '\'; print `$(MMS) $(USEMAKEFILE)$(MAKEFILE) $(USEMACRO)LINKTYPE=$(LINKTYPE)$(MACROEND) test`'."\n");
    }
    push(@m, "\t\@echo 'No tests defined for \$(NAME) extension.'\n") unless @m > 1;

    join('',@m);
}

sub install {
    my($self, %attribs) = @_;
    my(@m);
    push(@m, "
install :: all
");
    # install subdirectories first
    foreach(@{$att{DIR}}){
      my($vmsdir) = vmspath($_);
      push(@m, '	If F$Search("',$vmsdir,'$(MAKEFILE)").nes."" Then $(PERL) -e "chdir \'',$vmsdir,
           '\'; print `$(MMS) $(USEMAKEFILE)$(MAKEFILE) install`'."\n");
    }

    push(@m, "\t! perl5.000 used to autosplit into INST_ARCHLIB, we delete these old files here
	$att{RM_F} ",fixpath('$(INST_ARCHLIB)/auto/$(FULLEXT)/*.al'),";*,",fixpath('$(INST_ARCHLIB)/auto/$(FULLEXT)/*.ix'),';*
	$(MMS) $(USEMACROS)INST_LIB=\$(INST_PRIVLIB),INST_ARCHLIB=\$(INST_ARCHLIB)$(MACROEND)
');

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
$(O_FILES) : $(H_FILES)

';
    push(@m,'

$(PERL_ARCHLIB)/Config.pm: $(PERL_SRC)/config.sh
	@ Write Sys$Error "$(PERL_ARCHLIB)/Config.pm may be out of date with $(PERL_SRC)/config.sh"
	Set Default $(PERL_SRC)
	$(MMS) $(USEMAKEFILE)[.VMS]$(MAKEFILE) [.lib]config.pm
');

    push(@m, join(" ", map(vmsify($_),values %{$att{XS}}))." : \$(XSUBPPDEPS)\n")
      if %{$att{XS}};

    join('',@m);
}

sub makefile {
    my(@m,@cmd);
    @cmd = grep(/^\s/,split(/\n/,MY->c_o()));
    push(@m,join("\n",@cmd));
    push(@m,'

# We take a very conservative approach here, but it\'s worth it.
# We move $(MAKEFILE) to $(MAKEFILE)_old here to avoid gnu make looping.
$(MAKEFILE) : Makefile.PL $(CONFIGDEP)
	@ Write Sys$Output "',$att{MAKEFILE},' out-of-date with respect to $(MMS$SOURCE_LIST)"
	@ Write Sys$Output "Cleaning current config before rebuilding ',$att{MAKEFILE},'...
	- ',"$att{MV} $att{MAKEFILE} $att{MAKEFILE}_old",'
	- $(MMS) $(USEMAKEFILE)',$att{MAKEFILE},'_old clean
	$(PERL) $(I_PERL_LIBS) Makefile.PL
	@ Write Sys$Output "Now you must rerun $(MMS)."
');

    join('',@m);
}


# --- Determine libraries to use and how to use them ---

sub extliblist {
    '','','';
}

sub old_extliblist {
    '','',''
}

sub new_extliblist {
    '','',''
}

# --- Write a DynaLoader bootstrap file if required

# VMS doesn't require a bootstrap file as a rule
sub mkbootstrap {
    1;
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
    # First, a short linker options file to specify PerlShr
    # used only when linking dynamic extension
    open OPT, ">PerlShr.Opt";
    print OPT "PerlShr/Share\n";
    close OPT;

    # Next, the options file declaring universal symbols
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
