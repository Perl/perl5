/*    pp_sys.c
 *
 *    Copyright (c) 1991-1994, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/*
 * But only a short way ahead its floor and the walls on either side were
 * cloven by a great fissure, out of which the red glare came, now leaping
 * up, now dying down into darkness; and all the while far below there was
 * a rumour and a trouble as of great engines throbbing and labouring.
 */

#include "EXTERN.h"
#include "perl.h"

/* Omit this -- it causes too much grief on mixed systems.
#ifdef I_UNISTD
#include <unistd.h>
#endif
*/

/* Put this after #includes because fork and vfork prototypes may
   conflict.
*/
#ifndef HAS_VFORK
#   define vfork fork
#endif

#if defined(HAS_SOCKET) && !defined(VMS) /* VMS handles sockets via vmsish.h */
# include <sys/socket.h>
# include <netdb.h>
# ifndef ENOTSOCK
#  ifdef I_NET_ERRNO
#   include <net/errno.h>
#  endif
# endif
#endif

#ifdef HAS_SELECT
#ifdef I_SYS_SELECT
#ifndef I_SYS_TIME
#include <sys/select.h>
#endif
#endif
#endif

#ifdef HOST_NOT_FOUND
extern int h_errno;
#endif

#ifdef HAS_PASSWD
# ifdef I_PWD
#  include <pwd.h>
# else
    struct passwd *getpwnam _((char *));
    struct passwd *getpwuid _((Uid_t));
# endif
  struct passwd *getpwent _((void));
#endif

#ifdef HAS_GROUP
# ifdef I_GRP
#  include <grp.h>
# else
    struct group *getgrnam _((char *));
    struct group *getgrgid _((Gid_t));
# endif
    struct group *getgrent _((void));
#endif

#ifdef I_UTIME
#include <utime.h>
#endif
#ifdef I_FCNTL
#include <fcntl.h>
#endif
#ifdef I_SYS_FILE
#include <sys/file.h>
#endif

#ifdef HAS_GETPGRP2
#   define getpgrp getpgrp2
#endif

#ifdef HAS_SETPGRP2
#   define setpgrp setpgrp2
#endif

#if !defined(HAS_MKDIR) || !defined(HAS_RMDIR)
static int dooneliner _((char *cmd, char *filename));
#endif
/* Pushy I/O. */

PP(pp_backtick)
{
    dSP; dTARGET;
    FILE *fp;
    char *tmps = POPp;
    TAINT_PROPER("``");
    fp = my_popen(tmps, "r");
    if (fp) {
	sv_setpv(TARG, "");	/* note that this preserves previous buffer */
	if (GIMME == G_SCALAR) {
	    while (sv_gets(TARG, fp, SvCUR(TARG)) != Nullch)
		/*SUPPRESS 530*/
		;
	    XPUSHs(TARG);
	}
	else {
	    SV *sv;

	    for (;;) {
		sv = NEWSV(56, 80);
		if (sv_gets(sv, fp, 0) == Nullch) {
		    SvREFCNT_dec(sv);
		    break;
		}
		XPUSHs(sv_2mortal(sv));
		if (SvLEN(sv) - SvCUR(sv) > 20) {
		    SvLEN_set(sv, SvCUR(sv)+1);
		    Renew(SvPVX(sv), SvLEN(sv), char);
		}
	    }
	}
	statusvalue = my_pclose(fp);
    }
    else {
	statusvalue = -1;
	if (GIMME == G_SCALAR)
	    RETPUSHUNDEF;
    }

    RETURN;
}

PP(pp_glob)
{
    OP *result;
    ENTER;
    SAVEINT(rschar);
    SAVEINT(rslen);

    SAVESPTR(last_in_gv);	/* We don't want this to be permanent. */
    last_in_gv = (GV*)*stack_sp--;

    rslen = 1;
#ifdef DOSISH
    rschar = 0;
#else
#ifdef CSH
    rschar = 0;
#else
    rschar = '\n';
#endif	/* !CSH */
#endif	/* !MSDOS */
    result = do_readline();
    LEAVE;
    return result;
}

PP(pp_indread)
{
    last_in_gv = gv_fetchpv(SvPVx(GvSV((GV*)(*stack_sp--)), na), TRUE,SVt_PVIO);
    return do_readline();
}

PP(pp_rcatline)
{
    last_in_gv = cGVOP->op_gv;
    return do_readline();
}

PP(pp_warn)
{
    dSP; dMARK;
    char *tmps;
    if (SP - MARK != 1) {
	dTARGET;
	do_join(TARG, &sv_no, MARK, SP);
	tmps = SvPV(TARG, na);
	SP = MARK + 1;
    }
    else {
	tmps = SvPV(TOPs, na);
    }
    if (!tmps || !*tmps) {
	SV *error = GvSV(gv_fetchpv("@", TRUE, SVt_PV));
	(void)SvUPGRADE(error, SVt_PV);
	if (SvPOK(error) && SvCUR(error))
	    sv_catpv(error, "\t...caught");
	tmps = SvPV(error, na);
    }
    if (!tmps || !*tmps)
	tmps = "Warning: something's wrong";
    warn("%s", tmps);
    RETSETYES;
}

PP(pp_die)
{
    dSP; dMARK;
    char *tmps;
    if (SP - MARK != 1) {
	dTARGET;
	do_join(TARG, &sv_no, MARK, SP);
	tmps = SvPV(TARG, na);
	SP = MARK + 1;
    }
    else {
	tmps = SvPV(TOPs, na);
    }
    if (!tmps || !*tmps) {
	SV *error = GvSV(gv_fetchpv("@", TRUE, SVt_PV));
	(void)SvUPGRADE(error, SVt_PV);
	if (SvPOK(error) && SvCUR(error))
	    sv_catpv(error, "\t...propagated");
	tmps = SvPV(error, na);
    }
    if (!tmps || !*tmps)
	tmps = "Died";
    DIE("%s", tmps);
}

/* I/O. */

PP(pp_open)
{
    dSP; dTARGET;
    GV *gv;
    SV *sv;
    char *tmps;
    STRLEN len;

    if (MAXARG > 1)
	sv = POPs;
    else
	sv = GvSV(TOPs);
    gv = (GV*)POPs;
    tmps = SvPV(sv, len);
    if (do_open(gv, tmps, len,Nullfp)) {
	IoLINES(GvIOp(gv)) = 0;
	PUSHi( (I32)forkprocess );
    }
    else if (forkprocess == 0)		/* we are a new child */
	PUSHi(0);
    else
	RETPUSHUNDEF;
    RETURN;
}

PP(pp_close)
{
    dSP;
    GV *gv;

    if (MAXARG == 0)
	gv = defoutgv;
    else
	gv = (GV*)POPs;
    EXTEND(SP, 1);
    PUSHs( do_close(gv, TRUE) ? &sv_yes : &sv_no );
    RETURN;
}

PP(pp_pipe_op)
{
    dSP;
#ifdef HAS_PIPE
    GV *rgv;
    GV *wgv;
    register IO *rstio;
    register IO *wstio;
    int fd[2];

    wgv = (GV*)POPs;
    rgv = (GV*)POPs;

    if (!rgv || !wgv)
	goto badexit;

    rstio = GvIOn(rgv);
    wstio = GvIOn(wgv);

    if (IoIFP(rstio))
	do_close(rgv, FALSE);
    if (IoIFP(wstio))
	do_close(wgv, FALSE);

    if (pipe(fd) < 0)
	goto badexit;

    IoIFP(rstio) = fdopen(fd[0], "r");
    IoOFP(wstio) = fdopen(fd[1], "w");
    IoIFP(wstio) = IoOFP(wstio);
    IoTYPE(rstio) = '<';
    IoTYPE(wstio) = '>';

    if (!IoIFP(rstio) || !IoOFP(wstio)) {
	if (IoIFP(rstio)) fclose(IoIFP(rstio));
	else close(fd[0]);
	if (IoOFP(wstio)) fclose(IoOFP(wstio));
	else close(fd[1]);
	goto badexit;
    }

    RETPUSHYES;

badexit:
    RETPUSHUNDEF;
#else
    DIE(no_func, "pipe");
#endif
}

PP(pp_fileno)
{
    dSP; dTARGET;
    GV *gv;
    IO *io;
    FILE *fp;
    if (MAXARG < 1)
	RETPUSHUNDEF;
    gv = (GV*)POPs;
    if (!gv || !(io = GvIO(gv)) || !(fp = IoIFP(io)))
	RETPUSHUNDEF;
    PUSHi(fileno(fp));
    RETURN;
}

PP(pp_umask)
{
    dSP; dTARGET;
    int anum;

#ifdef HAS_UMASK
    if (MAXARG < 1) {
	anum = umask(0);
	(void)umask(anum);
    }
    else
	anum = umask(POPi);
    TAINT_PROPER("umask");
    XPUSHi(anum);
#else
    DIE(no_func, "Unsupported function umask");
#endif
    RETURN;
}

PP(pp_binmode)
{
    dSP;
    GV *gv;
    IO *io;
    FILE *fp;

    if (MAXARG < 1)
	RETPUSHUNDEF;

    gv = (GV*)POPs;

    EXTEND(SP, 1);
    if (!(io = GvIO(gv)) || !(fp = IoIFP(io)))
	RETSETUNDEF;

#ifdef DOSISH
#ifdef atarist
    if (!fflush(fp) && (fp->_flag |= _IOBIN))
	RETPUSHYES;
    else
	RETPUSHUNDEF;
#else
    if (setmode(fileno(fp), OP_BINARY) != -1)
	RETPUSHYES;
    else
	RETPUSHUNDEF;
#endif
#else
    RETPUSHYES;
#endif
}

PP(pp_tie)
{
    dSP;
    SV *varsv;
    HV* stash;
    GV *gv;
    BINOP myop;
    SV *sv;
    SV **mark = stack_base + ++*markstack_ptr;	/* reuse in entersub */
    I32 markoff = mark - stack_base - 1;
    char *methname;

    varsv = mark[0];
    if (SvTYPE(varsv) == SVt_PVHV)
	methname = "TIEHASH";
    else if (SvTYPE(varsv) == SVt_PVAV)
	methname = "TIEARRAY";
    else if (SvTYPE(varsv) == SVt_PVGV)
	methname = "TIEHANDLE";
    else
	methname = "TIESCALAR";

    stash = gv_stashsv(mark[1], FALSE);
    if (!stash || !(gv = gv_fetchmethod(stash, methname)) || !GvCV(gv))
	DIE("Can't locate object method \"%s\" via package \"%s\"",
		methname, SvPV(mark[1],na));

    Zero(&myop, 1, BINOP);
    myop.op_last = (OP *) &myop;
    myop.op_next = Nullop;
    myop.op_flags = OPf_KNOW|OPf_STACKED;

    ENTER;
    SAVESPTR(op);
    op = (OP *) &myop;

    XPUSHs(gv);
    PUTBACK;

    if (op = pp_entersub())
        run();
    SPAGAIN;

    sv = TOPs;
    if (sv_isobject(sv)) {
	if (SvTYPE(varsv) == SVt_PVHV || SvTYPE(varsv) == SVt_PVAV) {
	    sv_unmagic(varsv, 'P');
	    sv_magic(varsv, sv, 'P', Nullch, 0);
	}
	else {
	    sv_unmagic(varsv, 'q');
	    sv_magic(varsv, sv, 'q', Nullch, 0);
	}
    }
    LEAVE;
    SP = stack_base + markoff;
    PUSHs(sv);
    RETURN;
}

PP(pp_untie)
{
    dSP;
    if (SvTYPE(TOPs) == SVt_PVHV || SvTYPE(TOPs) == SVt_PVAV)
	sv_unmagic(TOPs, 'P');
    else
	sv_unmagic(TOPs, 'q');
    RETSETYES;
}

PP(pp_dbmopen)
{
    dSP;
    HV *hv;
    dPOPPOPssrl;
    HV* stash;
    GV *gv;
    BINOP myop;
    SV *sv;

    hv = (HV*)POPs;

    sv = sv_mortalcopy(&sv_no);
    sv_setpv(sv, "AnyDBM_File");
    stash = gv_stashsv(sv, FALSE);
    if (!stash || !(gv = gv_fetchmethod(stash, "TIEHASH")) || !GvCV(gv)) {
	PUTBACK;
	perl_requirepv("AnyDBM_File.pm");
	SPAGAIN;
	if (!(gv = gv_fetchmethod(stash, "TIEHASH")) || !GvCV(gv))
	    DIE("No dbm on this machine");
    }

    Zero(&myop, 1, BINOP);
    myop.op_last = (OP *) &myop;
    myop.op_next = Nullop;
    myop.op_flags = OPf_KNOW|OPf_STACKED;

    ENTER;
    SAVESPTR(op);
    op = (OP *) &myop;
    PUTBACK;
    pp_pushmark();

    EXTEND(sp, 5);
    PUSHs(sv);
    PUSHs(left);
    if (SvIV(right))
	PUSHs(sv_2mortal(newSViv(O_RDWR|O_CREAT)));
    else
	PUSHs(sv_2mortal(newSViv(O_RDWR)));
    PUSHs(right);
    PUSHs(gv);
    PUTBACK;

    if (op = pp_entersub())
        run();
    SPAGAIN;

    if (!sv_isobject(TOPs)) {
	sp--;
	op = (OP *) &myop;
	PUTBACK;
	pp_pushmark();

	PUSHs(sv);
	PUSHs(left);
	PUSHs(sv_2mortal(newSViv(O_RDONLY)));
	PUSHs(right);
	PUSHs(gv);
	PUTBACK;

	if (op = pp_entersub())
	    run();
	SPAGAIN;
    }

    if (sv_isobject(TOPs))
	sv_magic((SV*)hv, TOPs, 'P', Nullch, 0);
    LEAVE;
    RETURN;
}

