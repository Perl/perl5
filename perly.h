#ifdef PERL_CORE
/* A Bison parser, made by GNU Bison 1.875.  */

/* Skeleton parser for Yacc-like parsing with Bison,
   Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002 Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330,
   Boston, MA 02111-1307, USA.  */

/* As a special exception, when this file is copied by Bison into a
   Bison output file, you may use that output file without restriction.
   This special exception was added by the Free Software Foundation
   in version 1.24 of Bison.  */

/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     WORD = 258,
     METHOD = 259,
     FUNCMETH = 260,
     THING = 261,
     PMFUNC = 262,
     PRIVATEREF = 263,
     FUNC0SUB = 264,
     UNIOPSUB = 265,
     LSTOPSUB = 266,
     LABEL = 267,
     FORMAT = 268,
     SUB = 269,
     ANONSUB = 270,
     PACKAGE = 271,
     USE = 272,
     WHILE = 273,
     UNTIL = 274,
     IF = 275,
     UNLESS = 276,
     ELSE = 277,
     ELSIF = 278,
     CONTINUE = 279,
     FOR = 280,
     LOOPEX = 281,
     DOTDOT = 282,
     FUNC0 = 283,
     FUNC1 = 284,
     FUNC = 285,
     UNIOP = 286,
     LSTOP = 287,
     RELOP = 288,
     EQOP = 289,
     MULOP = 290,
     ADDOP = 291,
     DOLSHARP = 292,
     DO = 293,
     HASHBRACK = 294,
     NOAMP = 295,
     LOCAL = 296,
     MY = 297,
     MYSUB = 298,
     COLONATTR = 299,
     PREC_LOW = 300,
     DOROP = 301,
     OROP = 302,
     ANDOP = 303,
     NOTOP = 304,
     ASSIGNOP = 305,
     DORDOR = 306,
     OROR = 307,
     ANDAND = 308,
     BITOROP = 309,
     BITANDOP = 310,
     SHIFTOP = 311,
     MATCHOP = 312,
     REFGEN = 313,
     UMINUS = 314,
     POWOP = 315,
     POSTDEC = 316,
     POSTINC = 317,
     PREDEC = 318,
     PREINC = 319,
     ARROW = 320
   };
#endif
#define WORD 258
#define METHOD 259
#define FUNCMETH 260
#define THING 261
#define PMFUNC 262
#define PRIVATEREF 263
#define FUNC0SUB 264
#define UNIOPSUB 265
#define LSTOPSUB 266
#define LABEL 267
#define FORMAT 268
#define SUB 269
#define ANONSUB 270
#define PACKAGE 271
#define USE 272
#define WHILE 273
#define UNTIL 274
#define IF 275
#define UNLESS 276
#define ELSE 277
#define ELSIF 278
#define CONTINUE 279
#define FOR 280
#define LOOPEX 281
#define DOTDOT 282
#define FUNC0 283
#define FUNC1 284
#define FUNC 285
#define UNIOP 286
#define LSTOP 287
#define RELOP 288
#define EQOP 289
#define MULOP 290
#define ADDOP 291
#define DOLSHARP 292
#define DO 293
#define HASHBRACK 294
#define NOAMP 295
#define LOCAL 296
#define MY 297
#define MYSUB 298
#define COLONATTR 299
#define PREC_LOW 300
#define DOROP 301
#define OROP 302
#define ANDOP 303
#define NOTOP 304
#define ASSIGNOP 305
#define DORDOR 306
#define OROR 307
#define ANDAND 308
#define BITOROP 309
#define BITANDOP 310
#define SHIFTOP 311
#define MATCHOP 312
#define REFGEN 313
#define UMINUS 314
#define POWOP 315
#define POSTDEC 316
#define POSTINC 317
#define PREDEC 318
#define PREINC 319
#define ARROW 320




#endif /* PERL_CORE */
#if ! defined (YYSTYPE) && ! defined (YYSTYPE_IS_DECLARED)
#line 21 "perly.y"
typedef union YYSTYPE {
    I32	ival;
    char *pval;
    OP *opval;
    GV *gvval;
} YYSTYPE;
/* Line 1248 of yacc.c.  */
#line 173 "perly.h"
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif





