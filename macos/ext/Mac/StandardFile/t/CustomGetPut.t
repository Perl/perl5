#!perl

=head1 NAME

CustomGetPut - Display more complex get/put dialogs

=head1 DESCRIPTION

This script displays a few slightly sophisticated standard dialogs.

=cut

use Mac::StandardFile;
use Mac::Files;
use Mac::QuickDraw;
use Mac::Windows;
use Mac::Dialogs;
use Mac::Controls;

# Display results

sub sfresult {
   my($result) = @_;
   print 
      "sfGood               = ", $result->sfGood, "\n",
      "sfReplacing          = ", $result->sfReplacing, "\n",
      "sfType               = ", $result->sfType, "\n",
      "sfFile               = ", $result->sfFile, "\n",
      "sfScript             = ", $result->sfScript, "\n",
      "sfFlags              = ", $result->sfFlags, "\n",
      "sfIsFolder           = ", $result->sfIsFolder, "\n",
      "sfIsVolume           = ", $result->sfIsVolume, "\n",
      "______________________________________________\n";
}

# Select a volume

sfresult CustomGetFile(
   sub {               # File filter: Only let through volumes
      my($info) = @_;
      !($info->ioFlAttrib & 16) || $info->ioDrParID != 1;
   },
   -1, sfGetDialogID, new Point(-1,-1),
   sub {               # Dialog hook
      my($item, $dlg) = @_;
      return unless $dlg->refCon == sfMainDialogRefCon;
      
      if ($item == sfHookFirstCall) {
         my($kind, $ctrl, $r) = GetDialogItem $dlg, sfItemOpenButton;
         $ctrl = bless $ctrl, "ControlHandle";
         SetControlTitle $ctrl, "Select";
         $item = sfHookGoToDesktop;
      } elsif ($item == sfHookOpenFolder) {
         $item = sfItemOpenButton;
      }
      $item;
   });
   
