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
# define LABEL 261
# define FORMAT 262
# define SUB 263
# define PACKAGE 264
# define WHILE 265
# define UNTIL 266
# define IF 267
# define UNLESS 268
# define ELSE 269
# define ELSIF 270
# define CONTINUE 271
# define FOR 272
# define LOOPEX 273
# define DOTDOT 274
# define FUNC0 275
# define FUNC1 276
# define FUNC 277
# define RELOP 278
# define EQOP 279
# define MULOP 280
# define ADDOP 281
# define DOLSHARP 282
# define DO 283
# define LOCAL 284
# define DELETE 285
# define HASHBRACK 286
# define LSTOP 287
# define OROR 288
# define ANDAND 289
# define BITOROP 290
# define BITANDOP 291
# define UNIOP 292
# define SHIFTOP 293
# define MATCHOP 294
# define ARROW 295
# define UMINUS 296
# define REFGEN 297
# define POWOP 298
# define PREINC 299
# define PREDEC 300
# define POSTINC 301
# define POSTDEC 302
#define yyclearin yychar = -1
#define yyerrok yyerrflag = 0
extern int yychar;
extern int yyerrflag;
#ifndef YYMAXDEPTH
#define YYMAXDEPTH 150
#endif
YYSTYPE yylval, yyval;
# define YYERRCODE 256

# line 569 "perly.y"
 /* PROGRAM */
int yyexca[] ={
-1, 1,
	0, -1,
	-2, 0,
-1, 3,
	0, 2,
	-2, 39,
-1, 21,
	295, 145,
	-2, 25,
-1, 40,
	41, 97,
	265, 97,
	266, 97,
	267, 97,
	268, 97,
	274, 97,
	278, 97,
	279, 97,
	280, 97,
	281, 97,
	44, 97,
	61, 97,
	63, 97,
	58, 97,
	288, 97,
	289, 97,
	290, 97,
	291, 97,
	293, 97,
	294, 97,
	295, 97,
	298, 97,
	301, 97,
	302, 97,
	59, 97,
	93, 97,
	-2, 144,
-1, 54,
	41, 133,
	265, 133,
	266, 133,
	267, 133,
	268, 133,
	274, 133,
	278, 133,
	279, 133,
	280, 133,
	281, 133,
	44, 133,
	61, 133,
	63, 133,
	58, 133,
	288, 133,
	289, 133,
	290, 133,
	291, 133,
	293, 133,
	294, 133,
	295, 133,
	298, 133,
	301, 133,
	302, 133,
	59, 133,
	93, 133,
	-2, 143,
-1, 76,
	59, 35,
	-2, 0,
-1, 112,
	301, 0,
	302, 0,
	-2, 88,
-1, 113,
	301, 0,
	302, 0,
	-2, 89,
-1, 192,
	278, 0,
	-2, 71,
-1, 193,
	279, 0,
	-2, 72,
-1, 194,
	274, 0,
	-2, 75,
-1, 310,
	41, 35,
	-2, 0,
	};
