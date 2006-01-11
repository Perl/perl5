#!perl -w
package version;

use 5.005_03;
use strict;

require Exporter;
use vars qw(@ISA $VERSION $CLASS @EXPORT);

@ISA = qw(Exporter);

@EXPORT = qw(qv);

$VERSION = 0.53;

$CLASS = 'version';

# Preloaded methods go here.

1;
