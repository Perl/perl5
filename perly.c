char rcsid[] = "$Header: perly.c,v 3.0.1.5 90/03/27 16:20:57 lwall Locked $\nPatch level: ###\n";
/*
 *    Copyright (c) 1989, Larry Wall
 *
 *    You may distribute under the terms of the GNU General Public License
 *    as specified in the README file that comes with the perl 3.0 kit.
 *
 * $Log:	perly.c,v $
 * Revision 3.0.1.5  90/03/27  16:20:57  lwall
 * patch16: MSDOS support
 * patch16: do FILE inside eval blows up
 * 
 * Revision 3.0.1.4  90/02/28  18:06:41  lwall
 * patch9: perl can now start up other interpreters scripts
 * patch9: nested evals clobbered their longjmp environment
 * patch9: eval could mistakenly return undef in array context
 * 
 * Revision 3.0.1.3  89/12/21  20:15:41  lwall
 * patch7: ANSI strerror() is now supported
 * patch7: errno may now be a macro with an lvalue
 * patch7: allowed setuid scripts to have a space after #!
 * 
 * Revision 3.0.1.2  89/11/17  15:34:42  lwall
 * patch5: fixed possible confusion about current effective gid
 * 
 * Revision 3.0.1.1  89/11/11  04:50:04  lwall
 * patch2: moved yydebug to where its type didn't matter
 * 
 * Revision 3.0  89/10/18  15:22:21  lwall
 * 3.0 baseline
 * 
 */

#include "EXTERN.h"
#include "perl.h"
#include "perly.h"
#include "patchlevel.h"

#ifdef IAMSUID
#ifndef DOSUID
#define DOSUID
#endif
#endif

#ifdef SETUID_SCRIPTS_ARE_SECURE_NOW
#ifdef DOSUID
#undef DOSUID
#endif
#endif

