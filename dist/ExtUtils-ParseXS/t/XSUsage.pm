package XSUsage;

require DynaLoader;
use vars ( qw| @ISA $VERSION | );
@ISA = qw(Exporter DynaLoader);
$VERSION = '0.02';
bootstrap XSUsage $VERSION;
