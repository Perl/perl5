package IPC::Run::Win32Helper ;

=head1 NAME

IPC::Run::Win32Helper - helper routines for IPC::Run on Win32 platforms.

=head1 SYNOPSIS

use IPC::Run::Win32Helper ;   # Exports all by default

=head1 DESCRIPTION

IPC::Run needs to use sockets to redirect subprocess I/O so that the select() loop
will work on Win32. This seems to only work on WinNT and Win2K at this time, not
sure if it will ever work on Win95 or Win98. If you have experience in this area, please
contact me at barries@slaysys.com, thanks!.

=cut

@ISA = qw( Exporter ) ;

@EXPORT = qw(
   win32_spawn
   win32_parse_cmd_line
   _dont_inherit
   _inherit
) ;

use strict ;
use Carp ;
use IO::Handle ;
#use IPC::Open3 ();
require POSIX ;

use Text::ParseWords ;
use Win32::Process ;
use IPC::Run::Debug;
## REMOVE OSFHandleOpen
use Win32API::File qw(
   FdGetOsFHandle
   SetHandleInformation
   HANDLE_FLAG_INHERIT
   INVALID_HANDLE_VALUE
) ;

## Takes an fd or a GLOB ref, never never never a Win32 handle.
sub _dont_inherit {
   for ( @_ ) {
      next unless defined $_ ;
      my $fd = $_ ;
      $fd = fileno $fd if ref $fd ;
      _debug "disabling inheritance of ", $fd if _debugging_details ;
      my $osfh = FdGetOsFHandle $fd ;
      croak $^E if ! defined $osfh || $osfh == INVALID_HANDLE_VALUE ;

      SetHandleInformation( $osfh, HANDLE_FLAG_INHERIT, 0 ) ;
   }
}

sub _inherit {       #### REMOVE
   for ( @_ ) {       #### REMOVE
      next unless defined $_ ;       #### REMOVE
      my $fd = $_ ;       #### REMOVE
      $fd = fileno $fd if ref $fd ;       #### REMOVE
      _debug "enabling inheritance of ", $fd if _debugging_details ;       #### REMOVE
      my $osfh = FdGetOsFHandle $fd ;       #### REMOVE
      croak $^E if ! defined $osfh || $osfh == INVALID_HANDLE_VALUE ;       #### REMOVE
       #### REMOVE
      SetHandleInformation( $osfh, HANDLE_FLAG_INHERIT, 1 ) ;       #### REMOVE
   }       #### REMOVE
}       #### REMOVE
       #### REMOVE
#sub _inherit {
#   for ( @_ ) {
#      next unless defined $_ ;
#      my $osfh = GetOsFHandle $_ ;
#      croak $^E if ! defined $osfh || $osfh == INVALID_HANDLE_VALUE ;
#      SetHandleInformation( $osfh, HANDLE_FLAG_INHERIT, HANDLE_FLAG_INHERIT ) ;
#   }
#}

=head1 FUNCTIONS

=over

=cut

=item optimize()

Most common incantations of C<run()> (I<not> C<harness()>, C<start()>,
or C<finish()>) now use temporary files to redirect input and output
instead of pumper processes.

Temporary files are used when sending to child processes if input is
taken from a scalar with no filter subroutines.  This is the only time
we can assume that the parent is not interacting with the child's
redirected input as it runs.

Temporary files are used when receiving from children when output is
to a scalar or subroutine with or without filters, but only if
the child in question closes its inputs or takes input from 
unfiltered SCALARs or named files.  Normally, a child inherits its STDIN
from its parent; to close it, use "0<&-" or the C<noinherit => 1> option.
If data is sent to the child from CODE refs, filehandles or from
scalars through filters than the child's outputs will not be optimized
because C<optimize()> assumes the parent is interacting with the child.
It is ok if the output is filtered or handled by a subroutine, however.

This assumes that all named files are real files (as opposed to named
pipes) and won't change; and that a process is not communicating with
the child indirectly (through means not visible to IPC::Run).
These can be an invalid assumptions, but are the 99% case.
Write me if you need an option to enable or disable optimizations; I
suspect it will work like the C<binary()> modifier.

To detect cases that you might want to optimize by closing inputs, try
setting the C<IPCRUNDEBUG> environment variable to the special C<notopt>
value:

   C:> set IPCRUNDEBUG=notopt
   C:> my_app_that_uses_IPC_Run.pl

=item optimizer() rationalizations

