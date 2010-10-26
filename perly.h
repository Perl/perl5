#ifdef PERL_CORE
/* A Bison parser, made by GNU Bison 2.3.  */

/* Skeleton interface for Bison's Yacc-like parsers in C

   Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002, 2003, 2004, 2005, 2006
   Free Software Foundation, Inc.

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

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     GRAMPROG = 258,
     GRAMBLOCK = 259,
     GRAMBARESTMT = 260,
     GRAMFULLSTMT = 261,
     GRAMSTMTSEQ = 262,
     WORD = 263,
     METHOD = 264,
     FUNCMETH = 265,
     THING = 266,
     PMFUNC = 267,
     PRIVATEREF = 268,
     QWLIST = 269,
     FUNC0SUB = 270,
     UNIOPSUB = 271,
     LSTOPSUB = 272,
     PLUGEXPR = 273,
     PLUGSTMT = 274,
     LABEL = 275,
     FORMAT = 276,
     SUB = 277,
     ANONSUB = 278,
     PACKAGE = 279,
     USE = 280,
     WHILE = 281,
     UNTIL = 282,
     IF = 283,
     UNLESS = 284,
     ELSE = 285,
     ELSIF = 286,
     CONTINUE = 287,
     FOR = 288,
     GIVEN = 289,
     WHEN = 290,
     DEFAULT = 291,
     LOOPEX = 292,
     DOTDOT = 293,
     YADAYADA = 294,
     FUNC0 = 295,
     FUNC1 = 296,
     FUNC = 297,
     UNIOP = 298,
     LSTOP = 299,
     RELOP = 300,
     EQOP = 301,
     MULOP = 302,
     ADDOP = 303,
     DOLSHARP = 304,
     DO = 305,
     HASHBRACK = 306,
     NOAMP = 307,
     LOCAL = 308,
     MY = 309,
     MYSUB = 310,
     REQUIRE = 311,
     COLONATTR = 312,
     PREC_LOW = 313,
     DOROP = 314,
     OROP = 315,
     ANDOP = 316,
     NOTOP = 317,
     ASSIGNOP = 318,
     DORDOR = 319,
     OROR = 320,
     ANDAND = 321,
     BITOROP = 322,
     BITANDOP = 323,
     SHIFTOP = 324,
     MATCHOP = 325,
     REFGEN = 326,
     UMINUS = 327,
     POWOP = 328,
     POSTDEC = 329,
     POSTINC = 330,
     PREDEC = 331,
     PREINC = 332,
     ARROW = 333,
     PEG = 334
   };
#endif
/* Tokens.  */
#define GRAMPROG 258
#define GRAMBLOCK 259
#define GRAMBARESTMT 260
#define GRAMFULLSTMT 261
#define GRAMSTMTSEQ 262
#define WORD 263
#define METHOD 264
#define FUNCMETH 265
#define THING 266
#define PMFUNC 267
#define PRIVATEREF 268
#define QWLIST 269
#define FUNC0SUB 270
#define UNIOPSUB 271
#define LSTOPSUB 272
#define PLUGEXPR 273
#define PLUGSTMT 274
#define LABEL 275
#define FORMAT 276
#define SUB 277
#define ANONSUB 278
#define PACKAGE 279
#define USE 280
#define WHILE 281
#define UNTIL 282
#define IF 283
#define UNLESS 284
#define ELSE 285
#define ELSIF 286
#define CONTINUE 287
#define FOR 288
#define GIVEN 289
#define WHEN 290
#define DEFAULT 291
#define LOOPEX 292
#define DOTDOT 293
#define YADAYADA 294
#define FUNC0 295
#define FUNC1 296
#define FUNC 297
#define UNIOP 298
#define LSTOP 299
#define RELOP 300
#define EQOP 301
#define MULOP 302
#define ADDOP 303
#define DOLSHARP 304
#define DO 305
#define HASHBRACK 306
#define NOAMP 307
#define LOCAL 308
#define MY 309
#define MYSUB 310
#define REQUIRE 311
#define COLONATTR 312
#define PREC_LOW 313
#define DOROP 314
#define OROP 315
#define ANDOP 316
#define NOTOP 317
#define ASSIGNOP 318
#define DORDOR 319
#define OROR 320
#define ANDAND 321
#define BITOROP 322
#define BITANDOP 323
#define SHIFTOP 324
#define MATCHOP 325
#define REFGEN 326
#define UMINUS 327
#define POWOP 328
#define POSTDEC 329
#define POSTINC 330
#define PREDEC 331
#define PREINC 332
#define ARROW 333
#define PEG 334




#endif /* PERL_CORE */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef union YYSTYPE
{
    I32	ival; /* __DEFAULT__ (marker for regen_perly.pl;
				must always be 1st union member) */
    char *pval;
    OP *opval;
    GV *gvval;
#ifdef PERL_IN_MADLY_C
    TOKEN* p_tkval;
    TOKEN* i_tkval;
#else
    char *p_tkval;
    I32	i_tkval;
#endif
#ifdef PERL_MAD
    TOKEN* tkval;
#endif
}
/* Line 1529 of yacc.c.  */
	YYSTYPE;
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif



