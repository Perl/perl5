#!perl

=head1 NAME

CheckBox - modal dialog with somewhat more complicated controls

=head1 DESCRIPTION

This script displays a modal dialog with a checkbox.

=cut

use Mac::Windows;
use Mac::Dialogs;

$dlg = 
	new MacDialog 
		new Rect(20, 40, 320, 180), "Hey you!", 1, kMovableModalDialogVariantCode, 1, (
			[ kButtonDialogItem,     new Rect( 10, 110,  90, 130), "OK"	],
			[ kButtonDialogItem,     new Rect(115, 110, 195, 130), "Cancel"	],
   [ kCheckBoxDialogItem,   new Rect( 10,  75, 190, 95), "Let me out"],
			[ kStaticTextDialogItem, new Rect( 10,  10, 190, 70), "I'm trapped in a Perl script" ]
  );

SetDialogDefaultItem $dlg->window, 1;
SetDialogCancelItem  $dlg->window, 2;

$dlg->item_hit(1 => sub { $OK = 1; });	
$dlg->item_hit(2 => sub { $OK = 0; });
$dlg->item_hit(3 => sub { 
	$dlg->item_value(3 => !$dlg->item_value(3));
	$dlg->item_hilite(1 => $dlg->item_value(3) ? 0 : 255);
});

$dlg->item_value(3 => 1);

$dlg->modal until defined $OK;

print "You clicked ", ($OK ? "OK" : "Cancel"),
      " while the check box was ",
      ($dlg->item_value(3) ? "on" : "off"), ".\n";

dispose $dlg;
