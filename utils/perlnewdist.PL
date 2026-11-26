#!/usr/local/bin/perl

use Config;
use Cwd qw(cwd);
use File::Basename qw(basename dirname);

my $origdir = cwd;
chdir dirname($0) or die "Can't chdir to " . dirname($0) . ": $!\n";
my $file = basename($0, '.PL');

open my $out, '>', $file or die "Can't create $file: $!\n";

print {$out} <<"!GROK!THIS!";
$Config{startperl}
!GROK!THIS!

print {$out} <<'!PERLNEW!';

use strict;
use warnings;
use File::Basename qw(dirname);
use File::Spec;
use Getopt::Long qw(GetOptions);

my ($module, $author, $email, $config_file, $no_prompt);
my (@with);
my ($xs, $exporter, $git, $gitignore);

Getopt::Long::Configure('no_ignore_case', 'bundling');
GetOptions(
    'module=s'       => \$module,
    'with=s@'        => \@with,
    'xs!'            => \$xs,
    'exporter!'      => \$exporter,
    'git!'           => \$git,
    'gitignore!'     => \$gitignore,
    'author=s'       => \$author,
    'email=s'        => \$email,
    'config=s'       => \$config_file,
    'no-prompt'      => \$no_prompt,
    'help|h'         => sub { usage(); exit 0 },
) or usage();

usage("A module name is required") unless @ARGV || defined $module;
usage("A module name was supplied both positionally and with --module")
    if @ARGV && defined $module;
usage("Only one positional module name is accepted") if @ARGV > 1;
$module = shift @ARGV if @ARGV;

my $author_cli = defined $author;
my $email_cli = defined $email;

sub usage {
    my ($error) = @_;
    print STDERR "$error\n\n" if defined $error;
    print STDERR <<'USAGE';
perlnewdist [OPTIONS] MODULE

Create a new Perl distribution.

The usual first command is:

    perlnewdist Acme::Example

This creates a directory named Acme-Example containing a starter module,
tests, Makefile.PL, README, and Changes. It also initializes a Git repository
and makes an initial commit when Git is available.

Options:
    --module NAME       Primary module name (or use positional NAME).
    --with NAME(S)      Additional module; repeatable and comma-separated.
                        A name beginning with :: extends MODULE.
    --xs / --no-xs      Include or omit XS support (default: omit XS).
    --exporter          Include Exporter support (default: omit it).
    --no-exporter       Explicitly omit Exporter support.
    --git / --no-git    Initialize and commit a Git repository.
    --gitignore         Create Git ignore metadata (normally implied by --git).
    --no-gitignore      Do not create Git ignore metadata.
    --author NAME       Override the author name.
    --email ADDRESS     Override the author email address.
    --config FILE       Use FILE instead of ~/.perlnewdist.
    --no-prompt         Do not ask for missing metadata.
    --help

Examples:
    perlnewdist Acme::Example
    perlnewdist Acme::Example --with ::Util,::Constants
    perlnewdist --xs --author 'A. User' --email a.user@example.com Foo::Bar
    perlnewdist --no-git Foo::Bar

On the first run, perlnewdist asks for your name and email address. Git
configuration is used to prefill the answers when available. You can save
the answers in ~/.perlnewdist so later distributions can be created without
repeating them.
USAGE
    exit 2 if defined $error;
}

sub home_directory {
    return $ENV{HOME} if defined $ENV{HOME} && length $ENV{HOME};
    return $ENV{USERPROFILE} if defined $ENV{USERPROFILE} && length $ENV{USERPROFILE};
    return undef;
}

sub read_config {
    my ($path) = @_;
    return ({}, 0) unless defined $path && -f $path;

    open my $fh, '<', $path or die "Can't read $path: $!\n";
    my %config;
    while (<$fh>) {
        chomp;
        s/^\s+//;
        s/\s+$//;
        next if !length || /^#/;
        next unless /^([A-Za-z][A-Za-z0-9_-]*)\s*=\s*(.*?)\s*$/;
        $config{$1} = $2;
    }
    close $fh or die "Can't close $path: $!\n";
    return (\%config, 1);
}

