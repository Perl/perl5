#!/usr/bin/perl

use File::Find;
use Cwd;

$VERSION="5.7";
$PATCH="1";
$EPOC_VERSION=27;


sub filefound {

  my $f = $File::Find::name;
    
  return if ( $f =~ /CVS|unicode|CPAN|ExtUtils|IPC|User|DB.pm|\.a$|\.ld$|\.exists$|\.pod$/i);
  my $back = $f;

  my $psiback = $back;

  $psiback =~ s|.*/lib/|\\perl\\lib\\$VERSION.$PATCH\\|;

  print OUT "\"$back\"-\"!:$psiback\"\n"  if ( -f $f );
}

open OUT,">perl.pkg";

print OUT "#{\"perl$VERSION\"},(0x100051d8),$PATCH,$EPOC_VERSION,0\n";
print OUT "\"" . cwd . "/Artistic.txt\"-\"\",FT,TA\n";
print OUT "\"" . cwd . "/perl\"-\"!:\\system\\programs\\perl.exe\"\n";

find(\&filefound, cwd.'/lib');
# print OUT "@\"G:\\lib\\stdlib.sis\",(0x0100002c3)\n";

open IN,  "<Artistic";
open OUT, ">Artistic.txt";
while (my $line = <IN>) {
  chomp $line;
  print OUT "$line\x13\x10";
}

close IN;
close OUT;

