#!./miniperl
#
# Create perlmain.c from miniperlmain.c, adding code to boot the
# extensions listed on the command line.
#

if (-f 'miniperlmain.c') { $dir = ''; }
elsif (-f '../miniperlmain.c') { $dir = '../'; }
else { die "$0: Can't find miniperlmain.c\n"; }

open (IN,"${dir}miniperlmain.c")
  || die "$0: Can't open ${dir}miniperlmain.c: $!\n";
open (OUT,">${dir}perlmain.c")
  || die "$0: Can't open ${dir}perlmain.c: $!\n";

while (<IN>) {
  s/INTERN\.h/EXTERN\.h/;
  print OUT;
  last if /Do not delete this line--writemain depends on it/;
}
$ok = !eof(IN);
close IN;

if (!$ok) {
  close OUT;
  unlink "${dir}perlmain.c";
  die "$0: Can't find marker line in ${dir}miniperlmain.c - aborting\n";
}


if ($#ARGV > -1) {
  print OUT "    char *file = __FILE__;\n";
}

foreach $ext (@ARGV) {
  print OUT "extern void	boot_${ext} _((CV* cv));\n"
}

foreach $ext (@ARGV) {
  print "Adding $ext . . .\n";
  if ($ext eq 'DynaLoader') {
    # Must NOT install 'DynaLoader::boot_DynaLoader' as 'bootstrap'!
    # boot_DynaLoader is called directly in DynaLoader.pm
    print OUT "    newXS(\"${ext}::boot_${ext}\", boot_${ext}, file);\n"
  }
  else {
    print OUT "    newXS(\"${ext}::bootstrap\", boot_${ext}, file);\n"
  }
}

print OUT "}\n";
close OUT;
