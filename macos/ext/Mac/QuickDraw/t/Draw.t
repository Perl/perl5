#!perl

=head1 NAME

Draw - Draw two shapes

=head1 DESCRIPTION

This script draws two simple shapes directly into a random port.
You better have an open window when you run this.

=cut

use Mac::QuickDraw;
use Mac::Windows;

SetPort(FrontWindow());

$r = new Rect 10,10,100,100;
$p = new Pattern q{
   .......X
   .XXXXX.X
   .X...X.X
   .X.XXX.X
   .X.X...X
   .X.XXXXX
   .X......
   XXXXXXXX
};

FrameRect($r);
FillOval($r, $p);
