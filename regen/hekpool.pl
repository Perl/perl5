# Revision: a38ab4751f3c0df44dc09e4d685a2637e93c9778
# Author: Ruslan Zakirov <ruz@bestpractical.com>
# Date: 3/24/2013 9:31:35 PM
# Message:
# SV_CONST(name) and PL_sv_consts

# SV_CONST(XXX) returns SV* that contains "XXX" string.
# SVs are built on demand and stored in interp's structure
# for re-use. All SVs have precomputed hash value.

# Creates SVs on demand, we don't want 35 SV created during
# compile time or cloned during thread creation.

#!/usr/bin/perl -w
#
#
# Regenerate (overwriting only if changed):
#
#    scope_types.h
#
# from information contained in this file in the
# __DATA_ section below.
#
# To add a new type simply add its name to the list
# below in the correct section (marked by C comments)
# and then regenerate with 'make regen'.
#
# Accepts the standard regen_lib -q and -v args.
#
# This script is normally invoked from regen.pl.

# The style of this file is determined by:
#
# perltidy -w -ple -bbb -bbc -bbs -nolq -l=80 -noll -nola -nwls='=' \
#   -isbc -nolc -otr -kis -ci=4 -se -sot -sct -nsbl -pt=2 -fs  \
#   -fsb='##!' -fse='##.'

BEGIN {
    # Get function prototypes
    require './regen/regen_lib.pl';
}

use strict;
use warnings;
use List::Util;

sub escape_csymbol {
    my $v = shift;
    $v =~ s/([^A-Z0-9a-wyz_])/${\(sprintf('_%x_',ord($1)))}/eg;
    $v = '_'.$v.'_';
    return $v;
}

my $svht;
my $svhs;
my $hekt;
my $heks;
my @xpvs;
my $astfn;
my $cnt = 0;
my $maybeGShHeHekLenBf;
my $GShHeHekFastMatchArr;
my @pvbylen = ();
my $i = 0;
my $avref2;

