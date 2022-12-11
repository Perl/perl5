BEGIN {
    use File::Spec::Functions ':ALL';
    @INC = map { rel2abs($_) }
             (qw| ./lib ./t/lib ../../lib |);
}

use strict;
use warnings;
use Test::More;
use Testing qw( setup_testing_dir xconvert );
use Cwd;
use File::Spec::Functions;
use Pod::Html::Util qw(
    process_command_line
    unixify
);

my $debug = 0;
my $startdir = cwd();
END { chdir($startdir) or die("Cannot change back to $startdir: $!"); }
my $args;

my $tdir = setup_testing_dir( {
    debug       => $debug,
} );

my $cwd = unixify(Cwd::cwd());
my $cachedir = 't';
my $infile = catfile($cachedir, 'cache.pod');
my $outfile = "cacheout.html";
my $cachefile = "pod2htmd.tmp";
my $tcachefile = catfile($cachedir, 'pod2htmd.tmp');

unlink $cachefile, $tcachefile;
is(-f $cachefile, undef, "No cache file to start");
is(-f $tcachefile, undef, "No cache file to start");

# test podpath and podroot
my @switches = (
    "--infile=$infile",
    "--outfile=$outfile",
    "--podpath=scooby:shaggy:fred:velma:daphne",
    "--podroot=$cwd",
);
Pod::Html::pod2html(@switches);
is(-f $cachefile, 1, "Cache created");
open(my $cache, '<', $cachefile) or die "Cannot open cache file: $!";
chomp(my $podpath = <$cache>);
chomp(my $podroot = <$cache>);
close $cache;
is($podpath, "scooby:shaggy:fred:velma:daphne", "podpath");
is($podroot, "$cwd", "podroot");

# At this point, to test the '--flush' option, we have to deviate from our
# practice of only calling through Pod::Html::pod2html() and create a new
# Pod::Html object, call two methods on it, one of which will manually process
# a set of command-line switches, then confirm that $cachefile no longer
# exists.

{
    local @ARGV = map { split('=',$_) } @switches;
    my $self = Pod::Html->new();
    $self->init_globals();
    ok(-f $cachefile, "Original cachefile still exists");

    push @ARGV, '--flush';
    my $opts = process_command_line();
    $self->process_options($opts);
    ok(! -f $cachefile, "Original cachefile has been flushed");
}

# test cache contents: non-default cachedir
Pod::Html::pod2html(
    "--infile=$infile",
    "--outfile=$outfile",
    "--cachedir=$cachedir",
    "--podpath=$cachedir", # Use 't' to simplify test setup
    "--htmldir=$cwd",
    );
is(-f $tcachefile, 1, "Cache file created in non-default cachedir");
open($cache, '<', $tcachefile) or die "Cannot open cache file: $!";
chomp($podpath = <$cache>);
chomp($podroot = <$cache>);
is($podpath, $cachedir, "podpath identified");
my %pages;
while (<$cache>) {
    /(.*?) (.*)$/;
    $pages{$1} = $2;
}
chdir($cachedir);
my %expected_pages = 
    # chop off the .pod and set the path
    map { my $f = substr($_, 0, -4); $f => "t/$f" }
    <*.pod>;
chdir($cwd);
is_deeply(\%pages, \%expected_pages, "cache contents");
close $cache;

1 while unlink $outfile;
1 while unlink $cachefile;
1 while unlink $tcachefile;
is(-f $cachefile, undef, "No cache file to end");
is(-f $tcachefile, undef, "No cache file to end");

done_testing;
