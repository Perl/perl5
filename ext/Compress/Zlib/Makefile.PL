#! perl -w

use strict ;
require 5.004 ;

use ExtUtils::MakeMaker 5.16 ;
use Config ;
use File::Copy ;

BEGIN
{
    eval { require File::Spec::Functions ; File::Spec::Functions->import() } ;
    if ($@)
    {
        *catfile = sub { return "$_[0]/$_[1]" }
    }
}

require VMS::Filespec if $^O eq 'VMS';

my $ZLIB_LIB ;
my $ZLIB_INCLUDE ;
my $BUILD_ZLIB = 0 ;
my $OLD_ZLIB = '' ;
my $EXTRA_DEFINE = '';
my $WALL = '';
#$WALL = ' -Wall ';

unless($ENV{PERL_CORE}) {
    $ENV{PERL_CORE} = 1 if grep { $_ eq 'PERL_CORE=1' } @ARGV;
}

# don't ask if MM_USE_DEFAULT is set -- enables perl core building on cygwin
if ($^O =~ /cygwin/i and not $ENV{PERL_MM_USE_DEFAULT} and not $ENV{PERL_CORE})
{
    print <<EOM ;

I see you are running Cygwin.

Please note that this module cannot be installed on Cygwin using the
CPAN shell. The CPAN Shell uses Compress::Zlib internally and it is not
possible to delete an active DLL.

If you are running the CPAN shell, please exit it and install this module
by hand by running 'make install' under the directory

    ~/.cpan/build/Compress-Zlib-VERSION

EOM

    print "Do you want to continue? [Y/N]: " ;
    my $answer = <STDIN> ;

    if ($answer =~ /^yes|y/i)
    {
	print "continuing...\n" 
    }
    else
    {
	print "exiting...\n" ;
	exit 1 ;
    }


}

ParseCONFIG() ;

my @files = ('Zlib.pm', glob("t/*.t"), grep(!/\.bak$/,  glob("examples/*"))) ;
UpDowngrade(@files) unless $ENV{PERL_CORE} ;

WriteMakefile(	
	NAME   	 	=> 'Compress::Zlib',
	VERSION_FROM  	=> 'Zlib.pm',
	INC      	=> "-I$ZLIB_INCLUDE" ,
	DEFINE   	=> "$OLD_ZLIB $WALL $EXTRA_DEFINE" ,
	XS	 	=> { 'Zlib.xs'    => 'Zlib.c' },
	'depend' 	=> { 'Makefile'	  => 'config.in' },
	'clean' 	=> { FILES        => '*.c constants.h constants.xs' },
	'dist'	 	=> { COMPRESS     => 'gzip', 
		             SUFFIX       => 'gz',
			     DIST_DEFAULT => 'MyDoubleCheck Downgrade tardist',
			    },
	($BUILD_ZLIB
          ? zlib_files($ZLIB_LIB)
	  : (LIBS	=> [ "-L$ZLIB_LIB -lz " ])
	),  
	($] >= 5.005
	    ? (ABSTRACT_FROM	=> 'Zlib.pm',
	       AUTHOR  => 'Paul Marquess <pmqs@cpan.org>')
	    : ()
	),
    ) ;

my @names = qw(

	DEF_WBITS
        MAX_MEM_LEVEL
	MAX_WBITS
	OS_CODE

	Z_ASCII
	Z_BEST_COMPRESSION
	Z_BEST_SPEED
	Z_BINARY
	Z_BUF_ERROR
	Z_DATA_ERROR
	Z_DEFAULT_COMPRESSION
	Z_DEFAULT_STRATEGY
        Z_DEFLATED
	Z_ERRNO
	Z_FILTERED
	Z_FINISH
	Z_FULL_FLUSH
	Z_HUFFMAN_ONLY
	Z_MEM_ERROR
	Z_NEED_DICT
	Z_NO_COMPRESSION
	Z_NO_FLUSH
	Z_NULL
	Z_OK
	Z_PARTIAL_FLUSH
	Z_STREAM_END
	Z_STREAM_ERROR
	Z_SYNC_FLUSH
	Z_UNKNOWN
	Z_VERSION_ERROR
	);

if (eval {require ExtUtils::Constant; 1}) {
    # Check the constants above all appear in @EXPORT in Zlib.pm
    my %names = map { $_, 1} @names, 'ZLIB_VERSION';
    open F, "<Zlib.pm" or die "Cannot open Zlib.pm: $!\n";
    while (<F>)
    {
        last if /^\s*\@EXPORT\s+=\s+qw\(/ ;
    }

    while (<F>)
    {
        last if /^\s*\)/ ;
        /(\S+)/ ;
        delete $names{$1} if defined $1 ;
    }
    close F ;

    if ( keys %names )
    {
        my $missing = join ("\n\t", sort keys %names) ;
        die "The following names are missing from \@EXPORT in Zlib.pm\n" .
            "\t$missing\n" ;
    }
    
    push @names, {name => 'ZLIB_VERSION', type => 'PV' };

    ExtUtils::Constant::WriteConstants(
                                     NAME => 'Zlib',
                                     NAMES => \@names,
                                     C_FILE  => 'constants.h',
                                     XS_FILE  => 'constants.xs',
                                                                       
                                    );
} 
else {
    copy ('fallback.h', 'constants.h')
      or die "Can't copy fallback.h to constants.h: $!";
    copy ('fallback.xs', 'constants.xs')
      or die "Can't copy fallback.xs to constants.xs: $!";
}

