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
     WORD = 260,
     METHOD = 261,
     FUNCMETH = 262,
     THING = 263,
     PMFUNC = 264,
     PRIVATEREF = 265,
     FUNC0SUB = 266,
     UNIOPSUB = 267,
     LSTOPSUB = 268,
     PLUGEXPR = 269,
     PLUGSTMT = 270,
     LABEL = 271,
     FORMAT = 272,
     SUB = 273,
     ANONSUB = 274,
     PACKAGE = 275,
     USE = 276,
     WHILE = 277,
     UNTIL = 278,
     IF = 279,
     UNLESS = 280,
     ELSE = 281,
     ELSIF = 282,
     CONTINUE = 283,
     FOR = 284,
     GIVEN = 285,
     WHEN = 286,
     DEFAULT = 287,
     LOOPEX = 288,
     DOTDOT = 289,
     YADAYADA = 290,
     FUNC0 = 291,
     FUNC1 = 292,
     FUNC = 293,
     UNIOP = 294,
     LSTOP = 295,
     RELOP = 296,
     EQOP = 297,
     MULOP = 298,
     ADDOP = 299,
     DOLSHARP = 300,
     DO = 301,
     HASHBRACK = 302,
     NOAMP = 303,
     LOCAL = 304,
     MY = 305,
     MYSUB = 306,
     REQUIRE = 307,
     COLONATTR = 308,
     PREC_LOW = 309,
     DOROP = 310,
     OROP = 311,
     ANDOP = 312,
     NOTOP = 313,
     ASSIGNOP = 314,
     DORDOR = 315,
     OROR = 316,
     ANDAND = 317,
     BITOROP = 318,
     BITANDOP = 319,
     SHIFTOP = 320,
     MATCHOP = 321,
     REFGEN = 322,
     UMINUS = 323,
     POWOP = 324,
     POSTDEC = 325,
     POSTINC = 326,
     PREDEC = 327,
     PREINC = 328,
     ARROW = 329,
     PEG = 330
   };
#endif
/* Tokens.  */
#define GRAMPROG 258
#define GRAMFULLSTMT 259
#define WORD 260
#define METHOD 261
#define FUNCMETH 262
#define THING 263
#define PMFUNC 264
#define PRIVATEREF 265
#define FUNC0SUB 266
#define UNIOPSUB 267
#define LSTOPSUB 268
#define PLUGEXPR 269
#define PLUGSTMT 270
#define LABEL 271
#define FORMAT 272
#define SUB 273
#define ANONSUB 274
#define PACKAGE 275
#define USE 276
#define WHILE 277
#define UNTIL 278
#define IF 279
#define UNLESS 280
#define ELSE 281
#define ELSIF 282
#define CONTINUE 283
#define FOR 284
#define GIVEN 285
#define WHEN 286
#define DEFAULT 287
#define LOOPEX 288
#define DOTDOT 289
#define YADAYADA 290
#define FUNC0 291
#define FUNC1 292
#define FUNC 293
#define UNIOP 294
#define LSTOP 295
#define RELOP 296
#define EQOP 297
#define MULOP 298
#define ADDOP 299
#define DOLSHARP 300
#define DO 301
#define HASHBRACK 302
#define NOAMP 303
#define LOCAL 304
#define MY 305
#define MYSUB 306
#define REQUIRE 307
#define COLONATTR 308
#define PREC_LOW 309
#define DOROP 310
#define OROP 311
#define ANDOP 312
#define NOTOP 313
#define ASSIGNOP 314
#define DORDOR 315
#define OROR 316
#define ANDAND 317
#define BITOROP 318
#define BITANDOP 319
#define SHIFTOP 320
#define MATCHOP 321
#define REFGEN 322
#define UMINUS 323
#define POWOP 324
#define POSTDEC 325
#define POSTINC 326
#define PREDEC 327
#define PREINC 328
#define ARROW 329
#define PEG 330




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



