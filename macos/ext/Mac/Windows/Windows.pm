=head1 NAME

Mac::Windows - Macintosh Toolbox Interface to Window Manager

=head1 SYNOPSIS

=head1 DESCRIPTION

Access to Inside Macintosh is essential for proper use of these functions.
Explanations of terms, processes and procedures are provided there.
Any attempt to use these functions without guidance can cause severe errors in 
your machine, including corruption of data. B<You have been warned.>

=cut
	
use strict;

package Mac::Windows;

BEGIN {
	use Exporter   ();
	use DynaLoader ();
	
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
	$VERSION = '1.00';
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		GetGrayRgn
		GetWMgrPort
		NewWindow
		GetNewWindow
		DisposeWindow
		GetWTitle
		SelectWindow
		HideWindow
		ShowWindow
		ShowHide
		HiliteWindow
		BringToFront
		SendBehind
		FrontWindow
		DrawGrowIcon
		MoveWindow
		SizeWindow
		ZoomWindow
		InvalRect
		InvalRgn
		ValidRect
		ValidRgn
		BeginUpdate
		EndUpdate
		SetWRefCon
		GetWRefCon
		SetWindowPic
		GetWindowPic
		GrowWindow
		FindWindow
		PinRect
		DragGrayRgn
		TrackBox
		GetCWMgrPort
		SetDeskCPat
		NewCWindow
		GetNewCWindow
		GetWVariant
		SetWTitle
		TrackGoAway
		DragWindow
		GetWindowKind
		SetWindowKind
		IsWindowVisible
		IsWindowHilited
		GetWindowGoAwayFlag
		GetWindowZoomFlag
		GetWindowStructureRgn
		GetWindowContentRgn
		GetWindowUpdateRgn
		GetWindowTitleWidth
		GetNextWindow
		GetWindowStandardState
		SetWindowStandardState
		GetWindowUserState
		SetWindowUserState
	
		kWindowDefProcType
		kStandardWindowDefinition
		kRoundWindowDefinition
		kFloatingWindowDefinition
		kModalDialogVariantCode
		kMovableModalDialogVariantCode
		kSideFloaterVariantCode
		documentProc
		dBoxProc
		plainDBox
		altDBoxProc
		noGrowDocProc
		movableDBoxProc
		zoomDocProc
		zoomNoGrow
		rDocProc
		floatProc
		floatGrowProc
		floatZoomProc
		floatZoomGrowProc
		floatSideProc
		floatSideGrowProc
		floatSideZoomProc
		floatSideZoomGrowProc
		kDialogWindowKind
		kApplicationWindowKind
		inDesk
		inMenuBar
		inSysWindow
		inContent
		inDrag
		inGrow
		inGoAway
		inZoomIn
		inZoomOut
		wDraw
		wHit
		wCalcRgns
		wNew
		wDispose
		wGrow
		wDrawGIcon
		deskPatID
		wNoHit
		wInContent
		wInDrag
		wInGrow
		wInGoAway
		wInZoomIn
		wInZoomOut
		wContentColor
		wFrameColor
		wTextColor
		wHiliteColor
		wTitleBarColor
	);
	
	@EXPORT_OK = qw(
		%Window
	);
}

=head2 Constants

=over 4

=item kWindowDefProcType

=item kStandardWindowDefinition

=item kRoundWindowDefinition

=item kFloatingWindowDefinition

=item kModalDialogVariantCode

=item kMovableModalDialogVariantCode

=item kSideFloaterVariantCode

=item documentProc

=item dBoxProc

=item plainDBox

=item altDBoxProc

=item noGrowDocProc

=item movableDBoxProc

=item zoomDocProc

=item zoomNoGrow

=item rDocProc

=item floatProc

=item floatGrowProc

=item floatZoomProc

=item floatZoomGrowProc

=item floatSideProc

=item floatSideGrowProc

=item floatSideZoomProc

=item floatSideZoomGrowProc

Window definition procedure IDs.

