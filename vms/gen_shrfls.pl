# Create global symbol declarations, transfer vector, and
# linker options files for PerlShr.
#
# Input:
#    $cflags - command line qualifiers passed to cc when preprocesing perl.h
#        Note: A rather simple-minded attempt is made to restore quotes to
#        a /Define clause - use with care.
#    $objsuffix - file type (including '.') used for object files.
#
# Output:
#    PerlShr_Attr.Opt - linker options file which speficies that global vars
#        be placed in NOSHR,WRT psects.  Use when linking any object files
#        against PerlShr.Exe, since cc places global vars in SHR,WRT psects
#        by default.
#    PerlShr_Sym.Opt - declares universal symbols for PerlShr.Exe
#    Perlshr_Gbl*.Mar, Perlshr_Gbl*.Obj (VAX  only) - declares global symbols
#        for global vars (done here because gcc can't globaldef) and creates
#        transfer vectors for routines on a VAX.
#    PerlShr_Gbl.Opt (VAX only) - list of PerlShr_Gbl*.Obj, used for input
#        to the linker when building PerlShr.Exe.
#
# To do:
#   - figure out a good way to collect global vars in one psect, given that
#     we can't use globaldef because of gcc.
#   - then, check for existing files and preserve symbol and transfer vector
#     order for upward compatibility
#   - then, add GSMATCH to options file - but how do we insure that new
#     library has everything old one did
#     (i.e. /Define=DEBUGGING,EMBED,MULTIPLICITY)?
#
# Author: Charles Bailey  bailey@genetics.upenn.edu
# Revised: 21-Sep-1994

require 5.000;

$debug = $ENV{'GEN_SHRFLS_DEBUG'};
$cc_cmd = shift @ARGV;
print "Input \$cc_cmd: \\$cc_cmd\\\n" if $debug;
$docc = ($cc_cmd !~ /~~NOCC~~/);
print "\$docc = $docc\n" if $debug;