# define YYNPROD 152
# define YYLAST 2258
int yyact[]={

   107,   162,   104,   105,    90,   102,   229,   103,   148,    90,
    21,   239,    67,   104,   105,   150,   228,    91,    25,    72,
    74,   240,   241,    80,    82,    78,    91,    92,    56,    31,
    26,   102,    56,    58,    61,    90,    37,   132,    57,    30,
   102,    29,    69,    68,    90,   244,   115,   117,   119,   129,
    98,   133,    91,    92,   324,    16,   155,    77,    91,    92,
    59,    14,    11,    12,    13,    93,   102,   152,    87,   153,
    90,    93,   102,   157,   317,   159,    90,   315,   198,   164,
   156,   166,   158,   168,   298,   161,   297,    38,   165,   296,
   167,   262,   169,   170,   171,   172,   202,   210,    26,   200,
   268,   215,   123,   220,    31,    81,    87,    56,    58,    61,
   199,    37,   121,    57,    30,    26,    29,    87,   258,    26,
    79,   203,    32,    73,     3,   310,    98,    99,    91,    92,
   211,   212,   213,   214,   124,    59,   218,    98,    99,    91,
    92,    93,   102,    71,   122,   223,    90,    97,    96,    95,
    94,   237,    93,   102,   121,   316,   154,    90,    87,    70,
    87,    87,    38,    87,    66,    87,   295,    31,    87,   235,
    56,    58,    61,   318,    37,   299,    57,    30,   293,    29,
   243,    14,    11,    12,    13,   327,   122,   325,    26,    98,
    99,    91,    92,    87,    26,   204,    87,    32,    59,   320,
    96,    95,    94,    26,    93,   102,    26,   255,   256,    90,
   292,   266,   259,   174,   265,   232,    87,   234,   314,   304,
    98,    99,    91,    92,   267,    38,    26,   323,   271,   273,
    87,   264,   281,    94,   282,    93,   102,   284,   278,   286,
    90,   287,   263,   289,   206,   197,   156,    56,   202,   139,
   207,   200,    24,    54,    65,    46,    53,    26,   231,   221,
    32,    18,    19,    22,    23,   209,    56,   294,    20,    49,
   126,    51,    52,    63,   288,   280,   254,   300,    60,    48,
    36,    45,    39,    62,   308,   101,   219,   160,    50,    85,
    86,    83,    84,    33,   285,    34,    35,   312,   311,   274,
   242,   313,    87,    87,   238,   233,    31,    87,    87,    56,
    58,    61,   322,    37,   272,    57,    30,   149,    29,    25,
    85,    86,    83,    84,   326,   201,   328,    24,    54,    65,
    46,    53,    56,   137,   136,   135,    76,    59,   329,   306,
   307,   127,   309,     8,    49,     7,    51,    52,    63,   163,
     2,     9,    55,    60,    48,    36,    45,    39,    62,    17,
    47,    41,    44,    50,    38,    42,   321,    43,    33,    31,
    34,    35,    56,    58,    61,    15,    37,   270,    57,    30,
    10,    29,     5,   208,   205,    88,     6,     4,   147,     1,
     0,    54,    65,    46,    53,     0,    26,     0,     0,    32,
    59,     0,     0,     0,     0,     0,     0,    49,     0,    51,
    52,    63,     0,     0,     0,    28,    60,    48,    36,    45,
    39,    62,     0,     0,     0,     0,    50,    38,     0,   150,
     0,    33,    31,    34,    35,    56,    58,    61,     0,    37,
     0,    57,    30,     0,    29,   106,   108,   109,   110,   111,
   112,   113,    98,    99,    91,    92,     0,     0,   261,    26,
     0,     0,    32,    59,    95,    94,     0,    93,   102,     0,
     0,     0,    90,     0,     0,     0,    31,     0,     0,    56,
    58,    61,     0,    37,     0,    57,    30,   236,    29,     0,
    38,     0,     0,     0,     0,     0,   100,     0,     0,     0,
    98,    99,    91,    92,     0,     0,     0,    59,     0,     0,
    97,    96,    95,    94,     0,    93,   102,     0,     0,     0,
    90,   275,    26,     0,   276,    32,     0,     0,     0,     0,
    54,    65,    46,    53,    38,   225,   260,     0,   227,     0,
   230,    89,     0,   101,   269,     0,    49,     0,    51,    52,
    63,     0,     0,     0,     0,    60,    48,    36,    45,    39,
    62,   283,     0,     0,     0,    50,    26,     0,     0,    32,
    33,    31,    34,    35,    56,    58,    61,     0,    37,   257,
    57,    30,     0,    29,     0,     0,     0,     0,     0,     0,
     0,     0,     0,    54,    65,    46,    53,   301,     0,   302,
     0,     0,    59,     0,     0,     0,     0,     0,     0,    49,
     0,    51,    52,    63,     0,   277,     0,   279,    60,    48,
    36,    45,    39,    62,   319,     0,     0,     0,    50,    38,
     0,     0,     0,    33,     0,    34,    35,     0,     0,     0,
     0,     0,     0,   291,    89,     0,   101,     0,     0,     0,
     0,    64,     0,     0,     0,     0,    54,    65,    46,    53,
     0,    26,     0,     0,    32,     0,     0,     0,     0,   305,
     0,     0,    49,     0,    51,    52,    63,     0,     0,     0,
     0,    60,    48,    36,    45,    39,    62,    89,     0,   101,
     0,    50,     0,     0,     0,     0,    33,     0,    34,    35,
    54,    65,    46,    53,     0,     0,     0,     0,   138,   141,
   142,   143,   144,   145,   146,     0,    49,   151,    51,    52,
    63,     0,     0,     0,     0,    60,    48,    36,    45,    39,
    62,     0,     0,     0,     0,    50,     0,     0,     0,     0,
    33,    31,    34,    35,    56,    58,    61,     0,    37,   222,
    57,    30,     0,    29,   100,     0,     0,     0,    98,    99,
    91,    92,     0,     0,     0,     0,     0,     0,    97,    96,
    95,    94,    59,    93,   102,     0,     0,     0,    90,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,    54,    65,    46,    53,    38,
     0,   226,     0,     0,     0,     0,     0,     0,     0,     0,
     0,    49,     0,    51,    52,    63,     0,     0,     0,     0,
    60,    48,    36,    45,    39,    62,     0,     0,     0,     0,
    50,    26,     0,     0,    32,    33,    31,    34,    35,    56,
    58,    61,     0,    37,   217,    57,    30,     0,    29,     0,
     0,     0,     0,     0,     0,     0,     0,   100,     0,     0,
     0,    98,    99,    91,    92,     0,     0,    59,     0,     0,
     0,    97,    96,    95,    94,     0,    93,   102,     0,     0,
    31,    90,     0,    56,    58,    61,     0,    37,     0,    57,
    30,     0,    29,     0,    38,     0,     0,     0,     0,     0,
   100,     0,     0,     0,    98,    99,    91,    92,   190,     0,
     0,    59,     0,     0,    97,    96,    95,    94,     0,    93,
   102,     0,     0,     0,    90,     0,    26,     0,     0,    32,
    31,     0,     0,    56,    58,    61,     0,    37,    38,    57,
    30,     0,    29,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,   188,     0,
     0,    59,     0,     0,     0,    54,    65,    46,    53,     0,
    26,     0,     0,    32,     0,     0,     0,     0,     0,     0,
     0,    49,     0,    51,    52,    63,     0,     0,    38,     0,
    60,    48,    36,    45,    39,    62,     0,     0,     0,     0,
    50,     0,     0,     0,     0,    33,    31,    34,    35,    56,
    58,    61,     0,    37,     0,    57,    30,     0,    29,     0,
    26,     0,     0,    32,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,   186,     0,     0,    59,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
    54,    65,    46,    53,    38,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,    49,     0,    51,    52,
    63,     0,     0,     0,     0,    60,    48,    36,    45,    39,
    62,     0,     0,     0,     0,    50,    26,     0,     0,    32,
    33,     0,    34,    35,    54,    65,    46,    53,     0,    31,
     0,     0,    56,    58,    61,     0,    37,     0,    57,    30,
    49,    29,    51,    52,    63,     0,     0,     0,     0,    60,
    48,    36,    45,    39,    62,     0,     0,   184,     0,    50,
    59,     0,     0,     0,    33,     0,    34,    35,     0,     0,
     0,     0,     0,     0,    54,    65,    46,    53,     0,     0,
     0,     0,     0,     0,     0,     0,     0,    38,     0,     0,
    49,     0,    51,    52,    63,     0,     0,     0,     0,    60,
    48,    36,    45,    39,    62,     0,     0,     0,     0,    50,
     0,     0,     0,     0,    33,     0,    34,    35,     0,    26,
     0,     0,    32,     0,     0,     0,    31,     0,     0,    56,
    58,    61,     0,    37,     0,    57,    30,     0,    29,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
    54,    65,    46,    53,   182,     0,     0,    59,     0,     0,
     0,     0,     0,     0,     0,     0,    49,     0,    51,    52,
    63,     0,     0,     0,    40,    60,    48,    36,    45,    39,
    62,     0,     0,     0,    38,    50,     0,     0,     0,     0,
    33,     0,    34,    35,    31,    75,     0,    56,    58,    61,
     0,    37,     0,    57,    30,     0,    29,     0,     0,     0,
     0,     0,     0,     0,     0,     0,    26,     0,     0,    32,
   125,     0,   180,   131,     0,    59,     0,     0,     0,     0,
     0,   140,   140,   140,   140,   140,   140,     0,     0,    31,
   140,     0,    56,    58,    61,     0,    37,     0,    57,    30,
     0,    29,    38,    54,    65,    46,    53,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,   178,     0,    49,
    59,    51,    52,    63,     0,     0,     0,     0,    60,    48,
    36,    45,    39,    62,    26,     0,     0,    32,    50,     0,
     0,     0,     0,    33,     0,    34,    35,    38,     0,     0,
     0,   216,     0,     0,     0,    31,     0,     0,    56,    58,
    61,     0,    37,     0,    57,    30,     0,    29,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,    26,
     0,     0,    32,   176,     0,     0,    59,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
    54,    65,    46,    53,     0,     0,     0,     0,     0,     0,
     0,     0,     0,    38,     0,     0,    49,     0,    51,    52,
    63,     0,     0,     0,     0,    60,    48,    36,    45,    39,
    62,     0,     0,     0,     0,    50,   253,     0,     0,    89,
    33,   101,    34,    35,     0,    26,     0,     0,    32,     0,
     0,     0,     0,     0,    31,     0,     0,    56,    58,    61,
     0,    37,     0,    57,    30,     0,    29,     0,    54,    65,
    46,    53,     0,     0,     0,     0,     0,     0,     0,     0,
   120,     0,     0,     0,    49,    59,    51,    52,    63,     0,
     0,     0,     0,    60,    48,    36,    45,    39,    62,     0,
     0,     0,     0,    50,     0,     0,     0,     0,    33,     0,
    34,    35,    38,    54,    65,    46,    53,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,    49,
     0,    51,    52,    63,     0,     0,     0,     0,    60,    48,
    36,    45,    39,    62,    26,     0,     0,    32,    50,     0,
     0,     0,     0,    33,     0,    34,    35,    31,     0,     0,
    56,    58,    61,     0,    37,     0,    57,    30,     0,    29,
     0,     0,     0,     0,     0,     0,     0,     0,     0,    54,
    65,    46,    53,     0,     0,     0,     0,     0,    59,     0,
     0,     0,     0,     0,     0,    49,     0,    51,    52,    63,
     0,     0,     0,     0,    60,    48,    36,    45,    39,    62,
     0,     0,     0,     0,    50,    38,     0,   118,     0,    33,
     0,    34,    35,     0,    31,     0,     0,    56,    58,    61,
     0,    37,   116,    57,    30,     0,    29,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,    26,     0,     0,
    32,     0,   100,     0,     0,    59,    98,    99,    91,    92,
     0,     0,     0,     0,     0,     0,    97,    96,    95,    94,
     0,    93,   102,     0,     0,     0,    90,     0,    54,    65,
    46,    53,    38,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,    49,     0,    51,    52,    63,     0,
     0,     0,     0,    60,    48,    36,    45,    39,    62,     0,
     0,     0,     0,    50,    26,     0,     0,    32,    33,     0,
    34,    35,    31,     0,     0,    56,    58,    61,     0,    37,
     0,    57,    30,     0,    29,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,    59,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,    31,     0,     0,
    56,    58,    61,     0,    37,     0,    57,    30,     0,    29,
    38,    54,    65,    46,    53,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,    49,    59,    51,
    52,    63,     0,     0,     0,     0,    60,    48,    36,    45,
    39,    62,    26,     0,     0,    32,    50,     0,     0,     0,
     0,    33,     0,    34,    35,    38,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,    54,    65,
    46,    53,     0,     0,     0,     0,     0,    26,     0,     0,
    32,     0,     0,     0,    49,     0,    51,    52,    63,     0,
     0,     0,     0,    60,    48,    36,    45,    39,    62,     0,
     0,     0,     0,    50,     0,     0,     0,     0,    33,     0,
    34,    35,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,    54,    65,    46,    53,
    27,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,    49,     0,    51,    52,    63,     0,     0,     0,
     0,    60,    48,    36,    45,    39,    62,     0,     0,     0,
     0,    50,     0,     0,     0,     0,    33,   114,    34,    35,
     0,   130,    65,    46,    53,     0,     0,     0,     0,   128,
     0,   134,     0,     0,     0,     0,     0,    49,     0,    51,
    52,    63,     0,     0,     0,     0,    60,    48,    36,    45,
    39,    62,     0,     0,     0,     0,    50,     0,     0,     0,
     0,    33,     0,    34,    35,     0,     0,     0,   173,     0,
   175,   177,   179,   181,   183,   185,   187,   189,   191,   192,
   193,   194,   195,   196,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,   224,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,   245,     0,   246,
     0,   247,     0,   248,     0,   249,     0,   250,     0,   251,
     0,   252,     0,     0,     0,     0,     0,     0,     0,     0,
     0,   173,     0,     0,     0,   173,     0,     0,   173,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,   290,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,   303 };