#PERLVAR(prefix,var,type) EXT type PL_##var
$svht = "typedef struct {\n  U16 lensv; U8 lenxpv;\n  union {\n    struct {\n";
$svhs = "
#ifndef DOINIT
PERLVAR(G, hekpoolsv, SVHEKP_T)
#else
SVHEKP_T PL_hekpoolsv = {\n"
    ."  C_ARRAY_LENGTH(PL_hekpoolsv.u.a),\n"
    ."  (U8)((Size_t)(sizeof(XPVS_IMM_T)/sizeof(XPVIMM_T))),\n  {{\n";
$hekt = "typedef struct {\n";
$heks = "
#ifndef DOINIT
PERLVAR(G, hekpool, HEKP_T)
#else
HEKP_T PL_hekpool = {\n";
$astfn = "#ifdef WANT_HEKPOOL_ASSERT\nstatic SV*\nS_assert_hekpool(pTHX){\n".
    "  const char * lbl = NULL;\n  if(0)\n    NOOP;\n";

foreach my $line (<DATA>) {
    $line =~ s/\s+\z//;
    my $line_len = length($line);
    if($line_len) {
        $avref2 = $pvbylen[$line_len];
        if(!$avref2) {
          $pvbylen[$line_len] = $avref2 = [];
        }
        push(@{$avref2}, $line);
        $cnt++;
    }
}

@pvbylen = map({
  $_ ? [sort(@{$_})] : $_;
  } @pvbylen);

foreach my $line_len_arr (@pvbylen) {
    if($line_len_arr) {
        foreach my $line (@{$line_len_arr}) {

    my $sym = escape_csymbol($line);
    my $line_len = length($line);
    $hekt .= "    struct {struct he shared_he_he; struct{U32 hek_hash;I32 hek_len;\n        char hek_key [sizeof(\"".$line."\")+1];} shared_he_hek;} ".$sym.";\n";
    $heks .= "    {{NULL, (HEK*)&PL_hekpool.".$sym.".shared_he_hek, {(SV*)1}},{0,sizeof(\"".$line."\")-1,\"".$line."\"}},\n";
    $svht .= "      SV ".$sym.";\n";
    $svhs .= "    {(void*)(((Size_t)(&hekpool_xpvs.len".$line_len."))-STRUCT_OFFSET(XPV,xpv_cur)),((~(U32)0)/2),SVf_IsCOW|SVf_READONLY|SVf_POK|SVp_POK|SVt_PV,{(void*)&PL_hekpool.".$sym.".shared_he_hek.hek_key}},\n";
    $xpvs[$line_len] = $line_len;
    $astfn .= "  else if(memNEs(SvPVX(&PL_hekpoolsv.u.st.".$sym."), SvCUR(&PL_hekpoolsv.u.st.".$sym."),\"".$line."\"))\n    lbl = \"".$line."\";\n";
        }
    }
}




$svht .= "    } st;\n    SV a[".$cnt."];\n  } u;\n} SVHEKP_T;\n\n";
$svhs = substr($svhs,0,-2);
$svhs .= "\n}}\n}\n;\n#endif\n\n";
$hekt .= "} HEKP_T;\n\n";
$heks = substr($heks,0,-2);
$heks .= "\n}\n;\n#endif\n\n";
        my @xpvlens;
        my($l, $xpvts,$xpvs,$usenl, $minl, $maxl) = (scalar(@xpvs),'','',-1,0,0);
        $i = 0;
        for(; $i < $l; $i++) {
          push(@xpvlens, $i) if $xpvs[$i];
        }
        $maybeGShHeHekLenBf = "\n#define HEKPOOL_LENMASK ("
            .join('|',map({'(1<<'.$_.')'} @xpvlens))
            .")\n\n";
        $minl = List::Util::min(@xpvlens);
        $maxl = List::Util::max(@xpvlens);
        
        $GShHeHekFastMatchArr = '
#if defined(PERL_IN_HV_C) || defined(PERL_IN_SV_C)
typedef struct {
  U32 fastmask;
  U16 svoffst;  /* offset in bytes, not idx, to region of same len SV heads */
  U16 svoffend; /* +1 after last SV head, use < */
} HPOOL_FASTM_T;

typedef struct {
  U8 lenlow;
  U8 lenhi;
  HPOOL_FASTM_T leninfo ['.(($maxl-$minl)+1).'];
} HPOOL_FASTMS_T;
#define HPOOLPV_MIN '.$minl.'
#define HPOOLPV_MAX '.$maxl.'
'.$maybeGShHeHekLenBf.'
#if defined(PERL_IS_MINIPERL)
#  define IS_MAYBE_HPOOL(_s, _l) if(0){0;}
#else
#  define IS_MAYBE_HPOOL(_s, _l) XXXDISABLED; if((_l) < 32 && ((1<<(_l))&HEKPOOL_LENMASK) \\
  && PL_hpfastm.leninfo[(_l)-HPOOLPV_MIN].fastmask \\
  && (*((U32*)_s)&~PL_hpfastm.leninfo[(_l)-HPOOLPV_MIN].fastmask == 0) {\\
    __debugbreak();\\
  }
#endif



static const HPOOL_FASTMS_T PL_hpfastm = { '.$minl.', '.$maxl.', {
';
my @fastm;
my $mask;
$i = $minl;
my $chr;
#my $strs_per_len;
my $firstSVh;
my $lastSVh;
my $avrv;
for(; $i <= $maxl; $i++) {
  $avrv = $pvbylen[$i];
  if($avrv) {
    #$strs_per_len = scalar(@{$avrv});
    $firstSVh = escape_csymbol($$avrv[0]);
    $lastSVh = escape_csymbol($$avrv[-1]);
    $mask = "  {(".
      join("\n   |",
        map({
          my $chr1=substr($_,0,1)."";
          my $chr2=substr($_,1,1)."";
          my $chr3=substr($_,2,1)."";
          my $chr4=substr($_,3,1)."";
          "vtohl(('".($chr1 eq ''?'\0':$chr1)."'|('"
            .($chr2 eq ''?'\0':$chr2)."'<<8)|('"
            .($chr3 eq ''?'\0':$chr3)."'<<16)|('".($chr4 eq ''?'\0':$chr4)."'<<24)))"
            } @{$avrv} )
      )."),\n   STRUCT_OFFSET(SVHEKP_T,u.st.".$firstSVh.")-STRUCT_OFFSET(SVHEKP_T,u.st),\n   (STRUCT_OFFSET(SVHEKP_T,u.st.".$lastSVh.")-STRUCT_OFFSET(SVHEKP_T,u.st))+sizeof(SV)}";
  }
  else {
    $mask = '  {0,0,0}';
  }
  push(@fastm, $mask);
}

$GShHeHekFastMatchArr .= join(",\n",@fastm)."\n  }\n};\n#endif\n\n";

        $xpvts .= "
typedef struct {
    STRLEN cur;
    STRLEN len;
} XPVIMM_T;

typedef struct {\n"
            .join('',map({'    '.sprintf('%-12s','XPVIMM_T len'.$_.';').(($usenl=(($usenl+1)&0x3))==3?"\n":'');} @xpvlens))
            ."\n} XPVS_IMM_T;\n\n";
          $xpvs .= "#ifdef DOINIT\nstatic const XPVS_IMM_T hekpool_xpvs = {\n  "
            .join(',' , map({'{'.$_.',0}'} @xpvlens))
            ."\n};\n#endif\n\n";
$astfn .= "  if(lbl)\n    return newSVpvn_flags(lbl,strlen(lbl),SVs_TEMP);\n"
  ."  else\n    return &PL_sv_undef;\n}\n#endif\n\n"
."
#define SV_CONST2(_tok) (!PL_hekpool._##_tok##_.shared_he_hek.hek_hash \\
  ? sv_vivihek(&PL_hekpoolsv.u.st._##_tok##_) \\
  : &PL_hekpoolsv.u.st._##_tok##_)
#define PV_POOL(_tok,_tokpv) ((const char*)PL_hekpool._##_tok##_.shared_he_hek.hek_key)
/* XXX TODO macro needs rework, this can't CC fold */
#define PVN_POOL(_tok,_tokpv) (PL_hekpool._##_tok##_.shared_he_hek.hek_len)
#define HEK_POOL(_tok,_tokpv) (&PL_hekpool._##_tok##_.shared_he_hek)
/* is equal, len must be abs match, then memcmp() done. We are comparing
   against the string in the HEK, and NOT a generic C \"\" lit created by
   CC/link, for cache reasons, smaller libperl file size, and very often
   in Perl VM, L and R ptrs will be the same, as the gShHEHEK circulates
   and spreads around the interp, and the gShHEHEK's char* often degrades in
   in patterns like HEK->SV->PVN->its Jan 1 1970 strlen() time.
   Throughout layers of call frames in interp C/XS and CPAN C/XS, but even
   after loosing its HEK and SV containers, and maybe getting redundantly
   strlen()ed in some parent call frame, the gShHEHEK's char* reappears
   as L side input to memEQhp().  So don't memcmp() against a same contents
   generic C \"\" lit. */
#define memEQhp(_s,_l,_tok,_qqpv) ((_l) == sizeof(_qqpv)-1 && memEQ((_s), \\
  (char*)PL_hekpool._##_tok##_.shared_he_hek.hek_key,   sizeof(_qqpv)-1))

#define SV_POOLLEN C_ARRAY_LENGTH(PL_hekpoolsv.u.a)
#define SV_POOLSTART (&PL_hekpoolsv.u.a[0])
/* 1 beyond last, test with < not <= */
#define SV_POOLEND (&PL_hekpoolsv.u.a[SV_POOLLEN])

/* The GblShHE/HEKs can't be iterated using a loop b/c they are packed var
   lengths. Adding to libperl, a const HE* array of GblShHE/HEKs is a waste of
   disk space.  Indirectly, GblShHE/HEKs can be looped over through the array
   of corresponding immortal/pooled SV heads. */

/* range test isn't at HEHEK[0]'s 1st str char .hek_key*/
#define IS_HEKPOOL(_hek) (((Size_t)(_hek))>=((Size_t)(&PL_hekpool)) \\
  && ((Size_t)(_hek))<(((Size_t)(&PL_hekpool))+sizeof(PL_hekpool)) \\
  ?TRUE:FALSE)
#define IS_SVPOOL(_sv) (((Size_t)(_sv))>=((Size_t)(&PL_hekpoolsv.u.st)) \\
  && ((Size_t)(_sv))<(((Size_t)(&PL_hekpoolsv.u.st))+sizeof(PL_hekpoolsv.u.st)) \\
  ?TRUE:FALSE)

";
my $out= open_new(
    'hekpool.h',
    '>', {
        by        => 'regen/hekpool.pl',
        copyright => [2022],
        final     => 'QQQQFINALQQQQ',
    });
print $out $svht, $hekt,  $xpvts, $GShHeHekFastMatchArr, $heks, $xpvs, $svhs,$astfn;
read_only_bottom_close_and_rename($out);

#TODO more candidates, but not adding them for now because they have lc chars
# all of PL_AMG_names[] array
# all C strings inside Perl_sv_reftype
# the whole API family of Perl_sv_reftype() Perl_sv_ref() Perl_pp_reftype()
# need to learn about "pvn" objects and "hek" objects
# and perhaps COWed/immortal SV* POK objects
# main can isa charnames _charnames import unimport attributes
# version alpha __WARN__ i saw it, all the sig names or some of them ???
# SKIPPING str "IO" too short

__DATA__
TIESCALAR
TIEARRAY
TIEHASH
TIEHANDLE
FETCH
FETCHSIZE
STORE
STORESIZE
EXISTS
PUSH
POP
SHIFT
UNSHIFT
SPLICE
EXTEND
FIRSTKEY
NEXTKEY
SCALAR
OPEN
WRITE
PRINT
PRINTF
READ
READLINE
GETC
SEEK
TELL
EOF
BINMODE
FILENO
CLOSE
DELETE
CLEAR
UNTIE
VERSION
XS_VERSION
EXPORT
EXPORT_OK
EXPORT_TAGS
UNIVERSAL
__ANON__
__ANONIO__
DOES
ISA
INC
ENV
SIG
PATH
TERM
HOME
ERROR
SAFE
FLAGS
MASK
STDERR
STDOUT
STDIN
ARGV
ARGVOUT
FILE
NAME
DATA
INCDIR
DEBUG
NULL
NULLREF
__FILE__
__LINE__
__PACKAGE__
__CLASS__
__DATA__
__END__
__SUB__
ADJUST
AUTOLOAD
CLONE
CLONE_SKIP
BEGIN
UNITCHECK
DESTROY
END
INIT
CHECK
CORE
FIELDS
VSTRING
REF
LVALUE
ARRAY
HASH
CODE
GLOB
FORMAT
INVLIST
REGEXP
OBJECT
UNKNOWN
EXPXXXXXXXORT_TAGS
