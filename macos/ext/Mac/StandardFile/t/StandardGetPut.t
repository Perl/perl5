#!perl

=head1 NAME

StandardGetPut - Display simple get/put dialogs

=head1 DESCRIPTION

This script displays a few simple standard dialogs.

=cut

use Mac::StandardFile;
use Mac::Files;

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

# Get without file filter

sfresult StandardGetFile(undef, "TEXTAPPL");

# Permissive get

sfresult StandardGetFile(undef, -1);

# Get with ".pm" file filter

sfresult StandardGetFile(
   sub {
      my($info) = @_;
      if ($info->ioNamePtr =~ /\.pm$/) {
         return 0;    # 0 = include in list, 1 = omit
      } else {
         return 1;
      }
   },
   "TEXT");

# Put

sfresult StandardPutFile("Hello there", "Hello, yourself");

