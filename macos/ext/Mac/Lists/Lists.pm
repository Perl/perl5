=head1 NAME

Mac::Lists - Macintosh Toolbox Interface to List Manager

=head1 SYNOPSIS


=head1 DESCRIPTION

Access to Inside Macintosh is essential for proper use of these functions.
Explanations of terms, processes and procedures are provided there.
Any attempt to use these functions without guidance can cause severe errors in 
your machine, including corruption of data. B<You have been warned.>

=cut
	
use strict;

package Mac::Lists;

BEGIN {
	use Exporter   ();
	use DynaLoader ();
	
	use vars qw($VERSION @ISA @EXPORT);
	$VERSION = '1.00';
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		LNew
		LDispose
		LAddColumn
		LAddRow
		LDelColumn
		LDelRow
		LGetSelect
		LLastClick
		LNextCell
		LSize
		LSetDrawingMode
		LScroll
		LAutoScroll
		LUpdate
		LActivate
		LCellSize
		LClick
		LAddToCell
		LClrCell
		LGetCell
		LRect
		LSetCell
		LSetSelect
		LDraw
		
		lDoVAutoscroll
		lDoHAutoscroll
		lOnlyOne
		lExtendDrag
		lNoDisjoint
		lNoExtend
		lNoRect
		lUseSense
		lNoNilHilite
		lInitMsg
		lDrawMsg
		lHiliteMsg
		lCloseMsg
	);
}

=head2 Constants

=over 4

=item lDoVAutoscroll

=item lDoHAutoscroll

Flags for C<listFlags>.

=cut
sub lDoVAutoscroll ()              {          2; }
sub lDoHAutoscroll ()              {          1; }


=item lOnlyOne

=item lExtendDrag

=item lNoDisjoint

=item lNoExtend

=item lNoRect

=item lUseSense

=item lNoNilHilite

Flags for C<selFlags>.

=cut
sub lOnlyOne ()                    {       -128; }
sub lExtendDrag ()                 {         64; }
sub lNoDisjoint ()                 {         32; }
sub lNoExtend ()                   {         16; }
sub lNoRect ()                     {          8; }
sub lUseSense ()                   {          4; }
sub lNoNilHilite ()                {          2; }


=item lInitMsg

=item lDrawMsg

=item lHiliteMsg

=item lCloseMsg

=cut
sub lInitMsg ()                    {          0; }
sub lDrawMsg ()                    {          1; }
sub lHiliteMsg ()                  {          2; }
sub lCloseMsg ()                   {          3; }

=back

=cut

bootstrap Mac::Lists;

=include Lists.xs

=head2 Extension to MacWindow

=over 4

=cut
package MacWindow;

BEGIN {
	use Carp;
	import Mac::Lists;
}

=item new_list [CLASS, ] LIST

=item new_list [CLASS, ] rView, dataBounds, cSize, theProc, [, drawIt [, hasGrow [, scrollHoriz [, scrollVert]]]]

Create a new list, attach it to the window, and return it. In the first form, 
registers an existing list. In the second form, calls  C<LNew>.

=cut
sub new_list {
	my($my) = shift @_;
	my($type) = @_;
	my($class,$list);

	if (ref($type)) {
		$class = "MacList"
	} else {
		$class = shift @_;
		$type  = $_[0];
	}
	if (ref($type) eq "ListHandle") {
		$list = $type;
	} else {
		my @pre_ = splice(@_, 0, 4);
		$list 	 = LNew(@pre_, $my->{port}, @_) or croak "LNew failed";
	} 
	$class->new($my, $list);
}

=back

=head2 MacList - The object interface to a list

MacList is a List Manager list embedded into a pane.

=cut
package MacList;

BEGIN {
	use Mac::Hooks ();
	use Mac::QuickDraw;
	use Mac::Pane;
	use Mac::Events;
	use Mac::Windows();
	import Mac::Lists;

	use vars qw(@ISA);
	
	@ISA = qw(Mac::Pane Mac::Hooks);
}

=item new WINDOW, CONTROL

Initialize a C<MacList> (which is always created with 
C<MacWindow::new_list>).

=cut
sub new {
	my($class, $window, $list) = @_;

	my(%vars) = (window => $window, list => $list);
	
	my $me = bless \%vars, $class;
	
	$window->add_pane($me);
	$window->add_focusable($me);
	
	$me;
}

=item dispose

Dispose of the toolbox list.

=cut
sub dispose {
	my($my) = @_;
	LDispose($my->{'list'}) if $my->{'list'};
	delete $my->{'list'};
}

=item DESTROY

Destroys the C<MacList>.

=cut
sub DESTROY {
	dispose(@_);
}

=item list

Get the toolbox list handle.

=cut
sub list {
	my($my) = @_;
	
	$my->{'list'};
}

=item attach(WINDOW)

Called by MacWindow to indicate that the pane has just been attached.

=cut
sub attach {
	my($my, $window) = @_;
	
	$window->{lists}->{${$my->{'list'}}} = $my;
}

=item detach(WINDOW)

Called by MacWindow to indicate that the pane has just been detached.

=cut
sub detach {
	my($my, $window) = @_;
	
	delete $window->{lists}->{${$my->{'list'}}};
	dispose(@_);
}

=item focus(WINDOW, FOCUS)

Called by MacWindow to indicate that the list has acquired (1) or lost (0) the 
focus.

=cut
sub focus {
	my($my, $window, $focus) = @_;
	my $list = $my->{'list'};
	
	LActivate($focus, $list);

	$my->callhook("focus", @_) and return;

	return unless scalar(@{$window->{focusable}}) > 1;
	
	my $pen  = GetPenState;
	my $r    = InsetRect $list->bounds, -4, -4;	
	PenSize(2,2);
	PenMode($focus ? patOr : patBic);
	FrameRect($r);
	SetPenState($pen);
}

