package main;
use vars qw(%att);

# $Id: MakeMaker.pm,v 1.174 1996/02/06 17:03:12 k Exp $

package ExtUtils::MakeMaker::TieAtt;
# this package will go away again, when we don't have modules around
# anymore that import %att It ties an empty %att and records in which
# object this %att was tied. FETCH and STORE return/store-to the
# appropriate value from %$self

# the warndirectuse method warns if somebody calls MM->something. It
# has nothing to do with the tie'd %att.

$Enough_limit = 5;

sub TIEHASH {
    bless { SECRETHASH => $_[1]};
}

sub FETCH {
    print "Warning (non-fatal): Importing of %att is deprecated [$_[1]]
	use \$self instead\n" unless ++$Enough>$Enough_limit;
    print "Further ExtUtils::MakeMaker::TieAtt warnings suppressed\n" if $Enough==$Enough_limit;
    $_[0]->{SECRETHASH}->{$_[1]};
}

sub STORE {
    print "Warning (non-fatal): Importing of %att is deprecated [$_[1]][$_[2]]
	use \$self instead\n" unless ++$Enough>$Enough_limit;
    print "Further ExtUtils::MakeMaker::TieAtt warnings suppressed\n" if $Enough==$Enough_limit;
    $_[0]->{SECRETHASH}->{$_[1]} = $_[2];
}

sub FIRSTKEY {
    print "Warning (non-fatal): Importing of %att is deprecated [FIRSTKEY]
	use \$self instead\n" unless ++$Enough>$Enough_limit;
    print "Further ExtUtils::MakeMaker::TieAtt warnings suppressed\n" if $Enough==$Enough_limit;
    each %{$_[0]->{SECRETHASH}};
}

sub NEXTKEY {
    each %{$_[0]->{SECRETHASH}};
}

sub DESTROY {
}

sub warndirectuse {
    my($caller) = @_;
    return if $Enough>$Enough_limit;
    print STDOUT "Warning (non-fatal): Direct use of class methods deprecated; use\n";
    my($method) = $caller =~ /.*:(\w+)$/;
    print STDOUT
'		my $self = shift;
		$self->MM::', $method, "();
	instead\n";
    print "Further ExtUtils::MakeMaker::TieAtt warnings suppressed\n"
	if ++$Enough==$Enough_limit;
}






package ExtUtils::MakeMaker;

$Version = $VERSION = "5.21";
$Version_OK = "5.05";	# Makefiles older than $Version_OK will die
			# (Will be checked from MakeMaker version 4.13 onwards)
($Revision = substr(q$Revision: 1.174 $, 10)) =~ s/\s+$//;



use Config;
use Carp;
use Cwd;
require Exporter;
require ExtUtils::Manifest;
{
    # Current (5.21) FileHandle doesn't work with miniperl, so we roll our own
    # that's all copy & paste code from FileHandle.pm, version of perl5.002b3
    package FileHandle;
    use Symbol;
    sub new {
	@_ >= 1 && @_ <= 3 or croak('usage: new FileHandle [FILENAME [,MODE]]');
	my $class = shift;
	my $fh = gensym;
	if (@_) {
	    FileHandle::open($fh, @_)
		or return undef;
	}
	bless $fh, $class;
    }
    sub open {
	@_ >= 2 && @_ <= 4 or croak('usage: $fh->open(FILENAME [,MODE [,PERMS]])');
	my ($fh, $file) = @_;
	if (@_ > 2) {
	    my ($mode, $perms) = @_[2, 3];
	    if ($mode =~ /^\d+$/) {
		defined $perms or $perms = 0666;
		return sysopen($fh, $file, $mode, $perms);
	    }
	    $file = "./" . $file unless $file =~ m#^/#;
	    $file = _open_mode_string($mode) . " $file\0";
	}
	open($fh, $file);
    }
    sub close {
	@_ == 1 or croak('usage: $fh->close()');
	close($_[0]);
    }
}

use vars qw(
	    $VERSION $Version_OK $Revision
	    $Verbose %MM_Sections
	    @MM_Sections %Recognized_Att_Keys @Get_from_Config
	    %Prepend_dot_dot %Config @Parent %NORMAL_INC
	    $Setup_done
	   );
#use strict qw(refs);

eval {require DynaLoader;};	# Get mod2fname, if defined. Will fail
                                # with miniperl.

#
# Set up the inheritance before we pull in the MM_* packages, because they
# import variables and functions from here
#
@ISA = qw(Exporter);
@EXPORT = qw(&WriteMakefile &writeMakefile $Verbose &prompt);
@EXPORT_OK = qw($VERSION &Version_check &help &neatvalue &mkbootstrap &mksymlists
		$Version %att);  ## Import of %att is deprecated, please use OO features!
		# $Version in mixed case will go away!

#
# Dummy package MM inherits actual methods from OS-specific
# default packages.  We use this intermediate package so
# MY::XYZ->func() can call MM->func() and get the proper
# default routine without having to know under what OS
# it's running.
#
@MM::ISA = qw[ExtUtils::MM_Unix ExtUtils::Liblist ExtUtils::MakeMaker];

#
# Setup dummy package:
# MY exists for overriding methods to be defined within
#
{
    package MY;
    @ISA = qw(MM);
}

{
    package MM;
    # From somwhere they will want to inherit DESTROY
    sub DESTROY {}
}

#
# Now we can can pull in the friends
# Since they will require us back, we would better prepare the needed
# data _before_ we require them.
#
$Is_VMS = ($Config{osname} eq 'VMS');
$Is_OS2 = ($Config{osname} =~ m|^os/?2$|i);

require ExtUtils::MM_Unix;
if ($Is_VMS) {
    require ExtUtils::MM_VMS;
    require VMS::Filespec;
    import VMS::Filespec '&vmsify';
}
if ($Is_OS2) {
    require ExtUtils::MM_OS2;
}

%NORMAL_INC = %INC;
# package name for the classes into which the first object will be blessed
$PACKNAME = "PACK000";

 #####
#     #  #    #  #####
#        #    #  #    #
 #####   #    #  #####
      #  #    #  #    #
#     #  #    #  #    #
 #####    ####   #####


#
# MakeMaker serves currently (v 5.20) only for two purposes:
# Version_Check, and WriteMakefile. For WriteMakefile SelfLoader
# doesn't buy us anything. But for Version_Check we win with
# SelfLoader more than a second.
#
# The only subroutine we do not SelfLoad is Version_Check because it's
# called so often. Loading this minimum still requires 1.2 secs on my
# Indy :-(
#

sub Version_check {
    my($checkversion) = @_;
    die "Your Makefile was built with ExtUtils::MakeMaker v $checkversion.
Current Version is $ExtUtils::MakeMaker::VERSION. There have been considerable
changes in the meantime.
Please rerun 'perl Makefile.PL' to regenerate the Makefile.\n"
    if $checkversion < $Version_OK;
    printf STDOUT "%s %s %s %s.\n", "Makefile built with ExtUtils::MakeMaker v",
    $checkversion, "Current Version is", $VERSION
	unless $checkversion == $VERSION;
}

