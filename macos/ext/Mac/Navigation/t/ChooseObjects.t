#!perl
#
# ChooseObjects - Choose arbitrary file system objects
#

use Mac::Navigation;

$options = NavGetDefaultDialogOptions();
$options->message("What's up, Doc?");
$reply 	 = NavChooseObject("", $options, undef, sub {1}) or die $^E;

for ($i = 0; $i++<$reply->count; ) {
   print $reply->file($i), "\n";
}

