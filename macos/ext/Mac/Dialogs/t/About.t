#!perl

=head1 NAME

About - Display the MacPerl about dialog

=head1 DESCRIPTION

This script briefly displays a dialog.

=cut

use Mac::Windows;
use Mac::Dialogs;
use Mac::Events;

$dlg = 
	new MacDialog 258 or die $^E;

ShowWindow $dlg->window;

for (1..50) {
   WaitNextEvent;
}

END {
	dispose $dlg if $dlg;
}
