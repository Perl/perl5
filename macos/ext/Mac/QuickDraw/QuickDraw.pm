
=head1 NAME

Mac::QuickDraw - Macintosh Toolbox Interface to QuickDraw

=head1 SYNOPSIS


=head1 DESCRIPTION

Access to Inside Macintosh is essential for proper use of these functions.
Explanations of terms, processes and procedures are provided there.
Any attempt to use these functions without guidance can cause severe errors in 
your machine, including corruption of data. B<You have been warned.>

=cut

use strict;

package Mac::QuickDraw;

BEGIN {
	use Exporter   ();
	use DynaLoader ();
	
	use vars qw($VERSION @ISA @EXPORT %Cursors);
	$VERSION = '1.00';
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		SetPort
		GetPort
		SetOrigin
		SetClip
		GetClip
		ClipRect
		BackPat
		InitCursor
		SetCursor
		HideCursor
		ShowCursor
		ObscureCursor
		HidePen
		ShowPen
		GetPen
		GetPenState
		SetPenState
		PenSize
		PenMode
		PenPat
		PenNormal
		MoveTo
		Move
		LineTo
		Line
		ForeColor
		BackColor
		OffsetRect
		InsetRect
		SectRect
		UnionRect
		EqualRect
		EmptyRect
		FrameRect
		PaintRect
		EraseRect
		InvertRect
		FillRect
		FrameOval
		PaintOval
		EraseOval
		InvertOval
		FillOval
		FrameRoundRect
		PaintRoundRect
		EraseRoundRect
		InvertRoundRect
		FillRoundRect
		FrameArc
		PaintArc
		EraseArc
		InvertArc
		FillArc
		NewRgn
		OpenRgn
		CloseRgn
		DisposeRgn
		CopyRgn
		SetEmptyRgn
		SetRectRgn
		OffsetRgn
		InsetRgn
		SectRgn
		UnionRgn
		DiffRgn
		XorRgn
		RectInRgn
		EqualRgn
		EmptyRgn
		FrameRgn
		PaintRgn
		EraseRgn
		InvertRgn
		FillRgn
		ScrollRect
		CopyBits
		CopyMask
		OpenPicture
		PicComment
		ClosePicture
		DrawPicture
		KillPicture
		OpenPoly
		ClosePoly
		KillPoly
		OffsetPoly
		FramePoly
		PaintPoly
		ErasePoly
		InvertPoly
		FillPoly
		LocalToGlobal
		GlobalToLocal
		Random
		GetPixel
		ScalePt
		MapPt
		MapRect
		MapRgn
		MapPoly
		PtInRect
		AddPt
		SubPt
		EqualPt
		Pt2Rect
		PtToAngle
		PtInRgn
		NewPixMap
		DisposePixMap
		CopyPixMap
		NewPixPat
		DisposePixPat
		CopyPixPat
		PenPixPat
		BackPixPat
		GetPixPat
		FillCRect
		FillCOval
		FillCRoundRect
		FillCArc
		FillCRgn
		FillCPoly
		RGBForeColor
		RGBBackColor
		SetCPixel
		SetPortPix
		GetCPixel
		GetForeColor
		GetBackColor
		OpenCPicture
		OpColor
		HiliteColor
		DisposeCTable
		GetCTable
		GetCCursor
		SetCCursor
		DisposeCCursor
		GetCIcon
		PlotCIcon
		DisposeCIcon
		GetMaxDevice
		GetDeviceList
		GetMainDevice
		GetNextDevice
		TestDeviceAttribute
		SetDeviceAttribute
		NewGDevice
		DisposeGDevice
		SetGDevice
		GetGDevice
		Color2Index
		Index2Color
		InvertColor
		RealColor
		QDError
		CopyDeepMask
		GetPattern
		GetCursor
		GetPicture
		ShieldCursor
		ScreenRes
		GetIndPattern
		SetRect
		BitMapToRegion
		RectRgn
		PixelToChar
		CharToPixel
		DrawJustified
		PortionLine
		VisibleLength
		TextFont
		TextFace
		TextMode
		TextSize
		SpaceExtra
		DrawString
		StringWidth
		GetFontInfo
		CharExtra
		
		invalColReq
		srcCopy
		srcOr
		srcXor
		srcBic
		notSrcCopy
		notSrcOr
		notSrcXor
		notSrcBic
		patCopy
		patOr
		patXor
		patBic
		notPatCopy
		notPatOr
		notPatXor
		notPatBic
		grayishTextOr
		hilitetransfermode
		blend
		addPin
		addOver
		subPin
		addMax
		adMax
		subOver
		adMin
		ditherCopy
		transparent
		blackColor
		whiteColor
		redColor
		greenColor
		blueColor
		cyanColor
		magentaColor
		yellowColor
		picLParen
		picRParen
		clutType
		fixedType
		directType
		gdDevType
		interlacedDevice
		roundedDevice
		hasAuxMenuBar
		burstDevice
		ext32Device
		ramInit
		mainScreen
		allInit
		screenDevice
		noDriver
		screenActive
		hiliteBit
		pHiliteBit
		defQDColors
		RGBDirect
		sysPatListID
		iBeamCursor
		crossCursor
		plusCursor
		watchCursor
		leftCaret
		rightCaret
		hilite
		smLeftCaret
		smRightCaret
		smHilite
		onlyStyleRun
		leftStyleRun
		rightStyleRun
		middleStyleRun
		smOnlyStyleRun
		smLeftStyleRun
		smRightStyleRun
		smMiddleStyleRun
		normal
		bold
		italic
		underline
		outline
		shadow
		condense
		extend
	);
}

