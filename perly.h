
typedef union  {
    I32	ival;
    char *pval;
    OP *opval;
    GV *gvval;
} YYSTYPE;
extern YYSTYPE yylval;
# define WORD 257
# define METHOD 258
# define THING 259
# define PMFUNC 260
# define LABEL 261
# define FORMAT 262
# define SUB 263
# define PACKAGE 264
# define WHILE 265
# define UNTIL 266
# define IF 267
# define UNLESS 268
# define ELSE 269
# define ELSIF 270
# define CONTINUE 271
# define FOR 272
# define LOOPEX 273
# define DOTDOT 274
# define FUNC0 275
# define FUNC1 276
# define FUNC 277
# define RELOP 278
# define EQOP 279
# define MULOP 280
# define ADDOP 281
# define DOLSHARP 282
# define DO 283
# define LOCAL 284
# define DELETE 285
# define HASHBRACK 286
# define LSTOP 287
# define OROR 288
# define ANDAND 289
# define BITOROP 290
# define BITANDOP 291
# define UNIOP 292
# define SHIFTOP 293
# define MATCHOP 294
# define ARROW 295
# define UMINUS 296
# define REFGEN 297
# define POWOP 298
# define PREINC 299
# define PREDEC 300
# define POSTINC 301
# define POSTDEC 302
extern YYSTYPE yylval;
