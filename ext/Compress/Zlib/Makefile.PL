#! perl -w

use strict ;
require 5.004 ;

use ExtUtils::MakeMaker 5.16 ;
use Config qw(%Config) ;
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
my $WALL = '' ;
my $GZIP_OS_CODE = -1 ;

#$WALL = ' -pedantic ' if $Config{'cc'} =~ /gcc/ ;
$WALL = ' -Wall ' if $Config{'cc'} =~ /gcc/ ;

# don't ask if MM_USE_DEFAULT is set -- enables perl core building on cygwin
if ($^O =~ /cygwin/i and not $ENV{PERL_MM_USE_DEFAULT})
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

my @files = ('Zlib.pm', 't/ZlibTestUtils.pm',
             glob("t/*.t"), 
             glob("lib/IO/Compress/*.pm"),
             glob("lib/IO/Uncompress/*.pm"),
             glob("lib/Compress/Zlib/*.pm"),
             glob("lib/Compress/Gzip/*.pm"),
             glob("lib/File/*.pm"),
             grep(!/\.bak$/,  glob("examples/*"))) ;

UpDowngrade(@files) unless $ENV{PERL_CORE};

WriteMakefile(	
	NAME   	 	=> 'Compress::Zlib',
	VERSION_FROM => 'Zlib.pm',
	INC      	=> "-I$ZLIB_INCLUDE" ,
	DEFINE   	=> "$OLD_ZLIB $WALL -DGZIP_OS_CODE=$GZIP_OS_CODE" ,
	XS	 	    => { 'Zlib.xs'    => 'Zlib.c' },
	PREREQ_PM   => { 'Scalar::Util'  => 0,
                     $] >= 5.005 && $] < 5.006   ? ('File::BSDGlob' => 0) : () },
	'depend' 	=> { 'Makefile'	  => 'config.in' },
	'clean' 	=> { FILES        => '*.c constants.h constants.xs' },
	'dist'	 	=> { COMPRESS     => 'gzip', 
		             SUFFIX       => 'gz',
			     DIST_DEFAULT => 'MyDoubleCheck downgrade tardist',
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
	Z_BLOCK
	Z_BUF_ERROR
	Z_DATA_ERROR
	Z_DEFAULT_COMPRESSION
	Z_DEFAULT_STRATEGY
        Z_DEFLATED
	Z_ERRNO
	Z_FILTERED
	Z_FINISH
	Z_FIXED
	Z_FULL_FLUSH
	Z_HUFFMAN_ONLY
	Z_MEM_ERROR
	Z_NEED_DICT
	Z_NO_COMPRESSION
	Z_NO_FLUSH
	Z_NULL
	Z_OK
	Z_PARTIAL_FLUSH
	Z_RLE
	Z_STREAM_END
	Z_STREAM_ERROR
	Z_SYNC_FLUSH
	Z_UNKNOWN
	Z_VERSION_ERROR

	);
    #ZLIB_VERNUM

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
    foreach my $name (qw( constants.h constants.xs ))
    {
        my $from = catfile('fallback', $name);
        copy ($from, $name)
          or die "Can't copy $from to $name: $!";
    }
}

sub MY::libscan
{
    my $self = shift;
    my $path = shift;

    return undef
        if $path =~ /(~|\.bak|_bak)$/ ||
           $path =~ /\..*\.swp$/ ;

    return $path;
}