if ($docc) {
  # put quotes back onto defines - they were removed by DCL on the way in
  if (($prefix,$defines,$suffix) =
         ($cc_cmd =~ m#(.*)/Define=(.*?)([/\s].*)#i)) {
    $defines =~ s/^\((.*)\)$/$1/;
    @defines = split(/,/,$defines);
    $cc_cmd = "$prefix/Define=(" . join(',',grep($_ = "\"$_\"",@defines)) 
              . ')' . $suffix;
  }
  print "Filtered \$cc_cmd: \\$cc_cmd\\\n" if $debug;

  if (-f 'perl.h') { $dir = '[]'; }
  elsif (-f '[-]perl.h') { $dir = '[-]'; }
  else { die "$0: Can't find perl.h\n"; }
}
else { ($cpp_file) = ($cc_cmd =~ /~~NOCC~~(.*)/) }

$objsuffix = shift @ARGV;
print "\$objsuffix: \\$objsuffix\\\n" if $debug;

# Someday, we'll have $GetSyI built into perl . . .
$isvax = `\$ Write Sys\$Output F\$GetSyI(\"HW_MODEL\")` <= 1024;
print "\$isvax: \\$isvax\\\n" if $debug;

sub scan_var {
  my($line) = @_;

  print "\tchecking for global variable\n" if $debug;
  $line =~ s/INIT\(.*\)//;
  $line =~ s/\[.*//;
  $line =~ s/=.*//;
  $line =~ s/\W*;?\s*$//;
  print "\tfiltered to \\$line\\\n" if $debug;
  if ($line =~ /(\w+)$/) {
    print "\tvar name is \\$1\\\n" if $debug;
   $vars{$1}++;
  }
}

sub scan_func {
  my($line) = @_;

  print "\tchecking for global routine\n" if $debug;
  if ( /(\w+)\s+\(/ ) {
    print "\troutine name is \\$1\\\n" if $debug;
    if ($1 eq 'main' || $1 eq 'perl_init_ext') {
      print "\tskipped\n" if $debug;
    }
    else { $funcs{$1}++ }
  }
}

if ($docc) {
  open(CPP,"${cc_cmd}/NoObj/PreProc=Sys\$Output ${dir}perl.h|")
    or die "$0: Can't preprocess ${dir}perl.h: $!\n";
}
else {
  open(CPP,"$cpp_file") or die "$0: Can't read $cpp_file: $!\n";
}
LINE: while (<CPP>) {
  while (/^#.*vmsish\.h/i .. /^#.*perl\.h/i) {
    while (/__VMS_PROTOTYPES__/i .. /__VMS_SEPYTOTORP__/i) {
      print "vms_proto>> $_" if $debug;
      &scan_func($_);
      if (/^EXT/) { &scan_var($_); }
      last LINE unless $_ = <CPP>;
    }
    print "vmsish.h>> $_" if $debug;
    if (/^EXT/) { &scan_var($_); }
    last LINE unless $_ = <CPP>;
  }    
  while (/^#.*opcode\.h/i .. /^#.*perl\.h/i) {
    print "opcode.h>> $_" if $debug;
    if (/^OP \*\s/) { &scan_func($_); }
    if (/^EXT/) { &scan_var($_); }
    last LINE unless $_ = <CPP>;
  }
  while (/^#.*proto\.h/i .. /^#.*perl\.h/i) {
    print "proto.h>> $_" if $debug;
    &scan_func($_);
    if (/^EXT/) { &scan_var($_); }
    last LINE unless $_ = <CPP>;
  }
  print $_ if $debug;
  if (/^EXT/) { &scan_var($_); }
}
close CPP;
while (<DATA>) {
  next if /^#/;
  s/\s+#.*\n//;
  ($key,$array) = split('=',$_);
  print "Adding $key to \%$array list\n" if $debug;
  ${$array}{$key}++;
}

# Eventually, we'll check against existing copies here, so we can add new
# symbols to an existing options file in an upwardly-compatible manner.

$marord++;
open(OPTSYM,">${dir}perlshr_sym.opt")
  or die "$0: Can't write to ${dir}perlshr_sym.opt: $!\n";
open(OPTATTR,">${dir}perlshr_attr.opt")
  or die "$0: Can't write to ${dir}perlshr_attr.opt: $!\n";
if ($isvax) {
  open(MAR,">${dir}perlshr_gbl${marord}.mar")
    or die "$0: Can't write to ${dir}perlshr_gbl${marord}.mar: $!\n";
}
print OPTATTR "PSECT_ATTR=\$CHAR_STRING_CONSTANTS,PIC,SHR,NOEXE,RD,NOWRT\n";
foreach $var (sort keys %vars) {
  print OPTATTR "PSECT_ATTR=${var},PIC,OVR,RD,NOEXE,WRT,NOSHR\n";
  if ($isvax) { print OPTSYM "UNIVERSAL=$var\n"; }
  else { print OPTSYM "SYMBOL_VECTOR=($var=DATA)\n"; }
  if ($isvax) {
    if ($count++ > 200) {  # max 254 psects/file
      print MAR "\t.end\n";
      close MAR;
      $marord++;
      open(MAR,">${dir}perlshr_gbl${marord}.mar")
        or die "$0: Can't write to ${dir}perlshr_gbl${marord}.mar: $!\n";
      $count = 0;
    }
    # This hack brought to you by the lack of a globaldef in gcc.
    print MAR "\t.psect ${var},long,pic,ovr,rd,wrt,noexe,noshr\n";
    print MAR "\t${var}::	.blkl 1\n";
  }
}

print MAR "\t.psect \$transfer_vec,pic,rd,nowrt,exe,shr\n" if ($isvax);
foreach $func (sort keys %funcs) {
  if ($isvax) {
    print MAR "\t.transfer $func\n";
    print MAR "\t.mask $func\n";
    print MAR "\tjmp L\^${func}+2\n";
  }
  else { print OPTSYM "SYMBOL_VECTOR=($func=PROCEDURE)\n"; }
}

close OPTSYM;
close OPTATTR;
if ($isvax) {
  print MAR "\t.end\n";
  close MAR;
  open (GBLOPT,">PerlShr_Gbl.Opt") or die "$0: Can't write to PerlShr_Gbl.Opt: $!\n";
  $drvrname = "Compile_shrmars.tmp_".time;
  open (DRVR,">$drvrname") or die "$0: Can't write to $drvrname: $!\n";
  print DRVR "\$ Set NoOn\n";  
  print DRVR "\$ Delete/NoLog/NoConfirm $drvrname;\n";
  print DRVR "\$ old_proc_vfy = F\$Environment(\"VERIFY_PROCEDURE\")\n";
  print DRVR "\$ old_img_vfy = F\$Environment(\"VERIFY_IMAGE\")\n";
  print DRVR "\$ Set Verify\n";
  do {
    print GBLOPT "PerlShr_Gbl${marord}$objsuffix\n";
    print DRVR "\$ Macro/NoDebug/Object=PerlShr_Gbl${marord}$objsuffix PerlShr_Gbl$marord.Mar\n";
  } while (--$marord); 
  print DRVR "\$ old_proc_vfy = F\$Verify(old_proc_vfy,old_img_vfy)\n";
  close DRVR;
  close GBLOPT;
  exec "\$ \@$drvrname";
}
__END__

# Oddball cases, so we can keep the perl.h scan above simple
error=vars      # declared in perl.h only when DOINIT defined by INTERN.h
rcsid=vars      # declared in perl.c
regarglen=vars  # declared in regcomp.h
regdummy=vars   # declared in regcomp.h
regkind=vars    # declared in regcomp.h
simple=vars     # declared in regcomp.h
varies=vars     # declared in regcomp.h
watchaddr=vars  # declared in run.c
watchok=vars    # declared in run.c
yychar=vars     # generated by byacc in perly.c
yycheck=vars    # generated by byacc in perly.c
yydebug=vars    # generated by byacc in perly.c
yydefred=vars   # generated by byacc in perly.c
yydgoto=vars    # generated by byacc in perly.c
yyerrflag=vars  # generated by byacc in perly.c
yygindex=vars   # generated by byacc in perly.c
yylen=vars      # generated by byacc in perly.c
yylhs=vars      # generated by byacc in perly.c
yylval=vars     # generated by byacc in perly.c
yyname=vars     # generated by byacc in perly.c
yynerrs=vars    # generated by byacc in perly.c
yyrindex=vars   # generated by byacc in perly.c
yyrule=vars     # generated by byacc in perly.c
yysindex=vars   # generated by byacc in perly.c
yytable=vars    # generated by byacc in perly.c
yyval=vars      # generated by byacc in perly.c
