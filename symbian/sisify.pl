#!/usr/bin/perl -w

#
# sisify.pl - package Perl scripts or Perl libraries into SIS files
#
# Copyright (c) 2004-2005 Nokia. All rights reserved.
#
# The sisify.pl utility is licensed under the same terms as Perl itself.
#

require 5.008;

use strict;

use vars qw($VERSION);

$VERSION = '0.2';

use Getopt::Long;
use File::Temp qw/tempdir/;
use File::Find;
use File::Basename qw/basename dirname/;
use Cwd qw/getcwd/;

BEGIN {
  # This utility has been developed in Windows under cmd.exe with
  # the Series 60 2.6 SDK installed, but for the makesis utility
  # in UNIX/Linux, try e.g. one of the following:
  # http://gnupoc.sourceforge.net/
  # http://symbianos.org/~andreh/ You
  # will also need the 'uidcrc' utility.
  die "$0: Looks like Cygwin, aborting.\n" if exists $ENV{'!C:'};
}

sub die_with_usage {
  if (@_) {
    warn "$0: $_\n" for @_;
  }
  die <<__USAGE__;
$0: Usage:
$0 [ --uid=hhhhhhhh ] [ --version=a.b.c ] [ --library=x.y.z ] [ some.pl | Some.pm | somefile | dir ... ]
The uid is the Symbian app uid for the SIS.
The version is the version of the SIS.
The library is the version of Perl under which to install.  If using this,
only specify directories for packaging.
__USAGE__
}

my $SisUid;
my $SisVersion;
my $Library;
my @SisPl;
my @SisPm;
my @SisDir;
my @SisOther;
my $AppName;
my $Debug;
my $ShowPkg;

my $SisUidDefault     = 0x0acebabe;
my $SisVersionDefault = '0.0.0';

die_with_usage()
  unless GetOptions(
		    'uid=s'		=> \$SisUid,
		    'version=s'		=> \$SisVersion,
		    'debug'		=> \$Debug,
		    'showpkg'		=> \$ShowPkg,
		    'library=s'		=> \$Library,
		    'appname=s'		=> \$AppName,
		   );
die_with_usage("Need to specify what to sisify")
  unless @ARGV;

for my $i (@ARGV) {
  if ($i =~ /\.pl$/i) {
    push @SisPl, $i;
  } elsif ($i =~ /\.pm$/i) {
    push @SisPm, $i;
  } elsif (-f $i) {
    push @SisOther, $i;
  } elsif (-d $i) {
    push @SisDir, $i;
  } else {
    die_with_usage("Unknown sisifiable '$i'");
  }
}

