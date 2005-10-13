#ifdef PERL_CORE
/* A Bison parser, made by GNU Bison 2.1.  */

/* Skeleton parser for Yacc-like parsing with Bison,
   Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002, 2003, 2004, 2005 Free Software Foundation, Inc.

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
   Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.  */

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
     REQUIRE = 299,
     COLONATTR = 300,
     PREC_LOW = 301,
     DOROP = 302,
     OROP = 303,
     ANDOP = 304,
     NOTOP = 305,
     ASSIGNOP = 306,
     DORDOR = 307,
     OROR = 308,
     ANDAND = 309,
     BITOROP = 310,
     BITANDOP = 311,
     SHIFTOP = 312,
     MATCHOP = 313,
     REFGEN = 314,
     UMINUS = 315,
     POWOP = 316,
     POSTDEC = 317,
     POSTINC = 318,
     PREDEC = 319,
     PREINC = 320,
     ARROW = 321
   };
#endif
/* Tokens.  */
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
#define REQUIRE 299
#define COLONATTR 300
#define PREC_LOW 301
#define DOROP 302
#define OROP 303
#define ANDOP 304
#define NOTOP 305
#define ASSIGNOP 306
#define DORDOR 307
#define OROR 308
#define ANDAND 309
#define BITOROP 310
#define BITANDOP 311
#define SHIFTOP 312
#define MATCHOP 313
#define REFGEN 314
#define UMINUS 315
#define POWOP 316
#define POSTDEC 317
#define POSTINC 318
#define PREDEC 319
#define PREINC 320
#define ARROW 321




#endif /* PERL_CORE */
#if ! defined (YYSTYPE) && ! defined (YYSTYPE_IS_DECLARED)
#line 30 "perly.y"
typedef union YYSTYPE {
    I32	ival;
    char *pval;
    OP *opval;
    GV *gvval;
} YYSTYPE;
/* Line 1447 of yacc.c.  */
#line 177 "perly.h"
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif





