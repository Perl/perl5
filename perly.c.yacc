extern char *malloc(), *realloc();

# line 39 "perly.y"
#include "EXTERN.h"
#include "perl.h"

/*SUPPRESS 530*/
/*SUPPRESS 593*/
/*SUPPRESS 595*/


# line 50 "perly.y"
typedef union  {
    I32	ival;
    char *pval;
    OP *opval;
    GV *gvval;
} YYSTYPE;
# define WORD 257
# define METHOD 258
# define THING 259
# define PMFUNC 260
# define PRIVATEREF 261
# define LABEL 262
# define FORMAT 263
# define SUB 264
# define PACKAGE 265
# define WHILE 266
# define UNTIL 267
# define IF 268
# define UNLESS 269
# define ELSE 270
# define ELSIF 271
# define CONTINUE 272
# define FOR 273
# define LOOPEX 274
# define DOTDOT 275
# define FUNC0 276
# define FUNC1 277
# define FUNC 278
# define RELOP 279
# define EQOP 280
# define MULOP 281
# define ADDOP 282
# define DOLSHARP 283
# define DO 284
# define LOCAL 285
# define DELETE 286
# define HASHBRACK 287
# define LSTOP 288
# define OROR 289
# define ANDAND 290
# define BITOROP 291
# define BITANDOP 292
# define UNIOP 293
# define SHIFTOP 294
# define MATCHOP 295
# define ARROW 296
# define UMINUS 297
# define REFGEN 298
# define POWOP 299
# define PREINC 300
# define PREDEC 301
# define POSTINC 302
# define POSTDEC 303
#define yyclearin yychar = -1
#define yyerrok yyerrflag = 0
extern int yychar;
extern int yyerrflag;
#ifndef YYMAXDEPTH
#define YYMAXDEPTH 150
#endif
YYSTYPE yylval, yyval;
# define YYERRCODE 256

# line 573 "perly.y"
 /* PROGRAM */
int yyexca[] ={
-1, 1,
	0, -1,
	-2, 0,
-1, 3,
	0, 2,
	-2, 39,
-1, 21,
	296, 146,
	-2, 25,
-1, 40,
	41, 98,
	266, 98,
	267, 98,
	268, 98,
	269, 98,
	275, 98,
	279, 98,
	280, 98,
	281, 98,
	282, 98,
	44, 98,
	61, 98,
	63, 98,
	58, 98,
	289, 98,
	290, 98,
	291, 98,
	292, 98,
	294, 98,
	295, 98,
	296, 98,
	299, 98,
	302, 98,
	303, 98,
	59, 98,
	93, 98,
	-2, 145,
-1, 54,
	41, 134,
	266, 134,
	267, 134,
	268, 134,
	269, 134,
	275, 134,
	279, 134,
	280, 134,
	281, 134,
	282, 134,
	44, 134,
	61, 134,
	63, 134,
	58, 134,
	289, 134,
	290, 134,
	291, 134,
	292, 134,
	294, 134,
	295, 134,
	296, 134,
	299, 134,
	302, 134,
	303, 134,
	59, 134,
	93, 134,
	-2, 144,
-1, 78,
	59, 35,
	-2, 0,
-1, 114,
	302, 0,
	303, 0,
	-2, 89,
-1, 115,
	302, 0,
	303, 0,
	-2, 90,
-1, 194,
	279, 0,
	-2, 72,
-1, 195,
	280, 0,
	-2, 73,
-1, 196,
	275, 0,
	-2, 76,
-1, 312,
	41, 35,
	-2, 0,
	};
# define YYNPROD 154
# define YYLAST 2319
int yyact[]={

   109,   106,   107,   164,    92,   104,   231,   105,   150,    92,
    21,   241,    68,   106,   107,   152,   230,    80,    25,    74,
    76,   242,   243,    82,    84,    56,    26,    93,    94,   326,
    31,   319,   134,    56,    58,    61,    69,    37,   157,    57,
    30,   104,    29,   317,   300,    92,   117,   119,   121,   131,
   246,   135,   299,    93,    94,    93,    16,   298,    79,   125,
   264,    59,    14,    11,    12,    13,    95,   104,   154,   104,
   155,    92,   212,    92,    71,   159,   123,   161,    83,    81,
    75,   166,   158,   168,   160,   170,    26,   163,    38,   270,
   167,   126,   169,   200,   171,   172,   173,   174,   217,   260,
    73,   205,   222,   312,   239,   156,    31,    89,   124,    56,
    58,    61,    26,    37,    89,    57,    30,     3,    29,    89,
    26,    89,    89,    32,    72,   201,    89,   329,   100,   101,
    93,    94,   213,   214,   215,   216,   327,    59,   220,   100,
   101,    93,    94,    95,   104,   322,    89,   225,    92,    99,
    98,    97,    96,   123,    95,   104,   318,   316,   306,    92,
    67,    26,    26,    26,    38,    89,   280,   233,   297,    31,
   294,   237,    56,    58,    61,   267,    37,   290,    57,    30,
   320,    29,   245,    26,   223,   124,    89,    14,    11,    12,
    13,   100,   101,    93,    94,   265,    26,   282,   256,    32,
    59,   301,    98,    97,    96,   221,    95,   104,   176,   257,
   258,    92,   206,   100,   261,    93,    94,    89,   234,   162,
   236,   151,   100,   101,    93,    94,   269,    38,    95,   104,
   273,   275,   295,    92,   283,    96,   284,    95,   104,   286,
   139,   288,    92,   289,   204,   291,   141,   202,   158,   138,
    66,   137,    89,    24,    54,    65,    46,    53,    66,    26,
   199,   208,    32,    18,    19,    22,    23,   268,   129,   296,
    20,    49,    70,    51,    52,    63,   149,    89,   287,   302,
    60,    48,    36,    45,    39,    62,   310,   209,   325,    56,
    50,    89,   266,   203,     8,    33,     7,    34,    35,   314,
   313,   204,   211,   315,   202,   276,   244,    56,    89,    89,
    31,   128,     2,    56,    58,    61,   324,    37,   274,    57,
    30,    25,    29,     9,   240,   165,   328,    89,   330,    24,
    54,    65,    46,    53,    66,    17,    87,    88,    85,    86,
   331,    59,   308,   309,    56,   311,    55,    49,    78,    51,
    52,    63,   235,    47,    41,    89,    60,    48,    36,    45,
    39,    62,    44,    42,    43,    15,    50,    10,    38,   323,
     5,    33,   210,    34,    35,    31,   207,    90,    56,    58,
    61,     6,    37,   272,    57,    30,     4,    29,     1,   100,
   101,    93,    94,    54,    65,    46,    53,    66,     0,     0,
    26,    97,    96,    32,    95,   104,    59,     0,     0,    92,
    49,     0,    51,    52,    63,     0,     0,     0,    28,    60,
    48,    36,    45,    39,    62,   227,     0,     0,   229,    50,
   232,     0,   152,    38,    33,    31,    34,    35,    56,    58,
    61,     0,    37,     0,    57,    30,     0,    29,   108,   110,
   111,   112,   113,   114,   115,     0,     0,   238,    64,     0,
     0,   263,     0,     0,     0,    26,    59,     0,    32,    87,
    88,    85,    86,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,    31,    38,     0,    56,    58,    61,     0,    37,
     0,    57,    30,     0,    29,   279,     0,   281,     0,     0,
     0,     0,     0,     0,   271,   140,   143,   144,   145,   146,
   147,   148,     0,    59,   153,    26,     0,     0,    32,     0,
     0,   285,     0,   293,    54,    65,    46,    53,    66,     0,
     0,     0,     0,     0,     0,     0,   277,     0,     0,   278,
    38,    49,   262,    51,    52,    63,     0,     0,     0,   307,
    60,    48,    36,    45,    39,    62,    91,   303,   103,   304,
    50,     0,     0,     0,     0,    33,     0,    34,    35,     0,
     0,     0,    26,     0,     0,    32,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,    54,
    65,    46,    53,    66,     0,     0,     0,     0,     0,     0,
   228,     0,     0,     0,     0,     0,    49,     0,    51,    52,
    63,     0,     0,     0,     0,    60,    48,    36,    45,    39,
    62,     0,     0,     0,     0,    50,     0,     0,     0,     0,
    33,    31,    34,    35,    56,    58,    61,    40,    37,   259,
    57,    30,     0,    29,     0,     0,     0,     0,     0,    54,
    65,    46,    53,    66,     0,     0,     0,     0,    77,     0,
     0,     0,    59,     0,     0,     0,    49,     0,    51,    52,
    63,     0,     0,     0,     0,    60,    48,    36,    45,    39,
    62,     0,     0,   127,     0,    50,   133,     0,     0,    38,
    33,     0,    34,    35,   142,   142,   142,   142,   142,   142,
     0,     0,     0,   142,     0,     0,    54,    65,    46,    53,
    66,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,    26,     0,    49,    32,    51,    52,    63,     0,   103,
     0,     0,    60,    48,    36,    45,    39,    62,     0,     0,
     0,     0,    50,     0,     0,     0,     0,    33,    31,    34,
    35,    56,    58,    61,     0,    37,   224,    57,    30,     0,
    29,     0,     0,     0,     0,     0,   218,     0,     0,     0,
   102,     0,     0,     0,   100,   101,    93,    94,     0,    59,
     0,     0,     0,     0,    99,    98,    97,    96,     0,    95,
   104,     0,     0,     0,    92,     0,     0,     0,     0,     0,
     0,     0,     0,     0,    31,     0,    38,    56,    58,    61,
     0,    37,   219,    57,    30,     0,    29,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,    59,     0,     0,    26,     0,
     0,    32,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,    54,    65,    46,    53,    66,
     0,    31,    38,     0,    56,    58,    61,     0,    37,     0,
    57,    30,    49,    29,    51,    52,    63,     0,     0,     0,
     0,    60,    48,    36,    45,    39,    62,     0,     0,   192,
     0,    50,    59,     0,    26,     0,    33,    32,    34,    35,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,    38,
     0,    31,     0,     0,    56,    58,    61,     0,    37,     0,
    57,    30,     0,    29,     0,     0,     0,     0,     0,     0,
     0,   102,     0,     0,   321,   100,   101,    93,    94,   190,
     0,    26,    59,     0,    32,    99,    98,    97,    96,     0,
    95,   104,     0,     0,    91,    92,   103,     0,     0,     0,
     0,     0,    54,    65,    46,    53,    66,     0,     0,    38,
     0,     0,     0,     0,     0,     0,     0,     0,     0,    49,
     0,    51,    52,    63,     0,     0,     0,     0,    60,    48,
    36,    45,    39,    62,     0,     0,     0,   255,    50,     0,
    91,    26,   103,    33,    32,    34,    35,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,    54,    65,
    46,    53,    66,     0,    31,     0,     0,    56,    58,    61,
     0,    37,     0,    57,    30,    49,    29,    51,    52,    63,
     0,     0,     0,     0,    60,    48,    36,    45,    39,    62,
     0,     0,   188,     0,    50,    59,     0,     0,     0,    33,
     0,    34,    35,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,    54,    65,    46,    53,    66,
     0,     0,    38,     0,     0,     0,     0,     0,     0,     0,
     0,     0,    49,     0,    51,    52,    63,    91,     0,   103,
     0,    60,    48,    36,    45,    39,    62,     0,     0,     0,
     0,    50,     0,     0,    26,     0,    33,    32,    34,    35,
     0,     0,    31,     0,     0,    56,    58,    61,     0,    37,
     0,    57,    30,     0,    29,    54,    65,    46,    53,    66,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
   186,     0,    49,    59,    51,    52,    63,     0,     0,     0,
     0,    60,    48,    36,    45,    39,    62,     0,   102,     0,
     0,    50,   100,   101,    93,    94,    33,     0,    34,    35,
    38,     0,    99,    98,    97,    96,     0,    95,   104,     0,
     0,     0,    92,     0,     0,    31,     0,     0,    56,    58,
    61,     0,    37,     0,    57,    30,     0,    29,     0,     0,
     0,     0,    26,     0,   102,    32,     0,     0,   100,   101,
    93,    94,     0,   184,     0,     0,    59,     0,    99,    98,
    97,    96,     0,    95,   104,     0,     0,     0,    92,     0,
     0,     0,     0,     0,     0,     0,     0,     0,    54,    65,
    46,    53,    66,    38,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,    49,     0,    51,    52,    63,
     0,     0,     0,     0,    60,    48,    36,    45,    39,    62,
     0,     0,     0,     0,    50,    26,     0,     0,    32,    33,
     0,    34,    35,    31,     0,     0,    56,    58,    61,     0,
    37,     0,    57,    30,     0,    29,     0,     0,     0,     0,
     0,   102,     0,     0,     0,   100,   101,    93,    94,     0,
     0,   182,     0,     0,    59,    99,    98,    97,    96,     0,
    95,   104,     0,     0,     0,    92,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,    54,    65,    46,    53,
    66,    38,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,    49,     0,    51,    52,    63,     0,     0,
     0,     0,    60,    48,    36,    45,    39,    62,     0,     0,
     0,     0,    50,    26,     0,     0,    32,    33,     0,    34,
    35,     0,     0,     0,     0,     0,    31,     0,     0,    56,
    58,    61,     0,    37,     0,    57,    30,     0,    29,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,    54,
    65,    46,    53,    66,   180,     0,     0,    59,     0,     0,
     0,     0,     0,     0,     0,     0,    49,     0,    51,    52,
    63,     0,     0,     0,     0,    60,    48,    36,    45,    39,
    62,     0,     0,     0,    38,    50,     0,     0,     0,     0,
    33,     0,    34,    35,    31,     0,     0,    56,    58,    61,
     0,    37,     0,    57,    30,     0,    29,     0,     0,     0,
     0,     0,     0,     0,     0,     0,    26,     0,     0,    32,
     0,     0,   178,     0,     0,    59,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,    54,    65,    46,
    53,    66,    38,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,    49,     0,    51,    52,    63,     0,
     0,     0,     0,    60,    48,    36,    45,    39,    62,     0,
     0,     0,     0,    50,    26,     0,     0,    32,    33,     0,
    34,    35,     0,     0,     0,     0,     0,    31,     0,     0,
    56,    58,    61,     0,    37,     0,    57,    30,     0,    29,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,   122,     0,     0,     0,     0,    59,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
    54,    65,    46,    53,    66,    38,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,    49,     0,    51,
    52,    63,     0,     0,     0,     0,    60,    48,    36,    45,
    39,    62,     0,     0,     0,     0,    50,    26,     0,     0,
    32,    33,    31,    34,    35,    56,    58,    61,     0,    37,
     0,    57,    30,     0,    29,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,    54,    65,
    46,    53,    66,    59,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,    49,     0,    51,    52,    63,
     0,     0,     0,     0,    60,    48,    36,    45,    39,    62,
    38,     0,   120,     0,    50,     0,     0,     0,     0,    33,
     0,    34,    35,     0,     0,     0,     0,     0,    31,     0,
     0,    56,    58,    61,     0,    37,   118,    57,    30,     0,
    29,     0,    26,     0,     0,    32,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,    59,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,    54,    65,    46,    53,    66,    38,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,    49,     0,
    51,    52,    63,     0,     0,     0,     0,    60,    48,    36,
    45,    39,    62,     0,     0,     0,     0,    50,    26,     0,
     0,    32,    33,    31,    34,    35,    56,    58,    61,     0,
    37,     0,    57,    30,     0,    29,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,    59,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,    54,    65,    46,    53,
    66,    38,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,    49,     0,    51,    52,    63,     0,     0,
     0,     0,    60,    48,    36,    45,    39,    62,     0,     0,
     0,     0,    50,    26,     0,     0,    32,    33,    31,    34,
    35,    56,    58,    61,     0,    37,     0,    57,    30,     0,
    29,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,    59,
     0,     0,    54,    65,    46,    53,    66,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,    49,
     0,    51,    52,    63,     0,     0,    38,     0,    60,    48,
    36,    45,    39,    62,     0,     0,     0,     0,    50,     0,
     0,     0,     0,    33,     0,    34,    35,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,    26,    27,
     0,    32,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,   116,    54,    65,    46,
    53,    66,     0,     0,     0,     0,     0,     0,   130,     0,
   136,     0,     0,     0,    49,     0,    51,    52,    63,     0,
     0,     0,     0,    60,    48,    36,    45,    39,    62,     0,
     0,     0,     0,    50,     0,     0,     0,     0,    33,     0,
    34,    35,     0,     0,     0,     0,     0,     0,     0,   175,
     0,   177,   179,   181,   183,   185,   187,   189,   191,   193,
   194,   195,   196,   197,   198,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,   132,    65,    46,    53,    66,     0,     0,   226,
     0,     0,     0,     0,     0,     0,     0,     0,     0,    49,
     0,    51,    52,    63,     0,     0,     0,     0,    60,    48,
    36,    45,    39,    62,     0,     0,     0,     0,    50,     0,
     0,     0,     0,    33,     0,    34,    35,     0,   247,     0,
   248,     0,   249,     0,   250,     0,   251,     0,   252,     0,
   253,     0,   254,     0,     0,     0,     0,     0,     0,     0,
     0,     0,   175,     0,     0,     0,   175,     0,     0,   175,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,   292,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,   305 };
int yypact[]={

 -1000, -1000, -1000,  -200, -1000, -1000, -1000, -1000, -1000,    -3,
 -1000,   -97,  -221,    15, -1000, -1000, -1000,    65,    60,    40,
   308,  -255,    39,    38, -1000,    70, -1000,  1056,  -289,  1820,
  1820,  1820,  1820,  1820,  1820,  1820,  1820,  1725,  1649,  1554,
   -15, -1000, -1000,   -32, -1000,   271, -1000,   228,  1915,  -225,
  1820,   211,   209,   200, -1000, -1000,   -11,   -11,   -11,   -11,
   -11,   -11,  1820,   181,  -281,   -11, -1000,   -37, -1000,   -37,
    46, -1000, -1000,  1820,   -37,  1820,   -37,   179,    73, -1000,
   -37,  1820,   -37,  1820,   -37,  1820,  1820,  1820,  1820,  1820,
 -1000,  1820,  1451,  1383,  1280,  1182,  1109,  1011,   898,   838,
  1820,  1820,  1820,  1820,  1820,     2, -1000, -1000,  -301, -1000,
  -301,  -301,  -301,  -301, -1000, -1000,  -228,   260,    10,   168,
 -1000,   243,   -53,  1820,  1820,  1820,  1820,   -25,   253,   781,
  -228, -1000,   165,    62, -1000, -1000,  -228,   143,   725,  1820,
 -1000, -1000, -1000, -1000, -1000, -1000, -1000, -1000,   136, -1000,
    78,  1820,  -272,  1820, -1000, -1000, -1000,   126,    78,  -255,
   311,  -255,  1820,   203,    45, -1000, -1000,   283,  -249,   265,
  -249,    78,    78,    78,    78,  1056,   -75,  1056,  1820,  -295,
  1820,  -290,  1820,  -226,  1820,  -254,  1820,  -151,  1820,   -57,
  1820,   110,  1820,   -88,  -228,   -66,  -140,   959,  -295,   158,
  1820,  1820,   608,     8, -1000,  1820,   459, -1000, -1000,   402,
 -1000,   -65, -1000,   102,   233,    82,   208,  1820,   -34, -1000,
   260,   342,   277, -1000, -1000,   264,   505, -1000,   136,   125,
  1820,   157, -1000,   -37, -1000,   -37, -1000,   260,   -37,  1820,
   -37, -1000,   -37,   137,   -37, -1000, -1000,  1056,  1056,  1056,
  1056,  1056,  1056,  1056,  1056,  1820,  1820,    77,   173, -1000,
  1820,    75, -1000,   -68, -1000, -1000,   -73, -1000,   -81,   142,
  1820, -1000, -1000,   260, -1000,   260, -1000, -1000,  1820,   117,
 -1000, -1000,  1820,  -255,  -255,   -37,  -255,    44,  -249, -1000,
  1820,  -249,   676,   116, -1000,   -82,    63, -1000, -1000, -1000,
 -1000,   -94,   121, -1000, -1000,   913, -1000,   104, -1000, -1000,
  -255, -1000,    73, -1000,   247, -1000, -1000, -1000, -1000, -1000,
   -96, -1000, -1000, -1000,    95,   -37,    86,   -37,  -249, -1000,
 -1000, -1000 };
int yypgo[]={

     0,   388,   386,   381,   377,   293,   376,   372,     0,   117,
   370,   367,   365,     3,    11,     8,  2039,   418,   647,   364,
   363,   362,   354,   353,   325,   276,   458,    38,   346,   323,
    58,   312,   296,   294 };
int yyr1[]={

     0,    31,     1,     8,     4,     9,     9,     9,    10,    10,
    10,    10,    24,    24,    24,    24,    24,    24,    14,    14,
    14,    12,    12,    12,    12,    30,    30,    11,    11,    11,
    11,    11,    11,    11,    11,    13,    13,    27,    27,    29,
    29,     2,     2,     2,     3,     3,    32,    33,    33,    15,
    15,    28,    28,    28,    28,    28,    28,    28,    28,    16,
    16,    16,    16,    16,    16,    16,    16,    16,    16,    16,
    16,    16,    16,    16,    16,    16,    16,    16,    16,    16,
    16,    16,    17,    17,    17,    17,    17,    17,    17,    17,
    17,    17,    17,    17,    17,    17,    17,    17,    17,    17,
    17,    17,    17,    17,    17,    17,    17,    17,    17,    17,
    17,    17,    17,    17,    17,    17,    17,    17,    17,    17,
    17,    17,    17,    17,    17,    17,    17,    17,    17,    17,
    17,    17,    17,    17,    17,    17,    25,    25,    23,    18,
    19,    20,    21,    22,    26,    26,    26,    26,     5,     5,
     6,     6,     7,     7 };
int yyr2[]={

     0,     1,     5,     9,     1,     1,     5,     5,     5,     2,
     5,     7,     3,     3,     7,     7,     7,     7,     1,     5,
    13,    13,    13,     9,     9,     1,     5,    15,    15,    11,
    11,    17,    15,    21,     7,     1,     2,     1,     2,     1,
     2,     3,     3,     3,     7,     5,     7,     7,     5,     7,
     2,     7,    11,     9,    13,    13,     7,     5,     9,     7,
     9,     9,     9,     9,     9,     9,     9,     9,     7,     7,
     7,     7,     7,     7,     7,     7,     7,     7,     7,    11,
     7,     3,     5,     5,     5,     5,     5,     5,     5,     5,
     5,     5,     7,     5,     7,     5,     7,     7,     3,     3,
     9,    11,     3,     3,     3,    11,    13,    13,    11,     9,
    11,    13,    17,     3,     3,     7,     9,     5,     5,     9,
    11,     9,    11,     3,     5,     3,     5,     5,     3,     7,
     7,     9,     9,    13,     2,     2,     1,     3,     5,     5,
     5,     5,     5,     5,     3,     3,     3,     3,     5,     3,
     5,     3,     7,     5 };
int yychk[]={

 -1000,    -1,   -31,    -9,    -2,   -10,    -3,   -32,   -33,   -29,
   -11,   263,   264,   265,   262,   -12,    59,   -24,   266,   267,
   273,    -8,   268,   269,   256,   -15,   123,   -16,   -17,    45,
    43,    33,   126,   298,   300,   301,   285,    40,    91,   287,
   -18,   -22,   -20,   -19,   -21,   286,   259,   -23,   284,   274,
   293,   276,   277,   260,   257,   -28,    36,    42,    37,    64,
   283,    38,   288,   278,   -26,   258,   261,   257,    -8,   257,
   257,    59,    59,    40,    -8,    40,    -8,   -18,    40,   -30,
   272,    40,    -8,    40,    -8,   268,   269,   266,   267,    44,
    -4,    61,   299,   281,   282,   294,   292,   291,   290,   289,
   279,   280,   275,    63,   295,   296,   302,   303,   -17,    -8,
   -17,   -17,   -17,   -17,   -17,   -17,   -16,   -15,    41,   -15,
    93,   -15,    59,    91,   123,    91,   123,   -18,    40,    40,
   -16,    -8,   257,   -18,   257,    -8,   -16,    40,    40,    40,
   -26,   257,   -18,   -26,   -26,   -26,   -26,   -26,   -26,   -25,
   -15,    40,   296,   -26,    -8,    -8,    59,   -27,   -15,    -8,
   -15,    -8,    40,   -15,   -13,   -24,    -8,   -15,    -8,   -15,
    -8,   -15,   -15,   -15,   -15,   -16,    -9,   -16,    61,   -16,
    61,   -16,    61,   -16,    61,   -16,    61,   -16,    61,   -16,
    61,   -16,    61,   -16,   -16,   -16,   -16,   -16,   -16,   258,
    91,   123,    44,    -5,    41,    91,    44,    -6,    93,    44,
    -7,    59,   125,   -15,   -15,   -15,   -15,   123,   -18,    41,
   -15,    40,    40,    41,    41,   -15,   -16,   -25,   -26,   -25,
   288,   278,   -25,    41,   -30,    41,   -30,   -15,    -5,    59,
    41,   -14,   270,   271,    41,   -14,   125,   -16,   -16,   -16,
   -16,   -16,   -16,   -16,   -16,    58,    40,   -15,   -15,    41,
    91,   -15,    93,    59,   125,    93,    59,    93,    59,   -15,
   123,    -5,    41,   -15,    41,   -15,    41,    41,    44,   -25,
    41,   -25,    40,    -8,    -8,    -5,    -8,   -27,    -8,    -8,
    40,    -8,   -16,   -25,    93,    59,   -15,    93,   125,   125,
   125,    59,   -15,    -5,    -5,   -16,    41,   -25,   -30,   -30,
    -8,   -30,    59,   -14,   -15,   -14,    41,   125,    93,   125,
    59,    41,    41,   -30,   -13,    41,   125,    41,    -8,    41,
    -8,   -14 };
int yydef[]={

     1,    -2,     5,    -2,     6,     7,    41,    42,    43,     0,
     9,     0,     0,     0,    40,     8,    10,     0,     0,     0,
     0,    -2,     0,     0,    12,    13,     4,    50,    81,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
    -2,    99,   102,   103,   104,     0,   113,   114,     0,   123,
   125,   128,     0,     0,    -2,   135,     0,     0,     0,     0,
     0,     0,   136,     0,     0,     0,   147,     0,    45,     0,
     0,    48,    11,    37,     0,     0,     0,     0,    -2,    34,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     5,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,    87,    88,    82,   146,
    83,    84,    85,    86,    -2,    -2,    91,     0,    93,     0,
    95,     0,     0,     0,     0,     0,     0,     0,     0,     0,
   117,   118,   134,    98,   124,   126,   127,     0,     0,     0,
   139,   144,   145,   143,   141,   140,   142,   138,   136,    57,
   137,   136,     0,   136,    44,    46,    47,     0,    38,    25,
     0,    25,     0,    13,     0,    36,    26,     0,    18,     0,
    18,    14,    15,    16,    17,    49,    39,    59,     0,    68,
     0,    69,     0,    70,     0,    71,     0,    74,     0,    75,
     0,    77,     0,    78,    -2,    -2,    -2,     0,    80,     0,
     0,     0,     0,    92,   149,     0,     0,    94,   151,     0,
    96,     0,    97,     0,     0,     0,     0,     0,     0,   115,
     0,     0,     0,   129,   130,     0,     0,    51,   136,     0,
   136,     0,    56,     0,    29,     0,    30,     0,     0,    37,
     0,    23,     0,     0,     0,    24,     3,    60,    61,    62,
    63,    64,    65,    66,    67,     0,   136,     0,     0,   148,
     0,     0,   150,     0,   153,   100,     0,   109,     0,     0,
     0,   116,   119,     0,   121,     0,   131,   132,     0,     0,
    58,    53,   136,    25,    25,     0,    25,     0,    18,    19,
     0,    18,    79,     0,   101,     0,     0,   108,   152,   105,
   110,     0,     0,   120,   122,     0,    52,     0,    27,    28,
    25,    32,    -2,    21,     0,    22,    55,   106,   107,   111,
     0,   133,    54,    31,     0,     0,     0,     0,    18,   112,
    33,    20 };
typedef struct { char *t_name; int t_val; } yytoktype;
#ifndef YYDEBUG
#	define YYDEBUG	0	/* don't allow debugging */
#endif

#if YYDEBUG

yytoktype yytoks[] =
{
	"{",	123,
	")",	41,
	"WORD",	257,
	"METHOD",	258,
	"THING",	259,
	"PMFUNC",	260,
	"PRIVATEREF",	261,
	"LABEL",	262,
	"FORMAT",	263,
	"SUB",	264,
	"PACKAGE",	265,
	"WHILE",	266,
	"UNTIL",	267,
	"IF",	268,
	"UNLESS",	269,
	"ELSE",	270,
	"ELSIF",	271,
	"CONTINUE",	272,
	"FOR",	273,
	"LOOPEX",	274,
	"DOTDOT",	275,
	"FUNC0",	276,
	"FUNC1",	277,
	"FUNC",	278,
	"RELOP",	279,
	"EQOP",	280,
	"MULOP",	281,
	"ADDOP",	282,
	"DOLSHARP",	283,
	"DO",	284,
	"LOCAL",	285,
	"DELETE",	286,
	"HASHBRACK",	287,
	"LSTOP",	288,
	",",	44,
	"=",	61,
	"?",	63,
	":",	58,
	"OROR",	289,
	"ANDAND",	290,
	"BITOROP",	291,
	"BITANDOP",	292,
	"UNIOP",	293,
	"SHIFTOP",	294,
	"MATCHOP",	295,
	"ARROW",	296,
	"!",	33,
	"~",	126,
	"UMINUS",	297,
	"REFGEN",	298,
	"POWOP",	299,
	"PREINC",	300,
	"PREDEC",	301,
	"POSTINC",	302,
	"POSTDEC",	303,
	"(",	40,
	"-unknown-",	-1	/* ends search */
};

char * yyreds[] =
{
	"-no such reduction-",
	"prog : /* empty */",
	"prog : lineseq",
	"block : '{' remember lineseq '}'",
	"remember : /* empty */",
	"lineseq : /* empty */",
	"lineseq : lineseq decl",
	"lineseq : lineseq line",
	"line : label cond",
	"line : loop",
	"line : label ';'",
	"line : label sideff ';'",
	"sideff : error",
	"sideff : expr",
	"sideff : expr IF expr",
	"sideff : expr UNLESS expr",
	"sideff : expr WHILE expr",
	"sideff : expr UNTIL expr",
	"else : /* empty */",
	"else : ELSE block",
	"else : ELSIF '(' expr ')' block else",
	"cond : IF '(' expr ')' block else",
	"cond : UNLESS '(' expr ')' block else",
	"cond : IF block block else",
	"cond : UNLESS block block else",
	"cont : /* empty */",
	"cont : CONTINUE block",
	"loop : label WHILE '(' texpr ')' block cont",
	"loop : label UNTIL '(' expr ')' block cont",
	"loop : label WHILE block block cont",
	"loop : label UNTIL block block cont",
	"loop : label FOR scalar '(' expr crp block cont",
	"loop : label FOR '(' expr crp block cont",
	"loop : label FOR '(' nexpr ';' texpr ';' nexpr ')' block",
	"loop : label block cont",
	"nexpr : /* empty */",
	"nexpr : sideff",
	"texpr : /* empty */",
	"texpr : expr",
	"label : /* empty */",
	"label : LABEL",
	"decl : format",
	"decl : subrout",
	"decl : package",
	"format : FORMAT WORD block",
	"format : FORMAT block",
	"subrout : SUB WORD block",
	"package : PACKAGE WORD ';'",
	"package : PACKAGE ';'",
	"expr : expr ',' sexpr",
	"expr : sexpr",
	"listop : LSTOP indirob listexpr",
	"listop : FUNC '(' indirob listexpr ')'",
	"listop : indirob ARROW LSTOP listexpr",
	"listop : indirob ARROW FUNC '(' listexpr ')'",
	"listop : term ARROW METHOD '(' listexpr ')'",
	"listop : METHOD indirob listexpr",
	"listop : LSTOP listexpr",
	"listop : FUNC '(' listexpr ')'",
	"sexpr : sexpr '=' sexpr",
	"sexpr : sexpr POWOP '=' sexpr",
	"sexpr : sexpr MULOP '=' sexpr",
	"sexpr : sexpr ADDOP '=' sexpr",
	"sexpr : sexpr SHIFTOP '=' sexpr",
	"sexpr : sexpr BITANDOP '=' sexpr",
	"sexpr : sexpr BITOROP '=' sexpr",
	"sexpr : sexpr ANDAND '=' sexpr",
	"sexpr : sexpr OROR '=' sexpr",
	"sexpr : sexpr POWOP sexpr",
	"sexpr : sexpr MULOP sexpr",
	"sexpr : sexpr ADDOP sexpr",
	"sexpr : sexpr SHIFTOP sexpr",
	"sexpr : sexpr RELOP sexpr",
	"sexpr : sexpr EQOP sexpr",
	"sexpr : sexpr BITANDOP sexpr",
	"sexpr : sexpr BITOROP sexpr",
	"sexpr : sexpr DOTDOT sexpr",
	"sexpr : sexpr ANDAND sexpr",
	"sexpr : sexpr OROR sexpr",
	"sexpr : sexpr '?' sexpr ':' sexpr",
	"sexpr : sexpr MATCHOP sexpr",
	"sexpr : term",
	"term : '-' term",
	"term : '+' term",
	"term : '!' term",
	"term : '~' term",
	"term : REFGEN term",
	"term : term POSTINC",
	"term : term POSTDEC",
	"term : PREINC term",
	"term : PREDEC term",
	"term : LOCAL sexpr",
	"term : '(' expr crp",
	"term : '(' ')'",
	"term : '[' expr crb",
	"term : '[' ']'",
	"term : HASHBRACK expr crhb",
	"term : HASHBRACK ';' '}'",
	"term : scalar",
	"term : star",
	"term : scalar '[' expr ']'",
	"term : term ARROW '[' expr ']'",
	"term : hsh",
	"term : ary",
	"term : arylen",
	"term : scalar '{' expr ';' '}'",
	"term : term ARROW '{' expr ';' '}'",
	"term : '(' expr crp '[' expr ']'",
	"term : '(' ')' '[' expr ']'",
	"term : ary '[' expr ']'",
	"term : ary '{' expr ';' '}'",
	"term : DELETE scalar '{' expr ';' '}'",
	"term : DELETE '(' scalar '{' expr ';' '}' ')'",
	"term : THING",
	"term : amper",
	"term : amper '(' ')'",
	"term : amper '(' expr crp",
	"term : DO sexpr",
	"term : DO block",
	"term : DO WORD '(' ')'",
	"term : DO WORD '(' expr crp",
	"term : DO scalar '(' ')'",
	"term : DO scalar '(' expr crp",
	"term : LOOPEX",
	"term : LOOPEX WORD",
	"term : UNIOP",
	"term : UNIOP block",
	"term : UNIOP sexpr",
	"term : FUNC0",
	"term : FUNC0 '(' ')'",
	"term : FUNC1 '(' ')'",
	"term : FUNC1 '(' expr ')'",
	"term : PMFUNC '(' sexpr ')'",
	"term : PMFUNC '(' sexpr ',' sexpr ')'",
	"term : WORD",
	"term : listop",
	"listexpr : /* empty */",
	"listexpr : expr",
	"amper : '&' indirob",
	"scalar : '$' indirob",
	"ary : '@' indirob",
	"hsh : '%' indirob",
	"arylen : DOLSHARP indirob",
	"star : '*' indirob",
	"indirob : WORD",
	"indirob : scalar",
	"indirob : block",
	"indirob : PRIVATEREF",
	"crp : ',' ')'",
	"crp : ')'",
	"crb : ',' ']'",
	"crb : ']'",
	"crhb : ',' ';' '}'",
	"crhb : ';' '}'",
};
#endif /* YYDEBUG */
#line 1 "/usr/lib/yaccpar"
/*	@(#)yaccpar 1.10 89/04/04 SMI; from S5R3 1.10	*/

/*
** Skeleton parser driver for yacc output
*/

/*
** yacc user known macros and defines
*/
#define YYERROR		goto yyerrlab
#define YYACCEPT	{ free(yys); free(yyv); return(0); }
#define YYABORT		{ free(yys); free(yyv); return(1); }
#define YYBACKUP( newtoken, newvalue )\
{\
	if ( yychar >= 0 || ( yyr2[ yytmp ] >> 1 ) != 1 )\
	{\
		yyerror( "syntax error - cannot backup" );\
		goto yyerrlab;\
	}\
	yychar = newtoken;\
	yystate = *yyps;\
	yylval = newvalue;\
	goto yynewstate;\
}
#define YYRECOVERING()	(!!yyerrflag)
#ifndef YYDEBUG
#	define YYDEBUG	1	/* make debugging available */
#endif

/*
** user known globals
*/
int yydebug;			/* set to 1 to get debugging */

/*
** driver internal defines
*/
#define YYFLAG		(-1000)

/*
** static variables used by the parser
*/
static YYSTYPE *yyv;			/* value stack */
static int *yys;			/* state stack */

