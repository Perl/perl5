=head1 NAME

MacOS Memory Manager

Provide the MacPerl interface to the memory management routines in the MacOS.

Access to Inside Macintosh is essential for proper use of these functions.
Explanations of terms, processes and procedures are provided there.
Any attempt to use these functions without guidance can cause severe errors in 
your machine, including corruption of data. B<You have been warned.>

=head1 SYNOPSIS

The Memory module defines Ptr and Handle classes, and function interfaces to the 
memory management.

	use Mac::Memory;
	$handle = new Handle;
	$handle2 = NewHandle;

=head1 DESCRIPTION

The following packages and functions provide low level access to the memory
management functions.

=cut

use strict;

package Mac::Memory;

BEGIN {
	use Exporter   ();
	use DynaLoader ();
	
	use vars qw($VERSION @ISA @EXPORT);
	$VERSION = '1.20';
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		GetApplLimit
		TopMem
		MemError
		NewHandle
		NewHandleSys
		NewHandleClear
		NewHandleSysClear
		RecoverHandle
		RecoverHandleSys
		NewPtr
		NewPtrSys
		NewPtrClear
		NewPtrSysClear
		MaxBlock
		MaxBlockSys
		StackSpace
		NewEmptyHandle
		NewEmptyHandleSys
		HLock
		HUnlock
		HPurge
		HNoPurge
		HLockHi
		TempNewHandle
		TempMaxMem
		TempFreeMem
		CompactMem
		CompactMemSys
		PurgeMem
		PurgeMemSys
		FreeMem
		FreeMemSys
		ReserveMem
		ReserveMemSys
		MaxMem
		MaxMemSys
		MoveHHi
		DisposePtr
		GetPtrSize
		SetPtrSize
		DisposeHandle
		SetHandleSize
		GetHandleSize
		ReallocateHandle
		EmptyHandle
		MoreMasters
		BlockMove
		BlockMoveData
		PurgeSpace
		HGetState
		HSetState
		HandToHand
		PtrToHand
		PtrToXHand
		HandAndHand
		PtrAndHand
	);
}

=include Memory.xs

=cut

bootstrap Mac::Memory;

package Handle;

BEGIN {
	use Fcntl;
	use IO::Handle qw(_IONBF);
}

sub open {
	my($handle,$modestr) = @_;
	my($mode,$fd,$fh);
	
	if ($modestr =~ s/\+//) {
		$mode = O_RDWR;
	} elsif ($modestr =~ /[aw>]/) {
		$mode = O_WRONLY;
	} else {
		$mode = O_RDONLY;
	}
	
	if ($modestr =~ />>|a/) {
		$mode += O_APPEND;
	}
	
	if ($fd = $handle->_open($mode)) {
		$fh = new_from_fd IO::Handle(($fd+0), $modestr);
		$fh->setvbuf(undef, _IONBF, 0);
		return $fh;
	} else {
		return undef;
	}
}

=pod

The low level interface is not likely to be needed, except for the HLock() function.

=head1 Author

Matthias Ulrich Neeracher neeracher@mac.com "Programs"

Bob Dalgleish <bob.dalgleish@sasknet.sk.ca> "Documentation"

=cut

1;

__END__
