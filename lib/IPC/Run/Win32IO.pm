package IPC::Run::Win32IO;

=head1 NAME

IPC::Run::Win32IO - helper routines for IPC::Run on Win32 platforms.

=head1 SYNOPSIS

use IPC::Run::Win32IO;   # Exports all by default

=head1 DESCRIPTION

IPC::Run needs to use sockets to redirect subprocess I/O so that the select()
loop will work on Win32. This seems to only work on WinNT and Win2K at this
time, not sure if it will ever work on Win95 or Win98. If you have experience
in this area, please contact me at barries@slaysys.com, thanks!.

=cut

=head1 DESCRIPTION

A specialized IO class used on Win32.

=cut

use strict ;
use Carp ;
use IO::Handle ;
use Socket ;
require POSIX ;

use Socket qw( IPPROTO_TCP TCP_NODELAY ) ;
use Symbol ;
use Text::ParseWords ;
use Win32::Process ;
use IPC::Run::Debug qw( :default _debugging_level );
use IPC::Run::Win32Helper qw( _inherit _dont_inherit );
use Fcntl qw( O_TEXT O_RDONLY );

use base qw( IPC::Run::IO );
my @cleanup_fields;
BEGIN {
   ## These fields will be set to undef in _cleanup to close
   ## the handles.
   @cleanup_fields = (
      'SEND_THROUGH_TEMP_FILE', ## Set by WinHelper::optimize()
      'RECV_THROUGH_TEMP_FILE', ## Set by WinHelper::optimize()
      'TEMP_FILE_NAME',         ## The name of the temp file, needed for
                                ## error reporting / debugging only.

      'PARENT_HANDLE',       ## The handle of the socket for the parent
      'PUMP_SOCKET_HANDLE',  ## The socket handle for the pump
      'PUMP_PIPE_HANDLE',    ## The anon pipe handle for the pump
      'CHILD_HANDLE',        ## The anon pipe handle for the child

      'TEMP_FILE_HANDLE',    ## The Win32 filehandle for the temp file
   );
}

## REMOVE OSFHandleOpen
use Win32API::File qw(
   GetOsFHandle
   OsFHandleOpenFd
   OsFHandleOpen
   FdGetOsFHandle
   SetHandleInformation
   SetFilePointer
   HANDLE_FLAG_INHERIT
   INVALID_HANDLE_VALUE

   createFile
   WriteFile
   ReadFile
   CloseHandle

   FILE_ATTRIBUTE_TEMPORARY
   FILE_FLAG_DELETE_ON_CLOSE
   FILE_FLAG_WRITE_THROUGH

   FILE_BEGIN
) ;

#   FILE_ATTRIBUTE_HIDDEN
#   FILE_ATTRIBUTE_SYSTEM


BEGIN {
   ## Force AUTOLOADED constants to be, well, constant by getting them
   ## to AUTOLOAD before compilation continues.  Sigh.
   () = (
      SOL_SOCKET,
      SO_REUSEADDR,
      IPPROTO_TCP,
      TCP_NODELAY,
      HANDLE_FLAG_INHERIT,
      INVALID_HANDLE_VALUE,
   );
}


use constant temp_file_flags => (
   FILE_ATTRIBUTE_TEMPORARY()   |
   FILE_FLAG_DELETE_ON_CLOSE()  |
   FILE_FLAG_WRITE_THROUGH()
);

#   FILE_ATTRIBUTE_HIDDEN()    |
#   FILE_ATTRIBUTE_SYSTEM()    |
my $tmp_file_counter;
my $tmp_dir;

sub _cleanup {
    my IPC::Run::Win32IO $self = shift;
    my ( $harness ) = @_;

    $self->_recv_through_temp_file( $harness )
       if $self->{RECV_THROUGH_TEMP_FILE};

    CloseHandle( $self->{TEMP_FILE_HANDLE} )
       if defined $self->{TEMP_FILE_HANDLE};

    $self->{$_} = undef for @cleanup_fields;
}


