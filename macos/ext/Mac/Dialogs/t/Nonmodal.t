#!perl

=head1 NAME

Nonmodal - Display a nonmodal dialog

=head1 DESCRIPTION

This script displays a nonmodal dialog. Note that the code is almost identical to
the modal dialog case.

=cut

use Mac::Events;
use Mac::Windows;
use Mac::Dialogs;

$dlg = 
	new MacDialog 
		new Rect(20, 40, 320, 180), "Hey you!", 1, kStandardWindowDefinition, 1, (
			[ kButtonDialogItem,     new Rect( 10, 110,  90, 130), "OK"	],
			[ kButtonDialogItem,     new Rect(115, 110, 195, 130), "Cancel"	],
			[ kStaticTextDialogItem, new Rect( 10,  10, 190, 100), "Click a button whenever you feel like it" ]
  );

SetDialogDefaultItem $dlg->window, 1;
SetDialogCancelItem  $dlg->window, 2;

$dlg->item_hit(1 => sub { $OK = 1; });	
$dlg->item_hit(2 => sub { $OK = 0; });

WaitNextEvent until (defined $OK) || !$dlg->window;

print "You clicked ", ($OK ? "OK" : "Cancel"), "\n";

dispose $dlg;
