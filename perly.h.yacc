
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
# define PRIVATEREF 261
# define LABEL 262
# define FORMAT 263
# define SUB 264
# define PACKAGE 265
# define WHILE 266
# define UNTIL 267
# define IF 268
# define UNLESS 269
# define ELSE 270
# define ELSIF 271
# define CONTINUE 272
# define FOR 273
# define LOOPEX 274
# define DOTDOT 275
# define FUNC0 276
# define FUNC1 277
# define FUNC 278
# define RELOP 279
# define EQOP 280
# define MULOP 281
# define ADDOP 282
# define DOLSHARP 283
# define DO 284
# define LOCAL 285
# define DELETE 286
# define HASHBRACK 287
# define LSTOP 288
# define OROR 289
# define ANDAND 290
# define BITOROP 291
# define BITANDOP 292
# define UNIOP 293
# define SHIFTOP 294
# define MATCHOP 295
# define ARROW 296
# define UMINUS 297
# define REFGEN 298
# define POWOP 299
# define PREINC 300
# define PREDEC 301
# define POSTINC 302
# define POSTDEC 303
extern YYSTYPE yylval;
