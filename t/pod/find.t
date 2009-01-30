# Testing of Pod::Find
# Author: Marek Rouchal <marek@saftsack.fs.uni-bayreuth.de>

BEGIN {
  if($ENV{PERL_CORE}) {
    chdir 't' if -d 't';
    # The ../../../../../lib is for finding lib/utf8.pm
    # when running under all-utf8 settings (pod/find.t)
    # does not directly require lib/utf8.pm but regular
    # expressions will need that.
    @INC = qw(../lib ../../../../../lib);
  }
}

$| = 1;

use Test;

BEGIN {
  plan tests => 4;
  use File::Spec;
}

use Pod::Find qw(pod_find pod_where);
use File::Spec;

# load successful
ok(1);

require Cwd;
my $THISDIR = Cwd::cwd();
my $VERBOSE = $ENV{PERL_CORE} ? 0 : ($ENV{TEST_VERBOSE} || 0);
my $lib_dir = $ENV{PERL_CORE} ? 
  File::Spec->catdir('pod', 'testpods', 'lib')
  : File::Spec->catdir($THISDIR,'lib');

my $vms_unix_rpt = 0;
my $vms_efs = 0;
my $unix_mode = 1;

if ($^O eq 'VMS') {
    $lib_dir = $ENV{PERL_CORE} ?
      VMS::Filespec::unixify(File::Spec->catdir('pod', 'testpods', 'lib'))
      : VMS::Filespec::unixify(File::Spec->catdir($THISDIR,'-','lib','pod'));
    $Qlib_dir = $lib_dir;
    $Qlib_dir =~ s#\/#::#g;

    $unix_mode = 0;
    if (eval 'require VMS::Feature') {
        $vms_unix_rpt = VMS::Feature::current("filename_unix_report");
        $vms_efs = VMS::Feature::current("efs_charset");
    } else {
        my $unix_rpt = $ENV{'DECC$FILENAME_UNIX_REPORT'} || '';
        my $efs_charset = $ENV{'DECC$EFS_CHARSET'} || '';
        $vms_unix_rpt = $unix_rpt =~ /^[ET1]/i; 
        $vms_efs = $efs_charset =~ /^[ET1]/i; 
    }

    # Traditional VMS mode only if VMS is not in UNIX compatible mode.
    $unix_mode = ($vms_efs && $vms_unix_rpt);
}

print "### searching $lib_dir\n";
my %pods = pod_find($lib_dir);
my $result = join(',', sort values %pods);
print "### found $result\n";
my $compare = $ENV{PERL_CORE} ? 
  join(',', sort qw(
    Pod::Stuff
))
  : join(',', sort qw(
    Pod::Checker
    Pod::Find
    Pod::InputObjects
    Pod::ParseUtils
    Pod::Parser
    Pod::PlainText
    Pod::Select
    Pod::Usage
));
if ($^O eq 'VMS') {
    $compare = lc($compare);
    my $undollared = $Qlib_dir;
    $undollared =~ s/\$/\\\$/g;
    $undollared =~ s/\-/\\\-/g;
    $result =~ s/$undollared/pod::/g;
    $result =~ s/\$//g;
    my $count = 0;
    my @result = split(/,/,$result);
    my @compare = split(/,/,$compare);
    foreach(@compare) {
        $count += grep {/$_/} @result;
    }
    ok($count/($#result+1)-1,$#compare);
}
elsif (File::Spec->case_tolerant || $^O eq 'dos') {
    ok(lc $result,lc $compare);
}
else {
    ok($result,$compare);
}

print "### searching for File::Find\n";
$result = pod_where({ -inc => 1, -verbose => $VERBOSE }, 'File::Find')
  || 'undef - pod not found!';
print "### found $result\n";

require Config;
if ($^O eq 'VMS') { # privlib is perl_root:[lib] OK but not under mms
    if ($unix_mode) {
        $compare = "../lib/File/Find.pm";
    } else {
        $compare = "lib.File]Find.pm";
    }
    $result =~ s/perl_root:\[\-?\.?//i;
    $result =~ s/\[\-?\.?//i; # needed under `mms test`
    ok($result,$compare);
}
else {
    $compare = $ENV{PERL_CORE} ?
      File::Spec->catfile(File::Spec->updir, 'lib','File','Find.pm')
      : File::Spec->catfile($Config::Config{privlibexp},"File","Find.pm");
    ok(_canon($result),_canon($compare));
}

# Search for a documentation pod rather than a module
my $searchpod = 'Stuff';
print "### searching for $searchpod.pod\n";
$result = pod_where(
  { -dirs => [ File::Spec->catdir(
    $ENV{PERL_CORE} ? () : qw(t), 'pod', 'testpods', 'lib', 'Pod') ],
    -verbose => $VERBOSE }, $searchpod)
  || "undef - $searchpod.pod not found!";
print "### found $result\n";

$compare = File::Spec->catfile(
    $ENV{PERL_CORE} ? () : qw(t),
    'pod', 'testpods', 'lib', 'Pod' ,'Stuff.pm');
ok(_canon($result),_canon($compare));

# make the path as generic as possible
sub _canon
{
  my ($path) = @_;
  $path = File::Spec->canonpath($path);
  my @comp = File::Spec->splitpath($path);
  my @dir = File::Spec->splitdir($comp[1]);
  $comp[1] = File::Spec->catdir(@dir);
  $path = File::Spec->catpath(@comp);
  $path = uc($path) if File::Spec->case_tolerant;
  print "### general path: $path\n" if $VERBOSE;
  $path;
}

