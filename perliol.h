#ifndef _PERLIOL_H
#define _PERLIOL_H

typedef struct
{
 PerlIO_funcs *funcs;
 SV *arg;
} PerlIO_pair_t;

typedef struct
{
 IV refcnt;
 IV cur;
 IV len;
 PerlIO_pair_t *array;
} PerlIO_list_t;

struct _PerlIO_funcs
{
 char *		name;
 Size_t		size;
 IV		kind;
 IV		(*Pushed)(PerlIO *f,const char *mode,SV *arg);
 IV		(*Popped)(PerlIO *f);
 PerlIO *	(*Open)(pTHX_ PerlIO_funcs *tab,
			PerlIO_list_t *layers, IV n,
			const char *mode,
			int fd, int imode, int perm,
			PerlIO *old,
			int narg, SV **args);
 SV *		(*Getarg)(PerlIO *f);
 IV		(*Fileno)(PerlIO *f);
 /* Unix-like functions - cf sfio line disciplines */
 SSize_t	(*Read)(PerlIO *f, void *vbuf, Size_t count);
 SSize_t	(*Unread)(PerlIO *f, const void *vbuf, Size_t count);
 SSize_t	(*Write)(PerlIO *f, const void *vbuf, Size_t count);
 IV		(*Seek)(PerlIO *f, Off_t offset, int whence);
 Off_t		(*Tell)(PerlIO *f);
 IV		(*Close)(PerlIO *f);
 /* Stdio-like buffered IO functions */
 IV		(*Flush)(PerlIO *f);
 IV		(*Fill)(PerlIO *f);
 IV		(*Eof)(PerlIO *f);
 IV		(*Error)(PerlIO *f);
 void		(*Clearerr)(PerlIO *f);
 void		(*Setlinebuf)(PerlIO *f);
 /* Perl's snooping functions */
 STDCHAR *	(*Get_base)(PerlIO *f);
 Size_t		(*Get_bufsiz)(PerlIO *f);
 STDCHAR *	(*Get_ptr)(PerlIO *f);
 SSize_t	(*Get_cnt)(PerlIO *f);
 void		(*Set_ptrcnt)(PerlIO *f,STDCHAR *ptr,SSize_t cnt);
};

/*--------------------------------------------------------------------------------------*/
/* Kind values */
#define PERLIO_K_RAW		0x00000001
#define PERLIO_K_BUFFERED	0x00000002
#define PERLIO_K_CANCRLF	0x00000004
#define PERLIO_K_FASTGETS	0x00000008
#define PERLIO_K_DUMMY		0x00000010
#define PERLIO_K_UTF8		0x00008000
#define PERLIO_K_DESTRUCT	0x00010000

/*--------------------------------------------------------------------------------------*/
struct _PerlIO
{
 PerlIOl *	next;       /* Lower layer */
 PerlIO_funcs *	tab;        /* Functions for this layer */
 IV		flags;      /* Various flags for state */
};

/*--------------------------------------------------------------------------------------*/

/* Flag values */
#define PERLIO_F_EOF		0x00000100
#define PERLIO_F_CANWRITE	0x00000200
#define PERLIO_F_CANREAD	0x00000400
#define PERLIO_F_ERROR		0x00000800
#define PERLIO_F_TRUNCATE	0x00001000
#define PERLIO_F_APPEND		0x00002000
#define PERLIO_F_CRLF		0x00004000
#define PERLIO_F_UTF8		0x00008000
#define PERLIO_F_UNBUF		0x00010000
#define PERLIO_F_WRBUF		0x00020000
#define PERLIO_F_RDBUF		0x00040000
#define PERLIO_F_LINEBUF	0x00080000
#define PERLIO_F_TEMP		0x00100000
#define PERLIO_F_OPEN		0x00200000
#define PERLIO_F_FASTGETS	0x00400000
#define PERLIO_F_TTY		0x00800000

#define PerlIOBase(f)      (*(f))
#define PerlIOSelf(f,type) ((type *)PerlIOBase(f))
#define PerlIONext(f)      (&(PerlIOBase(f)->next))

