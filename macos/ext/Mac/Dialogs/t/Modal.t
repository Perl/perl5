#!perl

=head1 NAME

Modal - Display a modal dialog

=head1 DESCRIPTION

This script displays a modal dialog.

=cut

use Mac::Windows;
use Mac::Dialogs;

$dlg = 
	new MacDialog 
		new Rect(20, 40, 320, 180), "Hey you!", 1, kMovableModalDialogVariantCode, 1, (
			[ kButtonDialogItem,     new Rect( 10, 110,  90, 130), "OK"	],
			[ kButtonDialogItem,     new Rect(115, 110, 195, 130), "Cancel"	],
			[ kStaticTextDialogItem, new Rect( 10,  10, 190, 100), "I'm trapped in a Perl script" ]
  );

SetDialogDefaultItem $dlg->window, 1;
SetDialogCancelItem  $dlg->window, 2;

$dlg->item_hit(1 => sub { $OK = 1; });	
$dlg->item_hit(2 => sub { $OK = 0; });

$dlg->modal until defined $OK;

print "You clicked ", ($OK ? "OK" : "Cancel"), "\n";

dispose $dlg;
