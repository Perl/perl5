=head1 NAME

Mac::.Controls - Macintosh Toolbox Interface to Control Manager

=head1 SYNOPSIS


=head1 DESCRIPTION

Access to Inside Macintosh is essential for proper use of these functions.
Explanations of terms, processes and procedures are provided there.
Any attempt to use these functions without guidance can cause severe errors in 
your machine, including corruption of data. B<You have been warned.>

=cut

use strict;

package Mac::Controls;

BEGIN {
	use Exporter   ();
	use DynaLoader ();
	
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $gControlManager);
	$VERSION = '1.00';
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		NewControl
		GetNewControl
		DisposeControl
		KillControls
		ShowControl
		HideControl
		DrawControls
		Draw1Control
		UpdateControls
		HiliteControl
		TrackControl
		DragControl
		TestControl
		FindControl
		MoveControl
		SizeControl
		SetControlTitle
		GetControlTitle
		GetControlValue
		SetControlValue
		GetControlMinimum
		SetControlMinimum
		GetControlMaximum
		SetControlMaximum
		GetControlVariant
		SetControlReference
		GetControlReference
	
		pushButProc
		checkBoxProc
		radioButProc
		scrollBarProc
		popupMenuProc
		kControlUsesOwningWindowsFontVariant
		kControlNoPart
		kControlLabelPart
		kControlMenuPart
		kControlTrianglePart
		kControlButtonPart
		kControlCheckBoxPart
		kControlRadioButtonPart
		kControlUpButtonPart
		kControlDownButtonPart
		kControlPageUpPart
		kControlPageDownPart
		kControlIndicatorPart
		kControlDisabledPart
		kControlInactivePart
		kControlCheckboxUncheckedValue
		kControlCheckboxCheckedValue
		kControlCheckboxMixedValue
		kControlRadioButtonUncheckedValue
		kControlRadioButtonCheckedValue
		kControlRadioButtonMixedValue
		popupFixedWidth
		popupVariableWidth
		popupUseAddResMenu
		popupUseWFont
		popupTitleBold
		popupTitleItalic
		popupTitleUnderline
		popupTitleOutline
		popupTitleShadow
		popupTitleCondense
		popupTitleExtend
		popupTitleNoStyle
		popupTitleLeftJust
		popupTitleCenterJust
		popupTitleRightJust
		noConstraint
		hAxisOnly
		vAxisOnly
		cFrameColor
		cBodyColor
		cTextColor
		cThumbColor
		kNoHiliteControlPart
		kInLabelControlPart
		kInMenuControlPart
		kInTriangleControlPart
		kInButtonControlPart
		kInCheckBoxControlPart
		kInUpButtonControlPart
		kInDownButtonControlPart
		kInPageUpControlPart
		kInPageDownControlPart
		kInIndicatorControlPart
		kReservedControlPart
		kControlInactiveControlPart
	);
	@EXPORT_OK = qw(
		$gControlManager
	);
}

=head2 Constants

=over 4

=item pushButProc

=item checkBoxProc

=item radioButProc

=item scrollBarProc

=item popupMenuProc

=item kControlUsesOwningWindowsFontVariant

Standard control definition procedures and a variant to make them use the window
font instead of the system font.

=cut
sub pushButProc ()                 {          0; }
sub checkBoxProc ()                {          1; }
sub radioButProc ()                {          2; }
sub scrollBarProc ()               {         16; }
sub popupMenuProc ()               {       1008; }
sub kControlUsesOwningWindowsFontVariant () {     1 << 3; }


=item kControlNoPart

=item kControlLabelPart

=item kControlMenuPart

=item kControlTrianglePart

=item kControlButtonPart

=item kControlCheckBoxPart

=item kControlRadioButtonPart

=item kControlUpButtonPart

=item kControlDownButtonPart

=item kControlPageUpPart

=item kControlPageDownPart

=item kControlIndicatorPart

=item kControlDisabledPart

=item kControlInactivePart

Standard control parts.