sub do_system {
    my $cwd = getcwd();
    print qq{\# system("@_") [cwd "$cwd"]\n};
    return system("@_") == 0;
}

die_with_usage("Must specify something to sisify")
  unless @SisPl || @SisPm || @SisOther || @SisDir;

die_with_usage("With the lib option set, specify only directories")
  if defined $Library && ((@SisPl || @SisPm || @SisOther) || @SisDir == 0);

die_with_usage("Lib must define the Perl 5 version as 5.x.y")
  if defined $Library && $Library !~ /^5.\d+\.\d+$/;

die_with_usage("With the lib option unset, specify at least one .pl file")
  if (! defined $Library && @SisPl == 0);

if (!defined $AppName) {
  if (defined $Library) {
    $AppName = $SisDir[0];
    $AppName =~ tr!/!-!;
  } elsif (@SisPl > 0 && $SisPl[0] =~ /^(.+)\.pl$/i) {
    $AppName = basename($1);
  }
}

die_with_usage("Must either specify appname or at least one .pl file or the lib option")
  unless defined $AppName || defined $Library;

print "[app name '$AppName']\n" if $Debug;

unless (defined $SisUid) {
  $SisUid = $SisUidDefault;
  printf "[default app uid '0x%08x']\n", $SisUid;
} elsif ($SisUid =~ /^(?:0x)?([0-9a-f]{8})$/i) {
  $SisUid = hex($1);
} else {
  die_with_usage("Bad uid '$SisUid'");
}
$SisUid = sprintf "0x%08x", $SisUid;

die_with_usage("Bad uid '$SisUid'")
  if $SisUid !~ /^0x[0-9a-f]{8}$/i;

unless (defined $SisVersion) {
  $SisVersion = $SisVersionDefault;
  print "[default app version '$SisVersionDefault']\n";
} elsif ($SisVersion !~ /^\d+\.\d+\.\d+$/) {
  die_with_usage("Bad version '$SisVersion'")
}

my $tempdir = tempdir( CLEANUP => 1 );

print "[temp directory '$tempdir']\n" if $Debug;

for my $file (@SisPl, @SisPm, @SisOther) {
  print "[copying file '$file']\n" if $Debug;
  die_with_usage("$0: File '$file': $!") unless -f $file;
  my $dir = dirname($file);
  do_system("mkdir $tempdir\\$dir") unless $dir eq '.';
  do_system("copy $file $tempdir");
}
if (@SisPl) {
    do_system("copy $SisPl[0] $tempdir\\default.pl")
	unless $SisPl[0] eq "default.pl";
}
for my $dir (@SisDir) {
  print "[copying directory '$dir']\n" if $Debug;
  do_system("copy $dir $tempdir");
}

my $SisVersionCommas = $SisVersion;

$SisVersionCommas =~ s/\./\,/g;

my @pkg;

push @pkg, qq[&EN;];
push @pkg, qq[#{"$AppName"},($SisUid),$SisVersionCommas];
push @pkg, qq[(0x101F6F88), 0, 0, 0, {"Series60ProductID"}];

my $OWD = getcwd();

$OWD =~ s!/!\\!g;

chdir($tempdir) or die "$0: chdir('$tempdir')\n";

if (@SisPl) {
  if (open(my $fi, "default.pl")) {
    my $fn = "default.pl.new";
    if (open(my $fo, ">$fn")) {
      while (<$fi>) {
	last unless /^\#/;
	print $fo $_;
      }
      print $fo "use lib qw(\\system\\apps\\$AppName \\system\\apps\\$AppName\\lib);\n";
      printf $fo qq[# %d "$SisPl[0]"\n], $.;
      print $fo $_;
      while (<$fi>) {
	print $fo $_;
      }
      close($fo);
    } else {
      die "$0: open '>$fn': $!\n";
    }
    close($fi);
    rename($fn, "default.pl") or die "$0: rename $fn default.pl: $!\n";
    # system("cat -nvet default.pl");
  } else {
    die "$0: open 'default.pl': $!\n";
  }
}


my @c;
find(
     sub {
       if (-f $_) {
	 $File::Find::name =~ s!^\./!!;
	 push @c, $File::Find::name;
       }
     }
     ,
     ".");

for my $i (sort @c) {
  my $j = $i;
  $j =~ s!/!\\!g;
  push @pkg, defined $Library ? qq["$j"-"!:\\System\\Libs\\Perl\\siteperl\\$Library\\$j"] : qq["$j"-"!:\\system\\apps\\$AppName\\$j"];
}

sub hex2data {
  local $_ = shift;
  my $data; 
  while (/([0-9a-f]{2})/ig) {
    $data .= chr(hex($1));
  }
  return $data;
}

my $APPHEX;
my $RSCHEX;

unless ($Library) {
  # If we package an application we will need both a launching native
  # Symbian application and a resource file for it.  The resource file
  # we can get easily from a stub but for the native app we need to
  # patch in the right Symbian app uids and executable checksums.

  &init_hex; # Initialized $APPHEX and $RSCHEX.

  my $app = hex2data($APPHEX);
  my $uidcrc;
  my $uids = "0x10000079 0x100039CE $SisUid";

  my $cmd = "uidcrc $uids |";

  if (open(my $fh, $cmd)) {
    my $line = <$fh>;
    close($fh);
    # 0x10000079 0x100039ce 0x0acebabe 0xc82b1900
    $line =~ s/\r?\n$//;
    if ($line =~ /^$uids (0x[0-9a-f]{8})$/i) {
      $uidcrc = hex($1);
    } else {
      die "$0: uidcrc returned '$line'\n";
    }
  } else {
    die qq[$0: open '$cmd' failed: $!\n];
  }

  my $uid    = hex($SisUid);

  my $oldchk = unpack('V', substr($app, 24, 4));
  my $newchk = ($uid + $oldchk) & 0xFFFFFFFF;

  # printf "# uid    = 0x%08x\n", $uid;
  # printf "# uidcrc = 0x%08x\n", $uidcrc;
  # printf "# oldchk = 0x%08x\n", $oldchk;
  # printf "# newchk = 0x%08x\n", $newchk;

  substr($app,  8, 4) = pack('V', $uid);
  substr($app, 12, 4) = pack('V', $uidcrc);
  substr($app, 24, 4) = pack('V', $newchk);
  
  my $UID_OFFSET = 0x0C7C; # This is where the uid is in the $app.
  substr($app, $UID_OFFSET, 4) = substr($app, 8, 4); # Copy the uid also here.

  if (open(my $fh, ">$AppName.app")) {
    binmode($fh);
    print $fh $app;
    close($fh);
  } else {
    die qq[$0: open '>$AppName.app' failed: $!\n];
  }

  push @pkg, qq["$AppName.app"-"!:\\system\\apps\\$AppName\\$AppName.app"];

  if (open(my $fh, ">$AppName.rsc")) {
    binmode($fh);
    print $fh hex2data($RSCHEX);
    close($fh);
  } else {
    die qq[$0: open '>$AppName.rsc' failed: $!\n];
  }
  push @pkg, qq["$AppName.rsc"-"!:\\system\\apps\\$AppName\\$AppName.rsc"];
}

if ($ShowPkg) {
  for my $l (@pkg) {
    print $l, "\r\n";
  }
} else {
  my $fn = "$AppName.pkg";
  if (open(my $fh, ">$fn")) {
    for my $l (@pkg) {
      print $fh "$l\r\n"; # Note CRLF!
    }
    close($fh);
  } else {
    die qq[$0: Failed to open "$fn" for writing: $!\n];
  }
  my $sis = "$AppName.SIS";
  unlink($sis);
  do_system("dir");
  do_system("makesis $fn");
  unless (-f $sis) {
    die qq[$0: failed to create "$sis"\n];
  }
  do_system("copy $AppName.sis $OWD");
  chdir($OWD);
  system("dir $sis");
  print "\n=== Now transfer $sis to your device ===\n";
}

exit(0);

sub init_hex {
  # This is Symbian application executable skeleton.
  # You can create the ...\epoc32\release\thumb\urel\foo.app
  # by compiling the PerlApp.cpp with PerlMinSample defined in PerlApp.h.
  # The following executable has been compiled using the Series 60 SDK 2.6
  # for Visual C.
  $APPHEX = <<__APP__;
7900 0010 ce39 0010 f615 2010 8581 1076
4550 4f43 0020 0000 05fc d15d 0000 0000
0100 bf00 0048 827a 9ee0 e000 0300 0001
5811 0000 0000 0000 0010 0000 0000 1000
0020 0000 0000 0000 0100 0000 0000 0010
0000 0000 0700 0000 d011 0000 0100 0000
140f 0000 7c00 0000 0000 0000 d411 0000
d414 0000 0000 0000 5e01 0000 00b5 00f0
d5f9 02bc 0847 0000 0148 0068 7047 0000
000c 0010 00b5 011c 0248 00f0 f5fc 01bc
0047 0000 200c 0010 10b5 84b0 041c 0021
00f0 f2f9 6846 211c 00f0 88fb 6846 00f0
07f9 011c 2166 201c 0022 0023 00f0 48fa
0020 6066 00f0 4cfa 0121 00f0 4ffa 04b0
10bc 01bc 0047 0000 30b5 041c 0d1c 1a48
6061 1a48 a061 1a48 e061 1a48 a064 1a48
e064 1a48 2060 216e 0029 0dd0 6068 00f0
63fb 216e 0029 05d0 0868 8268 081c 0321
00f0 8af9 0020 2066 606e 0028 03d0 00f0
b1fc 0020 6066 a16a 0029 05d0 0868 8268
081c 0321 00f0 78f9 201c 291c 00f0 aaf9
30bc 01bc 0047 0000 9c0e 0010 000f 0010
f00e 0010 d00e 0010 dc0e 0010 340c 0010
84b0 10b5 95b0 1790 1891 1992 1a93 0120
0021 0022 00f0 cefc 041c 14a9 01a8 00f0
87fc 0028 08d1 0090 201c 17a9 0222 0023
00f0 c6fc 00f0 82fc 00f0 86fc 15b0 10bc
08bc 04b0 1847 0000 f0b5 4746 80b4 324c
a544 071c 8846 0229 52d1 00f0 0bfb 011c
0a68 7ea8 126a 00f0 2ff9 8026 f600 6e44
301c 00f0 cdfa 2949 301c 7eaa 0023 00f0
cdfa c425 ed00 6d44 281c 00f0 cffa 244c
6c44 0021 2248 6844 0160 201c 0421 00f0
cbfa 301c 00f0 cefa 011c 201c 2a1c 00f0
cffa 0028 24d1 301c 00f0 c4fa 011c 8420
0001 6844 8022 5200 00f0 44fc 8521 0901
6944 6846 fc22 5200 00f0 42fc 8420 0001
6844 0068 0f49 6944 0968 0f4a 6a44 1268
0e4b 6b44 1b68 fff7 83ff 381c 00f0 c0fa
0020 4446 002c 00d1 0120 094b 9d44 08bc
9846 f0bc 02bc 0847 b4f5 ffff 040c 0010
480a 0000 4408 0000 4808 0000 4c08 0000
4c0a 0000 00b5 021c 8020 4000 8142 02d0
0348 8142 06d1 101c 00f0 9afa 05e0 0000
c10b 0000 0120 fff7 e5fe 01bc 0047 0000
10b5 00f0 07f8 041c 00f0 00fc 201c 10bc
02bc 0847 30b5 051c 3020 00f0 fdfb 041c
002c 05d0 00f0 48f9 0748 6060 0748 2060
201c 00f0 f7fb 201c 291c 00f0 09f8 201c
30bc 02bc 0847 0000 ac0c 0010 bc0c 0010
30b5 041c 0d1c 00f0 35f9 201c 291c 00f0
37f9 2068 016a 201c 00f0 7cf8 30bc 01bc
0047 0000 30b5 84b0 041c 00f0 2ff9 051c
6846 211c 00f0 30f9 2868 b830 0268 281c
6946 00f0 69f8 04b0 30bc 01bc 0047 0000
30b5 051c 2420 00f0 b7fb 041c 002c 04d0
291c 00f0 95f8 0348 2060 201c 30bc 02bc
0847 0000 6c0d 0010 70b5 8820 4000 00f0
a3fb 061c 002e 18d0 00f0 28fa 0d48 b064
0d48 f064 0d4d 7561 0d4c b461 0d4b f361
0d4a b264 0d49 f164 0d48 3060 0d48 3060
301c 6830 5021 00f0 93fb 301c 70bc 02bc
0847 0000 040e 0010 100e 0010 9c0e 0010
000f 0010 f00e 0010 d00e 0010 dc0e 0010
240e 0010 340c 0010 10b5 8b20 8000 00f0
7dfb 041c 002c 03d0 00f0 f6f9 0248 2060
201c 10bc 02bc 0847 c80d 0010 0020 7047
0047 7047 0847 7047 1047 7047 1847 7047
2047 7047 2847 7047 3047 7047 3847 7047
4047 7047 4847 7047 5047 7047 5847 7047
6047 7047 7047 7047 014b 1b68 1847 c046
140f 0010 014b 1b68 1847 c046 1c0f 0010
014b 1b68 1847 c046 200f 0010 014b 1b68
1847 c046 180f 0010 014b 1b68 1847 c046
240f 0010 014b 1b68 1847 c046 5c0f 0010
014b 1b68 1847 c046 600f 0010 014b 1b68
1847 c046 3c0f 0010 014b 1b68 1847 c046
4c0f 0010 014b 1b68 1847 c046 2c0f 0010
014b 1b68 1847 c046 340f 0010 40b4 024e
3668 b446 40bc 6047 280f 0010 014b 1b68
1847 c046 580f 0010 014b 1b68 1847 c046
540f 0010 014b 1b68 1847 c046 480f 0010
014b 1b68 1847 c046 440f 0010 40b4 024e
3668 b446 40bc 6047 400f 0010 014b 1b68
1847 c046 300f 0010 014b 1b68 1847 c046
380f 0010 014b 1b68 1847 c046 500f 0010
40b4 024e 3668 b446 40bc 6047 680f 0010
014b 1b68 1847 c046 e80f 0010 014b 1b68
1847 c046 0410 0010 014b 1b68 1847 c046
f40f 0010 014b 1b68 1847 c046 780f 0010
014b 1b68 1847 c046 e00f 0010 014b 1b68
1847 c046 ec0f 0010 014b 1b68 1847 c046
c00f 0010 014b 1b68 1847 c046 b40f 0010
014b 1b68 1847 c046 ac0f 0010 014b 1b68
1847 c046 d80f 0010 014b 1b68 1847 c046
d40f 0010 014b 1b68 1847 c046 700f 0010
014b 1b68 1847 c046 640f 0010 014b 1b68
1847 c046 bc0f 0010 014b 1b68 1847 c046
0010 0010 014b 1b68 1847 c046 cc0f 0010
014b 1b68 1847 c046 dc0f 0010 014b 1b68
1847 c046 9c0f 0010 014b 1b68 1847 c046
b00f 0010 014b 1b68 1847 c046 940f 0010
014b 1b68 1847 c046 800f 0010 014b 1b68
1847 c046 840f 0010 014b 1b68 1847 c046
a40f 0010 014b 1b68 1847 c046 900f 0010
014b 1b68 1847 c046 8c0f 0010 014b 1b68
1847 c046 7c0f 0010 014b 1b68 1847 c046
e40f 0010 014b 1b68 1847 c046 b80f 0010
014b 1b68 1847 c046 740f 0010 014b 1b68
1847 c046 6c0f 0010 014b 1b68 1847 c046
c40f 0010 014b 1b68 1847 c046 c80f 0010
014b 1b68 1847 c046 a80f 0010 014b 1b68
1847 c046 880f 0010 014b 1b68 1847 c046
980f 0010 014b 1b68 1847 c046 d00f 0010
014b 1b68 1847 c046 a00f 0010 014b 1b68
1847 c046 0810 0010 014b 1b68 1847 c046
0c10 0010 014b 1b68 1847 c046 f80f 0010
014b 1b68 1847 c046 fc0f 0010 014b 1b68
1847 c046 1410 0010 014b 1b68 1847 c046
1010 0010 014b 1b68 1847 c046 f00f 0010
014b 1b68 1847 c046 2c10 0010 40b4 024e
3668 b446 40bc 6047 2410 0010 014b 1b68
1847 c046 2810 0010 014b 1b68 1847 c046
1810 0010 014b 1b68 1847 c046 2010 0010
014b 1b68 1847 c046 1c10 0010 014b 1b68
1847 c046 4010 0010 014b 1b68 1847 c046
b010 0010 014b 1b68 1847 c046 3010 0010
014b 1b68 1847 c046 6410 0010 014b 1b68
1847 c046 fc10 0010 014b 1b68 1847 c046
f810 0010 014b 1b68 1847 c046 1011 0010
014b 1b68 1847 c046 c010 0010 014b 1b68
1847 c046 7010 0010 014b 1b68 1847 c046
8010 0010 014b 1b68 1847 c046 e010 0010
014b 1b68 1847 c046 ac10 0010 014b 1b68
1847 c046 a010 0010 014b 1b68 1847 c046
5010 0010 014b 1b68 1847 c046 8410 0010
014b 1b68 1847 c046 ec10 0010 014b 1b68
1847 c046 c410 0010 014b 1b68 1847 c046
c810 0010 014b 1b68 1847 c046 4c10 0010
014b 1b68 1847 c046 9c10 0010 014b 1b68
1847 c046 3810 0010 014b 1b68 1847 c046
b810 0010 014b 1b68 1847 c046 6c10 0010
014b 1b68 1847 c046 3410 0010 014b 1b68
1847 c046 cc10 0010 014b 1b68 1847 c046
9410 0010 014b 1b68 1847 c046 5410 0010
014b 1b68 1847 c046 6010 0010 014b 1b68
1847 c046 a410 0010 014b 1b68 1847 c046
d810 0010 014b 1b68 1847 c046 e410 0010
014b 1b68 1847 c046 d010 0010 014b 1b68
1847 c046 6810 0010 014b 1b68 1847 c046
9010 0010 014b 1b68 1847 c046 8c10 0010
014b 1b68 1847 c046 b410 0010 014b 1b68
1847 c046 bc10 0010 014b 1b68 1847 c046
e810 0010 014b 1b68 1847 c046 0411 0010
40b4 024e 3668 b446 40bc 6047 8810 0010
014b 1b68 1847 c046 dc10 0010 014b 1b68
1847 c046 4810 0010 014b 1b68 1847 c046
7410 0010 014b 1b68 1847 c046 3c10 0010
40b4 024e 3668 b446 40bc 6047 d410 0010
014b 1b68 1847 c046 5c10 0010 014b 1b68
1847 c046 5810 0010 014b 1b68 1847 c046
9810 0010 014b 1b68 1847 c046 0011 0010
014b 1b68 1847 c046 4410 0010 40b4 024e
3668 b446 40bc 6047 a810 0010 014b 1b68
1847 c046 7810 0010 014b 1b68 1847 c046
0811 0010 014b 1b68 1847 c046 0c11 0010
40b4 024e 3668 b446 40bc 6047 7c10 0010
014b 1b68 1847 c046 f410 0010 014b 1b68
1847 c046 f010 0010 014b 1b68 1847 c046
1c11 0010 014b 1b68 1847 c046 3c11 0010
014b 1b68 1847 c046 2c11 0010 014b 1b68
1847 c046 3011 0010 014b 1b68 1847 c046
2011 0010 014b 1b68 1847 c046 3411 0010
014b 1b68 1847 c046 1411 0010 014b 1b68
1847 c046 2411 0010 014b 1b68 1847 c046
1811 0010 014b 1b68 1847 c046 2811 0010
014b 1b68 1847 c046 3811 0010 014b 1b68
1847 c046 4011 0010 014b 1b68 1847 c046
4411 0010 014b 1b68 1847 c046 4811 0010
40b4 024e 3668 b446 40bc 6047 4c11 0010
7047 0000 00b5 044a 4260 044a 0260 fff7
11fe 01bc 0047 0000 ac0c 0010 bc0c 0010
00b5 fff7 85ff 01bc 0047 0000 00b5 fff7
85ff 01bc 0047 0000 00b5 fff7 79ff 01bc
0047 0000 10b5 81b0 039c 1438 0094 fff7
07ff 01b0 10bc 01bc 0047 0000 00b5 1438
fff7 d8fc 01bc 0047 00b5 1438 fff7 00ff
01bc 0047 00b5 1838 fff7 52ff 02bc 0847
00b5 1c38 fff7 46ff 02bc 0847 00b5 1c38
fff7 3aff 02bc 0847 00b5 0438 fff7 c4fd
02bc 0847 00b5 0438 fff7 b8fd 02bc 0847
00b5 4838 fff7 a2fc 01bc 0047 00b5 4c38
fff7 a2fc 01bc 0047 ffff ffff 0000 0000
ffff ffff 0000 0000 000c 0010 200c 0010
9c0e 0010 000f 0010 f00e 0010 d00e 0010
dc0e 0010 340c 0010 040c 0010 ac0c 0010
bc0c 0010 6c0d 0010 040e 0010 100e 0010
9c0e 0010 000f 0010 f00e 0010 d00e 0010
dc0e 0010 240e 0010 340c 0010 300d 0010
c80d 0010 ac0c 0010 bc0c 0010 f615 2010
0a00 0000 6400 6500 6600 6100 7500 6c00
7400 2e00 7000 6c00 0000 0000 0700 0000
5000 6500 7200 6c00 4d00 6900 6e00 0000
0000 0000 0000 0000 6d00 0010 4104 0010
4d04 0010 9907 0010 a507 0010 7506 0010
8106 0010 5904 0010 8d06 0010 6504 0010
b107 0010 9906 0010 a506 0010 2d00 0010
bd07 0010 3d01 0010 c907 0010 2902 0010
d507 0010 e107 0010 ed07 0010 7104 0010
f907 0010 0508 0010 1108 0010 1d08 0010
8104 0010 8d04 0010 fcff ffff 0000 0000
690b 0010 5d0b 0010 0000 0000 0000 0000
c90a 0010 4905 0010 5505 0010 6105 0010
6d05 0010 7905 0010 8505 0010 9105 0010
9d05 0010 a905 0010 b505 0010 c105 0010
cd05 0010 d905 0010 e505 0010 f105 0010
fd05 0010 0906 0010 1506 0010 2106 0010
2d06 0010 3906 0010 4506 0010 5106 0010
c902 0010 5d06 0010 6906 0010 0000 0000
0000 0000 e50a 0010 9904 0010 2908 0010
9d0a 0010 a504 0010 3508 0010 ed03 0010
4108 0010 4d08 0010 5908 0010 6508 0010
7108 0010 9d0a 0010 0000 0000 0000 0000
f10a 0010 7d08 0010 8908 0010 f903 0010
9508 0010 a108 0010 ad08 0010 b908 0010
c508 0010 c50a 0010 d108 0010 dd08 0010
0504 0010 1104 0010 e908 0010 f508 0010
0109 0010 1d03 0010 b104 0010 0d09 0010
1909 0010 0000 0000 0000 0000 fd0a 0010
9904 0010 2908 0010 0d00 0010 a504 0010
3508 0010 ed03 0010 4108 0010 4d08 0010
5908 0010 6508 0010 7108 0010 f502 0010
0000 0000 0000 0000 9d0a 0010 0000 0000
0000 0000 9d0a 0010 b106 0010 bd06 0010
0000 0000 0000 0000 2904 0010 4104 0010
4d04 0010 9907 0010 a507 0010 7506 0010
8106 0010 5904 0010 8d06 0010 6504 0010
b107 0010 9906 0010 a506 0010 a509 0010
bd07 0010 b109 0010 c907 0010 c109 0010
d507 0010 e107 0010 ed07 0010 7104 0010
f907 0010 0508 0010 1108 0010 1d08 0010
8104 0010 8d04 0010 ecff ffff 0000 0000
210b 0010 4109 0010 4d09 0010 5909 0010
6509 0010 7509 0010 8109 0010 090b 0010
8d09 0010 2d0b 0010 9909 0010 b8ff ffff
0000 0000 750b 0010 b4ff ffff 0000 0000
810b 0010 b106 0010 bd06 0010 e4ff ffff
0000 0000 510b 0010 450b 0010 e8ff ffff
0000 0000 390b 0010 c906 0010 d506 0010
0300 0000 0600 0000 1b00 0000 4700 0000
3f00 0000 ee02 0000 f502 0000 2203 0000
2303 0000 2503 0000 2803 0000 b504 0000
b604 0000 d204 0000 e604 0000 f304 0000
4405 0000 4805 0000 0008 0000 0508 0000
0300 0000 0c00 0000 1c00 0000 1d00 0000
2100 0000 2800 0000 4200 0000 4800 0000
4a00 0000 5200 0000 5400 0000 5500 0000
5700 0000 5a00 0000 5f00 0000 6000 0000
6400 0000 6500 0000 8a00 0000 8b00 0000
8f00 0000 9300 0000 9900 0000 a000 0000
ad00 0000 b100 0000 b900 0000 bb00 0000
c500 0000 c800 0000 d000 0000 d600 0000
dd00 0000 df00 0000 e200 0000 e800 0000
ec00 0000 ff00 0000 0001 0000 1401 0000
1501 0000 2401 0000 2501 0000 3801 0000
3a01 0000 1200 0000 2700 0000 3300 0000
b700 0000 e300 0000 e600 0000 1100 0000
1400 0000 1e00 0000 1f00 0000 2000 0000
2800 0000 3000 0000 3100 0000 3300 0000
3400 0000 4000 0000 4100 0000 4200 0000
4300 0000 4400 0000 4700 0000 4a00 0000
4b00 0000 4c00 0000 5000 0000 5100 0000
5200 0000 5400 0000 5600 0000 6400 0000
7400 0000 7900 0000 7a00 0000 7c00 0000
8200 0000 8500 0000 8600 0000 8c00 0000
8e00 0000 8f00 0000 9200 0000 9300 0000
9500 0000 9600 0000 9700 0000 9b00 0000
9d00 0000 a100 0000 b300 0000 c600 0000
c800 0000 cc00 0000 ce00 0000 d500 0000
d600 0000 de00 0000 e000 0000 e200 0000
fd00 0000 0801 0000 2201 0000 2801 0000
0200 0000 0300 0000 2903 0000 3803 0000
3c03 0000 5a03 0000 7c04 0000 8c04 0000
0205 0000 0305 0000 e005 0000 2e06 0000
4b06 0000 0400 0000 8905 0000 0000 0000
8d03 0000 0003 0000 7802 0000 0400 0000
0300 0000 0600 0000 1b00 0000 4700 0000
8d02 0000 1000 0000 3f00 0000 ee02 0000
f502 0000 2203 0000 2303 0000 2503 0000
2803 0000 b504 0000 b604 0000 d204 0000
e604 0000 f304 0000 4405 0000 4805 0000
0008 0000 0508 0000 a102 0000 2d00 0000
0300 0000 0c00 0000 1c00 0000 1d00 0000
2100 0000 2800 0000 4200 0000 4800 0000
4a00 0000 5200 0000 5400 0000 5500 0000
5700 0000 5a00 0000 5f00 0000 6000 0000
6400 0000 6500 0000 8a00 0000 8b00 0000
8f00 0000 9300 0000 9900 0000 a000 0000
ad00 0000 b100 0000 b900 0000 bb00 0000
c500 0000 c800 0000 d000 0000 d600 0000
dd00 0000 df00 0000 e200 0000 e800 0000
ec00 0000 ff00 0000 0001 0000 1401 0000
1501 0000 2401 0000 2501 0000 3801 0000
3a01 0000 b402 0000 0600 0000 1200 0000
2700 0000 3300 0000 b700 0000 e300 0000
e600 0000 c802 0000 3900 0000 1100 0000
1400 0000 1e00 0000 1f00 0000 2000 0000
2800 0000 3000 0000 3100 0000 3300 0000
3400 0000 4000 0000 4100 0000 4200 0000
4300 0000 4400 0000 4700 0000 4a00 0000
4b00 0000 4c00 0000 5000 0000 5100 0000
5200 0000 5400 0000 5600 0000 6400 0000
7400 0000 7900 0000 7a00 0000 7c00 0000
8200 0000 8500 0000 8600 0000 8c00 0000
8e00 0000 8f00 0000 9200 0000 9300 0000
9500 0000 9600 0000 9700 0000 9b00 0000
9d00 0000 a100 0000 b300 0000 c600 0000
c800 0000 cc00 0000 ce00 0000 d500 0000
d600 0000 de00 0000 e000 0000 e200 0000
fd00 0000 0801 0000 2201 0000 2801 0000
de02 0000 0d00 0000 0200 0000 0300 0000
2903 0000 3803 0000 3c03 0000 5a03 0000
7c04 0000 8c04 0000 0205 0000 0305 0000
e005 0000 2e06 0000 4b06 0000 f202 0000
0200 0000 0400 0000 8905 0000 4150 5041
5243 5b31 3030 3033 6133 645d 2e44 4c4c
0041 564b 4f4e 5b31 3030 3035 3663 365d
2e44 4c4c 0043 4f4e 455b 3130 3030 3361
3431 5d2e 444c 4c00 4546 5352 565b 3130
3030 3339 6534 5d2e 444c 4c00 4549 4b43
4f52 455b 3130 3030 3438 3932 5d2e 444c
4c00 4555 5345 525b 3130 3030 3339 6535
5d2e 444c 4c00 5045 524c 3539 332e 444c
4c00 0000 c002 0000 5c01 0000 0000 0000
c002 0000 1430 2830 dc30 e030 e430 e830
ec30 f030 1032 9c32 a032 1833 6833 6c33
7033 7433 7833 7c33 8033 8433 8833 ac33
f433 0034 0c34 1834 2434 3034 3c34 4834
5434 6034 6c34 7c34 8834 9434 a034 ac34
bc34 c834 d434 e034 f034 fc34 0835 1435
2035 2c35 3835 4435 5035 5c35 6835 7435
8035 8c35 9835 a435 b035 bc35 c835 d435
e035 ec35 f835 0436 1036 1c36 2836 3436
4036 4c36 5836 6436 7036 7c36 8836 9436
a036 ac36 b836 c436 d036 dc36 e836 f436
0037 0c37 1c37 2837 3437 4037 4c37 5837
6437 7037 7c37 8837 9437 a037 ac37 b837
c437 d037 dc37 e837 f437 0038 0c38 1838
2438 3038 3c38 4838 5438 6038 6c38 7838
8438 9038 9c38 a838 b438 c038 cc38 d838
e438 f038 fc38 0839 1439 2039 3039 3c39
4839 5439 6039 7039 7c39 8839 9439 a039
ac39 bc39 c839 d439 e039 f039 fc39 083a
143a 203a 2c3a 383a 443a 503a 5c3a 683a
743a 803a 8c3a 983a a43a b03a c03a dc3a
e03a 9c3b a03b a43b a83b ac3b b03b b43b
b83b bc3b c03b c43b c83b cc3b d03b d43b
d83b dc3b e03b e43b e83b ec3b f03b f43b
f83b fc3b 3c3c 403c 443c 483c 4c3c 503c
543c 583c 5c3c 603c 643c 683c 6c3c 703c
743c 783c 7c3c 803c 843c 883c 8c3c 903c
943c 983c 9c3c a03c a43c a83c b43c b83c
c43c c83c cc3c d03c d43c d83c dc3c e03c
e43c e83c ec3c f03c f43c f83c fc3c 003d
043d 083d 0c3d 103d 143d 183d 1c3d 203d
243d 283d 2c3d 383d 3c3d 403d 443d 483d
4c3d 503d 543d 583d 5c3d 603d 643d 683d
743d 783d 7c3d 803d 843d 883d 8c3d 903d
943d 983d 9c3d a03d a43d a83d ac3d b03d
b43d b83d bc3d c03d c43d d03d d43d d83d
dc3d e03d e43d e83d ec3d f03d f43d f83d
fc3d 003e 0c3e 183e 1c3e 203e 2c3e 303e
343e 383e 3c3e 403e 443e 483e 4c3e 503e
543e 583e 5c3e 603e 643e 683e 6c3e 703e
743e 783e 7c3e 803e 843e 883e 8c3e 903e
943e 983e a43e a83e ac3e b03e b43e b83e
bc3e c03e c43e c83e cc3e d83e e43e e83e
ec3e f83e fc3e 083f 0c3f 103f
__APP__

  # This is Symbian application resource skeleton.
  # You can create the ...\epoc32\data\z\system\apps\PerlApp\PerlApp.rsc
  # by compiling the PerlApp.cpp.
  # The following resource has been compiled using the Series 60 SDK 2.6
  # for Visual C.
  $RSCHEX = <<__RSC__;
6b4a 1f10 0000 0000 5fde 0400 1ca3 60de
01b8 0010 0004 0000 0001 f0e5 4d00 0000
0004 f0e5 4d00 0000 0000 0000 001a 00cc
0800 0000 0001 0005 f0e5 4d00 0000 0000
00ff ffff ff00 0000 0000 0000 0000 0f05
0000 0400 0000 0000 0000 0000 0005 0541
626f 7574 1700 00ff ffff ff00 0000 0001
0400 0000 0000 0000 0000 0004 0454 696d
6517 0000 ffff ffff 0000 0000 0204 0000
0000 0000 0000 0000 0303 5275 6e17 0000
ffff ffff 0000 0000 0304 0000 0000 0000
0000 0000 0808 4f6e 656c 696e 6572 1700
00ff ffff ff00 0000 0004 0400 0000 0000
0000 0000 0009 0943 6f70 7972 6967 6874
0e00 00ff ffff ff00 0000 0000 0000 0001
2000 0000 0000 0000 1400 cc08 0100 6816
0001 0000 0000 0001 0000 0000 ffff ffff
00ff ffff ff00 0000 0000 0000 00ff ff00
0000 0000 0000 0120 0000 0000 0000 0024
00cc 0801 0068 1600 0100 0000 0000 0100
0000 00ff ffff ff00 ffff ffff 0000 0000
0000 0000 ffff 0000 0000 0000 0041 2200
0000 0000 0000 1400 cc08 0100 6916 0000
0500 0000 0001 0000 0000 0000 0000 0100
0000 0400 0700 0800 ff02 0100 ffff ffff
0000 0000 0000 0000 0000 ffff 0000 0000
0000 0041 2200 0000 0000 0000 1400 cc08
0100 7416 0007 0000 0000 0054 1600 00ff
ffff ff00 0000 0000 00ff ff00 0000 0000
0000 0000 0000 0015 001d 001d 0035 004d
00ef 0026 015d 01a3 01d2 01d7 01
__RSC__
}