int yypact[]={

 -1000, -1000, -1000,  -200, -1000, -1000, -1000, -1000, -1000,    -4,
 -1000,   -93,  -214,  -215, -1000, -1000, -1000,   100,   103,    83,
   296,  -246,    80,    65, -1000,    24, -1000,   626,  -288,  1719,
  1719,  1719,  1719,  1719,  1719,  1719,  1719,  1621,  1554,  1451,
    21, -1000, -1000,    11, -1000,   230, -1000,   301,  1764,  -220,
  1719,   295,   294,   293, -1000, -1000,    -8,    -8,    -8,    -8,
    -8,    -8,  1719,   277,  -280,    -8,   -25, -1000,   -25,    97,
 -1000,  1719,   -25,  1719,   -25,   247,    71, -1000,   -25,  1719,
   -25,  1719,   -25,  1719,  1719,  1719,  1719,  1719, -1000,  1719,
  1352,  1286,  1241,  1173,  1076,   973,   897,   847,  1719,  1719,
  1719,  1719,  1719,   -13, -1000, -1000,  -299, -1000,  -299,  -299,
  -299,  -299, -1000, -1000,  -222,   207,    30,   151, -1000,   206,
   -28,  1719,  1719,  1719,  1719,   -22,   211,   803,  -222, -1000,
   246,    63, -1000, -1000,  -222,   218,   708,  1719, -1000, -1000,
 -1000, -1000, -1000, -1000, -1000, -1000,   134, -1000,   124,  1719,
  -271,  1719, -1000, -1000, -1000,   217,   124,  -246,   264,  -246,
  1719,    55,    92, -1000, -1000,   263,  -248,   259,  -248,   124,
   124,   124,   124,   626,   -80,   626,  1719,  -294,  1719,  -289,
  1719,  -263,  1719,  -254,  1719,  -152,  1719,   -58,  1719,   174,
  1719,   -89,  -222,  -228,  -141,  1408,  -294,   236,  1719,  1719,
   538,    27, -1000,  1719,   443, -1000, -1000,   399, -1000,   -34,
 -1000,   149,   172,   121,   152,  1719,   -23, -1000,   207,   336,
   273, -1000, -1000,   258,   480, -1000,   134,   197,  1719,   235,
 -1000,   -25, -1000,   -25, -1000,   207,   -25,  1719,   -25, -1000,
   -25,   234,   -25, -1000, -1000,   626,   626,   626,   626,   626,
   626,   626,   626,  1719,  1719,   117,   119, -1000,  1719,    73,
 -1000,   -36, -1000, -1000,   -39, -1000,   -41,   116,  1719, -1000,
 -1000,   207, -1000,   207, -1000, -1000,  1719,   178, -1000, -1000,
  1719,  -246,  -246,   -25,  -246,    66,  -248, -1000,  1719,  -248,
   222,   177, -1000,   -48,    62, -1000, -1000, -1000, -1000,   -51,
   114, -1000, -1000,   583, -1000,   158, -1000, -1000,  -246, -1000,
    71, -1000,   186, -1000, -1000, -1000, -1000, -1000,   -71, -1000,
 -1000, -1000,   146,   -25,   144,   -25,  -248, -1000, -1000, -1000 };
