#!perl

=head1 NAME

FontList - Display a list of fonts and highlight available sizes

=head1 DESCRIPTION

This script displays a text list in a window.

To end the script, simply close the window.

=cut

use Mac::Events;
use Mac::Windows;
use Mac::QuickDraw;
use Mac::Lists;

$bounds = new Rect 50, 50, 550, 290;
$win = new MacWindow $bounds, "List", 0, documentProc, 1;
$fonts= $win->new_list( 
        new Rect(10, 10, 230, 200),
        new Rect(0, 0, 1, 4),
        new Point(220, 20),
        0,
        1,
        0);
$fonts->set(0, 0, "Chicago");
$fonts->set(0, 1, "Geneva");
$fonts->set(0, 2, "Monaco");
$fonts->set(0, 3, "Courier");
$fonts->list->selFlags($fonts->list->selFlags | lNoExtend | lOnlyOne);
LSetSelect(1, new Point(0,0), $fonts->list);
$sizes= $win->new_list( 
        new Rect(260, 10, 470, 200),
        new Rect(0, 0, 1, 4),
        new Point(210, 15),
        0,
        1,
        0);
$sizes->set(0, 0, "9");
$sizes->set(0, 1, "10");
$sizes->set(0, 2, "12");
$sizes->set(0, 3, "14");
$sizes->list->selFlags($sizes->list->selFlags | lNoExtend | lOnlyOne);
LSetSelect(1, new Point(0,0), $sizes->list);

SetPort($win->window);
TextFont(0);
ShowWindow($win->window);

while ($win->window) {
   WaitNextEvent;
}

dispose $win;
