#   MM_VMS.pm
#   MakeMaker default methods for VMS
#   This package is inserted into @ISA of MakeMaker's MM before the
#   built-in ExtUtils::MM_Unix methods if MakeMaker.pm is run under VMS.
#
#   Version: 5.17
#   Author:  Charles Bailey  bailey@genetics.upenn.edu
#   Revised: 14-Jan-1996

package ExtUtils::MM_VMS;

use Config;
require Exporter;
use VMS::Filespec;
use File::Basename;

Exporter::import('ExtUtils::MakeMaker', '$Verbose', '&neatvalue');


sub eliminate_macros {
    my($self,$path) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    unless ($path) {
	print "eliminate_macros('') = ||\n" if $Verbose >= 3;
	return '';
    }
    my($npath) = unixify($path);
    my($head,$macro,$tail);

    # perform m##g in scalar context so it acts as an iterator
    while ($npath =~ m#(.*?)\$\((\S+?)\)(.*)#g) { 
        if ($self->{$2}) {
            ($head,$macro,$tail) = ($1,$2,$3);
            ($macro = unixify($self->{$macro})) =~ s#/$##;
            $npath = "$head$macro$tail";
        }
    }
    print "eliminate_macros($path) = |$npath|\n" if $Verbose >= 3;
    $npath;
}

# Catchall routine to clean up problem macros.  Expands macros in any directory
# specification, and expands expressions which are all macro, so that we can
# tell how long the expansion is, and avoid overrunning DCL's command buffer
# when MM[KS] is running.
sub fixpath {
    my($self,$path,$force_path) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    unless ($path) {
	print "eliminate_macros('') = ||\n" if $Verbose >= 3;
	return '';
    }
    my($fixedpath,$prefix,$name);

    if ($path =~ m#^\$\(.+\)$# || $path =~ m#[/:>\]]#) { 
        if ($force_path or $path =~ /(?:DIR\)|\])$/) {
            $fixedpath = vmspath($self->eliminate_macros($path));
        }
        else {
            $fixedpath = vmsify($self->eliminate_macros($path));
        }
    }
    elsif ((($prefix,$name) = ($path =~ m#^\$\(([^\)]+)\)(.+)#)) && $self->{$prefix}) {
        my($vmspre) = vmspath($self->{$prefix}) || ''; # is it a dir or just a name?
        $fixedpath = ($vmspre ? $vmspre : $self->{$prefix}) . $name;
        $fixedpath = vmspath($fixedpath) if $force_path;
    }
    else {
        $fixedpath = $path;
        $fixedpath = vmspath($fixedpath) if $force_path;
    }
    # Convert names without directory or type to paths
    if (!$force_path and $fixedpath !~ /[:>(.\]]/) { $fixedpath = vmspath($fixedpath); }
    print "fixpath($path) = |$fixedpath|\n" if $Verbose >= 3;
    $fixedpath;
}

sub catdir {
    my($self,@dirs) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my($dir) = pop @dirs;
    @dirs = grep($_,@dirs);
    my($rslt);
    if (@dirs) {
      my($path) = (@dirs == 1 ? $dirs[0] : $self->catdir(@dirs));
      my($spath,$sdir) = ($path,$dir);
      $spath =~ s/.dir$//; $sdir =~ s/.dir$//; 
      $sdir = $self->eliminate_macros($sdir) unless $sdir =~ /^[\w\-]+$/;
      $rslt = vmspath($self->eliminate_macros($spath)."/$sdir");
    }
    else { $rslt = vmspath($dir); }
    print "catdir(",join(',',@_[1..$#_]),") = |$rslt|\n" if $Verbose >= 3;
    $rslt;
}

sub catfile {
    my($self,@files) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my($file) = pop @files;
    @files = grep($_,@files);
    my($rslt);
    if (@files) {
      my($path) = (@files == 1 ? $files[0] : $self->catdir(@files));
      my($spath) = $path;
      $spath =~ s/.dir$//;
      if ( $spath =~ /^[^\)\]\/:>]+\)$/ && basename($file) eq $file) { $rslt = "$spath$file"; }
      else {
          $rslt = $self->eliminate_macros($spath);
          $rslt = vmsify($rslt.($rslt ? '/' : '').unixify($file));
      }
    }
    else { $rslt = vmsify($file); }
    print "catfile(",join(',',@_[1..$#_]),") = |$rslt|\n" if $Verbose >= 3;
    $rslt;
}


# Default name is taken from the directory name if it's not passed in.
# Since VMS filenames are case-insensitive, we actually look in the
# extension files to find the Mixed-case name
sub guess_name {
    my($self) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my($defname,$defpm);
    local *PM;

    $defname = $ENV{'DEFAULT'};
    $defname =~ s:.*?([^.\]]+)\]:$1:
        unless ($defname =~ s:.*[.\[]ext\.(.*)\]:$1:i);
    $defname =~ s#[.\]]#::#g;
    ($defpm = $defname) =~ s/.*:://;
    if (open(PM,"${defpm}.pm")){
        while (<PM>) {
            if (/^\s*package\s+([^;]+)/i) {
                $defname = $1;
                last;
            }
        }
        print STDOUT "Warning (non-fatal): Couldn't find package name in ${defpm}.pm;\n\t",
                     "defaulting package name to $defname\n"
            if eof(PM);
        close PM;
    }
    else {
        print STDOUT "Warning (non-fatal): Couldn't find ${defpm}.pm;\n\t",
                     "defaulting package name to $defname\n";
    }
    $defname =~ s#[\-_][\d.\-]+$##;
    $defname;
}


sub find_perl{
    my($self, $ver, $names, $dirs, $trace) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my($name, $dir,$vmsfile,@cand);
    if ($trace){
	print "Looking for perl $ver by these names:\n";
	print "\t@$names,\n";
	print "in these dirs:\n";
	print "\t@$dirs\n";
    }
    foreach $dir (@$dirs){
	next unless defined $dir; # $self->{PERL_SRC} may be undefined
	foreach $name (@$names){
	    if ($name !~ m![/:>\]]!) { push(@cand,$self->catfile($dir,$name)); }
	    else                     { push(@cand,$self->fixpath($name));      }
	}
    }
    foreach $name (sort { length($a) <=> length($b) } @cand) {
	print "Checking $name\n" if ($trace >= 2);
	next unless $vmsfile = $self->maybe_command($name);
	print "Executing $vmsfile\n" if ($trace >= 2);
	if (`MCR $vmsfile -e "require $ver; print ""VER_OK\n"""` =~ /VER_OK/) {
	    print "Using PERL=MCR $vmsfile\n" if $trace;
	    return "MCR $vmsfile"
	}
    }
    print STDOUT "Unable to find a perl $ver (by these names: @$names, in these dirs: @$dirs)\n";
    0; # false and not empty
}


sub maybe_command {
    my($self,$file) = @_;
    return $file if -x $file && ! -d _;
    return "$file.exe" if -x "$file.exe";
    if ($file !~ m![/:>\]]!) {
	my($shrfile) = 'Sys$Share:' . $file;
	return $file if -x $shrfile && ! -d _;
	return "$file.exe" if -x "$shrfile.exe";
    }
    return 0;
}


sub maybe_command_in_dirs {	# $ver is optional argument if looking for perl
    my($self, $names, $dirs, $trace, $ver) = @_;
    my($name, $dir);
    foreach $dir (@$dirs){
	next unless defined $dir; # $self->{PERL_SRC} may be undefined
	foreach $name (@$names){
	    my($abs,$tryabs);
	    if ($self->file_name_is_absolute($name)) {
		$abs = $name;
	    } else {
		$abs = $self->catfile($dir, $name);
	    }
	    print "Checking $abs for $name\n" if ($trace >= 2);
	    next unless $tryabs = $self->maybe_command($abs);
	    print "Substituting $tryabs instead of $abs\n" 
		if ($trace >= 2 and $tryabs ne $abs);
	    $abs = $tryabs;
	    if (defined $ver) {
		print "Executing $abs\n" if ($trace >= 2);
		if (`$abs -e 'require $ver; print "VER_OK\n" ' 2>&1` =~ /VER_OK/) {
		    print "Using PERL=$abs\n" if $trace;
		    return $abs;
		}
	    } else { # Do not look for perl
		return $abs;
	    }
	}
    }
}


sub perl_script {
    my($self,$file) = @_;
    return $file if -r $file && ! -d _;
    return "$file.pl" if -r "$file.pl" && ! -d _;
    return '';
}

