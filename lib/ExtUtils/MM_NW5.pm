package ExtUtils::MM_NW5;

=head1 NAME

ExtUtils::MM_NW5 - methods to override UN*X behaviour in ExtUtils::MakeMaker

=head1 SYNOPSIS

 use ExtUtils::MM_NW5; # Done internally by ExtUtils::MakeMaker if needed

=head1 DESCRIPTION

See ExtUtils::MM_Unix for a documentation of the methods provided
there. This package overrides the implementation of these methods, not
the semantics.

=over

=cut 

use Config;
use File::Basename;

use vars qw(@ISA $VERSION);
$VERSION = '2.01_01';

require ExtUtils::MM_Win32;
@ISA = qw(ExtUtils::MM_Win32);

use ExtUtils::MakeMaker qw( &neatvalue );

$ENV{EMXSHELL} = 'sh'; # to run `commands`

$BORLAND  = 1 if $Config{'cc'} =~ /^bcc/i;
$GCC      = 1 if $Config{'cc'} =~ /^gcc/i;
$DMAKE    = 1 if $Config{'make'} =~ /^dmake/i;
$NMAKE    = 1 if $Config{'make'} =~ /^nmake/i;
$PERLMAKE = 1 if $Config{'make'} =~ /^pmake/i;


sub init_others
{
 my ($self) = @_;
 $self->SUPER::init_others(@_);

 # incpath is copied to makefile var INCLUDE in constants sub, here just make it empty
 my $libpth = $Config{'libpth'};
 $libpth =~ s( )(;);
 $self->{'LIBPTH'} = $libpth;
 $self->{'BASE_IMPORT'} = $Config{'base_import'};
 
 # Additional import file specified from Makefile.pl
 if($self->{'base_import'}) {
	$self->{'BASE_IMPORT'} .= ',' . $self->{'base_import'};
 }
 
 $self->{'NLM_VERSION'} = $Config{'nlm_version'};
 $self->{'MPKTOOL'}	= $Config{'mpktool'};
 $self->{'TOOLPATH'}	= $Config{'toolpath'};
}


=item constants (o)

Initializes lots of constants and .SUFFIXES and .PHONY

=cut

# NetWare override
sub const_cccmd {
    my($self,$libperl)=@_;
    return $self->{CONST_CCCMD} if $self->{CONST_CCCMD};
    return '' unless $self->needs_linking();
    return $self->{CONST_CCCMD} =
	q{CCCMD = $(CC) $(INC) $(CCFLAGS) $(OPTIMIZE) \\
	$(PERLTYPE) $(LARGE) $(SPLIT) $(MPOLLUTE) \\
	-DVERSION="$(VERSION)" -DXS_VERSION="$(XS_VERSION)"};
}