=cut
sub kWindowDefProcType ()          {     'WDEF'; }
sub kStandardWindowDefinition ()   {          0; }
sub kRoundWindowDefinition ()      {          1; }
sub kFloatingWindowDefinition ()   {        124; }
sub kModalDialogVariantCode ()     {          1; }
sub kMovableModalDialogVariantCode () {       5; }
sub kSideFloaterVariantCode ()     {          8; }
sub documentProc ()                {          0; }
sub dBoxProc ()                    {          1; }
sub plainDBox ()                   {          2; }
sub altDBoxProc ()                 {          3; }
sub noGrowDocProc ()               {          4; }
sub movableDBoxProc ()             {          5; }
sub zoomDocProc ()                 {          8; }
sub zoomNoGrow ()                  {         12; }
sub rDocProc ()                    {         16; }
sub floatProc ()                   {       1985; }
sub floatGrowProc ()               {       1987; }
sub floatZoomProc ()               {       1989; }
sub floatZoomGrowProc ()           {       1991; }
sub floatSideProc ()               {       1993; }
sub floatSideGrowProc ()           {       1995; }
sub floatSideZoomProc ()           {       1997; }
sub floatSideZoomGrowProc ()       {       1999; }


=item kDialogWindowKind

=item kApplicationWindowKind

Predefined window kinds.

=cut
sub kDialogWindowKind ()           {          2; }
sub kApplicationWindowKind ()      {          8; }


=item inDesk

=item inMenuBar

=item inSysWindow

=item inContent

=item inDrag

=item inGrow

=item inGoAway

=item inZoomIn

=item inZoomOut

Part codes for C<FindWindow>.

=cut
sub inDesk ()                      {          0; }
sub inMenuBar ()                   {          1; }
sub inSysWindow ()                 {          2; }
sub inContent ()                   {          3; }
sub inDrag ()                      {          4; }
sub inGrow ()                      {          5; }
sub inGoAway ()                    {          6; }
sub inZoomIn ()                    {          7; }
sub inZoomOut ()                   {          8; }


=item wDraw

=item wHit

=item wCalcRgns

=item wNew

=item wDispose

=item wGrow

=item wDrawGIcon

=item deskPatID

Part codes for the draw message to the window definition procedure.

=cut
sub wDraw ()                       {          0; }
sub wHit ()                        {          1; }
sub wCalcRgns ()                   {          2; }
sub wNew ()                        {          3; }
sub wDispose ()                    {          4; }
sub wGrow ()                       {          5; }
sub wDrawGIcon ()                  {          6; }
sub deskPatID ()                   {         16; }


=item wNoHit

=item wInContent

=item wInDrag

=item wInGrow

=item wInGoAway

=item wInZoomIn

=item wInZoomOut

Part codes for the hit message to the window definition procedure.

=cut
sub wNoHit ()                      {          0; }
sub wInContent ()                  {          1; }
sub wInDrag ()                     {          2; }
sub wInGrow ()                     {          3; }
sub wInGoAway ()                   {          4; }
sub wInZoomIn ()                   {          5; }
sub wInZoomOut ()                  {          6; }


=item wContentColor

=item wFrameColor

=item wTextColor

=item wHiliteColor

=item wTitleBarColor

Colors in window color record.

=cut
sub wContentColor ()               {          0; }
sub wFrameColor ()                 {          1; }
sub wTextColor ()                  {          2; }
sub wHiliteColor ()                {          3; }
sub wTitleBarColor ()              {          4; }

=back

=cut

bootstrap Mac::Windows;

=include Windows.xs

=head2 MacWindow - The Object Interface

Correctly handling a Mac window requires quite a bit of event management. The
C<MacWindow> class relieves you of most of these duties. Most of the events
received are dispatched to a set of panes as defined in C<Mac::Pane>.

=over 4

=cut
package MacWindow;

