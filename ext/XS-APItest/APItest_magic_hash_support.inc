static int
S_myset_set(pTHX_ SV* sv, MAGIC* mg)
{
    SV *isv = (SV*)mg->mg_ptr;

    PERL_UNUSED_ARG(sv);
    SvIVX(isv)++;
    return 0;
}

static int
S_myset_set_dies(pTHX_ SV* sv, MAGIC* mg)
{
    PERL_UNUSED_ARG(sv);
    PERL_UNUSED_ARG(mg);
    croak("in S_myset_set_dies");
    return 0;
}


static MGVTBL vtbl_foo, vtbl_bar;
static MGVTBL vtbl_myset = { 0, S_myset_set, 0, 0, 0, 0, 0, 0 };
static MGVTBL vtbl_myset_dies = { 0, S_myset_set_dies, 0, 0, 0, 0, 0, 0 };

static int
S_mycopy_copy(pTHX_ SV *sv, MAGIC* mg, SV *nsv, const char *name, I32 namlen) {
    PERL_UNUSED_ARG(sv);
    PERL_UNUSED_ARG(nsv);
    PERL_UNUSED_ARG(name);
    PERL_UNUSED_ARG(namlen);

    /* Count that we were called to "copy".
       There's actually no point in copying *this* magic onto nsv, as it's a
       SCALAR, whereas mg_copy is only triggered for ARRAYs and HASHes.
       It's not *exactly* generic. :-( */
    ++mg->mg_private;
    return 0;
}

static MGVTBL vtbl_mycopy = { 0, 0, 0, 0, 0, S_mycopy_copy, 0, 0 };

/* A routine to test hv_delayfree_ent
   (which itself is tested by testing on hv_free_ent  */

typedef void (freeent_function)(pTHX_ HV *, HE *);

void
test_freeent(freeent_function *f) {
    dSP;
    HV *test_hash = newHV();
    HE *victim;
    SV *test_scalar;
    U32 results[4];
    int i;

#ifdef PURIFY
    victim = (HE*)safemalloc(sizeof(HE));
#else
    /* Storing then deleting something should ensure that a hash entry is
       available.  */
    (void) hv_stores(test_hash, "", &PL_sv_yes);
    (void) hv_deletes(test_hash, "", 0);

    /* We need to "inline" new_he here as it's static, and the functions we
       test expect to be able to call del_HE on the HE  */
    if (!PL_body_roots[HE_ARENA_ROOT_IX])
        croak("PL_he_root is 0");
    victim = (HE*) PL_body_roots[HE_ARENA_ROOT_IX];
    PL_body_roots[HE_ARENA_ROOT_IX] = HeNEXT(victim);
#endif

#ifdef NODEFAULT_SHAREKEYS
    HvSHAREKEYS_on(test_hash);
#endif

    victim->hent_hek = Perl_share_hek(aTHX_ "", 0, 0);

    test_scalar = newSV(0);
    SvREFCNT_inc(test_scalar);
    HeVAL(victim) = test_scalar;

    /* Need this little game else we free the temps on the return stack.  */
    results[0] = SvREFCNT(test_scalar);
    SAVETMPS;
    results[1] = SvREFCNT(test_scalar);
    f(aTHX_ test_hash, victim);
    results[2] = SvREFCNT(test_scalar);
    FREETMPS;
    results[3] = SvREFCNT(test_scalar);

    i = 0;
    do {
        mXPUSHu(results[i]);
    } while (++i < (int)(sizeof(results)/sizeof(results[0])));

    /* Goodbye to our extra reference.  */
    SvREFCNT_dec(test_scalar);
}

/* Not that it matters much, but it's handy for the flipped character to just
 * be the opposite case (at least for ASCII-range and most Latin1 as well). */
#define FLIP_BIT ('A' ^ 'a')

static I32
bitflip_key(pTHX_ IV action, SV *field) {
    MAGIC *mg = mg_find(field, PERL_MAGIC_uvar);
    SV *keysv;
    PERL_UNUSED_ARG(action);
    if (mg && (keysv = mg->mg_obj)) {
        STRLEN len;
        const char *p = SvPV(keysv, len);

        if (len) {
            /* Allow for the flipped val to be longer than the original.  This
             * is just for testing, so can afford to have some slop */
            const STRLEN newlen = len * 2;

            SV *newkey = newSV(newlen);
            const char * const new_p_orig = SvPVX(newkey);
            char *new_p = (char *) new_p_orig;

            if (SvUTF8(keysv)) {
                const char *const end = p + len;
                while (p < end) {
                    STRLEN curlen;
                    UV chr = utf8_to_uvchr_buf((U8 *)p, (U8 *) end, &curlen);

                    /* Make sure don't exceed bounds */
                    assert(new_p - new_p_orig + curlen < newlen);

                    new_p = (char *)uvchr_to_utf8((U8 *)new_p, chr ^ FLIP_BIT);
                    p += curlen;
                }
                SvUTF8_on(newkey);
            } else {
                while (len--)
                    *new_p++ = *p++ ^ FLIP_BIT;
            }
            *new_p = '\0';
            SvCUR_set(newkey, new_p - new_p_orig);
            SvPOK_on(newkey);

            mg->mg_obj = newkey;
        }
    }
    return 0;
}