sub _create_temp_file {
   my IPC::Run::Win32IO $self = shift;

   ## Create a hidden temp file that Win32 will delete when we close
   ## it.
   unless ( defined $tmp_dir ) {
      $tmp_dir = File::Spec->catdir(
         File::Spec->tmpdir, "IPC-Run.tmp"
      );

      ## Trust in the user's umask.
      ## This could possibly be a security hole, perhaps
      ## we should offer an option.  Hmmmm, really, people coding
      ## security conscious apps should audit this code and
      ## tell me how to make it better.  Nice cop-out :).
      unless ( -d $tmp_dir ) {
         mkdir $tmp_dir or croak "$!: $tmp_dir";
      }
   }

   $self->{TEMP_FILE_NAME} = File::Spec->catfile(
      ## File name is designed for easy sorting and not conflicting
      ## with other processes.  This should allow us to use "t"runcate
      ## access in CreateFile in case something left some droppings
      ## around (which should never happen because we specify
      ## FLAG_DELETE_ON_CLOSE.
      ## heh, belt and suspenders are better than bug reports; God forbid
      ## that NT should ever crash before a temp file gets deleted!
      $tmp_dir, sprintf "Win32io-%06d-%08d", $$, $tmp_file_counter++
   );

   $self->{TEMP_FILE_HANDLE} = createFile(
      $self->{TEMP_FILE_NAME},
      "trw",         ## new, truncate, read, write
      {
         Flags      => temp_file_flags,
      },
   ) or croak "Can't create temporary file, $self->{TEMP_FILE_NAME}: $^E";

   $self->{TFD} = OsFHandleOpenFd $self->{TEMP_FILE_HANDLE}, 0;
   $self->{FD} = undef;

   _debug
      "Win32 Optimizer: temp file (",
      $self->{KFD},
      $self->{TYPE},
      $self->{TFD},
      ", fh ",
      $self->{TEMP_FILE_HANDLE},
      "): ",
      $self->{TEMP_FILE_NAME}
      if _debugging_details;
}


sub _reset_temp_file_pointer {
   my $self = shift;
   SetFilePointer( $self->{TEMP_FILE_HANDLE}, 0, 0, FILE_BEGIN )
      or confess "$^E seeking on (fd $self->{TFD}) $self->{TEMP_FILE_NAME} for kid's fd $self->{KFD}";
}


sub _send_through_temp_file {
   my IPC::Run::Win32IO $self = shift;

   _debug
      "Win32 optimizer: optimizing "
      . " $self->{KFD} $self->{TYPE} temp file instead of ",
         ref $self->{SOURCE} || $self->{SOURCE}
      if _debugging_details;

   $self->_create_temp_file;

   if ( defined ${$self->{SOURCE}} ) {
      my $bytes_written = 0;
      my $data_ref;
      if ( $self->binmode ) {
	 $data_ref = $self->{SOURCE};
      }
      else {
         my $data = ${$self->{SOURCE}};  # Ugh, a copy.
	 $data =~ s/(?<!\r)\n/\r\n/g;
	 $data_ref = \$data;
      }

      WriteFile(
         $self->{TEMP_FILE_HANDLE},
         $$data_ref,
         0,              ## Write entire buffer
         $bytes_written,
         [],             ## Not overlapped.
      ) or croak
         "$^E writing $self->{TEMP_FILE_NAME} for kid to read on fd $self->{KFD}";
      _debug
         "Win32 optimizer: wrote $bytes_written to temp file $self->{TEMP_FILE_NAME}"
         if _debugging_data;

      $self->_reset_temp_file_pointer;

   }


   _debug "Win32 optimizer: kid to read $self->{KFD} from temp file on $self->{TFD}"
      if _debugging_details;
}


sub _init_recv_through_temp_file {
   my IPC::Run::Win32IO $self = shift;

   $self->_create_temp_file;
}