# We don't selfload this, because chdir sometimes has problems
sub eval_in_subdirs {
    my($self) = @_;
    my($dir);
#    print "Starting to wade through directories:\n";
#    print join "\n", @{$self->{DIR}}, "\n";
    my $pwd = cwd();

    # As strange things happened twice in the history of MakeMaker to $self->{DIR},
    # lets be careful, maybe it helps some:
#    my(@copy_of_DIR) = @{$self->{DIR}};
#    my %copy;
#    @copy{@copy_od_DIR} = (1) x @copy_of_DIR;

    # with Tk-9.02 these give me as third directory "1":
    # foreach $dir (@($self->{DIR}){
    # foreach $dir (@copy_of_DIR){

    # this gives mi as third directory a core dump:
    # while ($dir = shift @copy_of_DIR){

    # this finishes the loop immediately:
#     foreach $dir (keys %copy){
# 	  print "Next to come: $dir\n";
# 	  chdir $dir or die "Couldn't change to directory $dir: $!";
# 	  package main;
# 	  my $fh = new FileHandle;
# 	  $fh->open("Makefile.PL") or carp("Couldn't open Makefile.PL in $dir");
# 	  my $eval = join "", <$fh>;
# 	  $fh->close;
# 	  eval $eval;
# 	  warn "WARNING from evaluation of $dir/Makefile.PL: $@" if $@;
# 	  chdir $pwd or die "Couldn't change to directory $pwd: $!";
#     }


    # So this did the trick (did it?)
    foreach $dir (@{$self->{DIR}}){
#	print "Next to come: $dir\n";
	my($abs) = $self->catdir($pwd,$dir);
	$self->eval_in_x($abs);
    }

    chdir $pwd;

#    print "Proudly presenting you self->{DIR}:\n";
#    print join "\n", @{$self->{DIR}}, "\n";

}

sub eval_in_x {
    my($self,$dir) = @_;
    package main;
    chdir $dir or carp("Couldn't change to directory $dir: $!");
    my $fh = new FileHandle;
    $fh->open("Makefile.PL") or carp("Couldn't open Makefile.PL in $dir");
    my $eval = join "", <$fh>;
    $fh->close;
    eval $eval;
    warn "WARNING from evaluation of $dir/Makefile.PL: $@" if $@;
}

# use SelfLoader;
# sub ExtUtils::MakeMaker::full_setup ;
# sub ExtUtils::MakeMaker::attrib_help ;
# sub ExtUtils::MakeMaker::writeMakefile ;
# sub ExtUtils::MakeMaker::WriteMakefile ;
# sub ExtUtils::MakeMaker::new ;
# sub ExtUtils::MakeMaker::check_manifest ;
# sub ExtUtils::MakeMaker::parse_args ;
# sub ExtUtils::MakeMaker::check_hints ;
# sub ExtUtils::MakeMaker::mv_all_methods ;
# sub ExtUtils::MakeMaker::prompt ;
# sub ExtUtils::MakeMaker::help ;
# sub ExtUtils::MakeMaker::skipcheck ;
# sub ExtUtils::MakeMaker::flush ;
# sub ExtUtils::MakeMaker::mkbootstrap ;
# sub ExtUtils::MakeMaker::mksymlists ;
# sub ExtUtils::MakeMaker::neatvalue ;
# sub ExtUtils::MakeMaker::selfdocument ;

# 1;

# __DATA__

#
# We're done with inheritance setup. As we have two frequently called
# things: Check_Version() and mod_install(), we want to reduce startup
# time. Only WriteMakefile needs all the power here. 
#

sub full_setup {
    $Verbose ||= 0;
    $^W=1;
    $SIG{__WARN__} = sub {
	$_[0] =~ /^Use of uninitialized value/ && return;
	$_[0] =~ /used only once/ && return;
	$_[0] =~ /^Subroutine\s+[\w:]+\s+redefined/ && return;
	warn @_;
    };

    @MM_Sections = 
	qw(
	post_initialize const_config constants const_loadlibs
	const_cccmd tool_autosplit tool_xsubpp tools_other dist macro
	depend post_constants pasthru c_o xs_c xs_o top_targets
	linkext dlsyms dynamic dynamic_bs dynamic_lib static
	static_lib installpm manifypods processPL installbin subdirs
	clean realclean dist_basics dist_core dist_dir dist_test
	dist_ci install force perldepend makefile staticmake test
	postamble selfdocument
	  ); # loses section ordering

    @MM_Sections{@MM_Sections} = {} x @MM_Sections;

    # All sections are valid keys.
    %Recognized_Att_Keys = %MM_Sections;

    # we will use all these variables in the Makefile
    @Get_from_Config = 
	qw(
	   ar cc cccdlflags ccdlflags dlext dlsrc ld lddlflags ldflags libc
	   lib_ext obj_ext ranlib sitelibexp sitearchexp so
	  );

    my $item;
    foreach $item (split(/\n/,attrib_help())){
	next unless $item =~ m/^=item\s+(\w+)\s*$/;
	$Recognized_Att_Keys{$1} = $2;
	print "Attribute '$1' => '$2'\n" if ($Verbose >= 2);
    }
    foreach $item (@Get_from_Config) {
	$Recognized_Att_Keys{uc $item} = $Config{$item};
	print "Attribute '\U$item\E' => '$Config{$item}'\n"
	    if ($Verbose >= 2);
    }

    #
    # When we pass these through to a Makefile.PL in a subdirectory, we prepend
    # "..", so that all files to be installed end up below ./blib
    #
    %Prepend_dot_dot = 
	qw(
	   INST_LIB 1 INST_ARCHLIB 1 INST_EXE 1 MAP_TARGET 1 INST_MAN1DIR 1 INST_MAN3DIR 1
	   PERL_SRC 1 PERL 1 FULLPERL 1
	  );

}

sub attrib_help {
    return $Attrib_Help if $Attrib_Help;
    my $switch = 0;
    my $help = "";
    my $line;
    while ($line = <DATA>) {
	$switch ||= $line =~ /^=item C\s*$/;
	next unless $switch;
	last if $line =~ /^=cut/;
	$help .= $line;
    }
#    close DATA;
    $Attrib_Help = $help;
}

sub writeMakefile {
    die <<END;

The extension you are trying to build apparently is rather old and
most probably outdated. We detect that from the fact, that a
subroutine "writeMakefile" is called, and this subroutine is not
supported anymore since about October 1994.

Please contact the author or look into CPAN (details about CPAN can be
found in the FAQ and at http:/www.perl.com) for a more recent version
of the extension. If you're really desperate, you can try to change
the subroutine name from writeMakefile to WriteMakefile and rerun
'perl Makefile.PL', but you're most probably left alone, when you do
so.

The MakeMaker team

END
}