int yypgo[]={

     0,   389,   387,   386,   385,   325,   384,   383,     0,   124,
   382,   380,   375,     1,    11,     8,  1980,   415,  1254,   367,
   365,   362,   361,   360,   349,   388,   651,    56,   352,   351,
    57,   350,   345,   343 };
int yyr1[]={

     0,    31,     1,     8,     4,     9,     9,     9,    10,    10,
    10,    10,    24,    24,    24,    24,    24,    24,    14,    14,
    14,    12,    12,    12,    12,    30,    30,    11,    11,    11,
    11,    11,    11,    11,    11,    13,    13,    27,    27,    29,
    29,     2,     2,     2,     3,     3,    32,    33,    15,    15,
    28,    28,    28,    28,    28,    28,    28,    28,    16,    16,
    16,    16,    16,    16,    16,    16,    16,    16,    16,    16,
    16,    16,    16,    16,    16,    16,    16,    16,    16,    16,
    16,    17,    17,    17,    17,    17,    17,    17,    17,    17,
    17,    17,    17,    17,    17,    17,    17,    17,    17,    17,
    17,    17,    17,    17,    17,    17,    17,    17,    17,    17,
    17,    17,    17,    17,    17,    17,    17,    17,    17,    17,
    17,    17,    17,    17,    17,    17,    17,    17,    17,    17,
    17,    17,    17,    17,    17,    25,    25,    23,    18,    19,
    20,    21,    22,    26,    26,    26,     5,     5,     6,     6,
     7,     7 };
int yyr2[]={

     0,     1,     5,     9,     1,     1,     5,     5,     5,     2,
     5,     7,     3,     3,     7,     7,     7,     7,     1,     5,
    13,    13,    13,     9,     9,     1,     5,    15,    15,    11,
    11,    17,    15,    21,     7,     1,     2,     1,     2,     1,
     2,     3,     3,     3,     7,     5,     7,     7,     7,     2,
     7,    11,     9,    13,    13,     7,     5,     9,     7,     9,
     9,     9,     9,     9,     9,     9,     9,     7,     7,     7,
     7,     7,     7,     7,     7,     7,     7,     7,    11,     7,
     3,     5,     5,     5,     5,     5,     5,     5,     5,     5,
     5,     7,     5,     7,     5,     7,     7,     3,     3,     9,
    11,     3,     3,     3,    11,    13,    13,    11,     9,    11,
    13,    17,     3,     3,     7,     9,     5,     5,     9,    11,
     9,    11,     3,     5,     3,     5,     5,     3,     7,     7,
     9,     9,    13,     2,     2,     1,     3,     5,     5,     5,
     5,     5,     5,     3,     3,     3,     5,     3,     5,     3,
     7,     5 };
