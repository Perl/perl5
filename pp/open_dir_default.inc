{
    dSP;
    const char * const dirname = POPpconstx;
    GV * const gv = MUTABLE_GV(POPs);
    IO * const io = GvIOn(gv);

    if ((IoIFP(io) || IoOFP(io)))
        Perl_croak(aTHX_ "Cannot open %" HEKf " as a dirhandle: it is already open as a filehandle",
                         HEKfARG(GvENAME_HEK(gv)));
    if (IoDIRP(io))
        PerlDir_close(IoDIRP(io));
    if (!(IoDIRP(io) = PerlDir_open(dirname)))
        goto nope;

    RETPUSHYES;
  nope:
    if (!errno)
        SETERRNO(EBADF,RMS_DIR);
    RETPUSHUNDEF;
}
