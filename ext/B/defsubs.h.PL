#!perl
my ($out) = __FILE__ =~ /(^.*)\.PL/;
open(OUT,">$out") || die "Cannot open $file:$!";
foreach my $const (qw(AVf_REAL 
		      HEf_SVKEY
                      SVf_IOK SVf_NOK SVf_POK SVf_ROK SVp_IOK SVp_POK ))
 {
  doconst($const);
 }
foreach my $file (qw(op.h cop.h))
 {
  open(OPH,"../../$file") || die "Cannot open ../../$file:$!";
  while (<OPH>)
   {  
    doconst($1) if (/#define\s+(\w+)\s+([\(\)\|\dx]+)\s*(?:$|\/\*)/);
   }  
  close(OPH);
 }
close(OUT);
               
sub doconst
{
 my $sym = shift;
 my $l = length($sym);
 print OUT <<"END";
 newCONSTSUB(stash,"$sym",newSViv($sym)); 
 av_push(export_ok,newSVpv("$sym",$l));
END
}