sub MY::postamble 
{
    my $postamble = <<'EOM';

Downgrade:
	@echo Downgrading.
	perl Makefile.PL -downgrade

MyDoubleCheck:	
	@echo Checking config.in is setup for a release
	@(grep '^LIB *= *./zlib' config.in &&			\
	  grep '^INCLUDE *= *./zlib' config.in &&		\
	  grep '^OLD_ZLIB *= *False' config.in &&		\
	  grep '^BUILD_ZLIB *= *True' config.in) >/dev/null ||	\
	(echo config.in needs fixing ; exit 1)
	@echo config.in is ok

MyTrebleCheck:
	@echo Checking for $$^W in files: '. "@files" . '
	@perl -ne \'						\
	    exit 1 if /^\s*local\s*\(\s*\$$\^W\s*\)/;		\
         \' ' . " @files || " . '				\
	(echo found unexpected $$^W ; exit 1)
	@echo All is ok.

EOM

    return $postamble;

}

sub ParseCONFIG
{
    my ($k, $v) ;
    my @badkey = () ;
    my %Info = () ;
    my @Options = qw( INCLUDE LIB BUILD_ZLIB OLD_ZLIB ) ;
    my %ValidOption = map {$_, 1} @Options ;
    my %Parsed = %ValidOption ;
    my $CONFIG = 'config.in' ;

    print "Parsing $CONFIG...\n" ;

    open(F, "<$CONFIG") or die "Cannot open file $CONFIG: $!\n" ;
    while (<F>) {
	s/^\s*|\s*$//g ;
	next if /^\s*$/ or /^\s*#/ ;
	s/\s*#\s*$// ;

	($k, $v) = split(/\s+=\s+/, $_, 2) ;
	$k = uc $k ;
	if ($ValidOption{$k}) {
	    delete $Parsed{$k} ;
	    $Info{$k} = $v ;
	}
	else {
	    push(@badkey, $k) ;
	}
    }
    close F ;

    print "Unknown keys in $CONFIG ignored [@badkey]\n"
	if @badkey ;

    # check parsed values
    my @missing = () ;
    die "The following keys are missing from $CONFIG  [@missing]\n" 
        if @missing = keys %Parsed ;

    $ZLIB_INCLUDE = $ENV{'ZLIB_INCLUDE'} || $Info{'INCLUDE'} ;
    $ZLIB_LIB = $ENV{'ZLIB_LIB'} || $Info{'LIB'} ;

    if ($^O eq 'VMS') {
        $ZLIB_INCLUDE = VMS::Filespec::vmspath($ZLIB_INCLUDE);
        $ZLIB_LIB = VMS::Filespec::vmspath($ZLIB_LIB);
    }

    $EXTRA_DEFINE = $ENV{EXTRA_DEFINE} if defined $ENV{EXTRA_DEFINE};

    my $y = $ENV{'OLD_ZLIB'} || $Info{'OLD_ZLIB'} ;
    $OLD_ZLIB = '-DOLD_ZLIB' if $y and $y =~ /^yes|on|true|1$/i;

    my $x = $ENV{'BUILD_ZLIB'} || $Info{'BUILD_ZLIB'} ;

    if ($x and $x =~ /^yes|on|true|1$/i ) {

        $BUILD_ZLIB = 1 ;

	# ZLIB_LIB & ZLIB_INCLUDE must point to the same place when 
	# BUILD_ZLIB is specified.
	die "INCLUDE & LIB must be the same when BUILD_ZLIB is True\n"
	    if $ZLIB_LIB ne $ZLIB_INCLUDE ;

	# Check the zlib source directory exists
	die "LIB/INCLUDE directory '$ZLIB_LIB' does not exits\n"
	   unless -d $ZLIB_LIB ;

	# check for a well known file
	die "LIB/INCLUDE directory, '$ZLIB_LIB', doesn't seem to have the zlib source files\n"
	   unless -e catfile($ZLIB_LIB, 'zlib.h') ;


	# check Makefile.zlib has been copied to ZLIB_LIB
    #copy 'Makefile.zlib', catfile($ZLIB_LIB, 'Makefile.PL') ||
    #die "Could not copy Makefile.zlib to " . catfile($ZLIB_LIB, 'Makefile.PL') . ": $!\n" ;
       #print "Created a Makefile.PL for zlib\n" ;
	
	# write the Makefile
	print "Building Zlib enabled\n" ;
    }

    print <<EOM if 0 ;
    INCLUDE	[$ZLIB_INCLUDE]
    LIB		[$ZLIB_LIB]

EOM

    print "Looks Good.\n" ;

}

