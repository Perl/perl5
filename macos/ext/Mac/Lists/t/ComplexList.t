#!perl

=head1 NAME

ComplexList - Display a list with an LDEF written in Perl

=head1 DESCRIPTION

This script displays a text list in a window.

To end the script, simply close the window.

=cut

use Mac::Events;
use Mac::Windows;
use Mac::QuickDraw;
use Mac::Lists;

$bounds = new Rect 50, 50, 550, 290;
$win = new MacWindow $bounds, "List", 1, documentProc, 1;
$list= $win->new_list(
        new Rect(10, 10, 250, 200),
        new Rect(0, 0, 1, 4),
        new Point(150, 15),
        \&MyLDEF,
        1,
        1);
SetPort($win->window);

$list->set(0, 0, "Ha!");
$list->set(0, 1, "Welch ein GlŸck");
$list->set(0, 2, "Dich hier zu sehn");
$list->set(0, 3, "So schšn");

while ($win->window) {
   WaitNextEvent;
}

sub MyLDEF {
   my($msg, $select, $rect, $cell, $data, $list) = @_;

   return unless $msg == lDrawMsg || $msg == lHiliteMsg;

   my($where) = AddPt($rect->topLeft, $list->indent);
   EraseRect $rect;
   TextFont(3+($cell->v & 1));
   TextSize(9);
   TextFace($select ? bold : normal);
   MoveTo($where->h, $where->v);
   DrawString $data;
}

