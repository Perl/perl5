#!perl

=head1 NAME

MouseLogger - Protocol 10 mouse clicks

=head1 DESCRIPTION

This script protocols the location of 10 mouse clicks. It accesses
the event interface of MacPerl directly, which you normally don't
have to do.

=cut

use Mac::Events;
use Mac::Windows;

$Mac::Events::Event[mouseDown] = \&MouseDownProc;

WaitNextEvent until $Clicks == 10;

sub MouseDownProc {
	my($ev) = @_;
	print "Mouse clicked: ", $ev->where->h, ", ", $ev->where->v, "\n";
	++$Clicks;
}
