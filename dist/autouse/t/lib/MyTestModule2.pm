package MyTestModule2;
use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = 'test_function2';

sub test_function2 {
    return 'works';
}

1;
