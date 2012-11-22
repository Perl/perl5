/*    perlio.h
 *
 *    Copyright (C) 1996, 1997, 1999, 2000, 2001, 2002, 2003,
 *    2004, 2005, 2006, 2007, by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

#ifndef _PERLIO_H
#define _PERLIO_H
/*
  Interface for perl to IO functions.

   One further note - the table-of-functions scheme controlled
   by PERL_IMPLICIT_SYS turns on USE_PERLIO so that iperlsys.h can
   #define PerlIO_xxx() to go via the function table, without having
   to #undef them from (say) stdio forms.

*/

/* --------------------  End of Configure controls ---------------------------- */

/*
 * Although we may not want stdio to be used including <stdio.h> here
 * avoids issues where stdio.h has strange side effects
 */
#include <stdio.h>

#ifdef __BEOS__
int fseeko(FILE *stream, off_t offset, int whence);
off_t ftello(FILE *stream);
#endif

/* BS2000 includes are sometimes a bit non standard :-( */
#if defined(POSIX_BC) && defined(O_BINARY) && !defined(O_TEXT)
#undef O_BINARY
#endif

/* ----------- PerlIO implementation ---------- */
/* PerlIO not #define-d to something else - define the implementation */

typedef struct _PerlIO PerlIOl;
typedef struct _PerlIO_funcs PerlIO_funcs;
typedef PerlIOl *PerlIO;
#define PerlIO PerlIO
#define PERLIO_LAYERS 1

/* Making the big PerlIO_funcs vtables const is good (enables placing
 * them in the const section which is good for speed, security, and
 * embeddability) but this cannot be done by default because of
 * backward compatibility. */
#ifdef PERLIO_FUNCS_CONST
#define PERLIO_FUNCS_DECL(funcs) const PerlIO_funcs funcs
#define PERLIO_FUNCS_CAST(funcs) (PerlIO_funcs*)(funcs)
#else
#define PERLIO_FUNCS_DECL(funcs) PerlIO_funcs funcs
#define PERLIO_FUNCS_CAST(funcs) (funcs)
#endif

PERL_EXPORT_C void PerlIO_define_layer(pTHX_ PerlIO_funcs *tab);
PERL_EXPORT_C PerlIO_funcs *PerlIO_find_layer(pTHX_ const char *name,
                                              STRLEN len,
				              int load);
PERL_EXPORT_C PerlIO *PerlIO_push(pTHX_ PerlIO *f, PERLIO_FUNCS_DECL(*tab),
			          const char *mode, SV *arg);
PERL_EXPORT_C void PerlIO_pop(pTHX_ PerlIO *f);
PERL_EXPORT_C AV* PerlIO_get_layers(pTHX_ PerlIO *f);
PERL_EXPORT_C void PerlIO_clone(pTHX_ PerlInterpreter *proto,
                                CLONE_PARAMS *param);

/* ----------- End of implementation choices  ---------- */

/* We now need to determine  what happens if source trys to use stdio.
 * There are three cases based on PERLIO_NOT_STDIO which XS code
 * can set how it wants.
 */

#ifdef PERL_CORE
/* Make a choice for perl core code
   - currently this is set to try and catch lingering raw stdio calls.
     This is a known issue with some non UNIX ports which still use
     "native" stdio features.
*/
#ifndef PERLIO_NOT_STDIO
#define PERLIO_NOT_STDIO 1
#endif
#else
#ifndef PERLIO_NOT_STDIO
#define PERLIO_NOT_STDIO 0
#endif
#endif

#ifdef PERLIO_NOT_STDIO
#if PERLIO_NOT_STDIO
/*
 * PERLIO_NOT_STDIO #define'd as 1
 * Case 1: Strong denial of stdio - make all stdio calls (we can think of) errors
 */
#include "nostdio.h"
#else				/* if PERLIO_NOT_STDIO */
/*
 * PERLIO_NOT_STDIO #define'd as 0
 * Case 2: Declares that both PerlIO and stdio can be used
 */
#endif				/* if PERLIO_NOT_STDIO */
#else				/* ifdef PERLIO_NOT_STDIO */
/*
 * PERLIO_NOT_STDIO not defined
 * Case 3: Try and fake stdio calls as PerlIO calls
 */
#include "fakesdio.h"
#endif				/* ifndef PERLIO_NOT_STDIO */

/* ----------- fill in things that have not got #define'd  ---------- */

#ifndef Fpos_t
#define Fpos_t Off_t
#endif

#ifndef EOF
#define EOF (-1)
#endif

/* This is to catch case with no stdio */
#ifndef BUFSIZ
#define BUFSIZ 1024
#endif

/* The default buffer size for the perlio buffering layer */
#ifndef PERLIOBUF_DEFAULT_BUFSIZ
#define PERLIOBUF_DEFAULT_BUFSIZ (BUFSIZ > 8192 ? BUFSIZ : 8192)
#endif

#ifndef SEEK_SET
#define SEEK_SET 0
#endif

#ifndef SEEK_CUR
#define SEEK_CUR 1
#endif

#ifndef SEEK_END
#define SEEK_END 2
#endif

#define PERLIO_DUP_CLONE	1
#define PERLIO_DUP_FD		2

/* --------------------- Now prototypes for functions --------------- */

