package IPC::Run::Win32Pump;

=head1 NAME

IPC::Run::Win32Pumper - helper processes to shovel data to/from parent, child

=head1 SYNOPSIS

Internal use only; see IPC::Run::Win32IO and best of luck to you.

=head1 DESCRIPTION

See L<IPC::Run::Win32Helper|IPC::Run::Win32Helper> for details.  This
module is used in subprocesses that are spawned to shovel data to/from
parent processes from/to their child processes.  Where possible, pumps
are optimized away.

NOTE: This is not a real module: it's a script in module form, designed
to be run like

   $^X -MIPC::Run::Win32Pumper -e 1 ...

It parses a bunch of command line parameters from IPC::Run::Win32IO.

=cut

use strict ;

use Win32API::File qw(
   OsFHandleOpen
) ;


my ( $stdin_fh, $stdout_fh, $debug_fh, $binmode, $parent_pid, $parent_start_time, $debug, $child_label );
BEGIN {
   ( $stdin_fh, $stdout_fh, $debug_fh, $binmode, $parent_pid, $parent_start_time, $debug, $child_label ) = @ARGV ;
   ## Rather than letting IPC::Run::Debug export all-0 constants
   ## when not debugging, we do it manually in order to not even
   ## load IPC::Run::Debug.
   if ( $debug ) {
      eval "use IPC::Run::Debug qw( :default _debug_init ); 1;"
	 or die $@;
   }
   else {
      eval <<STUBS_END or die $@;
	 sub _debug {}
	 sub _debug_init {}
	 sub _debugging() { 0 }
	 sub _debugging_data() { 0 }
	 sub _debugging_details() { 0 }
	 sub _debugging_gory_details() { 0 }
	 1;
STUBS_END
   }
}

## For some reason these get created with binmode on.  AAargh, gotta       #### REMOVE
## do it by hand below.       #### REMOVE
if ( $debug ) {       #### REMOVE
close STDERR;       #### REMOVE
OsFHandleOpen( \*STDERR, $debug_fh, "w" )       #### REMOVE
 or print "$! opening STDERR as Win32 handle $debug_fh in pumper $$" ;       #### REMOVE
}       #### REMOVE
close STDIN;       #### REMOVE
OsFHandleOpen( \*STDIN, $stdin_fh, "r" )       #### REMOVE
or die "$! opening STDIN as Win32 handle $stdin_fh in pumper $$" ;       #### REMOVE
close STDOUT;       #### REMOVE
OsFHandleOpen( \*STDOUT, $stdout_fh, "w" )       #### REMOVE
or die "$! opening STDOUT as Win32 handle $stdout_fh in pumper $$" ;       #### REMOVE

binmode STDIN;
binmode STDOUT;
$| = 1 ;
select STDERR ; $| = 1 ; select STDOUT ;

$child_label ||= "pump" ;
_debug_init(
$parent_pid,
$parent_start_time,
$debug,
fileno STDERR,
$child_label,
) ;

_debug "Entered" if _debugging_details ;

# No need to close all fds; win32 doesn't seem to pass any on to us.
$| = 1 ;
my $buf ;
my $total_count = 0 ;
while (1) {
my $count = sysread STDIN, $buf, 10_000 ;
last unless $count ;
if ( _debugging_gory_details ) {
 my $msg = "'$buf'" ;
 substr( $msg, 100, -1 ) = '...' if length $msg > 100 ;
 $msg =~ s/\n/\\n/g ;
 $msg =~ s/\r/\\r/g ;
 $msg =~ s/\t/\\t/g ;
 $msg =~ s/([\000-\037\177-\277])/sprintf "\0x%02x", ord $1/eg ;
 _debug sprintf( "%5d chars revc: ", $count ), $msg ;
}
$total_count += $count ;
$buf =~ s/\r//g unless $binmode;
if ( _debugging_gory_details ) {
 my $msg = "'$buf'" ;
 substr( $msg, 100, -1 ) = '...' if length $msg > 100 ;
 $msg =~ s/\n/\\n/g ;
 $msg =~ s/\r/\\r/g ;
 $msg =~ s/\t/\\t/g ;
 $msg =~ s/([\000-\037\177-\277])/sprintf "\0x%02x", ord $1/eg ;
 _debug sprintf( "%5d chars sent: ", $count ), $msg ;
}
print $buf ;
}

_debug "Exiting, transferred $total_count chars" if _debugging_details ;

## Perform a graceful socket shutdown.  Windows defaults to SO_DONTLINGER,
## which should cause a "graceful shutdown in the background" on sockets.
## but that's only true if the process closes the socket manually, it
## seems; if the process exits and lets the OS clean up, the OS is not
## so kind.  STDOUT is not always a socket, of course, but it won't hurt
## to close a pipe and may even help.  With a closed source OS, who
## can tell?
##
## In any case, this close() is one of the main reasons we have helper
## processes; if the OS closed socket fds gracefully when an app exits,
## we'd just redirect the client directly to what is now the pump end 
## of the socket.  As it is, however, we need to let the client play with
## pipes, which don't have the abort-on-app-exit behavior, and then
## adapt to the sockets in the helper processes to allow the parent to
## select.
##
## Possible alternatives / improvements:
## 
## 1) use helper threads instead of processes.  I don't trust perl's threads
## as of 5.005 or 5.6 enough (which may be myopic of me).
##
## 2) figure out if/how to get at WaitForMultipleObjects() with pipe
## handles.  May be able to take the Win32 handle and pass it to 
## Win32::Event::wait_any, dunno.
## 
## 3) Use Inline::C or a hand-tooled XS module to do helper threads.
## This would be faster than #1, but would require a ppm distro.
##
close STDOUT ;
close STDERR ;

=head1 AUTHOR

Barries Slaymaker <barries@slaysys.com>.  Funded by Perforce Software, Inc.

=head1 COPYRIGHT

Copyright 2001, Barrie Slaymaker, All Rights Reserved.

You may use this under the terms of either the GPL 2.0 ir the Artistic License.

=cut

1 ;
