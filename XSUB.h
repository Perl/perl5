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

#define XSRETURNNO    ST(0)=sv_mortalcopy(&sv_no); XSRETURN(1)
#define XSRETURNYES   ST(0)=sv_mortalcopy(&sv_yes); XSRETURN(1)
#define XSRETURNUNDEF ST(0)=sv_mortalcopy(&sv_undef); XSRETURN(1)
