package MyTestModuleNormal;
use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = 'test_function_normal';

sub test_function_normal {
    return 'works';
}

1;
