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
     GRAMFULLSTMT = 260,
     GRAMSTMTSEQ = 261,
     WORD = 262,
     METHOD = 263,
     FUNCMETH = 264,
     THING = 265,
     PMFUNC = 266,
     PRIVATEREF = 267,
     QWLIST = 268,
     FUNC0SUB = 269,
     UNIOPSUB = 270,
     LSTOPSUB = 271,
     PLUGEXPR = 272,
     PLUGSTMT = 273,
     LABEL = 274,
     FORMAT = 275,
     SUB = 276,
     ANONSUB = 277,
     PACKAGE = 278,
     USE = 279,
     WHILE = 280,
     UNTIL = 281,
     IF = 282,
     UNLESS = 283,
     ELSE = 284,
     ELSIF = 285,
     CONTINUE = 286,
     FOR = 287,
     GIVEN = 288,
     WHEN = 289,
     DEFAULT = 290,
     LOOPEX = 291,
     DOTDOT = 292,
     YADAYADA = 293,
     FUNC0 = 294,
     FUNC1 = 295,
     FUNC = 296,
     UNIOP = 297,
     LSTOP = 298,
     RELOP = 299,
     EQOP = 300,
     MULOP = 301,
     ADDOP = 302,
     DOLSHARP = 303,
     DO = 304,
     HASHBRACK = 305,
     NOAMP = 306,
     LOCAL = 307,
     MY = 308,
     MYSUB = 309,
     REQUIRE = 310,
     COLONATTR = 311,
     PREC_LOW = 312,
     DOROP = 313,
     OROP = 314,
     ANDOP = 315,
     NOTOP = 316,
     ASSIGNOP = 317,
     DORDOR = 318,
     OROR = 319,
     ANDAND = 320,
     BITOROP = 321,
     BITANDOP = 322,
     SHIFTOP = 323,
     MATCHOP = 324,
     REFGEN = 325,
     UMINUS = 326,
     POWOP = 327,
     POSTDEC = 328,
     POSTINC = 329,
     PREDEC = 330,
     PREINC = 331,
     ARROW = 332,
     PEG = 333
   };
#endif
/* Tokens.  */
#define GRAMPROG 258
#define GRAMBLOCK 259
#define GRAMFULLSTMT 260
#define GRAMSTMTSEQ 261
#define WORD 262
#define METHOD 263
#define FUNCMETH 264
#define THING 265
#define PMFUNC 266
#define PRIVATEREF 267
#define QWLIST 268
#define FUNC0SUB 269
#define UNIOPSUB 270
#define LSTOPSUB 271
#define PLUGEXPR 272
#define PLUGSTMT 273
#define LABEL 274
#define FORMAT 275
#define SUB 276
#define ANONSUB 277
#define PACKAGE 278
#define USE 279
#define WHILE 280
#define UNTIL 281
#define IF 282
#define UNLESS 283
#define ELSE 284
#define ELSIF 285
#define CONTINUE 286
#define FOR 287
#define GIVEN 288
#define WHEN 289
#define DEFAULT 290
#define LOOPEX 291
#define DOTDOT 292
#define YADAYADA 293
#define FUNC0 294
#define FUNC1 295
#define FUNC 296
#define UNIOP 297
#define LSTOP 298
#define RELOP 299
#define EQOP 300
#define MULOP 301
#define ADDOP 302
#define DOLSHARP 303
#define DO 304
#define HASHBRACK 305
#define NOAMP 306
#define LOCAL 307
#define MY 308
#define MYSUB 309
#define REQUIRE 310
#define COLONATTR 311
#define PREC_LOW 312
#define DOROP 313
#define OROP 314
#define ANDOP 315
#define NOTOP 316
#define ASSIGNOP 317
#define DORDOR 318
#define OROR 319
#define ANDAND 320
#define BITOROP 321
#define BITANDOP 322
#define SHIFTOP 323
#define MATCHOP 324
#define REFGEN 325
#define UMINUS 326
#define POWOP 327
#define POSTDEC 328
#define POSTINC 329
#define PREDEC 330
#define PREINC 331
#define ARROW 332
#define PEG 333




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



