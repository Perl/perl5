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

# Last edited $Date: 1996/01/28 11:33:38 $ by Andreas Koenig
# $Id: MakeMaker.pm,v 1.141 1996/01/28 11:33:38 k Exp $

$Version = $VERSION = "5.18";

$ExtUtils::MakeMaker::Version_OK = "5.05";	# Makefiles older than $Version_OK will die
			# (Will be checked from MakeMaker version 4.13 onwards)

use Config;
use Carp;
use Cwd;
require Exporter;
require ExtUtils::Manifest;
require ExtUtils::Liblist;
#use strict qw(refs);

eval {require DynaLoader;};	# Get mod2fname, if defined. Will fail
                                # with miniperl.

# print join "**\n**", "", %INC, "";
%NORMAL_INC = %INC;



@ISA = qw(Exporter);
@EXPORT = qw(&WriteMakefile &writeMakefile $Verbose &prompt);
@EXPORT_OK = qw($Version $VERSION &Version_check
		&help &neatvalue &mkbootstrap &mksymlists
		%att  ## Import of %att is deprecated, please use OO features!
);

if ($Is_VMS = ($Config::Config{osname} eq 'VMS')) {
    require ExtUtils::MM_VMS;
    require VMS::Filespec;
    import VMS::Filespec '&vmsify';
}
$Is_OS2 = $Config::Config{osname} =~ m|^os/?2$|i ;
$ENV{EMXSHELL} = 'sh' if $Is_OS2; # to run `commands`

$ExtUtils::MakeMaker::Verbose = 0 unless defined $ExtUtils::MakeMaker::Verbose;
$^W=1;
#$SIG{__DIE__} = sub { print @_, Carp::longmess(); die; };
####$SIG{__WARN__} = sub { print Carp::longmess(); warn @_; };
$SIG{__WARN__} = sub {
    $_[0] =~ /^Use of uninitialized value/ && return;
    $_[0] =~ /used only once/ && return;
    $_[0] =~ /^Subroutine\s+[\w:]+\s+redefined/ && return;
    warn @_;
};

# Setup dummy package:
# MY exists for overriding methods to be defined within
unshift(@MY::ISA, qw(MM));

# Dummy package MM inherits actual methods from OS-specific
# default packages.  We use this intermediate package so
# MY::XYZ->func() can call MM->func() and get the proper
# default routine without having to know under what OS
# it's running.

@MM::ISA = qw[ExtUtils::MM_Unix ExtUtils::MakeMaker];
unshift @MM::ISA, 'ExtUtils::MM_VMS' if $Is_VMS;
unshift @MM::ISA, 'ExtUtils::MM_OS2' if $Is_OS2;


@ExtUtils::MakeMaker::MM_Sections_spec = (
    post_initialize	=> {},
    const_config	=> {},
    constants		=> {},
    const_loadlibs	=> {},
    const_cccmd		=> {}, # the last but one addition here (CONST_CCCMD)
    tool_autosplit	=> {},
    tool_xsubpp		=> {},
    tools_other		=> {},
    dist		=> {},
    macro		=> {},
    depend		=> {},
    post_constants	=> {},
    pasthru		=> {},
    c_o			=> {},
    xs_c		=> {},
    xs_o		=> {},
    top_targets		=> {}, # currently the last section that adds a key to $self (DIR_TARGET)
    linkext		=> {},
    dlsyms		=> {},
    dynamic		=> {},
    dynamic_bs		=> {},
    dynamic_lib		=> {},
    static		=> {},
    static_lib		=> {},
    installpm		=> {},
    manifypods		=> {},
    processPL		=> {},
    installbin		=> {},
    subdirs		=> {},
    clean		=> {},
    realclean		=> {},
    dist_basics		=> {},
    dist_core		=> {},
    dist_dir		=> {},
    dist_test		=> {},
    dist_ci		=> {},
    install		=> {},
    force		=> {},
    perldepend		=> {},
    makefile		=> {},
    staticmake		=> {},	# Sadly this defines more macros
    test		=> {},
    postamble		=> {},	# should always be last the user has hands on
    selfdocument	=> {},  # well, he may override it, but he won't do it
);
# loses section ordering
%ExtUtils::MakeMaker::MM_Sections = @ExtUtils::MakeMaker::MM_Sections_spec;
# keeps order
@ExtUtils::MakeMaker::MM_Sections = grep(!ref, @ExtUtils::MakeMaker::MM_Sections_spec);

%ExtUtils::MakeMaker::Recognized_Att_Keys = %ExtUtils::MakeMaker::MM_Sections; # All sections are valid keys.

@ExtUtils::MakeMaker::Get_from_Config = qw(
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
so
);

my $item;
foreach $item (split(/\n/,attrib_help())){
    next unless $item =~ m/^=item\s+(\w+)\s*$/;
    $ExtUtils::MakeMaker::Recognized_Att_Keys{$1} = $2;
    print "Attribute '$1' => '$2'\n" if ($ExtUtils::MakeMaker::Verbose >= 2);
}
foreach $item (@ExtUtils::MakeMaker::Get_from_Config) {
    next unless $Config::Config{$item};
    $ExtUtils::MakeMaker::Recognized_Att_Keys{uc $item} = $Config::Config{$item};
    print "Attribute '\U$item\E' => '$Config::Config{$item}'\n"
	if ($ExtUtils::MakeMaker::Verbose >= 2);
}