int yychk[]={

 -1000,    -1,   -31,    -9,    -2,   -10,    -3,   -32,   -33,   -29,
   -11,   262,   263,   264,   261,   -12,    59,   -24,   265,   266,
   272,    -8,   267,   268,   256,   -15,   123,   -16,   -17,    45,
    43,    33,   126,   297,   299,   300,   284,    40,    91,   286,
   -18,   -22,   -20,   -19,   -21,   285,   259,   -23,   283,   273,
   292,   275,   276,   260,   257,   -28,    36,    42,    37,    64,
   282,    38,   287,   277,   -26,   258,   257,    -8,   257,   257,
    59,    40,    -8,    40,    -8,   -18,    40,   -30,   271,    40,
    -8,    40,    -8,   267,   268,   265,   266,    44,    -4,    61,
   298,   280,   281,   293,   291,   290,   289,   288,   278,   279,
   274,    63,   294,   295,   301,   302,   -17,    -8,   -17,   -17,
   -17,   -17,   -17,   -17,   -16,   -15,    41,   -15,    93,   -15,
    59,    91,   123,    91,   123,   -18,    40,    40,   -16,    -8,
   257,   -18,   257,    -8,   -16,    40,    40,    40,   -26,   257,
   -18,   -26,   -26,   -26,   -26,   -26,   -26,   -25,   -15,    40,
   295,   -26,    -8,    -8,    59,   -27,   -15,    -8,   -15,    -8,
    40,   -15,   -13,   -24,    -8,   -15,    -8,   -15,    -8,   -15,
   -15,   -15,   -15,   -16,    -9,   -16,    61,   -16,    61,   -16,
    61,   -16,    61,   -16,    61,   -16,    61,   -16,    61,   -16,
    61,   -16,   -16,   -16,   -16,   -16,   -16,   258,    91,   123,
    44,    -5,    41,    91,    44,    -6,    93,    44,    -7,    59,
   125,   -15,   -15,   -15,   -15,   123,   -18,    41,   -15,    40,
    40,    41,    41,   -15,   -16,   -25,   -26,   -25,   287,   277,
   -25,    41,   -30,    41,   -30,   -15,    -5,    59,    41,   -14,
   269,   270,    41,   -14,   125,   -16,   -16,   -16,   -16,   -16,
   -16,   -16,   -16,    58,    40,   -15,   -15,    41,    91,   -15,
    93,    59,   125,    93,    59,    93,    59,   -15,   123,    -5,
    41,   -15,    41,   -15,    41,    41,    44,   -25,    41,   -25,
    40,    -8,    -8,    -5,    -8,   -27,    -8,    -8,    40,    -8,
   -16,   -25,    93,    59,   -15,    93,   125,   125,   125,    59,
   -15,    -5,    -5,   -16,    41,   -25,   -30,   -30,    -8,   -30,
    59,   -14,   -15,   -14,    41,   125,    93,   125,    59,    41,
    41,   -30,   -13,    41,   125,    41,    -8,    41,    -8,   -14 };
int yydef[]={

     1,    -2,     5,    -2,     6,     7,    41,    42,    43,     0,
     9,     0,     0,     0,    40,     8,    10,     0,     0,     0,
     0,    -2,     0,     0,    12,    13,     4,    49,    80,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
    -2,    98,   101,   102,   103,     0,   112,   113,     0,   122,
   124,   127,     0,     0,    -2,   134,     0,     0,     0,     0,
     0,     0,   135,     0,     0,     0,     0,    45,     0,     0,
    11,    37,     0,     0,     0,     0,    -2,    34,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     5,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,    86,    87,    81,   145,    82,    83,
    84,    85,    -2,    -2,    90,     0,    92,     0,    94,     0,
     0,     0,     0,     0,     0,     0,     0,     0,   116,   117,
   133,    97,   123,   125,   126,     0,     0,     0,   138,   143,
   144,   142,   140,   139,   141,   137,   135,    56,   136,   135,
     0,   135,    44,    46,    47,     0,    38,    25,     0,    25,
     0,    13,     0,    36,    26,     0,    18,     0,    18,    14,
    15,    16,    17,    48,    39,    58,     0,    67,     0,    68,
     0,    69,     0,    70,     0,    73,     0,    74,     0,    76,
     0,    77,    -2,    -2,    -2,     0,    79,     0,     0,     0,
     0,    91,   147,     0,     0,    93,   149,     0,    95,     0,
    96,     0,     0,     0,     0,     0,     0,   114,     0,     0,
     0,   128,   129,     0,     0,    50,   135,     0,   135,     0,
    55,     0,    29,     0,    30,     0,     0,    37,     0,    23,
     0,     0,     0,    24,     3,    59,    60,    61,    62,    63,
    64,    65,    66,     0,   135,     0,     0,   146,     0,     0,
   148,     0,   151,    99,     0,   108,     0,     0,     0,   115,
   118,     0,   120,     0,   130,   131,     0,     0,    57,    52,
   135,    25,    25,     0,    25,     0,    18,    19,     0,    18,
    78,     0,   100,     0,     0,   107,   150,   104,   109,     0,
     0,   119,   121,     0,    51,     0,    27,    28,    25,    32,
    -2,    21,     0,    22,    54,   105,   106,   110,     0,   132,
    53,    31,     0,     0,     0,     0,    18,   111,    33,    20 };
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
	"LABEL",	261,
	"FORMAT",	262,
	"SUB",	263,
	"PACKAGE",	264,
	"WHILE",	265,
	"UNTIL",	266,
	"IF",	267,
	"UNLESS",	268,
	"ELSE",	269,
	"ELSIF",	270,
	"CONTINUE",	271,
	"FOR",	272,
	"LOOPEX",	273,
	"DOTDOT",	274,
	"FUNC0",	275,
	"FUNC1",	276,
	"FUNC",	277,
	"RELOP",	278,
	"EQOP",	279,
	"MULOP",	280,
	"ADDOP",	281,
	"DOLSHARP",	282,
	"DO",	283,
	"LOCAL",	284,
	"DELETE",	285,
	"HASHBRACK",	286,
	"LSTOP",	287,
	",",	44,
	"=",	61,
	"?",	63,
	":",	58,
	"OROR",	288,
	"ANDAND",	289,
	"BITOROP",	290,
	"BITANDOP",	291,
	"UNIOP",	292,
	"SHIFTOP",	293,
	"MATCHOP",	294,
	"ARROW",	295,
	"!",	33,
	"~",	126,
	"UMINUS",	296,
	"REFGEN",	297,
	"POWOP",	298,
	"PREINC",	299,
	"PREDEC",	300,
	"POSTINC",	301,
	"POSTDEC",	302,
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
				main_root = block_head(scalar(yypvt[-0].opval), &main_start);
			} break;