PP(pp_dbmclose)
{
    return pp_untie(ARGS);
}

PP(pp_sselect)
{
    dSP; dTARGET;
#ifdef HAS_SELECT
    register I32 i;
    register I32 j;
    register char *s;
    register SV *sv;
    double value;
    I32 maxlen = 0;
    I32 nfound;
    struct timeval timebuf;
    struct timeval *tbuf = &timebuf;
    I32 growsize;
    char *fd_sets[4];
#if BYTEORDER != 0x1234 && BYTEORDER != 0x12345678
	I32 masksize;
	I32 offset;
	I32 k;

#   if BYTEORDER & 0xf0000
#	define ORDERBYTE (0x88888888 - BYTEORDER)
#   else
#	define ORDERBYTE (0x4444 - BYTEORDER)
#   endif

#endif

    SP -= 4;
    for (i = 1; i <= 3; i++) {
	if (!SvPOK(SP[i]))
	    continue;
	j = SvCUR(SP[i]);
	if (maxlen < j)
	    maxlen = j;
    }

#if BYTEORDER == 0x1234 || BYTEORDER == 0x12345678
    growsize = maxlen;		/* little endians can use vecs directly */
#else
#ifdef NFDBITS

#ifndef NBBY
#define NBBY 8
#endif

    masksize = NFDBITS / NBBY;
#else
    masksize = sizeof(long);	/* documented int, everyone seems to use long */
#endif
    growsize = maxlen + (masksize - (maxlen % masksize));
    Zero(&fd_sets[0], 4, char*);
#endif

    sv = SP[4];
    if (SvOK(sv)) {
	value = SvNV(sv);
	if (value < 0.0)
	    value = 0.0;
	timebuf.tv_sec = (long)value;
	value -= (double)timebuf.tv_sec;
	timebuf.tv_usec = (long)(value * 1000000.0);
    }
    else
	tbuf = Null(struct timeval*);

    for (i = 1; i <= 3; i++) {
	sv = SP[i];
	if (!SvOK(sv)) {
	    fd_sets[i] = 0;
	    continue;
	}
	else if (!SvPOK(sv))
	    SvPV_force(sv,na);	/* force string conversion */
	j = SvLEN(sv);
	if (j < growsize) {
	    Sv_Grow(sv, growsize);
	    s = SvPVX(sv) + j;
	    while (++j <= growsize) {
		*s++ = '\0';
	    }
	}
#if BYTEORDER != 0x1234 && BYTEORDER != 0x12345678
	s = SvPVX(sv);
	New(403, fd_sets[i], growsize, char);
	for (offset = 0; offset < growsize; offset += masksize) {
	    for (j = 0, k=ORDERBYTE; j < masksize; j++, (k >>= 4))
		fd_sets[i][j+offset] = s[(k % masksize) + offset];
	}
#else
	fd_sets[i] = SvPVX(sv);
#endif
    }

    nfound = select(
	maxlen * 8,
	(Select_fd_set_t) fd_sets[1],
	(Select_fd_set_t) fd_sets[2],
	(Select_fd_set_t) fd_sets[3],
	tbuf);
    for (i = 1; i <= 3; i++) {
	if (fd_sets[i]) {
	    sv = SP[i];
#if BYTEORDER != 0x1234 && BYTEORDER != 0x12345678
	    s = SvPVX(sv);
	    for (offset = 0; offset < growsize; offset += masksize) {
		for (j = 0, k=ORDERBYTE; j < masksize; j++, (k >>= 4))
		    s[(k % masksize) + offset] = fd_sets[i][j+offset];
	    }
	    Safefree(fd_sets[i]);
#endif
	    SvSETMAGIC(sv);
	}
    }

    PUSHi(nfound);
    if (GIMME == G_ARRAY && tbuf) {
	value = (double)(timebuf.tv_sec) +
		(double)(timebuf.tv_usec) / 1000000.0;
	PUSHs(sv = sv_mortalcopy(&sv_no));
	sv_setnv(sv, value);
    }
    RETURN;
#else
    DIE("select not implemented");
#endif
}

PP(pp_select)
{
    dSP; dTARGET;
    GV *oldgv = defoutgv;
    if (op->op_private > 0) {
	defoutgv = (GV*)POPs;
	if (!GvIO(defoutgv))
	    gv_IOadd(defoutgv);
    }
    gv_efullname(TARG, oldgv);
    XPUSHTARG;
    RETURN;
}

PP(pp_getc)
{
    dSP; dTARGET;
    GV *gv;

    if (MAXARG <= 0)
	gv = stdingv;
    else
	gv = (GV*)POPs;
    if (!gv)
	gv = argvgv;
    if (!gv || do_eof(gv)) /* make sure we have fp with something */
	RETPUSHUNDEF;
    TAINT_IF(1);
    sv_setpv(TARG, " ");
    *SvPVX(TARG) = getc(IoIFP(GvIOp(gv))); /* should never be EOF */
    PUSHTARG;
    RETURN;
}

PP(pp_read)
{
    return pp_sysread(ARGS);
}

static OP *
doform(cv,gv,retop)
CV *cv;
GV *gv;
OP *retop;
{
    register CONTEXT *cx;
    I32 gimme = GIMME;
    AV* padlist = CvPADLIST(cv);
    SV** svp = AvARRAY(padlist);

    ENTER;
    SAVETMPS;

    push_return(retop);
    PUSHBLOCK(cx, CXt_SUB, stack_sp);
    PUSHFORMAT(cx);
    SAVESPTR(curpad);
    curpad = AvARRAY((AV*)svp[1]);

    defoutgv = gv;		/* locally select filehandle so $% et al work */
    return CvSTART(cv);
}

PP(pp_enterwrite)
{
    dSP;
    register GV *gv;
    register IO *io;
    GV *fgv;
    CV *cv;

    if (MAXARG == 0)
	gv = defoutgv;
    else {
	gv = (GV*)POPs;
	if (!gv)
	    gv = defoutgv;
    }
    EXTEND(SP, 1);
    io = GvIO(gv);
    if (!io) {
	RETPUSHNO;
    }
    if (IoFMT_GV(io))
	fgv = IoFMT_GV(io);
    else
	fgv = gv;

    cv = GvFORM(fgv);

    if (!cv) {
	if (fgv) {
	    SV *tmpstr = sv_newmortal();
	    gv_efullname(tmpstr, gv);
	    DIE("Undefined format \"%s\" called",SvPVX(tmpstr));
	}
	DIE("Not a format reference");
    }

    return doform(cv,gv,op->op_next);
}

PP(pp_leavewrite)
{
    dSP;
    GV *gv = cxstack[cxstack_ix].blk_sub.gv;
    register IO *io = GvIOp(gv);
    FILE *ofp = IoOFP(io);
    FILE *fp;
    SV **newsp;
    I32 gimme;
    register CONTEXT *cx;

    DEBUG_f(fprintf(stderr,"left=%ld, todo=%ld\n",
	  (long)IoLINES_LEFT(io), (long)FmLINES(formtarget)));
    if (IoLINES_LEFT(io) < FmLINES(formtarget) &&
	formtarget != toptarget)
    {
	if (!IoTOP_GV(io)) {
	    GV *topgv;
	    char tmpbuf[256];

	    if (!IoTOP_NAME(io)) {
		if (!IoFMT_NAME(io))
		    IoFMT_NAME(io) = savepv(GvNAME(gv));
		sprintf(tmpbuf, "%s_TOP", IoFMT_NAME(io));
		topgv = gv_fetchpv(tmpbuf,FALSE, SVt_PVFM);
                if ((topgv && GvFORM(topgv)) ||
		  !gv_fetchpv("top",FALSE,SVt_PVFM))
		    IoTOP_NAME(io) = savepv(tmpbuf);
		else
		    IoTOP_NAME(io) = savepv("top");
	    }
	    topgv = gv_fetchpv(IoTOP_NAME(io),FALSE, SVt_PVFM);
	    if (!topgv || !GvFORM(topgv)) {
		IoLINES_LEFT(io) = 100000000;
		goto forget_top;
	    }
	    IoTOP_GV(io) = topgv;
	}
	if (IoLINES_LEFT(io) >= 0 && IoPAGE(io) > 0)
	    fwrite1(SvPVX(formfeed), SvCUR(formfeed), 1, ofp);
	IoLINES_LEFT(io) = IoPAGE_LEN(io);
	IoPAGE(io)++;
	formtarget = toptarget;
	return doform(GvFORM(IoTOP_GV(io)),gv,op);
    }

  forget_top:
    POPBLOCK(cx,curpm);
    POPFORMAT(cx);
    LEAVE;

    fp = IoOFP(io);
    if (!fp) {
	if (dowarn) {
	    if (IoIFP(io))
		warn("Filehandle only opened for input");
	    else
		warn("Write on closed filehandle");
	}
	PUSHs(&sv_no);
    }
    else {
	if ((IoLINES_LEFT(io) -= FmLINES(formtarget)) < 0) {
	    if (dowarn)
		warn("page overflow");
	}
	if (!fwrite1(SvPVX(formtarget), 1, SvCUR(formtarget), ofp) ||
		ferror(fp))
	    PUSHs(&sv_no);
	else {
	    FmLINES(formtarget) = 0;
	    SvCUR_set(formtarget, 0);
	    if (IoFLAGS(io) & IOf_FLUSH)
		(void)fflush(fp);
	    PUSHs(&sv_yes);
	}
    }
    formtarget = bodytarget;
    PUTBACK;
    return pop_return();
}

PP(pp_prtf)
{
    dSP; dMARK; dORIGMARK;
    GV *gv;
    IO *io;
    FILE *fp;
    SV *sv = NEWSV(0,0);

    if (op->op_flags & OPf_STACKED)
	gv = (GV*)*++MARK;
    else
	gv = defoutgv;
    if (!(io = GvIO(gv))) {
	if (dowarn)
	    warn("Filehandle %s never opened", GvNAME(gv));
	errno = EBADF;
	goto just_say_no;
    }
    else if (!(fp = IoOFP(io))) {
	if (dowarn)  {
	    if (IoIFP(io))
		warn("Filehandle %s opened only for input", GvNAME(gv));
	    else
		warn("printf on closed filehandle %s", GvNAME(gv));
	}
	errno = EBADF;
	goto just_say_no;
    }
    else {
	do_sprintf(sv, SP - MARK, MARK + 1);
	if (!do_print(sv, fp))
	    goto just_say_no;

	if (IoFLAGS(io) & IOf_FLUSH)
	    if (fflush(fp) == EOF)
		goto just_say_no;
    }
    SvREFCNT_dec(sv);
    SP = ORIGMARK;
    PUSHs(&sv_yes);
    RETURN;

  just_say_no:
    SvREFCNT_dec(sv);
    SP = ORIGMARK;
    PUSHs(&sv_undef);
    RETURN;
}