=cut
sub kControlNoPart ()              {          0; }
sub kControlLabelPart ()           {          1; }
sub kControlMenuPart ()            {          2; }
sub kControlTrianglePart ()        {          4; }
sub kControlButtonPart ()          {         10; }
sub kControlCheckBoxPart ()        {         11; }
sub kControlRadioButtonPart ()     {         11; }
sub kControlUpButtonPart ()        {         20; }
sub kControlDownButtonPart ()      {         21; }
sub kControlPageUpPart ()          {         22; }
sub kControlPageDownPart ()        {         23; }
sub kControlIndicatorPart ()       {        129; }
sub kControlDisabledPart ()        {        254; }
sub kControlInactivePart ()        {        255; }


=item kControlCheckboxUncheckedValue

=item kControlCheckboxCheckedValue

=item kControlCheckboxMixedValue

=item kControlRadioButtonUncheckedValue

=item kControlRadioButtonCheckedValue

=item kControlRadioButtonMixedValue

Standard control values.

=cut
sub kControlCheckboxUncheckedValue () {          0; }
sub kControlCheckboxCheckedValue () {          1; }
sub kControlCheckboxMixedValue ()  {          2; }
sub kControlRadioButtonUncheckedValue () {          0; }
sub kControlRadioButtonCheckedValue () {          1; }
sub kControlRadioButtonMixedValue () {          2; }


=item popupFixedWidth

=item popupVariableWidth

=item popupUseAddResMenu

=item popupUseWFont

=item popupTitleBold

=item popupTitleItalic

=item popupTitleUnderline

=item popupTitleOutline

=item popupTitleShadow

=item popupTitleCondense

=item popupTitleExtend

=item popupTitleNoStyle

=item popupTitleLeftJust

=item popupTitleCenterJust

=item popupTitleRightJust

Popup menu options, for use in the C<value> parameter of the control creation.

=cut
sub popupFixedWidth ()             {     1 << 0; }
sub popupVariableWidth ()          {     1 << 1; }
sub popupUseAddResMenu ()          {     1 << 2; }
sub popupUseWFont ()               {     1 << 3; }
sub popupTitleBold ()              {     1 << 8; }
sub popupTitleItalic ()            {     1 << 9; }
sub popupTitleUnderline ()         {    1 << 10; }
sub popupTitleOutline ()           {    1 << 11; }
sub popupTitleShadow ()            {    1 << 12; }
sub popupTitleCondense ()          {    1 << 13; }
sub popupTitleExtend ()            {    1 << 14; }
sub popupTitleNoStyle ()           {    1 << 15; }
sub popupTitleLeftJust ()          { 0x00000000; }
sub popupTitleCenterJust ()        { 0x00000001; }
sub popupTitleRightJust ()         { 0x000000FF; }


=item noConstraint

=item hAxisOnly

=item vAxisOnly

Drag axis.

=cut
sub noConstraint ()                { 		  0; }
sub hAxisOnly ()                   {          1; }
sub vAxisOnly ()                   {          2; }


=item cFrameColor

=item cBodyColor

=item cTextColor

=item cThumbColor

Color specification parts for control colors.

=cut
sub cFrameColor ()                 {          0; }
sub cBodyColor ()                  {          1; }
sub cTextColor ()                  {          2; }
sub cThumbColor ()                 {          3; }


=item kNoHiliteControlPart

=item kInLabelControlPart

=item kInMenuControlPart

=item kInTriangleControlPart

=item kInButtonControlPart

=item kInCheckBoxControlPart

=item kInUpButtonControlPart

=item kInDownButtonControlPart

=item kInPageUpControlPart

=item kInPageDownControlPart

=item kInIndicatorControlPart

=item kReservedControlPart

=item kControlInactiveControlPart

Part codes for controls.

=cut
sub kNoHiliteControlPart ()        {          0; }
sub kInLabelControlPart ()         {          1; }
sub kInMenuControlPart ()          {          2; }
sub kInTriangleControlPart ()      {          4; }
sub kInButtonControlPart ()        {         10; }
sub kInCheckBoxControlPart ()      {         11; }
sub kInUpButtonControlPart ()      {         20; }
sub kInDownButtonControlPart ()    {         21; }
sub kInPageUpControlPart ()        {         22; }
sub kInPageDownControlPart ()      {         23; }
sub kInIndicatorControlPart ()     {        129; }
sub kReservedControlPart ()        {        254; }
sub kControlInactiveControlPart () {        255; }

=back

=cut

bootstrap Mac::Controls;

=include Controls.xs

=head2 Variables

