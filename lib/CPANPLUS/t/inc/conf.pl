BEGIN {
    use FindBin; 
    use File::Spec;
    
    ### paths to our own 'lib' and 'inc' dirs
    ### include them, relative from t/
    my @paths   = map { "$FindBin::Bin/$_" } qw[../lib inc];

    ### absolute'ify the paths in @INC;
    my @rel2abs = map { File::Spec->rel2abs( $_ ) }
                    grep { not File::Spec->file_name_is_absolute( $_ ) } @INC;
    
    ### use require to make devel::cover happy
    require lib;
    for ( @paths, @rel2abs ) { 
        my $l = 'lib'; 
        $l->import( $_ ) 
    }

    use Config;

    ### and add them to the environment, so shellouts get them
    $ENV{'PERL5LIB'} = join ':', 
                        grep { defined } $ENV{'PERL5LIB'}, @paths, @rel2abs;
    
    ### add our own path to the front of $ENV{PATH}, so that cpanp-run-perl
    ### and friends get picked up
    $ENV{'PATH'} = join $Config{'path_sep'}, 
                    grep { defined } "$FindBin::Bin/../bin", $ENV{'PATH'};

    ### Fix up the path to perl, as we're about to chdir
    ### but only under perlcore, or if the path contains delimiters,
    ### meaning it's relative, but not looked up in your $PATH
    $^X = File::Spec->rel2abs( $^X ) 
        if $ENV{PERL_CORE} or ( $^X =~ m|[/\\]| );

    ### chdir to our own test dir, so we know all files are relative 
    ### to this point, no matter whether run from perlcore tests or
    ### regular CPAN installs
    chdir "$FindBin::Bin" if -d "$FindBin::Bin"
}

BEGIN {
    use IPC::Cmd;
   
    ### Win32 has issues with redirecting FD's properly in IPC::Run:
    ### Can't redirect fd #4 on Win32 at IPC/Run.pm line 2801
    $IPC::Cmd::USE_IPC_RUN = 0 if $^O eq 'MSWin32';
    $IPC::Cmd::USE_IPC_RUN = 0 if $^O eq 'MSWin32';
}

use strict;
use CPANPLUS::Configure;

use File::Path      qw[rmtree];
use FileHandle;
use File::Basename  qw[basename];

{   ### Force the ignoring of .po files for L::M::S
    $INC{'Locale::Maketext::Lexicon.pm'} = __FILE__;
    $Locale::Maketext::Lexicon::VERSION = 0;
}

# prereq has to be in our package file && core!
use constant TEST_CONF_PREREQ           => 'Cwd';   
use constant TEST_CONF_MODULE           => 'Foo::Bar::EU::NOXS';
use constant TEST_CONF_INST_MODULE      => 'Foo::Bar';
use constant TEST_CONF_INVALID_MODULE   => 'fnurk';
use constant TEST_CONF_MIRROR_DIR       => 'dummy-localmirror';

### we might need this Some Day when we're installing into
### our own sandbox. see t/20.t for details
# use constant TEST_INSTALL_DIR       => do {
#     my $dir = File::Spec->rel2abs( 'dummy-perl' );
# 
#     ### clean up paths if we are on win32    
#     ### dirs with spaces will be.. bad :(
#     $^O eq 'MSWin32'
#         ? Win32::GetShortPathName( $dir )
#         : $dir;
# };        

# use constant TEST_INSTALL_DIR_LIB 
#     => File::Spec->catdir( TEST_INSTALL_DIR, 'lib' );
# use constant TEST_INSTALL_DIR_BIN 
#     => File::Spec->catdir( TEST_INSTALL_DIR, 'bin' );
# use constant TEST_INSTALL_DIR_MAN1 
#     => File::Spec->catdir( TEST_INSTALL_DIR, 'man', 'man1' );
# use constant TEST_INSTALL_DIR_MAN3
#     => File::Spec->catdir( TEST_INSTALL_DIR, 'man', 'man3' );
# use constant TEST_INSTALL_DIR_ARCH
#     => File::Spec->catdir( TEST_INSTALL_DIR, 'arch' );
# 
# use constant TEST_INSTALL_EU_MM_FLAGS =>
#     ' INSTALLDIRS=site' .
#     ' INSTALLSITELIB='     . TEST_INSTALL_DIR_LIB .
#     ' INSTALLSITEARCH='    . TEST_INSTALL_DIR_ARCH .    # .packlist
#     ' INSTALLARCHLIB='     . TEST_INSTALL_DIR_ARCH .    # perllocal.pod
#     ' INSTALLSITEBIN='     . TEST_INSTALL_DIR_BIN .
#     ' INSTALLSCRIPT='      . TEST_INSTALL_DIR_BIN .
#     ' INSTALLSITEMAN1DIR=' . TEST_INSTALL_DIR_MAN1 .
#     ' INSTALLSITEMAN3DIR=' . TEST_INSTALL_DIR_MAN3;


sub gimme_conf { 
    my $conf = CPANPLUS::Configure->new();
    $conf->set_conf( hosts  => [ { 
                        path        => 'dummy-CPAN',
                        scheme      => 'file',
                    } ],      
    );
    $conf->set_conf( base       => 'dummy-cpanplus' );
    $conf->set_conf( dist_type  => '' );
    $conf->set_conf( signature  => 0 );

    _clean_test_dir( [
        $conf->get_conf('base'),     
        TEST_CONF_MIRROR_DIR,
#         TEST_INSTALL_DIR_LIB,
#         TEST_INSTALL_DIR_BIN,
#         TEST_INSTALL_DIR_MAN1, 
#         TEST_INSTALL_DIR_MAN3,
    ], 1 );
        
    return $conf;
};

{
    my $fh;
    my $file = ".".basename($0).".output";
    sub output_handle {
        return $fh if $fh;
        
        $fh = FileHandle->new(">$file")
                    or warn "Could not open output file '$file': $!";
       
        $fh->autoflush(1);
        return $fh;
    }
    
    sub output_file { return $file }
}


### clean these files if we're under perl core
END { 
    if ( $ENV{PERL_CORE} ) {
        close output_handle(); 1 while unlink output_file();

        _clean_test_dir( [
            gimme_conf->get_conf('base'),   
            TEST_CONF_MIRROR_DIR,
    #         TEST_INSTALL_DIR_LIB,
    #         TEST_INSTALL_DIR_BIN,
    #         TEST_INSTALL_DIR_MAN1, 
    #         TEST_INSTALL_DIR_MAN3,
        ], 1 );
    }
}



### whenever we start a new script, we want to clean out our
### old files from the test '.cpanplus' dir..
sub _clean_test_dir {
    my $dirs    = shift || [];
    my $verbose = shift || 0;

    for my $dir ( @$dirs ) {

        my $dh;
        opendir $dh, $dir or die "Could not open basedir '$dir': $!";
        while( my $file = readdir $dh ) { 
            next if $file =~ /^\./;  # skip dot files
            
            my $path = File::Spec->catfile( $dir, $file );
            
            ### directory, rmtree it
            if( -d $path ) {
                print "Deleting directory '$path'\n" if $verbose;
                eval { rmtree( $path ) };
                warn "Could not delete '$path' while cleaning up '$dir'" if $@;
           
            ### regular file
            } else {
                print "Deleting file '$path'\n" if $verbose;
                1 while unlink $path;
            }            
        }       
    
        close $dh;
    }
    
    return 1;
}
1;