PP(pp_sysread)
{
    dSP; dMARK; dORIGMARK; dTARGET;
    int offset;
    GV *gv;
    IO *io;
    char *buffer;
    int length;
    int bufsize;
    SV *bufstr;
    STRLEN blen;

    gv = (GV*)*++MARK;
    if (!gv)
	goto say_undef;
    bufstr = *++MARK;
    buffer = SvPV_force(bufstr, blen);
    length = SvIVx(*++MARK);
    if (length < 0)
	DIE("Negative length");
    errno = 0;
    if (MARK < SP)
	offset = SvIVx(*++MARK);
    else
	offset = 0;
    io = GvIO(gv);
    if (!io || !IoIFP(io))
	goto say_undef;
#ifdef HAS_SOCKET
    if (op->op_type == OP_RECV) {
	bufsize = sizeof buf;
	buffer = SvGROW(bufstr, length+1);
	length = recvfrom(fileno(IoIFP(io)), buffer, length, offset,
	    (struct sockaddr *)buf, &bufsize);
	if (length < 0)
	    RETPUSHUNDEF;
	SvCUR_set(bufstr, length);
	*SvEND(bufstr) = '\0';
	(void)SvPOK_only(bufstr);
	SvSETMAGIC(bufstr);
	if (tainting)
	    sv_magic(bufstr, Nullsv, 't', Nullch, 0);
	SP = ORIGMARK;
	sv_setpvn(TARG, buf, bufsize);
	PUSHs(TARG);
	RETURN;
    }
#else
    if (op->op_type == OP_RECV)
	DIE(no_sock_func, "recv");
#endif
    buffer = SvGROW(bufstr, length+offset+1);
    if (op->op_type == OP_SYSREAD) {
	length = read(fileno(IoIFP(io)), buffer+offset, length);
    }
    else
#ifdef HAS_SOCKET__bad_code_maybe
    if (IoTYPE(io) == 's') {
	bufsize = sizeof buf;
	length = recvfrom(fileno(IoIFP(io)), buffer+offset, length, 0,
	    (struct sockaddr *)buf, &bufsize);
    }
    else
#endif
	length = fread(buffer+offset, 1, length, IoIFP(io));
    if (length < 0)
	goto say_undef;
    SvCUR_set(bufstr, length+offset);
    *SvEND(bufstr) = '\0';
    (void)SvPOK_only(bufstr);
    SvSETMAGIC(bufstr);
    if (tainting)
	sv_magic(bufstr, Nullsv, 't', Nullch, 0);
    SP = ORIGMARK;
    PUSHi(length);
    RETURN;

  say_undef:
    SP = ORIGMARK;
    RETPUSHUNDEF;
}

PP(pp_syswrite)
{
    return pp_send(ARGS);
}

PP(pp_send)
{
    dSP; dMARK; dORIGMARK; dTARGET;
    GV *gv;
    IO *io;
    int offset;
    SV *bufstr;
    char *buffer;
    int length;
    STRLEN blen;

    gv = (GV*)*++MARK;
    if (!gv)
	goto say_undef;
    bufstr = *++MARK;
    buffer = SvPV(bufstr, blen);
    length = SvIVx(*++MARK);
    if (length < 0)
	DIE("Negative length");
    errno = 0;
    io = GvIO(gv);
    if (!io || !IoIFP(io)) {
	length = -1;
	if (dowarn) {
	    if (op->op_type == OP_SYSWRITE)
		warn("Syswrite on closed filehandle");
	    else
		warn("Send on closed socket");
	}
    }
    else if (op->op_type == OP_SYSWRITE) {
	if (MARK < SP)
	    offset = SvIVx(*++MARK);
	else
	    offset = 0;
	if (length > blen - offset)
	    length = blen - offset;
	length = write(fileno(IoIFP(io)), buffer+offset, length);
    }
#ifdef HAS_SOCKET
    else if (SP > MARK) {
	char *sockbuf;
	STRLEN mlen;
	sockbuf = SvPVx(*++MARK, mlen);
	length = sendto(fileno(IoIFP(io)), buffer, blen, length,
				(struct sockaddr *)sockbuf, mlen);
    }
    else
	length = send(fileno(IoIFP(io)), buffer, blen, length);
#else
    else
	DIE(no_sock_func, "send");
#endif
    if (length < 0)
	goto say_undef;
    SP = ORIGMARK;
    PUSHi(length);
    RETURN;

  say_undef:
    SP = ORIGMARK;
    RETPUSHUNDEF;
}

PP(pp_recv)
{
    return pp_sysread(ARGS);
}

PP(pp_eof)
{
    dSP;
    GV *gv;

    if (MAXARG <= 0)
	gv = last_in_gv;
    else
	gv = last_in_gv = (GV*)POPs;
    PUSHs(!gv || do_eof(gv) ? &sv_yes : &sv_no);
    RETURN;
}

PP(pp_tell)
{
    dSP; dTARGET;
    GV *gv;

    if (MAXARG <= 0)
	gv = last_in_gv;
    else
	gv = last_in_gv = (GV*)POPs;
    PUSHi( do_tell(gv) );
    RETURN;
}

PP(pp_seek)
{
    dSP;
    GV *gv;
    int whence = POPi;
    long offset = POPl;

    gv = last_in_gv = (GV*)POPs;
    PUSHs( do_seek(gv, offset, whence) ? &sv_yes : &sv_no );
    RETURN;
}

PP(pp_truncate)
{
    dSP;
    Off_t len = (Off_t)POPn;
    int result = 1;
    GV *tmpgv;

    errno = 0;
#if defined(HAS_TRUNCATE) || defined(HAS_CHSIZE)
#ifdef HAS_TRUNCATE
    if (op->op_flags & OPf_SPECIAL) {
	tmpgv = gv_fetchpv(POPp,FALSE, SVt_PVIO);
	if (!GvIO(tmpgv) || !IoIFP(GvIOp(tmpgv)) ||
	  ftruncate(fileno(IoIFP(GvIOn(tmpgv))), len) < 0)
	    result = 0;
    }
    else if (truncate(POPp, len) < 0)
	result = 0;
#else
    if (op->op_flags & OPf_SPECIAL) {
	tmpgv = gv_fetchpv(POPp,FALSE, SVt_PVIO);
	if (!GvIO(tmpgv) || !IoIFP(GvIOp(tmpgv)) ||
	  chsize(fileno(IoIFP(GvIOn(tmpgv))), len) < 0)
	    result = 0;
    }
    else {
	int tmpfd;

	if ((tmpfd = open(POPp, 0)) < 0)
	    result = 0;
	else {
	    if (chsize(tmpfd, len) < 0)
		result = 0;
	    close(tmpfd);
	}
    }
#endif

    if (result)
	RETPUSHYES;
    if (!errno)
	errno = EBADF;
    RETPUSHUNDEF;
#else
    DIE("truncate not implemented");
#endif
}

PP(pp_fcntl)
{
    return pp_ioctl(ARGS);
}

PP(pp_ioctl)
{
    dSP; dTARGET;
    SV *argstr = POPs;
    unsigned int func = U_I(POPn);
    int optype = op->op_type;
    char *s;
    int retval;
    GV *gv = (GV*)POPs;
    IO *io = GvIOn(gv);

    if (!io || !argstr || !IoIFP(io)) {
	errno = EBADF;	/* well, sort of... */
	RETPUSHUNDEF;
    }

    if (SvPOK(argstr) || !SvNIOK(argstr)) {
	STRLEN len;
	s = SvPV_force(argstr, len);
	retval = IOCPARM_LEN(func);
	if (len < retval) {
	    s = Sv_Grow(argstr, retval+1);
	    SvCUR_set(argstr, retval);
	}

	s[SvCUR(argstr)] = 17;	/* a little sanity check here */
    }
    else {
	retval = SvIV(argstr);
#ifdef DOSISH
	s = (char*)(long)retval;	/* ouch */
#else
	s = (char*)retval;		/* ouch */
#endif
    }

    TAINT_PROPER(optype == OP_IOCTL ? "ioctl" : "fcntl");

    if (optype == OP_IOCTL)
#ifdef HAS_IOCTL
	retval = ioctl(fileno(IoIFP(io)), func, s);
#else
	DIE("ioctl is not implemented");
#endif
    else
#ifdef DOSISH
	DIE("fcntl is not implemented");
#else
#   ifdef HAS_FCNTL
	retval = fcntl(fileno(IoIFP(io)), func, s);
#   else
	DIE("fcntl is not implemented");
#   endif
#endif

    if (SvPOK(argstr)) {
	if (s[SvCUR(argstr)] != 17)
	    DIE("Possible memory corruption: %s overflowed 3rd argument",
		op_name[optype]);
	s[SvCUR(argstr)] = 0;		/* put our null back */
	SvSETMAGIC(argstr);		/* Assume it has changed */
    }

    if (retval == -1)
	RETPUSHUNDEF;
    if (retval != 0) {
	PUSHi(retval);
    }
    else {
	PUSHp("0 but true", 10);
    }
    RETURN;
}

PP(pp_flock)
{
    dSP; dTARGET;
    I32 value;
    int argtype;
    GV *gv;
    FILE *fp;
#ifdef HAS_FLOCK
    argtype = POPi;
    if (MAXARG <= 0)
	gv = last_in_gv;
    else
	gv = (GV*)POPs;
    if (gv && GvIO(gv))
	fp = IoIFP(GvIOp(gv));
    else
	fp = Nullfp;
    if (fp) {
	value = (I32)(flock(fileno(fp), argtype) >= 0);
    }
    else
	value = 0;
    PUSHi(value);
    RETURN;
#else
# ifdef HAS_LOCKF
    DIE(no_func, "flock()"); /* XXX emulate flock() with lockf()? */
# else
    DIE(no_func, "flock()");
# endif
#endif
}

/* Sockets. */

PP(pp_socket)
{
    dSP;
#ifdef HAS_SOCKET
    GV *gv;
    register IO *io;
    int protocol = POPi;
    int type = POPi;
    int domain = POPi;
    int fd;

    gv = (GV*)POPs;

    if (!gv) {
	errno = EBADF;
	RETPUSHUNDEF;
    }

    io = GvIOn(gv);
    if (IoIFP(io))
	do_close(gv, FALSE);

    TAINT_PROPER("socket");
    fd = socket(domain, type, protocol);
    if (fd < 0)
	RETPUSHUNDEF;
    IoIFP(io) = fdopen(fd, "r");	/* stdio gets confused about sockets */
    IoOFP(io) = fdopen(fd, "w");
    IoTYPE(io) = 's';
    if (!IoIFP(io) || !IoOFP(io)) {
	if (IoIFP(io)) fclose(IoIFP(io));
	if (IoOFP(io)) fclose(IoOFP(io));
	if (!IoIFP(io) && !IoOFP(io)) close(fd);
	RETPUSHUNDEF;
    }

    RETPUSHYES;
#else
    DIE(no_sock_func, "socket");
#endif
}

PP(pp_sockpair)
{
    dSP;
#ifdef HAS_SOCKETPAIR
    GV *gv1;
    GV *gv2;
    register IO *io1;
    register IO *io2;
    int protocol = POPi;
    int type = POPi;
    int domain = POPi;
    int fd[2];

    gv2 = (GV*)POPs;
    gv1 = (GV*)POPs;
    if (!gv1 || !gv2)
	RETPUSHUNDEF;

    io1 = GvIOn(gv1);
    io2 = GvIOn(gv2);
    if (IoIFP(io1))
	do_close(gv1, FALSE);
    if (IoIFP(io2))
	do_close(gv2, FALSE);

    TAINT_PROPER("socketpair");
    if (socketpair(domain, type, protocol, fd) < 0)
	RETPUSHUNDEF;
    IoIFP(io1) = fdopen(fd[0], "r");
    IoOFP(io1) = fdopen(fd[0], "w");
    IoTYPE(io1) = 's';
    IoIFP(io2) = fdopen(fd[1], "r");
    IoOFP(io2) = fdopen(fd[1], "w");
    IoTYPE(io2) = 's';
    if (!IoIFP(io1) || !IoOFP(io1) || !IoIFP(io2) || !IoOFP(io2)) {
	if (IoIFP(io1)) fclose(IoIFP(io1));
	if (IoOFP(io1)) fclose(IoOFP(io1));
	if (!IoIFP(io1) && !IoOFP(io1)) close(fd[0]);
	if (IoIFP(io2)) fclose(IoIFP(io2));
	if (IoOFP(io2)) fclose(IoOFP(io2));
	if (!IoIFP(io2) && !IoOFP(io2)) close(fd[1]);
	RETPUSHUNDEF;
    }

    RETPUSHYES;
#else
    DIE(no_sock_func, "socketpair");
#endif
}

PP(pp_bind)
{
    dSP;
#ifdef HAS_SOCKET
    SV *addrstr = POPs;
    char *addr;
    GV *gv = (GV*)POPs;
    register IO *io = GvIOn(gv);
    STRLEN len;

    if (!io || !IoIFP(io))
	goto nuts;

    addr = SvPV(addrstr, len);
    TAINT_PROPER("bind");
    if (bind(fileno(IoIFP(io)), (struct sockaddr *)addr, len) >= 0)
	RETPUSHYES;
    else
	RETPUSHUNDEF;

nuts:
    if (dowarn)
	warn("bind() on closed fd");
    errno = EBADF;
    RETPUSHUNDEF;
#else
    DIE(no_sock_func, "bind");
#endif
}

PP(pp_connect)
{
    dSP;
#ifdef HAS_SOCKET
    SV *addrstr = POPs;
    char *addr;
    GV *gv = (GV*)POPs;
    register IO *io = GvIOn(gv);
    STRLEN len;

    if (!io || !IoIFP(io))
	goto nuts;

    addr = SvPV(addrstr, len);
    TAINT_PROPER("connect");
    if (connect(fileno(IoIFP(io)), (struct sockaddr *)addr, len) >= 0)
	RETPUSHYES;
    else
	RETPUSHUNDEF;

nuts:
    if (dowarn)
	warn("connect() on closed fd");
    errno = EBADF;
    RETPUSHUNDEF;
#else
    DIE(no_sock_func, "connect");
#endif
}

