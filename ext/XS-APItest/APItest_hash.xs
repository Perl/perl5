MODULE = XS::APItest:Hash               PACKAGE = XS::APItest::Hash

void
rot13_hash(hash)
        HV *hash
        CODE:
        {
            struct ufuncs uf;
            uf.uf_val = rot13_key;
            uf.uf_set = 0;
            uf.uf_index = 0;

            sv_magic((SV*)hash, NULL, PERL_MAGIC_uvar, (char*)&uf, sizeof(uf));
        }

void
bitflip_hash(hash)
        HV *hash
        CODE:
        {
            struct ufuncs uf;
            uf.uf_val = bitflip_key;
            uf.uf_set = 0;
            uf.uf_index = 0;

            sv_magic((SV*)hash, NULL, PERL_MAGIC_uvar, (char*)&uf, sizeof(uf));
        }

#define UTF8KLEN(sv, len)   (SvUTF8(sv) ? -(I32)len : (I32)len)

bool
exists(hash, key_sv)
        PREINIT:
        STRLEN len;
        const char *key;
        INPUT:
        HV *hash
        SV *key_sv
        CODE:
        key = SvPV(key_sv, len);
        RETVAL = hv_exists(hash, key, UTF8KLEN(key_sv, len));
        OUTPUT:
        RETVAL

bool
exists_ent(hash, key_sv)
        PREINIT:
        INPUT:
        HV *hash
        SV *key_sv
        CODE:
        RETVAL = hv_exists_ent(hash, key_sv, 0);
        OUTPUT:
        RETVAL

SV *
delete(hash, key_sv, flags = 0)
        PREINIT:
        STRLEN len;
        const char *key;
        INPUT:
        HV *hash
        SV *key_sv
        I32 flags;
        CODE:
        key = SvPV(key_sv, len);
        /* It's already mortal, so need to increase reference count.  */
        RETVAL
            = SvREFCNT_inc(hv_delete(hash, key, UTF8KLEN(key_sv, len), flags));
        OUTPUT:
        RETVAL

SV *
delete_ent(hash, key_sv, flags = 0)
        INPUT:
        HV *hash
        SV *key_sv
        I32 flags;
        CODE:
        /* It's already mortal, so need to increase reference count.  */
        RETVAL = SvREFCNT_inc(hv_delete_ent(hash, key_sv, flags, 0));
        OUTPUT:
        RETVAL

SV *
store_ent(hash, key, value)
        PREINIT:
        SV *copy;
        HE *result;
        INPUT:
        HV *hash
        SV *key
        SV *value
        CODE:
        copy = newSV(0);
        result = hv_store_ent(hash, key, copy, 0);
        SvSetMagicSV(copy, value);
        if (!result) {
            SvREFCNT_dec(copy);
            XSRETURN_EMPTY;
        }
        /* It's about to become mortal, so need to increase reference count.
         */
        RETVAL = SvREFCNT_inc(HeVAL(result));
        OUTPUT:
        RETVAL

SV *
store(hash, key_sv, value)
        PREINIT:
        STRLEN len;
        const char *key;
        SV *copy;
        SV **result;
        INPUT:
        HV *hash
        SV *key_sv
        SV *value
        CODE:
        key = SvPV(key_sv, len);
        copy = newSV(0);
        result = hv_store(hash, key, UTF8KLEN(key_sv, len), copy, 0);
        SvSetMagicSV(copy, value);
        if (!result) {
            SvREFCNT_dec(copy);
            XSRETURN_EMPTY;
        }
        /* It's about to become mortal, so need to increase reference count.
         */
        RETVAL = SvREFCNT_inc(*result);
        OUTPUT:
        RETVAL

SV *
fetch_ent(hash, key_sv)
        PREINIT:
        HE *result;
        INPUT:
        HV *hash
        SV *key_sv
        CODE:
        result = hv_fetch_ent(hash, key_sv, 0, 0);
        if (!result) {
            XSRETURN_EMPTY;
        }
        /* Force mg_get  */
        RETVAL = newSVsv(HeVAL(result));
        OUTPUT:
        RETVAL

SV *
fetch(hash, key_sv)
        PREINIT:
        STRLEN len;
        const char *key;
        SV **result;
        INPUT:
        HV *hash
        SV *key_sv
        CODE:
        key = SvPV(key_sv, len);
        result = hv_fetch(hash, key, UTF8KLEN(key_sv, len), 0);
        if (!result) {
            XSRETURN_EMPTY;
        }
        /* Force mg_get  */
        RETVAL = newSVsv(*result);
        OUTPUT:
        RETVAL

