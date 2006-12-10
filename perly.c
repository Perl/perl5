/*    perly.c
 *
 *    Copyright (c) 2004, 2005, 2006 Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 * 
 *    Note that this file was originally generated as an output from
 *    GNU bison version 1.875, but now the code is statically maintained
 *    and edited; the bits that are dependent on perly.y are now
 *    #included from the files perly.tab and perly.act.
 *
 *    Here is an important copyright statement from the original, generated
 *    file:
 *
 *	As a special exception, when this file is copied by Bison into a
 *	Bison output file, you may use that output file without
 *	restriction.  This special exception was added by the Free
 *	Software Foundation in version 1.24 of Bison.
 *
 * Note that this file is also #included in madly.c, to allow compilation
 * of a second parser, Perl_madparse, that is identical to Perl_yyparse,
 * but which includes extra code for dumping the parse tree.
 * This is controlled by the PERL_IN_MADLY_C define.
 */



/* allow stack size to grow effectively without limit */
#define YYMAXDEPTH 10000000

#include "EXTERN.h"
#define PERL_IN_PERLY_C
#include "perl.h"

typedef unsigned char yytype_uint8;
typedef signed char yytype_int8;
typedef unsigned short int yytype_uint16;
typedef short int yytype_int16;
typedef signed char yysigned_char;

#ifdef DEBUGGING
#  define YYDEBUG 1
#else
#  define YYDEBUG 0
#endif

/* contains all the parser state tables; auto-generated from perly.y */
#include "perly.tab"

# define YYSIZE_T size_t

#define yyerrok		(yyerrstatus = 0)
#define yyclearin	(yychar = YYEMPTY)
#define YYEMPTY		(-2)
#define YYEOF		0

#define YYACCEPT	goto yyacceptlab
#define YYABORT		goto yyabortlab
#define YYERROR		goto yyerrlab1


/* Like YYERROR except do call yyerror.  This remains here temporarily
   to ease the transition to the new meaning of YYERROR, for GCC.
   Once GCC version 2 has supplanted version 1, this can go.  */

#define YYFAIL		goto yyerrlab

#define YYRECOVERING()  (!!yyerrstatus)

#define YYBACKUP(Token, Value)					\
do								\
    if (yychar == YYEMPTY && yylen == 1) {			\
	yychar = (Token);					\
	yylval = (Value);					\
	yytoken = YYTRANSLATE (yychar);				\
	YYPOPSTACK;						\
	goto yybackup;						\
    }								\
    else {							\
	yyerror ("syntax error: cannot back up");		\
	YYERROR;						\
    }								\
while (0)

#define YYTERROR	1
#define YYERRCODE	256

/* Enable debugging if requested.  */
#ifdef DEBUGGING

#  define yydebug (DEBUG_p_TEST)

#  define YYFPRINTF PerlIO_printf

#  define YYDPRINTF(Args)			\
do {						\
    if (yydebug)				\
	YYFPRINTF Args;				\
} while (0)

#  define YYDSYMPRINTF(Title, Token, Value)			\
do {								\
    if (yydebug) {						\
	YYFPRINTF (Perl_debug_log, "%s ", Title);		\
	yysymprint (aTHX_ Perl_debug_log,  Token, Value);	\
	YYFPRINTF (Perl_debug_log, "\n");			\
    }								\
} while (0)

/*--------------------------------.
| Print this symbol on YYOUTPUT.  |
`--------------------------------*/

static void
yysymprint(pTHX_ PerlIO * const yyoutput, int yytype, const YYSTYPE * const yyvaluep)
{
    if (yytype < YYNTOKENS) {
	YYFPRINTF (yyoutput, "token %s (", yytname[yytype]);
#   ifdef YYPRINT
	YYPRINT (yyoutput, yytoknum[yytype], *yyvaluep);
#   else
	YYFPRINTF (yyoutput, "0x%"UVxf, (UV)yyvaluep->ival);
#   endif
    }
    else
	YYFPRINTF (yyoutput, "nterm %s (", yytname[yytype]);

    YYFPRINTF (yyoutput, ")");
}


/*  yy_stack_print()
 *  print the top 8 items on the parse stack.  The args have the same
 *  meanings as the local vars in yyparse() of the same name */

