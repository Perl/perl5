static char	sccsid[] = "@(#)dlperl.c	1.2 10/12/92 (DLPERL)";

/*
 *     name:	dlperl.c
 * synopsis:	dlperl - perl interface to dynamically linked usubs
 *   sccsid:	@(#)dlperl.c	1.2 10/12/92
 */

/*
 * NOTE: this code is *not* portable
 *	 - uses SPARC assembler with gcc asm extensions
 *	 - is SPARC ABI specific
 *	 - uses SunOS 4.x dlopen
 *
 * NOTE: not all types are currently implemented
 *       - multiple indirections (pointers to pointers, etc.)
 *	 - structures
 *	 - quad-precison (long double)
 */

#include <dlfcn.h>
#include <alloca.h>
#include <ctype.h>

/* perl */
#include "EXTERN.h"
#include "perl.h"

/* globals */
int	Dl_warn			= 1;
int	Dl_errno;
#define DL_ERRSTR_SIZ		256
char	Dl_errstr[DL_ERRSTR_SIZ];
#define WORD_SIZE	(sizeof(int))

static int	userval();
static int	userset();
static int	usersub();


/*
 * glue perl subroutines and variables to dlperl functions
 */
enum usersubs {
	US_dl_open,
	US_dl_sym,
	US_dl_call,
	US_dl_close,
};

enum uservars {
	UV_DL_VERSION,
	UV_DL_WARN,
	UV_dl_errno,
	UV_dl_errstr,
};


int
dlperl_init()
{
	struct ufuncs	uf;
	char	*file = "dlperl.c";

	uf.uf_val = userval;
	uf.uf_set = userset;

#define MAGICVAR(name, ix) uf.uf_index = ix, magicname(name, &uf, sizeof uf)

	/* subroutines */
	make_usub("dl_open",		US_dl_open,		usersub, file);
	make_usub("dl_sym",		US_dl_sym,		usersub, file);
	make_usub("dl_call",		US_dl_call,		usersub, file);
	make_usub("dl_close",		US_dl_close,		usersub, file);

	/* variables */
	MAGICVAR("DL_VERSION",		(int) UV_DL_VERSION);
	MAGICVAR("DL_WARN",		(int) UV_DL_WARN);
	MAGICVAR("dl_errno",		(int) UV_dl_errno);
	MAGICVAR("dl_errstr",		(int) UV_dl_errstr);

	return 0;
}


/*
 * USERVAL AND USERSET
 */

/*
 * assign dlperl variables to perl variables
 */
/*ARGSUSED*/
static int
userval(ix, str)
int	ix;
STR	*str;
{
	switch(ix) {
	case UV_DL_VERSION:
		str_set(str, sccsid);
		break;
	case UV_DL_WARN:
		str_numset(str, (double) Dl_warn);
		break;
	case UV_dl_errno:
		str_numset(str, (double) Dl_errno);
		break;
	case UV_dl_errstr:
		str_set(str, Dl_errstr);
		break;
	default:
		fatal("dlperl: unimplemented userval");
		break;
	}
	return 0;
}

/*
 * assign perl variables to dlperl variables
 */
static int
userset(ix, str)
int	ix;
STR	*str;
{
	switch(ix) {
	case UV_DL_WARN:
		Dl_warn = (int) str_gnum(str);
		break;
	default:
		fatal("dlperl: unimplemented userset");
		break;
	}
	return 0;
}


/*
 * USERSUBS
 */
