#!perl
#
# ChooseFiles - Choose (text) files
#

use Mac::Navigation;

$options = NavGetDefaultDialogOptions(); 
# $options->dialogOptionFlags(
#   $options->dialogOptionFlags & ~kNavDontAddTranslateItems);
$options->message("WH3R3 R 7H3 F1L3Z?");

$types = new NavTypeListHandle "McPL", ["TEXT"];

$reply 	 = NavGetFile("", $options, $types) or die $^E;

for ($i = 0; $i++<$reply->count; ) {
   print $reply->file($i), "\n";
}

