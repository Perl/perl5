#!/usr/bin/perl

use File::Find;
use Cwd;

$VERSION="5.005";
$PATCH=62;
$EPOC_VERSION=11;
$CROSSCOMPILEPATH="Y:";


sub filefound {
    my $f = $File::Find::name;
    
    return if ( $f =~ /ExtUtils|unicode|CGI|CPAN|Net|IPC|User|DB.pm/i);
    my $back = $f;

    $back =~ s|$CROSSCOMPILEPATH||;

    $back =~ s|/|\\|g;

    my $psiback = $back;

    $psiback =~ s/\\perl$VERSION\\perl$VERSION\_$PATCH\\lib\\/\\perl\\lib\\$VERSION$PATCH\\/i;

    print OUT "\"$back\"-\"!:$psiback\"\n"  if ( -f $f );
;
}



    

open OUT,">perl.pkg";

print OUT "#{\"perl$VERSION\"},(0x100051d8),$PATCH,$EPOC_VERSION,0\n";

print OUT "\"\\epoc32\\release\\marm\\rel\\perl.exe\"-\"!:\\perl.exe\"\n";
print OUT "\"\\perl$VERSION\\perl${VERSION}_$PATCH\\epoc\\Config.pm\"-\"!:\\perl\\lib\\$VERSION$PATCH\\Config.pm\"\n";

find(\&filefound, cwd.'/lib');

print OUT "@\"\\epoc32\\release\\marm\\rel\\stdlib.sis\",(0x010002c3)\n"


