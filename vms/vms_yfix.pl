# This script takes the output produced from perly.y by byacc and
# the perly.fixer shell script (i.e. the perly.c and perly.h built
# for Unix systems) and patches them to produce copies containing
# appropriate declarations for VMS handling of global symbols.
#
# If it finds that the input files are already patches for VMS,
# it just copies the input to the output.
#
# Revised 26-May-1995 by Charles Bailey  bailey@genetics.upenn.edu

($cinfile,$hinfile,$coutfile,$houtfile) = @ARGV;

open C,$cinfile or die "Can't read $cinfile: $!\n";
open COUT, ">$coutfile" or die "Can't create $coutfile: $!\n";
while (<C>) {
  if (/^dEXT/) {  # we've already got a fixed copy
    print COUT $_,<C>;
    last;
  }
  # add the dEXT tag to definitions of global vars, so we'll insert
  # a globaldef when perly.c is compiled
  s/^(short|int|YYSTYPE|char \*)\s*yy/dEXT $1 yy/;
  print COUT;
}
close C;
close COUT;

open H,$hinfile  or die "Can't read $hinfile: $!\n";
open HOUT, ">$houtfile" or die "Can't create $houtfile: $!\n";
$hfixed = 0;  # keep -w happy
while (<H>) {
  $hfixed = /globalref/ unless $hfixed;  # we've already got a fixed copy
  next if /^extern YYSTYPE yylval/;  # we've got a Unix version, and this
                                     # is what we want to replace
  print HOUT;
}
close H;

print HOUT <<'EODECL' unless $hfixed;
#ifndef vax11c
  extern YYSTYPE yylval;
#else
  globalref YYSTYPE yylval;
#endif
EODECL

close HOUT;