START_EXTERN_C
#ifndef __attribute__format__
#  ifdef HASATTRIBUTE_FORMAT
#    define __attribute__format__(x,y,z) __attribute__((format(x,y,z)))
#  else
#    define __attribute__format__(x,y,z)
#  endif
#endif
PERL_EXPORT_C void PerlIO_init(pTHX);
PERL_EXPORT_C int PerlIO_stdoutf(const char *, ...)
    __attribute__format__(__printf__, 1, 2);
PERL_EXPORT_C int PerlIO_puts(PerlIO *, const char *);
PERL_EXPORT_C PerlIO *PerlIO_open(const char *, const char *);
PERL_EXPORT_C PerlIO *PerlIO_openn(pTHX_ const char *layers, const char *mode,
				   int fd, int imode, int perm, PerlIO *old,
				   int narg, SV **arg);
PERL_EXPORT_C int PerlIO_eof(PerlIO *);
PERL_EXPORT_C int PerlIO_error(PerlIO *);
PERL_EXPORT_C void PerlIO_clearerr(PerlIO *);
PERL_EXPORT_C int PerlIO_getc(PerlIO *);
PERL_EXPORT_C int PerlIO_putc(PerlIO *, int);
PERL_EXPORT_C int PerlIO_ungetc(PerlIO *, int);
PERL_EXPORT_C PerlIO *PerlIO_fdopen(int, const char *);
PERL_EXPORT_C PerlIO *PerlIO_importFILE(FILE *, const char *);
PERL_EXPORT_C FILE *PerlIO_exportFILE(PerlIO *, const char *);
PERL_EXPORT_C FILE *PerlIO_findFILE(PerlIO *);
PERL_EXPORT_C void PerlIO_releaseFILE(PerlIO *, FILE *);
PERL_EXPORT_C SSize_t PerlIO_read(PerlIO *, void *, Size_t);
PERL_EXPORT_C SSize_t PerlIO_unread(PerlIO *, const void *, Size_t);
PERL_EXPORT_C SSize_t PerlIO_write(PerlIO *, const void *, Size_t);
PERL_EXPORT_C void PerlIO_setlinebuf(PerlIO *);
PERL_EXPORT_C int PerlIO_printf(PerlIO *, const char *, ...)
    __attribute__format__(__printf__, 2, 3);
PERL_EXPORT_C int PerlIO_sprintf(char *, int, const char *, ...)
    __attribute__format__(__printf__, 3, 4);
PERL_EXPORT_C int PerlIO_vprintf(PerlIO *, const char *, va_list);
PERL_EXPORT_C Off_t PerlIO_tell(PerlIO *);
PERL_EXPORT_C int PerlIO_seek(PerlIO *, Off_t, int);
PERL_EXPORT_C void PerlIO_rewind(PerlIO *);
PERL_EXPORT_C int PerlIO_has_base(PerlIO *);
PERL_EXPORT_C int PerlIO_has_cntptr(PerlIO *);
PERL_EXPORT_C int PerlIO_fast_gets(PerlIO *);
PERL_EXPORT_C int PerlIO_canset_cnt(PerlIO *);
PERL_EXPORT_C STDCHAR *PerlIO_get_ptr(PerlIO *);
PERL_EXPORT_C int PerlIO_get_cnt(PerlIO *);
PERL_EXPORT_C void PerlIO_set_cnt(PerlIO *, int);
PERL_EXPORT_C void PerlIO_set_ptrcnt(PerlIO *, STDCHAR *, int);
PERL_EXPORT_C STDCHAR *PerlIO_get_base(PerlIO *);
PERL_EXPORT_C int PerlIO_get_bufsiz(PerlIO *);
PERL_EXPORT_C PerlIO *PerlIO_tmpfile(void);
PERL_EXPORT_C PerlIO *PerlIO_stdin(void);
PERL_EXPORT_C PerlIO *PerlIO_stdout(void);
PERL_EXPORT_C PerlIO *PerlIO_stderr(void);
PERL_EXPORT_C int PerlIO_getpos(PerlIO *, SV *);
PERL_EXPORT_C int PerlIO_setpos(PerlIO *, SV *);
PERL_EXPORT_C PerlIO *PerlIO_fdupopen(pTHX_ PerlIO *, CLONE_PARAMS *, int);
PERL_EXPORT_C char *PerlIO_modestr(PerlIO *, char *buf);
PERL_EXPORT_C int PerlIO_isutf8(PerlIO *);
PERL_EXPORT_C int PerlIO_apply_layers(pTHX_ PerlIO *f, const char *mode,
				      const char *names);
PERL_EXPORT_C int PerlIO_binmode(pTHX_ PerlIO *f, int iotype, int omode,
			  	 const char *names);
PERL_EXPORT_C char *PerlIO_getname(PerlIO *, char *);

PERL_EXPORT_C void PerlIO_destruct(pTHX);

PERL_EXPORT_C int PerlIO_intmode2str(int rawmode, char *mode, int *writing);

PERL_EXPORT_C void PerlIO_cleanup(pTHX);

PERL_EXPORT_C void PerlIO_debug(const char *fmt, ...)
    __attribute__format__(__printf__, 1, 2);
typedef struct PerlIO_list_s PerlIO_list_t;

END_EXTERN_C
#endif				/* _PERLIO_H */

/*
 * Local variables:
 * c-indentation-style: bsd
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 *
 * ex: set ts=8 sts=4 sw=4 et:
 */