sub UpDowngrade
{
    my @files = @_ ;

    # our      is stable from 5.6.0 onward
    # warnings is stable from 5.6.1 onward

    # Note: this code assumes that each statement it modifies is not
    #       split across multiple lines.


    my $warn_sub = '';
    my $our_sub = '' ;

    my $opt = shift @ARGV || '' ;
    my $upgrade = ($opt =~ /^-upgrade/i);
    my $downgrade = ($opt =~ /^-downgrade/i);
    push @ARGV, $opt unless $downgrade || $upgrade;

    if ($downgrade) {
        # From: use|no warnings "blah"
        # To:   local ($^W) = 1; # use|no warnings "blah"
        $warn_sub = sub {
	    s/^(\s*)(no\s+warnings)/${1}local (\$^W) = 0; #$2/ ;
	    s/^(\s*)(use\s+warnings)/${1}local (\$^W) = 1; #$2/ ;
          };
    }
    elsif ($] >= 5.006001 || $upgrade) {
        # From: local ($^W) = 1; # use|no warnings "blah"
        # To:   use|no warnings "blah"
        $warn_sub = sub {
	    s/^(\s*)local\s*\(\$\^W\)\s*=\s*\d+\s*;\s*#\s*((no|use)\s+warnings.*)/$1$2/ ;
          };
    }

    if ($downgrade) {
        $our_sub = sub {
	    if ( /^(\s*)our\s+\(\s*([^)]+\s*)\)/ ) {
                my $indent = $1;
                my $vars = join ' ', split /\s*,\s*/, $2;
                $_ = "${indent}use vars qw($vars);\n";
            }
          };
    }
    elsif ($] >= 5.006000 || $upgrade) {
        $our_sub = sub {
	    if ( /^(\s*)use\s+vars\s+qw\((.*?)\)/ ) {
                my $indent = $1;
                my $vars = join ', ', split ' ', $2;
                $_ = "${indent}our ($vars);\n";
            }
          };
    }

    if (! $our_sub && ! $warn_sub) {
        warn "Up/Downgrade not needed.\n";
	if ($upgrade || $downgrade)
          { exit 0 }
        else
          { return }
    }

    foreach (@files)
      { doUpDown($our_sub, $warn_sub, $_) }

    warn "Up/Downgrade complete.\n" ;
    exit 0 if $upgrade || $downgrade;

}


sub doUpDown
{
    my $our_sub = shift;
    my $warn_sub = shift;

    local ($^I) = ($^O eq 'VMS') ? "_bak" : ".bak";
    local (@ARGV) = shift;

    while (<>)
    {
	print, last if /^__(END|DATA)__/ ;

	&{ $our_sub }() if $our_sub ;
	&{ $warn_sub }() if $warn_sub ;
	print ;
    }

    return if eof ;

    while (<>)
      { print }
}


sub zlib_files
{
    my $dir = shift ;

    my @h_files = ();
    my @c_files = ();
    
    if (-f catfile($dir, "infback.c")) {
        # zlib 1.2.0 or greater
        #
        @h_files = qw(crc32.h    inffast.h inflate.h  trees.h    zconf.in.h 
    	          zutil.h    deflate.h inffixed.h inftrees.h zconf.h  
    		  zlib.h 
    		 );
        @c_files = qw(adler32  crc32   infback  inflate  uncompr
    		  compress deflate gzio     inffast  inftrees  
    		  trees    zutil 
    		 );
    }
    else {
        # zlib 1.1.x
    
        @h_files = qw(deflate.h  infcodes.h inftrees.h zconf.h zutil.h
    		  infblock.h inffast.h  infutil.h  zlib.h
    		 );
        @c_files = qw(adler32  compress crc32    gzio    uncompr
    		  deflate  trees    zutil    inflate infblock
    		  inftrees infcodes infutil  inffast
    		 );
    }
    
    @h_files = map { catfile($dir, $_)  } @h_files ;
    my @o_files = map { "$_\$(OBJ_EXT)" } 'Zlib', @c_files;
    @c_files = map { "$_.c" } 'Zlib', @c_files ;

    foreach my $file (@c_files)
      { copy(catfile($dir, $file), '.') }
    
    return (
        #'H'         =>  [ @h_files ],
    	'C'         =>  [ @c_files ] ,
        #'OBJECT'    => qq[ @o_files ],
        'OBJECT'    => q[ $(O_FILES) ],
        

           ) ;
}


# end of file Makefile.PL