static void
yy_stack_print (pTHX_ const short *yyss, const short *yyssp, const YYSTYPE *yyvs, const char**yyns)
{
    int i;
    int start = 1;
    int count = (int)(yyssp - yyss);

    if (count > 8) {
	start = count - 8 + 1;
	count = 8;
    }

    PerlIO_printf(Perl_debug_log, "\nindex:");
    for (i=0; i < count; i++)
	PerlIO_printf(Perl_debug_log, " %8d", start+i);
    PerlIO_printf(Perl_debug_log, "\nstate:");
    for (i=0; i < count; i++)
	PerlIO_printf(Perl_debug_log, " %8d", yyss[start+i]);
    PerlIO_printf(Perl_debug_log, "\ntoken:");
    for (i=0; i < count; i++)
	PerlIO_printf(Perl_debug_log, " %8.8s", yyns[start+i]);
    PerlIO_printf(Perl_debug_log, "\nvalue:");
    for (i=0; i < count; i++) {
	switch (yy_type_tab[yystos[yyss[start+i]]]) {
	case toketype_opval:
	    PerlIO_printf(Perl_debug_log, " %8.8s",
		  yyvs[start+i].opval
		    ? PL_op_name[yyvs[start+i].opval->op_type]
		    : "(NULL)"
	    );
	    break;
#ifndef PERL_IN_MADLY_C
	case toketype_p_tkval:
	    PerlIO_printf(Perl_debug_log, " %8.8s",
		  yyvs[start+i].pval ? yyvs[start+i].pval : "(NULL)");
	    break;

	case toketype_i_tkval:
#endif
	case toketype_ival:
	    PerlIO_printf(Perl_debug_log, " %8"IVdf, yyvs[start+i].ival);
	    break;
	default:
	    PerlIO_printf(Perl_debug_log, " %8"UVxf, (UV)yyvs[start+i].ival);
	}
    }
    PerlIO_printf(Perl_debug_log, "\n\n");
}

#  define YY_STACK_PRINT(yyss, yyssp, yyvs, yyns)		\
do {								\
    if (yydebug && DEBUG_v_TEST)				\
	yy_stack_print (aTHX_ (yyss), (yyssp), (yyvs), (yyns));	\
} while (0)


/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

static void
yy_reduce_print (pTHX_ int yyrule)
{
    int yyi;
    const unsigned int yylineno = yyrline[yyrule];
    YYFPRINTF (Perl_debug_log, "Reducing stack by rule %d (line %u), ",
			  yyrule - 1, yylineno);
    /* Print the symbols being reduced, and their result.  */
    for (yyi = yyprhs[yyrule]; 0 <= yyrhs[yyi]; yyi++)
	YYFPRINTF (Perl_debug_log, "%s ", yytname [yyrhs[yyi]]);
    YYFPRINTF (Perl_debug_log, "-> %s\n", yytname [yyr1[yyrule]]);
}

#  define YY_REDUCE_PRINT(Rule)		\
do {					\
    if (yydebug)			\
	yy_reduce_print (aTHX_ Rule);		\
} while (0)

#else /* !DEBUGGING */
#  define YYDPRINTF(Args)
#  define YYDSYMPRINTF(Title, Token, Value)
#  define YY_STACK_PRINT(yyss, yyssp, yyvs, yyns)
#  define YY_REDUCE_PRINT(Rule)
#endif /* !DEBUGGING */


/* YYINITDEPTH -- initial size of the parser's stacks.  */
#ifndef	YYINITDEPTH
# define YYINITDEPTH 200
#endif


#if YYERROR_VERBOSE
#  ifndef yystrlen
#    if defined (__GLIBC__) && defined (_STRING_H)
#      define yystrlen strlen
#    else
/* Return the length of YYSTR.  */
static YYSIZE_T
yystrlen (const char *yystr)
{
    register const char *yys = yystr;

    while (*yys++ != '\0')
	continue;

    return yys - yystr - 1;
}
#    endif
#  endif

#  ifndef yystpcpy
#    if defined (__GLIBC__) && defined (_STRING_H) && defined (_GNU_SOURCE)
#      define yystpcpy stpcpy
#    else
/* Copy YYSRC to YYDEST, returning the address of the terminating '\0' in
   YYDEST.  */
static char *
yystpcpy (pTHX_ char *yydest, const char *yysrc)
{
    register char *yyd = yydest;
    register const char *yys = yysrc;

    while ((*yyd++ = *yys++) != '\0')
	continue;

    return yyd - 1;
}
#    endif
#  endif