SV *
common(params)
        INPUT:
        HV *params
        PREINIT:
        HE *result;
        HV *hv = NULL;
        SV *keysv = NULL;
        const char *key = NULL;
        STRLEN klen = 0;
        int flags = 0;
        int action = 0;
        SV *val = NULL;
        U32 hash = 0;
        SV **svp;
        CODE:
        if ((svp = hv_fetchs(params, "hv", 0))) {
            SV *const rv = *svp;
            if (!SvROK(rv))
                croak("common passed a non-reference for parameter hv");
            hv = (HV *)SvRV(rv);
        }
        if ((svp = hv_fetchs(params, "keysv", 0)))
            keysv = *svp;
        if ((svp = hv_fetchs(params, "keypv", 0))) {
            key = SvPV_const(*svp, klen);
            if (SvUTF8(*svp))
                flags = HVhek_UTF8;
        }
        if ((svp = hv_fetchs(params, "action", 0)))
            action = SvIV(*svp);
        if ((svp = hv_fetchs(params, "val", 0)))
            val = newSVsv(*svp);
        if ((svp = hv_fetchs(params, "hash", 0)))
            hash = SvUV(*svp);

        if (hv_fetchs(params, "hash_pv", 0)) {
            assert(key);
            PERL_HASH(hash, key, klen);
        }
        if (hv_fetchs(params, "hash_sv", 0)) {
            assert(keysv);
            {
              STRLEN len;
              const char *const p = SvPV(keysv, len);
              PERL_HASH(hash, p, len);
            }
        }

        result = (HE *)hv_common(hv, keysv, key, klen, flags, action, val, hash);
        if (!result) {
            XSRETURN_EMPTY;
        }
        /* Force mg_get  */
        RETVAL = newSVsv(HeVAL(result));
        OUTPUT:
        RETVAL

void
test_hv_free_ent()
        PPCODE:
        test_freeent(&Perl_hv_free_ent);
        XSRETURN(4);

void
test_hv_delayfree_ent()
        PPCODE:
        test_freeent(&Perl_hv_delayfree_ent);
        XSRETURN(4);

SV *
test_share_unshare_pvn(input)
        PREINIT:
        STRLEN len;
        U32 hash;
        char *pvx;
        char *p;
        INPUT:
        SV *input
        CODE:
        pvx = SvPV(input, len);
        PERL_HASH(hash, pvx, len);
        p = sharepvn(pvx, len, hash);
        RETVAL = newSVpvn(p, len);
        unsharepvn(p, len, hash);
        OUTPUT:
        RETVAL

bool
refcounted_he_exists(key, level=0)
        SV *key
        IV level
        CODE:
        if (level) {
            croak("level must be zero, not %" IVdf, level);
        }
        RETVAL = (cop_hints_fetch_sv(PL_curcop, key, 0, 0) != &PL_sv_placeholder);
        OUTPUT:
        RETVAL

SV *
refcounted_he_fetch(key, level=0)
        SV *key
        IV level
        CODE:
        if (level) {
            croak("level must be zero, not %" IVdf, level);
        }
        RETVAL = cop_hints_fetch_sv(PL_curcop, key, 0, 0);
        SvREFCNT_inc(RETVAL);
        OUTPUT:
        RETVAL

void
test_force_keys(HV *hv)
    PREINIT:
        HE *he;
        SSize_t count = 0;
    PPCODE:
        hv_iterinit(hv);
        he = hv_iternext(hv);
        while (he) {
            SV *sv = HeSVKEY_force(he);
            ++count;
            EXTEND(SP, count);
            PUSHs(sv_mortalcopy(sv));
            he = hv_iternext(hv);
        }

=pod

sub TIEHASH  { bless {}, $_[0] }
sub STORE    { $_[0]->{$_[1]} = $_[2] }
sub FETCH    { $_[0]->{$_[1]} }
sub FIRSTKEY { my $a = scalar keys %{$_[0]}; each %{$_[0]} }
sub NEXTKEY  { each %{$_[0]} }
sub EXISTS   { exists $_[0]->{$_[1]} }
sub DELETE   { delete $_[0]->{$_[1]} }
sub CLEAR    { %{$_[0]} = () }

=cut
