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
     QWLIST = 266,
     FUNC0SUB = 267,
     UNIOPSUB = 268,
     LSTOPSUB = 269,
     PLUGEXPR = 270,
     PLUGSTMT = 271,
     LABEL = 272,
     FORMAT = 273,
     SUB = 274,
     ANONSUB = 275,
     PACKAGE = 276,
     USE = 277,
     WHILE = 278,
     UNTIL = 279,
     IF = 280,
     UNLESS = 281,
     ELSE = 282,
     ELSIF = 283,
     CONTINUE = 284,
     FOR = 285,
     GIVEN = 286,
     WHEN = 287,
     DEFAULT = 288,
     LOOPEX = 289,
     DOTDOT = 290,
     YADAYADA = 291,
     FUNC0 = 292,
     FUNC1 = 293,
     FUNC = 294,
     UNIOP = 295,
     LSTOP = 296,
     RELOP = 297,
     EQOP = 298,
     MULOP = 299,
     ADDOP = 300,
     DOLSHARP = 301,
     DO = 302,
     HASHBRACK = 303,
     NOAMP = 304,
     LOCAL = 305,
     MY = 306,
     MYSUB = 307,
     REQUIRE = 308,
     COLONATTR = 309,
     PREC_LOW = 310,
     DOROP = 311,
     OROP = 312,
     ANDOP = 313,
     NOTOP = 314,
     ASSIGNOP = 315,
     DORDOR = 316,
     OROR = 317,
     ANDAND = 318,
     BITOROP = 319,
     BITANDOP = 320,
     SHIFTOP = 321,
     MATCHOP = 322,
     REFGEN = 323,
     UMINUS = 324,
     POWOP = 325,
     POSTDEC = 326,
     POSTINC = 327,
     PREDEC = 328,
     PREINC = 329,
     ARROW = 330,
     PEG = 331
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
#define QWLIST 266
#define FUNC0SUB 267
#define UNIOPSUB 268
#define LSTOPSUB 269
#define PLUGEXPR 270
#define PLUGSTMT 271
#define LABEL 272
#define FORMAT 273
#define SUB 274
#define ANONSUB 275
#define PACKAGE 276
#define USE 277
#define WHILE 278
#define UNTIL 279
#define IF 280
#define UNLESS 281
#define ELSE 282
#define ELSIF 283
#define CONTINUE 284
#define FOR 285
#define GIVEN 286
#define WHEN 287
#define DEFAULT 288
#define LOOPEX 289
#define DOTDOT 290
#define YADAYADA 291
#define FUNC0 292
#define FUNC1 293
#define FUNC 294
#define UNIOP 295
#define LSTOP 296
#define RELOP 297
#define EQOP 298
#define MULOP 299
#define ADDOP 300
#define DOLSHARP 301
#define DO 302
#define HASHBRACK 303
#define NOAMP 304
#define LOCAL 305
#define MY 306
#define MYSUB 307
#define REQUIRE 308
#define COLONATTR 309
#define PREC_LOW 310
#define DOROP 311
#define OROP 312
#define ANDOP 313
#define NOTOP 314
#define ASSIGNOP 315
#define DORDOR 316
#define OROR 317
#define ANDAND 318
#define BITOROP 319
#define BITANDOP 320
#define SHIFTOP 321
#define MATCHOP 322
#define REFGEN 323
#define UMINUS 324
#define POWOP 325
#define POSTDEC 326
#define POSTINC 327
#define PREDEC 328
#define PREINC 329
#define ARROW 330
#define PEG 331




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