## TODO: USe the Win32 API in the select loop to see if the file has grown
## and read it incrementally if it has.
sub _recv_through_temp_file {
   my IPC::Run::Win32IO $self = shift;

   ## This next line kicks in if the run() never got to initting things
   ## and needs to clean up.
   return undef unless defined $self->{TEMP_FILE_HANDLE};

   push @{$self->{FILTERS}}, sub {
      my ( undef, $out_ref ) = @_;

      return undef unless defined $self->{TEMP_FILE_HANDLE};

      my $r;
      my $s;
      ReadFile(
	 $self->{TEMP_FILE_HANDLE},
	 $s,
	 999_999,  ## Hmmm, should read the size.
	 $r,
	 []
      ) or croak "$^E reading from $self->{TEMP_FILE_NAME}";

      _debug "ReadFile( $self->{TFD} ) = $r chars '$s'" if _debugging_data ;

      return undef unless $r;

      $s =~ s/\r\n/\n/g unless $self->binmode;

      my $pos = pos $$out_ref;
      $$out_ref .= $s;
      pos( $out_ref ) = $pos;
      return 1;
   };

   my ( $harness ) = @_;

   $self->_reset_temp_file_pointer;

   1 while $self->_do_filters( $harness );

   pop @{$self->{FILTERS}};

   IPC::Run::_close( $self->{TFD} );
}


sub poll {
   my IPC::Run::Win32IO $self = shift;

   return if $self->{SEND_THROUGH_TEMP_FILE} || $self->{RECV_THROUGH_TEMP_FILE};

   return $self->SUPER::poll( @_ );
}


## When threaded Perls get good enough, we should use threads here.
## The problem with threaded perls is that they dup() all sorts of
## filehandles and fds and don't allow sufficient control over
## closing off the ones we don't want.

sub _spawn_pumper {
   my ( $stdin, $stdout, $debug_fd, $binmode, $child_label, @opts ) = @_ ;
   my ( $stdin_fd, $stdout_fd ) = ( fileno $stdin, fileno $stdout ) ;

   _debug "pumper stdin = ", $stdin_fd if _debugging_details;
   _debug "pumper stdout = ", $stdout_fd if _debugging_details;
   _inherit $stdin_fd, $stdout_fd, $debug_fd ;
   my @I_options = map qq{"-I$_"}, @INC;

   my $cmd_line = join( " ",
      qq{"$^X"},
      @I_options,
      qw(-MIPC::Run::Win32Pump -e 1 ),
## I'm using this clunky way of passing filehandles to the child process
## in order to avoid some kind of premature closure of filehandles
## problem I was having with VCP's test suite when passing them
## via CreateProcess.  All of the ## REMOVE code is stuff I'd like
## to be rid of and the ## ADD code is what I'd like to use.
      FdGetOsFHandle( $stdin_fd ), ## REMOVE
      FdGetOsFHandle( $stdout_fd ), ## REMOVE
      FdGetOsFHandle( $debug_fd ), ## REMOVE
      $binmode ? 1 : 0,
      $$, $^T, _debugging_level, qq{"$child_label"},
      @opts
   ) ;

#   open SAVEIN,  "<&STDIN"  or croak "$! saving STDIN" ;       #### ADD
#   open SAVEOUT, ">&STDOUT" or croak "$! saving STDOUT" ;       #### ADD
#   open SAVEERR, ">&STDERR" or croak "$! saving STDERR" ;       #### ADD
#   _dont_inherit \*SAVEIN ;       #### ADD
#   _dont_inherit \*SAVEOUT ;       #### ADD
#   _dont_inherit \*SAVEERR ;       #### ADD
#   open STDIN,  "<&$stdin_fd"  or croak "$! dup2()ing $stdin_fd (pumper's STDIN)" ;       #### ADD
#   open STDOUT, ">&$stdout_fd" or croak "$! dup2()ing $stdout_fd (pumper's STDOUT)" ;       #### ADD
#   open STDERR, ">&$debug_fd" or croak "$! dup2()ing $debug_fd (pumper's STDERR/debug_fd)" ;       #### ADD

   _debug "pump cmd line: ", $cmd_line if _debugging_details;

   my $process ;
   Win32::Process::Create( 
      $process,
      $^X,
      $cmd_line,
      1,  ## Inherit handles
      NORMAL_PRIORITY_CLASS,
      ".",
   ) or croak "$!: Win32::Process::Create()" ;

#   open STDIN,  "<&SAVEIN"  or croak "$! restoring STDIN" ;       #### ADD
#   open STDOUT, ">&SAVEOUT" or croak "$! restoring STDOUT" ;       #### ADD
#   open STDERR, ">&SAVEERR" or croak "$! restoring STDERR" ;       #### ADD
#   close SAVEIN             or croak "$! closing SAVEIN" ;       #### ADD
#   close SAVEOUT            or croak "$! closing SAVEOUT" ;       #### ADD
#   close SAVEERR            or croak "$! closing SAVEERR" ;       #### ADD

   close $stdin  or croak "$! closing pumper's stdin in parent" ;
   close $stdout or croak "$! closing pumper's stdout in parent" ;
   # Don't close $debug_fd, we need it, as do other pumpers.

   # Pause a moment to allow the child to get up and running and emit
   # debug messages.  This does not always work.
   #   select undef, undef, undef, 1 if _debugging_details ;

   _debug "_spawn_pumper pid = ", $process->GetProcessID 
      if _debugging_data;
}