case 3:
# line 119 "perly.y"
{ yyval.opval = scalarseq(yypvt[-1].opval);
			  if (copline > (line_t)yypvt[-3].ival)
			      copline = yypvt[-3].ival;
			  if (savestack_ix > yypvt[-2].ival)
			    leave_scope(yypvt[-2].ival);
			  expect = XBLOCK; } break;
case 4:
# line 128 "perly.y"
{ yyval.ival = savestack_ix; } break;
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
{ yyval.opval = newLOOPOP(0, 1, scalar(yypvt[-0].opval), yypvt[-2].opval, Nullop); } break;
case 17:
# line 167 "perly.y"
{ yyval.opval = newLOOPOP(0, 1, invert(scalar(yypvt[-0].opval)), yypvt[-2].opval, Nullop);} break;
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
# line 276 "perly.y"
{ yyval.opval = append_elem(OP_LIST, yypvt[-2].opval, yypvt[-0].opval); } break;
case 50:
# line 281 "perly.y"
{ yyval.opval = convert(yypvt[-2].ival, OPf_STACKED,
				prepend_elem(OP_LIST, newGVREF(yypvt[-1].opval), yypvt[-0].opval) ); } break;
case 51:
# line 284 "perly.y"
{ yyval.opval = convert(yypvt[-4].ival, OPf_STACKED,
				prepend_elem(OP_LIST, newGVREF(yypvt[-2].opval), yypvt[-1].opval) ); } break;
case 52:
# line 287 "perly.y"
{ yyval.opval = convert(yypvt[-1].ival, OPf_STACKED,
				prepend_elem(OP_LIST, newGVREF(yypvt[-3].opval), yypvt[-0].opval) ); } break;
case 53:
# line 290 "perly.y"
{ yyval.opval = convert(yypvt[-3].ival, OPf_STACKED,
				prepend_elem(OP_LIST, newGVREF(yypvt[-5].opval), yypvt[-1].opval) ); } break;
case 54:
# line 293 "perly.y"
{ yyval.opval = convert(OP_ENTERSUBR, OPf_STACKED|OPf_SPECIAL,
				prepend_elem(OP_LIST, newMETHOD(yypvt[-5].opval,yypvt[-3].opval), yypvt[-1].opval)); } break;
case 55:
# line 296 "perly.y"
{ yyval.opval = convert(OP_ENTERSUBR, OPf_STACKED|OPf_SPECIAL,
				prepend_elem(OP_LIST, newMETHOD(yypvt[-1].opval,yypvt[-2].opval), yypvt[-0].opval)); } break;
case 56:
# line 299 "perly.y"
{ yyval.opval = convert(yypvt[-1].ival, 0, yypvt[-0].opval); } break;
case 57:
# line 301 "perly.y"
{ yyval.opval = convert(yypvt[-3].ival, 0, yypvt[-1].opval); } break;
case 58:
# line 305 "perly.y"
{ yyval.opval = newASSIGNOP(OPf_STACKED, yypvt[-2].opval, yypvt[-0].opval); } break;
case 59:
# line 307 "perly.y"
{ yyval.opval = newBINOP(yypvt[-2].ival, OPf_STACKED,
				ref(scalar(yypvt[-3].opval), yypvt[-2].ival), scalar(yypvt[-0].opval)); } break;
case 60:
# line 310 "perly.y"
{ yyval.opval = newBINOP(yypvt[-2].ival, OPf_STACKED,
				ref(scalar(yypvt[-3].opval), yypvt[-2].ival), scalar(yypvt[-0].opval)); } break;
case 61:
# line 313 "perly.y"
{ yyval.opval = newBINOP(yypvt[-2].ival, OPf_STACKED,
				ref(scalar(yypvt[-3].opval), yypvt[-2].ival), scalar(yypvt[-0].opval));} break;
case 62:
# line 316 "perly.y"
{ yyval.opval = newBINOP(yypvt[-2].ival, OPf_STACKED,
				ref(scalar(yypvt[-3].opval), yypvt[-2].ival), scalar(yypvt[-0].opval)); } break;
case 63:
# line 319 "perly.y"
{ yyval.opval = newBINOP(yypvt[-2].ival, OPf_STACKED,
				ref(scalar(yypvt[-3].opval), yypvt[-2].ival), scalar(yypvt[-0].opval)); } break;
case 64:
# line 322 "perly.y"
{ yyval.opval = newBINOP(yypvt[-2].ival, OPf_STACKED,
				ref(scalar(yypvt[-3].opval), yypvt[-2].ival), scalar(yypvt[-0].opval)); } break;
case 65:
# line 325 "perly.y"
{ yyval.opval = newLOGOP(OP_ANDASSIGN, 0,
				ref(scalar(yypvt[-3].opval), OP_ANDASSIGN),
				newUNOP(OP_SASSIGN, 0, scalar(yypvt[-0].opval))); } break;
case 66:
# line 329 "perly.y"
{ yyval.opval = newLOGOP(OP_ORASSIGN, 0,
				ref(scalar(yypvt[-3].opval), OP_ORASSIGN),
				newUNOP(OP_SASSIGN, 0, scalar(yypvt[-0].opval))); } break;
case 67:
# line 335 "perly.y"
{ yyval.opval = newBINOP(yypvt[-1].ival, 0, scalar(yypvt[-2].opval), scalar(yypvt[-0].opval)); } break;
case 68:
# line 337 "perly.y"
{   if (yypvt[-1].ival != OP_REPEAT)
				scalar(yypvt[-2].opval);
			    yyval.opval = newBINOP(yypvt[-1].ival, 0, yypvt[-2].opval, scalar(yypvt[-0].opval)); } break;
