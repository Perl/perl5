#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef I_LANGINFO
#   include <langinfo.h>
#endif

#define PERL_constant_NOTFOUND	1
#define PERL_constant_NOTDEF	2
#define PERL_constant_ISIV	3
#define PERL_constant_ISNO	4
#define PERL_constant_ISNV	5
#define PERL_constant_ISPV	6
#define PERL_constant_ISPVN	7
#define PERL_constant_ISSV	8
#define PERL_constant_ISUNDEF	9
#define PERL_constant_ISUV	10
#define PERL_constant_ISYES	11

#ifndef NVTYPE
typedef double NV; /* 5.6 and later define NVTYPE, and typedef NV to it.  */
#endif
static int
constant_5 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     DAY_1 DAY_2 DAY_3 DAY_4 DAY_5 DAY_6 DAY_7 D_FMT MON_1 MON_2 MON_3 MON_4
     MON_5 MON_6 MON_7 MON_8 MON_9 NOSTR T_FMT */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case '1':
    if (memEQ(name, "DAY_1", 5)) {
    /*                   ^      */
#ifdef DAY_1
      *iv_return = DAY_1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MON_1", 5)) {
    /*                   ^      */
#ifdef MON_1
      *iv_return = MON_1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "DAY_2", 5)) {
    /*                   ^      */
#ifdef DAY_2
      *iv_return = DAY_2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MON_2", 5)) {
    /*                   ^      */
#ifdef MON_2
      *iv_return = MON_2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '3':
    if (memEQ(name, "DAY_3", 5)) {
    /*                   ^      */
#ifdef DAY_3
      *iv_return = DAY_3;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MON_3", 5)) {
    /*                   ^      */
#ifdef MON_3
      *iv_return = MON_3;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '4':
    if (memEQ(name, "DAY_4", 5)) {
    /*                   ^      */
#ifdef DAY_4
      *iv_return = DAY_4;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MON_4", 5)) {
    /*                   ^      */
#ifdef MON_4
      *iv_return = MON_4;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '5':
    if (memEQ(name, "DAY_5", 5)) {
    /*                   ^      */
#ifdef DAY_5
      *iv_return = DAY_5;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MON_5", 5)) {
    /*                   ^      */
#ifdef MON_5
      *iv_return = MON_5;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '6':
    if (memEQ(name, "DAY_6", 5)) {
    /*                   ^      */
#ifdef DAY_6
      *iv_return = DAY_6;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MON_6", 5)) {
    /*                   ^      */
#ifdef MON_6
      *iv_return = MON_6;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '7':
    if (memEQ(name, "DAY_7", 5)) {
    /*                   ^      */
#ifdef DAY_7
      *iv_return = DAY_7;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MON_7", 5)) {
    /*                   ^      */
#ifdef MON_7
      *iv_return = MON_7;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '8':
    if (memEQ(name, "MON_8", 5)) {
    /*                   ^      */
#ifdef MON_8
      *iv_return = MON_8;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '9':
    if (memEQ(name, "MON_9", 5)) {
    /*                   ^      */
#ifdef MON_9
      *iv_return = MON_9;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "NOSTR", 5)) {
    /*                   ^      */
#ifdef NOSTR
      *iv_return = NOSTR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "D_FMT", 5)) {
    /*                   ^      */
#ifdef D_FMT
      *iv_return = D_FMT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "T_FMT", 5)) {
    /*                   ^      */
#ifdef T_FMT
      *iv_return = T_FMT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_6 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     AM_STR MON_10 MON_11 MON_12 NOEXPR PM_STR YESSTR */
  /* Offset 0 gives the best switch position.  */
  switch (name[0]) {
  case 'A':
    if (memEQ(name, "AM_STR", 6)) {
    /*               ^           */
#ifdef AM_STR
      *iv_return = AM_STR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "MON_10", 6)) {
    /*               ^           */
#ifdef MON_10
      *iv_return = MON_10;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MON_11", 6)) {
    /*               ^           */
#ifdef MON_11
      *iv_return = MON_11;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MON_12", 6)) {
    /*               ^           */
#ifdef MON_12
      *iv_return = MON_12;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "NOEXPR", 6)) {
    /*               ^           */
#ifdef NOEXPR
      *iv_return = NOEXPR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "PM_STR", 6)) {
    /*               ^           */
#ifdef PM_STR
      *iv_return = PM_STR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "YESSTR", 6)) {
    /*               ^           */
#ifdef YESSTR
      *iv_return = YESSTR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_7 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ABDAY_1 ABDAY_2 ABDAY_3 ABDAY_4 ABDAY_5 ABDAY_6 ABDAY_7 ABMON_1 ABMON_2
     ABMON_3 ABMON_4 ABMON_5 ABMON_6 ABMON_7 ABMON_8 ABMON_9 CODESET D_T_FMT
     THOUSEP YESEXPR */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case '1':
    if (memEQ(name, "ABDAY_1", 7)) {
    /*                     ^      */
#ifdef ABDAY_1
      *iv_return = ABDAY_1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "ABMON_1", 7)) {
    /*                     ^      */
#ifdef ABMON_1
      *iv_return = ABMON_1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "ABDAY_2", 7)) {
    /*                     ^      */
#ifdef ABDAY_2
      *iv_return = ABDAY_2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "ABMON_2", 7)) {
    /*                     ^      */
#ifdef ABMON_2
      *iv_return = ABMON_2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '3':
    if (memEQ(name, "ABDAY_3", 7)) {
    /*                     ^      */
#ifdef ABDAY_3
      *iv_return = ABDAY_3;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "ABMON_3", 7)) {
    /*                     ^      */
#ifdef ABMON_3
      *iv_return = ABMON_3;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '4':
    if (memEQ(name, "ABDAY_4", 7)) {
    /*                     ^      */
#ifdef ABDAY_4
      *iv_return = ABDAY_4;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "ABMON_4", 7)) {
    /*                     ^      */
#ifdef ABMON_4
      *iv_return = ABMON_4;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '5':
    if (memEQ(name, "ABDAY_5", 7)) {
    /*                     ^      */
#ifdef ABDAY_5
      *iv_return = ABDAY_5;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "ABMON_5", 7)) {
    /*                     ^      */
#ifdef ABMON_5
      *iv_return = ABMON_5;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '6':
    if (memEQ(name, "ABDAY_6", 7)) {
    /*                     ^      */
#ifdef ABDAY_6
      *iv_return = ABDAY_6;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "ABMON_6", 7)) {
    /*                     ^      */
#ifdef ABMON_6
      *iv_return = ABMON_6;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '7':
    if (memEQ(name, "ABDAY_7", 7)) {
    /*                     ^      */
#ifdef ABDAY_7
      *iv_return = ABDAY_7;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "ABMON_7", 7)) {
    /*                     ^      */
#ifdef ABMON_7
      *iv_return = ABMON_7;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '8':
    if (memEQ(name, "ABMON_8", 7)) {
    /*                     ^      */
#ifdef ABMON_8
      *iv_return = ABMON_8;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '9':
    if (memEQ(name, "ABMON_9", 7)) {
    /*                     ^      */
#ifdef ABMON_9
      *iv_return = ABMON_9;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "THOUSEP", 7)) {
    /*                     ^      */
#ifdef THOUSEP
      *iv_return = THOUSEP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "YESEXPR", 7)) {
    /*                     ^      */
#ifdef YESEXPR
      *iv_return = YESEXPR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "CODESET", 7)) {
    /*                     ^      */
#ifdef CODESET
      *iv_return = CODESET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "D_T_FMT", 7)) {
    /*                     ^      */
#ifdef D_T_FMT
      *iv_return = D_T_FMT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_8 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ABMON_10 ABMON_11 ABMON_12 CRNCYSTR */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case '0':
    if (memEQ(name, "ABMON_10", 8)) {
    /*                      ^      */
#ifdef ABMON_10
      *iv_return = ABMON_10;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '1':
    if (memEQ(name, "ABMON_11", 8)) {
    /*                      ^      */
#ifdef ABMON_11
      *iv_return = ABMON_11;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "ABMON_12", 8)) {
    /*                      ^      */
#ifdef ABMON_12
      *iv_return = ABMON_12;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "CRNCYSTR", 8)) {
    /*                      ^      */
#ifdef CRNCYSTR
      *iv_return = CRNCYSTR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_9 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ERA_D_FMT ERA_T_FMT RADIXCHAR */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'D':
    if (memEQ(name, "ERA_D_FMT", 9)) {
    /*                   ^          */
#ifdef ERA_D_FMT
      *iv_return = ERA_D_FMT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "ERA_T_FMT", 9)) {
    /*                   ^          */
#ifdef ERA_T_FMT
      *iv_return = ERA_T_FMT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "RADIXCHAR", 9)) {
    /*                   ^          */
#ifdef RADIXCHAR
      *iv_return = RADIXCHAR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant (pTHX_ const char *name, STRLEN len, IV *iv_return) {
  /* Initially switch on the length of the name.  */
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!../../../perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(ABDAY_1 ABDAY_2 ABDAY_3 ABDAY_4 ABDAY_5 ABDAY_6 ABDAY_7 ABMON_1
	       ABMON_10 ABMON_11 ABMON_12 ABMON_2 ABMON_3 ABMON_4 ABMON_5
	       ABMON_6 ABMON_7 ABMON_8 ABMON_9 ALT_DIGITS AM_STR CODESET
	       CRNCYSTR DAY_1 DAY_2 DAY_3 DAY_4 DAY_5 DAY_6 DAY_7 D_FMT D_T_FMT
	       ERA ERA_D_FMT ERA_D_T_FMT ERA_T_FMT MON_1 MON_10 MON_11 MON_12
	       MON_2 MON_3 MON_4 MON_5 MON_6 MON_7 MON_8 MON_9 NOEXPR NOSTR
	       PM_STR RADIXCHAR THOUSEP T_FMT T_FMT_AMPM YESEXPR YESSTR));

print constant_types(); # macro defs
foreach (C_constant ("I18N::Langinfo", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("I18N::Langinfo", $types);
__END__
   */

  switch (len) {
  case 3:
    if (memEQ(name, "ERA", 3)) {
#ifdef ERA
      *iv_return = ERA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 5:
    return constant_5 (aTHX_ name, iv_return);
    break;
  case 6:
    return constant_6 (aTHX_ name, iv_return);
    break;
  case 7:
    return constant_7 (aTHX_ name, iv_return);
    break;
  case 8:
    return constant_8 (aTHX_ name, iv_return);
    break;
  case 9:
    return constant_9 (aTHX_ name, iv_return);
    break;
  case 10:
    /* Names all of length 10.  */
    /* ALT_DIGITS T_FMT_AMPM */
    /* Offset 7 gives the best switch position.  */
    switch (name[7]) {
    case 'I':
      if (memEQ(name, "ALT_DIGITS", 10)) {
      /*                      ^         */
#ifdef ALT_DIGITS
        *iv_return = ALT_DIGITS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'M':
      if (memEQ(name, "T_FMT_AMPM", 10)) {
      /*                      ^         */
#ifdef T_FMT_AMPM
        *iv_return = T_FMT_AMPM;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 11:
    if (memEQ(name, "ERA_D_T_FMT", 11)) {
#ifdef ERA_D_T_FMT
      *iv_return = ERA_D_T_FMT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

MODULE = I18N::Langinfo	PACKAGE = I18N::Langinfo

PROTOTYPES: ENABLE

void
constant(sv)
    PREINIT:
#ifdef dXSTARG
	dXSTARG; /* Faster if we have it.  */
#else
	dTARGET;
#endif
	STRLEN		len;
        int		type;
	IV		iv;
	/* NV		nv;	Uncomment this if you need to return NVs */
	/* const char	*pv;	Uncomment this if you need to return PVs */
    INPUT:
	SV *		sv;
        const char *	s = SvPV(sv, len);
    PPCODE:
        /* Change this to constant(aTHX_ s, len, &iv, &nv);
           if you need to return both NVs and IVs */
	type = constant(aTHX_ s, len, &iv);
      /* Return 1 or 2 items. First is error message, or undef if no error.
           Second, if present, is found value */
        switch (type) {
        case PERL_constant_NOTFOUND:
          sv = sv_2mortal(newSVpvf("%s is not a valid I18N::Langinfo macro", s));
          PUSHs(sv);
          break;
        case PERL_constant_NOTDEF:
          sv = sv_2mortal(newSVpvf(
	    "Your vendor has not defined I18N::Langinfo macro %s, used", s));
          PUSHs(sv);
          break;
        case PERL_constant_ISIV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHi(iv);
          break;
	/* Uncomment this if you need to return NOs
        case PERL_constant_ISNO:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHs(&PL_sv_no);
          break; */
	/* Uncomment this if you need to return NVs
        case PERL_constant_ISNV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHn(nv);
          break; */
	/* Uncomment this if you need to return PVs
        case PERL_constant_ISPV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHp(pv, strlen(pv));
          break; */
	/* Uncomment this if you need to return PVNs
        case PERL_constant_ISPVN:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHp(pv, iv);
          break; */
	/* Uncomment this if you need to return SVs
        case PERL_constant_ISSV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHs(sv);
          break; */
	/* Uncomment this if you need to return UNDEFs
        case PERL_constant_ISUNDEF:
          break; */
	/* Uncomment this if you need to return UVs
        case PERL_constant_ISUV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHu((UV)iv);
          break; */
	/* Uncomment this if you need to return YESs
        case PERL_constant_ISYES:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHs(&PL_sv_yes);
          break; */
        default:
          sv = sv_2mortal(newSVpvf(
	    "Unexpected return type %d while processing I18N::Langinfo macro %s, used",
               type, s));
          PUSHs(sv);
        }

SV*
langinfo(code)
	int	code
  CODE:
	char *s = nl_langinfo(code);
	RETVAL = newSVpvn(s, strlen(s));
  OUTPUT:
	RETVAL
