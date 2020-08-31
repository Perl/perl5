package MyTestModule2;
use warnings;

our @ISA = ( qw| Exporter | );
require Exporter;
our @EXPORT_OK = 'test_function2';

sub test_function2 {
  return 'works';
}

1;
