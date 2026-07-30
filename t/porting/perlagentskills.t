#!./perl

BEGIN {
    if (-f 'TestInit.pm') {
        @INC = qw(lib .);
    }
    else {
        @INC = '..' if -f '../TestInit.pm';
    }
}

use TestInit qw(T);
use strict;
use warnings;
require './t/test.pl';

my $skills_root = '.agents/skills';
my $skills_pod  = 'pod/perlagentskills.pod';

opendir my $dh, $skills_root
    or die "Can't open $skills_root: $!";
my @skill_dirs = sort grep { !/^\./ && -d "$skills_root/$_" } readdir $dh;
closedir $dh or die "Can't close $skills_root: $!";

open my $pod_fh, '<', $skills_pod
    or die "Can't open $skills_pod: $!";
local $/;
my $pod = <$pod_fh>;
close $pod_fh or die "Can't close $skills_pod: $!";

my %documented;
while ($pod =~ /F<([a-z0-9]+(?:-[a-z0-9]+)+)>/g) {
    $documented{$1} = 1;
}

my %actual = map { $_ => 1 } @skill_dirs;

for my $skill (@skill_dirs) {
    ok($documented{$skill}, "$skill is documented in $skills_pod");
    delete $documented{$skill};
}

for my $skill (sort keys %documented) {
    ok($actual{$skill}, "$skill exists in $skills_root");
}

done_testing();
