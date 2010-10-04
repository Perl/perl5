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
     GRAMFULLSTMT = 259,
     GRAMSTMTSEQ = 260,
     WORD = 261,
     METHOD = 262,
     FUNCMETH = 263,
     THING = 264,
     PMFUNC = 265,
     PRIVATEREF = 266,
     QWLIST = 267,
     FUNC0SUB = 268,
     UNIOPSUB = 269,
     LSTOPSUB = 270,
     PLUGEXPR = 271,
     PLUGSTMT = 272,
     LABEL = 273,
     FORMAT = 274,
     SUB = 275,
     ANONSUB = 276,
     PACKAGE = 277,
     USE = 278,
     WHILE = 279,
     UNTIL = 280,
     IF = 281,
     UNLESS = 282,
     ELSE = 283,
     ELSIF = 284,
     CONTINUE = 285,
     FOR = 286,
     GIVEN = 287,
     WHEN = 288,
     DEFAULT = 289,
     LOOPEX = 290,
     DOTDOT = 291,
     YADAYADA = 292,
     FUNC0 = 293,
     FUNC1 = 294,
     FUNC = 295,
     UNIOP = 296,
     LSTOP = 297,
     RELOP = 298,
     EQOP = 299,
     MULOP = 300,
     ADDOP = 301,
     DOLSHARP = 302,
     DO = 303,
     HASHBRACK = 304,
     NOAMP = 305,
     LOCAL = 306,
     MY = 307,
     MYSUB = 308,
     REQUIRE = 309,
     COLONATTR = 310,
     PREC_LOW = 311,
     DOROP = 312,
     OROP = 313,
     ANDOP = 314,
     NOTOP = 315,
     ASSIGNOP = 316,
     DORDOR = 317,
     OROR = 318,
     ANDAND = 319,
     BITOROP = 320,
     BITANDOP = 321,
     SHIFTOP = 322,
     MATCHOP = 323,
     REFGEN = 324,
     UMINUS = 325,
     POWOP = 326,
     POSTDEC = 327,
     POSTINC = 328,
     PREDEC = 329,
     PREINC = 330,
     ARROW = 331,
     PEG = 332
   };
#endif
/* Tokens.  */
#define GRAMPROG 258
#define GRAMFULLSTMT 259
#define GRAMSTMTSEQ 260
#define WORD 261
#define METHOD 262
#define FUNCMETH 263
#define THING 264
#define PMFUNC 265
#define PRIVATEREF 266
#define QWLIST 267
#define FUNC0SUB 268
#define UNIOPSUB 269
#define LSTOPSUB 270
#define PLUGEXPR 271
#define PLUGSTMT 272
#define LABEL 273
#define FORMAT 274
#define SUB 275
#define ANONSUB 276
#define PACKAGE 277
#define USE 278
#define WHILE 279
#define UNTIL 280
#define IF 281
#define UNLESS 282
#define ELSE 283
#define ELSIF 284
#define CONTINUE 285
#define FOR 286
#define GIVEN 287
#define WHEN 288
#define DEFAULT 289
#define LOOPEX 290
#define DOTDOT 291
#define YADAYADA 292
#define FUNC0 293
#define FUNC1 294
#define FUNC 295
#define UNIOP 296
#define LSTOP 297
#define RELOP 298
#define EQOP 299
#define MULOP 300
#define ADDOP 301
#define DOLSHARP 302
#define DO 303
#define HASHBRACK 304
#define NOAMP 305
#define LOCAL 306
#define MY 307
#define MYSUB 308
#define REQUIRE 309
#define COLONATTR 310
#define PREC_LOW 311
#define DOROP 312
#define OROP 313
#define ANDOP 314
#define NOTOP 315
#define ASSIGNOP 316
#define DORDOR 317
#define OROR 318
#define ANDAND 319
#define BITOROP 320
#define BITANDOP 321
#define SHIFTOP 322
#define MATCHOP 323
#define REFGEN 324
#define UMINUS 325
#define POWOP 326
#define POSTDEC 327
#define POSTINC 328
#define PREDEC 329
#define PREINC 330
#define ARROW 331
#define PEG 332




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
/* Line 1489 of yacc.c.  */
	YYSTYPE;
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif



