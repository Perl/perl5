=head1 NAME

Mac::TextEdit - Macintosh Toolbox Interface to TextEdit

=head1 SYNOPSIS


=head1 DESCRIPTION

Access to Inside Macintosh is essential for proper use of these functions.
Explanations of terms, processes and procedures are provided there.
Any attempt to use these functions without guidance can cause severe errors in 
your machine, including corruption of data. B<You have been warned.>

=cut

use strict;

package Mac::TextEdit;

BEGIN {
	use Exporter   ();
	use DynaLoader ();
	
	use vars qw($VERSION @ISA @EXPORT);
	$VERSION = '1.00';
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		TEScrapHandle
		TEGetScrapLength
		TENew
		TEDispose
		TESetText
		TEGetText
		TEIdle
		TESetSelect
		TEActivate
		TEDeactivate
		TEKey
		TECut
		TECopy
		TEPaste
		TEDelete
		TEInsert
		TESetAlignment
		TEUpdate
		TETextBox
		TEScroll
		TESelView
		TEPinScroll
		TEAutoView
		TECalText
		TEGetOffset
		TEGetPoint
		TEClick
		TEStyleNew
		TESetStyleHandle
		TEGetStyleHandle
		TEGetStyle
		TEStylePaste
		TESetStyle
		TEReplaceStyle
		TEGetStyleScrapHandle
		TEStyleInsert
		TEGetHeight
		TEContinuousStyle
		TEUseStyleScrap
		TENumStyles
		TEFeatureFlag
		TESetScrapLength
		TEFromScrap
		TEToScrap

		teFlushDefault
		teCenter
		teFlushRight
		teFlushLeft
		doFont
		doFace
		doSize
		doColor
		doAll
		addSize
		doToggle
		teFAutoScroll
		teFTextBuffering
		teFOutlineHilite
		teFInlineInput
		teFUseInlineInput
		teFInlineInputAutoScroll
		teBitClear
		teBitSet
		teBitTest
		teWordSelect
		teWordDrag
		teFromFind
		teFromRecal
		teFind
		teHighlight
		teDraw
		teCaret
		teFUseTextServices
	);
}

bootstrap Mac::TextEdit;

=head2 Constants

=over 4

=item teFlushDefault

=item teCenter

=item teFlushRight

=item teFlushLeft

Text alignment constants.

=cut
sub teFlushDefault ()              {          0; }
sub teCenter ()                    {          1; }
sub teFlushRight ()                {         -1; }
sub teFlushLeft ()                 {         -2; }

=item doFont

=item doFace

=item doSize

=item doColor

=item doAll

=item addSize

=item doToggle

Constants for C<TEContinuousStyle>.

=cut
sub doFont ()                      {          1; }
sub doFace ()                      {          2; }
sub doSize ()                      {          4; }
sub doColor ()                     {          8; }
sub doAll ()                       {         15; }
sub addSize ()                     {         16; }
sub doToggle ()                    {         32; }

=item teFAutoScroll

=item teFTextBuffering

=item teFOutlineHilite

=item teFInlineInput

=item teFUseTextServices

=item teFUseInlineInput

=item teFInlineInputAutoScroll

=item teBitClear

=item teBitSet

=item teBitTest

Features.

=cut
sub teFAutoScroll ()               {          0; }
sub teFTextBuffering ()            {          1; }
sub teFOutlineHilite ()            {          2; }
sub teFInlineInput ()              {          3; }
sub teFUseTextServices ()          {          4; }
sub teFUseInlineInput ()           {          5; }
sub teFInlineInputAutoScroll ()    {          6; }
sub teBitClear ()                  {          0; }
sub teBitSet ()                    {          1; }
sub teBitTest ()                   {         -1; }

sub teWordSelect ()                {          4; }
sub teWordDrag ()                  {          8; }
sub teFromFind ()                  {         12; }
sub teFromRecal ()                 {         16; }
sub teFind ()                      {          0; }
sub teHighlight ()                 {          1; }
sub teDraw ()                      {         -1; }
sub teCaret ()                     {         -2; }

=include TextEdit.xs

=head2 Extension to MacWindow

=over 4

=cut
package MacWindow;

BEGIN {
	use Carp;
	use Mac::QuickDraw qw(SetPort);
	import Mac::TextEdit;
}

=item new_textedit [CLASS, ] HTE

=item new_textedit [CLASS, ] DESTRECT, VIEWRECT

Create a new text editing field, attach it to the window, and return it. In the 
first form,  registers an existing text editing field. In the second form, calls  
C<TENew>.

