{
    dSP;
    GV * const gv = MUTABLE_GV(POPs);
    IO * const io = GvIOn(gv);

    if (!IoDIRP(io)) {
        Perl_ck_warner(aTHX_ packWARN(WARN_IO),
                       "closedir() attempted on invalid dirhandle %" HEKf,
                                HEKfARG(GvENAME_HEK(gv)));
        goto nope;
    }
#ifdef VOID_CLOSEDIR
    PerlDir_close(IoDIRP(io));
#else
    if (PerlDir_close(IoDIRP(io)) < 0) {
        IoDIRP(io) = 0; /* Don't try to close again--coredumps on SysV */
        goto nope;
    }
#endif
    IoDIRP(io) = 0;

    RETPUSHYES;
  nope:
    if (!errno)
        SETERRNO(EBADF,RMS_IFI);
    RETPUSHUNDEF;
}
