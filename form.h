/* $Header: form.h,v 1.0 87/12/18 13:05:10 root Exp $
 *
 * $Log:	form.h,v $
 * Revision 1.0  87/12/18  13:05:10  root
 * Initial revision
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
