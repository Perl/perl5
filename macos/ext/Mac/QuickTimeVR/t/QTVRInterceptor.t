#!perl

=head1 NAME

QTVRInterceptor - Demostrate a pan interceptor for QTVR

=head1 DESCRIPTION

This script displays a movie in a window.

To end the script, simply close the window.

=cut

use Mac::Events;
use Mac::Windows;
use Mac::QuickDraw;
use Mac::Movies;
use Mac::QuickTimeVR;
use Mac::Sound;

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

$pane = $win->new_movie($movie, $win->window->portRect);
$track = QTVRGetQTVRTrack($movie, 1);  die $^E unless $track;
$qtvr  = QTVRGetQTVRInstance($track, $pane->movie); die $^E unless $qtvr;
QTVRInstallInterceptProc(
    $qtvr, kQTVRSetPanAngleSelector,
    sub { SysBeep(1); return 0; }, 
    0); 
WaitNextEvent while ($win->window);

DisposeMovie $movie;
dispose $win;

ExitMovies();