my $next_port = 2048 ;
my $loopback  = inet_aton "127.0.0.1" ;
my $tcp_proto = getprotobyname('tcp');
croak "$!: getprotobyname('tcp')" unless defined $tcp_proto ;

sub _socket {
   my ( $server ) = @_ ;
   $server ||= gensym ;
   my $client = gensym ;

   my $listener = gensym ;
   socket $listener, PF_INET, SOCK_STREAM, $tcp_proto
      or croak "$!: socket()";
   setsockopt $listener, SOL_SOCKET, SO_REUSEADDR, pack("l", 0)
      or croak "$!: setsockopt()";

   my $port ;
   my @errors ;
PORT_FINDER_LOOP:
   {
      $port = $next_port ;
      $next_port = 2048 if ++$next_port > 65_535 ; 
      unless ( bind $listener, sockaddr_in( $port, INADDR_ANY ) ) {
	 push @errors, "$! on port $port" ;
	 croak join "\n", @errors if @errors > 10 ;
         goto PORT_FINDER_LOOP;
      }
   }

   _debug "win32 port = $port" if _debugging_details;

   listen $listener, my $queue_size = 1
      or croak "$!: listen()" ;

   {
      socket $client, PF_INET, SOCK_STREAM, $tcp_proto
         or croak "$!: socket()";

      my $paddr = sockaddr_in($port, $loopback );

      connect $client, $paddr
         or croak "$!: connect()" ;
    
      croak "$!: accept" unless defined $paddr ;

      ## The windows "default" is SO_DONTLINGER, which should make
      ## sure all socket data goes through.  I have my doubts based
      ## on experimentation, but nothing prompts me to set SO_LINGER
      ## at this time...
      setsockopt $client, IPPROTO_TCP, TCP_NODELAY, pack("l", 0)
	 or croak "$!: setsockopt()";
   }

   {
      _debug "accept()ing on port $port" if _debugging_details;
      my $paddr = accept( $server, $listener ) ;
      croak "$!: accept()" unless defined $paddr ;
   }

   _debug
      "win32 _socket = ( ", fileno $server, ", ", fileno $client, " ) on port $port" 
      if _debugging_details;
   return ( $server, $client ) ;
}


