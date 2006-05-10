#ifdef PERL_CORE
#define WORD 257
#define METHOD 258
#define FUNCMETH 259
#define THING 260
#define PMFUNC 261
#define PRIVATEREF 262
#define FUNC0SUB 263
#define UNIOPSUB 264
#define LSTOPSUB 265
#define LABEL 266
#define FORMAT 267
#define SUB 268
#define ANONSUB 269
#define PACKAGE 270
#define USE 271
#define WHILE 272
#define UNTIL 273
#define IF 274
#define UNLESS 275
#define ELSE 276
#define ELSIF 277
#define CONTINUE 278
#define FOR 279
#define LOOPEX 280
#define DOTDOT 281
#define FUNC0 282
#define FUNC1 283
#define FUNC 284
#define UNIOP 285
#define LSTOP 286
#define RELOP 287
#define EQOP 288
#define MULOP 289
#define ADDOP 290
#define DOLSHARP 291
#define DO 292
#define HASHBRACK 293
#define NOAMP 294
#define LOCAL 295
#define MY 296
#define MYSUB 297
#define REQUIRE 298
#define COLONATTR 299
#define PREC_LOW 300
#define OROP 301
#define ANDOP 302
#define NOTOP 303
#define ASSIGNOP 304
#define OROR 305
#define ANDAND 306
#define BITOROP 307
#define BITANDOP 308
#define SHIFTOP 309
#define MATCHOP 310
#define UMINUS 311
#define REFGEN 312
#define POWOP 313
#define PREINC 314
#define PREDEC 315
#define POSTINC 316
#define POSTDEC 317
#define ARROW 318
#endif /* PERL_CORE */

typedef union {
    I32	ival;
    char *pval;
    OP *opval;
    GV *gvval;
} YYSTYPE;
