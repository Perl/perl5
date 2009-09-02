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

warn( "The 'open2.pl' legacy library is deprecated and will be"
      . " removed in the next major release of perl. Please use the"
      . " IPC::Open2 module instead." );

package main;
use IPC::Open2 'open2';
1