sub WriteMakefile {
    Carp::croak "WriteMakefile: Need even number of args" if @_ % 2;
    my %att = @_;
    MM->new(\%att)->flush;
}

sub new {
    my($class,$self) = @_;
    full_setup() unless $Setup_done++;

    my($key);

    print STDOUT "MakeMaker (v$VERSION)\n" if $Verbose;
    if (-f "MANIFEST" && ! -f "Makefile"){
	check_manifest();
    }

    $self = {} unless (defined $self);

    check_hints($self);

    my(%initial_att) = %$self; # record initial attributes

    if (defined $self->{CONFIGURE}) {
	if (ref $self->{CONFIGURE} eq 'CODE') {
	    $self = { %$self, %{&{$self->{CONFIGURE}}}};
	} else {
	    croak "Attribute 'CONFIGURE' to WriteMakefile() not a code reference\n";
	}
    }

    # This is for old Makefiles written pre 5.00, will go away
    if ( Carp::longmess("") =~ /runsubdirpl/s ){
	#$self->{Correct_relativ_directories}++;
	carp("WARNING: Please rerun 'perl Makefile.PL' to regenerate your Makefiles\n");
    } else {
	$self->{Correct_relativ_directories}=0;
    }

    my $class = ++$PACKNAME;
    {
#	no strict;
	print "Blessing Object into class [$class]\n" if $Verbose>=2;
	mv_all_methods("MY",$class);
	bless $self, $class;
	push @Parent, $self;
	@{"$class\:\:ISA"} = 'MM';
    }

    if (defined $Parent[-2]){
	$self->{PARENT} = $Parent[-2];
	my $key;
	for $key (keys %Prepend_dot_dot) {
	    next unless defined $self->{PARENT}{$key};
	    $self->{$key} = $self->{PARENT}{$key};
	    $self->{$key} = $self->catdir("..",$self->{$key})
		unless $self->{$key} =~ m!^/!;
	}
	$self->{PARENT}->{CHILDREN}->{$class} = $self if $self->{PARENT};
    } else {
	parse_args($self,@ARGV);
    }

    $self->{NAME} ||= $self->guess_name;

    ($self->{NAME_SYM} = $self->{NAME}) =~ s/\W+/_/g;

    $self->init_main();

    if (! $self->{PERL_SRC} ) {
	my($pthinks) = $INC{'Config.pm'};
	$pthinks = vmsify($pthinks) if $Is_VMS;
	if ($pthinks ne $self->catfile($Config{archlibexp},'Config.pm')){
	    $pthinks =~ s!/Config\.pm$!!;
	    $pthinks =~ s!.*/!!;
	    print STDOUT <<END;
Your perl and your Config.pm seem to have different ideas about the architecture
they are running on.
Perl thinks: [$pthinks]
Config says: [$Config{archname}]
This may or may not cause problems. Please check your installation of perl if you
have problems building this extension.
END
	}
    }

    $self->init_dirscan();
    $self->init_others();

    push @{$self->{RESULT}}, <<END;
# This Makefile is for the $self->{NAME} extension to perl.
#
# It was generated automatically by MakeMaker version
# $VERSION (Revision: $Revision) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#	ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker Parameters:
END

    foreach $key (sort keys %initial_att){
	my($v) = neatvalue($initial_att{$key});
	$v =~ s/(CODE|HASH|ARRAY|SCALAR)\([\dxa-f]+\)/$1\(...\)/;
	$v =~ tr/\n/ /s;
	push @{$self->{RESULT}}, "#	$key => $v";
    }

    # turn the SKIP array into a SKIPHASH hash
    my (%skip,$skip);
    for $skip (@{$self->{SKIP} || []}) {
	$self->{SKIPHASH}{$skip} = 1;
    }

    # We run all the subdirectories now. They don't have much to query
    # from the parent, but the parent has to query them: if they need linking!
    unless ($self->{NORECURS}) {
	$self->eval_in_subdirs if @{$self->{DIR}};
    }

    tie %::att, ExtUtils::MakeMaker::TieAtt, $self;
    my $section;
    foreach $section ( @MM_Sections ){
	print "Processing Makefile '$section' section\n" if ($Verbose >= 2);
	my($skipit) = $self->skipcheck($section);
	if ($skipit){
	    push @{$self->{RESULT}}, "\n# --- MakeMaker $section section $skipit.";
	} else {
	    my(%a) = %{$self->{$section} || {}};
	    push @{$self->{RESULT}}, "\n# --- MakeMaker $section section:";
	    push @{$self->{RESULT}}, "# " . join ", ", %a if $Verbose && %a;
	    push @{$self->{RESULT}}, $self->nicetext($self->$section( %a ));
	}
    }

    push @{$self->{RESULT}}, "\n# End.";
    pop @Parent;

    $self;
}

sub check_manifest {
    print STDOUT "Checking if your kit is complete...\n";
    $ExtUtils::Manifest::Quiet=$ExtUtils::Manifest::Quiet=1; #avoid warning
    my(@missed)=ExtUtils::Manifest::manicheck();
    if (@missed){
	print STDOUT "Warning: the following files are missing in your kit:\n";
	print "\t", join "\n\t", @missed;
	print STDOUT "\n";
	print STDOUT "Please inform the author.\n";
    } else {
	print STDOUT "Looks good\n";
    }
}

sub parse_args{
    my($self, @args) = @_;
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
	# This may go away, in mid 1996
	if ($self->{Correct_relativ_directories}){
	    $value = $self->catdir("..",$value)
		if $Prepend_dot_dot{$name} && ! $value =~ m!^/!;
	}
	$self->{uc($name)} = $value;
    }
    # This may go away, in mid 1996
    delete $self->{Correct_relativ_directories};

    # catch old-style 'potential_libs' and inform user how to 'upgrade'
    if (defined $self->{potential_libs}){
	my($msg)="'potential_libs' => '$self->{potential_libs}' should be";
	if ($self->{potential_libs}){
	    print STDOUT "$msg changed to:\n\t'LIBS' => ['$self->{potential_libs}']\n";
	} else {
	    print STDOUT "$msg deleted.\n";
	}
	$self->{LIBS} = [$self->{potential_libs}];
	delete $self->{potential_libs};
    }
    # catch old-style 'ARMAYBE' and inform user how to 'upgrade'
    if (defined $self->{ARMAYBE}){
	my($armaybe) = $self->{ARMAYBE};
	print STDOUT "ARMAYBE => '$armaybe' should be changed to:\n",
			"\t'dynamic_lib' => {ARMAYBE => '$armaybe'}\n";
	my(%dl) = %{$self->{dynamic_lib} || {}};
	$self->{dynamic_lib} = { %dl, ARMAYBE => $armaybe};
	delete $self->{ARMAYBE};
    }
    if (defined $self->{LDTARGET}){
	print STDOUT "LDTARGET should be changed to LDFROM\n";
	$self->{LDFROM} = $self->{LDTARGET};
	delete $self->{LDTARGET};
    }
    # Turn a DIR argument on the command line into an array
    if (defined $self->{DIR} && ref \$self->{DIR} eq 'SCALAR') {
	# So they can choose from the command line, which extensions they want
	# the grep enables them to have some colons too much in case they
	# have to build a list with the shell
	$self->{DIR} = [grep $_, split ":", $self->{DIR}];
    }
    my $mmkey;
    foreach $mmkey (sort keys %$self){
	print STDOUT "	$mmkey => ", neatvalue($self->{$mmkey}), "\n" if $Verbose;
	print STDOUT "'$mmkey' is not a known MakeMaker parameter name.\n"
	    unless exists $Recognized_Att_Keys{$mmkey};
    }
}

