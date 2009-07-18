#!perl
# Generates info for Module::CoreList from this perl tree
# run this from the root of a perl tree, using the perl built in that tree.
#
# Data is on STDOUT.
#
# With an optional arg specifying the root of a CPAN mirror, outputs the
# %upstream and %bug_tracker hashes too.

use 5.010001; # needs Parse::CPAN::Meta

use strict;
use warnings;
use File::Find;
use ExtUtils::MM_Unix;
use lib "Porting";
use Maintainers qw(%Modules files_to_modules);
use File::Spec;


my %lines;
my %module_to_file;
my %modlist;

die "usage: $0 [ cpan-mirror/ ]\n" unless @ARGV <= 1;
my $cpan = shift;

if (! -f 'MANIFEST') {
    die "Must be run from the root of a clean perl tree\n"
}

if ($cpan) {
    my $modlistfile
	= File::Spec->catfile($cpan, 'modules', '02packages.details.txt');
    open my $fh, '<', $modlistfile or die "Couldn't open $modlistfile: $!";

    {
	local $/ = "\n\n";
	die "Incompatible modlist format"
	    unless <$fh> =~ /^Columns: +package name, version, path/m;
    }

    # Converting the file to a hash is about 5 times faster than a regexp flat
    # lookup.
    while (<$fh>) {
	next unless /^([A-Za-z_:0-9]+) +[-0-9.undefHASHVERSIONvsetwhenloadingbogus]+ +(\S+)/;
	$modlist{$1} = $2;
    }
}

find(sub {
    /(\.pm|_pm\.PL)$/ or return;
    /PPPort\.pm$/ and return;
    my $module = $File::Find::name;
    $module =~ /\b(demo|t|private)\b/ and return; # demo or test modules
    my $version = MM->parse_version($_);
    defined $version or $version = 'undef';
    $version =~ /\d/ and $version = "'$version'";
    # some heuristics to figure out the module name from the file name
    $module =~ s{^(lib|(win32/|vms/|symbian/)?ext)/}{}
	and $1 ne 'lib'
	and ( $module =~ s{\b(\w+)/\1\b}{$1},
	      $module =~ s{^B/O}{O},
	      $module =~ s{^Devel-PPPort}{Devel},
	      $module =~ s{^Encode/encoding}{encoding},
	      $module =~ s{^IPC-SysV/}{IPC/},
	      $module =~ s{^MIME-Base64/QuotedPrint}{MIME/QuotedPrint},
	      $module =~ s{^(?:DynaLoader|Errno|Opcode)/}{},
	    );
    $module =~ s{/}{::}g;
    $module =~ s{-}{::}g;
    $module =~ s{^.*::lib::}{};
    $module =~ s/(\.pm|_pm\.PL)$//;
    $lines{$module} = $version;
    $module_to_file{$module} = $File::Find::name;
}, 'lib', 'ext', 'vms/ext', 'symbian/ext');

-e 'configpm' and $lines{Config} = 'undef';

if (open my $ucdv, "<", "lib/unicore/version") {
    chomp (my $ucd = <$ucdv>);
    $lines{Unicode} = "'$ucd'";
    close $ucdv;
    }

sub display_hash {
    my ($hash) = @_;
}

print "    $] => {\n";
printf "\t%-24s=> $lines{$_},\n", "'$_'" foreach sort keys %lines;
print "    },\n";

exit unless %modlist;

# We have to go through this two stage lookup, given how Maintainers.pl keys its
# data by "Module", which is really a dist.
my $file_to_M = files_to_modules(values %module_to_file);

my %module_to_upstream;
my %module_to_dist;
my %dist_to_meta_YAML;
while (my ($module, $file) = each %module_to_file) {
    my $M = $file_to_M->{$file};
    next unless $M;
    next if $Modules{$M}{MAINTAINER} eq 'p5p';
    $module_to_upstream{$module} = $Modules{$M}{UPSTREAM};
    next if defined $module_to_upstream{$module} &&
	$module_to_upstream{$module} =~ /^(?:blead|first-come)$/;
    my $dist = $modlist{$module};
    unless ($dist) {
	warn "Can't find a distribution for $module";
	next;
    }
    $module_to_dist{$module} = $dist;

    next if exists $dist_to_meta_YAML{$dist};

    $dist_to_meta_YAML{$dist} = undef;

    # Like it or lump it, this has to be Unix format.
    my $meta_YAML_path = "$cpan/authors/id/$dist";
    $meta_YAML_path =~ s/(?:tar\.gz|zip)$/meta/ or die "$meta_YAML_path";
    unless (-e $meta_YAML_path) {
	warn "$meta_YAML_path does not exist for $module";
	# I tried code to open the tarballs with Archive::Tar to find and
	# extract META.yml, but only Text-Tabs+Wrap-2006.1117.tar.gz had one,
	# so it's not worth including.
	next;
    }
    require Parse::CPAN::Meta;
    $dist_to_meta_YAML{$dist} = Parse::CPAN::Meta::LoadFile($meta_YAML_path);
}

print "\n%upstream = (\n";
foreach my $module (sort keys %module_to_upstream) {
    my $upstream = defined $module_to_upstream{$module}
	? "'$module_to_upstream{$module}'" : 'undef';
    printf "    %-24s=> $upstream,\n", "'$module'";
}
print ");\n";

print "\n%bug_tracker = (\n";
foreach my $module (sort keys %module_to_upstream) {
    my $upstream = defined $module_to_upstream{$module};
    next if defined $upstream
	and $upstream eq 'blead' || $upstream eq 'first-come';

    my $bug_tracker;

    my $dist = $module_to_dist{$module};
    $bug_tracker = $dist_to_meta_YAML{$dist}->{resources}{bugtracker}
	if $dist;

    $bug_tracker = defined $bug_tracker ? "'$bug_tracker'" : 'undef';
    next if $bug_tracker eq "'http://rt.perl.org/perlbug/'";
    printf "    %-24s=> $bug_tracker,\n", "'$module'";
}
print ");\n";