Only for that limited case can we be sure that it's ok to batch all the
input in to a temporary file.  If STDIN is from a SCALAR or from a named
file or filehandle (again, only in C<run()>), then outputs to CODE refs
are also assumed to be safe enough to batch through a temp file,
otherwise only outputs to SCALAR refs are batched.  This can cause a bit
of grief if the parent process benefits from or relies on a bit of
"early returns" coming in before the child program exits.  As long as
the output is redirected to a SCALAR ref, this will not be visible.
When output is redirected to a subroutine or (deprecated) filters, the
subroutine will not get any data until after the child process exits,
and it is likely to get bigger chunks of data at once.

The reason for the optimization is that, without it, "pumper" processes
are used to overcome the inconsistancies of the Win32 API.  We need to
use anonymous pipes to connect to the child processes' stdin, stdout,
and stderr, yet select() does not work on these.  select() only works on
sockets on Win32.  So for each redirected child handle, there is
normally a "pumper" process that connects to the parent using a
socket--so the parent can select() on that fd--and to the child on an
anonymous pipe--so the child can read/write a pipe.

Using a socket to connect directly to the child (as at least one MSDN
article suggests) seems to cause the trailing output from most children
to be lost.  I think this is because child processes rarely close their
stdout and stderr explicitly, and the winsock dll does not seem to flush
output when a process that uses it exits without explicitly closing
them.

Because of these pumpers and the inherent slowness of Win32
CreateProcess(), child processes with redirects are quite slow to
launch; so this routine looks for the very common case of
reading/writing to/from scalar references in a run() routine and
converts such reads and writes in to temporary file reads and writes.

Such files are marked as FILE_ATTRIBUTE_TEMPORARY to increase speed and
as FILE_FLAG_DELETE_ON_CLOSE so it will be cleaned up when the child
process exits (for input files).  The user's default permissions are
used for both the temporary files and the directory that contains them,
hope your Win32 permissions are secure enough for you.  Files are
created with the Win32API::File defaults of
FILE_SHARE_READ|FILE_SHARE_WRITE.

Setting the debug level to "details" or "gory" will give detailed
information about the optimization process; setting it to "basic" or
higher will tell whether or not a given call is optimized.  Setting
it to "notopt" will highligh those calls that aren't optimized.

=cut

