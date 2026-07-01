MODULE = XS::APItest            PACKAGE = XS::APItest

void
assertx(int x)
    CODE:
        /* this only needs to compile and checks that assert() can be
           used this way syntactically */
        (void)(assert(x), 1);
        (void)(x);

void
print_double(val)
        double val
        CODE:
        printf("%5.3f\n",val);

int
have_long_double()
        CODE:
#ifdef HAS_LONG_DOUBLE
        RETVAL = 1;
#else
        RETVAL = 0;
#endif
        OUTPUT:
        RETVAL

void
print_long_double()
        CODE:
#ifdef HAS_LONG_DOUBLE
#   if defined(PERL_PRIfldbl) && (LONG_DOUBLESIZE > DOUBLESIZE)
        long double val = 7.0;
        printf("%5.3" PERL_PRIfldbl "\n",val);
#   else
        double val = 7.0;
        printf("%5.3f\n",val);
#   endif
#endif

void
print_long_doubleL()
        CODE:
#ifdef HAS_LONG_DOUBLE
        /* used to test we allow the length modifier required by the standard */
        long double val = 7.0;
        printf("%5.3Lf\n",val);
#else
        double val = 7.0;
        printf("%5.3f\n",val);
#endif

void
print_int(val)
        int val
        CODE:
        printf("%d\n",val);

void
print_long(val)
        long val
        CODE:
        printf("%ld\n",val);

void
print_float(val)
        float val
        CODE:
        printf("%5.3f\n",val);

void
print_flush()
        CODE:
        fflush(stdout);

void
mpushp()
        PPCODE:
        EXTEND(SP, 3);
        mPUSHp("one", 3);
        mPUSHp("two", 3);
        mPUSHpvs("three");
        XSRETURN(3);

void
mpushn()
        PPCODE:
        EXTEND(SP, 3);
        mPUSHn(0.5);
        mPUSHn(-0.25);
        mPUSHn(0.125);
        XSRETURN(3);

void
mpushi()
        PPCODE:
        EXTEND(SP, 3);
        mPUSHi(-1);
        mPUSHi(2);
        mPUSHi(-3);
        XSRETURN(3);

void
mpushu()
        PPCODE:
        EXTEND(SP, 3);
        mPUSHu(1);
        mPUSHu(2);
        mPUSHu(3);
        XSRETURN(3);

void
mxpushp()
        PPCODE:
        mXPUSHp("one", 3);
        mXPUSHp("two", 3);
        mXPUSHpvs("three");
        XSRETURN(3);

void
mxpushn()
        PPCODE:
        mXPUSHn(0.5);
        mXPUSHn(-0.25);
        mXPUSHn(0.125);
        XSRETURN(3);

void
mxpushi()
        PPCODE:
        mXPUSHi(-1);
        mXPUSHi(2);
        mXPUSHi(-3);
        XSRETURN(3);

void
mxpushu()
        PPCODE:
        mXPUSHu(1);
        mXPUSHu(2);
        mXPUSHu(3);
        XSRETURN(3);


 # test_EXTEND(): excerise the EXTEND() macro.
 # After calling EXTEND(), it also does *(p+n) = NULL and
 # *PL_stack_max = NULL to allow valgrind etc to spot if the stack hasn't
 # actually been extended properly.
 #
 # max_offset specifies the SP to use.  It is treated as a signed offset
 #              from PL_stack_max.
 # nsv        is the SV holding the value of n indicating how many slots
 #              to extend the stack by.
 # use_ss     is a boolean indicating that n should be cast to a SSize_t

void
test_EXTEND(max_offset, nsv, use_ss)
    IV   max_offset;
    SV  *nsv;
    bool use_ss;
PREINIT:
    SV **new_sp = PL_stack_max + max_offset;
    SSize_t new_offset = new_sp - PL_stack_base;
PPCODE:
    if (use_ss) {
        SSize_t n = (SSize_t)SvIV(nsv);
        EXTEND(new_sp, n);
        new_sp = PL_stack_base + new_offset;
        assert(new_sp + n <= PL_stack_max);
        if ((new_sp + n) > PL_stack_sp)
            *(new_sp + n) = NULL;
    }
    else {
        IV n = SvIV(nsv);
        EXTEND(new_sp, n);
        new_sp = PL_stack_base + new_offset;
        assert(new_sp + n <= PL_stack_max);
        if ((new_sp + n) > PL_stack_sp)
            *(new_sp + n) = NULL;
    }
    if (PL_stack_max > PL_stack_sp)
        *PL_stack_max = NULL;


void
bad_EXTEND()
    PPCODE:
        /* testing failure to extend the stack, do not extend the stack */
        PUSHs(&PL_sv_yes);
        PUSHs(&PL_sv_no);
        XSRETURN(2);

bool
hwm_checks_enabled()
