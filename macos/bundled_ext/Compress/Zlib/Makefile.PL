#! perl -w
use strict ;
require 5.004 ;
use ExtUtils::MakeMaker 5.16 ;
use Config ;
#use File::Copy ;

my $ZLIB_LIB ;
my $ZLIB_INCLUDE ;
my $BUILD_ZLIB = 0 ;

ParseCONFIG() ;

my @files ;#= ('Zlib.pm', glob("t/*.t"), grep(!/\.bak$/,  glob("examples/*"))) ;
UpDowngrade(@files);

WriteMakefile(	
	NAME   	 	=> 'Compress::Zlib',
	VERSION_FROM  	=> 'Zlib.pm',
	INC      	=> "-I$ZLIB_INCLUDE" ,
	XS	 	=> { 'Zlib.xs' => 'Zlib.c' },
	'depend' 	=> { 'Makefile'	=> 'config.in' },
	'clean' 	=> { FILES => 'constants.h constants.xs' },
	'dist'	 	=> { COMPRESS=>'gzip', SUFFIX=>'gz',
			     DIST_DEFAULT => 'MyDoubleCheck Downgrade tardist',
			    },
	($BUILD_ZLIB
	  ? (MYEXTLIB	=> "$ZLIB_LIB/libz\$(LIB_EXT)")
	  : (LIBS	=> [ "-L$ZLIB_LIB -lz " ])
	),  
	($] >= 5.005
	    ? (ABSTRACT_FROM	=> 'Zlib.pm',
	       AUTHOR  	=> 'Paul Marquess <Paul.Marquess@btinternet.com>')
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
#    use File::Copy;
#    copy ('fallback.h', 'constants.h')
#      or die "Can't copy fallback.h to constants.h: $!";
#    copy ('fallback.xs', 'constants.xs')
#      or die "Can't copy fallback.xs to constants.xs: $!";
}

sub MY::postamble {
    my $postamble = '

Downgrade:
	@echo Downgrading.
	perl Makefile.PL -downgrade

MyDoubleCheck:	
	@echo Checking config.in is setup for a release
	@(grep "^LIB.*/usr/local/lib" config.in && 		\
	grep "^INCLUDE.*/usr/local/include" config.in &&	\
	grep "^BUILD_ZLIB.*False" config.in) >/dev/null ||		\
	(echo config.in needs fixing ; exit 1)
	@echo config.in is ok

MyTrebleCheck:
	@echo Checking for $$^W in files: '. "@files" . '
	@perl -ne \'						\
	    exit 1 if /^\s*local\s*\(\s*\$$\^W\s*\)/;		\
         \' ' . " @files || " . '				\
	(echo found unexpected $$^W ; exit 1)
	@echo All is ok.

Zlib.xs:	typemap
	@$(TOUCH) Zlib.xs

' ;

    if ($BUILD_ZLIB) {
        $postamble .=<<END ;
\$(MYEXTLIB): $ZLIB_LIB/Makefile
END
        $postamble .=<<END unless $^O eq 'MSWin32';
	DEFINE='\$(DEFINE)'; export DEFINE INC; \\
END

        $postamble .= ($^O eq 'MSWin32') ? <<END1 : <<END2;
	cd $ZLIB_LIB && \$(MAKE) all DEFINE=\$(DEFINE)
END1
	cd $ZLIB_LIB && \$(MAKE) -e all
END2
    }

    $postamble;
}

sub ParseCONFIG
{
    my ($k, $v) ;
    my @badkey = () ;
    my %Info = () ;
    my @Options = qw( INCLUDE LIB BUILD_ZLIB ) ;
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
    die "The following keys are missing from $CONFIG file: [@missing]\n" 
        if @missing = keys %Parsed ;

    $ZLIB_INCLUDE = $ENV{'ZLIB_INCLUDE'} || $Info{'INCLUDE'} ;
    $ZLIB_LIB = $ENV{'ZLIB_LIB'} || $Info{'LIB'} ;
    my $x = $ENV{'BUILD_ZLIB'} || $Info{'BUILD_ZLIB'} ;

    if ($x and $x =~ /^yes|on|true|1$/i ) {

        $BUILD_ZLIB = 1 ;

	# Check the zlib source directory exists
	die "ZLIB_LIB directory '$ZLIB_LIB' does not exits\n"
	   unless -d $ZLIB_LIB ;

	# check for a well known file
	die "ZLIB_LIB directory, '$ZLIB_LIB', doesn't seem to have the zlib source files\n"
	   unless -e "$ZLIB_LIB/zlib.h" ;


	# check Makefile.NT has been copied to ZLIB_DIR
	if (! -e "$ZLIB_LIB/Makefile.PL") {
#	    copy 'Makefile.NT', "$ZLIB_LIB/Makefile.PL" ||
#	       die "Could not copy Makefile.NT to $ZLIB_LIB/Makefile.PL: $!\n" ;
	    print "Created a Makefile.PL for zlib\n" ;
	}
	
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

    local ($^I) = ".bak" ;
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

# end of file Makefile.PL