sub file_name_is_absolute {
    my($sefl,$file);
    $file =~ m!^/! or $file =~ m![:<\[][^.]!;
}


sub replace_manpage_separator {
    my($self,$man) = @_;
    $man = unixify($man);
    $man =~ s#/+#__#g;
    $man;
}


sub init_others {
    my($self) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }

    $self->{NOOP} = "\t@ Continue";
    $self->{FIRST_MAKEFILE} ||= 'Descrip.MMS';
    $self->{MAKE_APERL_FILE} ||= 'Makeaperl.MMS';
    $self->{MAKEFILE} ||= $self->{FIRST_MAKEFILE};
    $self->{NOECHO} ||= '@ ';
    $self->{RM_F} = '$(PERL) -e "foreach (@ARGV) { 1 while ( -d $_ ? rmdir $_ : unlink $_)}"';
    $self->{RM_RF} = '$(PERL) "-I$(INST_LIB)" -e "use File::Path; @dirs = map(VMS::Filespec::unixify($_),@ARGV); rmtree(\@dirs,0,0)"';
    $self->{TOUCH} = '$(PERL) -e "$t=time; foreach (@ARGV) { -e $_ ? utime($t,$t,@ARGV) : (open(F,qq(>$_)),close F)}"';
    $self->{CHMOD} = '$(PERL) -e "chmod @ARGV"';  # expect Unix syntax from MakeMaker
    $self->{CP} = 'Copy/NoConfirm';
    $self->{MV} = 'Rename/NoConfirm';
    $self->{UMASK_NULL} = "\t!";  
    &ExtUtils::MM_Unix::init_others;
}

sub constants {
    my($self) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my(@m,$def);
    push @m, "
NAME = $self->{NAME}
DISTNAME = $self->{DISTNAME}
NAME_SYM = $self->{NAME_SYM}
VERSION = $self->{VERSION}
VERSION_SYM = $self->{VERSION_SYM}
VERSION_MACRO = VERSION
DEFINE_VERSION = ",'"$(VERSION_MACRO)=""$(VERSION)"""',"
XS_VERSION = $self->{XS_VERSION}
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = ",'"$(XS_VERSION_MACRO)=""$(XS_VERSION)"""',"

# In which library should we install this extension?
# This is typically the same as PERL_LIB.
# (also see INST_LIBDIR and relationship to ROOTEXT)
INST_LIB = ",$self->fixpath($self->{INST_LIB},1),"
INST_ARCHLIB = ",$self->fixpath($self->{INST_ARCHLIB},1),"
INST_EXE = ",$self->fixpath($self->{INST_EXE},1),"

PREFIX = $self->{PREFIX}

# AFS users will want to set the installation directories for
# the final 'make install' early without setting INST_LIB,
# INST_ARCHLIB, and INST_EXE for the testing phase
INSTALLPRIVLIB = ",$self->fixpath($self->{INSTALLPRIVLIB},1),'
INSTALLARCHLIB = ',$self->fixpath($self->{INSTALLARCHLIB},1),'
INSTALLBIN = ',$self->fixpath($self->{INSTALLBIN},1),'

# Perl library to use when building the extension
PERL_LIB = ',$self->fixpath($self->{PERL_LIB},1),'
PERL_ARCHLIB = ',$self->fixpath($self->{PERL_ARCHLIB},1),'
LIBPERL_A = ',$self->fixpath($self->{LIBPERL_A}),'

MAKEMAKER = ',$self->catfile($self->{PERL_LIB},'ExtUtils','MakeMaker.pm'),"
MM_VERSION = $ExtUtils::MakeMaker::VERSION
FIRST_MAKEFILE  = ",$self->fixpath($self->{FIRST_MAKEFILE}),'
MAKE_APERL_FILE = ',$self->fixpath($self->{MAKE_APERL_FILE}),"

PERLMAINCC = $self->{PERLMAINCC}
";

    if ($self->{PERL_SRC}) {
         push @m, "
# Where is the perl source code located?
PERL_SRC = ",$self->fixpath($self->{PERL_SRC},1);
        push @m, "
PERL_VMS = ",$self->catdir($self->{PERL_SRC},q(VMS));
    }
    push @m,"
# Perl header files (will eventually be under PERL_LIB)
PERL_INC = ",$self->fixpath($self->{PERL_INC},1),"
# Perl binaries
PERL = $self->{PERL}
FULLPERL = $self->{FULLPERL}

# FULLEXT = Pathname for extension directory (eg DBD/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT.
# ROOTEXT = Directory part of FULLEXT with leading slash (e.g /DBD)
FULLEXT = ",$self->fixpath($self->{FULLEXT},1),"
BASEEXT = $self->{BASEEXT}
ROOTEXT = ",($self->{ROOTEXT} eq '') ? '[]' : $self->fixpath($self->{ROOTEXT},1),"
DLBASE  = $self->{DLBASE}
";

    push @m, "
VERSION_FROM = $self->{VERSION_FROM}
" if defined $self->{VERSION_FROM};

    push @m,'
INC = ';

    if ($self->{'INC'}) {
	push @m,'/Include=(';
	my(@includes) = split(/\s+/,$self->{INC});
	my($plural);
	foreach (@includes) {
	    s/^-I//;
	    push @m,', ' if $plural++;
	    push @m,$self->fixpath($_,1);
	}
	push @m, ")\n";
    }

    if ($self->{DEFINE} ne '') {
	my(@defs) = split(/\s+/,$self->{DEFINE});
	foreach $def (@defs) {
	    next unless $def;
	    $def =~ s/^-D//;
	    $def = "\"$def\"" if $def =~ /=/;
	}
	$self->{DEFINE} = join ',',@defs;
    }

    if ($self->{OBJECT} =~ /\s/) {
	$self->{OBJECT} =~ s/(\\)?\n+\s+/ /g;
	$self->{OBJECT} = map($self->fixpath($_),split(/,?\s+/,$self->{OBJECT}));
    }
    $self->{LDFROM} = join(' ',map($self->fixpath($_),split(/,?\s+/,$self->{LDFROM})));

    push @m,"
DEFINE = $self->{DEFINE}
OBJECT = $self->{OBJECT}
LDFROM = $self->{LDFROM}
LINKTYPE = $self->{LINKTYPE}

# Handy lists of source code files:
XS_FILES = ",join(', ', sort keys %{$self->{XS}}),'
C_FILES  = ',join(', ', @{$self->{C}}),'
O_FILES  = ',join(', ', @{$self->{O_FILES}} ),'
H_FILES  = ',join(', ', @{$self->{H}}),'
MAN1PODS = ',join(" \\\n\t", sort keys %{$self->{MAN1PODS}}),'
MAN3PODS = ',join(" \\\n\t", sort keys %{$self->{MAN3PODS}}),'

# Man installation stuff:
INST_MAN1DIR = ',$self->fixpath($self->{INST_MAN1DIR},1),'
INSTALLMAN1DIR = ',$self->fixpath($self->{INSTALLMAN1DIR},1),"
MAN1EXT = $self->{MAN1EXT}

INST_MAN3DIR = ",$self->fixpath($self->{INST_MAN3DIR},1),'
INSTALLMAN3DIR = ',$self->fixpath($self->{INSTALLMAN3DIR},1),"
MAN3EXT = $self->{MAN3EXT}


.SUFFIXES : .xs .c \$(OBJ_EXT)

# This extension may link to it's own library (see SDBM_File)";
    push @m,"
MYEXTLIB = ",$self->fixpath($self->{MYEXTLIB}),"

# Here is the Config.pm that we are using/depend on
CONFIGDEP = \$(PERL_ARCHLIB)Config.pm, \$(PERL_INC)config.h \$(VERSION_FROM)

# Where to put things:
INST_LIBDIR = ",($self->{'INST_LIBDIR'} = $self->catdir($self->{INST_LIB},$self->{ROOTEXT})),"
INST_ARCHLIBDIR = ",($self->{'INST_ARCHLIBDIR'} = $self->catdir($self->{INST_ARCHLIB},$self->{ROOTEXT})),"

INST_AUTODIR = ",($self->{'INST_AUTODIR'} = $self->catdir($self->{INST_LIB},'auto',$self->{FULLEXT})),'
INST_ARCHAUTODIR = ',($self->{'INST_ARCHAUTODIR'} = $self->catdir($self->{INST_ARCHLIB},'auto',$self->{FULLEXT})),'
';

    if ($self->has_link_code()) {
	push @m,'
INST_STATIC = $(INST_ARCHAUTODIR)$(BASEEXT)$(LIB_EXT)
INST_DYNAMIC = $(INST_ARCHAUTODIR)$(BASEEXT).$(DLEXT)
INST_BOOT = $(INST_ARCHAUTODIR)$(BASEEXT).bs
';
    } else {
	push @m,'
INST_STATIC =
INST_DYNAMIC =
INST_BOOT =
EXPORT_LIST = $(BASEEXT).opt
PERL_ARCHIVE = ',($ENV{'PERLSHR'} ? $ENV{'PERLSHR'} : 'Sys$Share:PerlShr.Exe'),'
';
    }

    push @m,'
INST_PM = ',join(', ',map($self->fixpath($_),sort values %{$self->{PM}})),'
';

    join('',@m);
}