BEGIN {
	use Carp;
	use Mac::Hooks ();
	use Mac::Events;
	use Mac::Events qw($CurrentEvent @Event);
	use Mac::QuickDraw qw(SetPort GlobalToLocal GetClip ClipRect SetClip EraseRect SetCursor);
	import Mac::Windows;
	import Mac::Windows qw(%Window);

	use vars qw(@ISA);
	
	@ISA = qw(Mac::Hooks);
}

=head2 Creating and Destructing MacWindow objects

=item new MacWindow PORT

=item new MacWindow ID [, BEHIND]

=item new MacWindow BOUNDS, TITLE, VISIBLE, PROC, GOAWAY [, REFCON [, BEHIND]]

Register a new window. In the first form, registers an existing window. In the
second form, calls C<GetNewWindow>. In the third form, calls C<NewWindow>.

=cut
sub new {
	my($class) = shift @_;
	my($type) = @_;
	my($port);
	
	if (ref($type) eq "Rect") {
		$port = NewWindow(@_) or croak "NewWindow failed";
	} elsif (!ref($type)) {
		$port = GetNewWindow(@_) or croak "GetNewWindow failed";
	} else {
		$port = $type;
	}
	my(%vars) = 
		(port => $port, panes => [], focusable => [], focus => 0, 
		 idlealways => [], idlefront => [], tabbing => 1);
	$Window{$$port} = bless \%vars, $class;
}

=item dispose 

Unregisters and disposes the window.

=cut
sub dispose {
	my($self) = @_;
	return unless $self->{port};
	
	for my $pane (@{$self->{panes}}) { 
		$pane->detach($self); 
	};
	defined($_[0]->callhook("dispose", @_)) and return;
	delete $Window{${$self->{port}}};
	DisposeWindow($self->{port});
	$self->{port} = "";
}

sub DESTROY {
	my($my) = @_;
	$my->dispose;
}

=back 

=head2 Accessing Components

=over 4

=item window

Returns the underlying toolbox C<GrafPtr>.

=cut
sub window {
	my($my) = @_;
	
	$my->{port};
}

=item add_pane PANE

Adds a pane to the window.

=cut
sub add_pane {
	my($self, $pane) = @_;
	
	unshift @{$self->{panes}}, $pane;
	
	$pane->attach($self);
}

=item remove_pane PANE

Removes the pane.

=cut
sub remove_pane {
	my($self, $pane) = @_;
	
	$self->remove_focusable($pane);
	$self->remove_idle($pane);
	
	my $panes = $self->{panes};
	
	$pane->detach($self);
	
	@$panes = grep { $_ != $pane } @$panes;
}

=item add_idle PANE [, FRONT=0]

Indicates that the pane needs to get regular time slices. If FRONT is set, the
pane only needs time if its window is active.

=cut
sub add_idle {
	my($self, $pane, $front) = @_;
	my $idle = $front ? $self->{idlefront} : $self->{idlealways};

	push @$idle, $pane;
}

=item remove_idle PANE

Indicates that the pane no longer needs idle time.

=cut
sub remove_idle {
	my($self, $pane) = @_;

	my $idle = $self->{idlealways};
	@$idle = grep { $_ != $pane } @$idle;

	$idle = $self->{idlefront};
	@$idle = grep { $_ != $pane } @$idle;	
}

=item add_focusable PANE

Indicates that a pane can get the focus.

=cut
sub add_focusable {
	my($self, $pane) = @_;
	my $focusable = $self->{focusable};
	
	push @$focusable, $pane;
	
	$pane->focus($self, 1) if scalar(@$focusable) == 1;
}

=item remove_focusable PANE

Indicates that no instance of this pane can get the focus.

