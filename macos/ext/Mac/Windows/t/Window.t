#!perl

=head1 NAME

Window - Display a simple window

=head1 DESCRIPTION

This script displays a simple window. Note how through the MacWindow
class, most common events (drags, goaway, grows) are handled 
automatically.

To end the script, simply close the window.

=cut

use Mac::Events;
use Mac::Windows;
use Mac::QuickDraw;
use Mac::Fonts;

$helvetica = GetFNum "Helvetica" or die $^E;
$times = GetFNum "Times" or die $^E;
$bounds = new Rect 50, 50, 550, 290;
$win = new MacWindow $bounds, "Hello, World!", 1, documentProc, 1;

$win->sethook("redraw", \&DrawOurWindow);

WaitNextEvent while $win->window;

dispose $win;

sub DrawOurWindow {
	MoveTo 20,80;
	LineTo 80,130;
	$r = new Rect 100,100,200,200;
	PaintOval $r;
	MoveTo 10,25;
	TextFont($helvetica);
	TextSize(30);
	TextFace(normal);
	DrawString "We want the world and we want it...";
	MoveTo 30,70;
	TextFont($times);
	TextSize(50);
	TextFace(bold);
	DrawString "NOOOOOOOWW !";
}