=item redraw(WINDOW)

Redraw the contents of the pane.

=cut
sub redraw {
	my($my, $window) = @_;
	my $list = $my->{'list'};
	
	LUpdate($window->window->visRgn, $list);

	my $r    = InsetRect $list->bounds, -1, -1;
	FrameRect($r);

	$my->callhook("redraw", @_) && return;
	
	return unless $window->has_focus($my) && $window->can_focus;
	
	my $pen  = GetPenState;
	$r    = InsetRect $list->bounds, -4, -4;

	PenSize(2,2);
	FrameRect($r);
	SetPenState($pen);
}

sub _doselection {
	my($list,$clear) = @_;
	
	my $sel = LGetSelect(1, new Point(0,0), $list);
	
	return 
		($list->dataBounds->botRight, new Point(-1,-1)) 
			unless $sel;

	LSetSelect(0, $sel, $list) if $clear;
	
	my($first,$last) = ($sel, $sel);

	while ($sel = LNextCell(1, 1, $sel, $list)) {
		last unless $sel = LGetSelect(1, $sel, $list);
		LSetSelect(0, $sel, $list) if $clear;
		$last = $sel;
	}
	
	return ($first, $last);
}

sub _selectionrect {
	my($list, $start) = @_;
	my($sel) = new Rect($start->h, $start->v, $start->h, $start->v);
	if (!LGetSelect(0, $start, $list)) {
		return $sel;
	}
	my($cell,$h,$v);
	for ($v = $start->v; $v-- > 0; ) {
		last unless LGetSelect(0, new Point($start->h, $v), $list);
	}
	$sel->top($v+1);
	$v = $start->v+1;
	for ($cell = $start; $cell = LNextCell(0, 1, $cell, $list); ) {
		last unless LGetSelect(0, $cell, $list);
		++$v;
	}
	$sel->bottom($v);
LEFT:
	for ($h = $start->h; $h-- > 0; ) {
		for ($v = $sel->top; $v < $sel->bottom; ++$v) {
			last LEFT unless LGetSelect(0, new Point($h, $v), $list);
		}
	}
	$sel->left($h+1);
RIGHT:
	$h = $start->h+1;
	for ($cell = $start; $cell = LNextCell(1, 0, $cell, $list); ) {
		for ($v = $sel->top; $v < $sel->bottom; ++$v) {
			last RIGHT unless LGetSelect(0, new Point($h, $v), $list);
		}
		++$h
	}
	$sel->right($h);
	
	return $sel;
}

sub _selectrect {
	my($list, $r, $select) = @_;
	for my $h ($r->left..$r->right-1) {
		for my $v ($r->top..$r->bottom-1) {
			LSetSelect($select, new Point($h, $v), $list);
		}
	}
}

=item key(WINDOW, KEY)

Handle a key stroke.

=cut
sub key {
	my($my, $window, $key) = @_;
	my $list = $my->{'list'};
	
	$my->callhook("key", @_) and return;
	
	my($h,$v) = (0,0);
	if ($key == 28) { 		# Left arrow
		$h = -1;
	} elsif ($key == 29) { 	# Right arrow
		$h = 1;
	} elsif ($key == 30) { 	# Up arrow
		$v = -1;
	} elsif ($key == 31) { 	# Down arrow
		$v = 1;
	} else {
		return 0;
	} 
	my $extend = 
		($Mac::Events::CurrentEvent->modifiers & shiftKey) 
	 && !($list->selFlags & lNoExtend);
	my $extreme = $Mac::Events::CurrentEvent->modifiers & cmdKey;
	my ($first,$last) = _doselection($list, !$extend);
	if (!$extend || !$my->{anchoring}) {
		my $mul = $extreme ? 16380 : 1;
		my $sel = ($h < 0 || $v < 0) ? $first : $last;
		$last->h($sel->h + $mul*$h);
		$last->v($sel->v + $mul*$v);
		$last = Mac::Windows::PinRect($list->dataBounds, $last);
		if ($extend) {
			_selectrect(
				$list, 
				($h>0 || $v>0) 
				  ? new Rect($sel->h, $sel->v, $last->h+1, $last->v+1)
				  : new Rect($last->h, $last->v, $sel->h+1, $sel->v+1),
				1);
		} else {
			LSetSelect(1, $last, $list);
		}
	}
}

=item click(WINDOW, PT)

Handle a click.

=cut
sub click {
	my($my, $window, $pt) = @_;
	my($res);
	
	($res = $my->callhook("click", @_)) and return $res;
	
	if (LClick($pt, $Mac::Events::CurrentEvent->modifiers, $my->{'list'})) {
		$my->hit($window);
	}
	return PtInRect($pt, $my->{'list'}->bounds);
}

=item hit(WINDOW)

Handle a double click.

=cut
sub hit {
	defined($_[0]->callhook("hit", @_)) and return;
}

=item get H, V

=item get PT

Get the list data for a cell.

=cut
sub get {
	my($my)	  = shift @_;
	my($cell) = ref($_[0]) ? shift @_ : new Point(splice(@_, 0, 2));
	LGetCell($cell, $my->{'list'});
}

=item set H, V, DATA

=item set PT, DATA

Set the list data for a cell.

=cut
sub set {
	my($my)   = shift @_;
	my($cell) = ref($_[0]) ? shift @_ : new Point(splice(@_, 0, 2));
	my($data) = @_;
	
	LSetCell($data, $cell, $my->{'list'});
}

=head1 BUGS/LIMITATIONS

=head1 FILES

=head1 AUTHOR(S)

Matthias Ulrich Neeracher <neeracher@mac.com> 

=cut

1;

__END__
