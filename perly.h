#define WORD 257
#define METHOD 258
#define THING 259
#define PMFUNC 260
#define PRIVATEREF 261
#define LABEL 262
#define FORMAT 263
#define SUB 264
#define PACKAGE 265
#define WHILE 266
#define UNTIL 267
#define IF 268
#define UNLESS 269
#define ELSE 270
#define ELSIF 271
#define CONTINUE 272
#define FOR 273
#define LOOPEX 274
#define DOTDOT 275
#define FUNC0 276
#define FUNC1 277
#define FUNC 278
#define RELOP 279
#define EQOP 280
#define MULOP 281
#define ADDOP 282
#define DOLSHARP 283
#define DO 284
#define LOCAL 285
#define DELETE 286
#define HASHBRACK 287
#define NOAMP 288
#define LSTOP 289
#define OROR 290
#define ANDAND 291
#define BITOROP 292
#define BITANDOP 293
#define UNIOP 294
#define SHIFTOP 295
#define MATCHOP 296
#define ARROW 297
#define UMINUS 298
#define REFGEN 299
#define POWOP 300
#define PREINC 301
#define PREDEC 302
#define POSTINC 303
#define POSTDEC 304
typedef union {
    I32	ival;
    char *pval;
    OP *opval;
    GV *gvval;
} YYSTYPE;
extern YYSTYPE yylval;
extern YYSTYPE yylval;
