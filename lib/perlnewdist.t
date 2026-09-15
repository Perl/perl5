#!./perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use strict;
use File::Spec;
use File::Temp qw(tempdir);
use Cwd qw(cwd);
require './test.pl';

my $utility = File::Spec->rel2abs('../utils/perlnewdist');
my $test_lib = File::Spec->rel2abs('../lib');
if (!-e $utility) {
    print "1..0 # Skip: $utility was not built\n";
    exit 0;
}

my $git_available = 0;
if (open(my $git_version, '-|', 'git', '--version')) {
    while (<$git_version>) { }
    close $git_version;
    $git_available = $? == 0;
}
plan(20);

sub run_newdist {
    my ($directory, $environment, @args) = @_;
    my $old = cwd();
    chdir $directory or die "Can't chdir to $directory: $!";
    my %run_environment = (%$environment, PERL5LIB => $test_lib);
    my ($stdout, $stderr) = runperl_and_capture(\%run_environment, [$utility, @args]);
    my $status = $?;
    chdir $old or die "Can't chdir back to $old: $!";
    return ($status, $stdout, $stderr);
}

my $tmp = tempdir(CLEANUP => 1);
my $dist = File::Spec->catdir($tmp, 'Acme-Example');
my ($status, $stdout, $stderr) = run_newdist(
    $tmp, {},
    '--no-git', '--no-prompt',
    '--author', 'A. Test User',
    '--email', 'test@example.com',
    '--with', '::Util,::Deep::More',
    '--module', 'Acme::Example',
);

is($status, 0, 'perlnewdist creates a distribution');
ok(-f File::Spec->catfile($dist, 'lib', 'Acme', 'Example.pm'),
    'creates the primary module');
ok(-f File::Spec->catfile($dist, 'lib', 'Acme', 'Example', 'Util.pm'),
    'creates an additional module');
ok(-f File::Spec->catfile($dist, 'lib', 'Acme', 'Example', 'Deep', 'More.pm'),
    'creates a nested additional module');
ok(-f File::Spec->catfile($dist, 't', 'Acme-Example.t'),
    'creates the test file');
ok(-f File::Spec->catfile($dist, 'Makefile.PL'),
    'creates Makefile.PL');
ok(!-e File::Spec->catdir($dist, '.git'),
    '--no-git does not create a repository');

open my $makefile, '<', File::Spec->catfile($dist, 'Makefile.PL')
    or die "Can't read Makefile.PL: $!";
my $makefile_text = do { local $/; <$makefile> };
close $makefile or die "Can't close Makefile.PL: $!";
like($makefile_text, qr/A\. Test User/, 'passes the author to h2xs');
like($makefile_text, qr/test \[at\] example \[dot\] com/,
    'obfuscates the email in Makefile.PL');

open my $module, '<', File::Spec->catfile($dist, 'lib', 'Acme', 'Example.pm')
    or die "Can't read the generated module: $!";
my $module_text = do { local $/; <$module> };
close $module or die "Can't close the generated module: $!";
like($module_text, qr/test \[at\] example \[dot\] com/,
    'obfuscates the email in module documentation');

my $config = File::Spec->catfile($tmp, 'perlnewdist.conf');
open my $config_fh, '>', $config or die "Can't create config: $!";
print {$config_fh} <<'CONFIG';
author = Config User
email = config@example.com
git = false
gitignore = false
CONFIG
close $config_fh or die "Can't close config: $!";

my $configured = File::Spec->catdir($tmp, 'Configured-Dist');
($status, $stdout, $stderr) = run_newdist(
    $tmp, {},
    '--config', $config, '--no-prompt', 'Configured::Dist',
);
is($status, 0, 'uses a configuration file without prompting');
ok(-f File::Spec->catfile($configured, 'lib', 'Configured', 'Dist.pm'),
    'configuration run creates the requested module');
open $makefile, '<', File::Spec->catfile($configured, 'Makefile.PL')
    or die "Can't read configured Makefile.PL: $!";
$makefile_text = do { local $/; <$makefile> };
close $makefile or die "Can't close configured Makefile.PL: $!";
like($makefile_text, qr/Config User/, 'uses the configured author');
like($makefile_text, qr/config \[at\] example \[dot\] com/,
    'uses and obfuscates the configured email');
ok(!-e File::Spec->catdir($configured, '.git'),
    'configuration can disable Git repository creation');

my ($help_status, $help_out, $help_err) = run_newdist(
    $tmp, {}, '--help',
);
is($help_status, 0, '--help succeeds');
like($help_err . $help_out, qr/perlnewdist \[OPTIONS\] MODULE/,
    '--help describes the command');

SKIP: {
    skip('git is not available', 3) unless $git_available;

    my $gitconfig = File::Spec->catfile($tmp, 'gitconfig');
    open my $git_fh, '>', $gitconfig or die "Can't create Git config: $!";
    print {$git_fh} <<'GITCONFIG';
[user]
    name = Git Test User
    email = git-test@example.com
GITCONFIG
    close $git_fh or die "Can't close Git config: $!";

    my $git_dist = File::Spec->catdir($tmp, 'Git-Dist');
    ($status, $stdout, $stderr) = run_newdist(
        $tmp,
        { GIT_CONFIG_GLOBAL => $gitconfig, GIT_CONFIG_NOSYSTEM => 1 },
        '--no-prompt', 'Git::Dist',
    );
    is($status, 0, 'creates a Git distribution');
    ok(-d File::Spec->catdir($git_dist, '.git'),
        'default Git support creates a repository');
    my $log = `git --git-dir="$git_dist/.git" log -1 --format=%s 2>&1`;
    like($log, qr/^Initial module skeleton\s*$/,
        'creates the initial Git commit');
}