sub check_hints {
    my($self) = @_;
    # We allow extension-specific hints files.

    return unless -d "hints";

    # First we look for the best hintsfile we have
    my(@goodhints);
    my($hint)="$Config{osname}_$Config{osvers}";
    $hint =~ s/\./_/g;
    $hint =~ s/_$//;
    return unless $hint;

    # Also try without trailing minor version numbers.
    while (1) {
	last if -f "hints/$hint.pl";      # found
    } continue {
	last unless $hint =~ s/_[^_]*$//; # nothing to cut off
    }
    return unless -f "hints/$hint.pl";    # really there

    # execute the hintsfile:
    my $fh = new FileHandle;
    $fh->open("hints/$hint.pl");
    @goodhints = <$fh>;
    $fh->close;
    print STDOUT "Processing hints file hints/$hint.pl\n";
    eval join('',@goodhints);
    print STDOUT $@ if $@;
}

sub mv_all_methods {
    my($from,$to) = @_;
    my($method);
    my($symtab) = \%{"${from}::"};
#    no strict;

    # Here you see the *current* list of methods that are overridable
    # from Makefile.PL via MY:: subroutines. As of VERSION 5.07 I'm
    # still trying to reduce the list to some reasonable minimum --
    # because I want to make it easier for the user. A.K.

    foreach $method (@MM_Sections, qw[ dir_target
fileparse fileparse_set_fstype installpm_x libscan makeaperl
mksymlists needs_linking subdir_x test_via_harness
test_via_script writedoc ]) {

	# We cannot say "next" here. Nick might call MY->makeaperl
	# which isn't defined right now

	# next unless defined &{"${from}::$method"};

	*{"${to}::$method"} = \&{"${from}::$method"};

	# delete would do, if we were sure, nobody ever called
	# MY->makeaperl directly

	# delete $symtab->{$method};

	# If we delete a method, then it will be undefined and cannot
	# be called.  But as long as we have Makefile.PLs that rely on
	# %MY:: being intact, we have to fill the hole with an
	# inheriting method:

	eval "package MY; sub $method {local *$method; shift->MY::$method(\@_); }";

    }

    # We have to clean out %INC also, because the current directory is
    # changed frequently and Graham Barr prefers to get his version
    # out of a History.pl file which is "required" so woudn't get
    # loaded again in another extension requiring a History.pl

    my $inc;
    foreach $inc (keys %INC) {
	next if $NORMAL_INC{$inc};
	#warn "***$inc*** deleted";
	delete $INC{$inc};
    }

}

sub prompt {
    my($mess,$def)=@_;
    BEGIN { $ISA_TTY = -t STDIN && -t STDOUT }
    Carp::confess("prompt function called without an argument") unless defined $mess;
    $def = "" unless defined $def;
    my $dispdef = "[$def] ";
    my $ans;
    if ($ISA_TTY) {
	local $|=1;
	print "$mess $dispdef";
	chop($ans = <STDIN>);
    }
    return $ans if defined $ans;
    return $def;
}

sub help {print &attrib_help, "\n";}

sub skipcheck{
    my($self) = shift;
    my($section) = @_;
    if ($section eq 'dynamic') {
	print STDOUT "Warning (non-fatal): Target 'dynamic' depends on targets ",
	"in skipped section 'dynamic_bs'\n"
            if $self->{SKIPHASH}{dynamic_bs} && $Verbose;
        print STDOUT "Warning (non-fatal): Target 'dynamic' depends on targets ",
	"in skipped section 'dynamic_lib'\n"
            if $self->{SKIPHASH}{dynamic_lib} && $Verbose;
    }
    if ($section eq 'dynamic_lib') {
        print STDOUT "Warning (non-fatal): Target '\$(INST_DYNAMIC)' depends on ",
	"targets in skipped section 'dynamic_bs'\n"
            if $self->{SKIPHASH}{dynamic_bs} && $Verbose;
    }
    if ($section eq 'static') {
        print STDOUT "Warning (non-fatal): Target 'static' depends on targets ",
	"in skipped section 'static_lib'\n"
            if $self->{SKIPHASH}{static_lib} && $Verbose;
    }
    return 'skipped' if $self->{SKIPHASH}{$section};
    return '';
}

sub flush {
    my $self = shift;
    my($chunk);
    my $fh = new FileHandle;
    print STDOUT "Writing $self->{MAKEFILE} for $self->{NAME}\n";

    unlink($self->{MAKEFILE}, "MakeMaker.tmp", $Is_VMS ? 'Descrip.MMS' : '');
    $fh->open(">MakeMaker.tmp") or die "Unable to open MakeMaker.tmp: $!";

    for $chunk (@{$self->{RESULT}}) {
	print $fh "$chunk\n";
    }

    $fh->close;
    my($finalname) = $self->{MAKEFILE};
    rename("MakeMaker.tmp", $finalname);
    chmod 0644, $finalname unless $Is_VMS;
    system("$Config::Config{eunicefix} $finalname") unless $Config::Config{eunicefix} eq ":";
}

# The following mkbootstrap() is only for installations that are calling
# the pre-4.1 mkbootstrap() from their old Makefiles. This MakeMaker
# writes Makefiles, that use ExtUtils::Mkbootstrap directly.
sub mkbootstrap {
    die <<END;
!!! Your Makefile has been built such a long time ago, !!!
!!! that is unlikely to work with current MakeMaker.   !!!
!!! Please rebuild your Makefile                       !!!
END
}

# Ditto for mksymlists() as of MakeMaker 5.17
sub mksymlists {
    die <<END;
!!! Your Makefile has been built such a long time ago, !!!
!!! that is unlikely to work with current MakeMaker.   !!!
!!! Please rebuild your Makefile                       !!!
END
}

sub neatvalue {
    my($v) = @_;
    return "undef" unless defined $v;
    my($t) = ref $v;
    return "q[$v]" unless $t;
    if ($t eq 'ARRAY') {
	my(@m, $elem, @neat);
	push @m, "[";
	foreach $elem (@$v) {
	    push @neat, "q[$elem]";
	}
	push @m, join ", ", @neat;
	push @m, "]";
	return join "", @m;
    }
    return "$v" unless $t eq 'HASH';
    my(@m, $key, $val);
    push(@m,"$key=>".neatvalue($val)) while (($key,$val) = each %$v);
    return "{ ".join(', ',@m)." }";
}

