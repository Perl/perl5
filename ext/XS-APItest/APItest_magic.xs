MODULE = XS::APItest            PACKAGE = XS::APItest::Magic

PROTOTYPES: DISABLE

void
sv_magic_foo(SV *sv, SV *thingy)
ALIAS:
    sv_magic_bar = 1
    sv_magic_baz = 2
CODE:
    sv_magicext(sv, NULL, ix == 2 ? PERL_MAGIC_extvalue : PERL_MAGIC_ext, ix ? &vtbl_bar : &vtbl_foo, (const char *)thingy, 0);

SV *
mg_find_foo(SV *sv)
ALIAS:
    mg_find_bar = 1
    mg_find_baz = 2
CODE:
	RETVAL = &PL_sv_undef;
	if (SvTYPE(sv) >= SVt_PVMG) {
		MAGIC *mg = mg_findext(sv, ix == 2 ? PERL_MAGIC_extvalue : PERL_MAGIC_ext, ix ? &vtbl_bar : &vtbl_foo);
		if (mg)
			RETVAL = SvREFCNT_inc((SV *)mg->mg_ptr);
	}
OUTPUT:
    RETVAL

void
sv_unmagic_foo(SV *sv)
ALIAS:
    sv_unmagic_bar = 1
    sv_unmagic_baz = 2
CODE:
    sv_unmagicext(sv, ix == 2 ? PERL_MAGIC_extvalue : PERL_MAGIC_ext, ix ? &vtbl_bar : &vtbl_foo);

void
sv_magic(SV *sv, SV *thingy)
CODE:
    sv_magic(sv, NULL, PERL_MAGIC_ext, (const char *)thingy, 0);

UV
test_get_vtbl()
    PREINIT:
        MGVTBL *have;
        MGVTBL *want;
    CODE:
#define test_get_this_vtable(name) \
        want = (MGVTBL*)CAT2(&PL_vtbl_, name); \
        have = get_vtbl(CAT2(want_vtbl_, name)); \
        if (have != want) \
            croak("fail %p!=%p for get_vtbl(want_vtbl_" STRINGIFY(name) ") at " __FILE__ " line %d", have, want, __LINE__)

        test_get_this_vtable(sv);
        test_get_this_vtable(env);
        test_get_this_vtable(envelem);
        test_get_this_vtable(sigelem);
        test_get_this_vtable(pack);
        test_get_this_vtable(packelem);
        test_get_this_vtable(dbline);
        test_get_this_vtable(isa);
        test_get_this_vtable(isaelem);
        test_get_this_vtable(arylen);
        test_get_this_vtable(mglob);
        test_get_this_vtable(nkeys);
        test_get_this_vtable(taint);
        test_get_this_vtable(substr);
        test_get_this_vtable(vec);
        test_get_this_vtable(pos);
        test_get_this_vtable(bm);
        test_get_this_vtable(fm);
        test_get_this_vtable(uvar);
        test_get_this_vtable(defelem);
        test_get_this_vtable(regexp);
        test_get_this_vtable(regdata);
        test_get_this_vtable(regdatum);
#ifdef USE_LOCALE_COLLATE
        test_get_this_vtable(collxfrm);
#endif
        test_get_this_vtable(backref);
        test_get_this_vtable(utf8);

        RETVAL = PTR2UV(get_vtbl(-1));
    OUTPUT:
        RETVAL


    # attach ext magic to the SV pointed to by rsv that only has set magic,
    # where that magic's job is to increment thingy

void
sv_magic_myset_dies(SV *rsv, SV *thingy)
CODE:
    sv_magicext(SvRV(rsv), NULL, PERL_MAGIC_ext, &vtbl_myset_dies,
        (const char *)thingy, 0);


void
sv_magic_myset(SV *rsv, SV *thingy)
CODE:
    sv_magicext(SvRV(rsv), NULL, PERL_MAGIC_ext, &vtbl_myset,
        (const char *)thingy, 0);

void
sv_magic_mycopy(SV *rsv)
    PREINIT:
        MAGIC *mg;
    CODE:
        /* It's only actually useful to attach this to arrays and hashes. */
        mg = sv_magicext(SvRV(rsv), NULL, PERL_MAGIC_ext, &vtbl_mycopy, NULL, 0);
        mg->mg_flags = MGf_COPY;

SV *
sv_magic_mycopy_count(SV *rsv)
    PREINIT:
        MAGIC *mg;
    CODE:
        mg = mg_findext(SvRV(rsv), PERL_MAGIC_ext, &vtbl_mycopy);
        RETVAL = mg ? newSViv(mg->mg_private) : &PL_sv_undef;
    OUTPUT:
        RETVAL

int
my_av_store(SV *rsv, IV i, SV *sv)
    CODE:
        if (av_store((AV*)SvRV(rsv), i, sv)) {
            SvREFCNT_inc(sv);
            RETVAL = 1;
        } else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

STRLEN
sv_refcnt(SV *sv)
    CODE:
        RETVAL = SvREFCNT(sv);
    OUTPUT:
        RETVAL

void
test_mortal_destructor_sv(SV *coderef, SV *args)
    CODE:
        MORTALDESTRUCTOR_SV(coderef,args);

void
test_mortal_destructor_av(SV *coderef, AV *args)
    CODE:
        /* passing in an AV cast to SV is different from a SV ref to an AV */
        MORTALDESTRUCTOR_SV(coderef, (SV *)args);

void
test_mortal_svfunc_x(SV *args)
    CODE:
        MORTALSVFUNC_X(&destruct_test,args);
