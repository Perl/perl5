BEGIN {
    # We're not going to chdir() into 't' because we don't know if
    # chdir() works!  Instead, we'll hedge our bets and put both
    # possibilities into @INC.
    @INC = ('lib', '../lib');
}


# Might be a little early in the testing process to start using these,
# but I can't think of a way to write this test without them.
use Cwd qw(abs_path cwd);
use File::Spec::Functions qw(:DEFAULT splitdir);

use Test::More tests => 25;

my $cwd = abs_path;

# Let's get to a known position
SKIP: {
    skip("Already in t/", 2) if (splitdir(abs_path))[-1] eq 't';

    ok( chdir('t'),     'chdir("t")');
    is( abs_path, catdir($cwd, 't'),       '  abs_path() agrees' );
}

$cwd = abs_path;

# The environment variables chdir() pays attention to.
my @magic_envs = qw(HOME LOGDIR SYS$LOGIN);

foreach my $key (@magic_envs) {
    # We're going to be using undefs a lot here.
    no warnings 'uninitialized';

    delete @ENV{@magic_envs};
    local $ENV{$key} = catdir $cwd, 'op';
    
    # Make sure $ENV{'SYS$LOGIN'} is only honored on VMS.
    if( $key eq 'SYS$LOGIN' && $^O ne 'VMS' ) {
        ok( !chdir(),             "chdir() on $^O ignores only \$ENV{$key} set" );
        is( abs_path, $cwd,       '  abs_path() did not change' );
        ok( 1,                    "  no need to chdir back on $^O" );
    }
    else {
        ok( chdir(),              "chdir() w/ only \$ENV{$key} set" );
        is( abs_path, $ENV{$key}, '  abs_path() agrees' );
        chdir($cwd);
        is( abs_path, $cwd,       '  and back again' );
    }

    # Bug had chdir(undef) being the same as chdir()
    ok( !chdir(undef),              "chdir(undef) w/ only \$ENV{$key} set" );
    is( abs_path, $cwd,             '  abs_path() agrees' );

    # Ditto chdir('').
    ok( !chdir(''),                 "chdir('') w/ only \$ENV{$key} set" );
    is( abs_path, $cwd,             '  abs_path() agrees' );
}

{
    # We're going to be using undefs a lot here.
    no warnings 'uninitialized';

    # Unset all the environment variables chdir() pay attention to.
    local @ENV{@magic_envs} = (undef) x @magic_envs;

    ok( !chdir(),                   'chdir() w/o any ENV set' );
    is( abs_path, $cwd,             '  abs_path() agrees' );
}
