#define ST(off) stack_base[ax + (off)]

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
#define XST_mIV(i,v)  (ST(i) = sv_2mortal(newSViv(v))  )
#define XST_mNV(i,v)  (ST(i) = sv_2mortal(newSVnv(v))  )
#define XST_mPV(i,v)  (ST(i) = sv_2mortal(newSVpv(v,0)))
#define XST_mNO(i)    (ST(i) = &sv_no   )
#define XST_mYES(i)   (ST(i) = &sv_yes  )
#define XST_mUNDEF(i) (ST(i) = &sv_undef)
 
#define XSRETURN_IV(v) do { XST_mIV(0,v);  XSRETURN(1); } while (0)
#define XSRETURN_NV(v) do { XST_mNV(0,v);  XSRETURN(1); } while (0)
#define XSRETURN_PV(v) do { XST_mPV(0,v);  XSRETURN(1); } while (0)
#define XSRETURN_NO    do { XST_mNO(0);    XSRETURN(1); } while (0)
#define XSRETURN_YES   do { XST_mYES(0);   XSRETURN(1); } while (0)
#define XSRETURN_UNDEF do { XST_mUNDEF(0); XSRETURN(1); } while (0)
#define XSRETURN_EMPTY do {                XSRETURN(0); } while (0)

#define newXSproto(a,b,c,d)	sv_setpv((SV*)newXS(a,b,c), d)

#ifdef XS_VERSION
# define XS_VERSION_BOOTCHECK \
    do {                                                                      \
        char vn[255], *module = SvPV(ST(0),na);                               \
        if (items >= 2)         /* version supplied as bootstrap arg */       \
            Sv=ST(1);                                                         \
        else {                  /* read version from module::VERSION */       \
            sprintf(vn,"%s::VERSION", module);                                \
            Sv = perl_get_sv(vn, FALSE);   /* XXX GV_ADDWARN */               \
        }                                                                     \
        if (Sv && (!SvOK(Sv) || strNE(XS_VERSION, SvPV(Sv,na))) )             \
            croak("%s object version %s does not match %s.pm $VERSION %s",    \
              module,XS_VERSION, module,(Sv && SvOK(Sv))?SvPV(Sv,na):"(undef)");\
    } while (0)
#else
# define XS_VERSION_BOOTCHECK
#endif