sub boolean {
    my ($value) = @_;
    return 1 if defined $value && $value =~ /^(?:1|yes|true|on)$/i;
    return 0 if defined $value && $value =~ /^(?:0|no|false|off)$/i;
    return undef;
}

sub git_config {
    my ($key) = @_;
    open my $fh, '-|', 'git', 'config', '--get', $key or return undef;
    my $value = <$fh>;
    close $fh;
    return undef unless defined $value;
    chomp $value;
    return length $value ? $value : undef;
}

sub git_available {
    open my $fh, '-|', 'git', '--version' or return 0;
    while (<$fh>) { }
    close $fh;
    return $? == 0;
}

sub prompt {
    my ($label, $default) = @_;
    my $suffix = defined $default ? " [$default]" : '';
    print "$label$suffix: ";
    my $value = <STDIN>;
    return undef unless defined $value;
    chomp $value;
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;
    return length $value ? $value : $default;
}

sub write_config {
    my ($path, $author_value, $email_value) = @_;
    my $parent = dirname $path;
    die "Configuration directory $parent does not exist\n" unless -d $parent;
    open my $fh, '>', $path or die "Can't create $path: $!\n";
    print {$fh} "author = $author_value\n" if defined $author_value;
    print {$fh} "email = $email_value\n" if defined $email_value;
    close $fh or die "Can't close $path: $!\n";
    chmod 0600, $path or die "Can't protect $path: $!\n";
}

my $home = home_directory();
$config_file = File::Spec->catfile($home, '.perlnewdist')
    if !defined $config_file && defined $home;
my ($config, $config_exists) = read_config($config_file);

$author = $config->{author} if !defined $author && defined $config->{author};
$email  = $config->{email}  if !defined $email  && defined $config->{email};
$author = git_config('user.name')  if !defined $author;
$email  = git_config('user.email') if !defined $email;

$xs = boolean($config->{xs}) if !defined $xs;
$exporter = boolean($config->{exporter}) if !defined $exporter;
$git = boolean($config->{git}) if !defined $git;
$gitignore = boolean($config->{gitignore}) if !defined $gitignore;

$xs = 0 unless defined $xs;
$exporter = 0 unless defined $exporter;
$git = git_available() unless defined $git;
$gitignore = 1 if $git;
$gitignore = 0 unless defined $gitignore;

my $prompted;
if (!$no_prompt && -t STDIN && -t STDOUT
        && ((!$config_exists && (!$author_cli || !$email_cli))
            || !defined $author || !defined $email)) {
    my $did_prompt;
    $did_prompt = 1 unless $author_cli;
    $did_prompt = 1 unless $email_cli;
    $author = prompt('Author name', $author) unless $author_cli;
    $email = prompt('Author email', $email) unless $email_cli;
    $prompted = $did_prompt;
}

if ($prompted && !$config_exists && defined $config_file && defined $author && defined $email) {
    my $save = prompt('Save these values to ' . $config_file . '?', 'y');
    write_config($config_file, $author, $email)
        if defined $save && $save =~ /^y(?:es)?$/i;
}

my $h2xs = File::Spec->catfile(dirname(File::Spec->rel2abs($0)), 'h2xs');
my @h2xs_args = ('--module', $module, '--use-new-tests', '-A');
push @h2xs_args, '-X' unless $xs;
push @h2xs_args, '--skip-exporter' unless $exporter;
push @h2xs_args, ('--with', $_) for @with;
push @h2xs_args, '--git' if $git;
push @h2xs_args, '--gitignore' if $gitignore && !$git;
push @h2xs_args, ('--author', $author) if defined $author;
push @h2xs_args, ('--email', $email) if defined $email;

exec $^X, $h2xs, @h2xs_args
    or die "Can't execute $h2xs: $!\n";
__END__

=head1 NAME