PP(pp_listen)
{
    dSP;
#ifdef HAS_SOCKET
    int backlog = POPi;
    GV *gv = (GV*)POPs;
    register IO *io = GvIOn(gv);

    if (!io || !IoIFP(io))
	goto nuts;

    if (listen(fileno(IoIFP(io)), backlog) >= 0)
	RETPUSHYES;
    else
	RETPUSHUNDEF;

nuts:
    if (dowarn)
	warn("listen() on closed fd");
    errno = EBADF;
    RETPUSHUNDEF;
#else
    DIE(no_sock_func, "listen");
#endif
}

PP(pp_accept)
{
    dSP; dTARGET;
#ifdef HAS_SOCKET
    GV *ngv;
    GV *ggv;
    register IO *nstio;
    register IO *gstio;
    int len = sizeof buf;
    int fd;

    ggv = (GV*)POPs;
    ngv = (GV*)POPs;

    if (!ngv)
	goto badexit;
    if (!ggv)
	goto nuts;

    gstio = GvIO(ggv);
    if (!gstio || !IoIFP(gstio))
	goto nuts;

    nstio = GvIOn(ngv);
    if (IoIFP(nstio))
	do_close(ngv, FALSE);

    fd = accept(fileno(IoIFP(gstio)), (struct sockaddr *)buf, &len);
    if (fd < 0)
	goto badexit;
    IoIFP(nstio) = fdopen(fd, "r");
    IoOFP(nstio) = fdopen(fd, "w");
    IoTYPE(nstio) = 's';
    if (!IoIFP(nstio) || !IoOFP(nstio)) {
	if (IoIFP(nstio)) fclose(IoIFP(nstio));
	if (IoOFP(nstio)) fclose(IoOFP(nstio));
	if (!IoIFP(nstio) && !IoOFP(nstio)) close(fd);
	goto badexit;
    }

    PUSHp(buf, len);
    RETURN;

nuts:
    if (dowarn)
	warn("accept() on closed fd");
    errno = EBADF;

badexit:
    RETPUSHUNDEF;

#else
    DIE(no_sock_func, "accept");
#endif
}

PP(pp_shutdown)
{
    dSP; dTARGET;
#ifdef HAS_SOCKET
    int how = POPi;
    GV *gv = (GV*)POPs;
    register IO *io = GvIOn(gv);

    if (!io || !IoIFP(io))
	goto nuts;

    PUSHi( shutdown(fileno(IoIFP(io)), how) >= 0 );
    RETURN;

nuts:
    if (dowarn)
	warn("shutdown() on closed fd");
    errno = EBADF;
    RETPUSHUNDEF;
#else
    DIE(no_sock_func, "shutdown");
#endif
}

PP(pp_gsockopt)
{
#ifdef HAS_SOCKET
    return pp_ssockopt(ARGS);
#else
    DIE(no_sock_func, "getsockopt");
#endif
}

PP(pp_ssockopt)
{
    dSP;
#ifdef HAS_SOCKET
    int optype = op->op_type;
    SV *sv;
    int fd;
    unsigned int optname;
    unsigned int lvl;
    GV *gv;
    register IO *io;

    if (optype == OP_GSOCKOPT)
	sv = sv_2mortal(NEWSV(22, 257));
    else
	sv = POPs;
    optname = (unsigned int) POPi;
    lvl = (unsigned int) POPi;

    gv = (GV*)POPs;
    io = GvIOn(gv);
    if (!io || !IoIFP(io))
	goto nuts;

    fd = fileno(IoIFP(io));
    switch (optype) {
    case OP_GSOCKOPT:
	SvGROW(sv, 256);
	(void)SvPOK_only(sv);
	if (getsockopt(fd, lvl, optname, SvPVX(sv), (int*)&SvCUR(sv)) < 0)
	    goto nuts2;
	PUSHs(sv);
	break;
    case OP_SSOCKOPT: {
	    int aint;
	    STRLEN len = 0;
	    char *buf = 0;
	    if (SvPOKp(sv))
		buf = SvPV(sv, len);
	    else if (SvOK(sv)) {
		aint = (int)SvIV(sv);
		buf = (char*)&aint;
		len = sizeof(int);
	    }
	    if (setsockopt(fd, lvl, optname, buf, (int)len) < 0)
		goto nuts2;
	    PUSHs(&sv_yes);
	}
	break;
    }
    RETURN;

nuts:
    if (dowarn)
	warn("[gs]etsockopt() on closed fd");
    errno = EBADF;
nuts2:
    RETPUSHUNDEF;

#else
    DIE(no_sock_func, "setsockopt");
#endif
}

PP(pp_getsockname)
{
#ifdef HAS_SOCKET
    return pp_getpeername(ARGS);
#else
    DIE(no_sock_func, "getsockname");
#endif
}

PP(pp_getpeername)
{
    dSP;
#ifdef HAS_SOCKET
    int optype = op->op_type;
    SV *sv;
    int fd;
    GV *gv = (GV*)POPs;
    register IO *io = GvIOn(gv);

    if (!io || !IoIFP(io))
	goto nuts;

    sv = sv_2mortal(NEWSV(22, 257));
    SvCUR_set(sv, 256);
    SvPOK_on(sv);
    fd = fileno(IoIFP(io));
    switch (optype) {
    case OP_GETSOCKNAME:
	if (getsockname(fd, (struct sockaddr *)SvPVX(sv), (int*)&SvCUR(sv)) < 0)
	    goto nuts2;
	break;
    case OP_GETPEERNAME:
	if (getpeername(fd, (struct sockaddr *)SvPVX(sv), (int*)&SvCUR(sv)) < 0)
	    goto nuts2;
	break;
    }
    PUSHs(sv);
    RETURN;

nuts:
    if (dowarn)
	warn("get{sock, peer}name() on closed fd");
    errno = EBADF;
nuts2:
    RETPUSHUNDEF;

#else
    DIE(no_sock_func, "getpeername");
#endif
}

/* Stat calls. */

PP(pp_lstat)
{
    return pp_stat(ARGS);
}

PP(pp_stat)
{
    dSP;
    GV *tmpgv;
    I32 max = 13;

    if (op->op_flags & OPf_REF) {
	tmpgv = cGVOP->op_gv;
	if (tmpgv != defgv) {
	    laststype = OP_STAT;
	    statgv = tmpgv;
	    sv_setpv(statname, "");
	    if (!GvIO(tmpgv) || !IoIFP(GvIOp(tmpgv)) ||
	      Fstat(fileno(IoIFP(GvIOn(tmpgv))), &statcache) < 0) {
		max = 0;
		laststatval = -1;
	    }
	}
	else if (laststatval < 0)
	    max = 0;
    }
    else {
	sv_setpv(statname, POPp);
	statgv = Nullgv;
#ifdef HAS_LSTAT
	laststype = op->op_type;
	if (op->op_type == OP_LSTAT)
	    laststatval = lstat(SvPV(statname, na), &statcache);
	else
#endif
	    laststatval = Stat(SvPV(statname, na), &statcache);
	if (laststatval < 0) {
	    if (dowarn && strchr(SvPV(statname, na), '\n'))
		warn(warn_nl, "stat");
	    max = 0;
	}
    }

    EXTEND(SP, 13);
    if (GIMME != G_ARRAY) {
	if (max)
	    RETPUSHYES;
	else
	    RETPUSHUNDEF;
    }
    if (max) {
	PUSHs(sv_2mortal(newSViv((I32)statcache.st_dev)));
	PUSHs(sv_2mortal(newSViv((I32)statcache.st_ino)));
	PUSHs(sv_2mortal(newSViv((I32)statcache.st_mode)));
	PUSHs(sv_2mortal(newSViv((I32)statcache.st_nlink)));
	PUSHs(sv_2mortal(newSViv((I32)statcache.st_uid)));
	PUSHs(sv_2mortal(newSViv((I32)statcache.st_gid)));
	PUSHs(sv_2mortal(newSViv((I32)statcache.st_rdev)));
	PUSHs(sv_2mortal(newSViv((I32)statcache.st_size)));
	PUSHs(sv_2mortal(newSViv((I32)statcache.st_atime)));
	PUSHs(sv_2mortal(newSViv((I32)statcache.st_mtime)));
	PUSHs(sv_2mortal(newSViv((I32)statcache.st_ctime)));
#ifdef USE_STAT_BLOCKS
	PUSHs(sv_2mortal(newSViv((I32)statcache.st_blksize)));
	PUSHs(sv_2mortal(newSViv((I32)statcache.st_blocks)));
#else
	PUSHs(sv_2mortal(newSVpv("", 0)));
	PUSHs(sv_2mortal(newSVpv("", 0)));
#endif
    }
    RETURN;
}

PP(pp_ftrread)
{
    I32 result = my_stat(ARGS);
    dSP;
    if (result < 0)
	RETPUSHUNDEF;
    if (cando(S_IRUSR, 0, &statcache))
	RETPUSHYES;
    RETPUSHNO;
}

PP(pp_ftrwrite)
{
    I32 result = my_stat(ARGS);
    dSP;
    if (result < 0)
	RETPUSHUNDEF;
    if (cando(S_IWUSR, 0, &statcache))
	RETPUSHYES;
    RETPUSHNO;
}

PP(pp_ftrexec)
{
    I32 result = my_stat(ARGS);
    dSP;
    if (result < 0)
	RETPUSHUNDEF;
    if (cando(S_IXUSR, 0, &statcache))
	RETPUSHYES;
    RETPUSHNO;
}

PP(pp_fteread)
{
    I32 result = my_stat(ARGS);
    dSP;
    if (result < 0)
	RETPUSHUNDEF;
    if (cando(S_IRUSR, 1, &statcache))
	RETPUSHYES;
    RETPUSHNO;
}

PP(pp_ftewrite)
{
    I32 result = my_stat(ARGS);
    dSP;
    if (result < 0)
	RETPUSHUNDEF;
    if (cando(S_IWUSR, 1, &statcache))
	RETPUSHYES;
    RETPUSHNO;
}

PP(pp_fteexec)
{
    I32 result = my_stat(ARGS);
    dSP;
    if (result < 0)
	RETPUSHUNDEF;
    if (cando(S_IXUSR, 1, &statcache))
	RETPUSHYES;
    RETPUSHNO;
}

PP(pp_ftis)
{
    I32 result = my_stat(ARGS);
    dSP;
    if (result < 0)
	RETPUSHUNDEF;
    RETPUSHYES;
}

PP(pp_fteowned)
{
    return pp_ftrowned(ARGS);
}

PP(pp_ftrowned)
{
    I32 result = my_stat(ARGS);
    dSP;
    if (result < 0)
	RETPUSHUNDEF;
    if (statcache.st_uid == (op->op_type == OP_FTEOWNED ? euid : uid) )
	RETPUSHYES;
    RETPUSHNO;
}

PP(pp_ftzero)
{
    I32 result = my_stat(ARGS);
    dSP;
    if (result < 0)
	RETPUSHUNDEF;
    if (!statcache.st_size)
	RETPUSHYES;
    RETPUSHNO;
}

PP(pp_ftsize)
{
    I32 result = my_stat(ARGS);
    dSP; dTARGET;
    if (result < 0)
	RETPUSHUNDEF;
    PUSHi(statcache.st_size);
    RETURN;
}

PP(pp_ftmtime)
{
    I32 result = my_stat(ARGS);
    dSP; dTARGET;
    if (result < 0)
	RETPUSHUNDEF;
    PUSHn( (basetime - statcache.st_mtime) / 86400.0 );
    RETURN;
}

PP(pp_ftatime)
{
    I32 result = my_stat(ARGS);
    dSP; dTARGET;
    if (result < 0)
	RETPUSHUNDEF;
    PUSHn( (basetime - statcache.st_atime) / 86400.0 );
    RETURN;
}

PP(pp_ftctime)
{
    I32 result = my_stat(ARGS);
    dSP; dTARGET;
    if (result < 0)
	RETPUSHUNDEF;
    PUSHn( (basetime - statcache.st_ctime) / 86400.0 );
    RETURN;
}

PP(pp_ftsock)
{
    I32 result = my_stat(ARGS);
    dSP;
    if (result < 0)
	RETPUSHUNDEF;
    if (S_ISSOCK(statcache.st_mode))
	RETPUSHYES;
    RETPUSHNO;
}

PP(pp_ftchr)
{
    I32 result = my_stat(ARGS);
    dSP;
    if (result < 0)
	RETPUSHUNDEF;
    if (S_ISCHR(statcache.st_mode))
	RETPUSHYES;
    RETPUSHNO;
}

PP(pp_ftblk)
{
    I32 result = my_stat(ARGS);
    dSP;
    if (result < 0)
	RETPUSHUNDEF;
    if (S_ISBLK(statcache.st_mode))
	RETPUSHYES;
    RETPUSHNO;
}

