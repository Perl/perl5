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
#define OROP 289
#define ANDOP 290
#define LSTOP 291
#define OROR 292
#define ANDAND 293
#define BITOROP 294
#define BITANDOP 295
#define UNIOP 296
#define SHIFTOP 297
#define MATCHOP 298
#define ARROW 299
#define UMINUS 300
#define REFGEN 301
#define POWOP 302
#define PREINC 303
#define PREDEC 304
#define POSTINC 305
#define POSTDEC 306
typedef union {
    I32	ival;
    char *pval;
    OP *opval;
    GV *gvval;
} YYSTYPE;
extern YYSTYPE yylval;
extern YYSTYPE yylval;