perlnewdist - create a new Perl distribution

=head1 SYNOPSIS

    perlnewdist Acme::Example
    perlnewdist Acme::Example --with ::Util,::Constants
    perlnewdist --xs Foo::Bar

=head1 DESCRIPTION

C<perlnewdist> creates the initial files for a Perl distribution. It is
intended to make the first step of Perl module development simple: give it a
module name, then edit the generated module and tests.

It is a thin wrapper around L<h2xs>. The wrapper
chooses beginner-friendly defaults, manages author and project preferences,
and presents a smaller interface; h2xs remains responsible for generating
the distribution files.

The generated distribution contains a C<lib> directory for modules, a C<t>
directory for tests, a C<Makefile.PL> for building it, and starter
documentation. The generated test should pass immediately.

The default project is a pure-Perl module. It does not use XS or C code and
does not include C<Exporter>. Use C<--xs> when the distribution needs native
code, or C<--exporter> when it is deliberately providing an exporting
interface.

=head1 QUICK START

Create a distribution and enter it:

    perlnewdist Acme::Example
    cd Acme-Example

Build and test it:

    perl Makefile.PL
    make test

Then edit:

    lib/Acme/Example.pm
    t/Acme-Example.t

The generated files contain placeholders for the description, API, tests,
license, and release information. They are intended to be edited; they are
not a finished module.

=head1 MODULES

The first module is the primary module and determines the distribution name.
Additional pure-Perl modules can be requested with C<--with>:

    perlnewdist --module Foo::Bar \
        --with ::Util,::Constants \
        --with ::Internal::Parser

Names beginning with C<::> are appended to the primary module name. The
example creates C<Foo::Bar::Util>, C<Foo::Bar::Constants>, and
C<Foo::Bar::Internal::Parser>. A fully qualified name may also be supplied.

=head1 XS SUPPORT

XS is the Perl interface for connecting Perl code to C code. It is not needed
for an ordinary Perl module. Request it explicitly:

    perlnewdist --xs Foo::Fast

The generated XS skeleton is only a starting point. It may require a C
compiler and manual changes to C<Makefile.PL>, the XS file, and any C code.

=head1 AUTHOR INFORMATION

Author information is selected in this order:

=over 4

=item 1.

The C<--author> and C<--email> command-line options.

=item 2.

The C<~/.perlnewdist> configuration file.

=item 3.

The Git C<user.name> and C<user.email> settings.

=item 4.

Interactive prompts.

=back

When C<~/.perlnewdist> does not exist, the tool prompts even when Git has
provided defaults, so pressing Enter accepts the suggested values. It then
offers to save them for future distributions.

Email addresses are written using light obfuscation, such as
C<name [at] example [dot] com>, to make the generated files less useful to
simple address scrapers.

Use C<--no-prompt> in scripts or other noninteractive workflows. In that
case, command-line and configuration values are used without prompting.

=head1 CONFIGURATION

The optional C<~/.perlnewdist> file uses simple C<key = value> lines:

    author = A. User
    email = a.user@example.com
    xs = false
    exporter = false
    git = true
    gitignore = true

Blank lines and lines beginning with C<#> are ignored. Boolean values may be
written as C<true>, C<false>, C<yes>, C<no>, C<on>, C<off>, C<1>, or C<0>.
Use C<--config> to select another file.

=head1 GIT

When Git is available, the default is to create a repository containing the
initial skeleton and make one commit named C<Initial module skeleton>. No
files are added to an existing repository by perlnewdist; it operates in the
new distribution directory.

Use C<--no-git> to disable repository creation. Combine it with
C<--gitignore> when you want the Git-related ignore files without a
repository.

=head1 SEE ALSO

L<h2xs> is the lower-level generator used by perlnewdist. It remains
available for advanced XS and C-header workflows.

!PERLNEW!

close $out or die "Can't close $file: $!\n";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec($Config{'eunicefix'} . ' ' . $file) if $Config{'eunicefix'} ne ':';
chdir $origdir;
