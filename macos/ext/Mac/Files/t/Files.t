Perl -Sx "{0}" {"Parameters"}; Exit {Status}

#!perl
#
# Files.t - Demonstrate a few file calls.
#

use Mac::Files;

print FindFolder(kOnSystemDisk, kSystemFolderType), "\n";
$info = FSpGetCatInfo("::Makefile.mk");
print $info->ioDrMdDat, "\n";
print $info->ioFlMdDat, "\n";
$finfo = $info->ioFlFndrInfo;
print $finfo->fdType, "\n";
