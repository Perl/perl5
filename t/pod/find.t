# Testing of Pod::Find
# Author: Marek Rouchal <marek@saftsack.fs.uni-bayreuth.de>

$| = 1;

use Test;

BEGIN { plan tests => 4 }

use Pod::Find qw(pod_find pod_where);
use File::Spec;

# load successful
ok(1);

require Cwd;
my $THISDIR = Cwd::cwd();
my $VERBOSE = 0;

print "*** searching $THISDIR/lib\n";
my %pods = pod_find("$THISDIR/lib");
my $result = join(',', sort values %pods);
print "*** found $result\n";
my $compare = join(',', qw(
    Pod::Checker
    Pod::Find
    Pod::InputObjects
    Pod::ParseUtils
    Pod::Parser
    Pod::PlainText
    Pod::Select
    Pod::Usage
));
ok($result,$compare);

# File::Find is located in this place since eons
# and on all platforms, hopefully

print "*** searching for File::Find\n";
$result = pod_where({ -inc => 1, -verbose => $VERBOSE }, 'File::Find')
  || 'undef - pod not found!';
print "*** found $result\n";

require Config;
$compare = File::Spec->catfile($Config::Config{privlib},"File","Find.pm");
ok(_canon($result),_canon($compare));

# Search for a documentation pod rather than a module
print "*** searching for perlfunc.pod\n";
$result = pod_where({ -inc => 1, -verbose => $VERBOSE }, 'perlfunc')
  || 'undef - perlfunc.pod not found!';
print "*** found $result\n";

$compare =  File::Spec->catfile($Config::Config{privlib},"perlfunc.pod");
ok(_canon($result),_canon($compare));

# make the path as generic as possible
sub _canon
{
  my ($path) = @_;
  $path = File::Spec->canonpath($path);
  my @comp = File::Spec->splitpath($path);
  my @dir = File::Spec->splitdir($comp[1]);
  $comp[1] = File::Spec->catdir(@dir);
  $path = File::Spec->catpath(@dir);
  $path = uc($path) if File::Spec->case_tolerant;
  $path;
}