sub optimize {
   my ( $h ) = @_;

   my @kids = @{$h->{KIDS}};

   my $saw_pipe;

   my ( $ok_to_optimize_outputs, $veto_output_optimization );

   for my $kid ( @kids ) {
      ( $ok_to_optimize_outputs, $veto_output_optimization ) = ()
         unless $saw_pipe;

      _debug
         "Win32 optimizer: (kid $kid->{NUM}) STDIN piped, carrying over ok of non-SCALAR output optimization"
         if _debugging_details && $ok_to_optimize_outputs;
      _debug
         "Win32 optimizer: (kid $kid->{NUM}) STDIN piped, carrying over veto of non-SCALAR output optimization"
         if _debugging_details && $veto_output_optimization;

      if ( $h->{noinherit} && ! $ok_to_optimize_outputs ) {
	 _debug
	    "Win32 optimizer: (kid $kid->{NUM}) STDIN not inherited from parent oking non-SCALAR output optimization"
	    if _debugging_details && $ok_to_optimize_outputs;
	 $ok_to_optimize_outputs = 1;
      }

      for ( @{$kid->{OPS}} ) {
         if ( substr( $_->{TYPE}, 0, 1 ) eq "<" ) {
            if ( $_->{TYPE} eq "<" ) {
	       if ( @{$_->{FILTERS}} > 1 ) {
		  ## Can't assume that the filters are idempotent.
	       }
               elsif ( ref $_->{SOURCE} eq "SCALAR"
	          || ref $_->{SOURCE} eq "GLOB"
		  || UNIVERSAL::isa( $_, "IO::Handle" )
	       ) {
                  if ( $_->{KFD} == 0 ) {
                     _debug
                        "Win32 optimizer: (kid $kid->{NUM}) 0$_->{TYPE}",
                        ref $_->{SOURCE},
                        ", ok to optimize outputs"
                        if _debugging_details;
                     $ok_to_optimize_outputs = 1;
                  }
                  $_->{SEND_THROUGH_TEMP_FILE} = 1;
                  next;
               }
               elsif ( ! ref $_->{SOURCE} && defined $_->{SOURCE} ) {
                  if ( $_->{KFD} == 0 ) {
                     _debug
                        "Win32 optimizer: (kid $kid->{NUM}) 0<$_->{SOURCE}, ok to optimize outputs",
                        if _debugging_details;
                     $ok_to_optimize_outputs = 1;
                  }
                  next;
               }
            }
            _debug
               "Win32 optimizer: (kid $kid->{NUM}) ",
               $_->{KFD},
               $_->{TYPE},
               defined $_->{SOURCE}
                  ? ref $_->{SOURCE}      ? ref $_->{SOURCE}
                                          : $_->{SOURCE}
                  : defined $_->{FILENAME}
                                          ? $_->{FILENAME}
                                          : "",
	       @{$_->{FILTERS}} > 1 ? " with filters" : (),
               ", VETOING output opt."
               if _debugging_details || _debugging_not_optimized;
            $veto_output_optimization = 1;
         }
         elsif ( $_->{TYPE} eq "close" && $_->{KFD} == 0 ) {
            $ok_to_optimize_outputs = 1;
            _debug "Win32 optimizer: (kid $kid->{NUM}) saw 0<&-, ok to optimize outputs"
               if _debugging_details;
         }
         elsif ( $_->{TYPE} eq "dup" && $_->{KFD2} == 0 ) {
            $veto_output_optimization = 1;
            _debug "Win32 optimizer: (kid $kid->{NUM}) saw 0<&$_->{KFD2}, VETOING output opt."
               if _debugging_details || _debugging_not_optimized;
         }
         elsif ( $_->{TYPE} eq "|" ) {
            $saw_pipe = 1;
         }
      }

      if ( ! $ok_to_optimize_outputs && ! $veto_output_optimization ) {
         _debug
            "Win32 optimizer: (kid $kid->{NUM}) child STDIN not redirected, VETOING non-SCALAR output opt."
            if _debugging_details || _debugging_not_optimized;
         $veto_output_optimization = 1;
      }

      if ( $ok_to_optimize_outputs && $veto_output_optimization ) {
         $ok_to_optimize_outputs = 0;
         _debug "Win32 optimizer: (kid $kid->{NUM}) non-SCALAR output optimizations VETOed"
            if _debugging_details || _debugging_not_optimized;
      }

      ## SOURCE/DEST ARRAY means it's a filter.
      ## TODO: think about checking to see if the final input/output of
      ## a filter chain (an ARRAY SOURCE or DEST) is a scalar...but
      ## we may be deprecating filters.

      for ( @{$kid->{OPS}} ) {
         if ( $_->{TYPE} eq ">" ) {
            if ( ref $_->{DEST} eq "SCALAR"
               || (
                  ( @{$_->{FILTERS}} > 1
		     || ref $_->{DEST} eq "CODE"
		     || ref $_->{DEST} eq "ARRAY"  ## Filters?
	          )
                  && ( $ok_to_optimize_outputs && ! $veto_output_optimization ) 
               )
            ) {
	       $_->{RECV_THROUGH_TEMP_FILE} = 1;
	       next;
            }
	    _debug
	       "Win32 optimizer: NOT optimizing (kid $kid->{NUM}) ",
	       $_->{KFD},
	       $_->{TYPE},
	       defined $_->{DEST}
		  ? ref $_->{DEST}      ? ref $_->{DEST}
					  : $_->{SOURCE}
		  : defined $_->{FILENAME}
					  ? $_->{FILENAME}
					  : "",
		  @{$_->{FILTERS}} ? " with filters" : (),
	       if _debugging_details;
         }
      }
   }

}

=item win32_parse_cmd_line

   @words = win32_parse_cmd_line( q{foo bar 'baz baz' "bat bat"} ) ;

returns 4 words. This parses like the bourne shell (see
the bit about shellwords() in L<Text::ParseWords>), assuming we're
trying to be a little cross-platform here.  The only difference is
that "\" is *not* treated as an escape except when it precedes 
punctuation, since it's used all over the place in DOS path specs.

