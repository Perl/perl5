#! perl -w
use strict ;
require 5.004 ;
use ExtUtils::MakeMaker 5.16 ;
use Config ;
use File::Copy ;

my $ZLIB_LIB ;
my $ZLIB_INCLUDE ;
my $BUILD_ZLIB = 0 ;

ParseCONFIG() ;

my @files = ('Zlib.pm', glob("t/*.t"), grep(!/\.bak$/,  glob("examples/*"))) ;
# warnings pragma is stable from 5.6.1 onward
if ($] < 5.006001)
 { oldWarnings(@files) }
else
 { newWarnings(@files) }    

WriteMakefile(	
	NAME   	 	=> 'Compress::Zlib',
	VERSION_FROM  	=> 'Zlib.pm',
	INC      	=> "-I$ZLIB_INCLUDE" ,
	'dist'	 	=> {COMPRESS=>'gzip', SUFFIX=>'gz',
			    DIST_DEFAULT => 'MyDoubleCheck tardist',
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

sub MY::postamble {
    my $postamble =<<'END';

MyDoubleCheck:	
	@echo Checking config.in is setup for a release
	@(grep '^LIB.*/usr/local/lib' config.in && 		\
	grep '^INCLUDE.*/usr/local/include' config.in &&	\
	grep '^BUILD_ZLIB.*False' config.in) >/dev/null ||		\
	(echo config.in needs fixing ; exit 1)
	@echo config.in is ok

Zlib.xs:	typemap
	@$(TOUCH) Zlib.xs

Makefile:	config.in

END

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
	    copy 'Makefile.NT', "$ZLIB_LIB/Makefile.PL" ||
	       die "Could not copy Makefile.NT to $ZLIB_LIB/Makefile.PL: $!\n" ;
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

sub oldWarnings
{
    local ($^I) = ".bak" ;
    local (@ARGV) = @_ ;

    while (<>)
    {
	if (/^__END__/)
	{
	    print ;
	    my $this = $ARGV ;
    	    while (<>)
	    {
		last if $ARGV ne $this ;
		print ;
	    }
	}

	s/^(\s*)(no\s+warnings)/${1}local (\$^W) = 0; #$2/ ;
	s/^(\s*)(use\s+warnings)/${1}local (\$^W) = 1; #$2/ ;
	print ;
    }
}

sub newWarnings
{
    local ($^I) = ".bak" ;
    local (@ARGV) = @_ ;

    while (<>)
    {
	if (/^__END__/)
	{
	    my $this = $ARGV ;
	    print ;
    	    while (<>)
	    {
		last if $ARGV ne $this ;
		print ;
	    }
	}

	s/^(\s*)local\s*\(\$\^W\)\s*=\s*\d+\s*;\s*#\s*((no|use)\s+warnings.*)/$1$2/ ;
	print ;
    }
}

# end of file Makefile.PL
