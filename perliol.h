#ifndef _PERLIOL_H
#define _PERLIOL_H

struct _PerlIO_funcs
{
 char *		name;
 Size_t		size;
 IV		kind;
 IV		(*Fileno)(PerlIO *f);
 PerlIO *	(*Fdopen)(PerlIO_funcs *tab, int fd, const char *mode);
 PerlIO *	(*Open)(PerlIO_funcs *tab, const char *path, const char *mode);
 int		(*Reopen)(const char *path, const char *mode, PerlIO *f);
 IV		(*Pushed)(PerlIO *f,const char *mode);
 IV		(*Popped)(PerlIO *f);
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

#define PerlIOBase(f)      (*(f))
#define PerlIOSelf(f,type) ((type *)PerlIOBase(f))
#define PerlIONext(f)      (&(PerlIOBase(f)->next))

/*--------------------------------------------------------------------------------------*/

extern PerlIO_funcs PerlIO_unix;
extern PerlIO_funcs PerlIO_perlio;
extern PerlIO_funcs PerlIO_stdio;
extern PerlIO_funcs PerlIO_crlf;
#ifdef HAS_MMAP
extern PerlIO_funcs PerlIO_mmap;
#endif

extern PerlIO *PerlIO_allocate(pTHX);

#if O_BINARY != O_TEXT
#define PERLIO_STDTEXT "t"
#else
#define PERLIO_STDTEXT ""
#endif

/*--------------------------------------------------------------------------------------*/
/* Generic, or stub layer functions */

extern IV	PerlIOBase_fileno    (PerlIO *f);
extern IV	PerlIOBase_pushed    (PerlIO *f, const char *mode);
extern IV	PerlIOBase_popped    (PerlIO *f);
extern SSize_t	PerlIOBase_unread    (PerlIO *f, const void *vbuf, Size_t count);
extern IV	PerlIOBase_eof       (PerlIO *f);
extern IV	PerlIOBase_error     (PerlIO *f);
extern void	PerlIOBase_clearerr  (PerlIO *f);
extern IV	PerlIOBase_flush     (PerlIO *f);
extern IV	PerlIOBase_fill      (PerlIO *f);
extern IV	PerlIOBase_close     (PerlIO *f);
extern void	PerlIOBase_setlinebuf(PerlIO *f);

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

extern PerlIO *	PerlIOBuf_fdopen     (PerlIO_funcs *self, int fd, const char *mode);
extern PerlIO *	PerlIOBuf_open       (PerlIO_funcs *self, const char *path, const char *mode);
extern int	PerlIOBuf_reopen     (const char *path, const char *mode, PerlIO *f);
extern SSize_t	PerlIOBuf_read       (PerlIO *f, void *vbuf, Size_t count);
extern SSize_t	PerlIOBuf_unread     (PerlIO *f, const void *vbuf, Size_t count);
extern SSize_t	PerlIOBuf_write      (PerlIO *f, const void *vbuf, Size_t count);
extern IV	PerlIOBuf_seek       (PerlIO *f, Off_t offset, int whence);
extern Off_t	PerlIOBuf_tell       (PerlIO *f);
extern IV	PerlIOBuf_close      (PerlIO *f);
extern IV	PerlIOBuf_flush      (PerlIO *f);
extern IV	PerlIOBuf_fill       (PerlIO *f);
extern void	PerlIOBuf_setlinebuf (PerlIO *f);
extern STDCHAR *PerlIOBuf_get_base   (PerlIO *f);
extern Size_t	PerlIOBuf_bufsiz     (PerlIO *f);
extern STDCHAR *PerlIOBuf_get_ptr    (PerlIO *f);
extern SSize_t	PerlIOBuf_get_cnt    (PerlIO *f);
extern void	PerlIOBuf_set_ptrcnt (PerlIO *f, STDCHAR *ptr, SSize_t cnt);

/*--------------------------------------------------------------------------------------*/

#endif /* _PERLIOL_H */
