# Create global symbol declarations, transfer vector, and
# linker options files for PerlShr.
#
# Input:
#    $cflags - command line qualifiers passed to cc when preprocesing perl.h
#        Note: A rather simple-minded attempt is made to restore quotes to
#        a /Define clause - use with care.
#    $objsuffix - file type (including '.') used for object files.
#    $libperl - Perl object library.
#    $extnames - package names for static extensions (used to generate
#        linker options file entries for boot functions)
#    $rtlopt - name of options file specifying RTLs to which PerlShr.Exe
#        must be linked
#
# Output:
#    PerlShr_Attr.Opt - linker options file which specifies that global vars
#        be placed in NOSHR,WRT psects.  Use when linking any object files
#        against PerlShr.Exe, since cc places global vars in SHR,WRT psects
#        by default.
#    PerlShr_Bld.Opt - declares universal symbols for PerlShr.Exe
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
# Author: Charles Bailey  bailey@newman.upenn.edu

use strict;
require 5.000;

my $debug = $ENV{'GEN_SHRFLS_DEBUG'};

print "gen_shrfls.pl Rev. 30-Sep-2010\n" if $debug;

if ($ARGV[0] eq '-f') {
  open(INP,$ARGV[1]) or die "Can't read input file $ARGV[1]: $!\n";
  print "Input taken from file $ARGV[1]\n" if $debug;
  @ARGV = ();
  while (<INP>) {
    chomp;
    push(@ARGV,split(/\|/,$_));
  }
  close INP;
  print "Read input data | ",join(' | ',@ARGV)," |\n" if $debug > 1;
}

my $cc_cmd = shift @ARGV;
my $cpp_file;

# Someday, we'll have $GetSyI built into perl . . .
my $isvax = `\$ Write Sys\$Output \(F\$GetSyI(\"HW_MODEL\") .LE. 1024 .AND. F\$GetSyI(\"HW_MODEL\") .GT. 0\)`;
chomp $isvax;
print "\$isvax: \\$isvax\\\n" if $debug;

my $isi64 = `\$ Write Sys\$Output \(F\$GetSyI(\"HW_MODEL\") .GE. 4096)`;
chomp $isi64;
print "\$isi64: \\$isi64\\\n" if $debug;

print "Input \$cc_cmd: \\$cc_cmd\\\n" if $debug;
my $docc = ($cc_cmd !~ /^~~/);
print "\$docc = $docc\n" if $debug;

my ( $use_threads, $use_mymalloc, $care_about_case, $shorten_symbols,
     $debugging_enabled, $hide_mymalloc, $isgcc, $use_perlio, $dir )
   = ( 0, 0, 0, 0, 0, 0, 0, 0 );

if ($docc) {
  if (-f 'perl.h') { $dir = '[]'; }
  elsif (-f '[-]perl.h') { $dir = '[-]'; }
  else { die "$0: Can't find perl.h\n"; }

  # Go see what is enabled in config.sh
  my $config = $dir . "config.sh";
  open CONFIG, '<', $config;
  while(<CONFIG>) {
    $use_threads++ if /usethreads='(define|yes|true|t|y|1)'/i;
    $use_mymalloc++ if /usemymalloc='(define|yes|true|t|y|1)'/i;
    $care_about_case++ if /d_vms_case_sensitive_symbols='(define|yes|true|t|y|1)'/i;
    $shorten_symbols++ if /d_vms_shorten_long_symbols='(define|yes|true|t|y|1)'/i;
    $debugging_enabled++ if /usedebugging_perl='(define|yes|true|t|y|1)'/i;
    $hide_mymalloc++ if /embedmymalloc='(define|yes|true|t|y|1)'/i;
    $isgcc++ if /gccversion='[^']/;
    $use_perlio++ if /useperlio='(define|yes|true|t|y|1)'/i;
  }
  close CONFIG;
  
  # put quotes back onto defines - they were removed by DCL on the way in
  if (my ($prefix,$defines,$suffix) =
         ($cc_cmd =~ m#(.*)/Define=(.*?)([/\s].*)#i)) {
    $defines =~ s/^\((.*)\)$/$1/;
    $debugging_enabled ||= $defines =~ /\bDEBUGGING\b/;
    my @defines = split(/,/,$defines);
    $cc_cmd = "$prefix/Define=(" . join(',',grep($_ = "\"$_\"",@defines)) 
              . ')' . $suffix;
  }
  print "Filtered \$cc_cmd: \\$cc_cmd\\\n" if $debug;

  # check for gcc - if present, we'll need to use MACRO hack to
  # define global symbols for shared variables

  print "\$isgcc: $isgcc\n" if $debug;
  print "\$debugging_enabled: $debugging_enabled\n" if $debug;

}
else { 
  (undef,undef,$cpp_file,$cc_cmd) = split(/~~/,$cc_cmd,4);
  $isgcc = $cc_cmd =~ /case_hack/i
           or 0;  # for nice debug output
  $debugging_enabled = $cc_cmd =~ /\bdebugging\b/i;
  print "\$isgcc: \\$isgcc\\\n" if $debug;
  print "\$debugging_enabled: \\$debugging_enabled\\\n" if $debug;
  print "Not running cc, preprocesor output in \\$cpp_file\\\n" if $debug;
}