sub const_loadlibs{
    my($self) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my (@m);
    push @m, "
# $self->{NAME} might depend on some other libraries.
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
EXTRALIBS  = ",map($self->fixpath($_) . ' ',$self->{'EXTRALIBS'}),"
BSLOADLIBS = ",map($self->fixpath($_) . ' ',$self->{'BSLOADLIBS'}),"
LDLOADLIBS = ",map($self->fixpath($_) . ' ',$self->{'LDLOADLIBS'}),"\n";

    join('',@m);
}


sub const_cccmd {
    my($self,$libperl) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my($cmd,$quals) = ($Config{'cc'},$Config{'ccflags'});
    my($name,$sys,@m);

    ( $name = $self->{NAME} . "_cflags" ) =~ s/:/_/g ;
    print STDOUT "Unix shell script ".$Config{"$self->{'BASEEXT'}_cflags"}.
         " required to modify CC command for $self->{'BASEEXT'}\n"
    if ($Config{$name});

    # Deal with $self->{DEFINE} here since some C compilers pay attention
    # to only one /Define clause on command line, so we have to
    # conflate the ones from $Config{'cc'} and $self->{DEFINE}
    if ($quals =~ m:(.*)/define=\(?([^\(\/\)\s]+)\)?(.*)?:i) {
	$quals = "$1/Define=($2," . ($self->{DEFINE} ? "$self->{DEFINE}," : '') .
	         "\$(DEFINE_VERSION),\$(XS_DEFINE_VERSION))$3";
    }
    else {
	$quals .= '/Define=(' . ($self->{DEFINE} ? "$self->{DEFINE}," : '') .
	          '$(DEFINE_VERSION),$(XS_DEFINE_VERSION))';
    }

    $libperl or $libperl = $self->{LIBPERL_A} || "libperl.olb";
    if ($libperl =~ /libperl(\w+)\./i) {
        my($type) = uc $1;
        my(%map) = ( 'D'  => 'DEBUGGING', 'E' => 'EMBED', 'M' => 'MULTIPLICITY',
                     'DE' => 'DEBUGGING,EMBED', 'DM' => 'DEBUGGING,MULTIPLICITY',
                     'EM' => 'EMBED,MULTIPLICITY', 'DEM' => 'DEBUGGING,EMBED,MULTIPLICITY' );
        $quals =~ s:/define=\(([^\)]+)\):/Define=($1,$map{$type}):i
    }

    # Likewise with $self->{INC} and /Include
    my($incstr) = '/Include=($(PERL_INC)';
    if ($self->{'INC'}) {
	my(@includes) = split(/\s+/,$self->{INC});
	foreach (@includes) {
	    s/^-I//;
	    $incstr .= ', '.$self->fixpath($_,1);
	}
    }
    if ($quals =~ m:(.*)/include=\(?([^\(\/\)\s]+)\)?(.*):i) {
	$quals = "$1$incstr,$2)$3";
    }
    else { $quals .= "$incstr)"; }


   if ($Config{'vms_cc_type'} ne 'decc') {
        push @m,'
.FIRST
	',$self->{NOECHO},'If F$TrnLnm("Sys").eqs."" Then Define/NoLog SYS ',
        ($Config{'vms_cc_type'} eq 'gcc' ? 'GNU_CC_Include:[VMS]'
                                         : 'Sys$Library'),'

';
   }
   push(@m, "CCCMD = $cmd$quals\n");

   $self->{CONST_CCCMD} = join('',@m);
}


# --- Tool Sections ---

sub tool_autosplit{
    my($self, %attribs) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my($asl) = "";
    $asl = "\$AutoSplit::Maxlen=$attribs{MAXLEN};" if $attribs{MAXLEN};
    q{
# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -e "use AutoSplit;}.$asl.q{ AutoSplit::autosplit($ARGV[0], $ARGV[1], 0, 1, 1) ;"
};
}

sub tool_xsubpp{
    my($self) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my($xsdir) = $self->catdir($self->{PERL_LIB},'ExtUtils');
    # drop back to old location if xsubpp is not in new location yet
    $xsdir = $self->catdir($self->{PERL_SRC},'ext') unless (-f $self->catfile($xsdir,'xsubpp'));
    my(@tmdeps) = '$(XSUBPPDIR)typemap';
    if( $self->{TYPEMAPS} ){
	my $typemap;
	foreach $typemap (@{$self->{TYPEMAPS}}){
		if( ! -f  $typemap ){
			warn "Typemap $typemap not found.\n";
		}
		else{
			push(@tmdeps, $self->fixpath($typemap));
		}
	}
    }
    push(@tmdeps, "typemap") if -f "typemap";
    my(@tmargs) = map("-typemap $_", @tmdeps);
    if( exists $self->{XSOPT} ){
	unshift( @tmargs, $self->{XSOPT} );
    }

    my $xsubpp_version = $self->xsubpp_version($self->catfile($xsdir,'xsubpp'));

    # What are the correct thresholds for version 1 && 2 Paul?
    if ( $xsubpp_version > 1.923 ){
	$self->{XSPROTOARG} = '' unless defined $self->{XSPROTOARG};
    } else {
	if (defined $self->{XSPROTOARG} && $self->{XSPROTOARG} =~ /\-prototypes/) {
	    print STDOUT qq{Warning: This extension wants to pass the switch "-prototypes" to xsubpp.
	Your version of xsubpp is $xsubpp_version and cannot handle this.
	Please upgrade to a more recent version of xsubpp.
};
	} else {
	    $self->{XSPROTOARG} = "";
	}
    }

    "
XSUBPPDIR = ".$self->fixpath($xsdir,1)."
XSUBPP = \$(PERL) \"-I\$(PERL_ARCHLIB)\" \"-I\$(PERL_LIB)\" \$(XSUBPPDIR)xsubpp
XSPROTOARG = $self->{XSPROTOARG}
XSUBPPDEPS = @tmdeps
XSUBPPARGS = @tmargs
";
}


sub xsubpp_version
{
    my($self,$xsubpp) = @_;
    my ($version) ;

    # try to figure out the version number of the xsubpp on the system

    # first try the -v flag, introduced in 1.921 & 2.000a2

    my $command = "$self->{PERL} $xsubpp -v";
    print "Running: $command\n" if $Verbose;
    $version = `$command` ;
    warn "Running '$command' exits with status " . $? unless ($? & 1);
    chop $version ;

    return $1 if $version =~ /^xsubpp version (.*)/ ;

    # nope, then try something else

    my $counter = '000';
    my ($file) = 'temp' ;
    $counter++ while -e "$file$counter"; # don't overwrite anything
    $file .= $counter;

    local(*F);
    open(F, ">$file") or die "Cannot open file '$file': $!\n" ;
    print F <<EOM ;
MODULE = fred PACKAGE = fred

int
fred(a)
	int	a;
EOM

    close F ;

    $command = "$self->{PERL} $xsubpp $file";
    print "Running: $command\n" if $Verbose;
    my $text = `$command` ;
    warn "Running '$command' exits with status " . $? unless ($? & 1);
    unlink $file ;

    # gets 1.2 -> 1.92 and 2.000a1
    return $1 if $text =~ /automatically by xsubpp version ([\S]+)\s*/  ;

    # it is either 1.0 or 1.1
    return 1.1 if $text =~ /^Warning: ignored semicolon/ ;

    # none of the above, so 1.0
    return "1.0" ;
}


sub tools_other {
    my($self) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    qq!
# Assumes \$(MMS) invokes MMS or MMK
# (It is assumed in some cases later that the default makefile name
# (Descrip.MMS for MM[SK]) is used.)
USEMAKEFILE = /Descrip=
USEMACROS = /Macro=(
MACROEND = )
MAKEFILE = Descrip.MMS
SHELL = Posix
TOUCH = $self->{TOUCH}
CHMOD = $self->{CHMOD}
CP = $self->{CP}
MV = $self->{MV}
RM_F  = $self->{RM_F}
RM_RF = $self->{RM_RF}
UMASK_NULL = $self->{UMASK_NULL}
MKPATH = Create/Directory
EQUALIZE_TIMESTAMP = \$(PERL) -we "open F,"">\$ARGV[1]"";close F;utime((stat(""\$ARGV[0]""))[8,9],\$ARGV[1])"
!;
}