main(argc,argv,env)
register int argc;
register char **argv;
register char **env;
{
    register STR *str;
    register char *s;
    char *index(), *strcpy(), *getenv();
    bool dosearch = FALSE;
#ifdef DOSUID
    char *validarg = "";
#endif

#ifdef SETUID_SCRIPTS_ARE_SECURE_NOW
#ifdef IAMSUID
#undef IAMSUID
    fatal("suidperl is no longer needed since the kernel can now execute\n\
setuid perl scripts securely.\n");
#endif
#endif

    origargv = argv;
    origargc = argc;
    uid = (int)getuid();
    euid = (int)geteuid();
    gid = (int)getgid();
    egid = (int)getegid();
#ifdef MSDOS
    /*
     * There is no way we can refer to them from Perl so close them to save
     * space.  The other alternative would be to provide STDAUX and STDPRN
     * filehandles.
     */
    (void)fclose(stdaux);
    (void)fclose(stdprn);
#endif
    if (do_undump) {
	do_undump = 0;
	loop_ptr = -1;		/* start label stack again */
	goto just_doit;
    }
    (void)sprintf(index(rcsid,'#'), "%d\n", PATCHLEVEL);
    linestr = Str_new(65,80);
    str_nset(linestr,"",0);
    str = str_make("",0);		/* first used for -I flags */
    curstash = defstash = hnew(0);
    curstname = str_make("main",4);
    stab_xhash(stabent("_main",TRUE)) = defstash;
    incstab = aadd(stabent("INC",TRUE));
    incstab->str_pok |= SP_MULTI;
    for (argc--,argv++; argc; argc--,argv++) {
	if (argv[0][0] != '-' || !argv[0][1])
	    break;
#ifdef DOSUID
    if (*validarg)
	validarg = " PHOOEY ";
    else
	validarg = argv[0];
#endif
	s = argv[0]+1;
      reswitch:
	switch (*s) {
	case 'a':
	    minus_a = TRUE;
	    s++;
	    goto reswitch;
	case 'd':
#ifdef TAINT
	    if (euid != uid || egid != gid)
		fatal("No -d allowed in setuid scripts");
#endif
	    perldb = TRUE;
	    s++;
	    goto reswitch;
	case 'D':
#ifdef DEBUGGING
#ifdef TAINT
	    if (euid != uid || egid != gid)
		fatal("No -D allowed in setuid scripts");
#endif
	    debug = atoi(s+1);
#else
	    warn("Recompile perl with -DDEBUGGING to use -D switch\n");
#endif
	    break;
	case 'e':
#ifdef TAINT
	    if (euid != uid || egid != gid)
		fatal("No -e allowed in setuid scripts");
#endif
	    if (!e_fp) {
	        e_tmpname = savestr(TMPPATH);
		(void)mktemp(e_tmpname);
		e_fp = fopen(e_tmpname,"w");
	    }
	    if (argv[1])
		fputs(argv[1],e_fp);
	    (void)putc('\n', e_fp);
	    argc--,argv++;
	    break;
	case 'i':
	    inplace = savestr(s+1);
	    argvoutstab = stabent("ARGVOUT",TRUE);
	    break;
	case 'I':
#ifdef TAINT
	    if (euid != uid || egid != gid)
		fatal("No -I allowed in setuid scripts");
#endif
	    str_cat(str,"-");
	    str_cat(str,s);
	    str_cat(str," ");
	    if (*++s) {
		(void)apush(stab_array(incstab),str_make(s,0));
	    }
	    else {
		(void)apush(stab_array(incstab),str_make(argv[1],0));
		str_cat(str,argv[1]);
		argc--,argv++;
		str_cat(str," ");
	    }
	    break;
	case 'n':
	    minus_n = TRUE;
	    s++;
	    goto reswitch;
	case 'p':
	    minus_p = TRUE;
	    s++;
	    goto reswitch;
	case 'P':
#ifdef TAINT
	    if (euid != uid || egid != gid)
		fatal("No -P allowed in setuid scripts");
#endif
	    preprocess = TRUE;
	    s++;
	    goto reswitch;
	case 's':
#ifdef TAINT
	    if (euid != uid || egid != gid)
		fatal("No -s allowed in setuid scripts");
#endif
	    doswitches = TRUE;
	    s++;
	    goto reswitch;
	case 'S':
	    dosearch = TRUE;
	    s++;
	    goto reswitch;
	case 'u':
	    do_undump = TRUE;
	    s++;
	    goto reswitch;
	case 'U':
	    unsafe = TRUE;
	    s++;
	    goto reswitch;
	case 'v':
	    fputs(rcsid,stdout);
	    fputs("\nCopyright (c) 1989, 1990, Larry Wall\n",stdout);
#ifdef MSDOS
	    fputs("MS-DOS port Copyright (c) 1989, 1990, Diomidis Spinellis\n",
	    stdout);
#endif
	    fputs("\n\
Perl may be copied only under the terms of the GNU General Public License,\n\
a copy of which can be found with the Perl 3.0 distribution kit.\n",stdout);
	    exit(0);
	case 'w':
	    dowarn = TRUE;
	    s++;
	    goto reswitch;
	case '-':
	    argc--,argv++;
	    goto switch_end;
	case 0:
	    break;
	default:
	    fatal("Unrecognized switch: -%s",s);
	}
    }
  switch_end:
    if (e_fp) {
	(void)fclose(e_fp);
	argc++,argv--;
	argv[0] = e_tmpname;
    }
#ifndef PRIVLIB
#define PRIVLIB "/usr/local/lib/perl"
#endif
    (void)apush(stab_array(incstab),str_make(PRIVLIB,0));

    str_set(&str_no,No);
    str_set(&str_yes,Yes);

    /* open script */

    if (argv[0] == Nullch)
	argv[0] = "-";
    if (dosearch && !index(argv[0], '/') && (s = getenv("PATH"))) {
	char *xfound = Nullch, *xfailed = Nullch;
	int len;

	bufend = s + strlen(s);
	while (*s) {
	    s = cpytill(tokenbuf,s,bufend,':',&len);
	    if (*s)
		s++;
	    if (len)
		(void)strcat(tokenbuf+len,"/");
	    (void)strcat(tokenbuf+len,argv[0]);
#ifdef DEBUGGING
	    if (debug & 1)
		fprintf(stderr,"Looking for %s\n",tokenbuf);
#endif
	    if (stat(tokenbuf,&statbuf) < 0)		/* not there? */
		continue;
	    if ((statbuf.st_mode & S_IFMT) == S_IFREG
	     && cando(S_IREAD,TRUE,&statbuf) && cando(S_IEXEC,TRUE,&statbuf)) {
		xfound = tokenbuf;              /* bingo! */
		break;
	    }
	    if (!xfailed)
		xfailed = savestr(tokenbuf);
	}
	if (!xfound)
	    fatal("Can't execute %s", xfailed ? xfailed : argv[0] );
	if (xfailed)
	    Safefree(xfailed);
	argv[0] = savestr(xfound);
    }

    pidstatary = anew(Nullstab);	/* for remembering popen pids, status */

    filename = savestr(argv[0]);
    origfilename = savestr(filename);
    if (strEQ(filename,"-"))
	argv[0] = "";
    if (preprocess) {
	str_cat(str,"-I");
	str_cat(str,PRIVLIB);
	(void)sprintf(buf, "\
/bin/sed -e '/^[^#]/b' \
 -e '/^#[ 	]*include[ 	]/b' \
 -e '/^#[ 	]*define[ 	]/b' \
 -e '/^#[ 	]*if[ 	]/b' \
 -e '/^#[ 	]*ifdef[ 	]/b' \
 -e '/^#[ 	]*ifndef[ 	]/b' \
 -e '/^#[ 	]*else/b' \
 -e '/^#[ 	]*endif/b' \
 -e 's/^#.*//' \
 %s | %s -C %s %s",
	  argv[0], CPPSTDIN, str_get(str), CPPMINUS);
#ifdef IAMSUID				/* actually, this is caught earlier */
	if (euid != uid && !euid)	/* if running suidperl */
#ifdef SETEUID
	    (void)seteuid(uid);		/* musn't stay setuid root */
#else
#ifdef SETREUID
	    (void)setreuid(-1, uid);
#else
	    setuid(uid);
#endif
#endif
#endif /* IAMSUID */
	rsfp = mypopen(buf,"r");
    }
    else if (!*argv[0])
	rsfp = stdin;
    else
	rsfp = fopen(argv[0],"r");
    if (rsfp == Nullfp) {
#ifdef DOSUID
#ifndef IAMSUID		/* in case script is not readable before setuid */
	if (euid && stat(filename,&statbuf) >= 0 &&
	  statbuf.st_mode & (S_ISUID|S_ISGID)) {
	    (void)sprintf(buf, "%s/%s", BIN, "suidperl");
	    execv(buf, origargv);	/* try again */
	    fatal("Can't do setuid\n");
	}
#endif
#endif
	fatal("Can't open perl script \"%s\": %s\n",
	  filename, strerror(errno));
    }
    str_free(str);		/* free -I directories */

    /* do we need to emulate setuid on scripts? */

    /* This code is for those BSD systems that have setuid #! scripts disabled
     * in the kernel because of a security problem.  Merely defining DOSUID
     * in perl will not fix that problem, but if you have disabled setuid
     * scripts in the kernel, this will attempt to emulate setuid and setgid
     * on scripts that have those now-otherwise-useless bits set.  The setuid
     * root version must be called suidperl.  If regular perl discovers that
     * it has opened a setuid script, it calls suidperl with the same argv
     * that it had.  If suidperl finds that the script it has just opened
     * is NOT setuid root, it sets the effective uid back to the uid.  We
     * don't just make perl setuid root because that loses the effective
     * uid we had before invoking perl, if it was different from the uid.
     *
     * DOSUID must be defined in both perl and suidperl, and IAMSUID must
     * be defined in suidperl only.  suidperl must be setuid root.  The
     * Configure script will set this up for you if you want it.
     *
     * There is also the possibility of have a script which is running
     * set-id due to a C wrapper.  We want to do the TAINT checks
     * on these set-id scripts, but don't want to have the overhead of
     * them in normal perl, and can't use suidperl because it will lose
     * the effective uid info, so we have an additional non-setuid root
     * version called taintperl that just does the TAINT checks.
     */

#ifdef DOSUID
    if (fstat(fileno(rsfp),&statbuf) < 0)	/* normal stat is insecure */
	fatal("Can't stat script \"%s\"",filename);
    if (statbuf.st_mode & (S_ISUID|S_ISGID)) {
	int len;

#ifdef IAMSUID
#ifndef SETREUID
	/* On this access check to make sure the directories are readable,
	 * there is actually a small window that the user could use to make
	 * filename point to an accessible directory.  So there is a faint
	 * chance that someone could execute a setuid script down in a
	 * non-accessible directory.  I don't know what to do about that.
	 * But I don't think it's too important.  The manual lies when
	 * it says access() is useful in setuid programs.
	 */
	if (access(filename,1))		/* as a double check */
	    fatal("Permission denied");
#else
	/* If we can swap euid and uid, then we can determine access rights
	 * with a simple stat of the file, and then compare device and
	 * inode to make sure we did stat() on the same file we opened.
	 * Then we just have to make sure he or she can execute it.
	 */
	{
	    struct stat tmpstatbuf;

	    if (setreuid(euid,uid) < 0 || getuid() != euid || geteuid() != uid)
		fatal("Can't swap uid and euid");	/* really paranoid */
	    if (stat(filename,&tmpstatbuf) < 0) /* testing full pathname here */
		fatal("Permission denied");
	    if (tmpstatbuf.st_dev != statbuf.st_dev ||
		tmpstatbuf.st_ino != statbuf.st_ino) {
		(void)fclose(rsfp);
		if (rsfp = mypopen("/bin/mail root","w")) {	/* heh, heh */
		    fprintf(rsfp,
"User %d tried to run dev %d ino %d in place of dev %d ino %d!\n\
(Filename of set-id script was %s, uid %d gid %d.)\n\nSincerely,\nperl\n",
			uid,tmpstatbuf.st_dev, tmpstatbuf.st_ino,
			statbuf.st_dev, statbuf.st_ino,
			filename, statbuf.st_uid, statbuf.st_gid);
		    (void)mypclose(rsfp);
		}
		fatal("Permission denied\n");
	    }
	    if (setreuid(uid,euid) < 0 || getuid() != uid || geteuid() != euid)
		fatal("Can't reswap uid and euid");
	    if (!cando(S_IEXEC,FALSE,&statbuf))		/* can real uid exec? */
		fatal("Permission denied\n");
	}
#endif /* SETREUID */
#endif /* IAMSUID */

	if ((statbuf.st_mode & S_IFMT) != S_IFREG)
	    fatal("Permission denied");
	if ((statbuf.st_mode >> 6) & S_IWRITE)
	    fatal("Setuid/gid script is writable by world");
	doswitches = FALSE;		/* -s is insecure in suid */
	line++;
	if (fgets(tokenbuf,sizeof tokenbuf, rsfp) == Nullch ||
	  strnNE(tokenbuf,"#!",2) )	/* required even on Sys V */
	    fatal("No #! line");
	s = tokenbuf+2;
	if (*s == ' ') s++;
	while (!isspace(*s)) s++;
	if (strnNE(s-4,"perl",4))	/* sanity check */
	    fatal("Not a perl script");
	while (*s == ' ' || *s == '\t') s++;
	/*
	 * #! arg must be what we saw above.  They can invoke it by
	 * mentioning suidperl explicitly, but they may not add any strange
	 * arguments beyond what #! says if they do invoke suidperl that way.
	 */
	len = strlen(validarg);
	if (strEQ(validarg," PHOOEY ") ||
	    strnNE(s,validarg,len) || !isspace(s[len]))
	    fatal("Args must match #! line");

#ifndef IAMSUID
	if (euid != uid && (statbuf.st_mode & S_ISUID) &&
	    euid == statbuf.st_uid)
	    if (!do_undump)
		fatal("YOU HAVEN'T DISABLED SET-ID SCRIPTS IN THE KERNEL YET!\n\
FIX YOUR KERNEL, PUT A C WRAPPER AROUND THIS SCRIPT, OR USE -u AND UNDUMP!\n");
#endif /* IAMSUID */

	if (euid) {	/* oops, we're not the setuid root perl */
	    (void)fclose(rsfp);
#ifndef IAMSUID
	    (void)sprintf(buf, "%s/%s", BIN, "suidperl");
	    execv(buf, origargv);	/* try again */
#endif
	    fatal("Can't do setuid\n");
	}

	if (statbuf.st_mode & S_ISGID && statbuf.st_gid != egid)
#ifdef SETEGID
	    (void)setegid(statbuf.st_gid);
#else
#ifdef SETREGID
	    (void)setregid((GIDTYPE)-1,statbuf.st_gid);
#else
	    setgid(statbuf.st_gid);
#endif
#endif
	if (statbuf.st_mode & S_ISUID) {
	    if (statbuf.st_uid != euid)
#ifdef SETEUID
		(void)seteuid(statbuf.st_uid);	/* all that for this */
#else
#ifdef SETREUID
		(void)setreuid((UIDTYPE)-1,statbuf.st_uid);
#else
		setuid(statbuf.st_uid);
#endif
#endif
	}
	else if (uid)			/* oops, mustn't run as root */
#ifdef SETEUID
	    (void)seteuid((UIDTYPE)uid);
#else
#ifdef SETREUID
	    (void)setreuid((UIDTYPE)-1,(UIDTYPE)uid);
#else
	    setuid((UIDTYPE)uid);
#endif
#endif
	uid = (int)getuid();
	euid = (int)geteuid();
	gid = (int)getgid();
	egid = (int)getegid();
	if (!cando(S_IEXEC,TRUE,&statbuf))
	    fatal("Permission denied\n");	/* they can't do this */
    }
#ifdef IAMSUID
    else if (preprocess)
	fatal("-P not allowed for setuid/setgid script\n");
    else
	fatal("Script is not setuid/setgid in suidperl\n");
#else
#ifndef TAINT		/* we aren't taintperl or suidperl */
    /* script has a wrapper--can't run suidperl or we lose euid */
    else if (euid != uid || egid != gid) {
	(void)fclose(rsfp);
	(void)sprintf(buf, "%s/%s", BIN, "taintperl");
	execv(buf, origargv);	/* try again */
	fatal("Can't run setuid script with taint checks");
    }
#endif /* TAINT */
#endif /* IAMSUID */
#else /* !DOSUID */
#ifndef TAINT		/* we aren't taintperl or suidperl */
    if (euid != uid || egid != gid) {	/* (suidperl doesn't exist, in fact) */
#ifndef SETUID_SCRIPTS_ARE_SECURE_NOW
	fstat(fileno(rsfp),&statbuf);	/* may be either wrapped or real suid */
	if ((euid != uid && euid == statbuf.st_uid && statbuf.st_mode & S_ISUID)
	    ||
	    (egid != gid && egid == statbuf.st_gid && statbuf.st_mode & S_ISGID)
	   )
	    if (!do_undump)
		fatal("YOU HAVEN'T DISABLED SET-ID SCRIPTS IN THE KERNEL YET!\n\
FIX YOUR KERNEL, PUT A C WRAPPER AROUND THIS SCRIPT, OR USE -u AND UNDUMP!\n");
#endif /* SETUID_SCRIPTS_ARE_SECURE_NOW */
	/* not set-id, must be wrapped */
	(void)fclose(rsfp);
	(void)sprintf(buf, "%s/%s", BIN, "taintperl");
	execv(buf, origargv);	/* try again */
	fatal("Can't run setuid script with taint checks");
    }
#endif /* TAINT */
#endif /* DOSUID */

    defstab = stabent("_",TRUE);

    if (perldb) {
	debstash = hnew(0);
	stab_xhash(stabent("_DB",TRUE)) = debstash;
	curstash = debstash;
	lineary = stab_xarray(aadd((tmpstab = stabent("line",TRUE))));
	tmpstab->str_pok |= SP_MULTI;
	subname = str_make("main",4);
	DBstab = stabent("DB",TRUE);
	DBstab->str_pok |= SP_MULTI;
	DBsub = hadd(tmpstab = stabent("sub",TRUE));
	tmpstab->str_pok |= SP_MULTI;
	DBsingle = stab_val((tmpstab = stabent("single",TRUE)));
	tmpstab->str_pok |= SP_MULTI;
	curstash = defstash;
    }

    /* init tokener */

    bufend = bufptr = str_get(linestr);

    savestack = anew(Nullstab);		/* for saving non-local values */
    stack = anew(Nullstab);		/* for saving non-local values */
    stack->ary_flags = 0;		/* not a real array */

    /* now parse the script */

    error_count = 0;
    if (yyparse() || error_count)
	fatal("Execution aborted due to compilation errors.\n");

    New(50,loop_stack,128,struct loop);
#ifdef DEBUGGING
    if (debug) {
	New(51,debname,128,char);
	New(52,debdelim,128,char);
    }
#endif
    curstash = defstash;

    preprocess = FALSE;
    if (e_fp) {
	e_fp = Nullfp;
	(void)UNLINK(e_tmpname);
    }

    /* initialize everything that won't change if we undump */

    if (sigstab = stabent("SIG",allstabs)) {
	sigstab->str_pok |= SP_MULTI;
	(void)hadd(sigstab);
    }

    magicalize("!#?^~=-%0123456789.+&*()<>,\\/[|`':");

    amperstab = stabent("&",allstabs);
    leftstab = stabent("`",allstabs);
    rightstab = stabent("'",allstabs);
    sawampersand = (amperstab || leftstab || rightstab);
    if (tmpstab = stabent(":",allstabs))
	str_set(STAB_STR(tmpstab),chopset);

    /* these aren't necessarily magical */
    if (tmpstab = stabent(";",allstabs))
	str_set(STAB_STR(tmpstab),"\034");
#ifdef TAINT
    tainted = 1;
#endif
    if (tmpstab = stabent("0",allstabs))
	str_set(STAB_STR(tmpstab),origfilename);
#ifdef TAINT
    tainted = 0;
#endif
    if (tmpstab = stabent("]",allstabs))
	str_set(STAB_STR(tmpstab),rcsid);
    str_nset(stab_val(stabent("\"", TRUE)), " ", 1);

    stdinstab = stabent("STDIN",TRUE);
    stdinstab->str_pok |= SP_MULTI;
    stab_io(stdinstab) = stio_new();
    stab_io(stdinstab)->ifp = stdin;
    tmpstab = stabent("stdin",TRUE);
    stab_io(tmpstab) = stab_io(stdinstab);
    tmpstab->str_pok |= SP_MULTI;

    tmpstab = stabent("STDOUT",TRUE);
    tmpstab->str_pok |= SP_MULTI;
    stab_io(tmpstab) = stio_new();
    stab_io(tmpstab)->ofp = stab_io(tmpstab)->ifp = stdout;
    defoutstab = tmpstab;
    tmpstab = stabent("stdout",TRUE);
    stab_io(tmpstab) = stab_io(defoutstab);
    tmpstab->str_pok |= SP_MULTI;

    curoutstab = stabent("STDERR",TRUE);
    curoutstab->str_pok |= SP_MULTI;
    stab_io(curoutstab) = stio_new();
    stab_io(curoutstab)->ofp = stab_io(curoutstab)->ifp = stderr;
    tmpstab = stabent("stderr",TRUE);
    stab_io(tmpstab) = stab_io(curoutstab);
    tmpstab->str_pok |= SP_MULTI;
    curoutstab = defoutstab;		/* switch back to STDOUT */

    statname = Str_new(66,0);		/* last filename we did stat on */

    perldb = FALSE;		/* don't try to instrument evals */

    if (dowarn) {
	stab_check('A','Z');
	stab_check('a','z');
    }

    if (do_undump)
	abort();

  just_doit:		/* come here if running an undumped a.out */
    argc--,argv++;	/* skip name of script */
    if (doswitches) {
	for (; argc > 0 && **argv == '-'; argc--,argv++) {
	    if (argv[0][1] == '-') {
		argc--,argv++;
		break;
	    }
	    str_numset(stab_val(stabent(argv[0]+1,TRUE)),(double)1.0);
	}
    }
#ifdef TAINT
    tainted = 1;
#endif
    if (argvstab = stabent("ARGV",allstabs)) {
	argvstab->str_pok |= SP_MULTI;
	(void)aadd(argvstab);
	for (; argc > 0; argc--,argv++) {
	    (void)apush(stab_array(argvstab),str_make(argv[0],0));
	}
    }
#ifdef TAINT
    (void) stabent("ENV",TRUE);		/* must test PATH and IFS */
#endif
    if (envstab = stabent("ENV",allstabs)) {
	envstab->str_pok |= SP_MULTI;
	(void)hadd(envstab);
	for (; *env; env++) {
	    if (!(s = index(*env,'=')))
		continue;
	    *s++ = '\0';
	    str = str_make(s--,0);
	    str_magic(str, envstab, 'E', *env, s - *env);
	    (void)hstore(stab_hash(envstab), *env, s - *env, str, 0);
	    *s = '=';
	}
    }
#ifdef TAINT
    tainted = 0;
#endif
    if (tmpstab = stabent("$",allstabs))
	str_numset(STAB_STR(tmpstab),(double)getpid());

    if (setjmp(top_env))	/* sets goto_targ on longjump */
	loop_ptr = -1;		/* start label stack again */

#ifdef DEBUGGING
    if (debug & 1024)
	dump_all();
    if (debug)
	fprintf(stderr,"\nEXECUTING...\n\n");
#endif

    /* do it */

    (void) cmd_exec(main_root,G_SCALAR,-1);

    if (goto_targ)
	fatal("Can't find label \"%s\"--aborting",goto_targ);
    exit(0);
    /* NOTREACHED */
}

