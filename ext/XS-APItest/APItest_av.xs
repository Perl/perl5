MODULE = XS::APItest            PACKAGE = XS::APItest::av

void
av_splice_simple(AV *av, IV idx, IV delcount, ...)
    PROTOTYPE: \@$$@
    PPCODE:
    {
        Size_t inscount = items - 3;
        SV **in_svs = NULL, **out_svs = NULL;

        if (inscount) {
            Newx(in_svs, inscount, SV *);
            SAVEFREEPV(in_svs);

            for (Size_t i = 0; i < inscount; i++)
                in_svs[i] = newSVsv(ST(i + 3));
        }

        if (delcount && GIMME_V == G_LIST) {
            Newx(out_svs, delcount, SV *);
            SAVEFREEPV(out_svs);
        }

        Size_t out_count = av_splice_simple(av, idx, delcount, inscount, in_svs, out_svs);

        if (out_svs && out_count) {
            EXTEND(SP, (IV)out_count);

            for (Size_t i = 0; i < out_count; i++)
                mPUSHs(out_svs[i]);

            XSRETURN(out_count);
        }
    }