sub selfdocument {
    my($self) = @_;
    my(@m);
    if ($Verbose){
	push @m, "\n# Full list of MakeMaker attribute values:";
	foreach $key (sort keys %$self){
	    next if $key eq 'RESULT' || $key =~ /^[A-Z][a-z]/;
	    my($v) = neatvalue($self->{$key});
	    $v =~ s/(CODE|HASH|ARRAY|SCALAR)\([\dxa-f]+\)/$1\(...\)/;
	    $v =~ tr/\n/ /s;
	    push @m, "#	$key => $v";
	}
    }
    join "\n", @m;
}

package ExtUtils::MakeMaker;
1;

# Without selfLoader we need
__DATA__


# For SelfLoader we need 
# __END__ DATA


=head1 NAME

ExtUtils::MakeMaker - create an extension Makefile

=head1 SYNOPSIS

C<use ExtUtils::MakeMaker;>

C<WriteMakefile( ATTRIBUTE =E<gt> VALUE [, ...] );>

which is really

C<MM-E<gt>new(\%att)-E<gt>flush;>

=head1 DESCRIPTION

This utility is designed to write a Makefile for an extension module
from a Makefile.PL. It is based on the Makefile.SH model provided by
Andy Dougherty and the perl5-porters.

It splits the task of generating the Makefile into several subroutines
that can be individually overridden.  Each subroutine returns the text
it wishes to have written to the Makefile.

=head2 Hintsfile support

MakeMaker.pm uses the architecture specific information from
Config.pm. In addition it evaluates architecture specific hints files
in a C<hints/> directory. The hints files are expected to be named
like their counterparts in C<PERL_SRC/hints>, but with an C<.pl> file
name extension (eg. C<next_3_2.pl>). They are simply C<eval>ed by
MakeMaker within the WriteMakefile() subroutine, and can be used to
execute commands as well as to include special variables. The rules
which hintsfile is chosen are the same as in Configure.

The hintsfile is eval()ed immediately after the arguments given to
WriteMakefile are stuffed into a hash reference $self but before this
reference becomes blessed. So if you want to do the equivalent to
override or create an attribute you would say something like

    $self->{LIBS} = ['-ldbm -lucb -lc'];

=head2 What's new in version 5 of MakeMaker

MakeMaker 5 is pure object oriented. This allows us to write an
unlimited number of Makefiles with a single perl process. 'perl
Makefile.PL' with MakeMaker 5 goes through all subdirectories
immediately and evaluates any Makefile.PL found in the next level
subdirectories. The benefit of this approach comes in useful for both
single and multi directories extensions.

Multi directory extensions have an immediately visible speed
advantage, because there's no startup penalty for any single
subdirectory Makefile.

Single directory packages benefit from the much improved
needs_linking() method. As the main Makefile knows everything about
the subdirectories, a needs_linking() method can now query all
subdirectories if there is any linking involved down in the tree. The
speedup for PM-only Makefiles seems to be around 1 second on my
Indy 100 MHz.

=head2 Incompatibilities between MakeMaker 5.00 and 4.23

There are no incompatibilities in the short term, as all changes are
accompanied by short-term workarounds that guarantee full backwards
compatibility.

You are likely to face a few warnings that expose deprecations which
will result in incompatibilities in the long run:

You should not use %att directly anymore. Instead any subroutine you
override in the MY package will be called by the object method, so you
can access all object attributes directly via the object in $_[0].

You should not call the class methos MM->something anymore. Instead
you should call the superclass. Something like

    sub MY::constants {
        my $self = shift;
        $self->MM::constants();
    }

Especially the libscan() and exescan() methods should be altered
towards OO programming, that means do not expect that $_ to contain
the path but rather $_[1].

Try to build several extensions simultanously to debug your
Makefile.PL. You can unpack a bunch of distributed packages within one
directory and run

    perl -MExtUtils::MakeMaker -e 'WriteMakefile()'

That's actually fun to watch :)

Final suggestion: Try to delete all of your MY:: subroutines and
watch, if you really still need them. MakeMaker might already do what
you want without them. That's all about it.


=head2 Default Makefile Behaviour

The automatically generated Makefile enables the user of the extension
to invoke

  perl Makefile.PL # optionally "perl Makefile.PL verbose"
  make
  make test        # optionally set TEST_VERBOSE=1
  make install     # See below

The Makefile to be produced may be altered by adding arguments of the
form C<KEY=VALUE>. E.g.

  perl Makefile.PL PREFIX=/tmp/myperl5

Other interesting targets in the generated Makefile are

  make config     # to check if the Makefile is up-to-date
  make clean      # delete local temp files (Makefile gets renamed)
  make realclean  # delete derived files (including ./blib)
  make ci         # check in all the files in the MANIFEST file
  make dist       # see below the Distribution Support section

=head2 make test

MakeMaker checks for the existence of a file named "test.pl" in the
current directory and if it exists it adds commands to the test target
of the generated Makefile that will execute the script with the proper
set of perl C<-I> options.

MakeMaker also checks for any files matching glob("t/*.t"). It will
add commands to the test target of the generated Makefile that execute
all matching files via the L<Test::Harness> module with the C<-I>
switches set correctly.

=head2 make install

make alone puts all relevant files into directories that are named by
the macros INST_LIB, INST_ARCHLIB, INST_EXE, INST_MAN1DIR, and
INST_MAN3DIR. All these default to something below ./blib if
you are I<not> building below the perl source directory. If you I<are>
building below the perl source, INST_LIB and INST_ARCHLIB default to
 ../../lib, and INST_EXE is not defined.

The I<install> target of the generated Makefile copies the files found
below each of the INST_* directories to their INSTALL*
counterparts. Which counterparts are chosen depends on the setting of
INSTALLDIRS according to the following table:

		       	   INSTALLDIRS set to
       	       	        perl   	          site

    INST_LIB        INSTALLPRIVLIB    INSTALLSITELIB
    INST_ARCHLIB    INSTALLARCHLIB    INSTALLSITEARCH
    INST_EXE                   INSTALLBIN
    INST_MAN1DIR             INSTALLMAN1DIR
    INST_MAN3DIR             INSTALLMAN3DIR

The INSTALL... macros in turn default to their %Config
($Config{installprivlib}, $Config{installarchlib}, etc.) counterparts.

If you don't want to keep the defaults, MakeMaker helps you to
minimize the typing needed: the usual relationship between
INSTALLPRIVLIB and INSTALLARCHLIB is determined by Configure at perl
compilation time. MakeMaker supports the user who sets
INSTALLPRIVLIB. If INSTALLPRIVLIB is set, but INSTALLARCHLIB not, then
MakeMaker defaults the latter to be the same subdirectory of
INSTALLPRIVLIB as Configure decided for the counterparts in %Config ,
otherwise it defaults to INSTALLPRIVLIB. The same relationship holds
for INSTALLSITELIB and INSTALLSITEARCH.