=cut
sub remove_focusable {
	my($self, $pane) = @_;
	my $focusable = $self->{focusable};
	
	return unless scalar(@$focusable);
	
	my $focus     = ${$focusable}[$self->{focus}];
	my $focused   = $focus == $pane;
	
	$pane->focus($self, 0) if $focused;
	
	@$focusable = grep { $_ != $pane } @$focusable;
	
	if (my $focus_count = scalar(@$focusable)) {
		if ($focused) {
			$self->{focus} %= $focus_count;
			${$focusable}[$self->{focus}]->focus($self, 1);
		} else {
			if ($self->{focus} >= scalar(@$focusable) 
			 || ${$focusable}[$self->{focus}] != $focus
			) {
				--$self->{focus};
			}
		}
	} else {
		$self->{focus} = 0;
	}
}

=item has_focus PANE

Returns whether PANE currently is focused.

=cut
sub has_focus {
	my($my, $pane) = @_;

	defined ${$my->{focusable}}[$my->{focus}] or return;
	return ${$my->{focusable}}[$my->{focus}] == $pane
		if $my->{focus} && $my->{focusable} &&
		defined ${$my->{focusable}}[$my->{focus}];
}

=item can_focus 

Returns whether there are at least 2 focusable panes.

=cut
sub can_focus {
	my($my) = @_;
	
	return scalar(@{$my->{focusable}}) > 1;
}

=item advance_focus [STEP]

=item advance_focus PANE

Advance the focus by STEP or to PANE.

=cut
sub advance_focus {
	my($my,$step) = @_;
	$step ||= 1;
	my $focusable = $my->{focusable};
	my $max = scalar(@$focusable);
	return if $max < 2;
	my $focus = $my->{focus};
	my $newfocus;
	if (ref($step)) {
		for ($newfocus=0; $newfocus<$max; ++$newfocus) {
			goto switchfocus if $focusable->[$newfocus] == $step;
		}
		return;
	} else {
		$newfocus = ($focus+$max+$step) % $max;
	}
switchfocus:
	return if $newfocus == $focus;
	$my->{focus} = $newfocus;
	$focusable->[$focus]->focus($my, 0);
	$focusable->[$newfocus]->focus($my, 1);
}

=back

=head2 Event Handling

=over 4

=item activate ACTIVE, SUSPEND

Handle activation of the window, which is already set to the current port.
By default doesn't do anything but update the focus. Override as necessary.

The parameters distinguish the four cases:

   Event      ACTIVE  SUSPEND
   
   Activate      1       0
   Deactivate    0       0
   Suspend       0       1
   Resume        1       1

=cut
sub activate {
	my($self, $active, $suspend) = @_;

	for my $pane (@{$self->{panes}}) { 
		$pane->activate($self, $active, $suspend); 
	};

	defined($self->callhook("activate", @_)) and return;

	my $focus = $self->{focusable}[$self->{focus}];
	
	$focus->focus($self, $active) if $focus;
	
	1;
}

=item update 

Handle update events. The default action is to call the redraw function, wrapped
within BeginUpdate/EndUpdate, which is usually the correct thing to do.

=cut
sub update {
	defined($_[0]->callhook("update", @_)) and return;
	my($my) = @_;
	my($port) = $my->{port};
	BeginUpdate($port);
	EraseRect($port->portRect);
	$my->drawgrowicon;
	$my->redraw;
	EndUpdate($port);
	1;
}

=item drawgrowicon

Draw the grow icon, by default for a window without scroll bars. Override as
convenient.

=cut
sub drawgrowicon {
	defined($_[0]->callhook("drawgrowicon", @_)) and return;
	my($my) = @_;
	my($port) = $my->{port};
	my($clip) = GetClip();
	my($rect) = $port->portRect;
	$rect->left($rect->right-15);
	$rect->top($rect->bottom-15);
	ClipRect($rect);
	DrawGrowIcon($port);
	SetClip($clip);
}

=item redraw

Redraw the contents of the window. Override as you'd like, but consider calling
the parent procedure, too.

=cut
sub redraw {
	my($self) = @_;
	for my $pane (reverse @{$self->{panes}}) { 
		$pane->redraw($self); 
	};
	defined($self->callhook("redraw", @_)) and return;
}

=item key KEY

Handle a keypress and return 1 if the key was handled.