=over 4

=item $gControlManager

A pane to handle all controls in a window. The default control manager should
usually do what you want.

=back

=cut
$gControlManager = undef;

=head2 MacControlWindow - The Object Interface

The C<MacControlWindow> class used to be necessary to manage a window with 
controls, but is now obsolete.

=cut
package MacControlWindow;

BEGIN {
	use Carp;

	use vars qw(@ISA);
	
	@ISA = qw(MacWindow);
}

sub new {
	carp("MacControlWindow is obsolete, simply use MacWindow") if $^W;
	
	&MacWindow::new;
}

# Name dropping so new MacControlManager below works

package MacControlManager;

package MacWindow;

BEGIN {
	use Carp;
	use Mac::Windows ();
	import Mac::Controls;
}

=item new_control [CLASS, ] CONTROL

=item new_control [CLASS, ] BOUNDS, TITLE, VISIBLE, VAL, MIN, MAX, PROC [, REFCON]

Register a new control for the window. In the first form, registers an existing 
control. In the second form, calls  C<NewControl>.

=cut
sub new_control {
	my($my) = shift @_;
	my($type) = @_;
	my($class,$control,$popup,$c);
	
	unless ($my->{controlmanager}) {
		$my->{controlmanager} = new MacControlManager;
		$my->add_pane($my->{controlmanager});
	}
	if (ref($type)) {
		$class = "MacControl"
	} else {
		$class = shift @_;
		$type  = $_[0];
	}
	if (ref($type) eq "ControlHandle") {
		$control = $type;
	} else {
		$control = NewControl($my->{port}, @_) or croak "NewControl failed";
		$popup   = ($_[6] & ~0x0F) == popupMenuProc;
	} 
	$c = $class->new($my, $control);
	if ($popup) {
		$c->{action} = -1;
	}
	$my->{controls}->{$$control} = $c;
}

=head2 MacControlManager - Managing the controls in a window

The C<MacControlManager> pane handles all controls in a window. This class is
implemented as a flyweight, so only one instance is needed for the entire program.

=cut
package MacControlManager;

BEGIN {
	use Mac::Pane;
	import Mac::Controls;

	use vars qw(@ISA);
	
	@ISA = qw(Mac::Pane);
}

sub new {
	my($class) = @_;
	
	$Mac::Controls::gControlManager ||= bless {}, $class;
}

sub redraw {
	my($my,$win) = @_;
	UpdateControls($win->window);
}

sub click {
	my($my, $win, $pt) = @_;
	
	my($part,$control) = FindControl($pt, $win->window);
	return 0 unless $control;
	
	my($ctrl) = $win->{controls}->{$$control};
	return 0 unless $ctrl;

	$ctrl->track($win, $pt);
	
	1;
}

=head2 MacControl - The Object Interface

The C<MacControlWindow> class manages a single control in a window.

=over 4

=cut
package MacControl;

BEGIN {
	use Mac::Hooks ();
	import Mac::Controls;

	use vars qw(@ISA);
	
	@ISA = qw(Mac::Hooks);
}

=item new WINDOW, CONTROL

Initialize a C<MacControl> (which is always created with 
C<MacWindow::new_control>).

=cut
sub new {
	my($class, $window, $control) = @_;

	my(%vars) = (window => $window, control => $control);
	
	bless \%vars, $class;
}

=item DESTROY

Destroys the C<MacControl>.

=cut
sub DESTROY {
	my($my) = @_;
	DisposeControl($my->{control});
}

=item track WINDOW, PT

Track a mouse click in the control.

=cut
sub track {
	defined($_[0]->callhook("track", @_)) and return;
	my($my, $window, $pt) = @_;
	my($part);
	if ($my->{action}) {
		$part = TrackControl($my->{control}, $pt, $my->{action});
	} else {
		$part = TrackControl($my->{control}, $pt);
	}
	$part && $my->hit($part);
}

=item hit WINDOW, PART

Handle user action in a part. 

=cut
sub hit {
	defined($_[0]->callhook("hit", @_)) and return;
}

=back

=head1 BUGS/LIMITATIONS

=head1 FILES

=head1 AUTHOR(S)

Matthias Ulrich Neeracher <neeri@iis.ee.ethz.ch> 

=cut

1;

__END__
