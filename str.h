/* $Header: str.h,v 1.0 87/12/18 13:06:26 root Exp $
 *
 * $Log:	str.h,v $
 * Revision 1.0  87/12/18  13:06:26  root
 * Initial revision
 * 
 */

struct string {
    char *	str_ptr;	/* pointer to malloced string */
    double	str_nval;	/* numeric value, if any */
    int		str_len;	/* allocated size */
    int		str_cur;	/* length of str_ptr as a C string */
    union {
	STR *str_next;		/* while free, link to next free str */
	STAB *str_magic;	/* while in use, ptr to magic stab, if any */
    } str_link;
    char	str_pok;	/* state of str_ptr */
    char	str_nok;	/* state of str_nval */
};

#define Nullstr Null(STR*)

/* the following macro updates any magic values this str is associated with */

#define STABSET(x) (x->str_link.str_magic && stabset(x->str_link.str_magic,x))

EXT STR **tmps_list;
EXT long tmps_max INIT(-1);

char *str_2ptr();
double str_2num();
STR *str_static();
STR *str_make();
STR *str_nmake();