static I32
rot13_key(pTHX_ IV action, SV *field) {
    MAGIC *mg = mg_find(field, PERL_MAGIC_uvar);
    SV *keysv;
    PERL_UNUSED_ARG(action);
    if (mg && (keysv = mg->mg_obj)) {
        STRLEN len;
        const char *p = SvPV(keysv, len);

        if (len) {
            SV *newkey = newSV(len);
            char *new_p = SvPVX(newkey);

            /* There's a deliberate fencepost error here to loop len + 1 times
               to copy the trailing \0  */
            do {
                char new_c = *p++;
                /* Try doing this cleanly and clearly in EBCDIC another way: */
                switch (new_c) {
                case 'A': new_c = 'N'; break;
                case 'B': new_c = 'O'; break;
                case 'C': new_c = 'P'; break;
                case 'D': new_c = 'Q'; break;
                case 'E': new_c = 'R'; break;
                case 'F': new_c = 'S'; break;
                case 'G': new_c = 'T'; break;
                case 'H': new_c = 'U'; break;
                case 'I': new_c = 'V'; break;
                case 'J': new_c = 'W'; break;
                case 'K': new_c = 'X'; break;
                case 'L': new_c = 'Y'; break;
                case 'M': new_c = 'Z'; break;
                case 'N': new_c = 'A'; break;
                case 'O': new_c = 'B'; break;
                case 'P': new_c = 'C'; break;
                case 'Q': new_c = 'D'; break;
                case 'R': new_c = 'E'; break;
                case 'S': new_c = 'F'; break;
                case 'T': new_c = 'G'; break;
                case 'U': new_c = 'H'; break;
                case 'V': new_c = 'I'; break;
                case 'W': new_c = 'J'; break;
                case 'X': new_c = 'K'; break;
                case 'Y': new_c = 'L'; break;
                case 'Z': new_c = 'M'; break;
                case 'a': new_c = 'n'; break;
                case 'b': new_c = 'o'; break;
                case 'c': new_c = 'p'; break;
                case 'd': new_c = 'q'; break;
                case 'e': new_c = 'r'; break;
                case 'f': new_c = 's'; break;
                case 'g': new_c = 't'; break;
                case 'h': new_c = 'u'; break;
                case 'i': new_c = 'v'; break;
                case 'j': new_c = 'w'; break;
                case 'k': new_c = 'x'; break;
                case 'l': new_c = 'y'; break;
                case 'm': new_c = 'z'; break;
                case 'n': new_c = 'a'; break;
                case 'o': new_c = 'b'; break;
                case 'p': new_c = 'c'; break;
                case 'q': new_c = 'd'; break;
                case 'r': new_c = 'e'; break;
                case 's': new_c = 'f'; break;
                case 't': new_c = 'g'; break;
                case 'u': new_c = 'h'; break;
                case 'v': new_c = 'i'; break;
                case 'w': new_c = 'j'; break;
                case 'x': new_c = 'k'; break;
                case 'y': new_c = 'l'; break;
                case 'z': new_c = 'm'; break;
                }
                *new_p++ = new_c;
            } while (len--);
            SvCUR_set(newkey, SvCUR(keysv));
            SvPOK_on(newkey);
            if (SvUTF8(keysv))
                SvUTF8_on(newkey);

            mg->mg_obj = newkey;
        }
    }
    return 0;
}

static I32
rmagical_a_dummy(pTHX_ IV idx, SV *sv) {
    PERL_UNUSED_ARG(idx);
    PERL_UNUSED_ARG(sv);
    return 0;
}

/* We could do "= { 0 };" but some versions of gcc do warn
 * (with -Wextra) about missing initializer, this is probably gcc
 * being a bit too paranoid.  But since this is file-static, we can
 * just have it without initializer, since it should get
 * zero-initialized. */
static MGVTBL rmagical_b;