static int
usersub(ix, sp, items)
int	ix;
register int	sp;
register int	items;
{
	int	oldsp = sp;
	STR	**st = stack->ary_array + sp;
	register STR	*Str;	/* used in str_get and str_gnum macros */

	Dl_errno = 0;
	*Dl_errstr = '\0';

	switch(ix) {
	case US_dl_open:
	{
		char	*file;
		void	*dl_so;

		if(items != 1) {
			fatal("Usage: $dl_so = &dl_open($file)");
			return oldsp;
		}

		file = str_get(st[1]);
		dl_so = dlopen(file, 1);

		--sp;
		if(dl_so == NULL) {
			Dl_errno = 1;
			(void) sprintf(Dl_errstr, "&dl_open: %s", dlerror());
			if(Dl_warn) warn(Dl_errstr);

			astore(stack, ++sp, str_mortal(&str_undef));
		} else {
			astore(stack, ++sp, str_2mortal(str_make(
				(char *) &dl_so, sizeof(void *))));
		}
		break;
	}
	case US_dl_sym:
	{
		void	*dl_so;
		char	*symbol;
		void	*dl_func;

		if(items != 2) {
			fatal("Usage: $dl_func = &dl_sym($dl_so, $symbol)");
			return oldsp;
		}

		dl_so = *(void **) str_get(st[1]);
		symbol = str_get(st[2]);
		dl_func = dlsym(dl_so, symbol);

		--sp;
		if(dl_func == NULL) {
			Dl_errno = 1;
			(void) sprintf(Dl_errstr, "&dl_sym: %s", dlerror());
			if(Dl_warn) warn(Dl_errstr);

			astore(stack, ++sp, str_mortal(&str_undef));
		} else {
			astore(stack, ++sp, str_2mortal(str_make(
				(char *) &dl_func, sizeof(void *))));
		}
		break;
	}
	case US_dl_call:
	{
		void	*dl_func;
		char	*parms_desc, *return_desc;
		int	nstack, nparm, narr, nlen, nrep;
		int	f_indirect, f_no_parm, f_result;
		char	c, *c_p;		int	c_pn = 0;
		unsigned char	C, *C_p;	int	C_pn = 0;
		short	s, *s_p;		int	s_pn = 0;
		unsigned short	S, *S_p;	int	S_pn = 0;
		int	i, *i_p;		int	i_pn = 0;
		unsigned int	I, *I_p;	int	I_pn = 0;
		long	l, *l_p;		int	l_pn = 0;
		unsigned long	L, *L_p;	int	L_pn = 0;
		float	f, *f_p;		int	f_pn = 0;
		double	d, *d_p;		int	d_pn = 0;
		char	*a, **a_p;		int	a_pn = 0;
		char	*p, **p_p;		int	p_pn = 0;
		unsigned int	*stack_base, *stack_p;
		unsigned int	*xp;
		void	(*func)();
		unsigned int	ret_o;
		double	ret_fd;
		float	ret_f;
		char	*c1;
		int	n1, n2;

		if(items < 3) {
fatal("Usage: @vals = &dl_call($dl_func, $parms_desc, $return_desc, @parms)");
			return oldsp;
		}
		dl_func = *(void **) str_get(st[1]);
		parms_desc = str_get(st[2]);
		return_desc = str_get(st[3]);

		/* determine size of stack and temporaries */
#	define CNT_STK_TMP(PN, SN)					\
		n2 = 0; do {						\
			if(f_indirect) {				\
				PN += narr;				\
				++nstack;				\
				if(!f_no_parm)				\
					nparm += narr;			\
			} else {					\
				nstack += SN;				\
				if(!f_no_parm)				\
					++nparm;			\
			}						\
		} while(++n2 < nrep);					\
		f_indirect = f_no_parm = narr = nrep = 0;

		nstack = 0;
		nparm = 0;
		f_indirect = f_no_parm = narr = nrep = 0;
		for(c1 = parms_desc;*c1;++c1) {
			switch(*c1) {
			case ' ':
			case '\t':
				break;

			case 'c': /* signed char */
				CNT_STK_TMP(c_pn, 1);
				break;
			case 'C': /* unsigned char */
				CNT_STK_TMP(C_pn, 1);
				break;
			case 's': /* signed short */
				CNT_STK_TMP(s_pn, 1);
				break;
			case 'S': /* unsigned short */
				CNT_STK_TMP(S_pn, 1);
				break;
			case 'i': /* signed int */
				CNT_STK_TMP(i_pn, 1);
				break;
			case 'I': /* unsigned int */
				CNT_STK_TMP(I_pn, 1);
				break;
			case 'l': /* signed long */
				CNT_STK_TMP(l_pn, 1);
				break;
			case 'L': /* unsigned long */
				CNT_STK_TMP(L_pn, 1);
				break;
			case 'f': /* float */
				CNT_STK_TMP(f_pn, 1);
				break;
			case 'd': /* double */
				CNT_STK_TMP(d_pn, 2);
				break;
			case 'a': /* ascii (null-terminated) string */
				CNT_STK_TMP(a_pn, 1);
				break;
			case 'p': /* pointer to <nlen> buffer */
				CNT_STK_TMP(p_pn, 1);
				break;

			case '&': /* pointer = [1] */
				if(f_indirect) {
					Dl_errno = 1;
					(void) sprintf(Dl_errstr,
		"&dl_call: parms_desc %s: too many indirections, with char %c",
						parms_desc, *c1);
					if(Dl_warn) warn(Dl_errstr);
					return oldsp;
				}
				f_indirect = 1;
				narr = 1;
				break;
			case '[': /* array */
				if(f_indirect) {
					Dl_errno = 1;
					(void) sprintf(Dl_errstr,
		"&dl_call: parms_desc %s: too many indirections, with char %c",
						parms_desc, *c1);
					if(Dl_warn) warn(Dl_errstr);
					return oldsp;
				}
				f_indirect = 1;
				++c1;
				while(*c1 == ' ' && *c1 == '\t')
					++c1;
				while(isdigit(*c1)) {
					narr = narr * 10 + (*c1 - '0');
					++c1;
				}
				while(*c1 == ' ' && *c1 == '\t')
					++c1;
				if(*c1 != ']') {
					Dl_errno = 1;
					(void) sprintf(Dl_errstr,
			"&dl_call: parms_desc %s: bad char %c, expected ]",
						parms_desc, *c1);
					if(Dl_warn) warn(Dl_errstr);
					return oldsp;
				}
				break;
			case '<': /* length */
				++c1;
				while(*c1 == ' ' && *c1 == '\t')
					++c1;
				while(isdigit(*c1))
					++c1;
				while(*c1 == ' ' && *c1 == '\t')
					++c1;
				if(*c1 != '>') {
					Dl_errno = 1;
					(void) sprintf(Dl_errstr,
			"&dl_call: parms_desc %s: bad char %c, expected >",
						parms_desc, *c1);
					if(Dl_warn) warn(Dl_errstr);
					return oldsp;
				}
				break;
			case '+':
				break;
			case '-':
				f_no_parm = 1;
				break;
			case '0': case '1': case '2': case '3': case '4':
			case '5': case '6': case '7': case '8': case '9':
				if(nrep) {
					Dl_errno = 1;
					(void) sprintf(Dl_errstr,
						"&dl_call: too many repeats");
					if(Dl_warn) warn(Dl_errstr);
					return oldsp;
				}
				while(isdigit(*c1)) {
					nrep = nrep * 10 + (*c1 - '0');
					++c1;
				}
				--c1;
				break;
			default:
				Dl_errno = 1;
				(void) sprintf(Dl_errstr,
					"&dl_call: parms_desc %s: bad char %c",
					parms_desc, *c1);
				if(Dl_warn) warn(Dl_errstr);
				return oldsp;
			}
		}
		/* trailing &[]<>+-0-9 is ignored */
		if(nparm != items - 3) {
			Dl_errno = 1;
			(void) sprintf(Dl_errstr,
				"&dl_call: bad parameter count %d, expected %d",
				items - 3, nparm);
			if(Dl_warn) warn(Dl_errstr);
			return oldsp;
		}
		nparm = 4;

		/* allocate temporaries */
		if((c_pn && (c_p = (char *)
			alloca(c_pn * sizeof(char))) == NULL) ||
		   (C_pn && (C_p = (unsigned char *)
			alloca(C_pn * sizeof(unsigned char))) == NULL) ||
		   (s_pn && (s_p = (short *)
			alloca(s_pn * sizeof(short))) == NULL) ||
		   (S_pn && (S_p = (unsigned short *)
			alloca(S_pn * sizeof(unsigned short))) == NULL) ||
		   (i_pn && (i_p = (int *)
			alloca(i_pn * sizeof(int))) == NULL) ||
		   (I_pn && (I_p = (unsigned int *)
			alloca(I_pn * sizeof(unsigned int))) == NULL) ||
		   (l_pn && (l_p = (long *)
			alloca(l_pn * sizeof(long))) == NULL) ||
		   (L_pn && (L_p = (unsigned long *)
			alloca(L_pn * sizeof(unsigned long))) == NULL) ||
		   (f_pn && (f_p = (float *)
			alloca(f_pn * sizeof(float))) == NULL) ||
		   (d_pn && (d_p = (double *)
			alloca(d_pn * sizeof(double))) == NULL) ||
		   (a_pn && (a_p = (char **)
			alloca(a_pn * sizeof(char *))) == NULL) ||
		   (p_pn && (p_p = (char **)
			alloca(p_pn * sizeof(char *))) == NULL)) {
			Dl_errno = 1;
			(void) sprintf(Dl_errstr, "&dl_call: bad alloca");
			if(Dl_warn) warn(Dl_errstr);
			return oldsp;
		}

		/* grow stack - maintains stack alignment (double word) */
		/* NOTE: no functions should be called otherwise the stack */
		/*	 that is being built will be corrupted */
		/* NOTE: some of the stack is pre-allocated, but is not */
		/*	 reused here */
		if(alloca(nstack * WORD_SIZE) == NULL) {
			Dl_errno = 1;
			(void) sprintf(Dl_errstr, "&dl_call: bad alloca");
			if(Dl_warn) warn(Dl_errstr);
			return oldsp;
		}

		/* stack base */
#if !defined(lint)
		asm("add %%sp,68,%%o0;st %%o0,%0" :
			"=g" (stack_base) : /* input */ : "%%o0");
#else
		stack_base = 0;
#endif
		stack_p = stack_base;

		/* layout stack */
#	define LAY_STK_NUM(T, P, PN)					\
		n2 = 0; do {						\
			if(f_indirect) {				\
				*stack_p++ = (unsigned int) &P[PN];	\
				if(f_no_parm) {				\
					PN += narr;			\
				} else {				\
					for(n1 = 0;n1 < narr;++n1) {	\
					    P[PN++] = (T)		\
						str_gnum(st[nparm++]);	\
					}				\
				}					\
			} else {					\
				if(f_no_parm) {				\
					++stack_p;			\
				} else {				\
					*stack_p++ = (T)		\
						str_gnum(st[nparm++]);	\
				}					\
			}						\
		} while(++n2 < nrep);					\
		f_indirect = f_no_parm = narr = nrep = 0;

#	define LAY_STK_DOUBLE(T, P, PN)					\
		n2 = 0; do {						\
			if(f_indirect) {				\
				*stack_p++ = (unsigned int) &P[PN];	\
				if(f_no_parm) {				\
					PN += narr;			\
				} else {				\
					for(n1 = 0;n1 < narr;++n1) {	\
					    P[PN++] = (T)		\
						str_gnum(st[nparm++]);	\
					}				\
				}					\
			} else {					\
				if(f_no_parm) {				\
					stack_p += 2;			\
				} else {				\
					d = (T) str_gnum(st[nparm++]);	\
					xp = (unsigned int *) &d;	\
					*stack_p++ = *xp++;		\
					*stack_p++ = *xp;		\
				}					\
			}						\
		} while(++n2 < nrep);					\
		f_indirect = f_no_parm = narr = nrep = 0;

#	define LAY_STK_STR(P, PN)					\
		n2 = 0; do {						\
			if(f_indirect) {				\
				*stack_p++ = (unsigned int) &P[PN];	\
				if(f_no_parm) {				\
					PN += narr;			\
				} else {				\
					for(n1 = 0;n1 < narr;++n1) {	\
					    P[PN++] =			\
						str_get(st[nparm++]);	\
					}				\
				}					\
			} else {					\
				if(f_no_parm) {				\
					++stack_p;			\
				} else {				\
					*stack_p++ = (unsigned int)	\
						str_get(st[nparm++]);	\
				}					\
			}						\
		} while(++n2 < nrep);					\
		f_indirect = f_no_parm = narr = nrep = 0;

		c_pn = C_pn = s_pn = S_pn = i_pn = I_pn = l_pn = L_pn = 0;
		f_pn = d_pn = a_pn = p_pn = 0;
		f_indirect = f_no_parm = narr = nrep = 0;
		for(c1 = parms_desc;*c1;++c1) {
			switch(*c1) {
			case ' ':
			case '\t':
				break;

			case 'c': /* signed char */
				LAY_STK_NUM(char, c_p, c_pn);
				break;
			case 'C': /* unsigned char */
				LAY_STK_NUM(unsigned char, C_p, C_pn);
				break;
			case 's': /* signed short */
				LAY_STK_NUM(short, s_p, s_pn);
				break;
			case 'S': /* unsigned short */
				LAY_STK_NUM(unsigned short, S_p, S_pn);
				break;
			case 'i': /* signed int */
				LAY_STK_NUM(int, i_p, i_pn);
				break;
			case 'I': /* unsigned int */
				LAY_STK_NUM(unsigned int, I_p, I_pn);
				break;
			case 'l': /* signed long */
				LAY_STK_NUM(long, l_p, l_pn);
				break;
			case 'L': /* unsigned long */
				LAY_STK_NUM(unsigned long, L_p, L_pn);
				break;
			case 'f': /* float */
				LAY_STK_NUM(float, f_p, f_pn);
				break;
			case 'd': /* double */
				LAY_STK_DOUBLE(double, d_p, d_pn);
				break;
			case 'a': /* ascii (null-terminated) string */
				LAY_STK_STR(a_p, a_pn);
				break;
			case 'p': /* pointer to <nlen> buffer */
				LAY_STK_STR(p_p, p_pn);
				break;

			case '&': /* pointer = [1] */
				if(f_indirect) {
					Dl_errno = 1;
					(void) sprintf(Dl_errstr,
		"&dl_call: parms_desc %s: too many indirections, with char %c",
						parms_desc, *c1);
					if(Dl_warn) warn(Dl_errstr);
					return oldsp;
				}
				f_indirect = 1;
				narr = 1;
				break;
			case '[': /* array */
				if(f_indirect) {
					Dl_errno = 1;
					(void) sprintf(Dl_errstr,
		"&dl_call: parms_desc %s: too many indirections, with char %c",
						parms_desc, *c1);
					if(Dl_warn) warn(Dl_errstr);
					return oldsp;
				}
				f_indirect = 1;
				++c1;
				while(*c1 == ' ' && *c1 == '\t')
					++c1;
				while(isdigit(*c1)) {
					narr = narr * 10 + (*c1 - '0');
					++c1;
				}
				while(*c1 == ' ' && *c1 == '\t')
					++c1;
				if(*c1 != ']') {
					Dl_errno = 1;
					(void) sprintf(Dl_errstr,
			"&dl_call: parms_desc %s: bad char %c, expected ]",
						parms_desc, *c1);
					if(Dl_warn) warn(Dl_errstr);
					return oldsp;
				}
				break;
			case '<': /* length */
				++c1;
				while(*c1 == ' ' && *c1 == '\t')
					++c1;
				while(isdigit(*c1))
					++c1;
				while(*c1 == ' ' && *c1 == '\t')
					++c1;
				if(*c1 != '>') {
					Dl_errno = 1;
					(void) sprintf(Dl_errstr,
			"&dl_call: parms_desc %s: bad char %c, expected >",
						parms_desc, *c1);
					if(Dl_warn) warn(Dl_errstr);
					return oldsp;
				}
				break;
			case '+':
				break;
			case '-':
				f_no_parm = 1;
				break;
			case '0': case '1': case '2': case '3': case '4':
			case '5': case '6': case '7': case '8': case '9':
				if(nrep) {
					Dl_errno = 1;
					(void) sprintf(Dl_errstr,
						"&dl_call: too many repeats");
					if(Dl_warn) warn(Dl_errstr);
					return oldsp;
				}
				while(isdigit(*c1)) {
					nrep = nrep * 10 + (*c1 - '0');
					++c1;
				}
				--c1;
				break;
			default:
				Dl_errno = 1;
				(void) sprintf(Dl_errstr,
					"&dl_call: parms_desc %s: bad char %c",
					parms_desc, *c1);
				if(Dl_warn) warn(Dl_errstr);
				return oldsp;
			}
		}
		/* trailing &[]<>+-0-9 is ignored */

		/* call function */
		/* NOTE: the first 6 words are passed in registers %o0 - %o5 */
		/*	 %sp+68 to %sp+92 are vacant, but allocated */
		/*	 and shadow %o0 - %o5 */
		/*	 above stack_base starts at %sp+68 and the function */
		/*	 call below sets up %o0 - %o5 from stack_base */
		func = (void (*)()) dl_func;
		(*func)(stack_base[0], stack_base[1], stack_base[2],
			stack_base[3], stack_base[4], stack_base[5]);

		/* save return value */
		/* NOTE: return values are either in %o0 or %f0 */
#if !defined(lint)
		asm("st %%o0,%0" : "=g" (ret_o) : /* input */);
		asm("std %%f0,%0" : "=g" (ret_fd) : /* input */);
		asm("st %%f0,%0" : "=g" (ret_f) : /* input */);
#else
		ret_o = 0; ret_fd = 0.0; ret_f = 0.0;
#endif

		/* parameter results */
#	define RES_NUM(P, PN, SN)					\
		n2 = 0; do {						\
			if(f_indirect) {				\
				++nstack;				\
				if(f_result) {				\
					for(n1 = 0;n1 < narr;++n1) {	\
					  astore(stack, ++sp, str_2mortal( \
					    str_nmake((double) P[PN++]))); \
					}				\
				} else {				\
					PN += narr;			\
				}					\
			} else {					\
				nstack += SN;				\
				if(f_result) {				\
					astore(stack, ++sp,		\
						str_mortal(&str_undef));\
				}					\
			}						\
		} while(++n2 < nrep);					\
		f_indirect = f_result = narr = nlen = nrep = 0;

#	define RES_STR(P, PN, L, SN)					\
		n2 = 0; do {						\
			if(f_indirect) {				\
				++nstack;				\
				if(f_result) {				\
					for(n1 = 0;n1 < narr;++n1) {	\
					  astore(stack, ++sp, str_2mortal( \
					    str_make(P[PN++], L)));	\
					}				\
				} else {				\
					PN += narr;			\
				}					\
			} else {					\
				if(f_result) {				\
					astore(stack, ++sp, str_2mortal(\
					  str_make((char *)	\
					    stack_base[nstack], L)));	\
				}					\
				nstack += SN;				\
			}						\
		} while(++n2 < nrep);					\
		f_indirect = f_result = narr = nlen = nrep = 0;

		--sp;
		nstack = 0;
		c_pn = C_pn = s_pn = S_pn = i_pn = I_pn = l_pn = L_pn = 0;
		f_pn = d_pn = a_pn = p_pn = 0;
		f_indirect = f_result = narr = nlen = nrep = 0;
		for(c1 = parms_desc;*c1;++c1) {
			switch(*c1) {
			case ' ':
			case '\t':
				break;

			case 'c': /* signed char */
				RES_NUM(c_p, c_pn, 1);
				break;
			case 'C': /* unsigned char */
				RES_NUM(C_p, C_pn, 1);
				break;
			case 's': /* signed short */
				RES_NUM(s_p, s_pn, 1);
				break;
			case 'S': /* unsigned short */
				RES_NUM(S_p, S_pn, 1);
				break;
			case 'i': /* signed int */
				RES_NUM(i_p, i_pn, 1);
				break;
			case 'I': /* unsigned int */
				RES_NUM(I_p, I_pn, 1);
				break;
			case 'l': /* signed long */
				RES_NUM(l_p, l_pn, 1);
				break;
			case 'L': /* unsigned long */
				RES_NUM(L_p, L_pn, 1);
				break;
			case 'f': /* float */
				RES_NUM(f_p, f_pn, 1);
				break;
			case 'd': /* double */
				RES_NUM(d_p, d_pn, 2);
				break;
			case 'a': /* ascii (null-terminated) string */
				RES_STR(a_p, a_pn, 0, 1);
				break;
			case 'p': /* pointer to <nlen> buffer */
				RES_STR(p_p, p_pn, nlen, 1);
				break;

			case '&': /* pointer = [1] */
				if(f_indirect) {
					Dl_errno = 1;
					(void) sprintf(Dl_errstr,
		"&dl_call: parms_desc %s: too many indirections, with char %c",
						parms_desc, *c1);
					if(Dl_warn) warn(Dl_errstr);
					return oldsp;
				}
				f_indirect = 1;
				narr = 1;
				break;
			case '[': /* array */
				if(f_indirect) {
					Dl_errno = 1;
					(void) sprintf(Dl_errstr,
		"&dl_call: parms_desc %s: too many indirections, with char %c",
						parms_desc, *c1);
					if(Dl_warn) warn(Dl_errstr);
					return oldsp;
				}
				f_indirect = 1;
				++c1;
				while(*c1 == ' ' && *c1 == '\t')
					++c1;
				while(isdigit(*c1)) {
					narr = narr * 10 + (*c1 - '0');
					++c1;
				}
				while(*c1 == ' ' && *c1 == '\t')
					++c1;
				if(*c1 != ']') {
					Dl_errno = 1;
					(void) sprintf(Dl_errstr,
			"&dl_call: parms_desc %s: bad char %c, expected ]",
						parms_desc, *c1);
					if(Dl_warn) warn(Dl_errstr);
					return oldsp;
				}
				break;
			case '<': /* length */
				++c1;
				while(*c1 == ' ' && *c1 == '\t')
					++c1;
				while(isdigit(*c1)) {
					nlen = nlen * 10 + (*c1 - '0');
					++c1;
				}
				while(*c1 == ' ' && *c1 == '\t')
					++c1;
				if(*c1 != '>') {
					Dl_errno = 1;
					(void) sprintf(Dl_errstr,
			"&dl_call: parms_desc %s: bad char %c, expected >",
						parms_desc, *c1);
					if(Dl_warn) warn(Dl_errstr);
					return oldsp;
				}
				break;
			case '+':
				f_result = 1;
				break;
			case '-':
				break;
			case '0': case '1': case '2': case '3': case '4':
			case '5': case '6': case '7': case '8': case '9':
				if(nrep) {
					Dl_errno = 1;
					(void) sprintf(Dl_errstr,
						"&dl_call: too many repeats");
					if(Dl_warn) warn(Dl_errstr);
					return oldsp;
				}
				while(isdigit(*c1)) {
					nrep = nrep * 10 + (*c1 - '0');
					++c1;
				}
				--c1;
				break;
			default:
				Dl_errno = 1;
				(void) sprintf(Dl_errstr,
					"&dl_call: parms_desc %s: bad char %c",
					parms_desc, *c1);
				if(Dl_warn) warn(Dl_errstr);
				return oldsp;
			}
		}
		/* trailing &[]<>+-0-9 is ignored */

		/* return value */
#	define RET_NUM(T, S, P, R)					\
		if(f_indirect) {					\
			P = (T *) ret_o;				\
			for(n1 = 0;n1 < narr;++n1) {			\
				S = *P++;				\
				astore(stack, ++sp, str_2mortal(	\
					str_nmake((double) S)));	\
			}						\
		} else {						\
			S = (T) R;					\
			astore(stack, ++sp, str_2mortal(		\
				str_nmake((double) S)));		\
		}

#	define RET_STR(S, P, L)						\
		if(f_indirect) {					\
			P = (char **) ret_o;				\
			for(n1 = 0;n1 < narr;++n1) {			\
				S = *P++;				\
				astore(stack, ++sp, str_2mortal(	\
					str_make((char *) S, L)));	\
			}						\
		} else {						\
			S = (char *) ret_o;				\
			astore(stack, ++sp, str_2mortal(		\
				str_make((char *) S, L)));		\
		}

		f_indirect = nlen = narr = 0;
		for(c1 = return_desc;*c1;++c1) {
			switch(*c1) {
			case ' ':
			case '\t':
				break;

			case 'c': /* signed char */
				RET_NUM(char, c, c_p, ret_o);
				goto ret_exit;
			case 'C': /* unsigned char */
				RET_NUM(unsigned char, C, C_p, ret_o);
				goto ret_exit;
			case 's': /* signed short */
				RET_NUM(short, s, s_p, ret_o);
				goto ret_exit;
			case 'S': /* unsigned short */
				RET_NUM(unsigned short, S, S_p, ret_o);
				goto ret_exit;
			case 'i': /* signed int */
				RET_NUM(int, i, i_p, ret_o);
				goto ret_exit;
			case 'I': /* unsigned int */
				RET_NUM(unsigned int, I, I_p, ret_o);
				goto ret_exit;
			case 'l': /* signed long */
				RET_NUM(long, l, l_p, ret_o);
				goto ret_exit;
			case 'L': /* unsigned long */
				RET_NUM(unsigned long, L, L_p, ret_o);
				goto ret_exit;
			case 'f': /* float */
				RET_NUM(float, f, f_p, ret_f);
				break;
			case 'd': /* double */
				RET_NUM(double, d, d_p, ret_fd);
				goto ret_exit;
			case 'a': /* ascii (null-terminated) string */
				RET_STR(a, a_p, 0);
				goto ret_exit;
			case 'p': /* pointer to <nlen> buffer */
				RET_STR(p, p_p, nlen);
				goto ret_exit;

			case '&': /* pointer = [1] */
				if(f_indirect) {
					Dl_errno = 1;
					(void) sprintf(Dl_errstr,
		"&dl_call: return_desc %s: too many indirections, with char %c",
						return_desc, *c1);
					if(Dl_warn) warn(Dl_errstr);
					return oldsp;
				}
				f_indirect = 1;
				narr = 1;
				break;
			case '[': /* array */
				if(f_indirect) {
					Dl_errno = 1;
					(void) sprintf(Dl_errstr,
		"&dl_call: return_desc %s: too many indirections, with char %c",
						return_desc, *c1);
					if(Dl_warn) warn(Dl_errstr);
					return oldsp;
				}
				f_indirect = 1;
				++c1;
				while(*c1 == ' ' && *c1 == '\t')
					++c1;
				while(isdigit(*c1)) {
					narr = narr * 10 + (*c1 - '0');
					++c1;
				}
				while(*c1 == ' ' && *c1 == '\t')
					++c1;
				if(*c1 != ']') {
					Dl_errno = 1;
					(void) sprintf(Dl_errstr,
			"&dl_call: return_desc %s: bad char %c, expected ]",
						return_desc, *c1);
					if(Dl_warn) warn(Dl_errstr);
					return oldsp;
				}
				break;
			case '<': /* length */
				++c1;
				while(*c1 == ' ' && *c1 == '\t')
					++c1;
				while(isdigit(*c1)) {
					nlen = nlen * 10 + (*c1 - '0');
					++c1;
				}
				while(*c1 == ' ' && *c1 == '\t')
					++c1;
				if(*c1 != '>') {
					Dl_errno = 1;
					(void) sprintf(Dl_errstr,
			"&dl_call: return_desc %s: bad char %c, expected >",
						return_desc, *c1);
					if(Dl_warn) warn(Dl_errstr);
					return oldsp;
				}
				break;
			default:
				Dl_errno = 1;
				(void) sprintf(Dl_errstr,
					"&dl_call: return_desc %s: bad char %c",
					return_desc, *c1);
				if(Dl_warn) warn(Dl_errstr);
				return oldsp;
			}
		}
ret_exit:	/* anything beyond first [cCsSiIlLdfap] is ignored */
		break;
	}
	case US_dl_close:
	{
		void	*dl_so;
		int	dl_err;

		if(items != 1) {
			fatal("Usage: $dl_err = &dl_close($dl_so)");
			return oldsp;
		}

		dl_so = *(void **) str_get(st[1]);
		dl_err = dlclose(dl_so);

		--sp;
		if(dl_err) {
			Dl_errno = 1;
			(void) sprintf(Dl_errstr, "&dl_close: %s", dlerror());
			if(Dl_warn) warn(Dl_errstr);
		}
		astore(stack, ++sp, str_2mortal(str_nmake((double) dl_err)));
		break;
	}
	default:
		fatal("dlperl: unimplemented usersub");
		break;
	}
	return sp;
}