sub dist {
    my($self, %attribs) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    # VERSION should be sanitised before use as a file name
    my($name)         = $attribs{NAME}          || '$(DISTVNAME)';
    my($zip)          = $attribs{ZIP}           || 'zip';
    my($zipflags)     = $attribs{ZIPFLAGS}      || '-Vu';
    my($suffix)       = $attribs{SUFFIX}        || '';
    my($shar)         = $attribs{SHAR}          || 'vms_share';
    my($preop)        = $attribs{PREOP}         || '!'; # e.g., update MANIFEST
    my($postop)       = $attribs{POSTOP}        || '!';
    my($dist_cp)  = $attribs{DIST_CP}  || 'best';
    my($dist_default) = $attribs{DIST_DEFAULT}  || 'zipdist';

    my($src) = $name;
    $src = "[.$src]" unless $src =~ /\[/;
    $src =~ s#\]#...]#;
    $src .= '*.*' if $src =~ /\]$/;
    $suffix =~ s#\.#_#g;
"
DISTVNAME = \$(DISTNAME)-\$(VERSION_SYM)
SRC = $src
ZIP = $zip
ZIPFLAGS = $zipflags
SUFFIX = $suffix
SHARE = $shar
PREOP = $preop
POSTOP = $postop
DIST_CP = $dist_cp
DIST_DEFAULT = $dist_default
";
}


# --- Translation Sections ---

sub c_o {
    my($self) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    return '' unless $self->needs_linking();
    '
.c$(OBJ_EXT) :
	$(CCCMD) $(CCCDLFLAGS) $(MMS$TARGET_NAME).c
';
}

