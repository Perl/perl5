package ExtUtils::CBuilder::Platform::os2;

use strict;
use ExtUtils::CBuilder::Platform::Unix;

use vars qw($VERSION @ISA);
$VERSION = '0.12';
@ISA = qw(ExtUtils::CBuilder::Platform::Unix);

sub need_prelink { 1 }

1;
