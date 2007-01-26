### Module::Load::Conditional test suite ###
BEGIN { 
    if( $ENV{PERL_CORE} ) {
        chdir '../lib/Module/Load/Conditional' 
            if -d '../lib/Module/Load/Conditional';
        unshift @INC, '../../../..';
    
        ### fix perl location too
        $^X = '../../../../../t/' . $^X;
    }
} 

BEGIN { chdir 't' if -d 't' }

use strict;
use lib qw[../lib to_load];
use File::Spec ();

use Test::More tests => 23;

### case 1 ###
use_ok( 'Module::Load::Conditional' );

### stupid stupid warnings ###
{   $Module::Load::Conditional::VERBOSE =   
    $Module::Load::Conditional::VERBOSE = 0;

    *can_load       = *Module::Load::Conditional::can_load
                    = *Module::Load::Conditional::can_load;
    *check_install  = *Module::Load::Conditional::check_install
                    = *Module::Load::Conditional::check_install;
    *requires       = *Module::Load::Conditional::requires
                    = *Module::Load::Conditional::requires;
}

{
    my $rv = check_install(
                        module  => 'Module::Load::Conditional',
                        version => $Module::Load::Conditional::VERSION,
                );

    ok( $rv->{uptodate},    q[Verify self] );
    ok( $rv->{version} == $Module::Load::Conditional::VERSION,  
                            q[  Found proper version] );

    ok( $INC{'Module/Load/Conditional.pm'} eq
        File::Spec::Unix->catfile(File::Spec->splitdir($rv->{file}) ),
                            q[  Found proper file]
    );

}

{
    my $rv = check_install(
                        module  => 'Module::Load::Conditional',
                        version => $Module::Load::Conditional::VERSION + 1,
                );

    ok( !$rv->{uptodate} && $rv->{version} && $rv->{file},
        q[Verify out of date module]
    );
}

{
    my $rv = check_install( module  => 'Module::Load::Conditional' );

    ok( $rv->{uptodate} && $rv->{version} && $rv->{file},
        q[Verify any module]
    );
}

{
    my $rv = check_install( module  => 'Module::Does::Not::Exist' );

    ok( !$rv->{uptodate} && !$rv->{version} && !$rv->{file},
        q[Verify non-existant module]
    );

}

### test finding a version of a module that mentions $VERSION in pod
{   my $rv = check_install( module => 'InPod' );
    ok( $rv,                        'Testing $VERSION in POD' );
    ok( $rv->{version},             "   Version found" );
    is( $rv->{version}, 2,          "   Version is correct" );
}

### test $FIND_VERSION
{   local $Module::Load::Conditional::FIND_VERSION = 0;
    local $Module::Load::Conditional::FIND_VERSION = 0;
    
    my $rv = check_install( module  => 'Module::Load::Conditional' );

    ok( $rv,                        'Testing $FIND_VERSION' );
    is( $rv->{version}, undef,      "   No version info returned" );
    ok( $rv->{uptodate},            "   Module marked as uptodate" );
}    

### test 'can_load' ###

{
    my $use_list = { 'LoadIt' => 1 };
    my $bool = can_load( modules => $use_list );

    ok( $bool, q[Load simple module] );
}

{
    my $use_list = { 'Commented' => 2 };
    my $bool = can_load( modules => $use_list );

    ok( $bool, q[Load module with a second, commented-out $VERSION] );
}

{
    my $use_list = { 'Must::Be::Loaded' => 1 };
    my $bool = can_load( modules => $use_list );

    ok( !$bool, q[Detect out of date module] );
}

{
    delete $INC{'LoadIt.pm'};
    delete $INC{'Must/Be/Loaded.pm'};

    my $use_list = { 'LoadIt' => 1, 'Must::Be::Loaded' => 1 };
    my $bool = can_load( modules => $use_list );

    ok( !$INC{'LoadIt.pm'} && !$INC{'Must/Be/Loaded.pm'},
        q[Do not load if one prerequisite fails]
    );
}


### test 'requires' ###
SKIP:{
    skip "Depends on \$^X, which doesn't work well when testing the Perl core", 
        1 if $ENV{PERL_CORE};

    my %list = map { $_ => 1 } requires('Carp');
    
    my $flag;
    $flag++ unless delete $list{'Exporter'};

    ok( !$flag, q[Detecting requirements] );
}

### test using the %INC lookup for check_install
{   local $Module::Load::Conditional::CHECK_INC_HASH = 1;
    local $Module::Load::Conditional::CHECK_INC_HASH = 1;
    
    {   package A::B::C::D; 
        $A::B::C::D::VERSION = $$; 
        $INC{'A/B/C/D.pm'}   = $$.$$;
    }
    
    my $href = check_install( module => 'A::B::C::D', version => 0 );

    ok( $href,                  'Found package in %INC' );
    is( $href->{'file'}, $$.$$, '   Found correct file' );
    is( $href->{'version'}, $$, '   Found correct version' );
    ok( $href->{'uptodate'},    '   Marked as uptodate' );
    ok( can_load( modules => { 'A::B::C::D' => 0 } ),
                                '   can_load successful' );
}


