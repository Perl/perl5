#!/usr/bin/perl

use File::Find;
use Cwd;

$VERSION="5.005";
$PATCH=63;
$EPOC_VERSION=16;
$CROSSCOMPILEPATH=cwd;
$CROSSREPLACEPATH="H:\\devel\\perl5.005_63";


sub filefound {
    my $f = $File::Find::name;
    
    return if ( $f =~ /unicode|CPAN|ExtUtils|IPC|User|DB.pm|\.a$|\.ld$|\.exists$/i);
    my $back = $f;

    $back =~ s|$CROSSCOMPILEPATH||;

    $back =~ s|/|\\|g;

    my $psiback = $back;

    $psiback =~ s/\\lib\\/\\perl\\lib\\$VERSION$PATCH\\/i;

    print OUT "\"$CROSSREPLACEPATH$back\"-\"!:$psiback\"\n"  if ( -f $f );
;
}

open OUT,">perl.pkg";

print OUT "#{\"perl$VERSION\"},(0x100051d8),$PATCH,$EPOC_VERSION,0\n";

print OUT "\"$CROSSREPLACEPATH\\perlmain.exe\"-\"!:\\perl.exe\"\n";

find(\&filefound, cwd.'/lib');
print OUT "@\"G:\\lib\\stdlib.sis\",(0x010002c3)\n"


