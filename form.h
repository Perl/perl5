/* $Header: form.h,v 2.0 88/06/05 00:09:01 root Exp $
 *
 * $Log:	form.h,v $
 * Revision 2.0  88/06/05  00:09:01  root
 * Baseline version 2.0.
 * 
 */

#define F_NULL 0
#define F_LEFT 1
#define F_RIGHT 2
#define F_CENTER 3
#define F_LINES 4

struct formcmd {
    struct formcmd *f_next;
    ARG *f_expr;
    char *f_pre;
    short f_presize;
    short f_size;
    char f_type;
    char f_flags;
};

#define FC_CHOP 1
#define FC_NOBLANK 2
#define FC_MORE 4

#define Nullfcmd Null(FCMD*)