/*--------------------------------------------------------------------------------------*/
/* Data exports - EXT rather than extern is needed for Cygwin */
EXT PerlIO_funcs PerlIO_unix;
EXT PerlIO_funcs PerlIO_perlio;
EXT PerlIO_funcs PerlIO_stdio;
EXT PerlIO_funcs PerlIO_crlf;
EXT PerlIO_funcs PerlIO_utf8;
EXT PerlIO_funcs PerlIO_byte;
EXT PerlIO_funcs PerlIO_raw;
EXT PerlIO_funcs PerlIO_pending;
#ifdef HAS_MMAP
EXT PerlIO_funcs PerlIO_mmap;
#endif
#ifdef WIN32
EXT PerlIO_funcs PerlIO_win32;
#endif
extern PerlIO *PerlIO_allocate(pTHX);
extern SV *PerlIO_arg_fetch(PerlIO_list_t *av,IV n);
#define PerlIOArg PerlIO_arg_fetch(layers,n)

#if O_BINARY != O_TEXT
#define PERLIO_STDTEXT "t"
#else
#define PERLIO_STDTEXT ""
#endif

/*--------------------------------------------------------------------------------------*/
/* Generic, or stub layer functions */

extern IV	PerlIOBase_fileno    (PerlIO *f);
extern IV	PerlIOBase_pushed    (PerlIO *f, const char *mode,SV *arg);
extern IV	PerlIOBase_popped    (PerlIO *f);
extern SSize_t	PerlIOBase_read       (PerlIO *f, void *vbuf, Size_t count);
extern SSize_t	PerlIOBase_unread    (PerlIO *f, const void *vbuf, Size_t count);
extern IV	PerlIOBase_eof       (PerlIO *f);
extern IV	PerlIOBase_error     (PerlIO *f);
extern void	PerlIOBase_clearerr  (PerlIO *f);
extern IV	PerlIOBase_close     (PerlIO *f);
extern void	PerlIOBase_setlinebuf(PerlIO *f);
extern void	PerlIOBase_flush_linebuf(void);

extern IV	PerlIOBase_noop_ok   (PerlIO *f);
extern IV	PerlIOBase_noop_fail (PerlIO *f);

/*--------------------------------------------------------------------------------------*/
/* perlio buffer layer
   As this is reasonably generic its struct and "methods" are declared here
   so they can be used to "inherit" from it.
*/

typedef struct
{
 struct _PerlIO base;       /* Base "class" info */
 STDCHAR *	buf;        /* Start of buffer */
 STDCHAR *	end;        /* End of valid part of buffer */
 STDCHAR *	ptr;        /* Current position in buffer */
 Off_t		posn;       /* Offset of buf into the file */
 Size_t		bufsiz;     /* Real size of buffer */
 IV		oneword;    /* Emergency buffer */
} PerlIOBuf;

extern PerlIO *	PerlIOBuf_open       (pTHX_ PerlIO_funcs *self, PerlIO_list_t *layers, IV n, const char *mode, int fd, int imode, int perm, PerlIO *old, int narg, SV **args);
extern IV	PerlIOBuf_pushed     (PerlIO *f, const char *mode,SV *arg);
extern SSize_t	PerlIOBuf_read       (PerlIO *f, void *vbuf, Size_t count);
extern SSize_t	PerlIOBuf_unread     (PerlIO *f, const void *vbuf, Size_t count);
extern SSize_t	PerlIOBuf_write      (PerlIO *f, const void *vbuf, Size_t count);
extern IV	PerlIOBuf_seek       (PerlIO *f, Off_t offset, int whence);
extern Off_t	PerlIOBuf_tell       (PerlIO *f);
extern IV	PerlIOBuf_close      (PerlIO *f);
extern IV	PerlIOBuf_flush      (PerlIO *f);
extern IV	PerlIOBuf_fill       (PerlIO *f);
extern STDCHAR *PerlIOBuf_get_base   (PerlIO *f);
extern Size_t	PerlIOBuf_bufsiz     (PerlIO *f);
extern STDCHAR *PerlIOBuf_get_ptr    (PerlIO *f);
extern SSize_t	PerlIOBuf_get_cnt    (PerlIO *f);
extern void	PerlIOBuf_set_ptrcnt (PerlIO *f, STDCHAR *ptr, SSize_t cnt);

extern int	PerlIOUnix_oflags    (const char *mode);

/*--------------------------------------------------------------------------------------*/

#endif /* _PERLIOL_H */