PP(pp_ftfile)
{
    I32 result = my_stat(ARGS);
    dSP;
    if (result < 0)
	RETPUSHUNDEF;
    if (S_ISREG(statcache.st_mode))
	RETPUSHYES;
    RETPUSHNO;
}

PP(pp_ftdir)
{
    I32 result = my_stat(ARGS);
    dSP;
    if (result < 0)
	RETPUSHUNDEF;
    if (S_ISDIR(statcache.st_mode))
	RETPUSHYES;
    RETPUSHNO;
}

PP(pp_ftpipe)
{
    I32 result = my_stat(ARGS);
    dSP;
    if (result < 0)
	RETPUSHUNDEF;
    if (S_ISFIFO(statcache.st_mode))
	RETPUSHYES;
    RETPUSHNO;
}

PP(pp_ftlink)
{
    I32 result = my_lstat(ARGS);
    dSP;
    if (result < 0)
	RETPUSHUNDEF;
    if (S_ISLNK(statcache.st_mode))
	RETPUSHYES;
    RETPUSHNO;
}

PP(pp_ftsuid)
{
    dSP;
#ifdef S_ISUID
    I32 result = my_stat(ARGS);
    SPAGAIN;
    if (result < 0)
	RETPUSHUNDEF;
    if (statcache.st_mode & S_ISUID)
	RETPUSHYES;
#endif
    RETPUSHNO;
}

PP(pp_ftsgid)
{
    dSP;
#ifdef S_ISGID
    I32 result = my_stat(ARGS);
    SPAGAIN;
    if (result < 0)
	RETPUSHUNDEF;
    if (statcache.st_mode & S_ISGID)
	RETPUSHYES;
#endif
    RETPUSHNO;
}

PP(pp_ftsvtx)
{
    dSP;
#ifdef S_ISVTX
    I32 result = my_stat(ARGS);
    SPAGAIN;
    if (result < 0)
	RETPUSHUNDEF;
    if (statcache.st_mode & S_ISVTX)
	RETPUSHYES;
#endif
    RETPUSHNO;
}

PP(pp_fttty)
{
    dSP;
    int fd;
    GV *gv;
    char *tmps;
    if (op->op_flags & OPf_REF) {
	gv = cGVOP->op_gv;
	tmps = "";
    }
    else
	gv = gv_fetchpv(tmps = POPp, FALSE, SVt_PVIO);
    if (GvIO(gv) && IoIFP(GvIOp(gv)))
	fd = fileno(IoIFP(GvIOp(gv)));
    else if (isDIGIT(*tmps))
	fd = atoi(tmps);
    else
	RETPUSHUNDEF;
    if (isatty(fd))
	RETPUSHYES;
    RETPUSHNO;
}

#if defined(USE_STD_STDIO) || defined(atarist) /* this will work with atariST */
# define FBASE(f) ((f)->_base)
# define FSIZE(f) ((f)->_cnt + ((f)->_ptr - (f)->_base))
# define FPTR(f) ((f)->_ptr)
# define FCOUNT(f) ((f)->_cnt)
#else 
# if defined(USE_LINUX_STDIO)
#   define FBASE(f) ((f)->_IO_read_base)
#   define FSIZE(f) ((f)->_IO_read_end - FBASE(f))
#   define FPTR(f) ((f)->_IO_read_ptr)
#   define FCOUNT(f) ((f)->_IO_read_end - FPTR(f))
# endif
#endif

PP(pp_fttext)
{
    dSP;
    I32 i;
    I32 len;
    I32 odd = 0;
    STDCHAR tbuf[512];
    register STDCHAR *s;
    register IO *io;
    SV *sv;

    if (op->op_flags & OPf_REF) {
	EXTEND(SP, 1);
	if (cGVOP->op_gv == defgv) {
	    if (statgv)
		io = GvIO(statgv);
	    else {
		sv = statname;
		goto really_filename;
	    }
	}
	else {
	    statgv = cGVOP->op_gv;
	    sv_setpv(statname, "");
	    io = GvIO(statgv);
	}
	if (io && IoIFP(io)) {
#ifdef FBASE
	    Fstat(fileno(IoIFP(io)), &statcache);
	    if (S_ISDIR(statcache.st_mode))	/* handle NFS glitch */
		if (op->op_type == OP_FTTEXT)
		    RETPUSHNO;
		else
		    RETPUSHYES;
	    if (FCOUNT(IoIFP(io)) <= 0) {
		i = getc(IoIFP(io));
		if (i != EOF)
		    (void)ungetc(i, IoIFP(io));
	    }
	    if (FCOUNT(IoIFP(io)) <= 0)	/* null file is anything */
		RETPUSHYES;
	    len = FSIZE(IoIFP(io));
	    s = FBASE(IoIFP(io));
#else
	    DIE("-T and -B not implemented on filehandles");
#endif
	}
	else {
	    if (dowarn)
		warn("Test on unopened file <%s>",
		  GvENAME(cGVOP->op_gv));
	    errno = EBADF;
	    RETPUSHUNDEF;
	}
    }
    else {
	sv = POPs;
	statgv = Nullgv;
	sv_setpv(statname, SvPV(sv, na));
      really_filename:
#ifdef HAS_OPEN3
	i = open(SvPV(sv, na), O_RDONLY, 0);
#else
	i = open(SvPV(sv, na), 0);
#endif
	if (i < 0) {
	    if (dowarn && strchr(SvPV(sv, na), '\n'))
		warn(warn_nl, "open");
	    RETPUSHUNDEF;
	}
	Fstat(i, &statcache);
	len = read(i, tbuf, 512);
	(void)close(i);
	if (len <= 0) {
	    if (S_ISDIR(statcache.st_mode) && op->op_type == OP_FTTEXT)
		RETPUSHNO;		/* special case NFS directories */
	    RETPUSHYES;		/* null file is anything */
	}
	s = tbuf;
    }

    /* now scan s to look for textiness */

    for (i = 0; i < len; i++, s++) {
	if (!*s) {			/* null never allowed in text */
	    odd += len;
	    break;
	}
	else if (*s & 128)
	    odd++;
	else if (*s < 32 &&
	  *s != '\n' && *s != '\r' && *s != '\b' &&
	  *s != '\t' && *s != '\f' && *s != 27)
	    odd++;
    }

    if ((odd * 30 > len) == (op->op_type == OP_FTTEXT)) /* allow 30% odd */
	RETPUSHNO;
    else
	RETPUSHYES;
}

PP(pp_ftbinary)
{
    return pp_fttext(ARGS);
}

/* File calls. */

PP(pp_chdir)
{
    dSP; dTARGET;
    char *tmps;
    SV **svp;

    if (MAXARG < 1)
	tmps = Nullch;
    else
	tmps = POPp;
    if (!tmps || !*tmps) {
	svp = hv_fetch(GvHVn(envgv), "HOME", 4, FALSE);
	if (svp)
	    tmps = SvPV(*svp, na);
    }
    if (!tmps || !*tmps) {
	svp = hv_fetch(GvHVn(envgv), "LOGDIR", 6, FALSE);
	if (svp)
	    tmps = SvPV(*svp, na);
    }
    TAINT_PROPER("chdir");
    PUSHi( chdir(tmps) >= 0 );
    RETURN;
}

PP(pp_chown)
{
    dSP; dMARK; dTARGET;
    I32 value;
#ifdef HAS_CHOWN
    value = (I32)apply(op->op_type, MARK, SP);
    SP = MARK;
    PUSHi(value);
    RETURN;
#else
    DIE(no_func, "Unsupported function chown");
#endif
}

PP(pp_chroot)
{
    dSP; dTARGET;
    char *tmps;
#ifdef HAS_CHROOT
    tmps = POPp;
    TAINT_PROPER("chroot");
    PUSHi( chroot(tmps) >= 0 );
    RETURN;
#else
    DIE(no_func, "chroot");
#endif
}

PP(pp_unlink)
{
    dSP; dMARK; dTARGET;
    I32 value;
    value = (I32)apply(op->op_type, MARK, SP);
    SP = MARK;
    PUSHi(value);
    RETURN;
}

PP(pp_chmod)
{
    dSP; dMARK; dTARGET;
    I32 value;
    value = (I32)apply(op->op_type, MARK, SP);
    SP = MARK;
    PUSHi(value);
    RETURN;
}

PP(pp_utime)
{
    dSP; dMARK; dTARGET;
    I32 value;
    value = (I32)apply(op->op_type, MARK, SP);
    SP = MARK;
    PUSHi(value);
    RETURN;
}

PP(pp_rename)
{
    dSP; dTARGET;
    int anum;

    char *tmps2 = POPp;
    char *tmps = SvPV(TOPs, na);
    TAINT_PROPER("rename");
#ifdef HAS_RENAME
    anum = rename(tmps, tmps2);
#else
    if (same_dirent(tmps2, tmps))	/* can always rename to same name */
	anum = 1;
    else {
	if (euid || Stat(tmps2, &statbuf) < 0 || !S_ISDIR(statbuf.st_mode))
	    (void)UNLINK(tmps2);
	if (!(anum = link(tmps, tmps2)))
	    anum = UNLINK(tmps);
    }
#endif
    SETi( anum >= 0 );
    RETURN;
}

PP(pp_link)
{
    dSP; dTARGET;
#ifdef HAS_LINK
    char *tmps2 = POPp;
    char *tmps = SvPV(TOPs, na);
    TAINT_PROPER("link");
    SETi( link(tmps, tmps2) >= 0 );
#else
    DIE(no_func, "Unsupported function link");
#endif
    RETURN;
}

PP(pp_symlink)
{
    dSP; dTARGET;
#ifdef HAS_SYMLINK
    char *tmps2 = POPp;
    char *tmps = SvPV(TOPs, na);
    TAINT_PROPER("symlink");
    SETi( symlink(tmps, tmps2) >= 0 );
    RETURN;
#else
    DIE(no_func, "symlink");
#endif
}

PP(pp_readlink)
{
    dSP; dTARGET;
#ifdef HAS_SYMLINK
    char *tmps;
    int len;
    tmps = POPp;
    len = readlink(tmps, buf, sizeof buf);
    EXTEND(SP, 1);
    if (len < 0)
	RETPUSHUNDEF;
    PUSHp(buf, len);
    RETURN;
#else
    EXTEND(SP, 1);
    RETSETUNDEF;		/* just pretend it's a normal file */
#endif
}

#if !defined(HAS_MKDIR) || !defined(HAS_RMDIR)
static int
dooneliner(cmd, filename)
char *cmd;
char *filename;
{
    char mybuf[8192];
    char *s, *tmps;
    int anum = 1;
    FILE *myfp;

    strcpy(mybuf, cmd);
    strcat(mybuf, " ");
    for (s = mybuf+strlen(mybuf); *filename; ) {
	*s++ = '\\';
	*s++ = *filename++;
    }
    strcpy(s, " 2>&1");
    myfp = my_popen(mybuf, "r");
    if (myfp) {
	*mybuf = '\0';
	s = fgets(mybuf, sizeof mybuf, myfp);
	(void)my_pclose(myfp);
	if (s != Nullch) {
	    for (errno = 1; errno < sys_nerr; errno++) {
#ifdef HAS_SYS_ERRLIST
		if (instr(mybuf, sys_errlist[errno]))	/* you don't see this */
		    return 0;
#else
		char *errmsg;				/* especially if it isn't there */

		if (instr(mybuf,
		          (errmsg = strerror(errno)) ? errmsg : "NoErRoR"))
		    return 0;
#endif
	    }
	    errno = 0;
#ifndef EACCES
#define EACCES EPERM
#endif
	    if (instr(mybuf, "cannot make"))
		errno = EEXIST;
	    else if (instr(mybuf, "existing file"))
		errno = EEXIST;
	    else if (instr(mybuf, "ile exists"))
		errno = EEXIST;
	    else if (instr(mybuf, "non-exist"))
		errno = ENOENT;
	    else if (instr(mybuf, "does not exist"))
		errno = ENOENT;
	    else if (instr(mybuf, "not empty"))
		errno = EBUSY;
	    else if (instr(mybuf, "cannot access"))
		errno = EACCES;
	    else
		errno = EPERM;
	    return 0;
	}
	else {	/* some mkdirs return no failure indication */
	    anum = (Stat(filename, &statbuf) >= 0);
	    if (op->op_type == OP_RMDIR)
		anum = !anum;
	    if (anum)
		errno = 0;
	    else
		errno = EACCES;	/* a guess */
	}
	return anum;
    }
    else
	return 0;
}
#endif

PP(pp_mkdir)
{
    dSP; dTARGET;
    int mode = POPi;
#ifndef HAS_MKDIR
    int oldumask;
#endif
    char *tmps = SvPV(TOPs, na);

    TAINT_PROPER("mkdir");
#ifdef HAS_MKDIR
    SETi( mkdir(tmps, mode) >= 0 );
#else
    SETi( dooneliner("mkdir", tmps) );
    oldumask = umask(0);
    umask(oldumask);
    chmod(tmps, (mode & ~oldumask) & 0777);
#endif
    RETURN;
}