sub MY::postamble 
{
    my $postamble = <<'EOM';

downgrade:
	@echo Downgrading.
	perl Makefile.PL -downgrade

MyDoubleCheck:	
	@echo Checking config.in is setup for a release
	@(grep '^LIB *= *./zlib-src' config.in &&			\
	  grep '^INCLUDE *= *./zlib-src' config.in &&		\
	  grep '^OLD_ZLIB *= *False' config.in &&		\
	  grep '^GZIP_OS_CODE *= *AUTO_DETECT' config.in &&		\
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

longtest:
	@echo Running test suite with Devel::Cover
	$(MAKE) test COMPRESS_ZLIB_RUN_ALL=1 

cover:
	@echo Running test suite with Devel::Cover
	HARNESS_PERL_SWITCHES=-MDevel::Cover $(MAKE) test

longcover:
	@echo Running test suite with Devel::Cover
	HARNESS_PERL_SWITCHES=-MDevel::Cover $(MAKE) test COMPRESS_ZLIB_RUN_ALL=1 

test-utf8:
	@echo Running test suite with utf-8 enabled
	env LC_ALL=en_GB.UTF-8 $(MAKE) test	

test-utf8de:
	@echo Running test suite with utf-8 and non-english enabled
	env LC_ALL=de_DE.UTF-8 $(MAKE) test	

EOM

    $postamble .= <<'EOM' if $^O eq 'linux' ;

gcov:
	@echo Running test suite with gcov and Devel::Cover [needs gcc 3.4?]
	#@test  "${CC}" = "gcc" || (echo 'gcov' needs gcc, you have ${CC} ; exit 1)
	rm -f *.o *.gcov *.da *.bbg *.bb *.gcno 
	$(MAKE) OPTIMIZE=-g DEFINE="-fprofile-arcs -ftest-coverage"
	HARNESS_PERL_SWITCHES=-MDevel::Cover $(MAKE) test
    #gcov Zlib.xs
    #gcov2perl -db cover_db Zlib.xs.gcov

EOM

    return $postamble;

}

sub ParseCONFIG
{
    my ($k, $v) ;
    my @badkey = () ;
    my %Info = () ;
    my @Options = qw( INCLUDE LIB BUILD_ZLIB OLD_ZLIB GZIP_OS_CODE ) ;
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


	# write the Makefile
	print "Building Zlib enabled\n" ;
    }

    $GZIP_OS_CODE = defined $ENV{'GZIP_OS_CODE'} 
                          ? $ENV{'GZIP_OS_CODE'} 
                          : $Info{'GZIP_OS_CODE'} ;

	die "GZIP_OS_CODE not 'AUTO_DETECT' or a number between 0 and 255\n"
	   unless uc $GZIP_OS_CODE eq 'AUTO_DETECT'
                    || ( $GZIP_OS_CODE =~ /^(\d+)$/ && $1 >= 0 && $1 <= 255) ;

    if (uc $GZIP_OS_CODE eq 'AUTO_DETECT')
    {
        print "Auto Detect Gzip OS Code..\n" ;
        $GZIP_OS_CODE = getOSCode() ;
    }
    
    my $name = getOSname($GZIP_OS_CODE);
    print "Setting Gzip OS Code to $GZIP_OS_CODE [$name]\n" ;

    print <<EOM if 0 ;
    INCLUDE         [$ZLIB_INCLUDE]
    LIB             [$ZLIB_LIB]
    GZIP_OS_CODE    [$GZIP_OS_CODE]
    OLD_ZLIB        [$OLD_ZLIB]
    BUILD_ZLIB      [$BUILD_ZLIB]

EOM

    print "Looks Good.\n" ;

}

sub UpDowngrade
{
    my @files = @_ ;

    # our and use bytes/utf8 is stable from 5.6.0 onward
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
	    elsif ( /^(\s*)((use|no)\s+(bytes|utf8)\s*;.*)$/)
            {
                $_ = "$1# $2\n";
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
	    elsif ( /^(\s*)#\s*((use|no)\s+(bytes|utf8)\s*;.*)$/)
            {
                $_ = "$1$2\n";
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

    return if -d $_[0];

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
    		      compress deflate inffast  inftrees  
    		      trees    zutil 
    		 );
    }
    else {
        # zlib 1.1.x
    
        @h_files = qw(deflate.h  infcodes.h inftrees.h zconf.h zutil.h
    		      infblock.h inffast.h  infutil.h  zlib.h
    		 );
        @c_files = qw(adler32  compress crc32    uncompr
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



my @GZIP_OS_Names ;
my %OSnames ;

BEGIN
{
  @GZIP_OS_Names = (
    [ ''        => 0,    'MS-DOS'                       ],
    [ 'amigaos' => 1,    'Amiga'                        ],
    [ 'VMS'     => 2,    'VMS'                          ],
    [ ''        => 3,    'Unix/Default'                 ],
    [ ''        => 4,    'VM/CMS'                       ],
    [ ''        => 5,    'Atari TOS'                    ],
    [ 'os2'     => 6,    'HPFS (OS/2, NT)'              ],
    [ 'MacOS'   => 7,    'Macintosh'                    ],
    [ ''        => 8,    'Z-System'                     ],
    [ ''        => 9,    'CP/M'                         ],
    [ ''        => 10,   'TOPS-20'                      ],
    [ ''        => 11,   'NTFS (NT)'                    ],
    [ ''        => 12,   'SMS QDOS'                     ],
    [ ''        => 13,   'Acorn RISCOS'                 ],
    [ 'MSWin32' => 14,   'VFAT file system (Win95, NT)' ],
    [ ''        => 15,   'MVS'                          ],
    [ 'beos'    => 16,   'BeOS'                         ],
    [ ''        => 17,   'Tandem/NSK'                   ],
    [ ''        => 18,   'THEOS'                        ],
    [ ''        => 255,  'Unknown OS'                   ],
  );

  %OSnames = map { $$_[1] => $$_[2] }  
             @GZIP_OS_Names ;
}

sub getOSCode
{
    my $default = 3 ; # Unix is the default

    my $uname = $^O;

    for my $h (@GZIP_OS_Names)
    {
        my ($pattern, $code, $name) = @$h;

        return $code
            if $pattern && $uname eq $pattern ;
    }

    return $default ;
}

sub getOSname
{
    my $code = shift ;

    return $OSnames{$code} || 'Unknown OS' ;
}

# end of file Makefile.PL

