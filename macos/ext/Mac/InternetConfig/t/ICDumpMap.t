#!perl
#
# ICDumpMap - Dump suffix mappings
#

use Mac::InternetConfig;

sub ShowMap {
   my($entry) = @_;

   printf "%4s %4s %-6s %-25s %-20s %-15s\n",
      $entry->file_type, $entry->file_creator,
      $entry->extension, $entry->creator_app_name,
      $entry->MIME_type, $entry->entry_name;
}

print "PDF files are handled by:\n";
ShowMap $InternetConfigMap{".pdf"};
print "Word files are handled by:\n";
ShowMap $InternetConfigMap{[qw(WDBN MSWD)]};

print "The first 20 entries of the map are:\n";
for my $entry (keys %InternetConfigMap) {
   ShowMap $entry;
   last if ++$count==20;
}
