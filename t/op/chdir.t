#!./perl -w

BEGIN {
    # We're not going to chdir() into 't' because we don't know if
    # chdir() works!  Instead, we'll hedge our bets and put both
    # possibilities into @INC.
    @INC = qw(t . lib ../lib);
}

use Config;
require "test.pl";
plan(tests => 31);

my $IsVMS = $^O eq 'VMS';

my ($saved_sys_login);
BEGIN {
    $saved_sys_login = $ENV{'SYS$LOGIN'} if $^O eq 'VMS'
}
END {
    $ENV{'SYS$LOGIN'} = $saved_sys_login if $^O eq 'VMS';
}

# Might be a little early in the testing process to start using these,
# but I can't think of a way to write this test without them.
use File::Spec::Functions qw(:DEFAULT splitdir rel2abs splitpath);

# Can't use Cwd::abs_path() because it has different ideas about
# path separators than File::Spec.
sub abs_path {
    $IsVMS ? uc(rel2abs(curdir)) : rel2abs(curdir);
}

my $Cwd = abs_path;

# Let's get to a known position
SKIP: {
    my ($vol,$dir) = splitpath(abs_path,1);
    skip("Already in t/", 2) if (splitdir($dir))[-1] eq ($IsVMS ? 'T' : 't');

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
        pass( "  no need to test SYS\$LOGIN on $^O" ) for 1..7;
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

sub clean_env {
    foreach (@magic_envs) {
        delete $ENV{$_} unless $IsVMS && $_ eq 'HOME' && !$Config{'d_setenv'};
    }
    # The following means we won't really be testing for non-existence,
    # but in Perl we can only delete from the process table, not the job 
    # table.
    $ENV{'SYS$LOGIN'} = '' if $IsVMS;
}

foreach my $key (@magic_envs) {
    # We're going to be using undefs a lot here.
    no warnings 'uninitialized';

    clean_env;
    $ENV{$key} = catdir $Cwd, ($IsVMS ? 'OP' : 'op');

    check_env($key);
}

{
    clean_env;
    if ($IsVMS && !$Config{'d_setenv'}) {
        pass("Can't reset HOME, so chdir() test meaningless");
    } else {
        ok( !chdir(),                   'chdir() w/o any ENV set' );
    }
    is( abs_path, $Cwd,             '  abs_path() agrees' );
}
