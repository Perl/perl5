#!perl

=head1 NAME

Cursors - Demonstrate Cursors

=head1 DESCRIPTION

This script demonstrates cursor handling in the MacWindow class.

To end the script, simply close the window.

=cut

use Mac::Events;
use Mac::Windows;
use Mac::QuickDraw;
use Mac::Fonts;

$bounds = new Rect 50, 50, 450, 250;
$win = new MacWindow $bounds, "Move the cursor", 1, noGrowDocProc, 1;

$win->sethook("redraw", \&DrawOurWindow);
$win->sethook("cursor", \&SetOurCursor);

$c1 = new Cursor q{
	XXXX........XXXX
	.XXXX......XXXX.
	..XXXX....XXXX..
	...XXXX..XXXX...
	....XXXXXXXX....
	.....XXXXXX.....
	......XXXX......
	.....XXXXXX.....
	....XXXXXXXX....
	...XXXX..XXXX...
	..XXXX....XXXX..
	.XXXX......XXXX.
	XXXX........XXXX
	................
	................
	................
}, q{
	XXXX........XXXX
	.XXXX......XXXX.
	..XXXX....XXXX..
	...XXXX..XXXX...
	....XXXXXXXX....
	.....XXXXXX.....
	......XXXX......
	.....XXXXXX.....
	....XXXXXXXX....
	...XXXX..XXXX...
	..XXXX....XXXX..
	.XXXX......XXXX.
	XXXX........XXXX
	................
	................
	................
}, new Point(7, 6);

$c2 = new Cursor q{
	.....XXXXXX.....
	...XX......XX...
	..X..........X..
	.X............X.
	.X............X.
	X..............X
	X..............X
	X..............X
	X..............X
	X..............X
	X..............X
	.X............X.
	.X............X.
	..X..........X..
	...XX......XX...
	.....XXXXXX.....
}, q{
	.....XXXXXX.....
	...XX......XX...
	..X..........X..
	.X............X.
	.X............X.
	X..............X
	X..............X
	X..............X
	X..............X
	X..............X
	X..............X
	.X............X.
	.X............X.
	..X..........X..
	...XX......XX...
	.....XXXXXX.....
}, new Point(8, 8);
 
WaitNextEvent while $win->window;

dispose $win;

sub DrawOurWindow {
	MoveTo 50,0;
	LineTo 50,200;
	MoveTo 100,0;
	LineTo 100,200;
	MoveTo 150,0;
	LineTo 150,200;
	MoveTo 200,0;
	LineTo 200,200;
	MoveTo 250,0;
	LineTo 250,200;
	MoveTo 300,0;
	LineTo 300,200;
	MoveTo 350,0;
	LineTo 350,200;
}

sub SetOurCursor {
	my($my,$pt) = @_;
	if ($pt->h < 50) {
		SetCursor();
	} elsif ($pt->h < 100) {
		SetCursor(iBeamCursor);
	} elsif ($pt->h < 150) {
		SetCursor(watchCursor);
	} elsif ($pt->h < 200) {
		SetCursor(crossCursor);
	} elsif ($pt->h < 250) {
		SetCursor(plusCursor);
	} elsif ($pt->h < 300) {
		SetCursor($c1);
	} elsif ($pt->h < 350) {
		SetCursor($c2);
	} else {
		SetCursor();
	}
	1;
}

