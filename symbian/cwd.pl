use strict;
use Cwd;
my $CWD = getcwd();
$CWD =~ s!^C:!!i;
$CWD =~ s!/!\\!g;
$CWD;
