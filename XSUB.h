#define ST(off) stack_base[ax + off]

#ifdef CAN_PROTOTYPE
#define XS(name) void name(CV* cv)
#else
#define XS(name) void name(cv) CV* cv;
#endif

#define dXSARGS				\
	dSP; dMARK;			\
	I32 ax = mark - stack_base + 1;	\
	I32 items = sp - mark

#define XSANY CvXSUBANY(cv)

#define dXSI32 I32 ix = XSANY.any_i32

#define XSRETURN(off) stack_sp = stack_base + ax + ((off) - 1); return

/* Simple macros to put new mortal values onto the stack.   */
/* Typically used to return values from XS functions.       */
#define XST_mIV(i,v)  ST(i)=sv_2mortal(newSViv(v));
#define XST_mNV(i,v)  ST(i)=sv_2mortal(newSVnv(v));
#define XST_mPV(i,v)  ST(i)=sv_2mortal(newSVpv(v,0));
#define XST_mNO(i)    ST(i)=sv_mortalcopy(&sv_no);
#define XST_mYES(i)   ST(i)=sv_mortalcopy(&sv_yes);
#define XST_mUNDEF(i) ST(i)=sv_newmortal();
 
#define XSRETURN_IV(v) XST_mIV(0,v);  XSRETURN(1)
#define XSRETURN_NV(v) XST_mNV(0,v);  XSRETURN(1)
#define XSRETURN_PV(v) XST_mPV(0,v);  XSRETURN(1)
#define XSRETURN_NO    XST_mNO(0);    XSRETURN(1)
#define XSRETURN_YES   XST_mYES(0);   XSRETURN(1)
#define XSRETURN_UNDEF XST_mUNDEF(0); XSRETURN(1)
