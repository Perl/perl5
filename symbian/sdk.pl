use strict;

my $SDK;
my $WIN;

if ($ENV{PATH} =~ m!\\Symbian\\(.+?)\\gcc\\bin!) {
    my $cc = $1;
    $WIN = $cc =~ m!_CW!i ? 'winscw' : 'wins';
    $ENV{WIN} = $WIN; 
    if ($cc =~ m!Series60_v20!) {
	$ENV{S60SDK} = '2.0';
    } elsif ($cc =~ m!Series60_v21!) {
	$ENV{S60SDK} = '2.1';
    } elsif ($cc =~ m!S60_2nd_FP2!) {
	$ENV{S60SDK} = '2.6';
    }
}

if (open(GCC, "gcc -v 2>&1|")) {
   while (<GCC>) {
     if (/Reading specs from ((?:C:)?\\Symbian.+?)\\Epoc32\\/i) {
       $SDK = $1;
       # The S60SDK tells the Series 60 SDK version.
       if ($SDK eq 'C:\Symbian\6.1\Shared') { # Visual C. 
	   $SDK = 'C:\Symbian\6.1\Series60';
	   $ENV{S60SDK} = '1.2';
       } elsif ($SDK eq 'C:\Symbian\Series60_1_2_CW') { # CodeWarrior.
	   $ENV{S60SDK} = '1.2';
       }
       last;
     }
   }
   close GCC;
} else {
  die "$0: failed to run gcc: $!\n";
}

my $UARM = $ENV{UARM} ? $ENV{UARM} : "urel";
my $UREL = "$SDK\\epoc32\\release\\-ARM-\\$UARM";
if ($SDK eq 'C:\Symbian\6.1\Series60' && $ENV{WIN} eq 'winscw') {
    $UREL = "C:\\Symbian\\Series60_1_2_CW\\epoc32\\release\\-ARM-\\urel";
}
$ENV{UREL} = $UREL;
$ENV{UARM} = $UARM;

die "$0: failed to locate the Symbian SDK\n" unless defined $SDK;

$SDK;
