use strict;

if (exists $ENV{'!C:'}) {
  print "You are running this under Cygwin, aren't you?\n";
  print "I'm sorry but only cmd.exe will work.\n";
  exit(1);
}

if (# SDK 2.x
    $ENV{PATH} !~ m!c:\\program files\\common files\\symbian\\tools!i
    &&
    # SDK 1.2
    $ENV{PATH} !~ m!c:\\symbian\\6.1\\shared\\epoc32\\tools!i) {
  print "I think you have not installed the Symbian SDK.\n";
  exit(1);
}

unless (-f "symbian/symbianish.h") {
  print "You must run this in the top level directory.\n";
  exit(1);
}

if ($] < 5.008) {
  print "You must configure with Perl 5.8 or later.\n";
  exit(1);
}

1;