my $objsuffix = shift @ARGV;
print "\$objsuffix: \\$objsuffix\\\n" if $debug;
my $dbgprefix = shift @ARGV;
print "\$dbgprefix: \\$dbgprefix\\\n" if $debug;
my $olbsuffix = shift @ARGV;
print "\$olbsuffix: \\$olbsuffix\\\n" if $debug;
my $libperl = "${dbgprefix}libperl$olbsuffix";
my $extnames = shift @ARGV;
print "\$extnames: \\$extnames\\\n" if $debug;
my $rtlopt = shift @ARGV;
print "\$rtlopt: \\$rtlopt\\\n" if $debug;

my (%vars, %cvars, %fcns);

# These are symbols that we should not export.  They may merely
# look like exportable symbols but aren't, or they may be declared
# as exportable symbols but there is no function implementing them
# (possibly due to an alias).

my %symbols_to_exclude = (
  '__attribute__format__'  => 1,
  'main'                   => 1,
  'Perl_pp_avalues'        => 1,
  'Perl_pp_reach'          => 1,
  'Perl_pp_rvalues'        => 1,
  'Perl_pp_say'            => 1,
  'Perl_pp_transr'         => 1,
  'sizeof'                 => 1,
);

sub scan_var {
  my($line) = @_;
  my($const) = $line =~ /^EXTCONST/;

  print "\tchecking for global variable\n" if $debug > 1;
  $line =~ s/\s*EXT/EXT/;
  $line =~ s/INIT\s*\(.*\)//;
  $line =~ s/\[.*//;
  $line =~ s/=.*//;
  $line =~ s/\W*;?\s*$//;
  $line =~ s/\W*\)\s*\(.*$//; # closing paren for args stripped in previous stmt
  print "\tfiltered to \\$line\\\n" if $debug > 1;
  if ($line =~ /(\w+)$/) {
    print "\tvar name is \\$1\\" . ($const ? ' (const)' : '') . "\n" if $debug > 1;
   if ($const) { $cvars{$1}++; }
   else        { $vars{$1}++;  }
  }
}

sub scan_func {
  my @lines = split /;/, $_[0];

  for my $line (@lines) {
    print "\tchecking for global routine\n" if $debug > 1;
    $line =~ s/\b(IV|Off_t|Size_t|SSize_t|void|int)\b//i;
    if ( $line =~ /(\w+)\s*\(/ ) {
      print "\troutine name is \\$1\\\n" if $debug > 1;
      if (exists($symbols_to_exclude{$1})
          || ($1 eq 'Perl_stashpv_hvname_match' && ! $use_threads)) {
        print "\tskipped\n" if $debug > 1;
      }
      else { $fcns{$1}++ }
    }
  }
}

# Go add some right up front if we need 'em
if ($use_mymalloc) {
  $fcns{'Perl_malloc'}++;
  $fcns{'Perl_calloc'}++;
  $fcns{'Perl_realloc'}++;
  $fcns{'Perl_mfree'}++;
}

my ($used_expectation_enum, $used_opcode_enum) = (0, 0); # avoid warnings
if ($docc) {
  1 while unlink 'perlincludes.tmp';
  END { 1 while unlink 'perlincludes.tmp'; }  # and clean up after

  open(PERLINC, '>', 'perlincludes.tmp') or die "Couldn't open 'perlincludes.tmp' $!";

  print PERLINC qq/#include "${dir}perl.h"\n/;
  print PERLINC qq/#include "${dir}perlapi.h"\n/; 
  print PERLINC qq/#include "${dir}perliol.h"\n/ if $use_perlio;
  print PERLINC qq/#include "${dir}regcomp.h"\n/;

  close PERLINC;
  my $preprocess_list = 'perlincludes.tmp';

  open(CPP,"${cc_cmd}/NoObj/PreProc=Sys\$Output $preprocess_list|")
    or die "$0: Can't preprocess $preprocess_list: $!\n";
}
else {
  open(CPP,"$cpp_file") or die "$0: Can't read preprocessed file $cpp_file: $!\n";
}
my %checkh = map { $_,1 } qw( bytecode byterun intrpvar perlapi perlio perliol 
                           perlvars proto regcomp thrdvar thread );
my $ckfunc = 0;
LINE: while (<CPP>) {
  while (/^#.*vmsish\.h/i .. /^#.*perl\.h/i) {
    while (/__VMS_PROTOTYPES__/i .. /__VMS_SEPYTOTORP__/i) {
      print "vms_proto>> $_" if $debug > 2;
      if (/^\s*EXT(CONST|\s+)/) { &scan_var($_);  }
      else        { &scan_func($_); }
      last LINE unless defined($_ = <CPP>);
    }
    print "vmsish.h>> $_" if $debug > 2;
    if (/^\s*EXT(CONST|\s+)/) { &scan_var($_); }
    last LINE unless defined($_ = <CPP>);
  }    
  while (/^#.*opcode\.h/i .. /^#.*perl\.h/i) {
    print "opcode.h>> $_" if $debug > 2;
    if (/^OP \*\s/) { &scan_func($_); }
    if (/^\s*EXT(CONST|\s+)/) { &scan_var($_); }
    last LINE unless defined($_ = <CPP>);
  }
  # Check for transition to new header file
  my $scanname;
  if (/^# \d+ "(\S+)"/) {
    my $spec = $1;
    # Pull name from library module or header filespec
    $spec =~ /^(\w+)$/ or $spec =~ /(\w+)\.h/i;
    my $name = lc $1;
    $ckfunc = exists $checkh{$name} ? 1 : 0;
    $scanname = $name if $ckfunc;
    print "Header file transition: ckfunc = $ckfunc for $name.h\n" if $debug > 1;
  }
  if ($ckfunc) {
    print "$scanname>> $_" if $debug > 2;
    if (/^\s*EXT(CONST|\s+)/) { &scan_var($_);  }
    else           { &scan_func($_); }
  }
  else {
    print $_ if $debug > 3 && ($debug > 5 || length($_));
    if (/^\s*EXT(CONST|\s+)/) { &scan_var($_); }
  }
}
close CPP;

while (<DATA>) {
  next if /^#/;
  s/\s+#.*\n//;
  next if /^\s*$/;
  my ($key,$array) = split('=',$_);
  if ($array eq 'vars') { $key = "PL_$key";   }
  else                  { $key = "Perl_$key"; }
  print "Adding $key to \%$array list\n" if $debug > 1;
  ${$array}{$key}++;
}
if ($debugging_enabled and $isgcc) { $vars{'colors'}++ }
foreach (split /\s+/, $extnames) {
  my($pkgname) = $_;
  $pkgname =~ s/::/__/g;
  $fcns{"boot_$pkgname"}++;
  print "Adding boot_$pkgname to \%fcns (for extension $_)\n" if $debug;
}

# For symbols over 31 characters, export the shortened name.
# TODO: Make this general purpose so we can predict the shortened name the
# compiler will generate for any symbol over 31 characters in length.  The
# docs to CC/NAMES=SHORTENED describe the CRC used to shorten the name, but
# don't describe its use fully enough to actually mimic what the compiler
# does.

if ($shorten_symbols) {
  if (exists $fcns{'Perl_ck_entersub_args_proto_or_list'}) {
    delete $fcns{'Perl_ck_entersub_args_proto_or_list'};
    if ($care_about_case) {
      $fcns{'Perl_ck_entersub_args_p11c2bjj$'}++;
    }
    else {
      $fcns{'PERL_CK_ENTERSUB_ARGS_P3IAT616$'}++;
    }
  }
}

# Eventually, we'll check against existing copies here, so we can add new
# symbols to an existing options file in an upwardly-compatible manner.

my $marord = 1;
open(OPTBLD,'>', "${dir}${dbgprefix}perlshr_bld.opt")
  or die "$0: Can't write to ${dir}${dbgprefix}perlshr_bld.opt: $!\n";
if ($isvax) {
  open(MAR, '>', "${dir}perlshr_gbl${marord}.mar")
    or die "$0: Can't write to ${dir}perlshr_gbl${marord}.mar: $!\n";
  print MAR "\t.title perlshr_gbl$marord\n";
}

unless ($isgcc) {
  if ($isi64) {
    print OPTBLD "PSECT_ATTR=\$GLOBAL_RO_VARS,NOEXE,RD,NOWRT,SHR\n";
    print OPTBLD "PSECT_ATTR=\$GLOBAL_RW_VARS,NOEXE,RD,WRT,NOSHR\n";
  }
  else {
    print OPTBLD "PSECT_ATTR=\$GLOBAL_RO_VARS,PIC,NOEXE,RD,NOWRT,SHR\n";
    print OPTBLD "PSECT_ATTR=\$GLOBAL_RW_VARS,PIC,NOEXE,RD,WRT,NOSHR\n";
  }
}
print OPTBLD "case_sensitive=yes\n" if $care_about_case;
my $count = 0;
foreach my $var (sort (keys %vars,keys %cvars)) {
  if ($isvax) { print OPTBLD "UNIVERSAL=$var\n"; }
  else { print OPTBLD "SYMBOL_VECTOR=($var=DATA)\n"; }
  # This hack brought to you by the lack of a globaldef in gcc.
  if ($isgcc) {
    if ($count++ > 200) {  # max 254 psects/file
      print MAR "\t.end\n";
      close MAR;
      $marord++;
      open(MAR, '>', "${dir}perlshr_gbl${marord}.mar")
        or die "$0: Can't write to ${dir}perlshr_gbl${marord}.mar: $!\n";
      print MAR "\t.title perlshr_gbl$marord\n";
      $count = 0;
    }
    print MAR "\t.psect ${var},long,pic,ovr,rd,wrt,noexe,noshr\n";
    print MAR "\t${var}::	.blkl 1\n";
  }
}

print MAR "\t.psect \$transfer_vec,pic,rd,nowrt,exe,shr\n" if ($isvax);
foreach my $func (sort keys %fcns) {
  if ($isvax) {
    print MAR "\t.transfer $func\n";
    print MAR "\t.mask $func\n";
    print MAR "\tjmp G\^${func}+2\n";
  }
  else { print OPTBLD "SYMBOL_VECTOR=($func=PROCEDURE)\n"; }
}
if ($isvax) {
  print MAR "\t.end\n";
  close MAR;
}

open(OPTATTR, '>', "${dir}perlshr_attr.opt")
  or die "$0: Can't write to ${dir}perlshr_attr.opt: $!\n";
if ($isgcc) {
  foreach my $var (sort keys %cvars) {
    print OPTATTR "PSECT_ATTR=${var},PIC,OVR,RD,NOEXE,NOWRT,SHR\n";
  }
  foreach my $var (sort keys %vars) {
    print OPTATTR "PSECT_ATTR=${var},PIC,OVR,RD,NOEXE,WRT,NOSHR\n";
  }
}
else {
  print OPTATTR "! No additional linker directives are needed when using DECC\n";
}
close OPTATTR;

my $incstr = 'PERL,GLOBALS';
my (@symfiles, $drvrname);
if ($isvax) {
  $drvrname = "Compile_shrmars.tmp_".time;
  open (DRVR,'>', $drvrname) or die "$0: Can't write to $drvrname: $!\n";
  print DRVR "\$ Set NoOn\n";  
  print DRVR "\$ Delete/NoLog/NoConfirm $drvrname;\n";
  print DRVR "\$ old_proc_vfy = F\$Environment(\"VERIFY_PROCEDURE\")\n";
  print DRVR "\$ old_img_vfy = F\$Environment(\"VERIFY_IMAGE\")\n";
  print DRVR "\$ MCR $^X -e \"\$ENV{'LIBPERL_RDT'} = (stat('$libperl'))[9]\"\n";
  print DRVR "\$ Set Verify\n";
  print DRVR "\$ If F\$Search(\"$libperl\").eqs.\"\" Then Library/Object/Create $libperl\n";
  do {
    push(@symfiles,"perlshr_gbl$marord");
    print DRVR "\$ Macro/NoDebug/Object=PerlShr_Gbl${marord}$objsuffix PerlShr_Gbl$marord.Mar\n";
    print DRVR "\$ Library/Object/Replace/Log $libperl PerlShr_Gbl${marord}$objsuffix\n";
  } while (--$marord); 
  # We had to have a working miniperl to run this program; it's probably the
  # one we just built.  It depended on LibPerl, which will be changed when
  # the PerlShr_Gbl* modules get inserted, so miniperl will be out of date,
  # and so, therefore, will all of its dependents . . .
  # We touch LibPerl here so it'll be back 'in date', and we won't rebuild
  # miniperl etc., and therefore LibPerl, the next time we invoke MM[KS].
  print DRVR "\$ old_proc_vfy = F\$Verify(old_proc_vfy,old_img_vfy)\n";
  print DRVR "\$ MCR $^X -e \"utime 0, \$ENV{'LIBPERL_RDT'}, '$libperl'\"\n";
  close DRVR;
}

# Initial hack to permit building of compatible shareable images for a
# given version of Perl.
if ($ENV{PERLSHR_USE_GSMATCH}) {
  if ($ENV{PERLSHR_USE_GSMATCH} eq 'INCLUDE_COMPILE_OPTIONS') {
    # Build up a major ID. Since it can only be 8 bits, we encode the version
    # number in the top four bits and use the bottom four for build options
    # that'll cause incompatibilities
    my ($ver, $sub) = $] =~ /\.(\d\d\d)(\d\d)/;
    $ver += 0; $sub += 0;
    my $gsmatch = ($sub >= 50) ? "equal" : "lequal"; # Force an equal match for
						  # dev, but be more forgiving
						  # for releases

    $ver *=16;
    $ver += 8 if $debugging_enabled;	# If DEBUGGING is set
    $ver += 4 if $use_threads;		# if we're threaded
    $ver += 2 if $use_mymalloc;		# if we're using perl's malloc
    print OPTBLD "GSMATCH=$gsmatch,$ver,$sub\n";
  }
  else {
    my $major = int($] * 1000)                        & 0xFF;  # range 0..255
    my $minor = int(($] * 1000 - $major) * 100 + 0.5) & 0xFF;  # range 0..255
    print OPTBLD "GSMATCH=LEQUAL,$major,$minor\n";
  }
  print OPTBLD 'CLUSTER=$$TRANSFER_VECTOR,,',
               map(",$_$objsuffix",@symfiles), "\n";
}
elsif (@symfiles) { $incstr .= ',' . join(',',@symfiles); }
# Include object modules and RTLs in options file
# Linker wants /Include and /Library on different lines
print OPTBLD "$libperl/Include=($incstr)\n";
print OPTBLD "$libperl/Library\n";
open(RTLOPT,$rtlopt) or die "$0: Can't read options file $rtlopt: $!\n";
while (<RTLOPT>) { print OPTBLD; }
close RTLOPT;
close OPTBLD;

exec "\$ \@$drvrname" if $isvax;


__END__

# Oddball cases, so we can keep the perl.h scan above simple
#Foo=vars    # uncommented becomes PL_Foo
#Bar=funcs   # uncommented becomes Perl_Bar
