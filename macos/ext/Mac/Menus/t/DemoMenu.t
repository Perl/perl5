#!perl

=head1 NAME

DemoMenu - Demonstrate Menus

=head1 DESCRIPTION

This script demonstrates a simple menu.

=cut

use Mac::Menus;
use Mac::Events;

$menu = new MacMenu 2048, "Demo", (
	["One", \&Handler],
	["Two", \&Handler],
	["Three", \&Handler],
	[],
	["Four", \&Handler],
);

$menu->insert;

WaitNextEvent until defined $Menu;

dispose $menu;

sub Handler {
	my($menu,$item) = @_;

 print "Selected menu ", $menu, " item ", $item, "\n";
	$Menu = $item;
}
