/*    pp_i.c
 *
 *    Copyright (C) XXX by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

#include "EXTERN.h"
#define PERL_IN_PP_I_C
#include "perl.h"

/* integer versions of some of the maths ops. In a separate file, so that we
   can control the compiler options used for just these ops.  */

PP(pp_i_multiply)
{
    dVAR; dSP; dATARGET;
    tryAMAGICbin_MG(mult_amg, AMGf_assign);
    {
      dPOPTOPiirl_nomg;
      SETi( left * right );
      RETURN;
    }
}

PP(pp_i_divide)
{
    IV num;
    dVAR; dSP; dATARGET;
    tryAMAGICbin_MG(div_amg, AMGf_assign);
    {
      dPOPTOPssrl;
      IV value = SvIV_nomg(right);
      if (value == 0)
	  DIE(aTHX_ "Illegal division by zero");
      num = SvIV_nomg(left);

      /* avoid FPE_INTOVF on some platforms when num is IV_MIN */
      if (value == -1)
          value = - num;
      else
          value = num / value;
      SETi(value);
      RETURN;
    }
}

#if defined(__GLIBC__) && IVSIZE == 8
STATIC
PP(pp_i_modulo_0)
#else
PP(pp_i_modulo)
#endif
{
     /* This is the vanilla old i_modulo. */
     dVAR; dSP; dATARGET;
     tryAMAGICbin_MG(modulo_amg, AMGf_assign);
     {
	  dPOPTOPiirl_nomg;
	  if (!right)
	       DIE(aTHX_ "Illegal modulus zero");
	  /* avoid FPE_INTOVF on some platforms when left is IV_MIN */
	  if (right == -1)
	      SETi( 0 );
	  else
	      SETi( left % right );
	  RETURN;
     }
}

#if defined(__GLIBC__) && IVSIZE == 8
STATIC
PP(pp_i_modulo_1)

{
     /* This is the i_modulo with the workaround for the _moddi3 bug
      * in (at least) glibc 2.2.5 (the PERL_ABS() the workaround).
      * See below for pp_i_modulo. */
     dVAR; dSP; dATARGET;
     tryAMAGICbin_MG(modulo_amg, AMGf_assign);
     {
	  dPOPTOPiirl_nomg;
	  if (!right)
	       DIE(aTHX_ "Illegal modulus zero");
	  /* avoid FPE_INTOVF on some platforms when left is IV_MIN */
	  if (right == -1)
	      SETi( 0 );
	  else
	      SETi( left % PERL_ABS(right) );
	  RETURN;
     }
}

PP(pp_i_modulo)
{
     dVAR; dSP; dATARGET;
     tryAMAGICbin_MG(modulo_amg, AMGf_assign);
     {
	  dPOPTOPiirl_nomg;
	  if (!right)
	       DIE(aTHX_ "Illegal modulus zero");
	  /* The assumption is to use hereafter the old vanilla version... */
	  PL_op->op_ppaddr =
	       PL_ppaddr[OP_I_MODULO] =
	           Perl_pp_i_modulo_0;
	  /* .. but if we have glibc, we might have a buggy _moddi3
	   * (at least glicb 2.2.5 is known to have this bug), in other
	   * words our integer modulus with negative quad as the second
	   * argument might be broken.  Test for this and re-patch the
	   * opcode dispatch table if that is the case, remembering to
	   * also apply the workaround so that this first round works
	   * right, too.  See [perl #9402] for more information. */
	  {
	       IV l =   3;
	       IV r = -10;
	       /* Cannot do this check with inlined IV constants since
		* that seems to work correctly even with the buggy glibc. */
	       if (l % r == -3) {
		    /* Yikes, we have the bug.
		     * Patch in the workaround version. */
		    PL_op->op_ppaddr =
			 PL_ppaddr[OP_I_MODULO] =
			     &Perl_pp_i_modulo_1;
		    /* Make certain we work right this time, too. */
		    right = PERL_ABS(right);
	       }
	  }
	  /* avoid FPE_INTOVF on some platforms when left is IV_MIN */
	  if (right == -1)
	      SETi( 0 );
	  else
	      SETi( left % right );
	  RETURN;
     }
}
#endif

PP(pp_i_add)
{
    dVAR; dSP; dATARGET;
    tryAMAGICbin_MG(add_amg, AMGf_assign);
    {
      dPOPTOPiirl_ul_nomg;
      SETi( left + right );
      RETURN;
    }
}

PP(pp_i_subtract)
{
    dVAR; dSP; dATARGET;
    tryAMAGICbin_MG(subtr_amg, AMGf_assign);
    {
      dPOPTOPiirl_ul_nomg;
      SETi( left - right );
      RETURN;
    }
}

PP(pp_i_lt)
{
    dVAR; dSP;
    tryAMAGICbin_MG(lt_amg, AMGf_set);
    {
      dPOPTOPiirl_nomg;
      SETs(boolSV(left < right));
      RETURN;
    }
}

PP(pp_i_gt)
{
    dVAR; dSP;
    tryAMAGICbin_MG(gt_amg, AMGf_set);
    {
      dPOPTOPiirl_nomg;
      SETs(boolSV(left > right));
      RETURN;
    }
}

PP(pp_i_le)
{
    dVAR; dSP;
    tryAMAGICbin_MG(le_amg, AMGf_set);
    {
      dPOPTOPiirl_nomg;
      SETs(boolSV(left <= right));
      RETURN;
    }
}

PP(pp_i_ge)
{
    dVAR; dSP;
    tryAMAGICbin_MG(ge_amg, AMGf_set);
    {
      dPOPTOPiirl_nomg;
      SETs(boolSV(left >= right));
      RETURN;
    }
}

PP(pp_i_eq)
{
    dVAR; dSP;
    tryAMAGICbin_MG(eq_amg, AMGf_set);
    {
      dPOPTOPiirl_nomg;
      SETs(boolSV(left == right));
      RETURN;
    }
}

PP(pp_i_ne)
{
    dVAR; dSP;
    tryAMAGICbin_MG(ne_amg, AMGf_set);
    {
      dPOPTOPiirl_nomg;
      SETs(boolSV(left != right));
      RETURN;
    }
}

PP(pp_i_ncmp)
{
    dVAR; dSP; dTARGET;
    tryAMAGICbin_MG(ncmp_amg, 0);
    {
      dPOPTOPiirl_nomg;
      I32 value;

      if (left > right)
	value = 1;
      else if (left < right)
	value = -1;
      else
	value = 0;
      SETi(value);
      RETURN;
    }
}

PP(pp_i_negate)
{
    dVAR; dSP; dTARGET;
    tryAMAGICun_MG(neg_amg, 0);
    {
	SV * const sv = TOPs;
	IV const i = SvIV_nomg(sv);
	SETi(-i);
	RETURN;
    }
}


/*
 * Local variables:
 * c-indentation-style: bsd
 * c-basic-offset: 4
 * indent-tabs-mode: t
 * End:
 *
 * ex: set ts=8 sts=4 sw=4 noet:
 */
