#!perl

=head1 NAME

SimpleText - Display a simple text editing field

=head1 DESCRIPTION

This script displays a text list in a window.

To end the script, simply close the window.

=cut

use Mac::Events;
use Mac::Windows;
use Mac::QuickDraw;
use Mac::TextEdit;

$bounds = new Rect 50, 50, 550, 290;
$win = new MacWindow $bounds, "Edit", 1, documentProc, 1;
$list= $win->new_textedit( 
        new Rect(15, 15, 485, 195),
        new Rect(10, 10, 490, 200));

while ($win->window) {
   WaitNextEvent;
}

dispose $win;