sub xs_c {
    my($self) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    return '' unless $self->needs_linking();
    '
.xs.c :
	$(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $(MMS$TARGET_NAME).xs >$(MMS$TARGET)
';
}

sub xs_o {	# many makes are too dumb to use xs_c then c_o
    my($self) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    return '' unless $self->needs_linking();
    '
.xs$(OBJ_EXT) :
	$(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $(MMS$TARGET_NAME).xs >$(MMS$TARGET_NAME).c
	$(CCCMD) $(CCCDLFLAGS) $(MMS$TARGET_NAME).c
';
}


# --- Target Sections ---


sub top_targets {
    my($self) = shift;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my(@m);
    push @m, '
all ::	config $(INST_PM) subdirs linkext manifypods reorg_packlist
	$(NOOP)

subdirs :: $(MYEXTLIB)
	$(NOOP)

config :: $(MAKEFILE) $(INST_LIBDIR).exists
	$(NOOP)

config :: $(INST_ARCHAUTODIR).exists Version_check
	$(NOOP)

config :: $(INST_AUTODIR).exists
	$(NOOP)
';


    push @m, $self->dir_target(qw[$(INST_AUTODIR) $(INST_LIBDIR) $(INST_ARCHAUTODIR)]);
    if (%{$self->{MAN1PODS}}) {
	push @m, q[
config :: $(INST_MAN1DIR).exists
	$(NOOP)
];
	push @m, $self->dir_target(qw[$(INST_MAN1DIR)]);
    }
    if (%{$self->{MAN3PODS}}) {
	push @m, q[
config :: $(INST_MAN3DIR).exists
	$(NOOP)
];
	push @m, $self->dir_target(qw[$(INST_MAN3DIR)]);
    }

    push @m, '
$(O_FILES) : $(H_FILES)
' if @{$self->{O_FILES} || []} && @{$self->{H} || []};

    push @m, q{
help :
	perldoc ExtUtils::MakeMaker
};

    push @m, q{
Version_check :
	},$self->{NOECHO},q{$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -
	-e "use ExtUtils::MakeMaker qw($Version &Version_check);" -
	-e "&Version_check('$(MM_VERSION)')"
};

    join('',@m);
}


sub dlsyms {
    my($self,%attribs) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }

    return '' unless $self->needs_linking();

    my($funcs) = $attribs{DL_FUNCS} || $self->{DL_FUNCS} || {};
    my($vars)  = $attribs{DL_VARS}  || $self->{DL_VARS}  || [];
    my($srcdir)= $attribs{PERL_SRC} || $self->{PERL_SRC} || '';
    my(@m);

    unless ($self->{SKIPHASH}{'dynamic'}) {
	push(@m,'
dynamic :: rtls.opt $(INST_ARCHAUTODIR)$(BASEEXT).opt
	$(NOOP)
');
	if ($srcdir) {
	   my($opt) = $self->catfile($srcdir,'perlshr.opt');
	   push(@m,"# Depend on $(BASEEXT).opt to insure we copy here *after* autogenerating (wrong) rtls.opt in Mksymlists
rtls.opt : $opt \$(BASEEXT).opt
	Copy/Log $opt Sys\$Disk:[]rtls.opt
");
	}
	else {
	    push(@m,'
# rtls.opt is built in the same step as $(BASEEXT).opt
rtls.opt : $(BASEEXT).opt
	$(TOUCH) $(MMS$TARGET)
');
	}
    }

    push(@m,'
static :: $(INST_ARCHAUTODIR)$(BASEEXT).opt
	$(NOOP)
') unless $self->{SKIPHASH}{'static'};

    push(@m,'
$(INST_ARCHAUTODIR)$(BASEEXT).opt : $(BASEEXT).opt
	$(CP) $(MMS$SOURCE) $(MMS$TARGET)
	',$self->{NOECHO},'$(PERL) -e "open F,\'>>$(INST_ARCHAUTODIR).packlist\';print F qq[$(MMS$TARGET)\n];close F;"

$(BASEEXT).opt : Makefile.PL
	$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -e "use ExtUtils::Mksymlists;" -
	',qq[-e "Mksymlists('NAME' => '$self->{NAME}', 'DL_FUNCS' => ],
	neatvalue($funcs),q[, 'DL_VARS' => ],neatvalue($vars),')"
	$(PERL) -e "print ""$(INST_STATIC)/Include=$(BASEEXT)\n$(INST_STATIC)/Library\n"";" >>$(MMS$TARGET)
');

    join('',@m);
}


# --- Dynamic Loading Sections ---

sub dynamic_lib {
    my($self, %attribs) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    return '' unless $self->needs_linking(); #might be because of a subdir

    return '' unless $self->has_link_code();

    my($otherldflags) = $attribs{OTHERLDFLAGS} || "";
    my($inst_dynamic_dep) = $attribs{INST_DYNAMIC_DEP} || "";
    my(@m);
    push @m,"

OTHERLDFLAGS = $otherldflags
INST_DYNAMIC_DEP = $inst_dynamic_dep

";
    push @m, '
$(INST_DYNAMIC) : $(INST_STATIC) $(PERL_INC)perlshr_attr.opt rtls.opt $(INST_ARCHAUTODIR).exists $(EXPORT_LIST) $(PERL_ARCHIVE) $(INST_DYNAMIC_DEP)
	',$self->{NOECHO},'$(MKPATH) $(INST_ARCHAUTODIR)
	Link $(LDFLAGS) /Shareable=$(MMS$TARGET)$(OTHERLDFLAGS) $(BASEEXT).opt/Option,rtls.opt/Option,$(PERL_INC)perlshr_attr.opt/Option
	',$self->{NOECHO},'$(PERL) -e "open F,\'>>$(INST_ARCHAUTODIR).packlist\';print F qq[$(MMS$TARGET)\n];close F;"
';

    push @m, $self->dir_target('$(INST_ARCHAUTODIR)');
    join('',@m);
}

sub dynamic_bs {
    my($self, %attribs) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    return '
BOOTSTRAP =
' unless $self->has_link_code();
    '
BOOTSTRAP = '."$self->{BASEEXT}.bs".'

# As MakeMaker mkbootstrap might not write a file (if none is required)
# we use touch to prevent make continually trying to remake it.
# The DynaLoader only reads a non-empty file.
$(BOOTSTRAP) : $(MAKEFILE) '."$self->{BOOTDEP}".' $(INST_ARCHAUTODIR).exists
	'.$self->{NOECHO}.'Write Sys$Output "Running mkbootstrap for $(NAME) ($(BSLOADLIBS))"
	'.$self->{NOECHO}.'$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -
	-e "use ExtUtils::Mkbootstrap; Mkbootstrap(\'$(BASEEXT)\',\'$(BSLOADLIBS)\');"
	'.$self->{NOECHO}.' $(TOUCH) $(MMS$TARGET)
	'.$self->{NOECHO}.'$(PERL) -e "open F,\'>>$(INST_ARCHAUTODIR).packlist\';print F qq[$(MMS$TARGET)\n];close F;"

$(INST_BOOT) : $(BOOTSTRAP) $(INST_ARCHAUTODIR).exists
	'.$self->{NOECHO}.'$(RM_RF) $(INST_BOOT)
	- $(CP) $(BOOTSTRAP) $(INST_BOOT)
	'.$self->{NOECHO}.'$(PERL) -e "open F,\'>>$(INST_ARCHAUTODIR).packlist\';print F qq[$(MMS$TARGET)\n];close F;"
';
}
# --- Static Loading Sections ---

sub static_lib {
    my($self) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    return '' unless $self->needs_linking();

    return '
$(INST_STATIC) :
	$(NOOP)
' unless ($self->{OBJECT} or @{$self->{C} || []} or $self->{MYEXTLIB});

    my(@m);
    push @m,'
# Rely on suffix rule for update action
$(OBJECT) : $(INST_ARCHAUTODIR).exists

$(INST_STATIC) : $(OBJECT) $(MYEXTLIB)
';
    # If this extension has it's own library (eg SDBM_File)
    # then copy that to $(INST_STATIC) and add $(OBJECT) into it.
    push(@m, '	$(CP) $(MYEXTLIB) $(MMS$TARGET)',"\n") if $self->{MYEXTLIB};

    push(@m,'
	If F$Search("$(MMS$TARGET)").eqs."" Then Library/Object/Create $(MMS$TARGET)
	Library/Object/Replace $(MMS$TARGET) $(MMS$SOURCE_LIST)
	',$self->{NOECHO},'$(PERL) -e "open F,\'>>$(INST_ARCHAUTODIR)extralibs.ld\';print F qq[$(EXTRALIBS)\n];close F;"
	',$self->{NOECHO},'$(PERL) -e "open F,\'>>$(INST_ARCHAUTODIR).packlist\';print F qq[$(MMS$TARGET)\n];close F;"
');
    push @m, $self->dir_target('$(INST_ARCHAUTODIR)');
    join('',@m);
}


sub installpm_x { # called by installpm perl file
    my($self, $dist, $inst, $splitlib) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    if ($inst =~ m!#!) {
	warn "Warning: MM[SK] would have problems processing this file: $inst, SKIPPED\n";
	return '';
    }
    $inst = $self->fixpath($inst);
    $dist = $self->fixpath($dist);
    my($instdir) = $inst =~ /([^\)]+\))[^\)]*$/ ? $1 : dirname($inst);
    my(@m);

    push(@m, "
$inst : $dist \$(MAKEFILE) ${instdir}.exists \$(INST_ARCHAUTODIR).exists
",'	',$self->{NOECHO},'$(RM_F) $(MMS$TARGET)
	',$self->{NOECHO},'$(CP) ',"$dist $inst",'
	$(CHMOD) 644 $(MMS$TARGET)
	',$self->{NOECHO},'$(PERL) -e "open F,\'>>$(INST_ARCHAUTODIR).packlist\';print F qq[$(MMS$TARGET)\n];close F;"
');
    push(@m, '	$(AUTOSPLITFILE) $(MMS$TARGET) ',
              $self->catdir($splitlib,'auto')."\n\n")
        if ($splitlib and $inst =~ /\.pm$/);
    push(@m,$self->dir_target($instdir));

    join('',@m);
}


sub manifypods {
    my($self, %attribs) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    return "\nmanifypods :\n\t\$(NOOP)\n" unless %{$self->{MAN3PODS}};
    my($dist);
    my($pod2man_exe,$found_pod2man);
    if (defined $self->{PERL_SRC}) {
	$pod2man_exe = $self->catfile($self->{PERL_SRC},'pod','pod2man');
    } else {
	$pod2man_exe = $self->catfile($Config{bin},'pod2man');
    }
    if ($pod2man_exe = $self->perl_script($pod2man_exe)) { $found_pod2man = 1; }
    else {
	# No pod2man but some MAN3PODS to be installed
	print <<END;

Warning: I could not locate your pod2man program.  As a last choice,
         I will look for the file to which the logical name POD2MAN
         points when MMK is invoked.

END
        $pod2man_exe = "pod2man";
    }
    my(@m);
    push @m,
qq[POD2MAN_EXE = $pod2man_exe\n],
q[POD2MAN = $(PERL) -we "%m=@ARGV;for (keys %m){" -
-e "system(""MCR $^X $(POD2MAN_EXE) $_ >$m{$_}"");}"
];
    push @m, "\nmanifypods : ";
    push @m, join " ", keys %{$self->{MAN1PODS}}, keys %{$self->{MAN3PODS}};
    push(@m,"\n");
    if (%{$self->{MAN1PODS}} || %{$self->{MAN3PODS}}) {
	my($pod);
	foreach $pod (sort keys %{$self->{MAN1PODS}}) {
	    push @m, qq[\t\@- If F\$Search("\$(POD2MAN_EXE)").nes."" Then \$(POD2MAN) ];
	    push @m, "$pod $self->{MAN1PODS}{$pod}\n";
	}
	foreach $pod (sort keys %{$self->{MAN3PODS}}) {
	    push @m, qq[\t\@- If F\$Search("\$(POD2MAN_EXE)").nes."" Then \$(POD2MAN) ];
	    push @m, "$pod $self->{MAN3PODS}{$pod}\n";
	}
    }
    join('', @m);
}


sub processPL {
    my($self) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    return "" unless $self->{PL_FILES};
    my(@m, $plfile);
    foreach $plfile (sort keys %{$self->{PL_FILES}}) {
	push @m, "
all :: $self->{PL_FILES}->{$plfile}
	\$(NOOP)

$self->{PL_FILES}->{$plfile} :: $plfile
",'	$(PERL) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)" "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" '," $plfile
";
    }
    join "", @m;
}


sub installbin {
    my($self) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    return '' unless $self->{EXE_FILES} && ref $self->{EXE_FILES} eq "ARRAY";
    return '' unless @{$self->{EXE_FILES}};
    my(@m, $from, $to, %fromto, @to, $line);
    for $from (@{$self->{EXE_FILES}}) {
	my($path) = '$(INST_EXE)' . basename($from);
	local($_) = $path;  # backward compatibility
	$to = $self->exescan($path);
	print "exescan($from) => '$to'\n" if ($Verbose >=2);
	$fromto{$from}=$to;
    }
    @to   = values %fromto;
    push @m, "
EXE_FILES = @{$self->{EXE_FILES}}

all :: @to
	\$(NOOP)

realclean ::
";
    $line = '';  #avoid unitialized var warning
    foreach $to (@to) {
	if (length($line) + length($to) > 80) {
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
	$todir = $self->fixpath($todir,1);
	push @m, "
$to : $from \$(MAKEFILE) ${todir}.exists
	\$(CP) $from $to

", $self->dir_target($todir);
    }
    join "", @m;
}


# --- Sub-directory Sections ---

sub pasthru {
    my($self) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my(@m,$key);
    my(@pasthru);

    foreach $key (qw(INSTALLPRIVLIB INSTALLARCHLIB INSTALLBIN 
                     INSTALLMAN1DIR INSTALLMAN3DIR LIBPERL_A
                     LINKTYPE PREFIX)){
	push @pasthru, "$key=\"$self->{$key}\"";
    }

    push @m, "\nPASTHRU = \\\n ", join (",\\\n ", @pasthru), "\n";
    join "", @m;
}


sub subdir_x {
    my($self, $subdir) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my(@m,$key);
    $subdir = $self->fixpath($subdir,1);
    push @m, '

subdirs ::
	olddef = F$Environment("Default")
	Set Default ',$subdir,'
	- $(MMS) all $(USEMACROS)$(PASTHRU)$(MACROEND)
	Set Default \'olddef\'
';
    join('',@m);
}


# --- Cleanup and Distribution Sections ---

sub clean {
    my($self, %attribs) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my(@m,$dir);
    push @m, '
# Delete temporary files but do not touch installed files. We don\'t delete
# the Descrip.MMS here so that a later make realclean still has it to use.
clean ::
';
    foreach $dir (@{$self->{DIR}}) { # clean subdirectories first
	my($vmsdir) = $self->fixpath($dir,1);
	push( @m, '	If F$Search("'.$vmsdir.'$(MAKEFILE)") Then \\',"\n\t",
	      '$(PERL) -e "chdir ',"'$vmsdir'",'; print `$(MMS) clean`;"',"\n");
    }
    push @m, '	$(RM_F) *.Map *.lis *.cpp *$(OBJ_EXT) *$(LIB_EXT) *.Opt $(BOOTSTRAP) $(BASEEXT).bso
';

    my(@otherfiles) = values %{$self->{XS}}; # .c files from *.xs files
    push(@otherfiles, $attribs{FILES}) if $attribs{FILES};
    push(@otherfiles, 'blib.dir', '$(MAKE_APERL_FILE)', 'extralibs.ld', 'perlmain.c');
    push(@otherfiles,$self->catfile('$(INST_ARCHAUTODIR)','extralibs.all'));
    my($file,$line);
    $line = '';  #avoid unitialized var warning
    foreach $file (@otherfiles) {
	$file = $self->fixpath($file);
	if (length($line) + length($file) > 80) {
	    push @m, "\t\$(RM_RF) $line\n";
	    $line = "$file";
	}
	else { $line .= " $file"; }
    }
    push @m, "\t\$(RM_RF) $line\n\n";
    push(@m, "	$attribs{POSTOP}\n") if $attribs{POSTOP};
    join('', @m);
}


sub realclean {
    my($self, %attribs) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my(@m);
    push(@m,'
# Delete temporary files (via clean) and also delete installed files
realclean :: clean
');
    foreach(@{$self->{DIR}}){
	my($vmsdir) = $self->fixpath($_,1);
	push(@m, '	If F$Search("'."$vmsdir".'$(MAKEFILE)").nes."" Then \\',"\n\t",
	      '$(PERL) -e "chdir ',"'$vmsdir'",'; print `$(MMS) realclean`;"',"\n");
    }
    push @m,'	$(RM_RF) $(INST_AUTODIR) $(INST_ARCHAUTODIR)
';
    # We can't expand several of the MMS macros here, since they don't have
    # corresponding %$self keys (i.e. they're defined in Descrip.MMS as a
    # combination of macros).  In order to stay below DCL's 255 char limit,
    # we put only 2 on a line.
    my($file,$line,$fcnt);
    my(@files) = qw{ *.Opt $(INST_DYNAMIC) $(INST_STATIC) $(INST_BOOT) $(INST_PM) $(OBJECT) $(MAKEFILE) $(MAKEFILE)_old };
    $line = '';  #avoid unitialized var warning
    foreach $file (@files) {
	$file = $self->fixpath($file);
	if (length($line) + length($file) > 80 || ++$fcnt >= 2) {
	    push @m, "\t\$(RM_F) $line\n";
	    $line = "$file";
	    $fcnt = 0;
	}
	else { $line .= " $file"; }
    }
    push @m, "\t\$(RM_F) $line\n";
    if ($attribs{FILES} && ref $attribs{FILES} eq 'ARRAY') {
	$line = '';
	foreach $file (@{$attribs{'FILES'}}) {
	    $file = $self->fixpath($file);
	    if (length($line) + length($file) > 80) {
		push @m, "\t\$(RM_RF) $line\n";
		$line = "$file";
	    }
	    else { $line .= " $file"; }
	}
	push @m, "\t\$(RM_RF) $line\n";
    }
    push(@m, "	$attribs{POSTOP}\n")                     if $attribs{POSTOP};
    join('', @m);
}


sub dist_basics {
    my($self) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
'
distclean :: realclean distcheck
	$(NOOP)

distcheck :
	$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -e "use ExtUtils::Manifest \'&fullcheck\'; fullcheck()"

skipcheck :
	$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -e "use ExtUtils::Manifest \'&fullcheck\'; skipcheck()"

manifest :
	$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -e "use ExtUtils::Manifest \'&mkmanifest\'; mkmanifest()"
';
}


sub dist_core {
    my($self) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
'
dist : $(DIST_DEFAULT)
	$(NOOP)

zipdist : $(DISTVNAME).zip$(SUFFIX)
	$(NOOP)

$(DISTVNAME).zip$(SUFFIX) : distdir
	$(PREOP)
	$(ZIP) "$(ZIPFLAGS)" $(MMS$TARGET) $(SRC)
	$(RM_RF) $(DISTVNAME)
	$(POSTOP)

shdist : distdir
	$(PREOP)
	$(SHARE) $(SRC) $(DISTVNAME).share$(SUFFIX)
	$(RM_RF) $(DISTVNAME)
	$(POSTOP)
';
}


sub dist_dir {
    my($self) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
q{
distdir :
	$(RM_RF) $(DISTVNAME)
	$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -e "use ExtUtils::Manifest '/mani/';" \\
	-e "manicopy(maniread(),'$(DISTVNAME)','$(DIST_CP)');"
};
}


sub dist_test {
    my($self) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
q{
disttest : distdir
	startdir = F$Environment("Default")
	Set Default [.$(DISTVNAME)]
	$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" Makefile.PL
	$(MMS)
	$(MMS) test
	Set Default 'startdir'
};
}

sub dist_ci {
    my($self) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
'';
}


# --- Test and Installation Sections ---



sub install {
    my($self, %attribs) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my(@m);
    push @m, q[
doc_install ::
	],$self->{NOECHO},q[Write Sys$Output "Appending installation info to $(INST_ARCHLIB)perllocal.pod"
	],$self->{NOECHO},q[$(PERL) -e "print q{use ExtUtils::MakeMaker; }" >.MM_tmp
	],$self->{NOECHO},q[$(PERL) -e "print q{MY->new({})->writedoc(}" >>.MM_tmp
	],$self->{NOECHO},q[$(PERL) -e "print q{'Module','$(NAME)','LINKTYPE=$(LINKTYPE)',}" >>.MM_tmp
	],$self->{NOECHO},q[$(PERL) -e "print q{'VERSION=$(VERSION)','XS_VERSION=$(XS_VERSION)',}" >>.MM_tmp
	],$self->{NOECHO},q[$(PERL) -e "print q{'EXE_FILES=$(EXE_FILES)')}" >>.MM_tmp
	],$self->{NOECHO},q[$(PERL) "-I$(PERL_LIB)" "-I$(PERL_ARCHLIB)"  .MM_tmp >>$(INSTALLARCHLIB)perllocal.pod
	],$self->{NOECHO},q[If F$Search(".MM_tmp") .nes. "" then Delete/NoLog .MM_tmp;
];

    push(@m, "
install :: pure_install doc_install
	\$(NOOP)

# Interim solution for VMS; assumes directory tree of same structure under
# both \$(INST_LIB) and \$(INSTALLPRIVLIB).  This operation will be assumed
# into MakeMaker in a (near) future version.
pure_install :: all
");
#    # install subdirectories first
#    foreach(@{$self->{DIR}}){
#      my($vmsdir) = $self->fixpath($_,1);
#      push(@m, '	If F$Search("',$vmsdir,'$(MAKEFILE)").nes."" Then $(PERL) -e "chdir ',"'$vmsdir'",
#           '; print `$(MMS) install`"'."\n");
#    }
#
#    push(@m, '	',$self->{NOECHO},'$(PERL) "-I$(PERL_LIB)" -e "use File::Path; mkpath(\@ARGV)" $(INSTALLPRIVLIB) $(INSTALLARCHLIB)
#	',$self->{NOECHO},'$(PERL) -e "die qq{You do not have permissions to install into $ARGV[0]\n} unless -w VMS::Filespec::fileify($ARGV[0])" $(INSTALLPRIVLIB)
#	',$self->{NOECHO},'$(PERL) -e "die qq{You do not have permissions to install into $ARGV[0]\n} unless -w VMS::Filespec::fileify($ARGV[0])" $(INSTALLARCHLIB)',"
#	# Can't install manpages here -- INST_MAN%DIR macros make line >255 chars
#	\$(MMS) \$(USEMACROS)INST_LIB=$self->{INSTALLPRIVLIB},INST_ARCHLIB=$self->{INSTALLARCHLIB},INST_EXE=$self->{INSTALLBIN}\$(MACROEND)",'
#	',$self->{NOECHO},'$(PERL) -i_bak -lne "print unless $seen{$_}++" $(INST_ARCHAUTODIR).packlist
#');

    my($curtop,$insttop);
    ($curtop = $self->fixpath($self->{INST_LIB},1)) =~ s/]$//;
    ($insttop = $self->fixpath($self->{INSTALLPRIVLIB},1)) =~ s/]$//;
    push(@m,"	Backup/Log ${curtop}...]*.*; ${insttop}...]/New_Version/By_Owner=Parent\n");

    my($oldpacklist) = $self->catfile('$(PERL_ARCHLIB)','auto','$(FULLEXT)','.packlist');
    push @m,'
# This song and dance brought to you by DCL\'s 255 char limit
reorg_packlist :
';
    my($oldpacklist) = $self->catfile('$(PERL_ARCHLIB)','auto','$(FULLEXT)','.packlist');
    if ("\L$oldpacklist" ne "\L$self->{INST_ARCHAUTODIR}.packlist") {
	push(@m,'	If F$Search("',$oldpacklist,'").nes."" Then Append/New ',$oldpacklist,' $(INST_ARCHAUTODIR).packlist');
    }
    push @m,'
	$(PERL) -ne "BEGIN{exit unless -e $ARGV[0];}print unless $s{$_}++;"  $(INST_ARCHAUTODIR).packlist >.MM_tmp
	If F$Search(".MM_tmp").nes."" Then Copy/NoConfirm .MM_tmp $(INST_ARCHAUTODIR).packlist
	If F$Search(".MM_tmp").nes."" Then Delete/NoConfirm .MM_tmp;
';

# From MM 5.16:

    push @m, q[
# Comment on .packlist rewrite above:
# Read both .packlist files: the old one in PERL_ARCHLIB/auto/FULLEXT, and the new one
# in INSTARCHAUTODIR. Don't croak if they are missing. Write to the one
# in INSTARCHAUTODIR. 
];

    push @m, '
##### UNINSTALL IS STILL EXPERIMENTAL ####
uninstall ::
';
    foreach(@{$self->{DIR}}){
      my($vmsdir) = $self->fixpath($_,1);
      push(@m, '	If F$Search("',$vmsdir,'$(MAKEFILE)").nes."" Then $(PERL) -e "chdir ',"'$vmsdir'",
           '; print `$(MMS) uninstall`"'."\n");
    }
    push @m, "\t".'$(PERL) -le "use File::Path; foreach (<>) {s/',"$curtop/$insttop/;",'rmtree($_,1,0);}" <$(INST_ARCHAUTODIR).packlist
';

    join("",@m);
}


sub perldepend {
    my($self) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my(@m);

    push @m, '
$(OBJECT) : $(PERL_INC)EXTERN.h, $(PERL_INC)INTERN.h, $(PERL_INC)XSUB.h, $(PERL_INC)av.h
$(OBJECT) : $(PERL_INC)cop.h, $(PERL_INC)cv.h, $(PERL_INC)embed.h, $(PERL_INC)form.h
$(OBJECT) : $(PERL_INC)gv.h, $(PERL_INC)handy.h, $(PERL_INC)hv.h, $(PERL_INC)keywords.h
$(OBJECT) : $(PERL_INC)mg.h, $(PERL_INC)op.h, $(PERL_INC)opcode.h, $(PERL_INC)patchlevel.h
$(OBJECT) : $(PERL_INC)perl.h, $(PERL_INC)perly.h, $(PERL_INC)pp.h, $(PERL_INC)proto.h
$(OBJECT) : $(PERL_INC)regcomp.h, $(PERL_INC)regexp.h, $(PERL_INC)scope.h, $(PERL_INC)sv.h
$(OBJECT) : $(PERL_INC)vmsish.h, $(PERL_INC)util.h, $(PERL_INC)config.h

' if $self->{OBJECT}; 

    push(@m,'
# Check for unpropagated config.sh changes. Should never happen.
# We do NOT just update config.h because that is not sufficient.
# An out of date config.h is not fatal but complains loudly!
#$(PERL_INC)config.h : $(PERL_SRC)config.sh
$(PERL_INC)config.h : $(PERL_VMS)config.vms
	',$self->{NOECHO},'Write Sys$Error "Warning: $(PERL_INC)config.h out of date with $(PERL_VMS)config.vms"

#$(PERL_ARCHLIB)Config.pm : $(PERL_SRC)config.sh
$(PERL_ARCHLIB)Config.pm : $(PERL_VMS)config.vms $(PERL_VMS)genconfig.pl
	',$self->{NOECHO},'Write Sys$Error "$(PERL_ARCHLIB)Config.pm may be out of date with config.vms or genconfig.pl"
	olddef = F$Environment("Default")
	Set Default $(PERL_SRC)
	$(MMS) $(USEMAKEFILE)[.VMS]$(MAKEFILE) [.lib.',$Config{'arch'},']config.pm
	Set Default \'olddef\'
') if $self->{PERL_SRC};

    push(@m, join(" ", map($self->fixpath($_),values %{$self->{XS}}))." : \$(XSUBPPDEPS)\n")
      if %{$self->{XS}};

    join('',@m);
}

sub makefile {
    my($self) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my(@m,@cmd);
    # We do not know what target was originally specified so we
    # must force a manual rerun to be sure. But as it should only
    # happen very rarely it is not a significant problem.
    push @m, '
$(OBJECT) : $(FIRST_MAKEFILE)
' if $self->{OBJECT};

    push @m,'
# We take a very conservative approach here, but it\'s worth it.
# We move $(MAKEFILE) to $(MAKEFILE)_old here to avoid gnu make looping.
$(MAKEFILE) : Makefile.PL $(CONFIGDEP)
	',$self->{NOECHO},'Write Sys$Output "$(MAKEFILE) out-of-date with respect to $(MMS$SOURCE_LIST)"
	',$self->{NOECHO},'Write Sys$Output "Cleaning current config before rebuilding $(MAKEFILE) ..."
	- $(MV) $(MAKEFILE) $(MAKEFILE)_old
	- $(MMS) $(USEMAKEFILE)$(MAKEFILE)_old clean
	$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" Makefile.PL ',join(' ',@ARGV),'
	',$self->{NOECHO},'Write Sys$Output "$(MAKEFILE) has been rebuilt."
	',$self->{NOECHO},'Write Sys$Output "Please run $(MMS) to build the extension."
';

    join('',@m);
}


sub test {
    my($self, %attribs) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my($tests) = $attribs{TESTS} || ( -d 't' ? 't/*.t' : '');
    my(@m);
    push @m,"
TEST_VERBOSE = 0
TEST_TYPE=test_\$(LINKTYPE)

test : \$(TEST_TYPE)
	\$(NOOP)
";
    foreach(@{$self->{DIR}}){
      my($vmsdir) = $self->fixpath($_,1);
      push(@m, '	If F$Search("',$vmsdir,'$(MAKEFILE)").nes."" Then $(PERL) -e "chdir ',"'$vmsdir'",
           '; print `$(MMS) $(PASTHRU2) test`'."\n");
    }
    push(@m, "\t$self->{NOECHO}Write Sys\$Output \"No tests defined for \$(NAME) extension.\"\n")
        unless $tests or -f "test.pl" or @{$self->{DIR}};
    push(@m, "\n");

    push(@m, "test_dynamic :: all\n");
    push(@m, $self->test_via_harness('$(FULLPERL)', $tests)) if $tests;
    push(@m, $self->test_via_script('$(FULLPERL)', 'test.pl')) if -f "test.pl";
    push(@m, "    \$(NOOP)\n") if (!$tests && ! -f "test.pl");
    push(@m, "\n");

    # Occasionally we may face this degenerate target:
    push @m, "test_ : test_dynamic\n\n";
 
	if ($self->needs_linking()) {
	push(@m, "test_static :: all \$(MAP_TARGET)\n");
	push(@m, $self->test_via_harness('$(MAP_TARGET)', $tests)) if $tests;
	push(@m, $self->test_via_script('$(MAP_TARGET)', 'test.pl')) if -f "test.pl";
	push(@m, "\t$self->{NOECHO}\$(NOOP)\n") if (!$tests && ! -f "test.pl");
	push(@m, "\n");
    }
    else {
	push @m, "test_static :: test_dynamic\n\t$self->{NOECHO}\$(NOOP)\n";
    }

    join('',@m);
}


sub test_via_harness {
    my($self,$perl,$tests) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    "	$perl".' "-I$(INST_ARCHLIB)" "-I$(INST_LIB)" "-I$(PERL_LIB)" "-I$(PERL_ARCHLIB)" \\'."\n\t".
    '-e "use Test::Harness qw(&runtests $verbose); $verbose=$(TEST_VERBOSE); runtests @ARGV;" \\'."\n\t$tests\n";
}


sub test_via_script {
    my($self,$perl,$script) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    "	$perl".' "-I$(INST_ARCHLIB)" "-I$(INST_LIB)" "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" test.pl
';
}


sub makeaperl {
    my($self, %attribs) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my($makefilename, $searchdirs, $static, $extra, $perlinc, $target, $tmp, $libperl) = 
      @attribs{qw(MAKE DIRS STAT EXTRA INCL TARGET TMP LIBPERL)};
    my(@m);
    push @m, "
# --- MakeMaker makeaperl section ---
MAP_TARGET    = $target
";
    return join '', @m if $self->{PARENT};

    my($dir) = join ":", @{$self->{DIR}};

    unless ($self->{MAKEAPERL}) {
	push @m, q{
$(MAKE_APERL_FILE) : $(FIRST_MAKEFILE)
	},$self->{NOECHO},q{Write Sys$Output "Writing ""$(MMS$TARGET)"" for this $(MAP_TARGET)"
	},$self->{NOECHO},q{$(PERL) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)" "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" \
		Makefile.PL DIR=}, $dir, q{ \
		MAKEFILE=$(MAKE_APERL_FILE) LINKTYPE=static \
		MAKEAPERL=1 NORECURS=1

$(MAP_TARGET) :: $(MAKE_APERL_FILE)
	$(MMS)$(USEMAKEFILE)$(MAKE_APERL_FILE) static $(MMS$TARGET)
};
	push @m, map( " \\\n\t\t$_", @ARGV );
	push @m, "\n";

	return join '', @m;
    }


    my($linkcmd,@staticopts,@staticpkgs,$extralist,$target,$targdir,$libperldir);

    # The front matter of the linkcommand...
    $linkcmd = join ' ', $Config{'ld'},
	    grep($_, @Config{qw(large split ldflags ccdlflags)});
    $linkcmd =~ s/\s+/ /g;

    # Which *.olb files could we make use of...
    local(%olbs);
    $olbs{$self->{INST_ARCHAUTODIR}} = "$self->{BASEEXT}\$(LIB_EXT)";
    File::Find::find(sub {
	return unless m/\Q$self->{LIB_EXT}\E$/;
	return if m/^libperl/;
	$olbs{$ENV{DEFAULT}} = $_;
    }, grep( -d $_, @{$searchdirs || []}));

    # We trust that what has been handed in as argument will be buildable
    $static = [] unless $static;
    @olbs{@{$static}} = (1) x @{$static};
 
    $extra = [] unless $extra && ref $extra eq 'ARRAY';
    # Sort the object libraries in inverse order of
    # filespec length to try to insure that dependent extensions
    # will appear before their parents, so the linker will
    # search the parent library to resolve references.
    # (e.g. Intuit::DWIM will precede Intuit, so unresolved
    # references from [.intuit.dwim]dwim.obj can be found
    # in [.intuit]intuit.olb).
    for (sort keys %olbs) {
	next unless $olbs{$_} =~ /\Q$self->{LIB_EXT}\E$/;
	my($dir) = $self->fixpath($_,1);
	my($extralibs) = $dir . "extralibs.ld";
	my($extopt) = $dir . $olbs{$_};
	$extopt =~ s/$self->{LIB_EXT}$/.opt/;
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
		(my($pkg) = "$1_$1$self->{LIB_EXT}") =~ s#_*#/#g;
		push @staticpkgs,$pkg;
	    }
	    push @staticopts, $extopt;
	}
    }

    $target = "Perl.Exe" unless $target;
    ($shrtarget,$targdir) = fileparse($target);
    $shrtarget =~ s/^([^.]*)/$1Shr/;
    $shrtarget = $targdir . $shrtarget;
    $target = "Perlshr.$Config{'dlext'}" unless $target;
    $tmp = "[]" unless $tmp;
    $tmp = $self->fixpath($tmp,1);
    if (@$extra) {
	$extralist = join(' ',@$extra);
	$extralist =~ s/[,\s\n]+/, /g;
    }
    else { $extralist = ''; }
    if ($libperl) {
	unless (-f $libperl || -f ($libperl = $self->catfile($Config{'installarchlib'},'CORE',$libperl))) {
	    print STDOUT "Warning: $libperl not found\n";
	    undef $libperl;
	}
    }
    unless ($libperl) {
	if (defined $self->{PERL_SRC}) {
	    $libperl = $self->catfile($self->{PERL_SRC},"libperl$self->{LIB_EXT}");
	} elsif (-f ($libperl = $self->catfile($Config{'installarchlib'},'CORE',"libperl$self->{LIB_EXT}")) ) {
	} else {
	    print STDOUT "Warning: $libperl not found
    If you're going to build a static perl binary, make sure perl is installed
    otherwise ignore this warning\n";
	}
    }
    $libperldir = $self->fixpath((fileparse($libperl))[1],1);

    push @m, '
# Fill in the target you want to produce if it\'s not perl
MAP_TARGET    = ',$self->fixpath($target),'
MAP_SHRTARGET = ',$self->fixpath($shrtarget),"
MAP_LINKCMD   = $linkcmd
MAP_PERLINC   = ", $perlinc ? map('"$_" ',@{$perlinc}) : '','
# We use the linker options files created with each extension, rather than
#specifying the object files directly on the command line.
MAP_STATIC    = ',@staticopts ? join(' ', @staticopts) : '','
MAP_OPTS    = ',@staticopts ? ','.join(',', map($_.'/Option', @staticopts)) : '',"
MAP_EXTRA     = $extralist
MAP_LIBPERL = ",$self->fixpath($libperl),'
';


    push @m,'
$(MAP_SHRTARGET) : $(MAP_LIBPERL) $(MAP_STATIC) ',"${libperldir}Perlshr_Attr.Opt",'
	$(MAP_LINKCMD)/Shareable=$(MMS$TARGET) $(MAP_OPTS), $(MAP_EXTRA), $(MAP_LIBPERL) ',"${libperldir}Perlshr_Attr.Opt",'
$(MAP_TARGET) : $(MAP_SHRTARGET) ',"${tmp}perlmain\$(OBJ_EXT) ${tmp}PerlShr.Opt",'
	$(MAP_LINKCMD) ',"${tmp}perlmain\$(OBJ_EXT)",', PerlShr.Opt/Option
	',$self->{NOECHO},'Write Sys$Output "To install the new ""$(MAP_TARGET)"" binary, say"
	',$self->{NOECHO},'Write Sys$Output "    $(MMS)$(USEMAKEFILE)$(MAKEFILE) inst_perl $(USEMACROS)MAP_TARGET=$(MAP_TARGET)$(ENDMACRO)"
	',$self->{NOECHO},'Write Sys$Output "To remove the intermediate files, say
	',$self->{NOECHO},'Write Sys$Output "    $(MMS)$(USEMAKEFILE)$(MAKEFILE) map_clean"
';
    push @m,'
',"${tmp}perlmain.c",' : $(MAKEFILE)
	',$self->{NOECHO},'$(PERL) $(MAP_PERLINC) -e "use ExtUtils::Miniperl; writemain(qw|',@staticpkgs,'|)" >$(MMS$TARGET)
';

    push @m, q{
doc_inst_perl :
	},$self->{NOECHO},q{$(PERL) -e "use ExtUtils::MakeMaker; MY->new()->writedoc('Perl binary','$(MAP_TARGET)','MAP_STATIC=$(MAP_STATIC)','MAP_EXTRA=$(MAP_EXTRA)','MAP_LIBPERL=$(MAP_LIBPERL)')"
};

    push @m, "
inst_perl : pure_inst_perl doc_inst_perl
	\$(NOOP)

pure_inst_perl : \$(MAP_TARGET)
	$self->{CP} \$(MAP_SHRTARGET) ",$self->fixpath($Config{'installbin'},1),"
	$self->{CP} \$(MAP_TARGET) ",$self->fixpath($Config{'installbin'},1),"

clean :: map_clean
	\$(NOOP)

map_clean :
	\$(RM_F) ${tmp}perlmain\$(OBJ_EXT) ${tmp}perlmain.c \$(MAKEFILE)
	\$(RM_F) ${tmp}PerlShr.Opt \$(MAP_TARGET)
";

    join '', @m;
}
  
sub extliblist {
    my($self) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    '','','';
}


# --- Make-Directories section (internal method) ---
# dir_target(@array) returns a Makefile entry for the file .exists in each
# named directory. Returns nothing, if the entry has already been processed.
# We're helpless though, if the same directory comes as $(FOO) _and_ as "bar".
# Both of them get an entry, that's why we use "::". I chose '$(PERL)' as the 
# prerequisite, because there has to be one, something that doesn't change 
# too often :)

sub dir_target {
    my($self,@dirs) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my(@m,$dir);
    foreach $dir (@dirs) {
	next if $self->{DIR_TARGET}{$self}{$dir}++;
	my($vmsdir) = $self->fixpath($dir,1);
	push @m, "
${vmsdir}.exists :: \$(PERL_INC)perl.h
	$self->{NOECHO}\$(MKPATH) $vmsdir
	$self->{NOECHO}\$(EQUALIZE_TIMESTAMP) \$(MMS\$SOURCE) \$(MMS\$TARGET)
";
    }
    join "", @m;
}


# --- Output postprocessing section ---

sub nicetext {
    # Insure that colons marking targets are preceded by space -
    # most Unix Makes don't need this, but it's necessary under VMS
    # to distinguish the target delimiter from a colon appearing as
    # part of a filespec.

    my($self,$text) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    $text =~ s/([^\s:])(:+\s)/$1 $2/gs;
    $text;
}

1;

__END__