magicalize(list)
register char *list;
{
    register STAB *stab;
    char sym[2];

    sym[1] = '\0';
    while (*sym = *list++) {
	if (stab = stabent(sym,allstabs)) {
	    stab_flags(stab) = SF_VMAGIC;
	    str_magic(stab_val(stab), stab, 0, Nullch, 0);
	}
    }
}

/* this routine is in perly.c by virtue of being sort of an alternate main() */

int
do_eval(str,optype,stash,gimme,arglast)
STR *str;
int optype;
HASH *stash;
int gimme;
int *arglast;
{
    STR **st = stack->ary_array;
    int retval;
    CMD *myroot;
    ARRAY *ar;
    int i;
    char * VOLATILE oldfile = filename;
    VOLATILE line_t oldline = line;
    VOLATILE int oldtmps_base = tmps_base;
    VOLATILE int oldsave = savestack->ary_fill;
    SPAT * VOLATILE oldspat = curspat;
    static char *last_eval = Nullch;
    static CMD *last_root = Nullcmd;
    VOLATILE int sp = arglast[0];
    char *tmps;

    tmps_base = tmps_max;
    if (curstash != stash) {
	(void)savehptr(&curstash);
	curstash = stash;
    }
    str_set(stab_val(stabent("@",TRUE)),"");
    if (optype != O_DOFILE) {	/* normal eval */
	filename = "(eval)";
	line = 1;
	str_sset(linestr,str);
	str_cat(linestr,";");		/* be kind to them */
    }
    else {
	if (last_root && !in_eval) {
	    Safefree(last_eval);
	    cmd_free(last_root);
	    last_root = Nullcmd;
	}
	filename = savestr(str_get(str));	/* can't free this easily */
	str_set(linestr,"");
	rsfp = fopen(filename,"r");
	ar = stab_array(incstab);
	if (!rsfp && *filename != '/') {
	    for (i = 0; i <= ar->ary_fill; i++) {
		(void)sprintf(buf,"%s/%s",str_get(afetch(ar,i,TRUE)),filename);
		rsfp = fopen(buf,"r");
		if (rsfp) {
		    filename = savestr(buf);
		    break;
		}
	    }
	}
	if (!rsfp) {
	    filename = oldfile;
	    tmps_base = oldtmps_base;
	    if (gimme != G_ARRAY)
		st[++sp] = &str_undef;
	    return sp;
	}
	line = 0;
    }
    in_eval++;
    oldoldbufptr = oldbufptr = bufptr = str_get(linestr);
    bufend = bufptr + linestr->str_cur;
    if (++loop_ptr >= loop_max) {
	loop_max += 128;
	Renew(loop_stack, loop_max, struct loop);
    }
    loop_stack[loop_ptr].loop_label = "_EVAL_";
    loop_stack[loop_ptr].loop_sp = sp;
#ifdef DEBUGGING
    if (debug & 4) {
	deb("(Pushing label #%d _EVAL_)\n", loop_ptr);
    }
#endif
    if (setjmp(loop_stack[loop_ptr].loop_env)) {
	retval = 1;
	last_root = Nullcmd;
    }
    else {
	error_count = 0;
	if (rsfp)
	    retval = yyparse();
	else if (last_root && *bufptr == *last_eval && strEQ(bufptr,last_eval)){
	    retval = 0;
	    eval_root = last_root;	/* no point in reparsing */
	}
	else if (in_eval == 1) {
	    if (last_root) {
		Safefree(last_eval);
		cmd_free(last_root);
	    }
	    last_eval = savestr(bufptr);
	    last_root = Nullcmd;
	    retval = yyparse();
	    if (!retval)
		last_root = eval_root;
	}
	else
	    retval = yyparse();
    }
    myroot = eval_root;		/* in case cmd_exec does another eval! */
    if (retval || error_count) {
	st = stack->ary_array;
	sp = arglast[0];
	if (gimme != G_ARRAY)
	    st[++sp] = &str_undef;
	last_root = Nullcmd;	/* can't free on error, for some reason */
	if (rsfp) {
	    fclose(rsfp);
	    rsfp = 0;
	}
    }
    else {
	sp = cmd_exec(eval_root,gimme,sp);
	st = stack->ary_array;
	for (i = arglast[0] + 1; i <= sp; i++)
	    st[i] = str_static(st[i]);
				/* if we don't save result, free zaps it */
	if (in_eval != 1 && myroot != last_root)
	    cmd_free(myroot);
    }
    in_eval--;
#ifdef DEBUGGING
	if (debug & 4) {
	    tmps = loop_stack[loop_ptr].loop_label;
	    deb("(Popping label #%d %s)\n",loop_ptr,
		tmps ? tmps : "" );
	}
#endif
    loop_ptr--;
    filename = oldfile;
    line = oldline;
    tmps_base = oldtmps_base;
    curspat = oldspat;
    if (savestack->ary_fill > oldsave)	/* let them use local() */
	restorelist(oldsave);
    return sp;
}
