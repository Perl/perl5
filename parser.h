/*    parser.h
 *
 *    Copyright (c) 2006 Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 * 
 * This file defines the layout of the parser object used by the parser
 * and lexer (perly.c, toke,c).
 */

typedef struct {
    YYSTYPE val;    /* semantic value */
    short   state;
    AV	    *comppad; /* value of PL_comppad when this value was created */
#ifdef DEBUGGING
    const char  *name; /* token/rule name for -Dpv */
#endif
} yy_stack_frame;

typedef struct {
    int		    yychar;	/* The lookahead symbol.  */
    YYSTYPE	    yylval;	/* value of lookahead symbol, set by yylex() */

    /* Number of tokens to shift before error messages enabled.  */
    int		    yyerrstatus;

    int		    stack_size;
    int		    yylen;	/* length of active reduction */
    yy_stack_frame  *ps;	/* current stack frame */
    yy_stack_frame  stack[1];	/* will actually be as many as needed */
} yy_parser;
    