package Mac::QuickDraw;

sub invalColReq ()                 {         -1; }

sub srcCopy ()                     {          0; }
sub srcOr ()                       {          1; }
sub srcXor ()                      {          2; }
sub srcBic ()                      {          3; }
sub notSrcCopy ()                  {          4; }
sub notSrcOr ()                    {          5; }
sub notSrcXor ()                   {          6; }
sub notSrcBic ()                   {          7; }
sub patCopy ()                     {          8; }
sub patOr ()                       {          9; }
sub patXor ()                      {         10; }
sub patBic ()                      {         11; }
sub notPatCopy ()                  {         12; }
sub notPatOr ()                    {         13; }
sub notPatXor ()                   {         14; }
sub notPatBic ()                   {         15; }
sub grayishTextOr ()               {         49; }
sub hilitetransfermode ()          {         50; }
sub blend ()                       {         32; }
sub addPin ()                      {         33; }
sub addOver ()                     {         34; }
sub subPin ()                      {         35; }
sub addMax ()                      {         37; }
sub adMax ()                       {         37; }
sub subOver ()                     {         38; }
sub adMin ()                       {         39; }
sub ditherCopy ()                  {         64; }
sub transparent ()                 {         36; }

sub blackColor ()                  {         33; }
sub whiteColor ()                  {         30; }
sub redColor ()                    {        205; }
sub greenColor ()                  {        341; }
sub blueColor ()                   {        409; }
sub cyanColor ()                   {        273; }
sub magentaColor ()                {        137; }
sub yellowColor ()                 {         69; }

sub picLParen ()                   {          0; }
sub picRParen ()                   {          1; }

sub clutType ()                    {          0; }
sub fixedType ()                   {          1; }
sub directType ()                  {          2; }

sub gdDevType ()                   {          0; }
sub interlacedDevice ()            {          2; }
sub roundedDevice ()               {          5; }
sub hasAuxMenuBar ()               {          6; }
sub burstDevice ()                 {          7; }
sub ext32Device ()                 {          8; }
sub ramInit ()                     {         10; }
sub mainScreen ()                  {         11; }
sub allInit ()                     {         12; }
sub screenDevice ()                {         13; }
sub noDriver ()                    {         14; }
sub screenActive ()                {         15; }

sub defQDColors ()                 {        127; }
sub RGBDirect ()                   {         16; }

sub sysPatListID ()                {          0; }

sub iBeamCursor ()                 {          1; }
sub crossCursor ()                 {          2; }
sub plusCursor ()                  {          3; }
sub watchCursor ()                 {          4; }

sub smLeftCaret ()                 {          0; }
sub smRightCaret ()                {         -1; }
sub smHilite ()                    {          1; }

sub smOnlyStyleRun ()              {          0; }
sub smLeftStyleRun ()              {          1; }
sub smRightStyleRun ()             {          2; }
sub smMiddleStyleRun ()            {          3; }

sub normal ()                      {          0; }
sub bold ()                        {          1; }
sub italic ()                      {          2; }
sub underline ()                   {          4; }
sub outline ()                     {          8; }
sub shadow ()                      {       0x10; }
sub condense ()                    {       0x20; }
sub extend ()                      {       0x40; }

sub _PackImage {
	my($str,$width) = @_;
	my($image);
	for (split(/\s*\n\s*/, $str)) {
		next unless /\S/;
		s/[. _]/0/g;
		s/[^01]/1/g;
		$image .= pack("B$width", $_);
	}
	$image;
}

