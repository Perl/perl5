{
#if !defined(I_DIRENT) && !defined(VMS)
    Direntry_t *readdir (DIR *);
#endif
    dSP;

    SV *sv;
    const U8 gimme = GIMME_V;
    GV * const gv = MUTABLE_GV(POPs);
    const Direntry_t *dp;
    IO * const io = GvIOn(gv);

    if (!IoDIRP(io)) {
        Perl_ck_warner(aTHX_ packWARN(WARN_IO),
                       "readdir() attempted on invalid dirhandle %" HEKf,
                            HEKfARG(GvENAME_HEK(gv)));
        goto nope;
    }

    do {
        dp = (Direntry_t *)PerlDir_read(IoDIRP(io));
        if (!dp)
            break;
#ifdef DIRNAMLEN
        sv = newSVpvn(dp->d_name, dp->d_namlen);
#else
        sv = newSVpv(dp->d_name, 0);
#endif
        if (!(IoFLAGS(io) & IOf_UNTAINT))
            SvTAINTED_on(sv);
        mXPUSHs(sv);
    } while (gimme == G_LIST);

    if (!dp && gimme != G_LIST)
        RETPUSHUNDEF;

    RETURN;

  nope:
    if (!errno)
        SETERRNO(EBADF,RMS_ISI);
    if (gimme == G_LIST)
        RETURN;
    else
        RETPUSHUNDEF;
}