#endif /* !YYERROR_VERBOSE */

/*----------.
| yyparse.  |
`----------*/

int
#ifdef PERL_IN_MADLY_C
Perl_madparse (pTHX)
#else
Perl_yyparse (pTHX)
#endif
{
    dVAR;
    int yychar; /* The lookahead symbol.  */
    YYSTYPE yylval; /* The semantic value of the lookahead symbol.  */
    int yynerrs; /* Number of syntax errors so far.  */
    register int yystate;
    register int yyn;
    int yyresult;

    /* Number of tokens to shift before error messages enabled.  */
    int yyerrstatus;
    /* Lookahead token as an internal (translated) token number.  */
    int yytoken = 0;

    /* two stacks and their tools:
	  yyss: related to states,
	  yyvs: related to semantic values,

	  Refer to the stacks thru separate pointers, to allow yyoverflow
	  to reallocate them elsewhere.  */

    /* The state stack.  */
    short *yyss;
    register short *yyssp;

    /* The semantic value stack.  */
    YYSTYPE *yyvs;
    register YYSTYPE *yyvsp;

    /* for ease of re-allocation and automatic freeing, have two SVs whose
      * SvPVX points to the stacks */
    SV *yyss_sv, *yyvs_sv;

#ifdef DEBUGGING
    /* maintain also a stack of token/rule names for debugging with -Dpv */
    const char **yyns, **yynsp;
    SV *yyns_sv;
#  define YYPOPSTACK   (yyvsp--, yyssp--, yynsp--)
#else
#  define YYPOPSTACK   (yyvsp--, yyssp--)
#endif


    YYSIZE_T yystacksize = YYINITDEPTH;

    /* The variables used to return semantic value and location from the
	  action routines.  */
    YYSTYPE yyval;


    /* When reducing, the number of symbols on the RHS of the reduced
	  rule.  */
    int yylen;

    /* keep track of which pad ops are currently using */
    AV* comppad = PL_comppad;

#ifndef PERL_IN_MADLY_C
#  ifdef PERL_MAD
    if (PL_madskills)
	return madparse();
#  endif
#endif

    YYDPRINTF ((Perl_debug_log, "Starting parse\n"));

    ENTER;			/* force stack free before we return */
    SAVEVPTR(PL_yycharp);
    SAVEVPTR(PL_yylvalp);
    PL_yycharp = &yychar; /* so PL_yyerror() can access it */
    PL_yylvalp = &yylval; /* so various functions in toke.c can access it */

    yyss_sv = newSV(YYINITDEPTH * sizeof(short));
    yyvs_sv = newSV(YYINITDEPTH * sizeof(YYSTYPE));
    SAVEFREESV(yyss_sv);
    SAVEFREESV(yyvs_sv);
    yyss = (short *) SvPVX(yyss_sv);
    yyvs = (YYSTYPE *) SvPVX(yyvs_sv);
    /* note that elements zero of yyvs and yyns are not used */
    yyssp = yyss;
    yyvsp = yyvs;
#ifdef DEBUGGING
    yyns_sv = newSV(YYINITDEPTH * sizeof(char *));
    SAVEFREESV(yyns_sv);
    /* XXX This seems strange to cast char * to char ** */
    yyns = (const char **) SvPVX(yyns_sv);
    yynsp = yyns;
#endif

    yystate = 0;
    yyerrstatus = 0;
    yynerrs = 0;
    yychar = YYEMPTY;		/* Cause a token to be read.  */

    YYDPRINTF ((Perl_debug_log, "Entering state %d\n", yystate));

    goto yysetstate;

/*------------------------------------------------------------.
| yynewstate -- Push a new state, which is found in yystate.  |
`------------------------------------------------------------*/
  yynewstate:
    /* In all cases, when you get here, the value and location stacks
	  have just been pushed. so pushing a state here evens the stacks.
	  */
    yyssp++;

  yysetstate:
    *yyssp = yystate;

    if (yyss + yystacksize - 1 <= yyssp) {
	 /* Get the current used size of the three stacks, in elements.  */
	 const YYSIZE_T yysize = yyssp - yyss + 1;

	 /* Extend the stack our own way.  */
	 if (YYMAXDEPTH <= yystacksize)
	       goto yyoverflowlab;
	 yystacksize *= 2;
	 if (YYMAXDEPTH < yystacksize)
	       yystacksize = YYMAXDEPTH;

	 SvGROW(yyss_sv, yystacksize * sizeof(short));
	 SvGROW(yyvs_sv, yystacksize * sizeof(YYSTYPE));
	 yyss = (short *) SvPVX(yyss_sv);
	 yyvs = (YYSTYPE *) SvPVX(yyvs_sv);
#ifdef DEBUGGING
	 SvGROW(yyns_sv, yystacksize * sizeof(char *));
	 /* XXX This seems strange to cast char * to char ** */
	 yyns = (const char **) SvPVX(yyns_sv);
	 if (! yyns)
	       goto yyoverflowlab;
	 yynsp = yyns + yysize - 1;
#endif
	 if (!yyss || ! yyvs)
	       goto yyoverflowlab;

	 yyssp = yyss + yysize - 1;
	 yyvsp = yyvs + yysize - 1;


	 YYDPRINTF ((Perl_debug_log, "Stack size increased to %lu\n",
				   (unsigned long int) yystacksize));

	 if (yyss + yystacksize - 1 <= yyssp)
	       YYABORT;
    }

    goto yybackup;

  /*-----------.
  | yybackup.  |
  `-----------*/
  yybackup:

/* Do appropriate processing given the current state.  */
/* Read a lookahead token if we need one and don't already have one.  */
/* yyresume: */

    /* First try to decide what to do without reference to lookahead token.  */

    yyn = yypact[yystate];
    if (yyn == YYPACT_NINF)
	goto yydefault;

    /* Not known => get a lookahead token if don't already have one.  */

    /* YYCHAR is either YYEMPTY or YYEOF or a valid lookahead symbol.  */
    if (yychar == YYEMPTY) {
	YYDPRINTF ((Perl_debug_log, "Reading a token: "));
#ifdef PERL_IN_MADLY_C
	yychar = PL_madskills ? madlex() : yylex();
#else
	yychar = yylex();
#endif

#  ifdef EBCDIC
	if (yychar >= 0 && yychar < 255) {
	    yychar = NATIVE_TO_ASCII(yychar);
	}
#  endif
    }

    if (yychar <= YYEOF) {
	yychar = yytoken = YYEOF;
	YYDPRINTF ((Perl_debug_log, "Now at end of input.\n"));
    }
    else {
	yytoken = YYTRANSLATE (yychar);
	YYDSYMPRINTF ("Next token is", yytoken, &yylval);
    }

    /* If the proper action on seeing token YYTOKEN is to reduce or to
	  detect an error, take that action.  */
    yyn += yytoken;
    if (yyn < 0 || YYLAST < yyn || yycheck[yyn] != yytoken)
	goto yydefault;
    yyn = yytable[yyn];
    if (yyn <= 0) {
	if (yyn == 0 || yyn == YYTABLE_NINF)
	    goto yyerrlab;
	yyn = -yyn;
	goto yyreduce;
    }

    if (yyn == YYFINAL)
	YYACCEPT;

    /* Shift the lookahead token.  */
    YYDPRINTF ((Perl_debug_log, "Shifting token %s, ", yytname[yytoken]));

    /* Discard the token being shifted unless it is eof.  */
    if (yychar != YYEOF)
	yychar = YYEMPTY;

    *++yyvsp = yylval;
#ifdef DEBUGGING
    *++yynsp = (const char *)(yytname[yytoken]);
#endif


    /* Count tokens shifted since error; after three, turn off error
	  status.  */
    if (yyerrstatus)
	yyerrstatus--;

    yystate = yyn;
    YYDPRINTF ((Perl_debug_log, "Entering state %d\n", yystate));

    goto yynewstate;


  /*-----------------------------------------------------------.
  | yydefault -- do the default action for the current state.  |
  `-----------------------------------------------------------*/
  yydefault:
    yyn = yydefact[yystate];
    if (yyn == 0)
	goto yyerrlab;
    goto yyreduce;


  /*-----------------------------.
  | yyreduce -- Do a reduction.  |
  `-----------------------------*/
  yyreduce:
    /* yyn is the number of a rule to reduce with.  */
    yylen = yyr2[yyn];

    /* If YYLEN is nonzero, implement the default value of the action:
      "$$ = $1".

      Otherwise, the following line sets YYVAL to garbage.
      This behavior is undocumented and Bison
      users should not rely upon it.  Assigning to YYVAL
      unconditionally makes the parser a bit smaller, and it avoids a
      GCC warning that YYVAL may be used uninitialized.  */
    yyval = yyvsp[1-yylen];


    YY_REDUCE_PRINT (yyn);
    switch (yyn) {


#define dep() deprecate("\"do\" to call subroutines")

#ifdef PERL_IN_MADLY_C
#  define IVAL(i) (i)->tk_lval.ival
#  define PVAL(p) (p)->tk_lval.pval
#  define TOKEN_GETMAD(a,b,c) token_getmad((a),(b),(c))
#  define TOKEN_FREE(a) token_free(a)
#  define OP_GETMAD(a,b,c) op_getmad((a),(b),(c))
#  define IF_MAD(a,b) (a)
#  define DO_MAD(a) a
#  define MAD
#else
#  define IVAL(i) (i)
#  define PVAL(p) (p)
#  define TOKEN_GETMAD(a,b,c)
#  define TOKEN_FREE(a)
#  define OP_GETMAD(a,b,c)
#  define IF_MAD(a,b) (b)
#  define DO_MAD(a)
#  undef MAD
#endif

/* contains all the rule actions; auto-generated from perly.y */
#include "perly.act"

    }

    yyvsp -= yylen;
    yyssp -= yylen;
#ifdef DEBUGGING
    yynsp -= yylen;
#endif


    *++yyvsp = yyval;
    comppad = PL_comppad;

#ifdef DEBUGGING
    *++yynsp = (const char *)(yytname [yyr1[yyn]]);
#endif

    /* Now shift the result of the reduction.  Determine what state
	  that goes to, based on the state we popped back to and the rule
	  number reduced by.  */

    yyn = yyr1[yyn];

    yystate = yypgoto[yyn - YYNTOKENS] + *yyssp;
    if (0 <= yystate && yystate <= YYLAST && yycheck[yystate] == *yyssp)
	yystate = yytable[yystate];
    else
	yystate = yydefgoto[yyn - YYNTOKENS];

    YYDPRINTF ((Perl_debug_log, "Entering state %d\n", yystate));

#ifdef DEBUGGING
    /* tmp push yystate for stack print; this is normally pushed later in
     * yynewstate */
    yyssp++;
    *yyssp = yystate;
    YY_STACK_PRINT (yyss, yyssp, yyvs, yyns);
    yyssp--;
#endif

    goto yynewstate;


  /*------------------------------------.
  | yyerrlab -- here on detecting error |
  `------------------------------------*/
  yyerrlab:
    /* If not already recovering from an error, report this error.  */
    if (!yyerrstatus) {
	++yynerrs;
#if YYERROR_VERBOSE
	yyn = yypact[yystate];

	if (YYPACT_NINF < yyn && yyn < YYLAST) {
	    YYSIZE_T yysize = 0;
	    const int yytype = YYTRANSLATE (yychar);
	    char *yymsg;
	    int yyx, yycount;

	    yycount = 0;
	    /* Start YYX at -YYN if negative to avoid negative indexes in
		  YYCHECK.  */
	    for (yyx = yyn < 0 ? -yyn : 0;
		      yyx < (int) (sizeof (yytname) / sizeof (char *)); yyx++)
		if (yycheck[yyx + yyn] == yyx && yyx != YYTERROR)
		    yysize += yystrlen (yytname[yyx]) + 15, yycount++;
	    yysize += yystrlen ("syntax error, unexpected ") + 1;
	    yysize += yystrlen (yytname[yytype]);
	    Newx(yymsg, yysize, char *);
	    if (yymsg != 0) {
		const char *yyp = yystpcpy (yymsg, "syntax error, unexpected ");
		yyp = yystpcpy (yyp, yytname[yytype]);

		if (yycount < 5) {
		    yycount = 0;
		    for (yyx = yyn < 0 ? -yyn : 0;
			      yyx < (int) (sizeof (yytname) / sizeof (char *));
			      yyx++)
		    {
			if (yycheck[yyx + yyn] == yyx && yyx != YYTERROR) {
			    const char *yyq = ! yycount ?
						    ", expecting " : " or ";
			    yyp = yystpcpy (yyp, yyq);
			    yyp = yystpcpy (yyp, yytname[yyx]);
			    yycount++;
			}
		    }
		}
		yyerror (yymsg);
		YYSTACK_FREE (yymsg);
	    }
	    else
		yyerror ("syntax error; also virtual memory exhausted");
	}
	else
#endif /* YYERROR_VERBOSE */
	    yyerror ("syntax error");
    }


    if (yyerrstatus == 3) {
	/* If just tried and failed to reuse lookahead token after an
	      error, discard it.  */

	/* Return failure if at end of input.  */
	if (yychar == YYEOF) {
	    /* Pop the error token.  */
	    YYPOPSTACK;
	    /* Pop the rest of the stack.  */
	    PAD_RESTORE_LOCAL(comppad);
	    while (yyss < yyssp) {
		YYDSYMPRINTF ("Error: popping", yystos[*yyssp], yyvsp);
		if (yy_type_tab[yystos[*yyssp]] == toketype_padval) {
		    comppad = yyvsp->padval;
		    PAD_RESTORE_LOCAL(comppad);
		}
		else if (yy_type_tab[yystos[*yyssp]] == toketype_opval) {
		    YYDPRINTF ((Perl_debug_log, "(freeing op)\n"));
		    op_free(yyvsp->opval);
		}
		YYPOPSTACK;
	    }
	    YYABORT;
	}

	YYDSYMPRINTF ("Error: discarding", yytoken, &yylval);
	yychar = YYEMPTY;

    }

    /* Else will try to reuse lookahead token after shifting the error
	  token.  */
    goto yyerrlab1;


  /*----------------------------------------------------.
  | yyerrlab1 -- error raised explicitly by an action.  |
  `----------------------------------------------------*/
  yyerrlab1:
    yyerrstatus = 3;	/* Each real token shifted decrements this.  */

    PAD_RESTORE_LOCAL(comppad);
    for (;;) {
	yyn = yypact[yystate];
	if (yyn != YYPACT_NINF) {
	    yyn += YYTERROR;
	    if (0 <= yyn && yyn <= YYLAST && yycheck[yyn] == YYTERROR) {
		yyn = yytable[yyn];
		if (0 < yyn)
		    break;
	    }
	}

	/* Pop the current state because it cannot handle the error token.  */
	if (yyssp == yyss)
	    YYABORT;

	YYDSYMPRINTF ("Error: popping", yystos[*yyssp], yyvsp);
	if (yy_type_tab[yystos[*yyssp]] == toketype_padval) {
	    comppad = yyvsp->padval;
	    PAD_RESTORE_LOCAL(comppad);
	}
	else if (yy_type_tab[yystos[*yyssp]] == toketype_opval) {
	    YYDPRINTF ((Perl_debug_log, "(freeing op)\n"));
	    op_free(yyvsp->opval);
	}
	yyvsp--;
#ifdef DEBUGGING
	yynsp--;
#endif
	yystate = *--yyssp;

	YY_STACK_PRINT (yyss, yyssp, yyvs, yyns);
    }

    if (yyn == YYFINAL)
	YYACCEPT;

    YYDPRINTF ((Perl_debug_log, "Shifting error token, "));

    *++yyvsp = yylval;
#ifdef DEBUGGING
    *++yynsp ="<err>";
#endif

    yystate = yyn;
    YYDPRINTF ((Perl_debug_log, "Entering state %d\n", yystate));

    goto yynewstate;


  /*-------------------------------------.
  | yyacceptlab -- YYACCEPT comes here.  |
  `-------------------------------------*/
  yyacceptlab:
    yyresult = 0;
    goto yyreturn;

  /*-----------------------------------.
  | yyabortlab -- YYABORT comes here.  |
  `-----------------------------------*/
  yyabortlab:
    yyresult = 1;
    goto yyreturn;

  /*----------------------------------------------.
  | yyoverflowlab -- parser overflow comes here.  |
  `----------------------------------------------*/
  yyoverflowlab:
    yyerror ("parser stack overflow");
    yyresult = 2;
    /* Fall through.  */

  yyreturn:

    LEAVE;			/* force stack free before we return */

    return yyresult;
}

/*
 * Local variables:
 * c-indentation-style: bsd
 * c-basic-offset: 4
 * indent-tabs-mode: t
 * End:
 *
 * ex: set ts=8 sts=4 sw=4 noet:
 */
