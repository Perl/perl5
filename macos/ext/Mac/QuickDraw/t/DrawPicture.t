#!perl

=head1 NAME

DrawPicture - Draw a picture

=head1 DESCRIPTION

This script draws a picture directly into a random port.
You better have an open window when you run this.

=cut

use Mac::QuickDraw;
use Mac::Windows;

SetPort(FrontWindow());

$pict = GetPicture 129;

DrawPicture $pict, $pict->picFrame;

