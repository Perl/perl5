
package Devel::Harness;

require Exporter;
require DynaLoader;
use Carp;
use strict;
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK $data );

$VERSION = "2.0000";

@ISA = qw(Exporter DynaLoader);
@EXPORT =  qw();
# Other items we are prepared to export if requested
@EXPORT_OK = qw( );

bootstrap Devel::Harness;

package Devel::Harness;

1;