MakeMaker gives you much more freedom than needed to configure
internal variables and get different results. It is worth to mention,
that make(1) also lets you configure most of the variables that are
used in the Makefile. But in the majority of situations this will not
be necessary, and should only be done, if the author of a package
recommends it.


=head2 PREFIX attribute

The PREFIX attribute can be used to set the INSTALL* attributes in one
go. The quickest way to install a module in a non-standard place

    perl Makefile.PL PREFIX=~

This will replace the string specified by $Config{prefix} in all
$Config{install*} values.

Note, that the tilde expansion is done by MakeMaker, not by perl by
default, nor by make.

If the user has superuser privileges, and is not working on AFS
(Andrew File System) or relatives, then the defaults for
INSTALLPRIVLIB, INSTALLARCHLIB, INSTALLBIN, etc. will be appropriate,
and this incantation will be the best:

    perl Makefile.PL; make; make test
    make install

make install per default writes some documentation of what has been
done into the file C<$(INSTALLARCHLIB)/perllocal.pod>. This feature
can be bypassed by calling make pure_install.

=head2 AFS users

will have to specify the installation directories as these most
probably have changed since perl itself has been installed. They will
have to do this by calling

    perl Makefile.PL INSTALLSITELIB=/afs/here/today \
	INSTALLBIN=/afs/there/now INSTALLMAN3DIR=/afs/for/manpages
    make

Be careful to repeat this procedure every time you recompile an
extension, unless you are sure the AFS installation directories are
still valid.

=head2 Static Linking of a new Perl Binary

An extension that is built with the above steps is ready to use on
systems supporting dynamic loading. On systems that do not support
dynamic loading, any newly created extension has to be linked together
with the available resources. MakeMaker supports the linking process
by creating appropriate targets in the Makefile whenever an extension
is built. You can invoke the corresponding section of the makefile with

    make perl

That produces a new perl binary in the current directory with all
extensions linked in that can be found in INST_ARCHLIB , SITELIBEXP,
and PERL_ARCHLIB. To do that, MakeMaker writes a new Makefile, on
UNIX, this is called Makefile.aperl (may be system dependent). If you
want to force the creation of a new perl, it is recommended, that you
delete this Makefile.aperl, so the directories are searched-through
for linkable libraries again.

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

make inst_perl per default writes some documentation of what has been
done into the file C<$(INSTALLARCHLIB)/perllocal.pod>. This
can be bypassed by calling make pure_inst_perl.

Warning: the inst_perl: target will most probably overwrite your
existing perl binary. Use with care!

Sometimes you might want to build a statically linked perl although
your system supports dynamic loading. In this case you may explicitly
set the linktype with the invocation of the Makefile.PL or make:

    perl Makefile.PL LINKTYPE=static    # recommended

or

    make LINKTYPE=static                # works on most systems

=head2 Determination of Perl Library and Installation Locations

MakeMaker needs to know, or to guess, where certain things are
located.  Especially INST_LIB and INST_ARCHLIB (where to put the files
during the make(1) run), PERL_LIB and PERL_ARCHLIB (where to read
existing modules from), and PERL_INC (header files and C<libperl*.*>).

Extensions may be built either using the contents of the perl source
directory tree or from the installed perl library. The recommended way
is to build extensions after you have run 'make install' on perl
itself. You can do that in any directory on your hard disk that is not
below the perl source tree. The support for extensions below the ext
directory of the perl distribution is only good for the standard
extensions that come with perl.

If an extension is being built below the C<ext/> directory of the perl
source then MakeMaker will set PERL_SRC automatically (e.g.,
C<../..>).  If PERL_SRC is defined and the extension is recognized as
a standard extension, then other variables default to the following:

  PERL_INC     = PERL_SRC
  PERL_LIB     = PERL_SRC/lib
  PERL_ARCHLIB = PERL_SRC/lib
  INST_LIB     = PERL_LIB
  INST_ARCHLIB = PERL_ARCHLIB

If an extension is being built away from the perl source then MakeMaker
will leave PERL_SRC undefined and default to using the installed copy
of the perl library. The other variables default to the following:

  PERL_INC     = $archlibexp/CORE
  PERL_LIB     = $privlibexp
  PERL_ARCHLIB = $archlibexp
  INST_LIB     = ./blib/lib
  INST_ARCHLIB = ./blib/arch

If perl has not yet been installed then PERL_SRC can be defined on the
command line as shown in the previous section.

=head2 Useful Default Makefile Macros

FULLEXT = Pathname for extension directory (eg DBD/Oracle).

BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT.

ROOTEXT = Directory part of FULLEXT with leading slash (eg /DBD)

INST_LIBDIR = C<$(INST_LIB)$(ROOTEXT)>

INST_AUTODIR = C<$(INST_LIB)/auto/$(FULLEXT)>

INST_ARCHAUTODIR = C<$(INST_ARCHLIB)/auto/$(FULLEXT)>

=head2 Using Attributes and Parameters

The following attributes can be specified as arguments to WriteMakefile()
or as NAME=VALUE pairs on the command line:

=cut

# The following "=item C" is used by the attrib_help routine
# likewise the "=back" below. So be careful when changing it!

=over 2

=item C

Ref to array of *.c file names. Initialised from a directory scan
and the values portion of the XS attribute hash. This is not
currently used by MakeMaker but may be handy in Makefile.PLs.

=item CONFIG

Arrayref. E.g. [qw(archname manext)] defines ARCHNAME & MANEXT from
config.sh. MakeMaker will add to CONFIG the following values anyway:
ar
cc
cccdlflags
ccdlflags
dlext
dlsrc
ld
lddlflags
ldflags
libc
lib_ext
obj_ext
ranlib
sitelibexp
sitearchexp
so

=item CONFIGURE

CODE reference. The subroutine should return a hash reference. The
hash may contain further attributes, e.g. {LIBS => ...}, that have to
be determined by some evaluation method.

=item DEFINE

Something like C<"-DHAVE_UNISTD_H">

=item DIR

Ref to array of subdirectories containing Makefile.PLs e.g. [ 'sdbm'
] in ext/SDBM_File

=item DISTNAME

Your name for distributing the package (by tar file). This defaults to
NAME above.

=item DL_FUNCS

Hashref of symbol names for routines to be made available as
universal symbols.  Each key/value pair consists of the package name
and an array of routine names in that package.  Used only under AIX
(export lists) and VMS (linker options) at present.  The routine
names supplied will be expanded in the same way as XSUB names are
expanded by the XS() macro.  Defaults to

  {"$(NAME)" => ["boot_$(NAME)" ] }

e.g.

  {"RPC" => [qw( boot_rpcb rpcb_gettime getnetconfigent )],
   "NetconfigPtr" => [ 'DESTROY'] }

=item DL_VARS