%ExtUtils::MakeMaker::Prepend_dot_dot = qw(
INST_LIB 1 INST_ARCHLIB 1 INST_EXE 1 MAP_TARGET 1 INST_MAN1DIR 1 INST_MAN3DIR 1
PERL_SRC 1 PERL 1 FULLPERL 1
);
$PACKNAME = "PACK000";

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
    my($key);

    print STDOUT "MakeMaker (v$ExtUtils::MakeMaker::VERSION)\n" if $ExtUtils::MakeMaker::Verbose;
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
	$self->{Correct_relativ_directories}++;
    } else {
	$self->{Correct_relativ_directories}=0;
    }

    my $class = ++$PACKNAME;
    {
#	no strict;
	print "Blessing Object into class [$class]\n" if $ExtUtils::MakeMaker::Verbose;
	mv_all_methods("MY",$class);
	bless $self, $class;
########	tie %::att, ExtUtils::MakeMaker::TieAtt, $self;
	push @ExtUtils::MakeMaker::Parent, $self;
	@{"$class\:\:ISA"} = 'MM';
    }

    if (defined $ExtUtils::MakeMaker::Parent[-2]){
	$self->{PARENT} = $ExtUtils::MakeMaker::Parent[-2];
	my $key;
	for $key (keys %ExtUtils::MakeMaker::Prepend_dot_dot) {
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
	if ($pthinks ne $self->catfile($Config::Config{archlibexp},'Config.pm')){
	    $pthinks =~ s!/Config\.pm$!!;
	    $pthinks =~ s!.*/!!;
	    print STDOUT <<END;
Your perl and your Config.pm seem to have different ideas about the architecture
they are running on.
Perl thinks: [$pthinks]
Config says: [$Config::Config{archname}]
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
# It was generated automatically by MakeMaker version $ExtUtils::MakeMaker::VERSION from the contents
# of Makefile.PL. Don't edit this file, edit Makefile.PL instead.
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
    my($dir);
    unless ($self->{NORECURS}) {
	foreach $dir (@{$self->{DIR}}){
	    chdir $dir;
	    package main;
	    local *FH;
	    open FH, "Makefile.PL";
	    eval join "", <FH>;
	    close FH;
	    chdir "..";
	}
    }

    tie %::att, ExtUtils::MakeMaker::TieAtt, $self;
    my $section;
    foreach $section ( @ExtUtils::MakeMaker::MM_Sections ){
	print "Processing Makefile '$section' section\n" if ($ExtUtils::MakeMaker::Verbose >= 2);
	my($skipit) = $self->skipcheck($section);
	if ($skipit){
	    push @{$self->{RESULT}}, "\n# --- MakeMaker $section section $skipit.";
	} else {
	    my(%a) = %{$self->{$section} || {}};
	    push @{$self->{RESULT}}, "\n# --- MakeMaker $section section:";
	    push @{$self->{RESULT}}, "# " . join ", ", %a if $ExtUtils::MakeMaker::Verbose && %a;
	    push @{$self->{RESULT}}, $self->nicetext($self->$section( %a ));
	}
    }

    push @{$self->{RESULT}}, "\n# End.";
########    untie %::att;
    pop @ExtUtils::MakeMaker::Parent;

    $self;
}

sub check_manifest {
    eval {require ExtUtils::Manifest};
    if ($@){
	print STDOUT "Warning: you have not installed the ExtUtils::Manifest
         module -- skipping check of the MANIFEST file\n";
    } else {
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
}

sub parse_args{
    my($self, @args) = @_;
    foreach (@args){
	unless (m/(.*?)=(.*)/){
	    help(),exit 1 if m/^help$/;
	    ++$ExtUtils::MakeMaker::Verbose if m/^verb/;
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
		if $ExtUtils::MakeMaker::Prepend_dot_dot{$name} && ! $value =~ m!^/!;
	}
	$self->{$name} = $value;
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
	print STDOUT "	$mmkey => ", neatvalue($self->{$mmkey}), "\n" if $ExtUtils::MakeMaker::Verbose;
	print STDOUT "'$mmkey' is not a known MakeMaker parameter name.\n"
	    unless exists $ExtUtils::MakeMaker::Recognized_Att_Keys{$mmkey};
    }
}

sub check_hints {
    my($self) = @_;
    # We allow extension-specific hints files.

    return unless -d "hints";

    # First we look for the best hintsfile we have
    my(@goodhints);
    my($hint)="$Config::Config{osname}_$Config::Config{osvers}";
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
    local *HINTS;
    open HINTS, "hints/$hint.pl";
    @goodhints = <HINTS>;
    close HINTS;
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

    foreach $method (@ExtUtils::MakeMaker::MM_Sections, qw[ dir_target
exescan fileparse fileparse_set_fstype installpm_x libscan makeaperl
mksymlists needs_linking runsubdirpl subdir_x test_via_harness
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
	next if $ExtUtils::MakeMaker::NORMAL_INC{$inc};
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

sub attrib_help {
    return $Attrib_Help if $Attrib_Help;
    my $switch = 0;
    my $help;
    my $line;
    local *POD;
####    local $/ = ""; # bug in 5.001m
    open POD, $INC{"ExtUtils/MakeMaker.pm"}
    or die "Open $INC{'ExtUtils/MakeMaker.pm'}: $!";
    while ($line = <POD>) {
	$switch ||= $line =~ /^=item C\s*$/;
	next unless $switch;
	last if $line =~ /^=cut/;
	$help .= $line;
    }
    close POD;
    $Attrib_Help = $help;
}

sub help {print &attrib_help, "\n";}

sub skipcheck{
    my($self) = shift;
    my($section) = @_;
    if ($section eq 'dynamic') {
	print STDOUT "Warning (non-fatal): Target 'dynamic' depends on targets ",
	"in skipped section 'dynamic_bs'\n"
            if $self->{SKIPHASH}{dynamic_bs} && $ExtUtils::MakeMaker::Verbose;
        print STDOUT "Warning (non-fatal): Target 'dynamic' depends on targets ",
	"in skipped section 'dynamic_lib'\n"
            if $self->{SKIPHASH}{dynamic_lib} && $ExtUtils::MakeMaker::Verbose;
    }
    if ($section eq 'dynamic_lib') {
        print STDOUT "Warning (non-fatal): Target '\$(INST_DYNAMIC)' depends on ",
	"targets in skipped section 'dynamic_bs'\n"
            if $self->{SKIPHASH}{dynamic_bs} && $ExtUtils::MakeMaker::Verbose;
    }
    if ($section eq 'static') {
        print STDOUT "Warning (non-fatal): Target 'static' depends on targets ",
	"in skipped section 'static_lib'\n"
            if $self->{SKIPHASH}{static_lib} && $ExtUtils::MakeMaker::Verbose;
    }
    return 'skipped' if $self->{SKIPHASH}{$section};
    return '';
}

sub flush {
    my $self = shift;
    my($chunk);
    local *MAKE;
    print STDOUT "Writing $self->{MAKEFILE} for $self->{NAME}\n";

    unlink($self->{MAKEFILE}, "MakeMaker.tmp", $Is_VMS ? 'Descrip.MMS' : '');
    open MAKE, ">MakeMaker.tmp" or die "Unable to open MakeMaker.tmp: $!";

    for $chunk (@{$self->{RESULT}}) {
	print MAKE "$chunk\n";
    }

    close MAKE;
    my($finalname) = $self->{MAKEFILE};
    rename("MakeMaker.tmp", $finalname);
    chmod 0644, $finalname unless $Is_VMS;
    system("$Config::Config{eunicefix} $finalname") unless $Config::Config{eunicefix} eq ":";
}

sub Version_check {
    my($checkversion) = @_;
    die "Your Makefile was built with ExtUtils::MakeMaker v $checkversion.
Current Version is $ExtUtils::MakeMaker::VERSION. There have been considerable
changes in the meantime.
Please rerun 'perl Makefile.PL' to regenerate the Makefile.\n"
    if $checkversion lt $ExtUtils::MakeMaker::Version_OK;
    printf STDOUT "%s %s %s %s.\n", "Makefile built with ExtUtils::MakeMaker v",
    $checkversion, "Current Version is", $ExtUtils::MakeMaker::VERSION
	unless $checkversion == $ExtUtils::MakeMaker::VERSION;
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
    return "'$v'" unless $t;
    if ($t eq 'ARRAY') {
	my(@m, $elem, @neat);
	push @m, "[";
	foreach $elem (@$v) {
	    push @neat, "'$elem'";
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
    if ($ExtUtils::MakeMaker::Verbose){
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


 #     # #     #         #     #
 ##   ## ##   ##         #     #  #    #     #    #    #
 # # # # # # # #         #     #  ##   #     #     #  #
 #  #  # #  #  #         #     #  # #  #     #      ##
 #     # #     #         #     #  #  # #     #      ##
 #     # #     #         #     #  #   ##     #     #  #
 #     # #     # #######  #####   #    #     #    #    #

package ExtUtils::MM_Unix;

use Config;
use Cwd;
use File::Basename;
require Exporter;

Exporter::import('ExtUtils::MakeMaker',
	qw( $Verbose &neatvalue));

# These attributes cannot be overridden externally
@Other_Att_Keys{qw(EXTRALIBS BSLOADLIBS LDLOADLIBS)} = (1) x 3;

if ($Is_VMS = $Config::Config{osname} eq 'VMS') {
    require VMS::Filespec;
    import VMS::Filespec qw( &vmsify );
}

$Is_OS2 = $ExtUtils::MakeMaker::Is_OS2;

sub guess_name {
    my($self) = @_;
    my $name = fastcwd();
    $name =~ s:.*/:: unless ($name =~ s:^.*/ext/::);
    $name =~ s#/#::#g;
    $name =~  s#[\-_][\d.\-]+$##;  # this is new with MM 5.00
    $name;
}

sub init_main {
    my($self) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }

    # --- Initialize Module Name and Paths

    # NAME    = The perl module name for this extension (eg DBD::Oracle).
    # FULLEXT = Pathname for extension directory (eg DBD/Oracle).
    # BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT.
    # ROOTEXT = Directory part of FULLEXT with leading /.
    ($self->{FULLEXT} =
     $self->{NAME}) =~ s!::!/!g ;		             #eg. BSD/Foo/Socket

    # Copied from DynaLoader:

    my(@modparts) = split(/::/,$self->{NAME});
    my($modfname) = $modparts[-1];

    # Some systems have restrictions on files names for DLL's etc.
    # mod2fname returns appropriate file base name (typically truncated)
    # It may also edit @modparts if required.
    if (defined &DynaLoader::mod2fname) {
        $modfname = &DynaLoader::mod2fname(\@modparts);
    } elsif ($Is_OS2) {                # Need manual correction if run with miniperl:-(
        $modfname = substr($modfname, 0, 7) . '_';
    }


    ($self->{BASEEXT} =
     $self->{NAME}) =~ s!.*::!! ;		             #eg. Socket

    if (defined &DynaLoader::mod2fname or $Is_OS2) {
	# As of 5.001m, dl_os2 appends '_'
	$self->{DLBASE} = $modfname;                    #eg. Socket_
    } else {
	$self->{DLBASE} = '$(BASEEXT)';
    }

    ($self->{ROOTEXT} =
     $self->{FULLEXT}) =~ s#/?\Q$self->{BASEEXT}\E$## ;      #eg. /BSD/Foo

    $self->{ROOTEXT} = ($Is_VMS ? '' : '/') . $self->{ROOTEXT} if $self->{ROOTEXT};


    # --- Initialize PERL_LIB, INST_LIB, PERL_SRC

    # *Real* information: where did we get these two from? ...
    my $inc_config_dir = dirname($INC{'Config.pm'});
    my $inc_carp_dir   = dirname($INC{'Carp.pm'});

    # Typically PERL_* and INST_* will be identical but that need
    # not be the case (e.g., installing into project libraries etc).

    # Perl Macro:    With source    No source
    # PERL_SRC       ../..          (undefined)
    # PERL_LIB       PERL_SRC/lib   $Config{privlibexp}
    # PERL_ARCHLIB   PERL_SRC/lib   $Config{archlibexp}

    # INST Macro:    For standard   for any other
    #                modules        module
    # INST_LIB       PERL_SRC/lib   ./blib
    # INST_ARCHLIB   PERL_SRC/lib   ./blib/<archname>

    unless ($self->{PERL_SRC}){
	my($dir);
	foreach $dir (qw(.. ../.. ../../..)){
	    if ( -f "$dir/config.sh"
		&& -f "$dir/perl.h"
		&& -f "$dir/lib/Exporter.pm") {
		$self->{PERL_SRC}=$dir ;
		last;
	    }
	}
    }
    if ($self->{PERL_SRC}){
	$self->{PERL_LIB}     ||= $self->catdir("$self->{PERL_SRC}","lib");
	$self->{PERL_ARCHLIB} = $self->{PERL_LIB};
	$self->{PERL_INC}     = $self->{PERL_SRC};
	# catch a situation that has occurred a few times in the past:
	warn <<EOM unless -s "$self->{PERL_SRC}/cflags";
You cannot build extensions below the perl source tree after executing
a 'make clean' in the perl source tree.

To rebuild extensions distributed with the perl source you should
simply Configure (to include those extensions) and then build perl as
normal. After installing perl the source tree can be deleted. It is not
needed for building extensions.

It is recommended that you unpack and build additional extensions away
from the perl source tree.
EOM
    } else {
	# we should also consider $ENV{PERL5LIB} here
	$self->{PERL_LIB}     = $Config::Config{privlibexp} unless $self->{PERL_LIB};
	$self->{PERL_ARCHLIB} = $Config::Config{archlibexp} unless $self->{PERL_ARCHLIB};
	$self->{PERL_INC}     = $self->catdir("$self->{PERL_ARCHLIB}","CORE"); # wild guess for now
	my $perl_h;
	die <<EOM unless (-f ($perl_h = $self->catfile("$self->{PERL_INC}","perl.h")));
Error: Unable to locate installed Perl libraries or Perl source code.

It is recommended that you install perl in a standard location before
building extensions. You can say:

    $^X Makefile.PL PERL_SRC=/path/to/perl/source/directory

if you have not yet installed perl but still want to build this
extension now.
(You get this message, because MakeMaker could not find "$perl_h")
EOM

#	 print STDOUT "Using header files found in $self->{PERL_INC}\n"
#	     if $Verbose && $self->needs_linking();

    }

    # INST_LIB typically pre-set if building an extension after
    # perl has been built and installed. Setting INST_LIB allows
    # you to build directly into, say $Config::Config{privlibexp}.
    unless ($self->{INST_LIB}){


	##### XXXXX We have to change this nonsense

	if (defined $self->{PERL_SRC}) {
	    $self->{INST_LIB} = $self->{PERL_LIB};
	} else {
	    $self->{INST_LIB} = $self->catdir(".","blib");
	}
    }
    # Try to work out what INST_ARCHLIB should be if not set:
    unless ($self->{INST_ARCHLIB}){
	my(%archmap) = (
			# our private build lib
	    $self->catdir(".","blib") 	=>
			$self->catdir(".","blib",$Config::Config{archname}),
	    $self->{PERL_LIB}	=> $self->{PERL_ARCHLIB},
	    $Config::Config{privlibexp}	=> $Config::Config{archlibexp},
	    $inc_carp_dir	=> $inc_config_dir,
	);
	$self->{INST_ARCHLIB} = $archmap{$self->{INST_LIB}};
	unless($self->{INST_ARCHLIB}){
	    # Oh dear, we'll have to default it and warn the user
	    my($archname) = $Config::Config{archname};
	    if (-d "$self->{INST_LIB}/$archname"){
		$self->{INST_ARCHLIB} = $self->catdir("$self->{INST_LIB}","$archname");
		print STDOUT "Defaulting INST_ARCHLIB to $self->{INST_ARCHLIB}\n";
	    } else {
		$self->{INST_ARCHLIB} = $self->{INST_LIB};
	    }
	}
    }
    $self->{INST_EXE} ||= $self->catdir('.','blib',$Config::Config{archname});

    my($prefix) = $Config{'prefix'};
    $prefix = VMS::Filespec::unixify($prefix) if $Is_VMS;
    unless ($self->{PREFIX}){
	$self->{PREFIX} = $prefix;
    }
# With perl5.002 it turns out, that we hardcoded some assumptions in here:
#	$self->{INSTALLPRIVLIB} = $self->catdir($self->{PREFIX},"lib","perl5");
#	$self->{INSTALLBIN} = $self->catdir($self->{PREFIX},"bin");
#	$self->{INSTALLMAN3DIR} = $self->catdir($self->{PREFIX},"perl5","man","man3")
#	    unless defined $self->{INSTALLMAN3DIR};

    # we have to look at the relation between $Config{prefix} and
    # the requested values
    $self->{INSTALLPRIVLIB} = $Config{installprivlib};
    $self->{INSTALLPRIVLIB} = VMS::Filespec::unixpath($self->{INSTALLPRIVLIB})
      if $Is_VMS;
    $self->{INSTALLPRIVLIB} =~ s/\Q$prefix\E/\$(PREFIX)/;
    $self->{INSTALLBIN} = $Config{installbin};
    $self->{INSTALLBIN} = VMS::Filespec::unixpath($self->{INSTALLBIN})
      if $Is_VMS;
    $self->{INSTALLBIN} =~ s/\Q$prefix\E/\$(PREFIX)/;
    $self->{INSTALLMAN1DIR} = $Config{installman1dir};
    $self->{INSTALLMAN1DIR} = VMS::Filespec::unixpath($self->{INSTALLMAN1DIR})
      if $Is_VMS;
    $self->{INSTALLMAN1DIR} =~ s/\Q$prefix\E/\$(PREFIX)/;
    $self->{INSTALLMAN3DIR} = $Config{installman3dir};
    $self->{INSTALLMAN3DIR} = VMS::Filespec::unixpath($self->{INSTALLMAN3DIR})
      if $Is_VMS;
    $self->{INSTALLMAN3DIR} =~ s/\Q$prefix\E/\$(PREFIX)/;

    if( $self->{INSTALLPRIVLIB} && ! $self->{INSTALLARCHLIB} ){
# Same as above here. With the unresolved versioned directory issue, we have to
# be more careful to follow Configure
#	my($archname) = $Config::Config{archname};
#	if (-d $self->catdir($self->{INSTALLPRIVLIB},$archname)){
#	    $self->{INSTALLARCHLIB} = $self->catdir($self->{INSTALLPRIVLIB},$archname);
#	    print STDOUT "Defaulting INSTALLARCHLIB to $self->{INSTALLARCHLIB}\n";
#	} else {
#	    $self->{INSTALLARCHLIB} = $self->{INSTALLPRIVLIB};
#	}
	my($installprivlib) = $Config{'installprivlib'};
	$installprivlib = VMS::Filespec::unixify($installprivlib) if $Is_VMS;
	$self->{INSTALLARCHLIB} = $Config{installarchlib};
	$self->{INSTALLARCHLIB} = VMS::Filespec::unixpath($self->{INSTALLARCHLIB})
	   if $Is_VMS;
	$self->{INSTALLARCHLIB} =~ s/\Q$installprivlib\E/$self->{INSTALLPRIVLIB}/;

	# It's a pain to be so friendly to the user. I wish we wouldn't have been so nice.
	# Now we have '$(PREFIX)' in the string, and the directory won't exist
	my($installarchlib);
	($installarchlib = $self->{INSTALLARCHLIB}) =~ s/\$\(PREFIX\)/$self->{PREFIX}/;
	if (-d $installarchlib) {
	} else {
	    print STDOUT "Directory $self->{INSTALLARCHLIB} not found, thusly\n" if $Verbose;
	    $self->{INSTALLARCHLIB} = $self->{INSTALLPRIVLIB};
	}
	print STDOUT "Defaulting INSTALLARCHLIB to $self->{INSTALLARCHLIB}\n" if $Verbose;
    }

    $self->{INSTALLPRIVLIB} ||= $Config::Config{installprivlib};
    $self->{INSTALLARCHLIB} ||= $Config::Config{installarchlib};
    $self->{INSTALLBIN}     ||= $Config::Config{installbin};

    $self->{INSTALLMAN1DIR} = $Config::Config{installman1dir}
	unless defined $self->{INSTALLMAN1DIR};
    unless (defined $self->{INST_MAN1DIR}){
	if ($self->{INSTALLMAN1DIR} =~ /^(none|\s*)$/){
	    $self->{INST_MAN1DIR} = $self->{INSTALLMAN1DIR};
	} else {
	    $self->{INST_MAN1DIR} = $self->catdir('.','blib','man','man1');
	}
    }
    $self->{MAN1EXT} ||= $Config::Config{man1ext};

    $self->{INSTALLMAN3DIR} = $Config::Config{installman3dir}
	unless defined $self->{INSTALLMAN3DIR};
    unless (defined $self->{INST_MAN3DIR}){
	if ($self->{INSTALLMAN3DIR} =~ /^(none|\s*)$/){
	    $self->{INST_MAN3DIR} = $self->{INSTALLMAN3DIR};
	} else {
	    $self->{INST_MAN3DIR} = $self->catdir('.','blib','man','man3');
	}
    }
    $self->{MAN3EXT} ||= $Config::Config{man3ext};

    print STDOUT "CONFIG must be an array ref\n"
	if ($self->{CONFIG} and ref $self->{CONFIG} ne 'ARRAY');
    $self->{CONFIG} = [] unless (ref $self->{CONFIG});
    push(@{$self->{CONFIG}}, @ExtUtils::MakeMaker::Get_from_Config);
    push(@{$self->{CONFIG}}, 'shellflags') if $Config::Config{shellflags};
    my(%once_only,$m);
    foreach $m (@{$self->{CONFIG}}){
	next if $once_only{$m};
	print STDOUT "CONFIG key '$m' does not exist in Config.pm\n"
		unless exists $Config::Config{$m};
	$self->{uc $m} ||= $Config::Config{$m};
	$once_only{$m} = 1;
    }

    # These should never be needed
    $self->{LD} ||= 'ld';
    $self->{OBJ_EXT} ||= '.o';
    $self->{LIB_EXT} ||= '.a';

    $self->{MAP_TARGET} ||= "perl";

    unless ($self->{LIBPERL_A}){
	$self->{LIBPERL_A} = "libperl$self->{LIB_EXT}";
    }

    # make a few simple checks
    warn "Warning: PERL_LIB ($self->{PERL_LIB}) seems not to be a perl library directory
        (Exporter.pm not found)"
	unless (-f $self->catfile("$self->{PERL_LIB}","Exporter.pm"));

    ($self->{DISTNAME}=$self->{NAME}) =~ s#(::)#-#g unless $self->{DISTNAME};
    if ($self->{VERSION_FROM}){
	local *PM;
	open PM, $self->{VERSION_FROM} or die "Could not open '$self->{VERSION_FROM}' (attribute VERSION_FROM): $!";
	while (<PM>) {
	    chop;
	    next unless /\$([\w:]*\bVERSION)\b.*=/;
	    local $ExtUtils::MakeMaker::module_version_variable = $1;
	    my($eval) = "$_;";
	    eval $eval;
	    die "Could not eval '$eval': $@" if $@;
	    if ($self->{VERSION} = $$ExtUtils::MakeMaker::module_version_variable){
		print "Setting VERSION to $self->{VERSION}\n" if $Verbose;
	    } else {
		print "WARNING: Setting VERSION via file '$self->{VERSION_FROM}' failed\n";
	    }
	    last;
	}
	close PM;
    }
    $self->{VERSION} = "0.10" unless $self->{VERSION};
    ($self->{VERSION_SYM} = $self->{VERSION}) =~ s/\W/_/g;

    # Graham Barr and Paul Marquess had some ideas how to ensure
    # version compatibility between the *.pm file and the
    # corresponding *.xs file. The bottomline was, that we need an
    # XS_VERSION macro that defaults to VERSION:
    $self->{XS_VERSION} ||= $self->{VERSION};

    # --- Initialize Perl Binary Locations

    # Find Perl 5. The only contract here is that both 'PERL' and 'FULLPERL'
    # will be working versions of perl 5. miniperl has priority over perl
    # for PERL to ensure that $(PERL) is usable while building ./ext/*
    my ($component,@defpath);
    foreach $component ($self->{PERL_SRC}, $self->path(), $Config::Config{binexp}) {
	push @defpath, $component if defined $component;
    }
    $self->{PERL} =
        $self->find_perl(5.0, [ $^X, 'miniperl','perl','perl5',"perl$]" ],
	    \@defpath, $ExtUtils::MakeMaker::Verbose ) unless ($self->{PERL});
# don't check, if perl is executable, maybe they
# have decided to supply switches with perl

    # Define 'FULLPERL' to be a non-miniperl (used in test: target)
    ($self->{FULLPERL} = $self->{PERL}) =~ s/miniperl/perl/i
	unless ($self->{FULLPERL});
}

# Ilya's suggestion, will have to go into ExtUtils::MM_OS2 and MM_VMS
sub path {
    my($self) = @_;
    my $path_sep = $Is_OS2 ? ";" : $Is_VMS ? "/" : ":";
    my $path = $ENV{PATH};
    $path =~ s:\\:/:g if $Is_OS2;
    my @path = split $path_sep, $path;
}

sub init_dirscan {	# --- File and Directory Lists (.xs .pm .pod etc)
    my($self) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my($name, %dir, %xs, %c, %h, %ignore, %pl_files, %manifypods);
    local(%pm); #the sub in find() has to see this hash
    $ignore{'test.pl'} = 1;
    $ignore{'makefile.pl'} = 1 if $Is_VMS;
    foreach $name ($self->lsdir(".")){
	next if ($name =~ /^\./ or $ignore{$name});
	if (-d $name){
	    $dir{$name} = $name if (-f "$name/Makefile.PL");
	} elsif ($name =~ /\.xs$/){
	    my($c); ($c = $name) =~ s/\.xs$/.c/;
	    $xs{$name} = $c;
	    $c{$c} = 1;
	} elsif ($name =~ /\.c$/i){
	    $c{$name} = 1
		unless $name =~ m/perlmain\.c/; # See MAP_TARGET
	} elsif ($name =~ /\.h$/i){
	    $h{$name} = 1;
	} elsif ($name =~ /\.(p[ml]|pod)$/){
	    $pm{$name} = $self->catfile('$(INST_LIBDIR)',$name);
	} elsif ($name =~ /\.PL$/ && $name ne "Makefile.PL") {
	    ($pl_files{$name} = $name) =~ s/\.PL$// ;
	} elsif ($Is_VMS && $name =~ /\.pl$/ && $name ne 'makefile.pl' &&
	         $name ne 'test.pl') {  # case-insensitive filesystem
	    ($pl_files{$name} = $name) =~ s/\.pl$// ;
	}
    }

    # Some larger extensions often wish to install a number of *.pm/pl
    # files into the library in various locations.

    # The attribute PMLIBDIRS holds an array reference which lists
    # subdirectories which we should search for library files to
    # install. PMLIBDIRS defaults to [ 'lib', $self->{BASEEXT} ].  We
    # recursively search through the named directories (skipping any
    # which don't exist or contain Makefile.PL files).

    # For each *.pm or *.pl file found $self->libscan() is called with
    # the default installation path in $_[1]. The return value of
    # libscan defines the actual installation location.  The default
    # libscan function simply returns the path.  The file is skipped
    # if libscan returns false.

    # The default installation location passed to libscan in $_[1] is:
    #
    #  ./*.pm		=> $(INST_LIBDIR)/*.pm
    #  ./xyz/...	=> $(INST_LIBDIR)/xyz/...
    #  ./lib/...	=> $(INST_LIB)/...
    #
    # In this way the 'lib' directory is seen as the root of the actual
    # perl library whereas the others are relative to INST_LIBDIR
    # (which includes ROOTEXT). This is a subtle distinction but one
    # that's important for nested modules.

    $self->{PMLIBDIRS} = ['lib', $self->{BASEEXT}]
	unless $self->{PMLIBDIRS};

    #only existing directories that aren't in $dir are allowed

    # Avoid $_ wherever possible:
    # @{$self->{PMLIBDIRS}} = grep -d && !$dir{$_}, @{$self->{PMLIBDIRS}};
    my (@pmlibdirs) = @{$self->{PMLIBDIRS}};
    my ($pmlibdir);
    @{$self->{PMLIBDIRS}} = ();
    foreach $pmlibdir (@pmlibdirs) {
	-d $pmlibdir && !$dir{$pmlibdir} && push @{$self->{PMLIBDIRS}}, $pmlibdir;
    }

    if (@{$self->{PMLIBDIRS}}){
	print "Searching PMLIBDIRS: @{$self->{PMLIBDIRS}}\n"
	    if ($ExtUtils::MakeMaker::Verbose >= 2);
	use File::Find;		# try changing to require !
	File::Find::find(sub {
	    if (-d $_){
		if ($_ eq "CVS" || $_ eq "RCS"){
		    $File::Find::prune = 1;
		}
		return;
	    }
	    my($path, $prefix) = ($File::Find::name, '$(INST_LIBDIR)');
	    my($striplibpath,$striplibname);
	    $prefix =  '$(INST_LIB)' if (($striplibpath = $path) =~ s:^(\W*)lib\W:$1:);
	    ($striplibname,$striplibpath) = fileparse($striplibpath);
	    my($inst) = $self->catfile($prefix,$striplibpath,$striplibname);
	    local($_) = $inst; # for backwards compatibility
	    $inst = $self->libscan($inst);
	    print "libscan($path) => '$inst'\n" if ($ExtUtils::MakeMaker::Verbose >= 2);
	    return unless $inst;
	    $pm{$path} = $inst;
	}, @{$self->{PMLIBDIRS}});
    }

    $self->{DIR} = [sort keys %dir] unless $self->{DIR};
    $self->{XS}  = \%xs             unless $self->{XS};
    $self->{PM}  = \%pm             unless $self->{PM};
    $self->{C}   = [sort keys %c]   unless $self->{C};
    my(@o_files) = @{$self->{C}};
    $self->{O_FILES} = [grep s/\.c$/$self->{OBJ_EXT}/i, @o_files] ;
    $self->{H}   = [sort keys %h]   unless $self->{H};
    $self->{PL_FILES} = \%pl_files unless $self->{PL_FILES};

    # Set up names of manual pages to generate from pods
    if ($self->{MAN1PODS}) {
    } elsif ( $self->{INST_MAN1DIR} =~ /^(none|\s*)$/ ) {
    	$self->{MAN1PODS} = {};
    } else {
	my %manifypods = ();
	if ( exists $self->{EXE_FILES} ) {
	    foreach $name (@{$self->{EXE_FILES}}) {
		local(*TESTPOD);
		my($ispod)=0;
		# one day test, if $/ can be set to '' safely (is the bug fixed that was in 5.001m?)
		if (open(TESTPOD,"<$name")) {
		    my $testpodline;
		    while ($testpodline = <TESTPOD>) {
			if($testpodline =~ /^=head1\s+\w+/) {
			    $ispod=1;
			    last;
			}
		    }
		    close(TESTPOD);
		} else {
		    # If it doesn't exist yet, we assume, it has pods in it
		    $ispod = 1;
		}
		if( $ispod ) {
		    $manifypods{$name} = $self->catfile('$(INST_MAN1DIR)',basename($name).'.$(MAN1EXT)');
		}
	    }
	}
	$self->{MAN1PODS} = \%manifypods;
    }
    if ($self->{MAN3PODS}) {
    } elsif ( $self->{INST_MAN3DIR} =~ /^(none|\s*)$/ ) {
    	$self->{MAN3PODS} = {};
    } else {
	my %manifypods = (); # we collect the keys first, i.e. the files
			     # we have to convert to pod
	foreach $name (keys %{$self->{PM}}) {
	    if ($name =~ /\.pod$/ ) {
		$manifypods{$name} = $self->{PM}{$name};
	    } elsif ($name =~ /\.p[ml]$/ ) {
		local(*TESTPOD);
		my($ispod)=0;
		open(TESTPOD,"<$name");
		my $testpodline;
		while ($testpodline = <TESTPOD>) {
		    if($testpodline =~ /^=head/) {
			$ispod=1;
			last;
		    }
		    #Speculation on the future (K.A., not A.K. :)
		    #if(/^=don't\S+install/) { $ispod=0; last}
		}
		close(TESTPOD);

		if( $ispod ) {
		    $manifypods{$name} = $self->{PM}{$name};
		}
	    }
	}

	# Remove "Configure.pm" and similar, if it's not the only pod listed
	# To force inclusion, just name it "Configure.pod", or override MAN3PODS
	foreach $name (keys %manifypods) {
	    if ($name =~ /(config|install|setup).*\.pm/i) {
		delete $manifypods{$name};
		next;
	    }
	    my($manpagename) = $name;
	    unless ($manpagename =~ s!^(\W*)lib\W!$1!) {
		$manpagename = $self->catfile($self->{ROOTEXT},$manpagename);
	    }
	    $manpagename =~ s/\.p(od|m|l)$//;
	    # Strip leading slashes
	    $manpagename =~ s!^/+!!;
	    # Turn other slashes into colons
#	    $manpagename =~ s,/+,::,g;
	    $manpagename = $self->replace_manpage_separator($manpagename);
	    $manifypods{$name} = $self->catfile("\$(INST_MAN3DIR)","$manpagename.\$(MAN3EXT)");
	}
	$self->{MAN3PODS} = \%manifypods;
    }
}

sub lsdir {
    my($self) = shift;
    my($dir, $regex) = @_;
    local(*DIR, @ls);
    opendir(DIR, $dir || ".") or return ();
    @ls = readdir(DIR);
    closedir(DIR);
    @ls = grep(/$regex/, @ls) if $regex;
    @ls;
}

sub replace_manpage_separator {
    my($self,$man) = @_;
    $man =~ s,/+,::,g;
    $man;
}

sub libscan {
    my($self,$path) = @_;
    return '' if $path =~ m:/(RCS|SCCS)/: ;
    $path;
}

sub init_others {	# --- Initialize Other Attributes
    my($self) = shift;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }

    # Compute EXTRALIBS, BSLOADLIBS and LDLOADLIBS from $self->{LIBS}
    # Lets look at $self->{LIBS} carefully: It may be an anon array, a string or
    # undefined. In any case we turn it into an anon array:

    # May check $Config{libs} too, thus not empty.
    $self->{LIBS}=[''] unless $self->{LIBS}; 

    $self->{LIBS}=[$self->{LIBS}] if ref \$self->{LIBS} eq SCALAR;
    $self->{LD_RUN_PATH} = "";
    my($libs);
    foreach $libs ( @{$self->{LIBS}} ){
	$libs =~ s/^\s*(.*\S)\s*$/$1/; # remove leading and trailing whitespace
	my(@libs) = $self->extliblist($libs);
	if ($libs[0] or $libs[1] or $libs[2]){
	    # LD_RUN_PATH now computed by ExtUtils::Liblist
	    ($self->{EXTRALIBS}, $self->{BSLOADLIBS}, $self->{LDLOADLIBS}, $self->{LD_RUN_PATH}) = @libs;
	    last;
	}
    }

    unless ( $self->{OBJECT} ){
	# init_dirscan should have found out, if we have C files
	$self->{OBJECT} = '$(BASEEXT)$(OBJ_EXT)' if @{$self->{C}||[]};
    }
    $self->{OBJECT} =~ s/\n+/ \\\n\t/g;
    $self->{BOOTDEP}  = (-f "$self->{BASEEXT}_BS") ? "$self->{BASEEXT}_BS" : "";
    $self->{PERLMAINCC} ||= '$(CC)';
    $self->{LDFROM} = '$(OBJECT)' unless $self->{LDFROM};

    # Sanity check: don't define LINKTYPE = dynamic if we're skipping
    # the 'dynamic' section of MM.  We don't have this problem with
    # 'static', since we either must use it (%Config says we can't
    # use dynamic loading) or the caller asked for it explicitly.
    if (!$self->{LINKTYPE}) {
       $self->{LINKTYPE} = grep(/dynamic/,@{$self->{SKIP} || []})
                        ? 'static'
                        : ($Config::Config{usedl} ? 'dynamic' : 'static');
    };

    # These get overridden for VMS and maybe some other systems
    $self->{NOOP}  ||= "";
    $self->{FIRST_MAKEFILE} ||= "Makefile";
    $self->{MAKEFILE} ||= $self->{FIRST_MAKEFILE};
    $self->{MAKE_APERL_FILE} ||= "Makefile.aperl";
    $self->{NOECHO} ||= '@';
    $self->{RM_F}  ||= "rm -f";
    $self->{RM_RF} ||= "rm -rf";
    $self->{TOUCH} ||= "touch";
    $self->{CP} ||= "cp";
    $self->{MV} ||= "mv";
    $self->{CHMOD} ||= "chmod";
    $self->{UMASK_NULL} ||= "umask 0";
}

sub find_perl {
    my($self, $ver, $names, $dirs, $trace) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my($name, $dir);
    if ($trace >= 2){
	print "Looking for perl $ver by these names:
@$names
in these dirs:
@$dirs
";
    }
    foreach $dir (@$dirs){
	next unless defined $dir; # $self->{PERL_SRC} may be undefined
	foreach $name (@$names){
	    my $abs;
	    if ($self->file_name_is_absolute($name)) {
		$abs = $name;
	    } elsif (($name =~ m|/|) && ($name !~ m|^\.{1,2}/|)) {
		# name is a path that does not begin with dot or dotdot
		$abs = $self->catfile(".", $name);
	    } else {
		$abs = $self->catfile($dir, $name);
	    }
	    print "Checking $abs\n" if ($trace >= 2);
	    next unless $self->maybe_command($abs);
	    print "Executing $abs\n" if ($trace >= 2);
	    if (`$abs -e 'require $ver; print "VER_OK\n" ' 2>&1` =~ /VER_OK/) {
	        print "Using PERL=$abs\n" if $trace;
	        return $abs;
	    }
	}
    }
    print STDOUT "Unable to find a perl $ver (by these names: @$names, in these dirs: @$dirs)\n";
    0; # false and not empty
}


# Ilya's suggestion. Not yet used, want to understand it first, but at least the code is here
sub maybe_command_in_dirs {	# $ver is optional argument if looking for perl
    my($self, $names, $dirs, $trace, $ver) = @_;
    my($name, $dir);
    foreach $dir (@$dirs){
	next unless defined $dir; # $self->{PERL_SRC} may be undefined
	foreach $name (@$names){
	    my($abs,$tryabs);
	    if ($self->file_name_is_absolute($name)) {
		$abs = $name;
	    } elsif ($name =~ m|/|) {
		$abs = $self->catfile(".", $name); # not absolute
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

sub maybe_command {
    my($self,$file) = @_;
    return $file if -x $file && ! -d $file;
    return;
}

sub perl_script {
    my($self,$file) = @_;
    return 1 if -r $file && ! -d $file;
    return;
}

# Ilya's suggestion, not yet used
sub file_name_is_absolute {
    my($self,$file) = @_;
    $file =~ m:^/: ;
}

sub post_initialize {
    my($self) = shift;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    "";
}

# --- Constants Sections ---

sub const_config {
    my($self) = shift;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my(@m,$m);
    push(@m,"\n# These definitions are from config.sh (via $INC{'Config.pm'})\n");
    push(@m,"\n# They may have been overridden via Makefile.PL or on the command line\n");
    my(%once_only);
    foreach $m (@{$self->{CONFIG}}){
	next if $once_only{$m};
	push @m, "\U$m\E = ".$self->{uc $m}."\n";
	$once_only{$m} = 1;
    }
    join('', @m);
}

sub constants {
    my($self) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my(@m,$tmp);

    push @m, "
NAME = $self->{NAME}
DISTNAME = $self->{DISTNAME}
NAME_SYM = $self->{NAME_SYM}
VERSION = $self->{VERSION}
VERSION_SYM = $self->{VERSION_SYM}
VERSION_MACRO = VERSION
DEFINE_VERSION = -D\$(VERSION_MACRO)=\\\"\$(VERSION)\\\"
XS_VERSION = $self->{XS_VERSION}
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = -D\$(XS_VERSION_MACRO)=\\\"\$(XS_VERSION)\\\"

# In which directory should we put this extension during 'make'?
# This is typically ./blib.
# (also see INST_LIBDIR and relationship to ROOTEXT)
INST_LIB = $self->{INST_LIB}
INST_ARCHLIB = $self->{INST_ARCHLIB}
INST_EXE = $self->{INST_EXE}

PREFIX = $self->{PREFIX}

# AFS users will want to set the installation directories for
# the final 'make install' early without setting INST_LIB,
# INST_ARCHLIB, and INST_EXE for the testing phase
INSTALLPRIVLIB = $self->{INSTALLPRIVLIB}
INSTALLARCHLIB = $self->{INSTALLARCHLIB}
INSTALLBIN = $self->{INSTALLBIN}

# Perl library to use when building the extension
PERL_LIB = $self->{PERL_LIB}
PERL_ARCHLIB = $self->{PERL_ARCHLIB}
LIBPERL_A = $self->{LIBPERL_A}

MAKEMAKER = \$(PERL_LIB)/ExtUtils/MakeMaker.pm
MM_VERSION = $ExtUtils::MakeMaker::VERSION
FIRST_MAKEFILE  = $self->{FIRST_MAKEFILE}
MAKE_APERL_FILE = $self->{MAKE_APERL_FILE}

PERLMAINCC = $self->{PERLMAINCC}
";

    push @m, "
# Where is the perl source code located?
PERL_SRC = $self->{PERL_SRC}\n" if $self->{PERL_SRC};

    push @m, "
# Perl header files (will eventually be under PERL_LIB)
PERL_INC = $self->{PERL_INC}
# Perl binaries
PERL = $self->{PERL}
FULLPERL = $self->{FULLPERL}
";
    push @m, "
# FULLEXT = Pathname for extension directory (eg DBD/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT.
# ROOTEXT = Directory part of FULLEXT with leading slash (eg /DBD)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
FULLEXT = $self->{FULLEXT}
BASEEXT = $self->{BASEEXT}
ROOTEXT = $self->{ROOTEXT}
DLBASE  = $self->{DLBASE}
";

    push @m, "
VERSION_FROM = $self->{VERSION_FROM}
" if defined $self->{VERSION_FROM};

    push @m, "
INC = $self->{INC}
DEFINE = $self->{DEFINE}
OBJECT = $self->{OBJECT}
LDFROM = $self->{LDFROM}
LINKTYPE = $self->{LINKTYPE}

# Handy lists of source code files:
XS_FILES= ".join(" \\\n\t", sort keys %{$self->{XS}})."
C_FILES = ".join(" \\\n\t", @{$self->{C}})."
O_FILES = ".join(" \\\n\t", @{$self->{O_FILES}})."
H_FILES = ".join(" \\\n\t", @{$self->{H}})."
MAN1PODS = ".join(" \\\n\t", sort keys %{$self->{MAN1PODS}})."
MAN3PODS = ".join(" \\\n\t", sort keys %{$self->{MAN3PODS}})."

# Man installation stuff:
INST_MAN1DIR	= $self->{INST_MAN1DIR}
INSTALLMAN1DIR	= $self->{INSTALLMAN1DIR}
MAN1EXT	= $self->{MAN1EXT}

INST_MAN3DIR	= $self->{INST_MAN3DIR}
INSTALLMAN3DIR	= $self->{INSTALLMAN3DIR}
MAN3EXT	= $self->{MAN3EXT}


# work around a famous dec-osf make(1) feature(?):
makemakerdflt: all

.SUFFIXES: .xs .c .C \$(OBJ_EXT)

# .PRECIOUS: Makefile    # seems to be not necessary anymore

.PHONY: all config static dynamic test linkext

# This extension may link to it's own library (see SDBM_File)
MYEXTLIB = $self->{MYEXTLIB}

# Where is the Config information that we are using/depend on
CONFIGDEP = \$(PERL_ARCHLIB)/Config.pm \$(PERL_INC)/config.h \$(VERSION_FROM)
";

    push @m, '
# Where to put things:
INST_LIBDIR     = $(INST_LIB)$(ROOTEXT)
INST_ARCHLIBDIR = $(INST_ARCHLIB)$(ROOTEXT)

INST_AUTODIR      = $(INST_LIB)/auto/$(FULLEXT)
INST_ARCHAUTODIR  = $(INST_ARCHLIB)/auto/$(FULLEXT)
';

    if ($self->has_link_code()) {
	push @m, '
INST_STATIC  = $(INST_ARCHAUTODIR)/$(BASEEXT)$(LIB_EXT)
INST_DYNAMIC = $(INST_ARCHAUTODIR)/$(DLBASE).$(DLEXT)
INST_BOOT    = $(INST_ARCHAUTODIR)/$(BASEEXT).bs
';
    } else {
	push @m, '
INST_STATIC  =
INST_DYNAMIC =
INST_BOOT    =
';
    }

    if ($Is_OS2) {
	$tmp = "$self->{BASEEXT}.def";
    } else {
	$tmp = "";
    }
    push @m, "
EXPORT_LIST = $tmp
";

    if ($Is_OS2) {
	$tmp = "\$(PERL_INC)/libperl.lib";
    } else {
	$tmp = "";
    }
    push @m, "
PERL_ARCHIVE = $tmp
";

    push @m, '
INST_PM = '.join(" \\\n\t", sort values %{$self->{PM}}).'
';

    join('',@m);
}

sub const_loadlibs {
    my($self) = shift;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    return "" unless $self->needs_linking;
    # This description can be deleted after ExtUtils::Liblist is in
    # the perl dist with pods
    "
# $self->{NAME} might depend on some other libraries:
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
EXTRALIBS  = $self->{EXTRALIBS}
LDLOADLIBS = $self->{LDLOADLIBS}
BSLOADLIBS = $self->{BSLOADLIBS}
LD_RUN_PATH= $self->{LD_RUN_PATH}
";
}

sub const_cccmd {
    my($self,$libperl)=@_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    return $self->{CONST_CCCMD} if $self->{CONST_CCCMD};
    return '' unless $self->needs_linking();
    $libperl or $libperl = $self->{LIBPERL_A} || "libperl$self->{LIB_EXT}" ;
    $libperl =~ s/\.\$\(A\)$/$self->{LIB_EXT}/;
    # This is implemented in the same manner as extliblist,
    # e.g., do both and compare results during the transition period.
    my($cc,$ccflags,$optimize,$large,$split, $shflags)
	= @Config{qw(cc ccflags optimize large split shellflags)};
    my($optdebug) = "";

    $shflags = '' unless $shflags;
    my($prog, $uc, $perltype);

    my(%map) =  (
		D =>   '-DDEBUGGING',
		E =>   '-DEMBED',
		DE =>  '-DDEBUGGING -DEMBED',
		M =>   '-DEMBED -DMULTIPLICITY',
		DM =>  '-DDEBUGGING -DEMBED -DMULTIPLICITY',
		);

    if ($libperl =~ /libperl(\w*)\Q$self->{LIB_EXT}/){
	$uc = uc($1);
    } else {
	$uc = ""; # avoid warning
    }
    $perltype = $map{$uc} ? $map{$uc} : "";

    if ($uc =~ /^D/) {
	$optdebug = "-g";
    }


    my($name);
    ( $name = $self->{NAME} . "_cflags" ) =~ s/:/_/g ;
    if ($prog = $Config::Config{$name}) {
	# Expand hints for this extension via the shell
	print STDOUT "Processing $name hint:\n" if $ExtUtils::MakeMaker::Verbose;
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
		print STDOUT "	$1 = $2\n" if $ExtUtils::MakeMaker::Verbose;
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

    my($new) = "$cc -c \$(INC) $ccflags $optimize $perltype $large $split";
    $new =~ s/^\s+//; $new =~ s/\s+/ /g; $new =~ s/\s+$//;

    my($cccmd) = $new;
    $cccmd =~ s/^\s*\Q$Config::Config{cc}\E\s/\$(CC) /;
    $cccmd .= " \$(DEFINE_VERSION) \$(XS_DEFINE_VERSION)";
    $self->{CONST_CCCMD} = "CCCMD = $cccmd\n";
}

# --- Tool Sections ---

sub tool_autosplit {
    my($self, %attribs) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my($asl) = "";
    $asl = "\$AutoSplit::Maxlen=$attribs{MAXLEN};" if $attribs{MAXLEN};
    q{
# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -e 'use AutoSplit;}.$asl.q{autosplit($$ARGV[0], $$ARGV[1], 0, 1, 1) ;'
};
}

sub tool_xsubpp {
    my($self) = shift;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my($xsdir)  = "$self->{PERL_LIB}/ExtUtils";
    # drop back to old location if xsubpp is not in new location yet
    $xsdir = "$self->{PERL_SRC}/ext" unless (-f "$self->{PERL_LIB}/ExtUtils/xsubpp");
    my(@tmdeps) = ('$(XSUBPPDIR)/typemap');
    if( $self->{TYPEMAPS} ){
	my $typemap;
	foreach $typemap (@{$self->{TYPEMAPS}}){
		if( ! -f  $typemap ){
			warn "Typemap $typemap not found.\n";
		}
		else{
			push(@tmdeps,  $typemap);
		}
	}
    }
    push(@tmdeps, "typemap") if -f "typemap";
    my(@tmargs) = map("-typemap $_", @tmdeps);
    if( exists $self->{XSOPT} ){
 	unshift( @tmargs, $self->{XSOPT} );
    }

    my $xsubpp_version = $self->xsubpp_version("$xsdir/xsubpp");

    # What are the correct thresholds for version 1 && 2 Paul?
    if ( $xsubpp_version > 1.923 ){
	$self->{XSPROTOARG} = "" unless defined $self->{XSPROTOARG};
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
XSUBPPDIR = $xsdir
XSUBPP = \$(XSUBPPDIR)/xsubpp
XSPROTOARG = $self->{XSPROTOARG}
XSUBPPDEPS = @tmdeps
XSUBPPARGS = @tmargs
";
};

sub xsubpp_version
{
    my($self,$xsubpp) = @_;
    my ($version) ;

    # try to figure out the version number of the xsubpp on the system

    # first try the -v flag, introduced in 1.921 & 2.000a2

    my $command = "$self->{PERL} $xsubpp -v 2>&1";
    print "Running: $command\n" if $Verbose;
    $version = `$command` ;
    warn "Running '$command' exits with status " . ($?>>8) if $?;
    chop $version ;

    return $1 if $version =~ /^xsubpp version (.*)/ ;

    # nope, then try something else

    my $counter = '000';
    my ($file) = 'temp' ;
    $counter++ while -e "$file$counter"; # don't overwrite anything
    $file .= $counter;

    open(F, ">$file") or die "Cannot open file '$file': $!\n" ;
    print F <<EOM ;
MODULE = fred PACKAGE = fred

int
fred(a)
        int     a;
EOM

    close F ;

    $command = "$self->{PERL} $xsubpp $file 2>&1";
    print "Running: $command\n" if $Verbose;
    my $text = `$command` ;
    warn "Running '$command' exits with status " . ($?>>8) if $?;
    unlink $file ;

    # gets 1.2 -> 1.92 and 2.000a1
    return $1 if $text =~ /automatically by xsubpp version ([\S]+)\s*/  ;

    # it is either 1.0 or 1.1
    return 1.1 if $text =~ /^Warning: ignored semicolon/ ;

    # none of the above, so 1.0
    return "1.0" ;
}

sub tools_other {
    my($self) = shift;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    "
SHELL = /bin/sh
LD = $self->{LD}
TOUCH = $self->{TOUCH}
CP = $self->{CP}
MV = $self->{MV}
RM_F  = $self->{RM_F}
RM_RF = $self->{RM_RF}
CHMOD = $self->{CHMOD}
UMASK_NULL = $self->{UMASK_NULL}
".q{
# The following is a portable way to say mkdir -p
# To see which directories are created, change the if 0 to if 1
MKPATH = $(PERL) -wle '$$"="/"; foreach $$p (@ARGV){' \\
-e 'next if -d $$p; my(@p); foreach(split(/\//,$$p)){' \\
-e 'push(@p,$$_); next if -d "@p/"; print "mkdir @p" if 0;' \\
-e 'mkdir("@p",0777)||die $$! } } exit 0;'

# This helps us to minimize the effect of the .exists files A yet
# better solution would be to have a stable file in the perl
# distribution with a timestamp of zero. But this solution doesn't
# need any changes to the core distribution and works with older perls
EQUALIZE_TIMESTAMP = $(PERL) -we 'open F, ">$$ARGV[1]"; close F;' \\
-e 'utime ((stat("$$ARGV[0]"))[8,9], $$ARGV[1])'
};
}

sub dist {
    my($self, %attribs) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my(@m);
    # VERSION should be sanitised before use as a file name
    my($name)     = $attribs{NAME}     || '$(DISTVNAME)';
    my($tar)      = $attribs{TAR}      || 'tar';        # eg /usr/bin/gnutar
    my($tarflags) = $attribs{TARFLAGS} || 'cvf';
    my($compress) = $attribs{COMPRESS} || 'compress';   # eg gzip
    my($suffix)   = $attribs{SUFFIX}   || 'Z';          # eg gz
    my($shar)     = $attribs{SHAR}     || 'shar';       # eg "shar --gzip"
    my($preop)    = $attribs{PREOP}    || "$self->{NOECHO}true"; # eg update MANIFEST
    my($postop)   = $attribs{POSTOP}   || "$self->{NOECHO}true"; # eg remove the distdir
    my($ci)       = $attribs{CI}       || 'ci -u';
    my($rcs_label)= $attribs{RCS_LABEL}|| 'rcs -Nv$(VERSION_SYM): -q';
    my($dist_cp)  = $attribs{DIST_CP}  || 'best';
    my($dist_default) = $attribs{DIST_DEFAULT} || 'tardist';

    push @m, "
DISTVNAME = \$(DISTNAME)-\$(VERSION)
TAR  = $tar
TARFLAGS = $tarflags
COMPRESS = $compress
SUFFIX = $suffix
SHAR = $shar
PREOP = $preop
POSTOP = $postop
CI = $ci
RCS_LABEL = $rcs_label
DIST_CP = $dist_cp
DIST_DEFAULT = $dist_default
";
    join "", @m;
}

sub macro {
    my($self,%attribs) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my(@m,$key,$val);
    while (($key,$val) = each %attribs){
	push @m, "$key = $val\n";
    }
    join "", @m;
}

sub depend {
    my($self,%attribs) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my(@m,$key,$val);
    while (($key,$val) = each %attribs){
	push @m, "$key: $val\n";
    }
    join "", @m;
}

sub post_constants{
    my($self) = shift;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    "";
}

sub pasthru {
    my($self) = shift;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my(@m,$key);

    my(@pasthru);

    foreach $key (qw(INSTALLPRIVLIB INSTALLARCHLIB INSTALLBIN
		     INSTALLMAN1DIR INSTALLMAN3DIR LIBPERL_A
		     LINKTYPE PREFIX)){
	push @pasthru, "$key=\"\$($key)\"";
    }

    push @m, "\nPASTHRU = ", join ("\\\n\t", @pasthru), "\n";
    join "", @m;
}

# --- Translation Sections ---

sub c_o {
    my($self) = shift;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    return '' unless $self->needs_linking();
    my(@m);
    push @m, '
.c$(OBJ_EXT):
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $*.c

.C$(OBJ_EXT):
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $*.C
';
    join "", @m;
}

sub xs_c {
    my($self) = shift;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    return '' unless $self->needs_linking();
    '
.xs.c:
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs >$*.tc && mv $*.tc $@
';
}

sub xs_o {	# many makes are too dumb to use xs_c then c_o
    my($self) = shift;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    return '' unless $self->needs_linking();
    '
.xs$(OBJ_EXT):
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs >xstmp.c && mv xstmp.c $*.c
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $*.c
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

subdirs :: $(MYEXTLIB)

'.$self->{NOOP}.'

config :: '.$self->{MAKEFILE}.' $(INST_LIBDIR)/.exists

config :: $(INST_ARCHAUTODIR)/.exists Version_check

config :: $(INST_AUTODIR)/.exists
';

    push @m, $self->dir_target(qw[$(INST_AUTODIR) $(INST_LIBDIR) $(INST_ARCHAUTODIR)]);

    if (%{$self->{MAN1PODS}}) {
	push @m, q[
config :: $(INST_MAN1DIR)/.exists

];
	push @m, $self->dir_target(qw[$(INST_MAN1DIR)]);
    }
    if (%{$self->{MAN3PODS}}) {
	push @m, q[
config :: $(INST_MAN3DIR)/.exists

];
	push @m, $self->dir_target(qw[$(INST_MAN3DIR)]);
    }

    push @m, '
$(O_FILES): $(H_FILES)
' if @{$self->{O_FILES} || []} && @{$self->{H} || []};

    push @m, q{
help:
	perldoc ExtUtils::MakeMaker
};

    push @m, q{
Version_check:
	}.$self->{NOECHO}.q{$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) \
		-e 'use ExtUtils::MakeMaker qw($$Version &Version_check);' \
		-e '&Version_check("$(MM_VERSION)")'
};

    join('',@m);
}

sub linkext {
    my($self, %attribs) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    # LINKTYPE => static or dynamic or ''
    my($linktype) = defined $attribs{LINKTYPE} ?
      $attribs{LINKTYPE} : '$(LINKTYPE)';
    "
linkext :: $linktype
$self->{NOOP}
";
}

sub dlsyms {
    my($self,%attribs) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }

    return '' unless ($Config::Config{osname} eq 'aix' && $self->needs_linking() );

    my($funcs) = $attribs{DL_FUNCS} || $self->{DL_FUNCS} || {};
    my($vars)  = $attribs{DL_VARS} || $self->{DL_VARS} || [];
    my(@m);

    push(@m,"
dynamic :: $self->{BASEEXT}.exp

") unless $self->{SKIPHASH}{dynamic};

    push(@m,"
static :: $self->{BASEEXT}.exp

") unless $self->{SKIPHASH}{static};

    push(@m,"
$self->{BASEEXT}.exp: Makefile.PL
",'	$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -e \'use ExtUtils::Mksymlists; \\
	Mksymlists("NAME" => "',$self->{NAME},'", "DL_FUNCS" => ',
	neatvalue($funcs),', "DL_VARS" => ', neatvalue($vars), ');\'
');

    join('',@m);
}

# --- Dynamic Loading Sections ---

sub dynamic {
    my($self) = shift;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    '
# $(INST_PM) has been moved to the all: target.
# It remains here for awhile to allow for old usage: "make dynamic"
dynamic :: '.$self->{MAKEFILE}.' $(INST_DYNAMIC) $(INST_BOOT) $(INST_PM)
'.$self->{NOOP}.'
';
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

    return '
BOOTSTRAP = '."$self->{BASEEXT}.bs".'

# As Mkbootstrap might not write a file (if none is required)
# we use touch to prevent make continually trying to remake it.
# The DynaLoader only reads a non-empty file.
$(BOOTSTRAP): '."$self->{MAKEFILE} $self->{BOOTDEP}".' $(INST_ARCHAUTODIR)/.exists
	'.$self->{NOECHO}.'echo "Running Mkbootstrap for $(NAME) ($(BSLOADLIBS))"
	'.$self->{NOECHO}.'$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" \
		-e \'use ExtUtils::Mkbootstrap;\' \
		-e \'Mkbootstrap("$(BASEEXT)","$(BSLOADLIBS)");\'
	'.$self->{NOECHO}.'$(TOUCH) $(BOOTSTRAP)
	$(CHMOD) 644 $@
	'.$self->{NOECHO}.'echo $@ >> $(INST_ARCHAUTODIR)/.packlist

$(INST_BOOT): $(BOOTSTRAP) $(INST_ARCHAUTODIR)/.exists
	'."$self->{NOECHO}$self->{RM_RF}".' $(INST_BOOT)
	-'.$self->{CP}.' $(BOOTSTRAP) $(INST_BOOT)
	$(CHMOD) 644 $@
	'.$self->{NOECHO}.'echo $@ >> $(INST_ARCHAUTODIR)/.packlist
';
}

sub dynamic_lib {
    my($self, %attribs) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    return '' unless $self->needs_linking(); #might be because of a subdir

    return '' unless $self->has_link_code;

    my($otherldflags) = $attribs{OTHERLDFLAGS} || "";
    my($inst_dynamic_dep) = $attribs{INST_DYNAMIC_DEP} || "";
    my($armaybe) = $attribs{ARMAYBE} || $self->{ARMAYBE} || ":";
    my($ldfrom) = '$(LDFROM)';
    my($osname) = $Config::Config{osname};
    $armaybe = 'ar' if ($osname eq 'dec_osf' and $armaybe eq ':');
    my(@m);
    push(@m,'
# This section creates the dynamically loadable $(INST_DYNAMIC)
# from $(OBJECT) and possibly $(MYEXTLIB).
ARMAYBE = '.$armaybe.'
OTHERLDFLAGS = '.$otherldflags.'
INST_DYNAMIC_DEP = '.$inst_dynamic_dep.'

$(INST_DYNAMIC): $(OBJECT) $(MYEXTLIB) $(BOOTSTRAP) $(INST_ARCHAUTODIR)/.exists $(EXPORT_LIST) $(PERL_ARCHIVE) $(INST_DYNAMIC_DEP)
');
    if ($armaybe ne ':'){
	$ldfrom = 'tmp$(LIB_EXT)';
	push(@m,'	$(ARMAYBE) cr '.$ldfrom.' $(OBJECT)'."\n");
	push(@m,'	$(RANLIB) '."$ldfrom\n");
    }
    $ldfrom = "-all $ldfrom -none" if ($osname eq 'dec_osf');
    push(@m,'	LD_RUN_PATH="$(LD_RUN_PATH)" $(LD) -o $@ $(LDDLFLAGS) '.$ldfrom.
		' $(OTHERLDFLAGS) $(MYEXTLIB) $(LDLOADLIBS) $(EXPORT_LIST) $(PERL_ARCHIVE)');
    push @m, '
	$(CHMOD) 755 $@
	'.$self->{NOECHO}.'echo $@ >> $(INST_ARCHAUTODIR)/.packlist
';

    push @m, $self->dir_target('$(INST_ARCHAUTODIR)');
    join('',@m);
}

# --- Static Loading Sections ---

sub static {
    my($self) = shift;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    '
# $(INST_PM) has been moved to the all: target.
# It remains here for awhile to allow for old usage: "make static"
static :: '.$self->{MAKEFILE}.' $(INST_STATIC) $(INST_PM)
'.$self->{NOOP}.'
';
}

sub static_lib {
    my($self) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
# Come to think of it, if there are subdirs with linkcode, we still have no INST_STATIC
#    return '' unless $self->needs_linking(); #might be because of a subdir

    return '' unless $self->has_link_code;

    my(@m);
    push(@m, <<'END');
$(INST_STATIC): $(OBJECT) $(MYEXTLIB) $(INST_ARCHAUTODIR)/.exists
END
    # If this extension has it's own library (eg SDBM_File)
    # then copy that to $(INST_STATIC) and add $(OBJECT) into it.
    push(@m, "\t$self->{CP} \$(MYEXTLIB) \$\@\n") if $self->{MYEXTLIB};

    push @m, 
q{	$(AR) cr $@ $(OBJECT) && $(RANLIB) $@
	}.$self->{NOECHO}.q{echo "$(EXTRALIBS)" > $(INST_ARCHAUTODIR)/extralibs.ld
	$(CHMOD) 755 $@
	}.$self->{NOECHO}.q{echo $@ >> $(INST_ARCHAUTODIR)/.packlist
};

# Old mechanism - still available:

    push @m, "\t$self->{NOECHO}".q{echo "$(EXTRALIBS)" >> $(PERL_SRC)/ext.libs}."\n\n"
	if $self->{PERL_SRC};

    push @m, $self->dir_target('$(INST_ARCHAUTODIR)');
    join('', "\n",@m);
}

sub installpm {
    my($self, %attribs) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    # By default .pm files are split into the architecture independent
    # library. This is a good thing. If a specific module requires that
    # it's .pm files are split into the architecture specific library
    # then it should use: installpm => {SPLITLIB=>'$(INST_ARCHLIB)'}
    # Note that installperl currently interferes with this (Config.pm)
    # User can disable split by saying: installpm => {SPLITLIB=>''}
    my($splitlib) = '$(INST_LIB)'; # NOT arch specific by default
    $splitlib = $attribs{SPLITLIB} if exists $attribs{SPLITLIB};
    my(@m, $dist);
    push @m, "inst_pm :: \$(INST_PM)\n\n";
    foreach $dist (sort keys %{$self->{PM}}){
	my($inst) = $self->{PM}->{$dist};
	push(@m, "\n# installpm: $dist => $inst, splitlib=$splitlib\n");
	push(@m, $self->installpm_x($dist, $inst, $splitlib));
	push(@m, "\n");
    }
    join('', @m);
}

sub installpm_x { # called by installpm per file
    my($self, $dist, $inst, $splitlib) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    if ($inst =~ m,[:\#],){
	warn "Warning: 'make' would have problems processing this file: '$inst', SKIPPED\n";
	return '';
    }
    my($instdir) = $inst =~ m|(.*)/|;
    my(@m);
    push(@m,"
$inst: $dist $self->{MAKEFILE} $instdir/.exists \$(INST_ARCHAUTODIR)/.exists
	$self->{NOECHO}$self->{RM_F}".' $@
	$(UMASK_NULL) && '."$self->{CP} $dist \$\@
	$self->{NOECHO}echo ".'$@ >> $(INST_ARCHAUTODIR)/.packlist
');
    push(@m, "\t$self->{NOECHO}\$(AUTOSPLITFILE) \$@ $splitlib/auto\n")
	if ($splitlib and $inst =~ m/\.pm$/);

    push @m, $self->dir_target($instdir);
    join('', @m);
}

sub manifypods {
    my($self, %attribs) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    return "\nmanifypods :\n" unless %{$self->{MAN3PODS}};
    my($dist);
    my($pod2man_exe);
    if (defined $self->{PERL_SRC}) {
	$pod2man_exe = $self->catfile($self->{PERL_SRC},'pod','pod2man');
    } else {
	$pod2man_exe = $self->catfile($Config{bin},'pod2man');
    }
    unless ($self->perl_script($pod2man_exe)) {
	# No pod2man but some MAN3PODS to be installed
	print <<END;

Warning: I could not locate your pod2man program. Please make sure,
         your pod2man program is in your PATH before you execute 'make'

END
        $pod2man_exe = "-S pod2man";
    }
    my(@m);
    push @m,
qq[POD2MAN_EXE = $pod2man_exe\n],
q[POD2MAN = $(PERL) -we '%m=@ARGV;for (keys %m){' \\
-e 'next if -e $$m{$$_} && -M $$m{$$_} < -M $$_ && -M $$m{$$_} < -M "].$self->{MAKEFILE}.q[";' \\
-e 'print "Installing $$m{$$_}\n";' \\
-e 'system("$$^X \\"-I$(PERL_ARCHLIB)\\" \\"-I$(PERL_LIB)\\" $(POD2MAN_EXE) $$_>$$m{$$_}")==0 or warn "Couldn\\047t install $$m{$$_}\n";' \\
-e 'chmod 0644, $$m{$$_} or warn "chmod 644 $$m{$$_}: $$!\n";}'
];
    push @m, "\nmanifypods : ";
    push @m, join " \\\n\t", keys %{$self->{MAN1PODS}}, keys %{$self->{MAN3PODS}};

    push(@m,"\n");
    if (%{$self->{MAN1PODS}} || %{$self->{MAN3PODS}}) {
	push @m, "\t$self->{NOECHO}\$(POD2MAN) \\\n\t";
	push @m, join " \\\n\t", %{$self->{MAN1PODS}}, %{$self->{MAN3PODS}};
    }
    join('', @m);
}

sub processPL {
    my($self) = shift;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    return "" unless $self->{PL_FILES};
    my(@m, $plfile);
    foreach $plfile (sort keys %{$self->{PL_FILES}}) {
	push @m, "
all :: $self->{PL_FILES}->{$plfile}

$self->{PL_FILES}->{$plfile} :: $plfile
	\$(PERL) -I\$(INST_ARCHLIB) -I\$(INST_LIB) -I\$(PERL_ARCHLIB) -I\$(PERL_LIB) $plfile
";
    }
    join "", @m;
}

sub installbin {
    my($self) = shift;
    return "" unless $self->{EXE_FILES} && ref $self->{EXE_FILES} eq "ARRAY";
    return "" unless @{$self->{EXE_FILES}};
    my(@m, $from, $to, %fromto, @to);
    push @m, $self->dir_target(qw[$(INST_EXE)]);
    for $from (@{$self->{EXE_FILES}}) {
	my($path)= '$(INST_EXE)/' . basename($from);
	local($_) = $path; # for backwards compatibility
	$to = $self->exescan($path);
	print "exescan($from) => '$to'\n" if ($ExtUtils::MakeMaker::Verbose >=2);
	$fromto{$from}=$to;
    }
    @to   = values %fromto;
    push(@m, "
EXE_FILES = @{$self->{EXE_FILES}}

all :: @to

realclean ::
	$self->{RM_F} @to
");

    while (($from,$to) = each %fromto) {
	my $todir = dirname($to);
	push @m, "
$to: $from $self->{MAKEFILE} $todir/.exists
	$self->{CP} $from $to
";
    }
    join "", @m;
}

sub exescan {
    my($self,$path) = @_;
    $path;
}
# --- Sub-directory Sections ---

sub subdirs {
    my($self) = shift;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my(@m,$dir);
    # This method provides a mechanism to automatically deal with
    # subdirectories containing further Makefile.PL scripts.
    # It calls the subdir_x() method for each subdirectory.
    foreach $dir (@{$self->{DIR}}){
	push(@m, $self->subdir_x($dir));
####	print "Including $dir subdirectory\n";
    }
    if (@m){
	unshift(@m, "
# The default clean, realclean and test targets in this Makefile
# have automatically been given entries for each subdir.

");
    } else {
	push(@m, "\n# none")
    }
    join('',@m);
}

sub runsubdirpl{	# Experimental! See subdir_x section
    my($self,$subdir) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    chdir($subdir) or die "chdir($subdir): $!";
    package main;
    require "Makefile.PL";
}

sub subdir_x {
    my($self, $subdir) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my(@m);
    qq{

subdirs ::
	$self->{NOECHO}-cd $subdir && \$(MAKE) all \$(PASTHRU)

};
}

# --- Cleanup and Distribution Sections ---

sub clean {
    my($self, %attribs) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my(@m,$dir);
    push(@m, '
# Delete temporary files but do not touch installed files. We don\'t delete
# the Makefile here so a later make realclean still has a makefile to use.

clean ::
');
    # clean subdirectories first
    for $dir (@{$self->{DIR}}) {
	push @m, "\t-cd $dir && test -f $self->{MAKEFILE} && \$(MAKE) clean\n";
    }

    my(@otherfiles) = values %{$self->{XS}}; # .c files from *.xs files
    push(@otherfiles, $attribs{FILES}) if $attribs{FILES};
    push(@otherfiles, qw[./blib $(MAKE_APERL_FILE) $(INST_ARCHAUTODIR)/extralibs.all
			 perlmain.c mon.out core so_locations
			 *~ */*~ */*/*~
			 *$(OBJ_EXT) *$(LIB_EXT)
			 perl.exe $(BOOTSTRAP) $(BASEEXT).bso $(BASEEXT).def $(BASEEXT).exp
			]);
    push @m, "\t-$self->{RM_RF} @otherfiles\n";
    # See realclean and ext/utils/make_ext for usage of Makefile.old
    push(@m,
	 "\t-$self->{MV} $self->{MAKEFILE} $self->{MAKEFILE}.old 2>/dev/null\n");
    push(@m,
	 "\t$attribs{POSTOP}\n")   if $attribs{POSTOP};
    join("", @m);
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
realclean purge ::  clean
');
    # realclean subdirectories first (already cleaned)
    my $sub = "\t-cd %s && test -f %s && \$(MAKE) %s realclean\n";
    foreach(@{$self->{DIR}}){
	push(@m, sprintf($sub,$_,"$self->{MAKEFILE}.old","-f $self->{MAKEFILE}.old"));
	push(@m, sprintf($sub,$_,"$self->{MAKEFILE}",''));
    }
    push(@m, "	$self->{RM_RF} \$(INST_AUTODIR) \$(INST_ARCHAUTODIR)\n");
    push(@m, "	$self->{RM_F} \$(INST_DYNAMIC) \$(INST_BOOT)\n");
    push(@m, "	$self->{RM_F} \$(INST_STATIC) \$(INST_PM)\n");
    my(@otherfiles) = ($self->{MAKEFILE},
		       "$self->{MAKEFILE}.old"); # Makefiles last
    push(@otherfiles, $attribs{FILES}) if $attribs{FILES};
    push(@m, "	$self->{RM_RF} @otherfiles\n") if @otherfiles;
    push(@m, "	$attribs{POSTOP}\n")       if $attribs{POSTOP};
    join("", @m);
}

sub dist_basics {
    my($self) = shift;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my @m;
    push @m, q{
distclean :: realclean distcheck
};

    push @m, q{
distcheck :
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -e 'use ExtUtils::Manifest "&fullcheck";' \\
		-e 'fullcheck();'
};

    push @m, q{
skipcheck :
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -e 'use ExtUtils::Manifest "&skipcheck";' \\
		-e 'skipcheck();'
};

    push @m, q{
manifest :
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -e 'use ExtUtils::Manifest "&mkmanifest";' \\
		-e 'mkmanifest();'
};
    join "", @m;
}

sub dist_core {
    my($self) = shift;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my @m;
    push @m, q{
dist : $(DIST_DEFAULT)

tardist : $(DISTVNAME).tar.$(SUFFIX)

$(DISTVNAME).tar.$(SUFFIX) : distdir
	$(PREOP)
	$(TAR) $(TARFLAGS) $(DISTVNAME).tar $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(COMPRESS) $(DISTVNAME).tar
	$(POSTOP)

uutardist : $(DISTVNAME).tar.$(SUFFIX)
	uuencode $(DISTVNAME).tar.$(SUFFIX) \\
		$(DISTVNAME).tar.$(SUFFIX) > \\
		$(DISTVNAME).tar.$(SUFFIX).uu

shdist : distdir
	$(PREOP)
	$(SHAR) $(DISTVNAME) > $(DISTVNAME).shar
	$(RM_RF) $(DISTVNAME)
	$(POSTOP)
};
    join "", @m;
}

sub dist_dir {
    my($self) = shift;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my @m;
    push @m, q{
distdir :
	$(RM_RF) $(DISTVNAME)
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -e 'use ExtUtils::Manifest "/mani/";' \\
		-e 'manicopy(maniread(),"$(DISTVNAME)", "$(DIST_CP)");'
};
    join "", @m;
}

sub dist_test {
    my($self) = shift;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my @m;
    push @m, q{
disttest : distdir
	cd $(DISTVNAME) && $(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) Makefile.PL
	cd $(DISTVNAME) && $(MAKE)
	cd $(DISTVNAME) && $(MAKE) test
};
    join "", @m;
}

sub dist_ci {
    my($self) = shift;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my @m;
    push @m, q{
ci :
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -e 'use ExtUtils::Manifest "&maniread";' \\
		-e '@all = keys %{ maniread() };' \\
		-e 'print("Executing $(CI) @all\n"); system("$(CI) @all");' \\
		-e 'print("Executing $(RCS_LABEL) ...\n"); system("$(RCS_LABEL) @all");'
};
    join "", @m;
}

sub install {
    my($self, %attribs) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my(@m);
    push @m, q{
doc_install ::
	}.$self->{NOECHO}.q{echo Appending installation info to $(INSTALLARCHLIB)/perllocal.pod
	}.$self->{NOECHO}.q{$(PERL) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB)  \\
		-e "use ExtUtils::MakeMaker; MY->new({})->writedoc('Module', '$(NAME)', \\
		'LINKTYPE=$(LINKTYPE)', 'VERSION=$(VERSION)', 'XS_VERSION=$(XS_VERSION)', \\
		'EXE_FILES=$(EXE_FILES)')" >> $(INSTALLARCHLIB)/perllocal.pod
};

    push(@m, "
install :: pure_install doc_install

pure_install ::
");
    # install subdirectories first
    push(@m, map("\tcd $_ && test -f $self->{MAKEFILE} && \$(MAKE) install\n",
		 @{$self->{DIR}}));

    push(@m, "\t$self->{NOECHO}".q{$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -e 'require File::Path;' \
	-e '$$message = q[ You do not have permissions to install into];' \
	-e 'File::Path::mkpath(@ARGV);' \
	-e 'foreach (@ARGV){ die qq{ $$message $$_\\n} unless -w $$_}' \
	    $(INSTALLPRIVLIB) $(INSTALLARCHLIB)
	$(MAKE) INST_LIB=$(INSTALLPRIVLIB) INST_ARCHLIB=$(INSTALLARCHLIB) \
	    INST_EXE=$(INSTALLBIN) INST_MAN1DIR=$(INSTALLMAN1DIR) \
	    INST_MAN3DIR=$(INSTALLMAN3DIR) all

reorg_packlist:
	}.$self->{NOECHO}.q{$(PERL) -ne 'BEGIN{die "Need 2 arguments to reorg .packlist" unless @ARGV==2;' \
	    -e '$$out=$$ARGV[1]; shift @ARGV while @ARGV && ! -f $$ARGV[0]; exit unless @ARGV;}' \
	    -e 'push @lines, $$_ unless $$seen{$$_}++;' \
	    -e 'END{open STDOUT, ">$$out" or die "Cannot write to $$out: $$!";' \
	    -e 'print @lines;}' $(PERL_ARCHLIB)/auto/$(FULLEXT)/.packlist \
		$(INST_ARCHAUTODIR)/.packlist
});

# From MM 5.16:

    push @m, q[
# Comment on .packlist rewrite above:
# Read both .packlist files: the old one in PERL_ARCHLIB/auto/FULLEXT, and the new one
# in INSTARCHAUTODIR. Don't croak if they are missing. Write to the one
# in INSTARCHAUTODIR. 

#### UNINSTALL IS STILL EXPERIMENTAL ####
uninstall ::
];

    push(@m, map("\tcd $_ && test -f $self->{MAKEFILE} && \$(MAKE) uninstall\n",
		 @{$self->{DIR}}));
    push @m, "\t".'$(RM_RF) `cat $(PERL_ARCHLIB)/auto/$(FULLEXT)/.packlist`
';

    join("",@m);
}


sub force {
    my($self) = shift;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    '# Phony target to force checking subdirectories.
FORCE:
';
}


sub perldepend {
    my($self) = shift;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
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
' if $self->{OBJECT};

    push(@m,'
# Check for unpropogated config.sh changes. Should never happen.
# We do NOT just update config.h because that is not sufficient.
# An out of date config.h is not fatal but complains loudly!
$(PERL_INC)/config.h: $(PERL_SRC)/config.sh
	-'.$self->{NOECHO}.'echo "Warning: $(PERL_INC)/config.h out of date with $(PERL_SRC)/config.sh"; false

$(PERL_ARCHLIB)/Config.pm: $(PERL_SRC)/config.sh
	'.$self->{NOECHO}.'echo "Warning: $(PERL_ARCHLIB)/Config.pm may be out of date with $(PERL_SRC)/config.sh"
	cd $(PERL_SRC) && $(MAKE) lib/Config.pm
') if $self->{PERL_SRC};

    push(@m, join(" ", values %{$self->{XS}})." : \$(XSUBPPDEPS)\n")
	if %{$self->{XS}};
    join("\n",@m);
}

sub makefile {
    my($self) = shift;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my @m;
    # We do not know what target was originally specified so we
    # must force a manual rerun to be sure. But as it should only
    # happen very rarely it is not a significant problem.
    push @m, '
$(OBJECT) : $(FIRST_MAKEFILE)
' if $self->{OBJECT};

    push @m, '
# We take a very conservative approach here, but it\'s worth it.
# We move Makefile to Makefile.old here to avoid gnu make looping.
'.$self->{MAKEFILE}.' :	Makefile.PL $(CONFIGDEP)
	'.$self->{NOECHO}.'echo "Makefile out-of-date with respect to $?"
	'.$self->{NOECHO}.'echo "Cleaning current config before rebuilding Makefile..."
	-'.$self->{NOECHO}.'mv '."$self->{MAKEFILE} $self->{MAKEFILE}.old".'
	-$(MAKE) -f '.$self->{MAKEFILE}.'.old clean >/dev/null 2>&1 || true
	$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" Makefile.PL '."@ARGV".'
	'.$self->{NOECHO}.'echo ">>> Your Makefile has been rebuilt. <<<"
	'.$self->{NOECHO}.'echo ">>> Please rerun the make command.  <<<"; false
';

    join "", @m;
}

sub staticmake {
    my($self, %attribs) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my(@static);

    my(%searchdirs)=($self->{PERL_ARCHLIB} => 1,  $self->{INST_ARCHLIB} => 1);
    my(@searchdirs)=keys %searchdirs;

    # And as it's not yet built, we add the current extension
    # but only if it has some C code (or XS code, which implies C code)
    if (@{$self->{C}}) {
	@static="$self->{INST_ARCHLIB}/auto/$self->{FULLEXT}/$self->{BASEEXT}$self->{LIB_EXT}";
    }

    # Either we determine now, which libraries we will produce in the
    # subdirectories or we do it at runtime of the make.

    # We could ask all subdir objects, but I cannot imagine, why it
    # would be necessary.

    # Instead we determine all libraries for the new perl at
    # runtime.
    my(@perlinc) = ($self->{INST_ARCHLIB}, $self->{INST_LIB}, $self->{PERL_ARCHLIB}, $self->{PERL_LIB});

    $self->makeaperl(MAKE	=> $self->{MAKEFILE},
		     DIRS	=> \@searchdirs,
		     STAT	=> \@static,
		     INCL	=> \@perlinc,
		     TARGET	=> $self->{MAP_TARGET},
		     TMP	=> "",
		     LIBPERL	=> $self->{LIBPERL_A}
		    );
}

# --- Test and Installation Sections ---

sub test {
    my($self, %attribs) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my($tests) = $attribs{TESTS} || (-d "t" ? "t/*.t" : "");
    my(@m);
    push(@m,"
TEST_VERBOSE=0
TEST_TYPE=test_\$(LINKTYPE)

test :: \$(TEST_TYPE)
");
    push(@m, map("\t$self->{NOECHO}cd $_ && test -f $self->{MAKEFILE} && \$(MAKE) test \$(PASTHRU)\n",
		 @{$self->{DIR}}));
    push(@m, "\t$self->{NOECHO}echo 'No tests defined for \$(NAME) extension.'\n")
	unless $tests or -f "test.pl" or @{$self->{DIR}};
    push(@m, "\n");

    push(@m, "test_dynamic :: all\n");
    push(@m, $self->test_via_harness('$(FULLPERL)', $tests)) if $tests;
    push(@m, $self->test_via_script('$(FULLPERL)', 'test.pl')) if -f "test.pl";
    push(@m, "\n");

    # Occasionally we may face this degenerate target:
    push @m, "test_ : test_dynamic\n\n";

    if ($self->needs_linking()) {
	push(@m, "test_static :: all \$(MAP_TARGET)\n");
	push(@m, $self->test_via_harness('./$(MAP_TARGET)', $tests)) if $tests;
	push(@m, $self->test_via_script('./$(MAP_TARGET)', 'test.pl')) if -f "test.pl";
	push(@m, "\n");
    } else {
	push @m, "test_static :: test_dynamic\n";
    }
    join("", @m);
}

sub test_via_harness {
    my($self, $perl, $tests) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    "\tPERL_DL_NONLAZY=1 $perl".q! -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -e 'use Test::Harness qw(&runtests $$verbose); $$verbose=$(TEST_VERBOSE); runtests @ARGV;' !."$tests\n";
}

sub test_via_script {
    my($self, $perl, $script) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    "\tPERL_DL_NONLAZY=1 $perl".' -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) test.pl
';
}


sub postamble {
    my($self) = shift;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    "";
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
FULLPERL      = $self->{FULLPERL}
";
    return join '', @m if $self->{PARENT};

    my($dir) = join ":", @{$self->{DIR}};

    unless ($self->{MAKEAPERL}) {
	push @m, q{
$(MAP_TARGET) :: $(MAKE_APERL_FILE)
	$(MAKE) -f $(MAKE_APERL_FILE) static $@

$(MAKE_APERL_FILE) : $(FIRST_MAKEFILE)
	}.$self->{NOECHO}.q{echo Writing \"$(MAKE_APERL_FILE)\" for this $(MAP_TARGET)
	}.$self->{NOECHO}.q{$(PERL) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) \
		Makefile.PL DIR=}, $dir, q{ \
		MAKEFILE=$(MAKE_APERL_FILE) LINKTYPE=static \
		MAKEAPERL=1 NORECURS=1 CCCDLFLAGS=};

	push @m, map( " \\\n\t\t$_", @ARGV );
	push @m, "\n";

	return join '', @m;
    }



    my($cccmd, $linkcmd, $lperl);


    $cccmd = $self->const_cccmd($libperl);
    $cccmd =~ s/^CCCMD\s*=\s*//;
    $cccmd =~ s/\$\(INC\)/ -I$self->{PERL_INC} /;
    $cccmd .= " $Config::Config{cccdlflags}" if ($Config::Config{d_shrplib});
    $cccmd =~ s/\n/ /g; # yes I've seen "\n", don't ask me where it came from. A.K.
    $cccmd =~ s/\(CC\)/\(PERLMAINCC\)/;

    # The front matter of the linkcommand...
    $linkcmd = join ' ', "\$(CC)",
	    grep($_, @Config{qw(large split ldflags ccdlflags)});
    $linkcmd =~ s/\s+/ /g;

    # Which *.a files could we make use of...
    local(%static);
    File::Find::find(sub {
	return unless m/\Q$self->{LIB_EXT}\E$/;
	return if m/^libperl/;
	# don't include the installed version of this extension. I
	# leave this line here, although it is not necessary anymore:
	# I patched minimod.PL instead, so that Miniperl.pm won't
	# enclude duplicates

	# Once the patch to minimod.PL is in the distribution, I can
	# drop it
	return if $File::Find::name =~ m:auto/$self->{FULLEXT}/$self->{BASEEXT}$self->{LIB_EXT}$:;
	$static{fastcwd() . "/" . $_}++;
    }, grep( -d $_, @{$searchdirs || []}) );

    # We trust that what has been handed in as argument, will be buildable
    $static = [] unless $static;
    @static{@{$static}} = (1) x @{$static};

    $extra = [] unless $extra && ref $extra eq 'ARRAY';
    for (sort keys %static) {
	next unless /\Q$self->{LIB_EXT}\E$/;
	$_ = dirname($_) . "/extralibs.ld";
	push @$extra, $_;
    }

    grep(s/^/-I/, @{$perlinc || []});

    $target = "perl" unless $target;
    $tmp = "." unless $tmp;

# MAP_STATIC doesn't look into subdirs yet. Once "all" is made and we
# regenerate the Makefiles, MAP_STATIC and the dependencies for
# extralibs.all are computed correctly
    push @m, "
MAP_LINKCMD   = $linkcmd
MAP_PERLINC   = @{$perlinc || []}
MAP_STATIC    = ",
join(" \\\n\t", reverse sort keys %static), "

MAP_PRELIBS   = $Config::Config{libs} $Config::Config{cryptlib}
";

    if (defined $libperl) {
	($lperl = $libperl) =~ s/\$\(A\)/$self->{LIB_EXT}/;
    }
    unless ($libperl && -f $lperl) { # Could quite follow your idea her, Ilya
	my $dir = $self->{PERL_SRC} || "$self->{PERL_ARCHLIB}/CORE";
	$libperl ||= "libperl$self->{LIB_EXT}";
	$libperl   = "$dir/$libperl";
	$lperl   ||= "libperl$self->{LIB_EXT}";
	$lperl     = "$dir/$lperl";
	print STDOUT "Warning: $libperl not found
    If you're going to build a static perl binary, make sure perl is installed
    otherwise ignore this warning\n"
		unless (-f $lperl || defined($self->{PERL_SRC}));
    }

    push @m, "
MAP_LIBPERL = $libperl
";

    push @m, "
\$(INST_ARCHAUTODIR)/extralibs.all: \$(INST_ARCHAUTODIR)/.exists ".join(" \\\n\t", @$extra)."
	$self->{NOECHO}$self->{RM_F} \$\@
	$self->{NOECHO}\$(TOUCH) \$\@
";

    my $catfile;
    foreach $catfile (@$extra){
	push @m, "\tcat $catfile >> \$\@\n";
    }

    push @m, "
\$(MAP_TARGET) :: $tmp/perlmain\$(OBJ_EXT) \$(MAP_LIBPERL) \$(MAP_STATIC) \$(INST_ARCHAUTODIR)/extralibs.all
	\$(MAP_LINKCMD) -o \$\@ $tmp/perlmain\$(OBJ_EXT) \$(MAP_LIBPERL) \$(MAP_STATIC) `cat \$(INST_ARCHAUTODIR)/extralibs.all` \$(MAP_PRELIBS)
	$self->{NOECHO}echo 'To install the new \"\$(MAP_TARGET)\" binary, call'
	$self->{NOECHO}echo '    make -f $makefilename inst_perl MAP_TARGET=\$(MAP_TARGET)'
	$self->{NOECHO}echo 'To remove the intermediate files say'
	$self->{NOECHO}echo '    make -f $makefilename map_clean'

$tmp/perlmain\$(OBJ_EXT): $tmp/perlmain.c
";
    push @m, "\tcd $tmp && $cccmd -I\$(PERL_INC) perlmain.c\n";

    push @m, qq{
$tmp/perlmain.c: $makefilename}, q{
	}.$self->{NOECHO}.q{echo Writing $@
	}.$self->{NOECHO}.q{$(PERL) $(MAP_PERLINC) -e 'use ExtUtils::Miniperl; \\
		writemain(grep s#.*/auto/##, qw|$(MAP_STATIC)|)' > $@.tmp && mv $@.tmp $@

};

# We write EXTRA outside the perl program to have it eval'd by the shell
    push @m, q{
doc_inst_perl:
	}.$self->{NOECHO}.q{echo Appending installation info to $(INSTALLARCHLIB)/perllocal.pod
	}.$self->{NOECHO}.q{$(FULLPERL) -e 'use ExtUtils::MakeMaker; MY->new->writedoc("Perl binary",' \\
		-e '"$(MAP_TARGET)", "MAP_STATIC=$(MAP_STATIC)",' \\
		-e '"MAP_EXTRA=@ARGV", "MAP_LIBPERL=$(MAP_LIBPERL)")' \\
		-- `cat $(INST_ARCHAUTODIR)/extralibs.all` >> $(INSTALLARCHLIB)/perllocal.pod
};

    push @m, qq{
inst_perl: pure_inst_perl doc_inst_perl

pure_inst_perl: \$(MAP_TARGET)
	$self->{CP} \$(MAP_TARGET) \$(INSTALLBIN)/\$(MAP_TARGET)

clean :: map_clean

map_clean :
	$self->{RM_F} $tmp/perlmain\$(OBJ_EXT) $tmp/perlmain.c \$(MAP_TARGET) $makefilename \$(INST_ARCHAUTODIR)/extralibs.all
};

    join '', @m;
}

sub extliblist {
    my($self,$libs) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    require ExtUtils::Liblist;
    ExtUtils::Liblist::ext($libs, $ExtUtils::MakeMaker::Verbose);
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
	push @m, "
$dir/.exists :: \$(PERL)
	$self->{NOECHO}\$(MKPATH) $dir
	$self->{NOECHO}\$(EQUALIZE_TIMESTAMP) \$(PERL) $dir/.exists
	$self->{NOECHO}-\$(CHMOD) 755 $dir
";
    }
    join "", @m;
}

# --- Output postprocessing section ---
# nicetext is included to make VMS support easier
sub nicetext { # Just return the input - no action needed
    my($self,$text) = @_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    $text;
}

sub needs_linking { # Does this module need linking? Looks into
                    # subdirectory objects (see also has_link_code()
    my($self) = shift;
    my($child,$caller);
    $caller = (caller(0))[3];
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse($caller);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    Carp::confess("Needs_linking called too early") if $caller =~ /^ExtUtils::MakeMaker::/;
    return $self->{NEEDS_LINKING} if defined $self->{NEEDS_LINKING};
#    print "DEBUG:\n";
#    print Carp::longmess();
#    print "EO_DEBUG\n";
    if ($self->has_link_code or $self->{MAKEAPERL}){
	$self->{NEEDS_LINKING} = 1;
	return 1;
    }
    foreach $child (keys %{$self->{CHILDREN}}) {
	if ($self->{CHILDREN}->{$child}->needs_linking) {
	    $self->{NEEDS_LINKING} = 1;
	    return 1;
	}
    }
    return $self->{NEEDS_LINKING} = 0;
}

sub has_link_code {
    my($self) = shift;
    return $self->{HAS_LINK_CODE} if defined $self->{HAS_LINK_CODE};
    if ($self->{OBJECT} or @{$self->{C} || []} or $self->{MYEXTLIB}){
	$self->{HAS_LINK_CODE} = 1;
	return 1;
    }
    return $self->{HAS_LINK_CODE} = 0;
}

# --- perllocal.pod section ---
sub writedoc {
    my($self,$what,$name,@attribs)=@_;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my($time) = localtime;
    print "=head2 $time: $what C<$name>\n\n=over 4\n\n=item *\n\n";
    print join "\n\n=item *\n\n", map("C<$_>",@attribs);
    print "\n\n=back\n\n";
}

sub catdir  { shift; my $result = join('/',@_); $result =~ s:/+:/:g; $result; }
sub catfile { shift; my $result = join('/',@_); $result =~ s:/+:/:g; $result; }

package ExtUtils::MM_OS2;

#use Config;
#use Cwd;
#use File::Basename;
require Exporter;

Exporter::import('ExtUtils::MakeMaker',
       qw( $Verbose &neatvalue));

sub dlsyms {
    my($self,%attribs) = @_;

    my($funcs) = $attribs{DL_FUNCS} || $self->{DL_FUNCS} || {};
    my($vars)  = $attribs{DL_VARS} || $self->{DL_VARS} || [];
    my(@m);
    (my $boot = $self->{NAME}) =~ s/:/_/g;

    if (not $self->{SKIPHASH}{'dynamic'}) {
	push(@m,"
$self->{BASEEXT}.def: Makefile.PL
",'	$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -e \'use ExtUtils::Mksymlists; \\
	Mksymlists("NAME" => "',$self->{NAME},'", "DLBASE" => "',$self->{DLBASE},
	'", "DL_FUNCS" => ',neatvalue($funcs),', "DL_VARS" => ', neatvalue($vars), ');\'
');
    }
    join('',@m);
}

sub replace_manpage_separator {
    my($self,$man) = @_;
    $man =~ s,/+,.,g;
    $man;
}

sub maybe_command {
    my($self,$file) = @_;
    return $file if -x $file && ! -d _;
    return "$file.exe" if -x "$file.exe" && ! -d _;
    return "$file.cmd" if -x "$file.cmd" && ! -d _;
    return;
}

sub file_name_is_absolute {
    my($self,$file) = @_;
    $file =~ m{^([a-z]:)?[\\/]}i ;
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

You should program with more care. Watch out for any MakeMaker
variables. Do not try to alter them, somebody else might depend on
them. E.g. do not overwrite the ExtUtils::MakeMaker::VERSION variable
(this happens if you import it and then set it to the version number
of your package), do not expect that the INST_LIB variable will be
./blib (do not 'unshift @INC, "./blib" and do not use
"blib/FindBin.pm"). Do not croak in your Makefile.PL, let it fail with
a warning instead.

Try to build several extensions simultanously to debug your
Makefile.PL. You can unpack a bunch of distributed packages, so your
directory looks like

    Alias-1.00/         Net-FTP-1.01a/      Set-Scalar-0.001/
    ExtUtils-Peek-0.4/  Net-Ping-1.00/      SetDualVar-1.0/
    Filter-1.06/        NetTools-1.01a/     Storable-0.1/
    GD-1.00/            Religion-1.04/      Sys-Domain-1.05/
    MailTools-1.03/     SNMP-1.5b/          Term-ReadLine-0.7/

and write a dummy Makefile.PL that contains nothing but

    use ExtUtils::MakeMaker;
    WriteMakefile();

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
form C<KEY=VALUE>. If the user wants to work with a different perl
than the default, this can be achieved with

  perl Makefile.PL PERL=/tmp/myperl5

Other interesting targets in the generated Makefile are

  make config     # to check if the Makefile is up-to-date
  make clean      # delete local temp files (Makefile gets renamed)
  make realclean  # delete derived files (including ./blib)
  make dist       # see below the Distribution Support section

=head2 Special case make install

make alone puts all relevant files into directories that are named by
the macros INST_LIB, INST_ARCHLIB, INST_EXE, INST_MAN1DIR, and
INST_MAN3DIR. All these default to ./blib or something below blib if
you are I<not> building below the perl source directory. If you I<are>
building below the perl source, INST_LIB and INST_ARCHLIB default to
 ../../lib, and INST_EXE is not defined.

The I<install> target of the generated Makefile is a recursive call to
make which sets

    INST_LIB     to INSTALLPRIVLIB
    INST_ARCHLIB to INSTALLARCHLIB
    INST_EXE     to INSTALLBIN
    INST_MAN1DIR to INSTALLMAN1DIR
    INST_MAN3DIR to INSTALLMAN3DIR

The INSTALL... macros in turn default to their %Config
($Config{installprivlib}, $Config{installarchlib}, etc.) counterparts.

The recommended way to proceed is to set only the INSTALL* macros, not
the INST_* targets. In doing so, you give room to the compilation
process without affecting important directories. Usually a make
test will succeed after the make, and a make install can finish
the game.

MakeMaker gives you much more freedom than needed to configure
internal variables and get different results. It is worth to mention,
that make(1) also lets you configure most of the variables that are
used in the Makefile. But in the majority of situations this will not
be necessary, and should only be done, if the author of a package
recommends it.

The usual relationship between INSTALLPRIVLIB and INSTALLARCHLIB is
that the latter is a subdirectory of the former with the name
C<$Config{archname}>, MakeMaker supports the user who sets
INSTALLPRIVLIB. If INSTALLPRIVLIB is set, but INSTALLARCHLIB not, then
MakeMaker defaults the latter to be INSTALLPRIVLIB/ARCHNAME if that
directory exists, otherwise it defaults to INSTALLPRIVLIB.


=head2 PREFIX attribute

The PREFIX attribute can be used to set the INSTALL* attributes in one
go. The quickest way to install a module in a non-standard place

    perl Makefile.PL PREFIX=~

This will replace the string specified by $Config{prefix} in all
$Config{install*} values.

Note, that the tilde expansion is done by MakeMaker, not by perl by
default, nor by make.

It is important to know, that the INSTALL* macros should be absolute
paths, never relativ ones. Packages with multiple Makefile.PLs in
different directories get the contents of the INSTALL* macros
propagated verbatim. (The INST_* macros will be corrected, if they are
relativ paths, but not the INSTALL* macros.)

If the user has superuser privileges, and is not working on AFS
(Andrew File System) or relatives, then the defaults for
INSTALLPRIVLIB, INSTALLARCHLIB, INSTALLBIN, etc. will be appropriate,
and this incantation will be the best:

    perl Makefile.PL; make; make test
    make install

make install per default writes some documentation of what has been
done into the file C<$(INSTALLARCHLIB)/perllocal.pod>. This is
an experimental feature. It can be bypassed by calling make
pure_install.

=head2 AFS users

will have to specify the installation directories as these most
probably have changed since perl itself has been installed. They will
have to do this by calling

    perl Makefile.PL INSTALLPRIVLIB=/afs/here/today \
	INSTALLBIN=/afs/there/now INSTALLMAN3DIR=/afs/for/manpages
    make

In nested extensions with many subdirectories, the INSTALL* arguments
will get propagated to the subdirectories. Be careful to repeat this
procedure every time you recompile an extension, unless you are sure
the AFS istallation directories are still valid.

=head2 Static Linking of a new Perl Binary

An extension that is built with the above steps is ready to use on
systems supporting dynamic loading. On systems that do not support
dynamic loading, any newly created extension has to be linked together
with the available resources. MakeMaker supports the linking process
by creating appropriate targets in the Makefile whenever an extension
is built. You can invoke the corresponding section of the makefile with

    make perl

That produces a new perl binary in the current directory with all
extensions linked in that can be found in INST_ARCHLIB (which usually
is C<./blib>) and PERL_ARCHLIB. To do that, MakeMaker writes a new
Makefile, on UNIX, this is called Makefile.aperl (may be system
dependent). If you want to force the creation of a new perl, it is
recommended, that you delete this Makefile.aperl, so INST_ARCHLIB and
PERL_ARCHLIB are searched-through for linkable libraries again.

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

make inst_perl per default writes some documentation of what has been
done into the file C<$(INSTALLARCHLIB)/perllocal.pod>. This
can be bypassed by calling make pure_inst_perl.

Warning: the inst_perl: target is rather mighty and will probably
overwrite your existing perl binary. Use with care!

Sometimes you might want to build a statically linked perl although
your system supports dynamic loading. In this case you may explicitly
set the linktype with the invocation of the Makefile.PL or make:

    perl Makefile.PL LINKTYPE=static    # recommended

or

    make LINKTYPE=static                # works on most systems

=head2 Determination of Perl Library and Installation Locations

MakeMaker needs to know, or to guess, where certain things are
located.  Especially INST_LIB and INST_ARCHLIB (where to install files
into), PERL_LIB and PERL_ARCHLIB (where to read existing modules
from), and PERL_INC (header files and C<libperl*.*>).

Extensions may be built either using the contents of the perl source
directory tree or from an installed copy of the perl library. The
recommended way is to build extensions after you have run 'make
install' on perl itself. Do that in a directory that is not below the
perl source tree. The support for extensions below the ext directory
of the perl distribution is only good for the standard extensions that
come with perl.

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
  INST_ARCHLIB = ./blib/<archname>

If perl has not yet been installed then PERL_SRC can be defined on the
command line as shown in the previous section.

=head2 Useful Default Makefile Macros

FULLEXT = Pathname for extension directory (eg DBD/Oracle).

BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT.

ROOTEXT = Directory part of FULLEXT with leading slash (eg /DBD)

INST_LIBDIR = C<$(INST_LIB)$(ROOTEXT)>

INST_AUTODIR = C<$(INST_LIB)/auto/$(FULLEXT)>

INST_ARCHAUTODIR = C<$(INST_ARCHLIB)/auto/$(FULLEXT)>

=head2 Using Attributes (and Parameters)

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
so

=item CONFIGURE

CODE reference. Extension writers are requested to do all their
initializing within that subroutine. The subroutine
should return a hash reference. The hash may contain
further attributes, e.g. {LIBS => ...}, that have to
be determined by some evaluation method.

=item DEFINE

Something like C<"-DHAVE_UNISTD_H">

=item DIR

Ref to array of subdirectories containing Makefile.PLs e.g. [ 'sdbm'
] in ext/SDBM_File

=item DISTNAME

Your name for distributing the package (by tar file) This defaults to
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

Used by 'make install', which sets INST_ARCHLIB to this value.

=item INSTALLBIN

Used by 'make install' which sets INST_EXE to this value.

=item INSTALLMAN1DIR

This directory gets the man pages at 'make install' time. Defaults to
$Config{installman1dir}.

=item INSTALLMAN3DIR

This directory gets the man pages at 'make install' time. Defaults to
$Config{installman3dir}.

=item INSTALLPRIVLIB

Used by 'make install', which sets INST_LIB to this value.

=item INST_ARCHLIB

Same as INST_LIB for architecture dependent files.

=item INST_EXE

Directory, where executable scripts should be installed during
'make'. Defaults to "./blib/ARCHNAME", just to have a dummy
location during testing. make install will set
INST_EXE to INSTALLBIN.

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

'static' or 'dynamic' (default unless usedl=undef in config.sh) Should
only be used to force static linking (also see
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

=item NORECURS

Boolean. Experimental attribute to inhibit descending into
subdirectories.

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
INSTALLMAN1DIR).  They will have PREFIX as a common directory node and
will branch from that node into lib/, lib/ARCHNAME, and bin/ unless
you override one of them.

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
    ( $VERSION ) = '$Revision: 1.141 $ ' =~ /\$Revision:\s+([^\s]+)/;
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
F<E<lt>bailey@HMIVAX.HUMGEN.UPENN.EDUE<gt>>. Contact the makemaker
mailing list C<mailto:makemaker@franz.ww.tu-berlin.de>, if you have any
questions.

=head1 MODIFICATION HISTORY

For a more complete documentation see the file Changes in the
MakeMaker distribution package.

=head1 TODO

See the file Todo in the MakeMaker distribution package.

=cut
