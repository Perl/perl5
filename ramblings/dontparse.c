int
perl_dontparse(sv_interp, xsinit, argc, argv, env)
PerlInterpreter *sv_interp;
void (*xsinit)_((void));
int argc;
char **argv;
char **env;
{
    register char *s;
    char *scriptname = NULL;
    VOL bool dosearch = FALSE;
    char *validarg = "";
    AV* comppadlist;

#ifdef SETUID_SCRIPTS_ARE_SECURE_NOW
#ifdef IAMSUID
#undef IAMSUID
    croak("suidperl is no longer needed since the kernel can now execute\n\
setuid perl scripts securely.\n");
#endif
#endif

    if (!(curinterp = sv_interp))
	return 255;

    origargv = argv;
    origargc = argc;
#ifndef VMS  /* VMS doesn't have environ array */
    origenviron = environ;
#endif

    switch (Sigsetjmp(top_env,1)) {
    case 1:
#ifdef VMS
	statusvalue = 255;
#else
	statusvalue = 1;
#endif
    case 2:
	curstash = defstash;
	if (endav)
	    calllist(endav);
	return(statusvalue);	/* my_exit() was called */
    case 3:
	fprintf(stderr, "panic: top_env\n");
	return 1;
    }

    sv_setpvn(linestr,"",0);
    init_main_stash();

    scriptname = argv[0];
    if (scriptname == Nullch) {
#ifdef MSDOS
	if ( isatty(fileno(stdin)) )
	    moreswitches("v");
#endif
	scriptname = "-";
    }

    init_perllib();

    open_script(scriptname,dosearch,sv);

    validate_suid(validarg);

    if (doextract)
	find_beginning();

    compcv = (CV*)NEWSV(1104,0);
    sv_upgrade((SV *)compcv, SVt_PVCV);

    pad = newAV();
    comppad = pad;
    av_push(comppad, Nullsv);
    curpad = AvARRAY(comppad);
    padname = newAV();
    comppad_name = padname;
    comppad_name_fill = 0;
    min_intro_pending = 0;
    padix = 0;

    comppadlist = newAV();
    AvREAL_off(comppadlist);
    av_store(comppadlist, 0, (SV*)comppad_name);
    av_store(comppadlist, 1, (SV*)comppad);
    CvPADLIST(compcv) = comppadlist;

    if (xsinit)
	(*xsinit)();	/* in case linked C routines want magical variables */
#ifdef VMS
    init_os_extras();
#endif

    init_predump_symbols();
    init_postdump_symbols(argc,argv,env);

    init_lexer();

    /* now parse the script */

    error_count = 0;
    if (yyparse() || error_count) {
	if (minus_c)
	    croak("%s had compilation errors.\n", origfilename);
	else {
	    croak("Execution of %s aborted due to compilation errors.\n",
		origfilename);
	}
    }
    curcop->cop_line = 0;
    curstash = defstash;
    preprocess = FALSE;
    if (e_fp) {
	fclose(e_fp);
	e_fp = Nullfp;
	(void)UNLINK(e_tmpname);
    }

    /* now that script is parsed, we can modify record separator */
    SvREFCNT_dec(rs);
    rs = SvREFCNT_inc(nrs);
    sv_setsv(GvSV(gv_fetchpv("/", TRUE, SVt_PV)), rs);

    if (do_undump)
	my_unexec();

    if (dowarn)
	gv_check(defstash);

    LEAVE;
    FREETMPS;

#ifdef DEBUGGING_MSTATS
    if ((s=getenv("PERL_DEBUG_MSTATS")) && atoi(s) >= 2)
	dump_mstats("after compilation:");
#endif

    ENTER;
    restartop = 0;
    return 0;
}