Array of symbol names for variables to be made available as
universal symbols.  Used only under AIX (export lists) and VMS
(linker options) at present.  Defaults to [].  (e.g. [ qw(
Foo_version Foo_numstreams Foo_tree ) ])

=item EXE_FILES

Ref to array of executable files. The files will be copied to the
INST_EXE directory. Make realclean will delete them from there
again.

=item FIRST_MAKEFILE

The name of the Makefile to be produced. Defaults to the contents of
MAKEFILE, but can be overridden. This is used for the second Makefile
that will be produced for the MAP_TARGET.

=item FULLPERL

Perl binary able to run this extension.

=item H

Ref to array of *.h file names. Similar to C.

=item INC

Include file dirs eg: C<"-I/usr/5include -I/path/to/inc">

=item INSTALLARCHLIB

Used by 'make install', which copies files from INST_ARCHLIB to this
directory if INSTALLDIRS is set to perl.

=item INSTALLBIN

Used by 'make install' which copies files from INST_EXE to this
directory.

=item INSTALLDIRS

Determines which of the two sets of installation directories to
choose: installprivlib and installarchlib versus installsitelib and
installsitearch. The first pair is chosen with INSTALLDIRS=perl, the
second with INSTALLDIRS=site. Default is site.

=item INSTALLMAN1DIR

This directory gets the man pages at 'make install' time. Defaults to
$Config{installman1dir}.

=item INSTALLMAN3DIR

This directory gets the man pages at 'make install' time. Defaults to
$Config{installman3dir}.

=item INSTALLPRIVLIB

Used by 'make install', which copies files from INST_LIB to this
directory if INSTALLDIRS is set to perl.

=item INSTALLSITELIB

Used by 'make install', which copies files from INST_LIB to this
directory if INSTALLDIRS is set to site (default).

=item INSTALLSITEARCH

Used by 'make install', which copies files from INST_ARCHLIB to this
directory if INSTALLDIRS is set to site (default).

=item INST_ARCHLIB

Same as INST_LIB for architecture dependent files.

=item INST_EXE

Directory, where executable scripts should be installed during
'make'. Defaults to "./blib/bin", just to have a dummy location during
testing. make install will copy the files in INST_EXE to INSTALLBIN.

=item INST_LIB

Directory where we put library files of this extension while building
it.

=item INST_MAN1DIR

Directory to hold the man pages at 'make' time

=item INST_MAN3DIR

Directory to hold the man pages at 'make' time

=item LDFROM

defaults to "$(OBJECT)" and is used in the ld command to specify
what files to link/load from (also see dynamic_lib below for how to
specify ld flags)

=item LIBPERL_A

The filename of the perllibrary that will be used together with this
extension. Defaults to libperl.a.

=item LIBS

An anonymous array of alternative library
specifications to be searched for (in order) until
at least one library is found. E.g.

  'LIBS' => ["-lgdbm", "-ldbm -lfoo", "-L/path -ldbm.nfs"]

Mind, that any element of the array
contains a complete set of arguments for the ld
command. So do not specify

  'LIBS' => ["-ltcl", "-ltk", "-lX11"]

See ODBM_File/Makefile.PL for an example, where an array is needed. If
you specify a scalar as in

  'LIBS' => "-ltcl -ltk -lX11"

MakeMaker will turn it into an array with one element.

=item LINKTYPE

'static' or 'dynamic' (default unless usedl=undef in
config.sh). Should only be used to force static linking (also see
linkext below).

=item MAKEAPERL

Boolean which tells MakeMaker, that it should include the rules to
make a perl. This is handled automatically as a switch by
MakeMaker. The user normally does not need it.

=item MAKEFILE

The name of the Makefile to be produced.

=item MAN1PODS

Hashref of pod-containing files. MakeMaker will default this to all
EXE_FILES files that include POD directives. The files listed
here will be converted to man pages and installed as was requested
at Configure time.

=item MAN3PODS

Hashref of .pm and .pod files. MakeMaker will default this to all
 .pod and any .pm files that include POD directives. The files listed
here will be converted to man pages and installed as was requested
at Configure time.

=item MAP_TARGET

If it is intended, that a new perl binary be produced, this variable
may hold a name for that binary. Defaults to perl

=item MYEXTLIB

If the extension links to a library that it builds set this to the
name of the library (see SDBM_File)

=item NAME

Perl module name for this extension (DBD::Oracle). This will default
to the directory name but should be explicitly defined in the
Makefile.PL.

=item NEEDS_LINKING

MakeMaker will figure out, if an extension contains linkable code
anywhere down the directory tree, and will set this variable
accordingly, but you can speed it up a very little bit, if you define
this boolean variable yourself.

=item NOECHO

Defaults the C<@>. By setting it to an empty string you can generate a
Makefile that echos all commands. Mainly used in debugging MakeMaker
itself.

=item NORECURS

Boolean.  Attribute to inhibit descending into subdirectories.

=item OBJECT

List of object files, defaults to '$(BASEEXT)$(OBJ_EXT)', but can be a long
string containing all object files, e.g. "tkpBind.o
tkpButton.o tkpCanvas.o"

=item PERL

Perl binary for tasks that can be done by miniperl

=item PERLMAINCC

The call to the program that is able to compile perlmain.c. Defaults
to $(CC).

=item PERL_ARCHLIB

Same as above for architecture dependent files

=item PERL_LIB

Directory containing the Perl library to use.

=item PERL_SRC

Directory containing the Perl source code (use of this should be
avoided, it may be undefined)

=item PL_FILES

Ref to hash of files to be processed as perl programs. MakeMaker
will default to any found *.PL file (except Makefile.PL) being keys
and the basename of the file being the value. E.g.

  {'foobar.PL' => 'foobar'}

The *.PL files are expected to produce output to the target files
themselves.

=item PM

Hashref of .pm files and *.pl files to be installed.  e.g.

  {'name_of_file.pm' => '$(INST_LIBDIR)/install_as.pm'}

By default this will include *.pm and *.pl. If a lib directory
exists and is not listed in DIR (above) then any *.pm and *.pl files
it contains will also be included by default.  Defining PM in the
Makefile.PL will override PMLIBDIRS.

=item PMLIBDIRS

Ref to array of subdirectories containing library files.  Defaults to
[ 'lib', $(BASEEXT) ]. The directories will be scanned and any files
they contain will be installed in the corresponding location in the
library.  A libscan() method can be used to alter the behaviour.
Defining PM in the Makefile.PL will override PMLIBDIRS.

=item PREFIX

Can be used to set the three INSTALL* attributes in one go (except for
probably INSTALLMAN1DIR, if it is not below PREFIX according to
%Config).  They will have PREFIX as a common directory node and will
branch from that node into lib/, lib/ARCHNAME or whatever Configure
decided at the build time of your perl (unless you override one of
them, of course).

=item PREREQ

