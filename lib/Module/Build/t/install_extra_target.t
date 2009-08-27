#!perl -w
# Contributed by: Thorben Jaendling

use strict;
use lib $ENV{PERL_CORE} ? '../lib/Module/Build/t/lib' : 't/lib';
use MBTest tests => 8;

require_ok 'Module::Build';
ensure_blib('Module::Build');

use File::Spec::Functions qw( catdir );

my $tmp = MBTest->tmpdir;
my $output;

use DistGen;
my $dist = DistGen->new( dir => $tmp );

# note("Dist is in $tmp\n");

$dist->add_file("Build.PL", <<'===EOF===');
#!perl -w

use strict;
use Module::Build;

my $subclass = Module::Build->subclass(code => <<'=EOF=');
sub copy_files
{
	my $self = shift;
	my $dir = shift;

	my $files = $self->rscan_dir($dir, sub {-f $_ and not m!/\.|[#~]$!});

	foreach my $file (@$files) {
		$self->copy_if_modified(from => $file, to_dir => "blib");
	}
}

#Copy etc files to blib
sub process_etc_files
{
	my $self = shift;

	$self->copy_files("etc");
}

#Copy share files to blib
sub process_share_files
{
	my $self = shift;

	$self->copy_files("share");
}

1;
=EOF=

my $build = $subclass->new(
	module_name => 'Simple',
	license     => 'perl'
);

$build->add_build_element('etc');
$build->add_build_element('share');

my $distdir = lc $build->dist_name();

foreach my $id ('core', 'site', 'vendor') {
	#Where to install these build types when using prefix symantics
	$build->prefix_relpaths($id, 'share' => "share/$distdir");
	$build->prefix_relpaths($id, 'etc' => "etc/$distdir");

	#Where to install these build types when using default symantics
	my $set = $build->install_sets($id);
	$set->{'share'} = '/usr/'.($id eq 'site' ? 'local/':'')."share/$distdir";
	$set->{'etc'} = ($id eq 'site' ? '/usr/local/etc/':'/etc/').$distdir;
}

#Where to install these types when using install_base symantics
$build->install_base_relpaths('share' => "share/$distdir");
$build->install_base_relpaths('etc' => "etc/$distdir");

$build->create_build_script();

===EOF===
	
#Test Build.PL exists ok?

$dist->add_file("etc/config", <<'===EOF===');
[main]
Foo = bar
Jim = bob

[supplemental]
stardate = 1234344

===EOF===

$dist->add_file("share/data", <<'===EOF===');
7 * 9 = 42?

===EOF===

$dist->add_file("share/html/index.html", <<'===EOF===');
<HTML>
  <BODY>
    <H1>Hello World!</H1>
  </BODY>
</HTML>

===EOF===

$dist->regen;
$dist->chdir_in;

my $installdest = catdir($tmp, 't', "install_extra_targets-$$");

$output = stdout_of sub { $dist->run_build_pl("--install_base=$installdest") };

$output .= stdout_of sub { $dist->run_build };

my $error;
$error++ unless ok(-e "blib/etc/config", "Built etc/config");
$error++ unless ok(-e "blib/share/data", "Built share/data");
$error++ unless ok(-e "blib/share/html/index.html", "Built share/html");
diag "OUTPUT:\n$output" if $error;

$output = stdout_of sub { $dist->run_build('install') };

$error = 0;
$error++ unless ok(-e "$installdest/etc/simple/config", "installed etc/config");
$error++ unless ok(-e "$installdest/share/simple/data", "installed share/data");
$error++ unless ok(-e "$installdest/share/simple/html/index.html", "installed share/html");
diag "OUTPUT:\n$output" if $error;

$dist->remove();
