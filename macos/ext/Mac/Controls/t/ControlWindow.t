#!perl


=head1 NAME

ControlWindow - Demonstrate Controls

=head1 DESCRIPTION

This script demonstrates a window with two buttons. Again, most of
the dirty work is done automatically by the C<MacWindow> class.

To end the script, simply close the window.

=cut

use Mac::QuickDraw;
use Mac::Windows;
use Mac::Controls;
use Mac::Events;

$bounds = new Rect 50, 50, 550, 290;
$win = new MacWindow $bounds, "Hello, World!", 1, 0, 1;

$pur = new Rect  18,  90, 198, 109;
$pop = new_control $win $pur, "Type:", 1, popupTitleLeftJust, 192, 80, popupMenuProc;
$pop->sethook("hit", sub { print "Pop 'till you drop\n"; });

$b1r = new Rect 380, 160, 480, 180;
$b1  = new_control $win $b1r, "OK", 1, 0, 0, 1, pushButProc;
$b1->sethook("hit", sub { print "Okey Dokey\n"; });

$b2r = OffsetRect($b1r, 0, 40);
$b2 	= new_control $win $b2r, "Cancel", 1, 0, 0, 1, pushButProc;
$b2->sethook("hit", sub { print "Scratch That\n"; });

WaitNextEvent while $win->window;

dispose $win;