=cut
sub key {
	my($self, $key) = @_;
	my($handled);
	defined($handled = $self->callhook("key", @_)) and return $handled;
	my $focusable = $self->{focusable};
	
	if ($key == 9 && $self->can_focus) {
		$self->advance_focus(
			$CurrentEvent->modifiers & shiftKey ? -1 : 1);
		return 1;
	}

	my $focus = $focusable->[$self->{focus}];
	
	return $focus ? $focus->key($self, $key) : 0;
}

=item click PT

Handle a mouse click and return 1 if the click was handled.

=cut
sub click {
	my($self, $pt) = @_;
	for my $pane (@{$self->{panes}}) { 
		if ($pane->click($self, $pt)) {
			$self->advance_focus($pane);
			return 1; 
		}
	};
	my($handled);
	defined($handled = $self->callhook("click", @_)) and return 1;
	
	1;
}

=item drag PT

Handle a drag and return 1 if it was handled. Normally doesn't need an
override.

=cut
sub drag {
	my($handled);
	defined($handled = $_[0]->callhook("drag", @_)) and return $handled;
	my($my, $pt) = @_;
	
	DragWindow($my->{port}, $pt);
	
	1;
}

=item grow PT

Handle a drag and return 1 if it was handled. Normally doesn't need an
override.

=cut
sub grow {
	my($handled);
	defined($handled = $_[0]->callhook("grow", @_)) and return $handled;
	my($my,$pt) = @_;
	
	if (my($w,$h) = GrowWindow($my->{port}, $pt)) {
		$my->invalgrowarea;
		SizeWindow($my->{port}, $w, $h);
		$my->invalgrowarea;
		$my->layout;
	}
	
	1;
}

=item invalgrowarea

Invalidate area potentially affected by a size change (grow icon & such).

=cut
sub invalgrowarea {
	defined($_[0]->callhook("invalgrowarea", @_)) and return;
	my($my) = @_;
	my($port) = $my->{port};
	my($rect) = $port->portRect;
	$rect->left($rect->right-15);
	$rect->top($rect->bottom-15);
	InvalRect($rect);
}

=item layout

After a grow, recalculate element positions.

=cut
sub layout {
	defined($_[0]->callhook("layout", @_)) and return;
}

=item goaway PT

Handle a click in the close box and return 1 if it was handled. Normally doesn't 
need an override.

=cut
sub goaway {
	my($handled);
	defined($handled = $_[0]->callhook("goaway", @_)) and return $handled;
	my($my,$pt) = @_;
	
	TrackGoAway($my->{port}, $pt) and $my->dispose;
	
	1;
}

=item zoom PT, PART

Handle a click in the zoom box and return 1 if it was handled. Normally doesn't 
need an override.

=cut
sub zoom {
	my($handled);
	defined($handled = $_[0]->callhook("zoom", @_)) and return $handled;
	my($my,$pt,$part) = @_;
	
	if (TrackBox($my->{port}, $pt, $part)) {
		$my->invalgrowarea;
		ZoomWindow($my->{port}, $part, 1);
		$my->invalgrowarea;
		$my->layout;
	}
	
	1;
}

=item cursor PT

Set the correct cursor for the local point. Defaults to arrow.

=cut
sub cursor {
	my($self, $pt) = @_;
	for my $pane (@{$self->{panes}}) { 
		$pane->cursor($self, $pt) and return; 
	};
	my($handled);
	defined($handled = $_[0]->callhook("cursor", @_)) and return $handled;
	SetCursor();
}

=item idle

Perform regular activities.

=cut
sub idle {
	my($self) = @_;
	return unless $self->{port};
	my($front) = FrontWindow();
	if ($front && ${$self->{port}} == $$front) {
		for my $pane (@{$self->{idlefront}}) { 
			$pane->idle($self); 
		}
	}
	for my $pane (@{$self->{idlealways}}) { 
		$pane->idle($self); 
	}
	$self->callhook("idle", @_);
}