PP(pp_rmdir)
{
    dSP; dTARGET;
    char *tmps;

    tmps = POPp;
    TAINT_PROPER("rmdir");
#ifdef HAS_RMDIR
    XPUSHi( rmdir(tmps) >= 0 );
#else
    XPUSHi( dooneliner("rmdir", tmps) );
#endif
    RETURN;
}

/* Directory calls. */

PP(pp_open_dir)
{
    dSP;
#if defined(Direntry_t) && defined(HAS_READDIR)
    char *dirname = POPp;
    GV *gv = (GV*)POPs;
    register IO *io = GvIOn(gv);

    if (!io)
	goto nope;

    if (IoDIRP(io))
	closedir(IoDIRP(io));
    if (!(IoDIRP(io) = opendir(dirname)))
	goto nope;

    RETPUSHYES;
nope:
    if (!errno)
	errno = EBADF;
    RETPUSHUNDEF;
#else
    DIE(no_dir_func, "opendir");
#endif
}

PP(pp_readdir)
{
    dSP;
#if defined(Direntry_t) && defined(HAS_READDIR)
#ifndef I_DIRENT
    Direntry_t *readdir _((DIR *));
#endif
    register Direntry_t *dp;
    GV *gv = (GV*)POPs;
    register IO *io = GvIOn(gv);

    if (!io || !IoDIRP(io))
	goto nope;

    if (GIMME == G_ARRAY) {
	/*SUPPRESS 560*/
	while (dp = (Direntry_t *)readdir(IoDIRP(io))) {
#ifdef DIRNAMLEN
	    XPUSHs(sv_2mortal(newSVpv(dp->d_name, dp->d_namlen)));
#else
	    XPUSHs(sv_2mortal(newSVpv(dp->d_name, 0)));
#endif
	}
    }
    else {
	if (!(dp = (Direntry_t *)readdir(IoDIRP(io))))
	    goto nope;
#ifdef DIRNAMLEN
	XPUSHs(sv_2mortal(newSVpv(dp->d_name, dp->d_namlen)));
#else
	XPUSHs(sv_2mortal(newSVpv(dp->d_name, 0)));
#endif
    }
    RETURN;

nope:
    if (!errno)
	errno = EBADF;
    if (GIMME == G_ARRAY)
	RETURN;
    else
	RETPUSHUNDEF;
#else
    DIE(no_dir_func, "readdir");
#endif
}

PP(pp_telldir)
{
    dSP; dTARGET;
#if defined(HAS_TELLDIR) || defined(telldir)
#if !defined(telldir) && !defined(HAS_TELLDIR_PROTOTYPE)
    long telldir _((DIR *));
#endif
    GV *gv = (GV*)POPs;
    register IO *io = GvIOn(gv);

    if (!io || !IoDIRP(io))
	goto nope;

    PUSHi( telldir(IoDIRP(io)) );
    RETURN;
nope:
    if (!errno)
	errno = EBADF;
    RETPUSHUNDEF;
#else
    DIE(no_dir_func, "telldir");
#endif
}

PP(pp_seekdir)
{
    dSP;
#if defined(HAS_SEEKDIR) || defined(seekdir)
    long along = POPl;
    GV *gv = (GV*)POPs;
    register IO *io = GvIOn(gv);

    if (!io || !IoDIRP(io))
	goto nope;

    (void)seekdir(IoDIRP(io), along);

    RETPUSHYES;
nope:
    if (!errno)
	errno = EBADF;
    RETPUSHUNDEF;
#else
    DIE(no_dir_func, "seekdir");
#endif
}

PP(pp_rewinddir)
{
    dSP;
#if defined(HAS_REWINDDIR) || defined(rewinddir)
    GV *gv = (GV*)POPs;
    register IO *io = GvIOn(gv);

    if (!io || !IoDIRP(io))
	goto nope;

    (void)rewinddir(IoDIRP(io));
    RETPUSHYES;
nope:
    if (!errno)
	errno = EBADF;
    RETPUSHUNDEF;
#else
    DIE(no_dir_func, "rewinddir");
#endif
}

PP(pp_closedir)
{
    dSP;
#if defined(Direntry_t) && defined(HAS_READDIR)
    GV *gv = (GV*)POPs;
    register IO *io = GvIOn(gv);

    if (!io || !IoDIRP(io))
	goto nope;

#ifdef VOID_CLOSEDIR
    closedir(IoDIRP(io));
#else
    if (closedir(IoDIRP(io)) < 0)
	goto nope;
#endif
    IoDIRP(io) = 0;

    RETPUSHYES;
nope:
    if (!errno)
	errno = EBADF;
    RETPUSHUNDEF;
#else
    DIE(no_dir_func, "closedir");
#endif
}

/* Process control. */

PP(pp_fork)
{
    dSP; dTARGET;
    int childpid;
    GV *tmpgv;

    EXTEND(SP, 1);
#ifdef HAS_FORK
    childpid = fork();
    if (childpid < 0)
	RETSETUNDEF;
    if (!childpid) {
	/*SUPPRESS 560*/
	if (tmpgv = gv_fetchpv("$", TRUE, SVt_PV))
	    sv_setiv(GvSV(tmpgv), (I32)getpid());
	hv_clear(pidstatus);	/* no kids, so don't wait for 'em */
    }
    PUSHi(childpid);
    RETURN;
#else
    DIE(no_func, "Unsupported function fork");
#endif
}

PP(pp_wait)
{
    dSP; dTARGET;
    int childpid;
    int argflags;
    I32 value;

    EXTEND(SP, 1);
#ifdef HAS_WAIT
    childpid = wait(&argflags);
    if (childpid > 0)
	pidgone(childpid, argflags);
    value = (I32)childpid;
    statusvalue = (U16)argflags;
    PUSHi(value);
    RETURN;
#else
    DIE(no_func, "Unsupported function wait");
#endif
}

PP(pp_waitpid)
{
    dSP; dTARGET;
    int childpid;
    int optype;
    int argflags;
    I32 value;

#ifdef HAS_WAIT
    optype = POPi;
    childpid = TOPi;
    childpid = wait4pid(childpid, &argflags, optype);
    value = (I32)childpid;
    statusvalue = (U16)argflags;
    SETi(value);
    RETURN;
#else
    DIE(no_func, "Unsupported function wait");
#endif
}

PP(pp_system)
{
    dSP; dMARK; dORIGMARK; dTARGET;
    I32 value;
    int childpid;
    int result;
    int status;
    Signal_t (*ihand)();     /* place to save signal during system() */
    Signal_t (*qhand)();     /* place to save signal during system() */

#if defined(HAS_FORK) && !defined(VMS)
    if (SP - MARK == 1) {
	if (tainting) {
	    char *junk = SvPV(TOPs, na);
	    TAINT_ENV();
	    TAINT_PROPER("system");
	}
    }
    while ((childpid = vfork()) == -1) {
	if (errno != EAGAIN) {
	    value = -1;
	    SP = ORIGMARK;
	    PUSHi(value);
	    RETURN;
	}
	sleep(5);
    }
    if (childpid > 0) {
	ihand = signal(SIGINT, SIG_IGN);
	qhand = signal(SIGQUIT, SIG_IGN);
	result = wait4pid(childpid, &status, 0);
	(void)signal(SIGINT, ihand);
	(void)signal(SIGQUIT, qhand);
	statusvalue = (U16)status;
	if (result < 0)
	    value = -1;
	else {
	    value = (I32)((unsigned int)status & 0xffff);
	}
	do_execfree();	/* free any memory child malloced on vfork */
	SP = ORIGMARK;
	PUSHi(value);
	RETURN;
    }
    if (op->op_flags & OPf_STACKED) {
	SV *really = *++MARK;
	value = (I32)do_aexec(really, MARK, SP);
    }
    else if (SP - MARK != 1)
	value = (I32)do_aexec(Nullsv, MARK, SP);
    else {
	value = (I32)do_exec(SvPVx(sv_mortalcopy(*SP), na));
    }
    _exit(-1);
#else /* ! FORK or VMS */
    if (op->op_flags & OPf_STACKED) {
	SV *really = *++MARK;
	value = (I32)do_aspawn(really, MARK, SP);
    }
    else if (SP - MARK != 1)
	value = (I32)do_aspawn(Nullsv, MARK, SP);
    else {
	value = (I32)do_spawn(SvPVx(sv_mortalcopy(*SP), na));
    }
    do_execfree();
    SP = ORIGMARK;
    PUSHi(value);
#endif /* !FORK or VMS */
    RETURN;
}

PP(pp_exec)
{
    dSP; dMARK; dORIGMARK; dTARGET;
    I32 value;

    if (op->op_flags & OPf_STACKED) {
	SV *really = *++MARK;
	value = (I32)do_aexec(really, MARK, SP);
    }
    else if (SP - MARK != 1)
#ifdef VMS
	value = (I32)vms_do_aexec(Nullsv, MARK, SP);
#else
	value = (I32)do_aexec(Nullsv, MARK, SP);
#endif
    else {
	if (tainting) {
	    char *junk = SvPV(*SP, na);
	    TAINT_ENV();
	    TAINT_PROPER("exec");
	}
#ifdef VMS
	value = (I32)vms_do_exec(SvPVx(sv_mortalcopy(*SP), na));
#else
	value = (I32)do_exec(SvPVx(sv_mortalcopy(*SP), na));
#endif
    }
    SP = ORIGMARK;
    PUSHi(value);
    RETURN;
}

PP(pp_kill)
{
    dSP; dMARK; dTARGET;
    I32 value;
#ifdef HAS_KILL
    value = (I32)apply(op->op_type, MARK, SP);
    SP = MARK;
    PUSHi(value);
    RETURN;
#else
    DIE(no_func, "Unsupported function kill");
#endif
}

PP(pp_getppid)
{
#ifdef HAS_GETPPID
    dSP; dTARGET;
    XPUSHi( getppid() );
    RETURN;
#else
    DIE(no_func, "getppid");
#endif
}

PP(pp_getpgrp)
{
#ifdef HAS_GETPGRP
    dSP; dTARGET;
    int pid;
    I32 value;

    if (MAXARG < 1)
	pid = 0;
    else
	pid = SvIVx(POPs);
#ifdef USE_BSDPGRP
    value = (I32)getpgrp(pid);
#else
    if (pid != 0)
	DIE("POSIX getpgrp can't take an argument");
    value = (I32)getpgrp();
#endif
    XPUSHi(value);
    RETURN;
#else
    DIE(no_func, "getpgrp()");
#endif
}

PP(pp_setpgrp)
{
#ifdef HAS_SETPGRP
    dSP; dTARGET;
    int pgrp;
    int pid;
    if (MAXARG < 2) {
	pgrp = 0;
	pid = 0;
    }
    else {
	pgrp = POPi;
	pid = TOPi;
    }

    TAINT_PROPER("setpgrp");
#ifdef USE_BSDPGRP
    SETi( setpgrp(pid, pgrp) >= 0 );
#else
    if ((pgrp != 0) || (pid != 0)) {
	DIE("POSIX setpgrp can't take an argument");
    }
    SETi( setpgrp() >= 0 );
#endif /* USE_BSDPGRP */
    RETURN;
#else
    DIE(no_func, "setpgrp()");
#endif
}

PP(pp_getpriority)
{
    dSP; dTARGET;
    int which;
    int who;
#ifdef HAS_GETPRIORITY
    who = POPi;
    which = TOPi;
    SETi( getpriority(which, who) );
    RETURN;
#else
    DIE(no_func, "getpriority()");
#endif
}

PP(pp_setpriority)
{
    dSP; dTARGET;
    int which;
    int who;
    int niceval;
#ifdef HAS_SETPRIORITY
    niceval = POPi;
    who = POPi;
    which = TOPi;
    TAINT_PROPER("setpriority");
    SETi( setpriority(which, who, niceval) >= 0 );
    RETURN;
#else
    DIE(no_func, "setpriority()");
#endif
}

/* Time calls. */

PP(pp_time)
{
    dSP; dTARGET;
    XPUSHi( time(Null(Time_t*)) );
    RETURN;
}

#ifndef HZ
#define HZ 60
#endif

PP(pp_tms)
{
    dSP;

#if defined(MSDOS) || !defined(HAS_TIMES)
    DIE("times not implemented");
#else
    EXTEND(SP, 4);

#ifndef VMS
    (void)times(&timesbuf);
#else
    (void)times((tbuffer_t *)&timesbuf);  /* time.h uses different name for */
                                          /* struct tms, though same data   */
                                          /* is returned.                   */
#endif

    PUSHs(sv_2mortal(newSVnv(((double)timesbuf.tms_utime)/HZ)));
    if (GIMME == G_ARRAY) {
	PUSHs(sv_2mortal(newSVnv(((double)timesbuf.tms_stime)/HZ)));
	PUSHs(sv_2mortal(newSVnv(((double)timesbuf.tms_cutime)/HZ)));
	PUSHs(sv_2mortal(newSVnv(((double)timesbuf.tms_cstime)/HZ)));
    }
    RETURN;
#endif /* MSDOS */
}