Placeholder, not yet implemented. Will eventually be a hashref: Names
of modules that need to be available to run this extension (e.g. Fcntl
for SDBM_File) are the keys of the hash and the desired version is the
value. Needs further evaluation, should probably allow to define
prerequisites among header files, libraries, perl version, etc.

=item SKIP

Arryref. E.g. [qw(name1 name2)] skip (do not write) sections of the
Makefile

=item TYPEMAPS

Ref to array of typemap file names.  Use this when the typemaps are
in some directory other than the current directory or when they are
not named B<typemap>.  The last typemap in the list takes
precedence.  A typemap in the current directory has highest
precedence, even if it isn't listed in TYPEMAPS.  The default system
typemap has lowest precedence.

=item VERSION

Your version number for distributing the package.  This defaults to
0.1.

=item VERSION_FROM

Instead of specifying the VERSION in the Makefile.PL you can let
MakeMaker parse a file to determine the version number. The parsing
routine requires that the file named by VERSION_FROM contains one
single line to compute the version number. The first line in the file
that contains the regular expression

    /(\$[\w:]*\bVERSION)\b.*=/

will be evaluated with eval() and the value of the named variable
B<after> the eval() will be assigned to the VERSION attribute of the
MakeMaker object. The following lines will be parsed o.k.:

    $VERSION = '1.00';
    ( $VERSION ) = '$Revision: 1.174 $ ' =~ /\$Revision:\s+([^\s]+)/;
    $FOO::VERSION = '1.10';

but these will fail:

    my $VERSION = '1.01';
    local $VERSION = '1.02';
    local $FOO::VERSION = '1.30';

The file named in VERSION_FROM is added as a dependency to Makefile to
guarantee, that the Makefile contains the correct VERSION macro after
a change of the file.

=item XS

Hashref of .xs files. MakeMaker will default this.  e.g.

  {'name_of_file.xs' => 'name_of_file.c'}

The .c files will automatically be included in the list of files
deleted by a make clean.

=item XSOPT

String of options to pass to xsubpp.  This might include C<-C++> or
C<-extern>.  Do not include typemaps here; the TYPEMAP parameter exists for
that purpose.

=item XSPROTOARG

May be set to an empty string, which is identical to C<-prototypes>, or
C<-noprototypes>. See the xsubpp documentation for details. MakeMaker
defaults to the empty string.

=item XS_VERSION

Your version number for the .xs file of this package.  This defaults
to the value of the VERSION attribute.

=back

=head2 Additional lowercase attributes

can be used to pass parameters to the methods which implement that
part of the Makefile. These are not normally required:

=over 2

=item clean

  {FILES => "*.xyz foo"}

=item depend

  {ANY_TARGET => ANY_DEPENDECY, ...}

=item dist

  {TARFLAGS => 'cvfF', COMPRESS => 'gzip', SUFFIX => 'gz',
  SHAR => 'shar -m', DIST_CP => 'ln'}

If you specify COMPRESS, then SUFFIX should also be altered, as it is
needed to tell make the target file of the compression. Setting
DIST_CP to ln can be useful, if you need to preserve the timestamps on
your files. DIST_CP can take the values 'cp', which copies the file,
'ln', which links the file, and 'best' which copies symbolic links and
links the rest. Default is 'best'.

=item dynamic_lib

  {ARMAYBE => 'ar', OTHERLDFLAGS => '...', INST_DYNAMIC_DEP => '...'}

=item installpm

  {SPLITLIB => '$(INST_LIB)' (default) or '$(INST_ARCHLIB)'}

=item linkext

  {LINKTYPE => 'static', 'dynamic' or ''}

NB: Extensions that have nothing but *.pm files had to say

  {LINKTYPE => ''}

with Pre-5.0 MakeMakers. Since version 5.00 of MakeMaker such a line
can be deleted safely. MakeMaker recognizes, when there's nothing to
be linked.

=item macro

  {ANY_MACRO => ANY_VALUE, ...}

=item realclean

  {FILES => '$(INST_ARCHAUTODIR)/*.xyz'}

=item tool_autosplit

  {MAXLEN =E<gt> 8}

=back

=cut

# bug in pod2html, so leave the =back

# Don't delete this cut, MM depends on it!

=head2 Overriding MakeMaker Methods

If you cannot achieve the desired Makefile behaviour by specifying
attributes you may define private subroutines in the Makefile.PL.
Each subroutines returns the text it wishes to have written to
the Makefile. To override a section of the Makefile you can
either say:

	sub MY::c_o { "new literal text" }

or you can edit the default by saying something like:

	sub MY::c_o {
	    my $self = shift;
	    local *c_o;
            $_=$self->MM::c_o;
	    s/old text/new text/;
	    $_;
	}

Both methods above are available for backwards compatibility with
older Makefile.PLs.

If you still need a different solution, try to develop another
subroutine, that fits your needs and submit the diffs to
F<perl5-porters@nicoh.com> or F<comp.lang.perl.misc> as appropriate.

=head2 Distribution Support

For authors of extensions MakeMaker provides several Makefile
targets. Most of the support comes from the ExtUtils::Manifest module,
where additional documentation can be found.

=over 4

=item    make distcheck

reports which files are below the build directory but not in the
MANIFEST file and vice versa. (See ExtUtils::Manifest::fullcheck() for
details)

=item    make skipcheck

reports which files are skipped due to the entries in the
C<MANIFEST.SKIP> file (See ExtUtils::Manifest::skipcheck() for
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

=item	make disttest

Makes a distdir first, and runs a C<perl Makefile.PL>, a make, and
a make test in that directory.

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

Does a $(CI) and a $(RCS_LABEL) on all files in the MANIFEST file.

=back

Customization of the dist targets can be done by specifying a hash
reference to the dist attribute of the WriteMakefile call. The
following parameters are recognized:

    CI           ('ci -u')
    COMPRESS     ('compress')
    POSTOP       ('@ :')
    PREOP        ('@ :')
    RCS_LABEL    ('rcs -q -Nv$(VERSION_SYM):')
    SHAR         ('shar')
    SUFFIX       ('Z')
    TAR          ('tar')
    TARFLAGS     ('cvf')

An example:

    WriteMakefile( 'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" })


=head1 AUTHORS

Andy Dougherty F<E<lt>doughera@lafcol.lafayette.eduE<gt>>, Andreas
KE<ouml>nig F<E<lt>A.Koenig@franz.ww.TU-Berlin.DEE<gt>>, Tim Bunce
F<E<lt>Tim.Bunce@ig.co.ukE<gt>>.  VMS support by Charles Bailey
F<E<lt>bailey@genetics.upenn.eduE<gt>>. OS/2 support by Ilya
Zakharevich F<E<lt>ilya@math.ohio-state.eduE<gt>>. Contact the
makemaker mailing list C<mailto:makemaker@franz.ww.tu-berlin.de>, if
you have any questions.

=head1 MODIFICATION HISTORY

For a more complete documentation see the file Changes in the
MakeMaker distribution package.

=head1 TODO

See the file Todo in the MakeMaker distribution package.

=cut