=head2 Types

=over 4

=cut
package Pattern;

=item Pattern

A QuickDraw pattern

=over 4

=item new Pattern BITS

=item new Pattern IMAGE

Create a new pattern, either from a binary string of length 8, or from an ASCII
image, where ".", " ", "_", and "0" are interpreted as clear pixels, everything 
else as set pixels. Indent is removed.

	$love = new Pattern q{
	    .XX.XX..
		X..X..X.
		X.....X.
		.X...X..
		..X.X...
		...X....
		........
		........
	};

=back

=cut
sub new {
	my($class,$patstr) = @_;
	my($p);
	if (length($patstr) == 8) {
	   	$p = $patstr;
	} else {
		$p = Mac::QuickDraw::_PackImage($patstr, 8);
	}
	bless \$p, $class;
}

package Cursor;

=item Cursor

A QuickDraw cursor

=over 4

=item new Cursor DATA

=item new Cursor DATABITS, MASKBITS, HOTSPOT

=item new Cursor DATAIMAGE, MASKIMAGE, HOTSPOT

Create a new cursor, either from a binary string of length 68, from two binary
strings of length 32 and a hotspot C<Point>, or from two ASCII images similar
to the patterns above, and a hotspot point.

	$sniper = new Cursor q{
	   .......@........
	   .......@........
	   .....@@@@@......
	   ....@..@..@.....
	   ...@...@...@....
	   ..@....@....@...
	   ..@.........@...
	   @@@@@@...@@@@@@.
	   ..@.........@...
	   ..@....@....@...
	   ...@...@...@....
	   ....@..@..@.....
	   .....@@@@@......
	   .......@........
	   .......@........
	   ................
    }, q{
	   .......@........
	   .......@........
	   .....@@@@@......
	   ....@..@..@.....
	   ...@...@...@....
	   ..@....@....@...
	   ..@.........@...
	   @@@@@@...@@@@@@.
	   ..@.........@...
	   ..@....@....@...
	   ...@...@...@....
	   ....@..@..@.....
	   .....@@@@@......
	   .......@........
	   .......@........
	   ................
   }, new Point(7,7);

=back

=cut
sub new {
	my($class,$data,$mask,$hotspot) = @_;
	my($p);
	if (length($data) == 68) {
		$p = $data;
	} elsif (length($data) == 32) {
	   	$p = $data.$mask.$$hotspot;
	} else {
		$p = Mac::QuickDraw::_PackImage($data, 16)
		   . Mac::QuickDraw::_PackImage($mask, 16)
		   . $$hotspot;
	}
	bless \$p, $class;
}

package PicHandle;

use Mac::Memory ();

sub new {
	my($class,$data) = @_;
	
	$data = new Handle($data) unless ref($data) && $data->isa("Handle");
	
	bless $data, $class;
}

package RgnHandle;

sub new {
	Mac::QuickDraw::NewRgn();
}

package RGBColor;

sub new {
	my($class, $red, $green, $blue) = @_;
	my($color) = pack("SSS", $red, $green, $blue);
	
	bless \$color, $class;
}

package Rect;

sub new {
	my $class = shift @_;
	my $r;

	if (ref($_[0]) && $_[0]->isa("Point")) {
		$r = _new();
		$r->topLeft($_[0]);
		$r->botRight($_[1]) if $_[1];
	} else {
		$r = _new(@_);
	}
	$r;
}

package Mac::QuickDraw;

bootstrap Mac::QuickDraw;

=include QuickDraw.xs

=item RECT = SetRect LEFT, TOP, RIGHT, BOTTOM

=cut
sub SetRect {
	new Rect @_;
}

=item PT = SetPt H, V

=cut
sub SetPt {
	new Point @_;
}

sub BitMapToRegion {
	unshift @_, NewRgn() unless @_ >= 2;
	&_BitMapToRegion(@_);
}

sub RectRgn {
	unshift @_, NewRgn() unless @_ >= 2;
	&_RectRgn(@_);
}

sub MakeRGBPat {
	unshift @_, NewPixPat() unless @_ >= 2;
	&_MakeRGBPat(@_);
}

sub SetCursor {
	my($crsr) = @_;
	if (defined($crsr) && !ref($crsr)) {
		$Cursors{$crsr} ||= GetCursor($crsr);
		@_ = ($Cursors{$crsr});
	}
	_SetCursor(@_);
}

=head1 BUGS/LIMITATIONS

=head1 FILES

=head1 AUTHOR(S)

Matthias Ulrich Neeracher <neeri@iis.ee.ethz.ch> 

=cut

__END__
