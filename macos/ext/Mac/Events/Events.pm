
=head1 NAME

Mac::Events - Macintosh Toolbox Interface to Event Manager

=head1 SYNOPSIS


=head1 DESCRIPTION

Access to Inside Macintosh is essential for proper use of these functions.
Explanations of terms, processes and procedures are provided there.
Any attempt to use these functions without guidance can cause severe errors in 
your machine, including corruption of data. B<You have been warned.>

=cut

use strict;

package Mac::Events;

BEGIN {
	use Exporter   ();
	use DynaLoader ();
	
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $CurrentEvent @SavedEvents @Event);
	$VERSION = '1.00';
	@ISA = qw(Exporter DynaLoader);
	
	@EXPORT = qw(
		GetCaretTime
		GetDblTime
		GetMouse
		Button
		StillDown
		WaitMouseUp
		TickCount
		FlushEvents
		WaitNextEvent
	
		nullEvent
		mouseDown
		mouseUp
		keyDown
		keyUp
		autoKey
		updateEvt
		diskEvt
		activateEvt
		osEvt
		kHighLevelEvent
		mDownMask
		mUpMask
		keyDownMask
		keyUpMask
		autoKeyMask
		updateMask
		diskMask
		activMask
		highLevelEventMask
		osMask
		everyEvent
		charCodeMask
		keyCodeMask
		adbAddrMask
		osEvtMessageMask
		mouseMovedMessage
		suspendResumeMessage
		resumeFlag
		convertClipboardFlag
		activeFlag
		btnState
		cmdKey
		shiftKey
		alphaLock
		optionKey
		controlKey
		rightShiftKey
		rightOptionKey
		rightControlKey
	);
	
	@EXPORT_OK = qw(
		DispatchEvent
	
		$CurrentEvent
		@SavedEvents
		@Event
	);
}

=head2 Constants

=over 4

=item nullEvent

=item mouseDown

=item mouseUp

=item keyDown

=item keyUp

=item autoKey

=item updateEvt

=item diskEvt

=item activateEvt

=item osEvt

=item kHighLevelEvent

Event codes in the C<what> field of an event.

=cut
sub nullEvent ()                   {          0; }
sub mouseDown ()                   {          1; }
sub mouseUp ()                     {          2; }
sub keyDown ()                     {          3; }
sub keyUp ()                       {          4; }
sub autoKey ()                     {          5; }
sub updateEvt ()                   {          6; }
sub diskEvt ()                     {          7; }
sub activateEvt ()                 {          8; }
sub osEvt ()                       {         15; }
sub kHighLevelEvent ()             {         23; }


=item mDownMask

=item mUpMask

=item keyDownMask

=item keyUpMask

=item autoKeyMask

=item updateMask

=item diskMask

=item activMask

=item highLevelEventMask

=item osMask

=item everyEvent

Event masks to pass to C<WaitNextEvent>.

=cut
sub mDownMask ()                   {     0x0002; }
sub mUpMask ()                     {     0x0004; }
sub keyDownMask ()                 {     0x0008; }
sub keyUpMask ()                   {     0x0010; }
sub autoKeyMask ()                 {     0x0020; }
sub updateMask ()                  {     0x0040; }
sub diskMask ()                    {     0x0080; }
sub activMask ()                   {     0x0100; }
sub highLevelEventMask ()          {     0x0400; }
sub osMask ()                      {     0x8000; }
sub everyEvent ()                  {     0xFFFF; }


=item charCodeMask

=item keyCodeMask

=item adbAddrMask

=item osEvtMessageMask

=item mouseMovedMessage

=item suspendResumeMessage

=item resumeFlag

=item convertClipboardFlag

Subfields of the C<message> field of an event and their values.

=cut
sub charCodeMask ()                { 0x000000FF; }
sub keyCodeMask ()                 { 0x0000FF00; }
sub adbAddrMask ()                 { 0x00FF0000; }
sub osEvtMessageMask ()            { 0xFF000000; }
sub mouseMovedMessage ()           {     0x00FA; }
sub suspendResumeMessage ()        {     0x0001; }
sub resumeFlag ()                  {          1; }
sub convertClipboardFlag ()        {          2; }


=item activeFlag

=item btnState

=item cmdKey

=item shiftKey

=item alphaLock

=item optionKey

=item controlKey

=item rightShiftKey

=item rightOptionKey

=item rightControlKey

Flags in the C<modifier> field of an event.

=cut
sub activeFlag ()                  {     0x0001; }
sub btnState ()                    {     0x0080; }
sub cmdKey ()                      {     0x0100; }
sub shiftKey ()                    {     0x0200; }
sub alphaLock ()                   {     0x0400; }
sub optionKey ()                   {     0x0800; }
sub controlKey ()                  {     0x1000; }
sub rightShiftKey ()               {     0x2000; }
sub rightOptionKey ()              {     0x4000; }
sub rightControlKey ()             {     0x8000; }

=back

=cut

bootstrap Mac::Events;

=include Events.xs

=item DispatchEvent EVENT

Dispatch an event to its handler.

=back

=cut
sub DispatchEvent {
	push @SavedEvents, $CurrentEvent;
	$CurrentEvent = $_[0];
	my($handler) = $Event[$CurrentEvent->what];
	my($res) = $handler ? &$handler($CurrentEvent) : 0;
	$CurrentEvent = pop @SavedEvents;
	$res;
}


=head1 BUGS/LIMITATIONS

=head1 FILES

=head1 AUTHOR(S)

Matthias Ulrich Neeracher <neeri@iis.ee.ethz.ch> 

=cut

__END__
