*** /scalpel/lwall/perl5alpha4/gv.c	Fri Jan 14 04:28:25 1994
--- gv.c	Fri Jan 14 14:05:38 1994
***************
*** 133,151 ****
  	SV** svp = AvARRAY(av);
  	I32 items = AvFILL(av) + 1;
  	while (items--) {
- 	    char tmpbuf[512];
  	    SV* sv = *svp++;
! 	    *tmpbuf = '_';
! 	    SvUPGRADE(sv, SVt_PV);
! 	    strcpy(tmpbuf+1, SvPV(sv, na));
! 	    gv = gv_fetchpv(tmpbuf,FALSE);
! 	    if (!gv || !(stash = GvHV(gv))) {
  		if (dowarn)
  		    warn("Can't locate package %s for @%s'ISA",
  			SvPVX(sv), HvNAME(stash));
  		continue;
  	    }
! 	    gv = gv_fetchmeth(stash, name, len);
  	    if (gv) {
  		GvCV(topgv) = GvCV(gv);			/* cache the CV */
  		GvCVGEN(topgv) = sub_generation;	/* valid for now */
--- 133,147 ----
  	SV** svp = AvARRAY(av);
  	I32 items = AvFILL(av) + 1;
  	while (items--) {
  	    SV* sv = *svp++;
! 	    HV* basestash = fetch_stash(sv, FALSE);
! 	    if (!basestash) {
  		if (dowarn)
  		    warn("Can't locate package %s for @%s'ISA",
  			SvPVX(sv), HvNAME(stash));
  		continue;
  	    }
! 	    gv = gv_fetchmeth(basestash, name, len);
  	    if (gv) {
  		GvCV(topgv) = GvCV(gv);			/* cache the CV */
  		GvCVGEN(topgv) = sub_generation;	/* valid for now */