sub _open_socket_pipe {
   my IPC::Run::Win32IO $self = shift;
   my ( $debug_fd, $parent_handle ) = @_ ;

   my $is_send_to_child = $self->dir eq "<";

   $self->{CHILD_HANDLE}     = gensym;
   $self->{PUMP_PIPE_HANDLE} = gensym;

   ( 
      $self->{PARENT_HANDLE},
      $self->{PUMP_SOCKET_HANDLE}
   ) = _socket $parent_handle ;

   ## These binmodes seem to have no effect on Win2K, but just to be safe
   ## I do them.
   binmode $self->{PARENT_HANDLE}      or die $!;
   binmode $self->{PUMP_SOCKET_HANDLE} or die $!;

_debug "PUMP_SOCKET_HANDLE = ", fileno $self->{PUMP_SOCKET_HANDLE}
   if _debugging_details;
##my $buf ;
##$buf = "write on child end of " . fileno( $self->{WRITE_HANDLE} ) . "\n\n\n\n\n" ;
##POSIX::write(fileno $self->{WRITE_HANDLE}, $buf, length $buf) or warn "$! in syswrite" ;
##$buf = "write on parent end of " . fileno( $self->{CHILD_HANDLE} ) . "\r\n" ;
##POSIX::write(fileno $self->{CHILD_HANDLE},$buf, length $buf) or warn "$! in syswrite" ;
##   $self->{CHILD_HANDLE}->autoflush( 1 ) ;
##   $self->{WRITE_HANDLE}->autoflush( 1 ) ;

   ## Now fork off a data pump and arrange to return the correct fds.
   if ( $is_send_to_child ) {
      pipe $self->{CHILD_HANDLE}, $self->{PUMP_PIPE_HANDLE}
         or croak "$! opening child pipe" ;
_debug "CHILD_HANDLE = ", fileno $self->{CHILD_HANDLE}
   if _debugging_details;
_debug "PUMP_PIPE_HANDLE = ", fileno $self->{PUMP_PIPE_HANDLE}
   if _debugging_details;
   }
   else {
      pipe $self->{PUMP_PIPE_HANDLE}, $self->{CHILD_HANDLE}
         or croak "$! opening child pipe" ;
_debug "CHILD_HANDLE = ", fileno $self->{CHILD_HANDLE}
   if _debugging_details;
_debug "PUMP_PIPE_HANDLE = ", fileno $self->{PUMP_PIPE_HANDLE}
   if _debugging_details;
   }

   ## These binmodes seem to have no effect on Win2K, but just to be safe
   ## I do them.
   binmode $self->{CHILD_HANDLE};
   binmode $self->{PUMP_PIPE_HANDLE};

   ## No child should ever see this.
   _dont_inherit $self->{PARENT_HANDLE} ;

   ## We clear the inherit flag so these file descriptors are not inherited.
   ## It'll be dup()ed on to STDIN/STDOUT/STDERR before CreateProcess is
   ## called and *that* fd will be inheritable.
   _dont_inherit $self->{PUMP_SOCKET_HANDLE} ;
   _dont_inherit $self->{PUMP_PIPE_HANDLE} ;
   _dont_inherit $self->{CHILD_HANDLE} ;

   ## Need to return $self so the HANDLEs don't get freed.
   ## Return $self, $parent_fd, $child_fd
   my ( $parent_fd, $child_fd ) = (
      fileno $self->{PARENT_HANDLE},
      fileno $self->{CHILD_HANDLE}
   ) ;

   ## Both PUMP_..._HANDLEs will be closed, no need to worry about
   ## inheritance.
   _debug "binmode on" if _debugging_data && $self->binmode;
   _spawn_pumper(
      $is_send_to_child
	 ? ( $self->{PUMP_SOCKET_HANDLE}, $self->{PUMP_PIPE_HANDLE} )
	 : ( $self->{PUMP_PIPE_HANDLE}, $self->{PUMP_SOCKET_HANDLE} ),
      $debug_fd,
      $self->binmode,
      $child_fd . $self->dir . "pump" . $self->dir . $parent_fd,
   ) ;

{
my $foo ;
confess "PARENT_HANDLE no longer open"
   unless POSIX::read( $parent_fd, $foo, 0 ) ;
}

   _debug "win32_fake_pipe = ( $parent_fd, $child_fd )"
      if _debugging_details;

   $self->{FD}  = $parent_fd;
   $self->{TFD} = $child_fd;
}

sub _do_open {
   my IPC::Run::Win32IO $self = shift;

   if ( $self->{SEND_THROUGH_TEMP_FILE} ) {
      return $self->_send_through_temp_file( @_ );
   }
   elsif ( $self->{RECV_THROUGH_TEMP_FILE} ) {
      return $self->_init_recv_through_temp_file( @_ );
   }
   else {
      return $self->_open_socket_pipe( @_ );
   }
}

=head1 AUTHOR

Barries Slaymaker <barries@slaysys.com>.  Funded by Perforce Software, Inc.

=head1 COPYRIGHT

Copyright 2001, Barrie Slaymaker, All Rights Reserved.

You may use this under the terms of either the GPL 2.0 ir the Artistic License.

=cut

1;