PP(pp_localtime)
{
    return pp_gmtime(ARGS);
}

PP(pp_gmtime)
{
    dSP;
    Time_t when;
    struct tm *tmbuf;
    static char *dayname[] = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};
    static char *monname[] = {"Jan", "Feb", "Mar", "Apr", "May", "Jun",
			      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};

    if (MAXARG < 1)
	(void)time(&when);
    else
	when = (Time_t)SvIVx(POPs);

    if (op->op_type == OP_LOCALTIME)
	tmbuf = localtime(&when);
    else
	tmbuf = gmtime(&when);

    EXTEND(SP, 9);
    if (GIMME != G_ARRAY) {
	dTARGET;
	char mybuf[30];
	if (!tmbuf)
	    RETPUSHUNDEF;
	sprintf(mybuf, "%s %s %2d %02d:%02d:%02d %d",
	    dayname[tmbuf->tm_wday],
	    monname[tmbuf->tm_mon],
	    tmbuf->tm_mday,
	    tmbuf->tm_hour,
	    tmbuf->tm_min,
	    tmbuf->tm_sec,
	    tmbuf->tm_year + 1900);
	PUSHp(mybuf, strlen(mybuf));
    }
    else if (tmbuf) {
	PUSHs(sv_2mortal(newSViv((I32)tmbuf->tm_sec)));
	PUSHs(sv_2mortal(newSViv((I32)tmbuf->tm_min)));
	PUSHs(sv_2mortal(newSViv((I32)tmbuf->tm_hour)));
	PUSHs(sv_2mortal(newSViv((I32)tmbuf->tm_mday)));
	PUSHs(sv_2mortal(newSViv((I32)tmbuf->tm_mon)));
	PUSHs(sv_2mortal(newSViv((I32)tmbuf->tm_year)));
	PUSHs(sv_2mortal(newSViv((I32)tmbuf->tm_wday)));
	PUSHs(sv_2mortal(newSViv((I32)tmbuf->tm_yday)));
	PUSHs(sv_2mortal(newSViv((I32)tmbuf->tm_isdst)));
    }
    RETURN;
}

PP(pp_alarm)
{
    dSP; dTARGET;
    int anum;
#ifdef HAS_ALARM
    anum = POPi;
    anum = alarm((unsigned int)anum);
    EXTEND(SP, 1);
    if (anum < 0)
	RETPUSHUNDEF;
    PUSHi((I32)anum);
    RETURN;
#else
    DIE(no_func, "Unsupported function alarm");
#endif
}

PP(pp_sleep)
{
    dSP; dTARGET;
    I32 duration;
    Time_t lasttime;
    Time_t when;

    (void)time(&lasttime);
    if (MAXARG < 1)
	pause();
    else {
	duration = POPi;
	sleep((unsigned int)duration);
    }
    (void)time(&when);
    XPUSHi(when - lasttime);
    RETURN;
}

/* Shared memory. */

PP(pp_shmget)
{
    return pp_semget(ARGS);
}

PP(pp_shmctl)
{
    return pp_semctl(ARGS);
}

PP(pp_shmread)
{
    return pp_shmwrite(ARGS);
}

PP(pp_shmwrite)
{
#if defined(HAS_MSG) || defined(HAS_SEM) || defined(HAS_SHM)
    dSP; dMARK; dTARGET;
    I32 value = (I32)(do_shmio(op->op_type, MARK, SP) >= 0);
    SP = MARK;
    PUSHi(value);
    RETURN;
#else
    pp_semget(ARGS);
#endif
}

/* Message passing. */

PP(pp_msgget)
{
    return pp_semget(ARGS);
}

PP(pp_msgctl)
{
    return pp_semctl(ARGS);
}

PP(pp_msgsnd)
{
#if defined(HAS_MSG) || defined(HAS_SEM) || defined(HAS_SHM)
    dSP; dMARK; dTARGET;
    I32 value = (I32)(do_msgsnd(MARK, SP) >= 0);
    SP = MARK;
    PUSHi(value);
    RETURN;
#else
    pp_semget(ARGS);
#endif
}

PP(pp_msgrcv)
{
#if defined(HAS_MSG) || defined(HAS_SEM) || defined(HAS_SHM)
    dSP; dMARK; dTARGET;
    I32 value = (I32)(do_msgrcv(MARK, SP) >= 0);
    SP = MARK;
    PUSHi(value);
    RETURN;
#else
    pp_semget(ARGS);
#endif
}

/* Semaphores. */

PP(pp_semget)
{
#if defined(HAS_MSG) || defined(HAS_SEM) || defined(HAS_SHM)
    dSP; dMARK; dTARGET;
    int anum = do_ipcget(op->op_type, MARK, SP);
    SP = MARK;
    if (anum == -1)
	RETPUSHUNDEF;
    PUSHi(anum);
    RETURN;
#else
    DIE("System V IPC is not implemented on this machine");
#endif
}

PP(pp_semctl)
{
#if defined(HAS_MSG) || defined(HAS_SEM) || defined(HAS_SHM)
    dSP; dMARK; dTARGET;
    int anum = do_ipcctl(op->op_type, MARK, SP);
    SP = MARK;
    if (anum == -1)
	RETSETUNDEF;
    if (anum != 0) {
	PUSHi(anum);
    }
    else {
	PUSHp("0 but true",10);
    }
    RETURN;
#else
    pp_semget(ARGS);
#endif
}

PP(pp_semop)
{
#if defined(HAS_MSG) || defined(HAS_SEM) || defined(HAS_SHM)
    dSP; dMARK; dTARGET;
    I32 value = (I32)(do_semop(MARK, SP) >= 0);
    SP = MARK;
    PUSHi(value);
    RETURN;
#else
    pp_semget(ARGS);
#endif
}

/* Get system info. */

PP(pp_ghbyname)
{
#ifdef HAS_SOCKET
    return pp_ghostent(ARGS);
#else
    DIE(no_sock_func, "gethostbyname");
#endif
}

PP(pp_ghbyaddr)
{
#ifdef HAS_SOCKET
    return pp_ghostent(ARGS);
#else
    DIE(no_sock_func, "gethostbyaddr");
#endif
}

PP(pp_ghostent)
{
    dSP;
#ifdef HAS_SOCKET
    I32 which = op->op_type;
    register char **elem;
    register SV *sv;
    struct hostent *gethostbyname();
    struct hostent *gethostbyaddr();
#ifdef HAS_GETHOSTENT
    struct hostent *gethostent();
#endif
    struct hostent *hent;
    unsigned long len;

    EXTEND(SP, 10);
    if (which == OP_GHBYNAME) {
	hent = gethostbyname(POPp);
    }
    else if (which == OP_GHBYADDR) {
	int addrtype = POPi;
	SV *addrstr = POPs;
	STRLEN addrlen;
	char *addr = SvPV(addrstr, addrlen);

	hent = gethostbyaddr(addr, addrlen, addrtype);
    }
    else
#ifdef HAS_GETHOSTENT
	hent = gethostent();
#else
	DIE("gethostent not implemented");
#endif

#ifdef HOST_NOT_FOUND
    if (!hent)
	statusvalue = (U16)h_errno & 0xffff;
#endif

    if (GIMME != G_ARRAY) {
	PUSHs(sv = sv_newmortal());
	if (hent) {
	    if (which == OP_GHBYNAME) {
		sv_setpvn(sv, hent->h_addr, hent->h_length);
	    }
	    else
		sv_setpv(sv, (char*)hent->h_name);
	}
	RETURN;
    }

    if (hent) {
	PUSHs(sv = sv_mortalcopy(&sv_no));
	sv_setpv(sv, (char*)hent->h_name);
	PUSHs(sv = sv_mortalcopy(&sv_no));
	for (elem = hent->h_aliases; elem && *elem; elem++) {
	    sv_catpv(sv, *elem);
	    if (elem[1])
		sv_catpvn(sv, " ", 1);
	}
	PUSHs(sv = sv_mortalcopy(&sv_no));
	sv_setiv(sv, (I32)hent->h_addrtype);
	PUSHs(sv = sv_mortalcopy(&sv_no));
	len = hent->h_length;
	sv_setiv(sv, (I32)len);
#ifdef h_addr
	for (elem = hent->h_addr_list; elem && *elem; elem++) {
	    XPUSHs(sv = sv_mortalcopy(&sv_no));
	    sv_setpvn(sv, *elem, len);
	}
#else
	PUSHs(sv = sv_mortalcopy(&sv_no));
	sv_setpvn(sv, hent->h_addr, len);
#endif /* h_addr */
    }
    RETURN;
#else
    DIE(no_sock_func, "gethostent");
#endif
}

PP(pp_gnbyname)
{
#ifdef HAS_SOCKET
    return pp_gnetent(ARGS);
#else
    DIE(no_sock_func, "getnetbyname");
#endif
}

PP(pp_gnbyaddr)
{
#ifdef HAS_SOCKET
    return pp_gnetent(ARGS);
#else
    DIE(no_sock_func, "getnetbyaddr");
#endif
}

PP(pp_gnetent)
{
    dSP;
#ifdef HAS_SOCKET
    I32 which = op->op_type;
    register char **elem;
    register SV *sv;
    struct netent *getnetbyname();
    struct netent *getnetbyaddr();
    struct netent *getnetent();
    struct netent *nent;

    if (which == OP_GNBYNAME)
	nent = getnetbyname(POPp);
    else if (which == OP_GNBYADDR) {
	int addrtype = POPi;
	unsigned long addr = U_L(POPn);
	nent = getnetbyaddr((long)addr, addrtype);
    }
    else
	nent = getnetent();

    EXTEND(SP, 4);
    if (GIMME != G_ARRAY) {
	PUSHs(sv = sv_newmortal());
	if (nent) {
	    if (which == OP_GNBYNAME)
		sv_setiv(sv, (I32)nent->n_net);
	    else
		sv_setpv(sv, nent->n_name);
	}
	RETURN;
    }

    if (nent) {
	PUSHs(sv = sv_mortalcopy(&sv_no));
	sv_setpv(sv, nent->n_name);
	PUSHs(sv = sv_mortalcopy(&sv_no));
	for (elem = nent->n_aliases; *elem; elem++) {
	    sv_catpv(sv, *elem);
	    if (elem[1])
		sv_catpvn(sv, " ", 1);
	}
	PUSHs(sv = sv_mortalcopy(&sv_no));
	sv_setiv(sv, (I32)nent->n_addrtype);
	PUSHs(sv = sv_mortalcopy(&sv_no));
	sv_setiv(sv, (I32)nent->n_net);
    }

    RETURN;
#else
    DIE(no_sock_func, "getnetent");
#endif
}

PP(pp_gpbyname)
{
#ifdef HAS_SOCKET
    return pp_gprotoent(ARGS);
#else
    DIE(no_sock_func, "getprotobyname");
#endif
}

PP(pp_gpbynumber)
{
#ifdef HAS_SOCKET
    return pp_gprotoent(ARGS);
#else
    DIE(no_sock_func, "getprotobynumber");
#endif
}

PP(pp_gprotoent)
{
    dSP;
#ifdef HAS_SOCKET
    I32 which = op->op_type;
    register char **elem;
    register SV *sv;
    struct protoent *getprotobyname();
    struct protoent *getprotobynumber();
    struct protoent *getprotoent();
    struct protoent *pent;

    if (which == OP_GPBYNAME)
	pent = getprotobyname(POPp);
    else if (which == OP_GPBYNUMBER)
	pent = getprotobynumber(POPi);
    else
	pent = getprotoent();

    EXTEND(SP, 3);
    if (GIMME != G_ARRAY) {
	PUSHs(sv = sv_newmortal());
	if (pent) {
	    if (which == OP_GPBYNAME)
		sv_setiv(sv, (I32)pent->p_proto);
	    else
		sv_setpv(sv, pent->p_name);
	}
	RETURN;
    }

    if (pent) {
	PUSHs(sv = sv_mortalcopy(&sv_no));
	sv_setpv(sv, pent->p_name);
	PUSHs(sv = sv_mortalcopy(&sv_no));
	for (elem = pent->p_aliases; *elem; elem++) {
	    sv_catpv(sv, *elem);
	    if (elem[1])
		sv_catpvn(sv, " ", 1);
	}
	PUSHs(sv = sv_mortalcopy(&sv_no));
	sv_setiv(sv, (I32)pent->p_proto);
    }

    RETURN;
#else
    DIE(no_sock_func, "getprotoent");
#endif
}

