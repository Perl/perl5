/* $Header: form.h,v 4.0 91/03/20 01:19:37 lwall Locked $
 *
 *    Copyright (c) 1989, Larry Wall
 *
 *    You may distribute under the terms of the GNU General Public License
 *    as specified in the README file that comes with the perl 3.0 kit.
 *
 * $Log:	form.h,v $
 * Revision 4.0  91/03/20  01:19:37  lwall
 * 4.0 baseline.
 * 
 */

#define F_NULL 0
#define F_LEFT 1
#define F_RIGHT 2
#define F_CENTER 3
#define F_LINES 4
#define F_DECIMAL 5

struct formcmd {
    struct formcmd *f_next;
    ARG *f_expr;
    STR *f_unparsed;
    line_t f_line;
    char *f_pre;
    short f_presize;
    short f_size;
    short f_decimals;
    char f_type;
    char f_flags;
};

#define FC_CHOP 1
#define FC_NOBLANK 2
#define FC_MORE 4
#define FC_REPEAT 8
#define FC_DP 16

#define Nullfcmd Null(FCMD*)

EXT char *chopset INIT(" \n-");
