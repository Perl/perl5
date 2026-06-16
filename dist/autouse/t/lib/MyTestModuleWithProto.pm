package MyTestModuleWithProto;
use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(test_function_with_proto test_function_another);

sub test_function_with_proto (&$) {
    if (@_ == 2 && ref $_[0] eq 'CODE') {
        return 'works';
    }
    return 'fails';
}

sub test_function_another {
    return 'works';
}

1;
