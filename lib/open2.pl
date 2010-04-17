warn "Legacy library @{[(caller(0))[6]]} will be removed from the Perl core distribution in the next major release. Please install it from the CPAN distribution Perl4::CoreLibs. It is being used at @{[(caller)[1]]}, line @{[(caller)[2]]}.\n";

# This legacy library is deprecated and will be removed in a future
# release of perl.
#
# This is a compatibility interface to IPC::Open2.  New programs should
# do
#
#     use IPC::Open2;
#
# instead of
#
#     require 'open2.pl';

package main;
use IPC::Open2 'open2';
1
