#!./perl -w

BEGIN {
    # We're not going to chdir() into 't' because we don't know if
    # chdir() works!  Instead, we'll hedge our bets and put both
    # possibilities into @INC.
    @INC = qw(t . lib ../lib);
}

require "test.pl";
plan(tests => 25);

my $IsVMS = $^O eq 'VMS';

# Might be a little early in the testing process to start using these,
# but I can't think of a way to write this test without them.
use File::Spec::Functions qw(:DEFAULT splitdir rel2abs);

# Can't use Cwd::abs_path() because it has different ideas about
# path seperators than File::Spec.
sub abs_path {
    rel2abs(curdir);
}

my $Cwd = abs_path;

# Let's get to a known position
SKIP: {
    skip("Already in t/", 2) if (splitdir(abs_path))[-1] eq 't';

    ok( chdir('t'),     'chdir("t")');
    is( abs_path, catdir($Cwd, 't'),       '  abs_path() agrees' );
}

$Cwd = abs_path;

# The environment variables chdir() pays attention to.
my @magic_envs = qw(HOME LOGDIR SYS$LOGIN);

sub check_env {
    my($key) = @_;

    # Make sure $ENV{'SYS$LOGIN'} is only honored on VMS.
    if( $key eq 'SYS$LOGIN' && !$IsVMS ) {
        ok( !chdir(),         "chdir() on $^O ignores only \$ENV{$key} set" );
        is( abs_path, $Cwd,   '  abs_path() did not change' );
        pass( "  no need to chdir back on $^O" );
    }
    else {
        ok( chdir(),              "chdir() w/ only \$ENV{$key} set" );
        is( abs_path, $ENV{$key}, '  abs_path() agrees' );
        chdir($Cwd);
        is( abs_path, $Cwd,       '  and back again' );

        my $warning = '';
        local $SIG{__WARN__} = sub { $warning .= join '', @_ };


        # Check the deprecated chdir(undef) feature.
#line 60
        ok( chdir(undef),           "chdir(undef) w/ only \$ENV{$key} set" );
        is( abs_path, $ENV{$key},   '  abs_path() agrees' );
        is( $warning,  <<WARNING,   '  got uninit & deprecation warning' );
Use of uninitialized value in chdir at $0 line 60.
Use of chdir('') or chdir(undef) as chdir() is deprecated at $0 line 60.
WARNING

        chdir($Cwd);

        # Ditto chdir('').
        $warning = '';
#line 72
        ok( chdir(''),              "chdir('') w/ only \$ENV{$key} set" );
        is( abs_path, $ENV{$key},   '  abs_path() agrees' );
        is( $warning,  <<WARNING,   '  got deprecation warning' );
Use of chdir('') or chdir(undef) as chdir() is deprecated at $0 line 72.
WARNING

        chdir($Cwd);
    }
}

foreach my $key (@magic_envs) {
    # We're going to be using undefs a lot here.
    no warnings 'uninitialized';

    local %ENV = ();
    $ENV{$key} = catdir $Cwd, 'op';
    
    check_env($key);
}

{
    local %ENV = ();

    ok( !chdir(),                   'chdir() w/o any ENV set' );
    is( abs_path, $Cwd,             '  abs_path() agrees' );
}