=cut
sub new_textedit {
	my($my) = shift @_;
	my($type) = @_;
	my($class,$edit);

	if (ref($type)) {
		$class = "MacTextEdit"
	} else {
		$class = shift @_;
		$type  = $_[0];
	}
	if (ref($type) eq "TEHandle") {
		$edit = $type;
	} else {
		SetPort($my->{port});
		$edit = TENew(@_) or croak "TENew failed";
	} 
	$class->new($my, $edit);
}

=item new_textedit_style [CLASS, ] DESTRECT, VIEWRECT

Create a new styled text editing field, attach it to the window, and return it.

=cut
sub new_textedit_style {
	my($my) = shift @_;
	my($type) = @_;
	my($class,$edit);

	if (ref($type)) {
		$class = "MacTextEdit"
	} else {
		$class = shift @_;
		$type  = $_[0];
	}
	if (ref($type) eq "TEHandle") {
		$edit = $type;
	} else {
		SetPort($my->{port});
		$edit = TEStyleNew(@_) or croak "TEStyleNew failed";
	} 
	$class->new($my, $edit);
}

=back

=head2 MacTextEdit - The object interface to a text editing field

MacTextEdit is a TextEdit field embedded into a pane.

=cut
package MacTextEdit;

BEGIN {
	use Mac::Hooks ();
	use Mac::QuickDraw;
	use Mac::Pane;
	use Mac::Events;
	use Mac::Windows();
	import Mac::TextEdit;

	use vars qw(@ISA);
	
	@ISA = qw(Mac::Pane Mac::Hooks);
}

=item new WINDOW, CONTROL

Initialize a C<MacTextEdit> (which is always created with 
C<MacWindow::new_textedit>).

=cut
sub new {
	my($class, $window, $edit) = @_;

	my(%vars) = (window => $window, edit => $edit);
	
	my $me = bless \%vars, $class;
	
	$window->add_pane($me);
	$window->add_focusable($me);
	$window->add_idle($me, 1);
	
	$me;
}

=item dispose

Dispose of the toolbox edit.

=cut
sub dispose {
	my($my) = @_;
	TEDispose($my->{edit}) if $my->{edit};
	delete $my->{edit};
}

=item DESTROY

Destroys the C<MacList>.

=cut
sub DESTROY {
	dispose(@_);
}

=item edit

Get the toolbox TextEdit handle.

=cut
sub edit {
	my($my) = @_;
	
	$my->{edit};
}

=item attach(WINDOW)

Called by MacWindow to indicate that the pane has just been attached.

=cut
sub attach {
	my($my, $window) = @_;
	
	$window->{edits}->{${$my->{edit}}} = $my;
}

=item detach(WINDOW)

Called by MacWindow to indicate that the pane has just been detached.

=cut
sub detach {
	my($my, $window) = @_;
	
	delete $window->{edits}->{${$my->{edit}}};
	dispose(@_);
}

=item focus(WINDOW, FOCUS)

Called by MacWindow to indicate that the edit has acquired (1) or lost (0) the 
focus.

=cut
sub focus {
	my($my, $window, $focus) = @_;
	my $edit = $my->{edit};
	
	if ($focus) {
		TEActivate($edit);
	} else {
		TEDeactivate($edit);
	}
	
	$my->callhook("focus", @_) and return;
}

=item redraw(WINDOW)

Redraw the contents of the pane.

=cut
sub redraw {
	my($my, $window) = @_;
	my $edit = $my->{edit};
	
	TEUpdate($window->window->visRgn->rgnBBox, $edit);

	my $r    = InsetRect $edit->viewRect, -1, -1;
	FrameRect($r);
}

=item key(WINDOW, KEY)

Handle a key stroke. 

=cut
sub key {
	my($my, $window, $key) = @_;
	
	$my->callhook("key", @_) and return;
	
	my $edit = $my->{edit};
	
	TEKey(chr($key), $edit);
}

=item click(WINDOW, PT)

Handle a click.

=cut
sub click {
	my($my, $window, $pt) = @_;
	my($res);
	
	($res = $my->callhook("click", @_)) and return $res;

	my $edit = $my->{edit};
	my $extend = ($Mac::Events::CurrentEvent->modifiers & shiftKey) != 0;
	
	if (TEClick($pt, $extend, $edit)) {
		$my->hit($window);
	}
	return PtInRect($pt, $edit->viewRect);
}

=item hit(WINDOW)

Handle a double click.

=cut
sub hit {
	defined($_[0]->callhook("hit", @_)) and return;
}

=item idle 

Handle idle events. 

=cut
sub idle {
	my($my) = @_;
	TEIdle($my->{edit});
}

=head1 BUGS/LIMITATIONS

=head1 FILES

=head1 AUTHOR(S)

Matthias Ulrich Neeracher <neeri@iis.ee.ethz.ch> 

=cut

1;

__END__