case 69:
# line 341 "perly.y"
{ yyval.opval = newBINOP(yypvt[-1].ival, 0, scalar(yypvt[-2].opval), scalar(yypvt[-0].opval)); } break;
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
{ yyval.opval = newRANGE(yypvt[-1].ival, scalar(yypvt[-2].opval), scalar(yypvt[-0].opval));} break;
case 76:
# line 355 "perly.y"
{ yyval.opval = newLOGOP(OP_AND, 0, yypvt[-2].opval, yypvt[-0].opval); } break;
case 77:
# line 357 "perly.y"
{ yyval.opval = newLOGOP(OP_OR, 0, yypvt[-2].opval, yypvt[-0].opval); } break;
case 78:
# line 359 "perly.y"
{ yyval.opval = newCONDOP(0, yypvt[-4].opval, yypvt[-2].opval, yypvt[-0].opval); } break;
case 79:
# line 361 "perly.y"
{ yyval.opval = bind_match(yypvt[-1].ival, yypvt[-2].opval, yypvt[-0].opval); } break;
case 80:
# line 363 "perly.y"
{ yyval.opval = yypvt[-0].opval; } break;
case 81:
# line 367 "perly.y"
{ yyval.opval = newUNOP(OP_NEGATE, 0, scalar(yypvt[-0].opval)); } break;
case 82:
# line 369 "perly.y"
{ yyval.opval = yypvt[-0].opval; } break;
case 83:
# line 371 "perly.y"
{ yyval.opval = newUNOP(OP_NOT, 0, scalar(yypvt[-0].opval)); } break;
case 84:
# line 373 "perly.y"
{ yyval.opval = newUNOP(OP_COMPLEMENT, 0, scalar(yypvt[-0].opval));} break;
case 85:
# line 375 "perly.y"
{ yyval.opval = newUNOP(OP_REFGEN, 0, ref(yypvt[-0].opval, OP_REFGEN)); } break;
case 86:
# line 377 "perly.y"
{ yyval.opval = newUNOP(OP_POSTINC, 0,
					ref(scalar(yypvt[-1].opval), OP_POSTINC)); } break;
case 87:
# line 380 "perly.y"
{ yyval.opval = newUNOP(OP_POSTDEC, 0,
					ref(scalar(yypvt[-1].opval), OP_POSTDEC)); } break;
case 88:
# line 383 "perly.y"
{ yyval.opval = newUNOP(OP_PREINC, 0,
					ref(scalar(yypvt[-0].opval), OP_PREINC)); } break;
case 89:
# line 386 "perly.y"
{ yyval.opval = newUNOP(OP_PREDEC, 0,
					ref(scalar(yypvt[-0].opval), OP_PREDEC)); } break;
case 90:
# line 389 "perly.y"
{ yyval.opval = localize(yypvt[-0].opval); } break;
case 91:
# line 391 "perly.y"
{ yyval.opval = sawparens(yypvt[-1].opval); } break;
case 92:
# line 393 "perly.y"
{ yyval.opval = newNULLLIST(); } break;
case 93:
# line 395 "perly.y"
{ yyval.opval = newANONLIST(yypvt[-1].opval); } break;
case 94:
# line 397 "perly.y"
{ yyval.opval = newANONLIST(Nullop); } break;
case 95:
# line 399 "perly.y"
{ yyval.opval = newANONHASH(yypvt[-1].opval); } break;
case 96:
# line 401 "perly.y"
{ yyval.opval = newANONHASH(Nullop); } break;
case 97:
# line 403 "perly.y"
{ yyval.opval = yypvt[-0].opval; } break;
case 98:
# line 405 "perly.y"
{ yyval.opval = yypvt[-0].opval; } break;
case 99:
# line 407 "perly.y"
{ yyval.opval = newBINOP(OP_AELEM, 0, oopsAV(yypvt[-3].opval), scalar(yypvt[-1].opval)); } break;
case 100:
# line 409 "perly.y"
{ yyval.opval = newBINOP(OP_AELEM, 0,
					scalar(ref(newAVREF(yypvt[-4].opval),OP_RV2AV)),
					scalar(yypvt[-1].opval));} break;
case 101:
# line 413 "perly.y"
{ yyval.opval = yypvt[-0].opval; } break;
case 102:
# line 415 "perly.y"
{ yyval.opval = yypvt[-0].opval; } break;
case 103:
# line 417 "perly.y"
{ yyval.opval = newUNOP(OP_AV2ARYLEN, 0, ref(yypvt[-0].opval, OP_AV2ARYLEN));} break;
case 104:
# line 419 "perly.y"
{ yyval.opval = newBINOP(OP_HELEM, 0, oopsHV(yypvt[-4].opval), jmaybe(yypvt[-2].opval));
			    expect = XOPERATOR; } break;
case 105:
# line 422 "perly.y"
{ yyval.opval = newBINOP(OP_HELEM, 0,
					scalar(ref(newHVREF(yypvt[-5].opval),OP_RV2HV)),
					jmaybe(yypvt[-2].opval));
			    expect = XOPERATOR; } break;
case 106:
# line 427 "perly.y"
{ yyval.opval = newSLICEOP(0, yypvt[-1].opval, yypvt[-4].opval); } break;
case 107:
# line 429 "perly.y"
{ yyval.opval = newSLICEOP(0, yypvt[-1].opval, Nullop); } break;
case 108:
# line 431 "perly.y"
{ yyval.opval = prepend_elem(OP_ASLICE,
				newOP(OP_PUSHMARK, 0),
				list(
				    newLISTOP(OP_ASLICE, 0,
					list(yypvt[-1].opval),
					ref(yypvt[-3].opval, OP_ASLICE)))); } break;
case 109:
# line 438 "perly.y"
{ yyval.opval = prepend_elem(OP_HSLICE,
				newOP(OP_PUSHMARK, 0),
				list(
				    newLISTOP(OP_HSLICE, 0,
					list(yypvt[-2].opval),
					ref(oopsHV(yypvt[-4].opval), OP_HSLICE))));
			    expect = XOPERATOR; } break;
case 110:
# line 446 "perly.y"
{ yyval.opval = newBINOP(OP_DELETE, 0, oopsHV(yypvt[-4].opval), jmaybe(yypvt[-2].opval));
			    expect = XOPERATOR; } break;
