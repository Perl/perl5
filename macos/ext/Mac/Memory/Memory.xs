/*
 *
 *    Copyright (c) 1996 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: Memory.xs,v $
 * Revision 1.2  2000/09/09 22:18:27  neeri
 * Dynamic libraries compile under 5.6
 *
 * Revision 1.1  2000/08/14 03:39:31  neeri
 * Checked into Sourceforge
 *
 * Revision 1.4  1999/06/04 16:01:31  pudge
 * Fixed Handle::get again.  Added version number (1.20).
 *
 * Revision 1.3  1999/06/03 19:27:41  pudge
 * Fixed bug in Handle::get, for returning data when handle size is 0.
 *
 * Revision 1.2  1997/11/18 00:52:34  neeri
 * MacPerl 5.1.5
 *
 * Revision 1.1  1997/04/07 20:49:55  neeri
 * Synchronized with MacPerl 5.1.4a1
 *
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#include <Memory.h>
#include <TextUtils.h>

typedef int	SysRet;

#define MemErrorReturn	\
	ST(0) = sv_newmortal();					\
	if (!(gMacPerl_OSErr = MemError()))	\
		sv_setiv(ST(0), 1);

MODULE = Mac::Memory	PACKAGE = Handle

=head2 Handle

Handle provides an object interface to do simple operations on MacOS handles.
The interface is simpler than the more general memory management functions.

=item new

=item new STRING

Create a new handle and return it. Copy $STRING into the handle if present.
Return a 0 value if a handle could not be created.

	$h = new Handle;
	$hs = new Handle("This string will now exist in hyperspace");

=cut

HandleRet
new(package,data=0)
	SV *	package
	SV *	data
	CODE:
	if (data) {
		STRLEN	len;
		Ptr		ptr	=	SvPV(data, len);
		if (gMacPerl_OSErr = PtrToHand(ptr, &RETVAL, len)) {
			XSRETURN_UNDEF;
		}
	} else
		RETVAL = NewHandle(0);
	OUTPUT:
	RETVAL

=item size

Return the size of a handle (i.e., its data portion).

	die unless (new Handle)->size == 0;
	die unless $hs->size == 40;

=cut

long
size(hand)
	Handle	hand
	CODE:
	RETVAL = GetHandleSize(hand);
	OUTPUT:
	RETVAL

=item append DATA 

Appends the DATA to the end of the handle
and returns the success as the result.

	$h->append("This string will now exist in hyperspace");
	die unless $h->size == 40;

=cut

Boolean
append(hand, data)
	Handle	hand
	SV *		data
	CODE:
	{
		STRLEN	len;
		Ptr		ptr	=	SvPV(data, len);
		RETVAL = !PtrAndHand(ptr, hand, len);
	}
	OUTPUT:
	RETVAL

=item set OFFSET, LENGTH, DATA 

=item set OFFSET, LENGTH 

=item set OFFSET 

=item set

Munge the contents of the handle with the $DATA (deleting if not present), for the
$LENGTH (through to the end of the handle contents if not present), starting at
$OFFSET (the beginning if not present).

	$h->set(5, 6, "datum");
	
yields

	"This datum will now exist in hyperspace"


=cut

Boolean
set(hand, offset=0, length=-1, data=0)
	Handle	hand
	long		offset
	long		length
	SV *		data
	CODE:	
	{
		STRLEN	len;
		Ptr		ptr;
		if (data)
			ptr =	SvPV(data, len);
		else {
			len = 0;
			ptr = (char *) -1;
		}
		RETVAL = 0 <= Munger(hand, offset, nil, length, ptr, len);
	}
	OUTPUT:
	RETVAL

=item get OFFSET, LENGTH 

=item get OFFSET 

=item get

Return a datum which is the contents of the memory referenced by $HANDLE, 
starting at $OFFSET (default zero), of length $LENGTH (default the rest
of the handle).

	die unless $hs->get(5, 6) eq "string";

=cut

SV *
get(hand, offset=0, length=-1)
	Handle	hand
	long		offset
	long		length
	CODE:
	{
		char state = HGetState(hand);
		HLock(hand);
		if (GetHandleSize(hand) > 0) {
			if (length < 0)
				length = GetHandleSize(hand) - offset;
			RETVAL = newSVpv(*hand+offset, length);
			HSetState(hand, state);
		} else {
		    XSRETURN_UNDEF;
		}
	}
	OUTPUT:
	RETVAL

=item address 

Return the address of the memory block.

=cut

RawPtr
address(hand)
	Handle	hand
	CODE:
	RETVAL = *hand;
	OUTPUT:
	RETVAL

=item state

=item state NEWSTATE 

Return the (locked) state of the handle, or return TRUE if the $NEWSTATE
of the handle is installed.

	my $state = $h->state;
	HLock($h);
	# bunch of operations requiring $h to be locked
	$h->state($state);	# so nested locks exit properly

More than the lock state is stored here, so restoring the actual state on leaving
a scope is required.


=cut
char
state(hand, state=0)
	Handle	hand
	char		state
	CODE:
	if (items == 1)
		RETVAL = HGetState(hand);
	else {
		HSetState(hand, state);
		RETVAL = 1;
	}
	OUTPUT:
	RETVAL

=item open MODE

Open a stream to a handle and return it.

NOT DEFINED AT THE MOMENT

SysRet
_open(hand, mode)
	Handle	hand
	int		mode
	CODE:
	RETVAL = OpenHandle(hand, mode);
	OUTPUT:
	RETVAL
	
=item dispose

Disposes of the handle.
Return zero if no error was detected.

=cut

void
dispose(hand)
	Handle	hand
	CODE:
	DisposeHandle(hand);
	CLEANUP:
	MemErrorReturn

=back

Almost all of the memory management needs in MacPerl can be handled by the above interface

=cut

MODULE = Mac::Memory	PACKAGE = Ptr
=head2 Ptr

Handle provides an object interface to do simple operations on MacOS pointers
(nonrelocatable heap blocks). There are very few good reasons to create pointers
like this.

=cut

PtrRet
new(package,len)
	SV *	package
	long	len
	CODE:
	RETVAL = NewPtr(len);
	OUTPUT:
	RETVAL

=item size

Return the size of a pointer (i.e., its data portion).

	die unless $ptr->size == 40;


=cut
long
size(ptr)
	Ptr	ptr
	CODE:
	RETVAL = GetPtrSize(ptr);
	OUTPUT:
	RETVAL

=item set OFFSET, DATA 

=cut
Boolean
set(ptr, offset, data)
	Ptr		ptr
	long		offset
	SV *		data
	CODE:	
	{
		STRLEN	len;
		Ptr		p;
		p =	SvPV(data, len);
		BlockMove(p, ptr+offset, len);
		RETVAL = 1;
	}
	OUTPUT:
	RETVAL

=item get OFFSET, LENGTH 

=item get OFFSET 

=item get

Return a datum which is the contents of the memory referenced by PTR, 
starting at $OFFSET (default zero), of length $LENGTH (default the rest
of the block).

	die unless $ps->get(5, 6) eq "string";


=cut
SV *
get(ptr, offset=0, length=-1)
	Ptr		ptr
	long		offset
	long		length
	CODE:
	{
		if (length < 0)
			length = GetPtrSize(ptr) - offset;
		RETVAL = newSVpv(ptr+offset, length);
	}
	OUTPUT:
	RETVAL

=item address 

Return the address of the memory block.

=cut

RawPtr
address(ptr)
	Ptr		ptr
	CODE:
	RETVAL = ptr;
	OUTPUT:
	RETVAL

=item dispose

Disposes of the block.
Return zero if no error was detected.

=back

=cut
void
dispose(ptr)
	Ptr	ptr
	CODE:
	DisposePtr(ptr);
	CLEANUP:
	MemErrorReturn


MODULE = Mac::Memory	PACKAGE = Mac::Memory

=head2 Functions

=over 4

=item GetApplLimit

The GetApplLimit function returns the current application heap limit.


=cut
RawPtr
GetApplLimit()

=item TopMem

Return a pointer to the top of memory for the application.



=cut
RawPtr
TopMem()

=item NewHandle BYTECOUNT

=item NewHandleSys BYTECOUNT

=item NewHandleClear BYTECOUNT

=item NewHandleSysClear BYTECOUNT

Return a handle of $BYTECOUNT size.

NewHandleSys returns a handle in the system heap.

The NewHandleClear and NewHandleSysClear functions work much as the NewHandle
and NewHandleSys functions do but set
all bytes in the new block to 0 instead of leaving the contents of the block
undefined.
Currently, this is quite inefficient.


=cut
HandleRet
NewHandle(byteCount)
	long	byteCount

HandleRet
NewHandleSys(byteCount)
	long	byteCount

HandleRet
NewHandleClear(byteCount)
	long	byteCount

HandleRet
NewHandleSysClear(byteCount)
	long	byteCount

=item NewPtr BYTECOUNT

=item NewPtrSys BYTECOUNT

=item NewPtrClear BYTECOUNT

=item NewPtrSysClear BYTECOUNT

Allocate a nonrelocatable block of memory of a specified size.

NewPtrSys and NewPtrSysClear allocate blocks in the system heap.

NewPtrClear and NewPtrSysClear allocate and zero the blocks (inefficiently).


=cut
PtrRet
NewPtr(byteCount)
	long	byteCount
	CLEANUP:
	gMacPerl_OSErr = MemError();

PtrRet
NewPtrSys(byteCount)
	long	byteCount
	CLEANUP:
	gMacPerl_OSErr = MemError();

PtrRet
NewPtrClear(byteCount)
	long	byteCount
	CLEANUP:
	gMacPerl_OSErr = MemError();

PtrRet
NewPtrSysClear(byteCount)
	long	byteCount
	CLEANUP:
	gMacPerl_OSErr = MemError();

=item MaxBlock

=item MaxBlockSys

The MaxBlock function returns the maximum contiguous space, in bytes, that you
could obtain after compacting the current heap zone. MaxBlock does not actually
do the compaction.

MaxBlockSys does the same for the system heap.


=cut
long
MaxBlock()

long
MaxBlockSys()

=item StackSpace

The StackSpace function returns the current amount of stack space (in bytes)
between the current stack pointer and the application heap at the instant of
return from the trap.


=cut
long
StackSpace()

=item NewEmptyHandle

=item NewEmptyHandleSys

The NewEmptyHandle function initializes a new handle by allocating a master
pointer for it, but it does not allocate any memory for the handle to control.
NewEmptyHandle
sets the handle's master pointer to NIL.

NewEmptyHandleSys does the same for the system heap.


=cut
HandleRet
NewEmptyHandle()

HandleRet
NewEmptyHandleSys()

=item HLock HANDLE

Lock a relocatable block so that it does not move in the heap. If you plan to
dereference a handle and then allocate, move, or purge memory (or call a routine
that does so), then you should lock the handle before using the dereferenced
handle.


=cut
void
HLock(h)
	Handle	h
	CLEANUP:
	MemErrorReturn

=item HUnlock HANDLE

Unlock a relocatable block so that it is free to move in its heap zone.


=cut
void
HUnlock(h)
	Handle	h
	CLEANUP:
	MemErrorReturn

=item HPurge HANDLE

Mark a relocatable block so that it can be purged if a memory request cannot be
fulfilled after compaction.


=cut
void
HPurge(h)
	Handle	h
	CLEANUP:
	MemErrorReturn

=item HNoPurge HANDLE

Mark a relocatable block so that it cannot be purged.


=cut
void
HNoPurge(h)
	Handle	h
	CLEANUP:
	MemErrorReturn

=item HLockHi HANDLE

The HLockHi procedure attempts to move the relocatable block referenced by the
handle $HANDLE upward until it reaches a nonrelocatable block, a locked relocatable
block, or the top of the heap. Then HLockHi locks the block.


=cut
void
HLockHi(h)
	Handle	h
	CLEANUP:
	MemErrorReturn

=item TempNewHandle BYTECOUNT

The TempNewHandle function returns a handle to a block of size $BYTECOUNT from
temporary memory. If it
cannot allocate a block of that size, the function returns NIL.


=cut
Handle
TempNewHandle(logicalSize)
	long	logicalSize
	CODE:
	{
		RETVAL = TempNewHandle(logicalSize, &gMacPerl_OSErr);
		if (gMacPerl_OSErr) {
			XSRETURN_UNDEF;
		}
	}
	OUTPUT:
	RETVAL

=item TempMaxMem

The TempMaxMem function compacts the current heap zone and returns the size of
the largest contiguous block available for temporary allocation.

	$SIZE = &TempMaxMem;


=cut
long
TempMaxMem()
	CODE:
	{
		long	grow;
		RETVAL = TempMaxMem(&grow);
	}
	OUTPUT:
	RETVAL

=item TempFreeMem

The TempFreeMem function returns the total amount of free temporary memory that
you could allocate by calling TempNewHandle. The returned value is the total
number of free bytes. Because these bytes might be dispersed throughout memory,
it is ordinarily not possible to allocate a single relocatable block of that
size.

	$SIZE = &TempFreeMem;


=cut
long
TempFreeMem()

=item CompactMem BYTECOUNT

=item CompactMemSys BYTECOUNT

The CompactMem function compacts the current heap zone by moving unlocked,
relocatable blocks down until they encounter nonrelocatable blocks or locked,
relocatable blocks, but not by purging blocks. It continues compacting until it
either finds a contiguous block of at least $BYTECOUNT free bytes or has compacted
the entire zone.

The CompactMem function returns the size, in bytes, of the largest contiguous
free block for which it could make room, but it does not actually allocate that
block.

CompactMemSys does the same for the system heap.


=cut
long
CompactMem(cbNeeded)
	long	cbNeeded

long
CompactMemSys(cbNeeded)
	long	cbNeeded

=item PurgeMem BYTECOUNT

=item PurgeMemSys BYTECOUNT

The PurgeMem procedure sequentially purges blocks from the current heap zone
until it either allocates a contiguous block of at least $BYTECOUNT free bytes or
has purged the entire zone. If it purges the entire zone without creating a
contiguous block of at least $BYTECOUNT free bytes, PurgeMem generates a
memFullErr.

The PurgeMem procedure purges only relocatable, unlocked, purgeable blocks.

The PurgeMem procedure does not actually attempt to allocate a block of  $BYTECOUNT
bytes.

PurgeMemSys does the same for the system heap.


=cut
void
PurgeMem(cbNeeded)
	long	cbNeeded

void
PurgeMemSys(cbNeeded)
	long	cbNeeded

=item FreeMem

=item FreeMemSys

The FreeMem function returns the total amount of free space (in bytes) in the
current heap zone. Note that it usually isn't possible to allocate a block of
that size, because of heap fragmentation due to nonrelocatable or locked blocks.

FreeMemSys does the same for the system heap.


=cut
long
FreeMem()

long
FreeMemSys()

=item ReserveMem BYTECOUNT

=item ReserveMemSys BYTECOUNT

The ReserveMem procedure attempts to create free space for a block of $BYTECOUNT
contiguous logical bytes at the lowest possible position in the current heap
zone. It pursues every available means of placing the block as close as possible
to the bottom of the zone, including moving other relocatable blocks upward,
expanding the zone (if possible), and purging blocks from it. 

ReserveMemSys does the same for the system heap.


=cut
void
ReserveMem(cbNeeded)
	long	cbNeeded

void
ReserveMemSys(cbNeeded)
	long	cbNeeded

=item MaxMem

=item MaxMemSys

Use the MaxMem function to compact and purge the current heap zone. The values
returned are the amount of memory available and the amount by which the zone can
grow.

	($SIZE, $GROW) = &MaxMem;

MaxMemSys does the purge and compact of the system heap zone, and the $GROW value
is set to zero.


=cut
void
MaxMem()
	PPCODE:
	{
		long	grow;
		
		XS_PUSH(long, MaxMem(&grow));
		if (GIMME == G_ARRAY) {
			XS_PUSH(long, grow);
		}
	}

void
MaxMemSys()
	PPCODE:
	{
		long	grow;
		
		XS_PUSH(long, MaxMemSys(&grow));
		if (GIMME == G_ARRAY) {
			XS_PUSH(long, grow);
		}
	}

=item MoveHHi HANDLE

The MoveHHi procedure attempts to move the relocatable block referenced by the
handle $HANDLE upward until it reaches a nonrelocatable block, a locked relocatable
block, or the top of the heap.


=cut
void
MoveHHi(h)
	Handle	h
	CLEANUP:
	MemErrorReturn

=item DisposePtr PTR

Releases the memory occupied by the nonrelocatable block specified by $PTR.


=cut
void
DisposePtr(p)
	Ptr	p
	CLEANUP:
	MemErrorReturn

=item GetPtrSize PTR

The GetPtrSize function returns the logical size, in bytes, of the nonrelocatable
block pointed to by $PTR.


=cut
long
GetPtrSize(p)
	Ptr	p
	CLEANUP:
	gMacPerl_OSErr = MemError();

=item SetPtrSize PTR, NEWSIZE

The SetPtrSize procedure attempts to change the logical size of the
nonrelocatable block pointed to by $PTR. The new logical size is specified by
$NEWSIZE.
Return zero if no error was detected.


=cut
void
SetPtrSize(p, newSize)
	Ptr	p
	long	newSize
	CLEANUP:
	MemErrorReturn

=item DisposeHandle HANDLE

The DisposeHandle procedure releases the memory occupied by the relocatable block
whose handle is $HANDLE. It also frees the handle's master pointer for other uses.


=cut
void
DisposeHandle(h)
	Handle	h
	CLEANUP:
	MemErrorReturn

=item SetHandleSize HANDLE, BYTECOUNT

The SetHandleSize procedure attempts to change the logical size of the
relocatable block whose handle is $HANDLE. The new logical size is specified by
$BYTECOUNT.
Return zero if no error was detected.


=cut
void
SetHandleSize(h, newSize)
	Handle	h
	long		newSize
	CLEANUP:
	MemErrorReturn

=item GetHandleSize HANDLE

The GetHandleSize function returns the logical size, in bytes, of the relocatable
block whose handle is $HANDLE. In case of an error, GetHandleSize returns 0.


=cut
long
GetHandleSize(h)
	Handle	h

=item ReallocateHandle HANDLE, BYTECOUNT

Allocates a new relocatable block with a logical size of $BYTECOUNT bytes. It
updates the handle $HANDLE by setting its master pointer to point to the new block. 
The new block is unlocked and unpurgeable.
Return zero if no error was detected.


=cut
void
ReallocateHandle(h, byteCount)
	Handle	h
	long		byteCount
	CLEANUP:
	MemErrorReturn

=item EmptyHandle

Free memory taken by a relocatable block without freeing the relocatable block's
master pointer for other uses.


=cut
void
EmptyHandle(h)
	Handle	h
	CLEANUP:
	MemErrorReturn

=item MoreMasters

Call the MoreMasters procedure several times at the beginning of your program to
prevent the Memory Manager from running out of master pointers in the middle of
application execution. If it does run out, it allocates more, possibly causing
heap fragmentation.


=cut
void
MoreMasters()
	CLEANUP:
	MemErrorReturn

=item BlockMove SOURCEPTR, DESTPTR, BYTECOUNT

=item BlockMoveData SOURCEPTR, DESTPTR, BYTECOUNT

The BlockMove/BlockMoveData procedure moves a block of $BYTECOUNT consecutive bytes from the
address designated by $SOURCEPTR to that designated by $DESTPTR.


=cut
void
BlockMove(srcPtr, destPtr, byteCount)
	RawPtr	srcPtr
	RawPtr	destPtr
	long	byteCount

void
BlockMoveData(srcPtr, destPtr, byteCount)
	RawPtr	srcPtr
	RawPtr	destPtr
	long	byteCount

=item PurgeSpace

Determine the total amount of free memory and the size of the largest allocatable
block after a purge of the heap.

	($Total, $Contiguous) = &PurgeSpace;


=cut
void
PurgeSpace()
	PPCODE:
	{
		long	total;
		long	contig;
	
		PurgeSpace(&total, &contig);
		EXTEND(sp, 2);
		PUSHs(sv_2mortal(newSViv(total)));
		PUSHs(sv_2mortal(newSViv(contig)));
	}	

=item HGetState HANDLE

Get the current properties of a relocatable block (perhaps so that you can change
and then later restore those properties).


=cut
char
HGetState(h)
	Handle	h
	CLEANUP:
	if (gMacPerl_OSErr = MemError())
		RETVAL = 0;

=item HSetState HANDLE, STATE

Restore properties of a block after a call to HGetState.


=cut
void
HSetState(h, flags)
	Handle	h
	char		flags
	CLEANUP:
	MemErrorReturn

=item HandToHand HANDLE

The HandToHand function attempts to copy the information in the relocatable block
to which $HANDLE is a handle.
Return C<undef> if an error was detected.


=cut
Handle
HandToHand(theHndl)
	Handle	&theHndl
	CODE:
	if (gMacPerl_OSErr = HandToHand(&theHndl)) {
		XSRETURN_UNDEF;
	} else {
		RETVAL = theHndl;
	}
	OUTPUT:
	RETVAL

=item PtrToHand PTR, BYTECOUNT

The PtrToHand function returns a newly created handle to a copy of
the number of bytes specified by $BYTECOUNT, beginning at the location
specified by $PTR.
Return C<undef> if an error was detected.


=cut
Handle
PtrToHand(srcPtr, size)
	Ptr		srcPtr
	long		size
	CODE:
	if (gMacPerl_OSErr = PtrToHand(srcPtr, &RETVAL, size)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item PtrToXHand HANDLE, PTR, BYTECOUNT

The PtrToXHand function makes the existing handle, specified by $HANDLE, a handle
to a copy of the number of bytes specified by $BYTECOUNT, beginning at
the location specified by $PTR.
Return C<undef> if an error was detected.


=cut
MacOSRet
PtrToXHand(srcPtr, dstHndl, size)
	Ptr		srcPtr
	Handle	dstHndl
	long		size

=item HandAndHand AHNDLE, BHNDLE

The HandAndHand function concatenates the information from the relocatable block
to which $AHNDL is a handle onto the end of the relocatable block to which $BHNDL
is a handle. The $AHNDL variable remains unchanged.
Return zero if no error was detected.


=cut
MacOSRet
HandAndHand(hand1, hand2)
	Handle	hand1
	Handle	hand2
	CODE:
	{
		char	state = HGetState(hand1);
		HLock(hand1);
		RETVAL = HandAndHand(hand1, hand2);
		HSetState(hand1, state);
	}
	OUTPUT:
	RETVAL

=item PtrAndHand PTR, HANDLE, BYTECOUNT

The PtrAndHand function takes the number of bytes specified by $BYTECOUNT, 
beginning at the location specified by $PTR, and concatenates them
onto the end of the relocatable block to which $HANDLE is a handle.


=cut
MacOSRet
PtrAndHand(ptr1, hand2, size)
	Ptr		ptr1
	Handle	hand2
	long		size

=back

=cut