=back

=head2 MacColorWindow 

A C<MacColorWindow> is a C<MacWindow> with a color C<GrafPort>.
=over 4

=cut
package MacColorWindow;

BEGIN {
	use Carp;
	
	import Mac::Windows;
}

=item new MacColorWindow PORT

=item new MacColorWindow ID [, BEHIND]

=item new MacColorWindow BOUNDS, TITLE, VISIBLE, PROC, GOAWAY [, REFCON [, BEHIND]]

Register a new window. In the first form, registers an existing window. In the
second form, calls C<GetNewCWindow>. In the third form, calls C<NewCWindow>.

=cut
sub new {
	my($class) = shift @_;
	my($type) = @_;
	my($port);
	
	if (ref($type) eq "Rect") {
		$port = NewCWindow(@_) or croak "NewCWindow failed";
	} elsif (!ref($type)) {
		$port = GetNewCWindow(@_) or croak "GetNewCWindow failed";
	} else {
		$port = $type;
	}
	
	new MacWindow $port;
}

package MacWindow;

#
# Event handlers
#
sub _MouseDown {
	my($ev) = @_;
	my($code,$win) = FindWindow($ev->where);
	return 0 unless $win;
	my($w) = $Window{$$win};
	return 0 unless $w;
 	if ($$win != ${FrontWindow()} && $code != inDrag) {
		SelectWindow($win);
		return 1;
 	}
	SetPort($win);
	if ($code == inContent) {
		$w->click(GlobalToLocal($ev->where));
	} elsif ($code == inDrag) {
		$w->drag($ev->where);
	} elsif ($code == inGrow) {
		$w->grow($ev->where);
	} elsif ($code == inGoAway) {
		$w->goaway($ev->where);
	} elsif ($code == inZoomIn || $code == inZoomOut) {
		$w->zoom($ev->where, $code);
	} else {
		0;
	}
}
$Event[mouseDown] = \&_MouseDown;

sub _Activate {
	my($ev) = @_;
	my($win) = $ev->window;
	my($w) = $Window{$$win};
	return 0 unless $w;
	SetPort($win);
	$w->activate($ev->modifiers & activeFlag, 0);
}

sub _Idle {
	my($ev) = @_;
	
	for my $w (values %Window) {
		$w->idle;
	}
	
	my($code,$win) = FindWindow($ev->where);
 	if (!$win || $$win != ${FrontWindow()} || $code != inContent) {
		SetCursor();
		return 1;
	}
	my($w) = $Window{$$win};
	return 0 unless $w;
	SetPort($win);
	$w->cursor(GlobalToLocal($ev->where));
}
$Event[nullEvent] = \&_Idle;

sub _OSEvent {
	my($ev) = @_;
	return _Idle($ev) if $ev->osMessage == mouseMovedMessage;
	return 0 unless $ev->osMessage == suspendResumeMessage;
	my($win) = FrontWindow();
	return 0 unless $win;
	my($w) = $Window{$$win};
	return 0 unless $w;
	SetPort($win);
	$w->activate($ev->message & activeFlag, 1);
}
$Event[activateEvt] = \&_Activate;
$Event[osEvt] = \&_OSEvent;

sub _Update {
	my($ev) = @_;
	my($win) = $ev->window;
	my($w) = $Window{$$win};
	return 0 unless $w;
	SetPort($win);
	$w->update;
}
$Event[updateEvt] = \&_Update;

sub _KeyPress {
	my($ev) = @_;
	my($win) = FrontWindow();
	return 0 unless $win;
	my($w) = $Window{$$win};
	return 0 unless $w;
	SetPort($win);
	$w->key($ev->character);
}
$Event[keyDown] = \&_KeyPress;
$Event[autoKey] = \&_KeyPress;

=head1 BUGS/LIMITATIONS

=head1 FILES

=head1 AUTHOR(S)

Matthias Ulrich Neeracher <neeri@iis.ee.ethz.ch> 

=cut

__END__