case 111:
# line 449 "perly.y"
{ yyval.opval = newBINOP(OP_DELETE, 0, oopsHV(yypvt[-5].opval), jmaybe(yypvt[-3].opval));
			    expect = XOPERATOR; } break;
case 112:
# line 452 "perly.y"
{ yyval.opval = yypvt[-0].opval; } break;
case 113:
# line 454 "perly.y"
{ yyval.opval = newUNOP(OP_ENTERSUBR, 0,
				scalar(yypvt[-0].opval)); } break;
case 114:
# line 457 "perly.y"
{ yyval.opval = newUNOP(OP_ENTERSUBR, OPf_STACKED, scalar(yypvt[-2].opval)); } break;
case 115:
# line 459 "perly.y"
{ yyval.opval = newUNOP(OP_ENTERSUBR, OPf_STACKED,
			    list(prepend_elem(OP_LIST, scalar(yypvt[-3].opval), yypvt[-1].opval))); } break;
case 116:
# line 462 "perly.y"
{ yyval.opval = newUNOP(OP_DOFILE, 0, scalar(yypvt[-0].opval));
			  allgvs = TRUE;} break;
case 117:
# line 465 "perly.y"
{ yyval.opval = newUNOP(OP_NULL, OPf_SPECIAL, scope(yypvt[-0].opval)); } break;
case 118:
# line 467 "perly.y"
{ yyval.opval = newUNOP(OP_ENTERSUBR, OPf_SPECIAL|OPf_STACKED,
			    list(prepend_elem(OP_LIST,
				scalar(newCVREF(scalar(yypvt[-2].opval))), newNULLLIST()))); } break;
case 119:
# line 471 "perly.y"
{ yyval.opval = newUNOP(OP_ENTERSUBR, OPf_SPECIAL|OPf_STACKED,
			    list(prepend_elem(OP_LIST,
				scalar(newCVREF(scalar(yypvt[-3].opval))),
				yypvt[-1].opval))); } break;
case 120:
# line 476 "perly.y"
{ yyval.opval = newUNOP(OP_ENTERSUBR, OPf_SPECIAL|OPf_STACKED,
			    list(prepend_elem(OP_LIST,
				scalar(newCVREF(scalar(yypvt[-2].opval))), newNULLLIST())));} break;
case 121:
# line 480 "perly.y"
{ yyval.opval = newUNOP(OP_ENTERSUBR, OPf_SPECIAL|OPf_STACKED,
			    list(prepend_elem(OP_LIST,
				scalar(newCVREF(scalar(yypvt[-3].opval))),
				yypvt[-1].opval))); } break;
case 122:
# line 485 "perly.y"
{ yyval.opval = newOP(yypvt[-0].ival, OPf_SPECIAL); } break;
case 123:
# line 487 "perly.y"
{ yyval.opval = newPVOP(yypvt[-1].ival, 0,
				savestr(SvPVnx(((SVOP*)yypvt[-0].opval)->op_sv)));
			    op_free(yypvt[-0].opval); } break;
case 124:
# line 491 "perly.y"
{ yyval.opval = newOP(yypvt[-0].ival, 0); } break;
case 125:
# line 493 "perly.y"
{ yyval.opval = newUNOP(yypvt[-1].ival, 0, yypvt[-0].opval); } break;
case 126:
# line 495 "perly.y"
{ yyval.opval = newUNOP(yypvt[-1].ival, 0, yypvt[-0].opval); } break;
case 127:
# line 497 "perly.y"
{ yyval.opval = newOP(yypvt[-0].ival, 0); } break;
case 128:
# line 499 "perly.y"
{ yyval.opval = newOP(yypvt[-2].ival, 0); } break;
case 129:
# line 501 "perly.y"
{ yyval.opval = newOP(yypvt[-2].ival, OPf_SPECIAL); } break;
case 130:
# line 503 "perly.y"
{ yyval.opval = newUNOP(yypvt[-3].ival, 0, yypvt[-1].opval); } break;
case 131:
# line 505 "perly.y"
{ yyval.opval = pmruntime(yypvt[-3].opval, yypvt[-1].opval, Nullop); } break;
case 132:
# line 507 "perly.y"
{ yyval.opval = pmruntime(yypvt[-5].opval, yypvt[-3].opval, yypvt[-1].opval); } break;
case 135:
# line 513 "perly.y"
{ yyval.opval = newNULLLIST(); } break;
case 136:
# line 515 "perly.y"
{ yyval.opval = yypvt[-0].opval; } break;
case 137:
# line 519 "perly.y"
{ yyval.opval = newCVREF(yypvt[-0].opval); } break;
case 138:
# line 523 "perly.y"
{ yyval.opval = newSVREF(yypvt[-0].opval); } break;
case 139:
# line 527 "perly.y"
{ yyval.opval = newAVREF(yypvt[-0].opval); } break;
case 140:
# line 531 "perly.y"
{ yyval.opval = newHVREF(yypvt[-0].opval); } break;
case 141:
# line 535 "perly.y"
{ yyval.opval = newAVREF(yypvt[-0].opval); } break;
case 142:
# line 539 "perly.y"
{ yyval.opval = newGVREF(yypvt[-0].opval); } break;
case 143:
# line 543 "perly.y"
{ yyval.opval = scalar(yypvt[-0].opval); } break;
case 144:
# line 545 "perly.y"
{ yyval.opval = scalar(yypvt[-0].opval); } break;
case 145:
# line 547 "perly.y"
{ yyval.opval = scalar(scope(yypvt[-0].opval)); } break;
case 146:
# line 552 "perly.y"
{ yyval.ival = 1; } break;
case 147:
# line 554 "perly.y"
{ yyval.ival = 0; } break;
case 148:
# line 558 "perly.y"
{ yyval.ival = 1; } break;
case 149:
# line 560 "perly.y"
{ yyval.ival = 0; } break;
case 150:
# line 564 "perly.y"
{ yyval.ival = 1; } break;
case 151:
# line 566 "perly.y"
{ yyval.ival = 0; } break;
	}
	goto yystack;		/* reset registers in driver code */
}
