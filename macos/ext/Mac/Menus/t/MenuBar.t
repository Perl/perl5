#!perl

=head1 NAME

MenuBar - Demonstrate Menu bars

=head1 DESCRIPTION

This script demonstrates a simple menu.

=cut

use Mac::Menus;
use Mac::Events;
use Mac::Resources;
use Mac::Memory;

$res = FSpOpenResFile("MenuBar.rsrc", 0) or die $^E;
$bar = GetNewMBar(30000);

$old = GetMenuBar();
SetMenuBar($bar);

$m   = GetMenuHandle(30000);

$menu = new MacMenu $m, (
	[ sub { print "A"; }],
	[ sub { print "B"; }],
	[],
	[ sub { $done = 1; }],
);

WaitNextEvent until defined $done;

SetMenuBar($old);
DisposeHandle($bar);
CloseResFile($res);