sub constants {
    my($self) = @_;
    my(@m,$tmp);

# Added LIBPTH, BASE_IMPORT, ABSTRACT, NLM_VERSION BOOT_SYMBOL, NLM_SHORT_NAME
# for NETWARE

    for $tmp (qw/

	      AR_STATIC_ARGS NAME DISTNAME NAME_SYM VERSION
	      VERSION_SYM XS_VERSION INST_BIN INST_EXE INST_LIB
	      INST_ARCHLIB INST_SCRIPT PREFIX  INSTALLDIRS
	      INSTALLPRIVLIB INSTALLARCHLIB INSTALLSITELIB
	      INSTALLSITEARCH INSTALLBIN INSTALLSCRIPT PERL_LIB
	      PERL_ARCHLIB SITELIBEXP SITEARCHEXP LIBPERL_A MYEXTLIB
	      FIRST_MAKEFILE MAKE_APERL_FILE PERLMAINCC PERL_SRC
	      PERL_INC PERL FULLPERL LIBPTH BASE_IMPORT PERLRUN
          FULLPERLRUN PERLRUNINST FULLPERLRUNINST TEST_LIBS 
          FULL_AR PERL_CORE NLM_VERSION MPKTOOL TOOLPATH

	      / ) {
	next unless defined $self->{$tmp};
	push @m, "$tmp = $self->{$tmp}\n";
    }

	(my $boot = $self->{'NAME'}) =~ s/:/_/g;
	$self->{'BOOT_SYMBOL'}=$boot;
	push @m, "BOOT_SYMBOL = $self->{'BOOT_SYMBOL'}\n";

	# If the final binary name is greater than 8 chars,
	# truncate it here and rename it after creation
	# otherwise, Watcom Linker fails
	if(length($self->{'BASEEXT'}) > 8) {
		$self->{'NLM_SHORT_NAME'} = substr($self->{'NAME'},0,8);
		push @m, "NLM_SHORT_NAME = $self->{'NLM_SHORT_NAME'}\n";
	}

    push @m, qq{
VERSION_MACRO = VERSION
DEFINE_VERSION = -D\$(VERSION_MACRO)=\\\"\$(VERSION)\\\"
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = -D\$(XS_VERSION_MACRO)=\\\"\$(XS_VERSION)\\\"
};

	# Get the include path and replace the spaces with ;
	# Copy this to makefile as INCLUDE = d:\...;d:\;
	(my $inc = $Config{'incpath'}) =~ s/ /;/g;

	# Get the additional include path and append to INCLUDE, keep it in
	# INC will give problems during compilation, hence reset it after getting
	# the value
	(my $add_inc = $self->{'INC'}) =~ s/ -I/;/g;
	$self->{'INC'} = '';
 	push @m, qq{
INCLUDE = $inc;$add_inc;
};

	# Set the path to Watcom binaries which might not have been set in
	# any other place
	push @m, qq{
PATH = \$(PATH);\$(TOOLPATH)
};

    push @m, qq{
MAKEMAKER = $INC{'ExtUtils/MakeMaker.pm'}
MM_VERSION = $ExtUtils::MakeMaker::VERSION
};

    push @m, q{
# FULLEXT = Pathname for extension directory (eg Foo/Bar/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT. (eg Oracle)
# PARENT_NAME = NAME without BASEEXT and no trailing :: (eg Foo::Bar)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
};

    for $tmp (qw/
	      FULLEXT BASEEXT PARENT_NAME DLBASE VERSION_FROM INC DEFINE OBJECT
	      LDFROM LINKTYPE
	      /	) {
	next unless defined $self->{$tmp};
	push @m, "$tmp = $self->{$tmp}\n";
    }

    push @m, "
# Handy lists of source code files:
XS_FILES= ".join(" \\\n\t", sort keys %{$self->{XS}})."
C_FILES = ".join(" \\\n\t", @{$self->{C}})."
O_FILES = ".join(" \\\n\t", @{$self->{O_FILES}})."
H_FILES = ".join(" \\\n\t", @{$self->{H}})."
MAN1PODS = ".join(" \\\n\t", sort keys %{$self->{MAN1PODS}})."
MAN3PODS = ".join(" \\\n\t", sort keys %{$self->{MAN3PODS}})."
";

    for $tmp (qw/
	      INST_MAN1DIR        INSTALLMAN1DIR MAN1EXT
	      INST_MAN3DIR        INSTALLMAN3DIR MAN3EXT
	      /) {
	next unless defined $self->{$tmp};
	push @m, "$tmp = $self->{$tmp}\n";
    }

    push @m, qq{
.USESHELL :
} if $DMAKE;

    push @m, q{
.NO_CONFIG_REC: Makefile
} if $ENV{CLEARCASE_ROOT};

    # why not q{} ? -- emacs
    push @m, qq{
# work around a famous dec-osf make(1) feature(?):
makemakerdflt: all

.SUFFIXES: .xs .c .C .cpp .cxx .cc \$(OBJ_EXT)

# Nick wanted to get rid of .PRECIOUS. I don't remember why. I seem to recall, that
# some make implementations will delete the Makefile when we rebuild it. Because
# we call false(1) when we rebuild it. So make(1) is not completely wrong when it
# does so. Our milage may vary.
# .PRECIOUS: Makefile    # seems to be not necessary anymore

.PHONY: all config static dynamic test linkext manifest

# Where is the Config information that we are using/depend on
CONFIGDEP = \$(PERL_ARCHLIB)\\Config.pm \$(PERL_INC)\\config.h
};

    my @parentdir = split(/::/, $self->{PARENT_NAME});
    push @m, q{
# Where to put things:
INST_LIBDIR      = }. File::Spec->catdir('$(INST_LIB)',@parentdir)        .q{
INST_ARCHLIBDIR  = }. File::Spec->catdir('$(INST_ARCHLIB)',@parentdir)    .q{

INST_AUTODIR     = }. File::Spec->catdir('$(INST_LIB)','auto','$(FULLEXT)')       .q{
INST_ARCHAUTODIR = }. File::Spec->catdir('$(INST_ARCHLIB)','auto','$(FULLEXT)')   .q{
};

    if ($self->has_link_code()) {
	push @m, '
INST_STATIC  = $(INST_ARCHAUTODIR)\$(BASEEXT)$(LIB_EXT)
INST_DYNAMIC = $(INST_ARCHAUTODIR)\$(DLBASE).$(DLEXT)
INST_BOOT    = $(INST_ARCHAUTODIR)\$(BASEEXT).bs
';
    } else {
	push @m, '
INST_STATIC  =
INST_DYNAMIC =
INST_BOOT    =
';
    }

    $tmp = $self->export_list;
    push @m, "
EXPORT_LIST = $tmp
";
    $tmp = $self->perl_archive;
    push @m, "
PERL_ARCHIVE = $tmp
";

#    push @m, q{
#INST_PM = }.join(" \\\n\t", sort values %{$self->{PM}}).q{
#
#PM_TO_BLIB = }.join(" \\\n\t", %{$self->{PM}}).q{
#};

    push @m, q{
TO_INST_PM = }.join(" \\\n\t", sort keys %{$self->{PM}}).q{

PM_TO_BLIB = }.join(" \\\n\t", %{$self->{PM}}).q{
};

    join('',@m);
}


