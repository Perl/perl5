#!perl

=head1 NAME

PlayMacMovie - Display a movie the easy way, with a movie controller

=head1 DESCRIPTION

This script displays a movie in a window.

To end the script, simply close the window.

=cut

use Mac::Events;
use Mac::Windows;
use Mac::QuickDraw;
use Mac::Movies;

require "StandardFile.pl"; 

sub GetMovie {
   my($file) = StandardFile::GetFile('MooV');
   die "I'll be back!" unless defined $file;
   my($resfile) = OpenMovieFile($file);
   die $^E unless $resfile;
   my($movie)   = NewMovieFromFile($resfile, 0, newMovieActive);
   die $^E unless $movie;
   CloseMovieFile($resFile);

   $movie;
}

EnterMovies() or die $^E;

$bounds = new Rect 50, 50, 550, 400;
$win = new MacWindow $bounds, "You Gotta Move", 1, documentProc, 1;

SetPort($win->window);
$movie = GetMovie();

$win->new_movie($movie, $win->window->portRect);

WaitNextEvent while ($win->window);

DisposeMovie $movie;
dispose $win;

ExitMovies();