static YYSTYPE *yypv;			/* top of value stack */
static int *yyps;			/* top of state stack */

static int yystate;			/* current state */
static int yytmp;			/* extra var (lasts between blocks) */

int yynerrs;			/* number of errors */

int yyerrflag;			/* error recovery flag */
int yychar;			/* current input token number */


/*
** yyparse - return 0 if worked, 1 if syntax error not recovered from
*/
int
yyparse()
{
	register YYSTYPE *yypvt;	/* top of value stack for $vars */
	unsigned yymaxdepth = YYMAXDEPTH;

	/*
	** Initialize externals - yyparse may be called more than once
	*/
	yyv = (YYSTYPE*)malloc(yymaxdepth*sizeof(YYSTYPE));
	yys = (int*)malloc(yymaxdepth*sizeof(int));
	if (!yyv || !yys)
	{
		yyerror( "out of memory" );
		return(1);
	}
	yypv = &yyv[-1];
	yyps = &yys[-1];
	yystate = 0;
	yytmp = 0;
	yynerrs = 0;
	yyerrflag = 0;
	yychar = -1;

	goto yystack;
	{
		register YYSTYPE *yy_pv;	/* top of value stack */
		register int *yy_ps;		/* top of state stack */
		register int yy_state;		/* current state */
		register int  yy_n;		/* internal state number info */

		/*
		** get globals into registers.
		** branch to here only if YYBACKUP was called.
		*/
	yynewstate:
		yy_pv = yypv;
		yy_ps = yyps;
		yy_state = yystate;
		goto yy_newstate;

		/*
		** get globals into registers.
		** either we just started, or we just finished a reduction
		*/
	yystack:
		yy_pv = yypv;
		yy_ps = yyps;
		yy_state = yystate;

		/*
		** top of for (;;) loop while no reductions done
		*/
	yy_stack:
		/*
		** put a state and value onto the stacks
		*/
#if YYDEBUG
		/*
		** if debugging, look up token value in list of value vs.
		** name pairs.  0 and negative (-1) are special values.
		** Note: linear search is used since time is not a real
		** consideration while debugging.
		*/
		if ( yydebug )
		{
			register int yy_i;

			(void)printf( "State %d, token ", yy_state );
			if ( yychar == 0 )
				(void)printf( "end-of-file\n" );
			else if ( yychar < 0 )
				(void)printf( "-none-\n" );
			else
			{
				for ( yy_i = 0; yytoks[yy_i].t_val >= 0;
					yy_i++ )
				{
					if ( yytoks[yy_i].t_val == yychar )
						break;
				}
				(void)printf( "%s\n", yytoks[yy_i].t_name );
			}
		}
#endif /* YYDEBUG */
		if ( ++yy_ps >= &yys[ yymaxdepth ] )	/* room on stack? */
		{
			/*
			** reallocate and recover.  Note that pointers
			** have to be reset, or bad things will happen
			*/
			int yyps_index = (yy_ps - yys);
			int yypv_index = (yy_pv - yyv);
			int yypvt_index = (yypvt - yyv);
			yymaxdepth += YYMAXDEPTH;
			yyv = (YYSTYPE*)realloc((char*)yyv,
				yymaxdepth * sizeof(YYSTYPE));
			yys = (int*)realloc((char*)yys,
				yymaxdepth * sizeof(int));
			if (!yyv || !yys)
			{
				yyerror( "yacc stack overflow" );
				return(1);
			}
			yy_ps = yys + yyps_index;
			yy_pv = yyv + yypv_index;
			yypvt = yyv + yypvt_index;
		}
		*yy_ps = yy_state;
		*++yy_pv = yyval;

		/*
		** we have a new state - find out what to do
		*/
	yy_newstate:
		if ( ( yy_n = yypact[ yy_state ] ) <= YYFLAG )
			goto yydefault;		/* simple state */
#if YYDEBUG
		/*
		** if debugging, need to mark whether new token grabbed
		*/
		yytmp = yychar < 0;
#endif
		if ( ( yychar < 0 ) && ( ( yychar = yylex() ) < 0 ) )
			yychar = 0;		/* reached EOF */
#if YYDEBUG
		if ( yydebug && yytmp )
		{
			register int yy_i;

			(void)printf( " *** Received token " );
			if ( yychar == 0 )
				(void)printf( "end-of-file\n" );
			else if ( yychar < 0 )
				(void)printf( "-none-\n" );
			else
			{
				for ( yy_i = 0; yytoks[yy_i].t_val >= 0;
					yy_i++ )
				{
					if ( yytoks[yy_i].t_val == yychar )
						break;
				}
				(void)printf( "%s\n", yytoks[yy_i].t_name );
			}
		}
#endif /* YYDEBUG */
		if ( ( ( yy_n += yychar ) < 0 ) || ( yy_n >= YYLAST ) )
			goto yydefault;
		if ( yychk[ yy_n = yyact[ yy_n ] ] == yychar )	/*valid shift*/
		{
			yychar = -1;
			yyval = yylval;
			yy_state = yy_n;
			if ( yyerrflag > 0 )
				yyerrflag--;
			goto yy_stack;
		}

	yydefault:
		if ( ( yy_n = yydef[ yy_state ] ) == -2 )
		{
#if YYDEBUG
			yytmp = yychar < 0;
#endif
			if ( ( yychar < 0 ) && ( ( yychar = yylex() ) < 0 ) )
				yychar = 0;		/* reached EOF */
#if YYDEBUG
			if ( yydebug && yytmp )
			{
				register int yy_i;

				(void)printf( " *** Received token " );
				if ( yychar == 0 )
					(void)printf( "end-of-file\n" );
				else if ( yychar < 0 )
					(void)printf( "-none-\n" );
				else
				{
					for ( yy_i = 0;
						yytoks[yy_i].t_val >= 0;
						yy_i++ )
					{
						if ( yytoks[yy_i].t_val
							== yychar )
						{
							break;
						}
					}
					(void)printf( "%s\n", yytoks[yy_i].t_name );
				}
			}
#endif /* YYDEBUG */
			/*
			** look through exception table
			*/
			{
				register int *yyxi = yyexca;

				while ( ( *yyxi != -1 ) ||
					( yyxi[1] != yy_state ) )
				{
					yyxi += 2;
				}
				while ( ( *(yyxi += 2) >= 0 ) &&
					( *yyxi != yychar ) )
					;
				if ( ( yy_n = yyxi[1] ) < 0 )
					YYACCEPT;
			}
		}

		/*
		** check for syntax error
		*/
		if ( yy_n == 0 )	/* have an error */
		{
			/* no worry about speed here! */
			switch ( yyerrflag )
			{
			case 0:		/* new error */
				yyerror( "syntax error" );
				goto skip_init;
			yyerrlab:
				/*
				** get globals into registers.
				** we have a user generated syntax type error
				*/
				yy_pv = yypv;
				yy_ps = yyps;
				yy_state = yystate;
				yynerrs++;
			skip_init:
			case 1:
			case 2:		/* incompletely recovered error */
					/* try again... */
				yyerrflag = 3;
				/*
				** find state where "error" is a legal
				** shift action
				*/
				while ( yy_ps >= yys )
				{
					yy_n = yypact[ *yy_ps ] + YYERRCODE;
					if ( yy_n >= 0 && yy_n < YYLAST &&
						yychk[yyact[yy_n]] == YYERRCODE)					{
						/*
						** simulate shift of "error"
						*/
						yy_state = yyact[ yy_n ];
						goto yy_stack;
					}
					/*
					** current state has no shift on
					** "error", pop stack
					*/
#if YYDEBUG
#	define _POP_ "Error recovery pops state %d, uncovers state %d\n"
					if ( yydebug )
						(void)printf( _POP_, *yy_ps,
							yy_ps[-1] );
#	undef _POP_
#endif
					yy_ps--;
					yy_pv--;
				}
				/*
				** there is no state on stack with "error" as
				** a valid shift.  give up.
				*/
				YYABORT;
			case 3:		/* no shift yet; eat a token */
#if YYDEBUG
				/*
				** if debugging, look up token in list of
				** pairs.  0 and negative shouldn't occur,
				** but since timing doesn't matter when
				** debugging, it doesn't hurt to leave the
				** tests here.
				*/
				if ( yydebug )
				{
					register int yy_i;

					(void)printf( "Error recovery discards " );
					if ( yychar == 0 )
						(void)printf( "token end-of-file\n" );
					else if ( yychar < 0 )
						(void)printf( "token -none-\n" );
					else
					{
						for ( yy_i = 0;
							yytoks[yy_i].t_val >= 0;
							yy_i++ )
						{
							if ( yytoks[yy_i].t_val
								== yychar )
							{
								break;
							}
						}
						(void)printf( "token %s\n",
							yytoks[yy_i].t_name );
					}
				}
#endif /* YYDEBUG */
				if ( yychar == 0 )	/* reached EOF. quit */
					YYABORT;
				yychar = -1;
				goto yy_newstate;
			}
		}/* end if ( yy_n == 0 ) */
		/*
		** reduction by production yy_n
		** put stack tops, etc. so things right after switch
		*/
#if YYDEBUG
		/*
		** if debugging, print the string that is the user's
		** specification of the reduction which is just about
		** to be done.
		*/
		if ( yydebug )
			(void)printf( "Reduce by (%d) \"%s\"\n",
				yy_n, yyreds[ yy_n ] );
#endif
		yytmp = yy_n;			/* value to switch over */
		yypvt = yy_pv;			/* $vars top of value stack */
		/*
		** Look in goto table for next state
		** Sorry about using yy_state here as temporary
		** register variable, but why not, if it works...
		** If yyr2[ yy_n ] doesn't have the low order bit
		** set, then there is no action to be done for
		** this reduction.  So, no saving & unsaving of
		** registers done.  The only difference between the
		** code just after the if and the body of the if is
		** the goto yy_stack in the body.  This way the test
		** can be made before the choice of what to do is needed.
		*/
		{
			/* length of production doubled with extra bit */
			register int yy_len = yyr2[ yy_n ];

			if ( !( yy_len & 01 ) )
			{
				yy_len >>= 1;
				yyval = ( yy_pv -= yy_len )[1];	/* $$ = $1 */
				yy_state = yypgo[ yy_n = yyr1[ yy_n ] ] +
					*( yy_ps -= yy_len ) + 1;
				if ( yy_state >= YYLAST ||
					yychk[ yy_state =
					yyact[ yy_state ] ] != -yy_n )
				{
					yy_state = yyact[ yypgo[ yy_n ] ];
				}
				goto yy_stack;
			}
			yy_len >>= 1;
			yyval = ( yy_pv -= yy_len )[1];	/* $$ = $1 */
			yy_state = yypgo[ yy_n = yyr1[ yy_n ] ] +
				*( yy_ps -= yy_len ) + 1;
			if ( yy_state >= YYLAST ||
				yychk[ yy_state = yyact[ yy_state ] ] != -yy_n )
			{
				yy_state = yyact[ yypgo[ yy_n ] ];
			}
		}
					/* save until reenter driver code */
		yystate = yy_state;
		yyps = yy_ps;
		yypv = yy_pv;
	}
	/*
	** code supplied by user is placed in this switch
	*/
	switch( yytmp )
	{
		
case 1:
# line 100 "perly.y"
{
#if defined(YYDEBUG) && defined(DEBUGGING)
		    yydebug = (debug & 1);
#endif
		    expect = XBLOCK;
		} break;
case 2:
# line 107 "perly.y"
{   if (in_eval) {
				eval_root = newUNOP(OP_LEAVEEVAL, 0, yypvt[-0].opval);
				eval_start = linklist(eval_root);
				eval_root->op_next = 0;
				peep(eval_start);
			    }
			    else
				main_root = block_head(yypvt[-0].opval, &main_start);
			} break;
case 3:
# line 119 "perly.y"
{ yyval.opval = scalarseq(yypvt[-1].opval);
			  if (copline > (line_t)yypvt[-3].ival)
			      copline = yypvt[-3].ival;
			  leave_scope(yypvt[-2].ival);
			  pad_leavemy(comppadnamefill);
			  expect = XBLOCK; } break;
case 4:
# line 128 "perly.y"
{ yyval.ival = savestack_ix; SAVEINT(comppadnamefill); } break;
case 5:
# line 132 "perly.y"
{ yyval.opval = Nullop; } break;
case 6:
# line 134 "perly.y"
{ yyval.opval = yypvt[-1].opval; } break;
case 7:
# line 136 "perly.y"
{ yyval.opval = append_list(OP_LINESEQ, yypvt[-1].opval, yypvt[-0].opval); pad_reset(); } break;
case 8:
# line 140 "perly.y"
{ yyval.opval = newSTATEOP(0, yypvt[-1].pval, yypvt[-0].opval); } break;
case 10:
# line 143 "perly.y"
{ if (yypvt[-1].pval != Nullch) {
			      yyval.opval = newSTATEOP(0, yypvt[-1].pval, newOP(OP_NULL, 0));
			    }
			    else {
			      yyval.opval = Nullop;
			      copline = NOLINE;
			    }
			    expect = XBLOCK; } break;
case 11:
# line 152 "perly.y"
{ yyval.opval = newSTATEOP(0, yypvt[-2].pval, yypvt[-1].opval);
			  expect = XBLOCK; } break;
case 12:
# line 157 "perly.y"
{ yyval.opval = Nullop; } break;
case 13:
# line 159 "perly.y"
{ yyval.opval = yypvt[-0].opval; } break;
case 14:
# line 161 "perly.y"
{ yyval.opval = newLOGOP(OP_AND, 0, yypvt[-0].opval, yypvt[-2].opval); } break;
case 15:
# line 163 "perly.y"
{ yyval.opval = newLOGOP(OP_OR, 0, yypvt[-0].opval, yypvt[-2].opval); } break;
case 16:
# line 165 "perly.y"
{ yyval.opval = newLOOPOP(0, 1, scalar(yypvt[-0].opval), yypvt[-2].opval); } break;
case 17:
# line 167 "perly.y"
{ yyval.opval = newLOOPOP(0, 1, invert(scalar(yypvt[-0].opval)), yypvt[-2].opval);} break;
case 18:
# line 171 "perly.y"
{ yyval.opval = Nullop; } break;
case 19:
# line 173 "perly.y"
{ yyval.opval = scope(yypvt[-0].opval); } break;
case 20:
# line 175 "perly.y"
{ copline = yypvt[-5].ival;
			    yyval.opval = newCONDOP(0, yypvt[-3].opval, scope(yypvt[-1].opval), yypvt[-0].opval); } break;
case 21:
# line 180 "perly.y"
{ copline = yypvt[-5].ival;
			    yyval.opval = newCONDOP(0, yypvt[-3].opval, scope(yypvt[-1].opval), yypvt[-0].opval); } break;
case 22:
# line 183 "perly.y"
{ copline = yypvt[-5].ival;
			    yyval.opval = newCONDOP(0,
				invert(scalar(yypvt[-3].opval)), scope(yypvt[-1].opval), yypvt[-0].opval); } break;
case 23:
# line 187 "perly.y"
{ copline = yypvt[-3].ival;
			    yyval.opval = newCONDOP(0, scope(yypvt[-2].opval), scope(yypvt[-1].opval), yypvt[-0].opval); } break;
case 24:
# line 190 "perly.y"
{ copline = yypvt[-3].ival;
			    yyval.opval = newCONDOP(0, invert(scalar(scope(yypvt[-2].opval))),
						scope(yypvt[-1].opval), yypvt[-0].opval); } break;
case 25:
# line 196 "perly.y"
{ yyval.opval = Nullop; } break;
case 26:
# line 198 "perly.y"
{ yyval.opval = scope(yypvt[-0].opval); } break;
case 27:
# line 202 "perly.y"
{ copline = yypvt[-5].ival;
			    yyval.opval = newSTATEOP(0, yypvt[-6].pval,
				    newWHILEOP(0, 1, Nullop, yypvt[-3].opval, yypvt[-1].opval, yypvt[-0].opval) ); } break;
case 28:
# line 206 "perly.y"
{ copline = yypvt[-5].ival;
			    yyval.opval = newSTATEOP(0, yypvt[-6].pval,
				    newWHILEOP(0, 1, Nullop,
					invert(scalar(yypvt[-3].opval)), yypvt[-1].opval, yypvt[-0].opval) ); } break;
case 29:
# line 211 "perly.y"
{ copline = yypvt[-3].ival;
			    yyval.opval = newSTATEOP(0, yypvt[-4].pval,
				    newWHILEOP(0, 1, Nullop,
					scope(yypvt[-2].opval), yypvt[-1].opval, yypvt[-0].opval) ); } break;
case 30:
# line 216 "perly.y"
{ copline = yypvt[-3].ival;
			    yyval.opval = newSTATEOP(0, yypvt[-4].pval,
				    newWHILEOP(0, 1, Nullop,
					invert(scalar(scope(yypvt[-2].opval))), yypvt[-1].opval, yypvt[-0].opval)); } break;
case 31:
# line 221 "perly.y"
{ yyval.opval = newFOROP(0, yypvt[-7].pval, yypvt[-6].ival, ref(yypvt[-5].opval, OP_ENTERLOOP),
				yypvt[-3].opval, yypvt[-1].opval, yypvt[-0].opval); } break;
case 32:
# line 224 "perly.y"
{ yyval.opval = newFOROP(0, yypvt[-6].pval, yypvt[-5].ival, Nullop, yypvt[-3].opval, yypvt[-1].opval, yypvt[-0].opval); } break;
case 33:
# line 227 "perly.y"
{  copline = yypvt[-8].ival;
			    yyval.opval = append_elem(OP_LINESEQ,
				    newSTATEOP(0, yypvt[-9].pval, scalar(yypvt[-6].opval)),
				    newSTATEOP(0, yypvt[-9].pval,
					newWHILEOP(0, 1, Nullop,
					    scalar(yypvt[-4].opval), yypvt[-0].opval, scalar(yypvt[-2].opval)) )); } break;
case 34:
# line 234 "perly.y"
{ yyval.opval = newSTATEOP(0,
				yypvt[-2].pval, newWHILEOP(0, 1, Nullop, Nullop, yypvt[-1].opval, yypvt[-0].opval)); } break;
case 35:
# line 239 "perly.y"
{ yyval.opval = Nullop; } break;
case 37:
# line 244 "perly.y"
{ (void)scan_num("1"); yyval.opval = yylval.opval; } break;
case 39:
# line 249 "perly.y"
{ yyval.pval = Nullch; } break;
case 41:
# line 254 "perly.y"
{ yyval.ival = 0; } break;
case 42:
# line 256 "perly.y"
{ yyval.ival = 0; } break;
case 43:
# line 258 "perly.y"
{ yyval.ival = 0; } break;
case 44:
# line 262 "perly.y"
{ newFORM(yypvt[-2].ival, yypvt[-1].opval, yypvt[-0].opval); } break;
case 45:
# line 264 "perly.y"
{ newFORM(yypvt[-1].ival, Nullop, yypvt[-0].opval); } break;
case 46:
# line 268 "perly.y"
{ newSUB(yypvt[-2].ival, yypvt[-1].opval, yypvt[-0].opval); } break;
case 47:
# line 272 "perly.y"
{ package(yypvt[-1].opval); } break;
case 48:
# line 274 "perly.y"
{ package(Nullop); } break;
case 49:
# line 278 "perly.y"
{ yyval.opval = append_elem(OP_LIST, yypvt[-2].opval, yypvt[-0].opval); } break;
case 51:
# line 283 "perly.y"
{ yyval.opval = convert(yypvt[-2].ival, OPf_STACKED,
				prepend_elem(OP_LIST, newGVREF(yypvt[-1].opval), yypvt[-0].opval) ); } break;
case 52:
# line 286 "perly.y"
{ yyval.opval = convert(yypvt[-4].ival, OPf_STACKED,
				prepend_elem(OP_LIST, newGVREF(yypvt[-2].opval), yypvt[-1].opval) ); } break;
case 53:
# line 289 "perly.y"
{ yyval.opval = convert(yypvt[-1].ival, OPf_STACKED,
				prepend_elem(OP_LIST, newGVREF(yypvt[-3].opval), yypvt[-0].opval) ); } break;
case 54:
# line 292 "perly.y"
{ yyval.opval = convert(yypvt[-3].ival, OPf_STACKED,
				prepend_elem(OP_LIST, newGVREF(yypvt[-5].opval), yypvt[-1].opval) ); } break;
case 55:
# line 295 "perly.y"
{ yyval.opval = convert(OP_ENTERSUBR, OPf_STACKED|OPf_SPECIAL,
				prepend_elem(OP_LIST, newMETHOD(yypvt[-5].opval,yypvt[-3].opval), yypvt[-1].opval)); } break;
case 56:
# line 298 "perly.y"
{ yyval.opval = convert(OP_ENTERSUBR, OPf_STACKED|OPf_SPECIAL,
				prepend_elem(OP_LIST, newMETHOD(yypvt[-1].opval,yypvt[-2].opval), yypvt[-0].opval)); } break;
case 57:
# line 301 "perly.y"
{ yyval.opval = convert(yypvt[-1].ival, 0, yypvt[-0].opval); } break;
case 58:
# line 303 "perly.y"
{ yyval.opval = convert(yypvt[-3].ival, 0, yypvt[-1].opval); } break;
case 59:
# line 307 "perly.y"
{ yyval.opval = newASSIGNOP(OPf_STACKED, yypvt[-2].opval, yypvt[-0].opval); } break;
case 60:
# line 309 "perly.y"
{ yyval.opval = newBINOP(yypvt[-2].ival, OPf_STACKED,
				ref(scalar(yypvt[-3].opval), yypvt[-2].ival), scalar(yypvt[-0].opval)); } break;
case 61:
# line 312 "perly.y"
{ yyval.opval = newBINOP(yypvt[-2].ival, OPf_STACKED,
				ref(scalar(yypvt[-3].opval), yypvt[-2].ival), scalar(yypvt[-0].opval)); } break;
case 62:
# line 315 "perly.y"
{ yyval.opval = newBINOP(yypvt[-2].ival, OPf_STACKED,
				ref(scalar(yypvt[-3].opval), yypvt[-2].ival), scalar(yypvt[-0].opval));} break;
case 63:
# line 318 "perly.y"
{ yyval.opval = newBINOP(yypvt[-2].ival, OPf_STACKED,
				ref(scalar(yypvt[-3].opval), yypvt[-2].ival), scalar(yypvt[-0].opval)); } break;
case 64:
# line 321 "perly.y"
{ yyval.opval = newBINOP(yypvt[-2].ival, OPf_STACKED,
				ref(scalar(yypvt[-3].opval), yypvt[-2].ival), scalar(yypvt[-0].opval)); } break;
case 65:
# line 324 "perly.y"
{ yyval.opval = newBINOP(yypvt[-2].ival, OPf_STACKED,
				ref(scalar(yypvt[-3].opval), yypvt[-2].ival), scalar(yypvt[-0].opval)); } break;
case 66:
# line 327 "perly.y"
{ yyval.opval = newLOGOP(OP_ANDASSIGN, 0,
				ref(scalar(yypvt[-3].opval), OP_ANDASSIGN),
				newUNOP(OP_SASSIGN, 0, scalar(yypvt[-0].opval))); } break;
case 67:
# line 331 "perly.y"
{ yyval.opval = newLOGOP(OP_ORASSIGN, 0,
				ref(scalar(yypvt[-3].opval), OP_ORASSIGN),
				newUNOP(OP_SASSIGN, 0, scalar(yypvt[-0].opval))); } break;
case 68:
# line 337 "perly.y"
{ yyval.opval = newBINOP(yypvt[-1].ival, 0, scalar(yypvt[-2].opval), scalar(yypvt[-0].opval)); } break;
case 69:
# line 339 "perly.y"
{   if (yypvt[-1].ival != OP_REPEAT)
				scalar(yypvt[-2].opval);
			    yyval.opval = newBINOP(yypvt[-1].ival, 0, yypvt[-2].opval, scalar(yypvt[-0].opval)); } break;
case 70:
# line 343 "perly.y"
{ yyval.opval = newBINOP(yypvt[-1].ival, 0, scalar(yypvt[-2].opval), scalar(yypvt[-0].opval)); } break;
case 71:
# line 345 "perly.y"
{ yyval.opval = newBINOP(yypvt[-1].ival, 0, scalar(yypvt[-2].opval), scalar(yypvt[-0].opval)); } break;
case 72:
# line 347 "perly.y"
{ yyval.opval = newBINOP(yypvt[-1].ival, 0, scalar(yypvt[-2].opval), scalar(yypvt[-0].opval)); } break;
case 73:
# line 349 "perly.y"
{ yyval.opval = newBINOP(yypvt[-1].ival, 0, scalar(yypvt[-2].opval), scalar(yypvt[-0].opval)); } break;
case 74:
# line 351 "perly.y"
{ yyval.opval = newBINOP(yypvt[-1].ival, 0, scalar(yypvt[-2].opval), scalar(yypvt[-0].opval)); } break;
case 75:
# line 353 "perly.y"
{ yyval.opval = newBINOP(yypvt[-1].ival, 0, scalar(yypvt[-2].opval), scalar(yypvt[-0].opval)); } break;
case 76:
# line 355 "perly.y"
{ yyval.opval = newRANGE(yypvt[-1].ival, scalar(yypvt[-2].opval), scalar(yypvt[-0].opval));} break;
case 77:
# line 357 "perly.y"
{ yyval.opval = newLOGOP(OP_AND, 0, yypvt[-2].opval, yypvt[-0].opval); } break;
case 78:
# line 359 "perly.y"
{ yyval.opval = newLOGOP(OP_OR, 0, yypvt[-2].opval, yypvt[-0].opval); } break;
case 79:
# line 361 "perly.y"
{ yyval.opval = newCONDOP(0, yypvt[-4].opval, yypvt[-2].opval, yypvt[-0].opval); } break;
case 80:
# line 363 "perly.y"
{ yyval.opval = bind_match(yypvt[-1].ival, yypvt[-2].opval, yypvt[-0].opval); } break;
case 81:
# line 365 "perly.y"
{ yyval.opval = yypvt[-0].opval; } break;
case 82:
# line 369 "perly.y"
{ yyval.opval = newUNOP(OP_NEGATE, 0, scalar(yypvt[-0].opval)); } break;
case 83:
# line 371 "perly.y"
{ yyval.opval = yypvt[-0].opval; } break;
case 84:
# line 373 "perly.y"
{ yyval.opval = newUNOP(OP_NOT, 0, scalar(yypvt[-0].opval)); } break;
case 85:
# line 375 "perly.y"
{ yyval.opval = newUNOP(OP_COMPLEMENT, 0, scalar(yypvt[-0].opval));} break;
case 86:
# line 377 "perly.y"
{ yyval.opval = newUNOP(OP_REFGEN, 0, ref(yypvt[-0].opval, OP_REFGEN)); } break;
case 87:
# line 379 "perly.y"
{ yyval.opval = newUNOP(OP_POSTINC, 0,
					ref(scalar(yypvt[-1].opval), OP_POSTINC)); } break;
case 88:
# line 382 "perly.y"
{ yyval.opval = newUNOP(OP_POSTDEC, 0,
					ref(scalar(yypvt[-1].opval), OP_POSTDEC)); } break;
case 89:
# line 385 "perly.y"
{ yyval.opval = newUNOP(OP_PREINC, 0,
					ref(scalar(yypvt[-0].opval), OP_PREINC)); } break;
case 90:
# line 388 "perly.y"
{ yyval.opval = newUNOP(OP_PREDEC, 0,
					ref(scalar(yypvt[-0].opval), OP_PREDEC)); } break;
case 91:
# line 391 "perly.y"
{ yyval.opval = localize(yypvt[-0].opval,yypvt[-1].ival); } break;
case 92:
# line 393 "perly.y"
{ yyval.opval = sawparens(yypvt[-1].opval); } break;
case 93:
# line 395 "perly.y"
{ yyval.opval = newNULLLIST(); } break;
case 94:
# line 397 "perly.y"
{ yyval.opval = newANONLIST(yypvt[-1].opval); } break;
case 95:
# line 399 "perly.y"
{ yyval.opval = newANONLIST(Nullop); } break;
case 96:
# line 401 "perly.y"
{ yyval.opval = newANONHASH(yypvt[-1].opval); } break;
case 97:
# line 403 "perly.y"
{ yyval.opval = newANONHASH(Nullop); } break;
case 98:
# line 405 "perly.y"
{ yyval.opval = yypvt[-0].opval; } break;
case 99:
# line 407 "perly.y"
{ yyval.opval = yypvt[-0].opval; } break;
case 100:
# line 409 "perly.y"
{ yyval.opval = newBINOP(OP_AELEM, 0, oopsAV(yypvt[-3].opval), scalar(yypvt[-1].opval)); } break;
case 101:
# line 411 "perly.y"
{ yyval.opval = newBINOP(OP_AELEM, 0,
					scalar(ref(newAVREF(yypvt[-4].opval),OP_RV2AV)),
					scalar(yypvt[-1].opval));} break;
case 102:
# line 415 "perly.y"
{ yyval.opval = yypvt[-0].opval; } break;
case 103:
# line 417 "perly.y"
{ yyval.opval = yypvt[-0].opval; } break;
case 104:
# line 419 "perly.y"
{ yyval.opval = newUNOP(OP_AV2ARYLEN, 0, ref(yypvt[-0].opval, OP_AV2ARYLEN));} break;
case 105:
# line 421 "perly.y"
{ yyval.opval = newBINOP(OP_HELEM, 0, oopsHV(yypvt[-4].opval), jmaybe(yypvt[-2].opval));
			    expect = XOPERATOR; } break;
case 106:
# line 424 "perly.y"
{ yyval.opval = newBINOP(OP_HELEM, 0,
					scalar(ref(newHVREF(yypvt[-5].opval),OP_RV2HV)),
					jmaybe(yypvt[-2].opval));
			    expect = XOPERATOR; } break;
case 107:
# line 429 "perly.y"
{ yyval.opval = newSLICEOP(0, yypvt[-1].opval, yypvt[-4].opval); } break;
case 108:
# line 431 "perly.y"
{ yyval.opval = newSLICEOP(0, yypvt[-1].opval, Nullop); } break;
case 109:
# line 433 "perly.y"
{ yyval.opval = prepend_elem(OP_ASLICE,
				newOP(OP_PUSHMARK, 0),
				list(
				    newLISTOP(OP_ASLICE, 0,
					list(yypvt[-1].opval),
					ref(yypvt[-3].opval, OP_ASLICE)))); } break;
case 110:
# line 440 "perly.y"
{ yyval.opval = prepend_elem(OP_HSLICE,
				newOP(OP_PUSHMARK, 0),
				list(
				    newLISTOP(OP_HSLICE, 0,
					list(yypvt[-2].opval),
					ref(oopsHV(yypvt[-4].opval), OP_HSLICE))));
			    expect = XOPERATOR; } break;
case 111:
# line 448 "perly.y"
{ yyval.opval = newBINOP(OP_DELETE, 0, oopsHV(yypvt[-4].opval), jmaybe(yypvt[-2].opval));
			    expect = XOPERATOR; } break;
case 112:
# line 451 "perly.y"
{ yyval.opval = newBINOP(OP_DELETE, 0, oopsHV(yypvt[-5].opval), jmaybe(yypvt[-3].opval));
			    expect = XOPERATOR; } break;
case 113:
# line 454 "perly.y"
{ yyval.opval = yypvt[-0].opval; } break;
case 114:
# line 456 "perly.y"
{ yyval.opval = newUNOP(OP_ENTERSUBR, 0,
				scalar(yypvt[-0].opval)); } break;
case 115:
# line 459 "perly.y"
{ yyval.opval = newUNOP(OP_ENTERSUBR, OPf_STACKED, scalar(yypvt[-2].opval)); } break;
case 116:
# line 461 "perly.y"
{ yyval.opval = newUNOP(OP_ENTERSUBR, OPf_STACKED,
			    list(prepend_elem(OP_LIST, scalar(yypvt[-3].opval), yypvt[-1].opval))); } break;
case 117:
# line 464 "perly.y"
{ yyval.opval = newUNOP(OP_DOFILE, 0, scalar(yypvt[-0].opval));
			  allgvs = TRUE;} break;
case 118:
# line 467 "perly.y"
{ yyval.opval = newUNOP(OP_NULL, OPf_SPECIAL, scope(yypvt[-0].opval)); } break;
case 119:
# line 469 "perly.y"
{ yyval.opval = newUNOP(OP_ENTERSUBR, OPf_SPECIAL|OPf_STACKED,
			    list(prepend_elem(OP_LIST,
				scalar(newCVREF(scalar(yypvt[-2].opval))), newNULLLIST()))); } break;
case 120:
# line 473 "perly.y"
{ yyval.opval = newUNOP(OP_ENTERSUBR, OPf_SPECIAL|OPf_STACKED,
			    list(prepend_elem(OP_LIST,
				scalar(newCVREF(scalar(yypvt[-3].opval))),
				yypvt[-1].opval))); } break;
case 121:
# line 478 "perly.y"
{ yyval.opval = newUNOP(OP_ENTERSUBR, OPf_SPECIAL|OPf_STACKED,
			    list(prepend_elem(OP_LIST,
				scalar(newCVREF(scalar(yypvt[-2].opval))), newNULLLIST())));} break;
case 122:
# line 482 "perly.y"
{ yyval.opval = newUNOP(OP_ENTERSUBR, OPf_SPECIAL|OPf_STACKED,
			    list(prepend_elem(OP_LIST,
				scalar(newCVREF(scalar(yypvt[-3].opval))),
				yypvt[-1].opval))); } break;
case 123:
# line 487 "perly.y"
{ yyval.opval = newOP(yypvt[-0].ival, OPf_SPECIAL); } break;
case 124:
# line 489 "perly.y"
{ yyval.opval = newPVOP(yypvt[-1].ival, 0,
				savestr(SvPVnx(((SVOP*)yypvt[-0].opval)->op_sv)));
			    op_free(yypvt[-0].opval); } break;
case 125:
# line 493 "perly.y"
{ yyval.opval = newOP(yypvt[-0].ival, 0); } break;
case 126:
# line 495 "perly.y"
{ yyval.opval = newUNOP(yypvt[-1].ival, 0, yypvt[-0].opval); } break;
case 127:
# line 497 "perly.y"
{ yyval.opval = newUNOP(yypvt[-1].ival, 0, yypvt[-0].opval); } break;
case 128:
# line 499 "perly.y"
{ yyval.opval = newOP(yypvt[-0].ival, 0); } break;
case 129:
# line 501 "perly.y"
{ yyval.opval = newOP(yypvt[-2].ival, 0); } break;
case 130:
# line 503 "perly.y"
{ yyval.opval = newOP(yypvt[-2].ival, OPf_SPECIAL); } break;
case 131:
# line 505 "perly.y"
{ yyval.opval = newUNOP(yypvt[-3].ival, 0, yypvt[-1].opval); } break;
case 132:
# line 507 "perly.y"
{ yyval.opval = pmruntime(yypvt[-3].opval, yypvt[-1].opval, Nullop); } break;
case 133:
# line 509 "perly.y"
{ yyval.opval = pmruntime(yypvt[-5].opval, yypvt[-3].opval, yypvt[-1].opval); } break;
case 136:
# line 515 "perly.y"
{ yyval.opval = newNULLLIST(); } break;
case 137:
# line 517 "perly.y"
{ yyval.opval = yypvt[-0].opval; } break;
case 138:
# line 521 "perly.y"
{ yyval.opval = newCVREF(yypvt[-0].opval); } break;
case 139:
# line 525 "perly.y"
{ yyval.opval = newSVREF(yypvt[-0].opval); } break;
case 140:
# line 529 "perly.y"
{ yyval.opval = newAVREF(yypvt[-0].opval); } break;
case 141:
# line 533 "perly.y"
{ yyval.opval = newHVREF(yypvt[-0].opval); } break;
case 142:
# line 537 "perly.y"
{ yyval.opval = newAVREF(yypvt[-0].opval); } break;
case 143:
# line 541 "perly.y"
{ yyval.opval = newGVREF(yypvt[-0].opval); } break;
case 144:
# line 545 "perly.y"
{ yyval.opval = scalar(yypvt[-0].opval); } break;
case 145:
# line 547 "perly.y"
{ yyval.opval = scalar(yypvt[-0].opval); } break;
case 146:
# line 549 "perly.y"
{ yyval.opval = scalar(scope(yypvt[-0].opval)); } break;
case 147:
# line 552 "perly.y"
{ yyval.opval = yypvt[-0].opval; } break;
case 148:
# line 556 "perly.y"
{ yyval.ival = 1; } break;
case 149:
# line 558 "perly.y"
{ yyval.ival = 0; } break;
case 150:
# line 562 "perly.y"
{ yyval.ival = 1; } break;
case 151:
# line 564 "perly.y"
{ yyval.ival = 0; } break;
case 152:
# line 568 "perly.y"
{ yyval.ival = 1; } break;
case 153:
# line 570 "perly.y"
{ yyval.ival = 0; } break;
	}
	goto yystack;		/* reset registers in driver code */
}
