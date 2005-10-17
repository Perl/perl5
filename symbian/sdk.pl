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

# The following is a cheat sheet for the right S60/S80 SDK settings.
#
# set EPOC_BIN=%EPOCROOT%Epoc32\gcc\bin;%EPOCROOT%Epoc32\Tools
# set MWCW=C:\Program Files\Metrowerks\CodeWarrior for Symbian OEM v2.8
# set MSVC=C:\Program Files\Microsoft Visual Studio
# set MSVC_BIN=%MSVC%\VC98\Bin;%MSVC%\Common\MSDev98\Bin
# set MSVC_INC=%MSVC%\VC98\atl\include;%MSVC%\mfc\include;%MSVC%\include
# set MSVC_LIB=%MSVC%\mfc\lib;%MSVC%\lib
#
# s60-1.2-cw:
#
# set EPOCROOT=\Symbian\Series60_1_2_CW\
# set PATH=%EPOC_BIN%;%MSVC_BIN%;%MWCW%\Bin;%MWCW%\Symbian_Tools\Command_Line_Tools;%PATH%
# set USERDEFS=%USERDEFS% -D__SERIES60_12__ -D__SERIES60_MAJOR__=1 -D__SERIES60_MINOR__=2 -D__SERIES60_1X__
#
# s60-1.2-vc:
#
# set EPOCROOT=\Symbian\6.1\Series60\
# set PATH=\Symbian\6.1\Shared\Epoc32\gcc\bin;\Symbian\6.1\Shared\Epoc32\Tools;%MSVC_BIN%;%PATH%
# set INCLUDE=%MSVC_INC%
# set LIB=%MSVC_LIB%
# set USERDEFS=%USERDEFS% -D__SERIES60_12__ -D__SERIES60_MAJOR__=1 -D__SERIES60_MINOR__=2 -D__SERIES60_1X__
# 
# s60-2.0-cw:
#
# set EPOCROOT=\Symbian\7.0s\Series60_v20_CW\
# set EPOCDEVICE=Series60_2_0_CW:com.Nokia.Series60_2_0_CW
# set PATH=%EPOC_BIN%;%MWCW%\Bin;%MWCW%\Symbian_Tools\Command_Line_Tools;%PATH%
# set USERDEFS=%USERDEFS% -D__SERIES60_20__ -D__SERIES60_MAJOR__=2 -D__SERIES60_MINOR__=0 -D__SERIES60_2X__
# 
# s60-2.0-vc:
#
# set EPOCROOT=\Symbian\7.0s\Series60_v20\
# set EPOCDEVICE=Series60_v20:com.nokia.series60
# set PATH=%EPOC_BIN%;%MSVC_BIN%;%PATH%
# set INCLUDE=%MSVC_INC%
# set LIB=%MSVC_LIB%
# set USERDEFS=%USERDEFS% -D__SERIES60_20__ -D__SERIES60_MAJOR__=2 -D__SERIES60_MINOR__=0 -D__SERIES60_2X__
# 
# s60-2.1-cw:
#
# set EPOCROOT=\Symbian\7.0s\Series60_v21_CW\
# set EPOCDEVICE=Series60_v21_CW:com.Nokia.series60
# set PATH=%EPOC_BIN%;%MWCW%\Bin;%MWCW%\Symbian_Tools\Command_Line_Tools;%PATH%
# set USERDEFS=%USERDEFS% -D__SERIES60_21__ -D__SERIES60_MAJOR__=2 -D__SERIES60_MINOR__=1 -D__SERIES60_2X__
# 
# s60-2.6-cw:
#
# set EPOCROOT=\Symbian\8.0a\S60_2nd_FP2_CW\
# set EPOCDEVICE=S60_2nd_FP2_CW:com.nokia.series60
# set PATH=%EPOC_BIN%;%MWCW%\Bin;%MWCW%\Symbian_Tools\Command_Line_Tools;%PATH%
# set USERDEFS=%USERDEFS% -D__SERIES60_26__ -D__SERIES60_MAJOR__=2 -D__SERIES60_MINOR__=6 -D__SERIES60_2X__ -D__BLUETOOTH_API_V2__
# 
# s60-2.6-vc:
#
# set EPOCROOT=\Symbian\8.0a\S60_2nd_FP2\
# set EPOCDEVICE=S60_2nd_FP2:com.nokia.Series60
# set PATH=%EPOC_BIN%;%MSVC_BIN%;%PATH%
# set INCLUDE=%MSVC_INC%
# set LIB=%MSVC_LIB%
# set USERDEFS=%USERDEFS% -D__SERIES60_26__ -D__SERIES60_MAJOR__=2 -D__SERIES60_MINOR__=6 -D__SERIES60_2X__ -D__BLUETOOTH_API_V2__
# 
# s60-2.8-cw:
#
# set EPOCROOT=\Symbian\8.1a\S60_2nd_FP3\
# set EPOCDEVICE=S60_2nd_FP3:com.nokia.series60
# set PATH=%EPOC_BIN%;%MWCW%\Bin;%MWCW%\Symbian_Tools\Command_Line_Tools;%PATH%
# set USERDEFS=%USERDEFS% -D__SERIES60_28__ -D__SERIES60_MAJOR__=2 -D__SERIES60_MINOR__=8 -D__SERIES60_2X__ -D__BLUETOOTH_API_V2__
# 
# s80-2.0-cw:
#
# set EPOCROOT=\Symbian\7.0s\S80_DP2_0_SDK_CW\
# set EPOCDEVICE=Series80_DP2_0_SDK_CW:com.nokia.Series80
# set PATH=%EPOC_BIN%;%MWCW%\Bin;%MWCW%\Symbian_Tools\Command_Line_Tools;%PATH%
# set USERDEFS=%USERDEFS% -D__SERIES80_20__ -D__SERIES80_MAJOR__=2 -D__SERIES80_MINOR__=0 -D__SERIES80_2X__
#
# s80-2.0-vc:
#
# set EPOCROOT=\Symbian\7.0s\S80_DP2_0_SDK\
# set EPOCDEVICE=Series80_DP2_0_SDK:com.nokia.Series80
# set PATH=%EPOC_BIN%;%MWCW%\Bin;%MWCW%\Symbian_Tools\Command_Line_Tools;%PATH%
# set USERDEFS=%USERDEFS% -D__SERIES80_20__ -D__SERIES80_MAJOR__=2 -D__SERIES80_MINOR__=0 -D__SERIES80_2X__
#
# EOF

