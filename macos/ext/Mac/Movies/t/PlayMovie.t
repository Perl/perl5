#!perl

=head1 NAME

PlayMovie - Display a movie

=head1 DESCRIPTION

This script displays a movie in a window.

To end the script, simply close the window.

=cut

use Mac::Events;
use Mac::Windows;
use Mac::QuickDraw;
use Mac::Movies;
use Mac::StandardFile;

sub GetMovie {
   my($file) = StandardGetFile(0, 'MooV');
   die "I'll be back!" unless defined $file;
   my($resfile) = OpenMovieFile($file->sfFile);
   die $^E unless $resfile;
   my($movie)   = NewMovieFromFile($resfile, 0, newMovieActive);
   die $^E unless $movie;
   CloseMovieFile($resFile);

   $movie;
}

EnterMovies() or die $^E;

$movie = GetMovie();

$bounds = new Rect 50, 50, 550, 290;
$win = new MacWindow $bounds, "You Gotta Move", 1, documentProc, 1;

SetPort($win->window);
$mbox  = GetMovieBox($movie);
SetMovieBox $movie, OffsetRect($mbox, -$mbox->left, -$mbox->top);
SetMovieGWorld $movie, $win->window;

StartMovie $movie;

$win->sethook("redraw", \&DrawOurWindow);

while ($win->window && !IsMovieDone($movie)) {
   WaitNextEvent;
   MoviesTask $movie, 5000;
}

while ($win->window) {
   WaitNextEvent;
}

DisposeMovie $movie;
dispose $win;

sub DrawOurWindow {
   UpdateMovie $movie;
}