=item dynamic_lib (o)

Defines how to produce the *.so (or equivalent) files.

=cut

sub dynamic_lib {
	my($self, %attribs) = @_;
    return '' unless $self->needs_linking(); #might be because of a subdir

    return '' unless $self->has_link_code;

    my($otherldflags) = $attribs{OTHERLDFLAGS} || ($BORLAND ? 'c0d32.obj': '');
    my($inst_dynamic_dep) = $attribs{INST_DYNAMIC_DEP} || "";
    my($ldfrom) = '$(LDFROM)';
    my(@m);
	(my $boot = $self->{NAME}) =~ s/:/_/g;
	my ($mpk);
    push(@m,'
# This section creates the dynamically loadable $(INST_DYNAMIC)
# from $(OBJECT) and possibly $(MYEXTLIB).
OTHERLDFLAGS = '.$otherldflags.'
INST_DYNAMIC_DEP = '.$inst_dynamic_dep.'

$(INST_DYNAMIC): $(OBJECT) $(MYEXTLIB) $(BOOTSTRAP)
');
#      push(@m,
#      q{	$(LD) -out:$@ $(LDDLFLAGS) }.$ldfrom.q{ $(OTHERLDFLAGS) }
#      .q{$(MYEXTLIB) $(PERL_ARCHIVE) $(LDLOADLIBS) -def:$(EXPORT_LIST)});

		# Create xdc data for an MT safe NLM in case of mpk build
		if ( $self->{CCFLAGS} =~ m/ -DMPK_ON /) {
			$mpk=1;
			push @m, ' $(MPKTOOL) $(BASEEXT).xdc
';
		} else {
			$mpk=0;
		}

		push(@m,
			q{ $(LD) Form Novell NLM '$(DISTNAME) Extension, XS_VERSION=$(XS_VERSION)'} 
			);

		# Taking care of long names like FileHandle, ByteLoader, SDBM_File etc
		if($self->{NLM_SHORT_NAME}) {
			# In case of nlms with names exceeding 8 chars, build nlm in the 
			# current dir, rename and move to auto\lib.  If we create in auto\lib
			# in the first place, we can't rename afterwards.
			push(@m,
				q{ Name $(NLM_SHORT_NAME).$(DLEXT)}
				);
		} else {
			push(@m,
				q{ Name $(INST_AUTODIR)\\$(BASEEXT).$(DLEXT)}
				);
		}

		push(@m,
		   q{ Option Quiet Option Version = $(NLM_VERSION) Option Caseexact Option NoDefaultLibs Option screenname 'none' Option Synchronize }
		   );

		if ($mpk) {
		push (@m, 
		q{ Option XDCDATA=$(BASEEXT).xdc }
		);
		}

		# Add additional lib files if any (SDBM_File)
		if($self->{MYEXTLIB}) {
			push(@m,
				q{ Library $(MYEXTLIB) }
				);
		}

#For now lets comment all the Watcom lib calls
#q{ LibPath $(LIBPTH) Library plib3s.lib Library math3s.lib Library clib3s.lib Library emu387.lib Library $(PERL_ARCHIVE) Library $(PERL_INC)\Main.lib}

		push(@m,
				q{ Library $(PERL_ARCHIVE) Library $(PERL_INC)\Main.lib}			   
			   .q{ Export boot_$(BOOT_SYMBOL) $(BASE_IMPORT) }
			   .q{ FILE $(OBJECT:.obj=,)}
			);

		# If it is having a short name, rename it 
		if($self->{NLM_SHORT_NAME}) {
			push @m, '
 if exist $(INST_AUTODIR)\\$(BASEEXT).$(DLEXT) del $(INST_AUTODIR)\\$(BASEEXT).$(DLEXT)';
			push @m, '
 rename $(NLM_SHORT_NAME).$(DLEXT) $(BASEEXT).$(DLEXT)';
			push @m, '
 move $(BASEEXT).$(DLEXT) $(INST_AUTODIR)';
		}

    push @m, '
	$(CHMOD) 755 $@
';

    push @m, $self->dir_target('$(INST_ARCHAUTODIR)');
    join('',@m);
}


1;
__END__

=back

=cut 