TODO: globbing? probably not (it's unDOSish).

TODO: shebang emulation? Probably, but perhaps that should be part
of Run.pm so all spawned processes get the benefit.

LIMITATIONS: shellwords dies silently on malformed input like 

   a\"

=cut

sub win32_parse_cmd_line {
   my $line = shift ;
   $line =~ s{(\\[\w\s])}{\\$1}g ;
   return shellwords $line ;
}


=item win32_spawn

Spawns a child process, possibly with STDIN, STDOUT, and STDERR (file descriptors 0, 1, and 2, respectively) redirected.

B<LIMITATIONS>.

Cannot redirect higher file descriptors due to lack of support for this in the
Win32 environment.

This can be worked around by marking a handle as inheritable in the
parent (or leaving it marked; this is the default in perl), obtaining it's
Win32 handle with C<Win32API::GetOSFHandle(FH)> or
C<Win32API::FdGetOsFHandle($fd)> and passing it to the child using the command
line, the environment, or any other IPC mechanism (it's a plain old integer).
The child can then use C<OsFHandleOpen()> or C<OsFHandleOpenFd()> and possibly
C<<open FOO ">&BAR">> or C<<open FOO ">&$fd>> as need be.  Ach, the pain!

Remember to check the Win32 handle against INVALID_HANDLE_VALUE.

=cut

sub _save {
   my ( $saved, $saved_as, $fd ) = @_ ;

   ## We can only save aside the original fds once.
   return if exists $saved->{$fd} ;

   my $saved_fd = IPC::Run::_dup( $fd ) ;
   _dont_inherit $saved_fd ;

   $saved->{$fd} = $saved_fd ;
   $saved_as->{$saved_fd} = $fd ;

   _dont_inherit $saved->{$fd} ;
}

sub _dup2_gently {
   my ( $saved, $saved_as, $fd1, $fd2 ) = @_ ;
   _save $saved, $saved_as, $fd2 ;

   if ( exists $saved_as->{$fd2} ) {
      ## The target fd is colliding with a saved-as fd, gotta bump
      ## the saved-as fd to another fd.
      my $orig_fd = delete $saved_as->{$fd2} ;
      my $saved_fd = IPC::Run::_dup( $fd2 ) ;
      _dont_inherit $saved_fd ;

      $saved->{$orig_fd} = $saved_fd ;
      $saved_as->{$saved_fd} = $orig_fd ;
   }
   _debug "moving $fd1 to kid's $fd2" if _debugging_details ;
   IPC::Run::_dup2_rudely( $fd1, $fd2 ) ;
}

sub win32_spawn {
   my ( $cmd, $ops) = @_ ;

   ## NOTE: The debug pipe write handle is passed to pump processes as STDOUT.
   ## and is not to the "real" child process, since they would not know
   ## what to do with it...unlike Unix, we have no code executing in the
   ## child before the "real" child is exec()ed.
   
   my %saved ;      ## Map of parent's orig fd -> saved fd
   my %saved_as ;   ## Map of parent's saved fd -> orig fd, used to
                    ## detect collisions between a KFD and the fd a
		    ## parent's fd happened to be saved to.
   
   for my $op ( @$ops ) {
      _dont_inherit $op->{FD}  if defined $op->{FD} ;

      if ( defined $op->{KFD} && $op->{KFD} > 2 ) {
	 ## TODO: Detect this in harness()
	 ## TODO: enable temporary redirections if ever necessary, not
	 ## sure why they would be...
	 ## 4>&1 1>/dev/null 1>&4 4>&-
         croak "Can't redirect fd #", $op->{KFD}, " on Win32" ;
      }

      ## This is very similar logic to IPC::Run::_do_kid_and_exit().
      if ( defined $op->{TFD} ) {
	 unless ( $op->{TFD} == $op->{KFD} ) {
	    _dup2_gently \%saved, \%saved_as, $op->{TFD}, $op->{KFD} ;
	    _dont_inherit $op->{TFD} ;
	 }
      }
      elsif ( $op->{TYPE} eq "dup" ) {
         _dup2_gently \%saved, \%saved_as, $op->{KFD1}, $op->{KFD2}
            unless $op->{KFD1} == $op->{KFD2} ;
      }
      elsif ( $op->{TYPE} eq "close" ) {
	 _save \%saved, \%saved_as, $op->{KFD} ;
	 IPC::Run::_close( $op->{KFD} ) ;
      }
      elsif ( $op->{TYPE} eq "init" ) {
	 ## TODO: detect this in harness()
         croak "init subs not allowed on Win32" ;
      }
   }

   my $process ;
   my $cmd_line = join " ", map {
      ( my $s = $_ ) =~ s/"/"""/g;
      $s = qq{"$s"} if /["\s]/;
      $s ;
   } @$cmd ;

   _debug "cmd line: ", $cmd_line
      if _debugging;

   Win32::Process::Create( 
      $process,
      $cmd->[0],
      $cmd_line,
      1,  ## Inherit handles
      NORMAL_PRIORITY_CLASS,
      ".",
   ) or croak "$!: Win32::Process::Create()" ;

   for my $orig_fd ( keys %saved ) {
      IPC::Run::_dup2_rudely( $saved{$orig_fd}, $orig_fd ) ;
      IPC::Run::_close( $saved{$orig_fd} ) ;
   }

   return ( $process->GetProcessID(), $process ) ;
}


=back

=head1 AUTHOR

Barries Slaymaker <barries@slaysys.com>.  Funded by Perforce Software, Inc.

=head1 COPYRIGHT

Copyright 2001, Barrie Slaymaker, All Rights Reserved.

You may use this under the terms of either the GPL 2.0 ir the Artistic License.

=cut

1 ;
