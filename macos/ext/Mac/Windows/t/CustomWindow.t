#!perl

=head1 NAME

CustomWindow - Display a window with a custom WDEF

=head1 DESCRIPTION

This script displays a window with a WDEF written in Perl.

To end the script, simply close the window.

=cut

use Mac::Events;
use Mac::Windows;
use Mac::QuickDraw;
use Mac::Fonts;

$helvetica = GetFNum "Helvetica" or die $^E;
$times = GetFNum "Times" or die $^E;
$bounds = new Rect 50, 50, 550, 290;
$win = new MacWindow $bounds, "Hello, World!", 1, \&MyWDEF, 1;

$win->sethook("redraw", \&DrawOurWindow);

while ($win->window) {
   WaitNextEvent;
   if ($log) {
      print STDERR $log;
      $log = "";
   }
}

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

sub MyWDEF {
   my($variant, $win, $msg, $param) = @_;
   if ($msg == wNew) {
      ;
   } elsif ($msg == wCalcRgns) {
      my($r) = 
         OffsetRect 
            $win->portRect, 
            -$win->portBits->bounds->left,
            -$win->portBits->bounds->top;
      RectRgn $win->contRgn, $r;
      CopyRgn $win->contRgn, $win->strucRgn;
      InsetRgn $win->strucRgn, -10, -10;
   } elsif ($msg == wDraw) {
      if ($param == wInGoAway) {
         my($r) = $win->strucRgn->rgnBBox;
         $r->bottom($r->top + 10);
         $r->right($r->left + 20);
         InvertRect(InsetRect $r, 1, 1);
      } else {
         my($frame) = DiffRgn $win->strucRgn, $win->contRgn;
         EraseRgn $frame;
         FrameRgn $frame;
         if ($win->hilited) {
            my($hilite) = $win->strucRgn->rgnBBox;
            $hilite->bottom($hilite->top+10);
            if ($win->goAwayFlag) {
               MoveTo($hilite->left, $hilite->bottom-1);
               Line(10, 0);
               $hilite->left($hilite->left+20);
            }
            PaintRect($hilite);
         }
      }
   } elsif ($msg == wHit) {
      my($r) = $win->strucRgn->rgnBBox;
      if ($param->h > $r->left && $param->h < $r->right 
       && $param->v > $r->top  && $param->v < $r->top + 10
      ) {
         if ($win->hilited && $win->goAwayFlag && $param->h < $r->left+20) {
            return wInGoAway;
         }
         return wInDrag;
      } elsif (PtInRgn($param, $win->contRgn)) {
         return wInContent;
      }
   }
   return 0;
}

