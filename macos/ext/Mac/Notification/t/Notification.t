#!perl

use Mac::Notification;
use Mac::Events;
use Mac::Processes;
use Mac::Resources;

sub DoNotify {
   my($notification) = @_;

   print "Switch me to the background, please!\n";

   WaitNextEvent while SameProcess(GetCurrentProcess, GetFrontProcess);
   NMInstall($notification);

   WaitNextEvent until SameProcess(GetCurrentProcess, GetFrontProcess);
   NMRemove($notification);
}

#
# Notify with dialog, system beep, check mark, application icon
#
DoNotify(new NMRec(nmStr=>"Thank you. Please bring MacPerl to the front again."));

#
# Notify with custom sound and application icon only. 
# Sample from pitchshifter's _www.pitchshifter.com_ used with 
# permission.
#
chomp($file = `pwd`);
$file .= ":Notification.rsrc";
print $file, "\n";
($res = OpenResFile($file)) or die $^E;
$snd = GetResource("snd ", 128);
DoNotify(new NMRec(nmMark=>0, nmSound=>$snd));
CloseResFile($res);