PP(pp_gsbyname)
{
#ifdef HAS_SOCKET
    return pp_gservent(ARGS);
#else
    DIE(no_sock_func, "getservbyname");
#endif
}

PP(pp_gsbyport)
{
#ifdef HAS_SOCKET
    return pp_gservent(ARGS);
#else
    DIE(no_sock_func, "getservbyport");
#endif
}

PP(pp_gservent)
{
    dSP;
#ifdef HAS_SOCKET
    I32 which = op->op_type;
    register char **elem;
    register SV *sv;
    struct servent *getservbyname();
    struct servent *getservbynumber();
    struct servent *getservent();
    struct servent *sent;

    if (which == OP_GSBYNAME) {
	char *proto = POPp;
	char *name = POPp;

	if (proto && !*proto)
	    proto = Nullch;

	sent = getservbyname(name, proto);
    }
    else if (which == OP_GSBYPORT) {
	char *proto = POPp;
	int port = POPi;

	sent = getservbyport(port, proto);
    }
    else
	sent = getservent();

    EXTEND(SP, 4);
    if (GIMME != G_ARRAY) {
	PUSHs(sv = sv_newmortal());
	if (sent) {
	    if (which == OP_GSBYNAME) {
#ifdef HAS_NTOHS
		sv_setiv(sv, (I32)ntohs(sent->s_port));
#else
		sv_setiv(sv, (I32)(sent->s_port));
#endif
	    }
	    else
		sv_setpv(sv, sent->s_name);
	}
	RETURN;
    }

    if (sent) {
	PUSHs(sv = sv_mortalcopy(&sv_no));
	sv_setpv(sv, sent->s_name);
	PUSHs(sv = sv_mortalcopy(&sv_no));
	for (elem = sent->s_aliases; *elem; elem++) {
	    sv_catpv(sv, *elem);
	    if (elem[1])
		sv_catpvn(sv, " ", 1);
	}
	PUSHs(sv = sv_mortalcopy(&sv_no));
#ifdef HAS_NTOHS
	sv_setiv(sv, (I32)ntohs(sent->s_port));
#else
	sv_setiv(sv, (I32)(sent->s_port));
#endif
	PUSHs(sv = sv_mortalcopy(&sv_no));
	sv_setpv(sv, sent->s_proto);
    }

    RETURN;
#else
    DIE(no_sock_func, "getservent");
#endif
}

PP(pp_shostent)
{
    dSP;
#ifdef HAS_SOCKET
    sethostent(TOPi);
    RETSETYES;
#else
    DIE(no_sock_func, "sethostent");
#endif
}

PP(pp_snetent)
{
    dSP;
#ifdef HAS_SOCKET
    setnetent(TOPi);
    RETSETYES;
#else
    DIE(no_sock_func, "setnetent");
#endif
}

PP(pp_sprotoent)
{
    dSP;
#ifdef HAS_SOCKET
    setprotoent(TOPi);
    RETSETYES;
#else
    DIE(no_sock_func, "setprotoent");
#endif
}

PP(pp_sservent)
{
    dSP;
#ifdef HAS_SOCKET
    setservent(TOPi);
    RETSETYES;
#else
    DIE(no_sock_func, "setservent");
#endif
}

PP(pp_ehostent)
{
    dSP;
#ifdef HAS_SOCKET
    endhostent();
    EXTEND(sp,1);
    RETPUSHYES;
#else
    DIE(no_sock_func, "endhostent");
#endif
}

PP(pp_enetent)
{
    dSP;
#ifdef HAS_SOCKET
    endnetent();
    EXTEND(sp,1);
    RETPUSHYES;
#else
    DIE(no_sock_func, "endnetent");
#endif
}

PP(pp_eprotoent)
{
    dSP;
#ifdef HAS_SOCKET
    endprotoent();
    EXTEND(sp,1);
    RETPUSHYES;
#else
    DIE(no_sock_func, "endprotoent");
#endif
}

PP(pp_eservent)
{
    dSP;
#ifdef HAS_SOCKET
    endservent();
    EXTEND(sp,1);
    RETPUSHYES;
#else
    DIE(no_sock_func, "endservent");
#endif
}

PP(pp_gpwnam)
{
#ifdef HAS_PASSWD
    return pp_gpwent(ARGS);
#else
    DIE(no_func, "getpwnam");
#endif
}

PP(pp_gpwuid)
{
#ifdef HAS_PASSWD
    return pp_gpwent(ARGS);
#else
    DIE(no_func, "getpwuid");
#endif
}

PP(pp_gpwent)
{
    dSP;
#ifdef HAS_PASSWD
    I32 which = op->op_type;
    register SV *sv;
    struct passwd *pwent;

    if (which == OP_GPWNAM)
	pwent = getpwnam(POPp);
    else if (which == OP_GPWUID)
	pwent = getpwuid(POPi);
    else
	pwent = (struct passwd *)getpwent();

    EXTEND(SP, 10);
    if (GIMME != G_ARRAY) {
	PUSHs(sv = sv_newmortal());
	if (pwent) {
	    if (which == OP_GPWNAM)
		sv_setiv(sv, (I32)pwent->pw_uid);
	    else
		sv_setpv(sv, pwent->pw_name);
	}
	RETURN;
    }

    if (pwent) {
	PUSHs(sv = sv_mortalcopy(&sv_no));
	sv_setpv(sv, pwent->pw_name);
	PUSHs(sv = sv_mortalcopy(&sv_no));
	sv_setpv(sv, pwent->pw_passwd);
	PUSHs(sv = sv_mortalcopy(&sv_no));
	sv_setiv(sv, (I32)pwent->pw_uid);
	PUSHs(sv = sv_mortalcopy(&sv_no));
	sv_setiv(sv, (I32)pwent->pw_gid);
	PUSHs(sv = sv_mortalcopy(&sv_no));
#ifdef PWCHANGE
	sv_setiv(sv, (I32)pwent->pw_change);
#else
#ifdef PWQUOTA
	sv_setiv(sv, (I32)pwent->pw_quota);
#else
#ifdef PWAGE
	sv_setpv(sv, pwent->pw_age);
#endif
#endif
#endif
	PUSHs(sv = sv_mortalcopy(&sv_no));
#ifdef PWCLASS
	sv_setpv(sv, pwent->pw_class);
#else
#ifdef PWCOMMENT
	sv_setpv(sv, pwent->pw_comment);
#endif
#endif
	PUSHs(sv = sv_mortalcopy(&sv_no));
	sv_setpv(sv, pwent->pw_gecos);
	PUSHs(sv = sv_mortalcopy(&sv_no));
	sv_setpv(sv, pwent->pw_dir);
	PUSHs(sv = sv_mortalcopy(&sv_no));
	sv_setpv(sv, pwent->pw_shell);
#ifdef PWEXPIRE
	PUSHs(sv = sv_mortalcopy(&sv_no));
	sv_setiv(sv, (I32)pwent->pw_expire);
#endif
    }
    RETURN;
#else
    DIE(no_func, "getpwent");
#endif
}

PP(pp_spwent)
{
    dSP;
#ifdef HAS_PASSWD
    setpwent();
    RETPUSHYES;
#else
    DIE(no_func, "setpwent");
#endif
}

PP(pp_epwent)
{
    dSP;
#ifdef HAS_PASSWD
    endpwent();
    RETPUSHYES;
#else
    DIE(no_func, "endpwent");
#endif
}

PP(pp_ggrnam)
{
#ifdef HAS_GROUP
    return pp_ggrent(ARGS);
#else
    DIE(no_func, "getgrnam");
#endif
}

PP(pp_ggrgid)
{
#ifdef HAS_GROUP
    return pp_ggrent(ARGS);
#else
    DIE(no_func, "getgrgid");
#endif
}

PP(pp_ggrent)
{
    dSP;
#ifdef HAS_GROUP
    I32 which = op->op_type;
    register char **elem;
    register SV *sv;
    struct group *grent;

    if (which == OP_GGRNAM)
	grent = (struct group *)getgrnam(POPp);
    else if (which == OP_GGRGID)
	grent = (struct group *)getgrgid(POPi);
    else
	grent = (struct group *)getgrent();

    EXTEND(SP, 4);
    if (GIMME != G_ARRAY) {
	PUSHs(sv = sv_newmortal());
	if (grent) {
	    if (which == OP_GGRNAM)
		sv_setiv(sv, (I32)grent->gr_gid);
	    else
		sv_setpv(sv, grent->gr_name);
	}
	RETURN;
    }

    if (grent) {
	PUSHs(sv = sv_mortalcopy(&sv_no));
	sv_setpv(sv, grent->gr_name);
	PUSHs(sv = sv_mortalcopy(&sv_no));
	sv_setpv(sv, grent->gr_passwd);
	PUSHs(sv = sv_mortalcopy(&sv_no));
	sv_setiv(sv, (I32)grent->gr_gid);
	PUSHs(sv = sv_mortalcopy(&sv_no));
	for (elem = grent->gr_mem; *elem; elem++) {
	    sv_catpv(sv, *elem);
	    if (elem[1])
		sv_catpvn(sv, " ", 1);
	}
    }

    RETURN;
#else
    DIE(no_func, "getgrent");
#endif
}

PP(pp_sgrent)
{
    dSP;
#ifdef HAS_GROUP
    setgrent();
    RETPUSHYES;
#else
    DIE(no_func, "setgrent");
#endif
}

PP(pp_egrent)
{
    dSP;
#ifdef HAS_GROUP
    endgrent();
    RETPUSHYES;
#else
    DIE(no_func, "endgrent");
#endif
}

PP(pp_getlogin)
{
    dSP; dTARGET;
#ifdef HAS_GETLOGIN
    char *tmps;
    EXTEND(SP, 1);
    if (!(tmps = getlogin()))
	RETPUSHUNDEF;
    PUSHp(tmps, strlen(tmps));
    RETURN;
#else
    DIE(no_func, "getlogin");
#endif
}

/* Miscellaneous. */

PP(pp_syscall)
{
#ifdef HAS_SYSCALL
    dSP; dMARK; dORIGMARK; dTARGET;
    register I32 items = SP - MARK;
    unsigned long a[20];
    register I32 i = 0;
    I32 retval = -1;

    if (tainting) {
	while (++MARK <= SP) {
	    if (SvGMAGICAL(*MARK) && SvSMAGICAL(*MARK) && mg_find(*MARK, 't'))
		tainted = TRUE;
	}
	MARK = ORIGMARK;
	TAINT_PROPER("syscall");
    }

    /* This probably won't work on machines where sizeof(long) != sizeof(int)
     * or where sizeof(long) != sizeof(char*).  But such machines will
     * not likely have syscall implemented either, so who cares?
     */
    while (++MARK <= SP) {
	if (SvNIOK(*MARK) || !i)
	    a[i++] = SvIV(*MARK);
	else
	    a[i++] = (unsigned long)SvPVX(*MARK);
	if (i > 15)
	    break;
    }
    switch (items) {
    default:
	DIE("Too many args to syscall");
    case 0:
	DIE("Too few args to syscall");
    case 1:
	retval = syscall(a[0]);
	break;
    case 2:
	retval = syscall(a[0],a[1]);
	break;
    case 3:
	retval = syscall(a[0],a[1],a[2]);
	break;
    case 4:
	retval = syscall(a[0],a[1],a[2],a[3]);
	break;
    case 5:
	retval = syscall(a[0],a[1],a[2],a[3],a[4]);
	break;
    case 6:
	retval = syscall(a[0],a[1],a[2],a[3],a[4],a[5]);
	break;
    case 7:
	retval = syscall(a[0],a[1],a[2],a[3],a[4],a[5],a[6]);
	break;
    case 8:
	retval = syscall(a[0],a[1],a[2],a[3],a[4],a[5],a[6],a[7]);
	break;
#ifdef atarist
    case 9:
	retval = syscall(a[0],a[1],a[2],a[3],a[4],a[5],a[6],a[7],a[8]);
	break;
    case 10:
	retval = syscall(a[0],a[1],a[2],a[3],a[4],a[5],a[6],a[7],a[8],a[9]);
	break;
    case 11:
	retval = syscall(a[0],a[1],a[2],a[3],a[4],a[5],a[6],a[7],a[8],a[9],
	  a[10]);
	break;
    case 12:
	retval = syscall(a[0],a[1],a[2],a[3],a[4],a[5],a[6],a[7],a[8],a[9],
	  a[10],a[11]);
	break;
    case 13:
	retval = syscall(a[0],a[1],a[2],a[3],a[4],a[5],a[6],a[7],a[8],a[9],
	  a[10],a[11],a[12]);
	break;
    case 14:
	retval = syscall(a[0],a[1],a[2],a[3],a[4],a[5],a[6],a[7],a[8],a[9],
	  a[10],a[11],a[12],a[13]);
	break;
#endif /* atarist */
    }
    SP = ORIGMARK;
    PUSHi(retval);
    RETURN;
#else
    DIE(no_func, "syscall");
#endif
}

