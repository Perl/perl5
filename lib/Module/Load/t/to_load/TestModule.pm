package TestModule;

use strict;
require Exporter;
use vars qw(@EXPORT @EXPORT_OK @ISA $IMPORTED);

@ISA        = qw(Exporter);
@EXPORT     = qw(func2);
@EXPORT_OK  = qw(func1);

### test if import gets called properly
sub import   { $IMPORTED = 1; goto &Exporter::import; }
sub imported { $IMPORTED;       }

sub func1    { return "func1";  }

sub func2    { return "func2";  }

1;
