/*    perlio.c
 *
 *    Copyright (c) 1996-2000, Nick Ing-Simmons
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

#define VOIDUSED 1
#ifdef PERL_MICRO
#   include "uconfig.h"
#else
#   include "config.h"
#endif

#define PERLIO_NOT_STDIO 0
#if !defined(PERLIO_IS_STDIO) && !defined(USE_SFIO)
/* #define PerlIO FILE */
#endif
/*
 * This file provides those parts of PerlIO abstraction
 * which are not #defined in iperlsys.h.
 * Which these are depends on various Configure #ifdef's
 */

#include "EXTERN.h"
#define PERL_IN_PERLIO_C
#include "perl.h"

#if !defined(PERL_IMPLICIT_SYS)

#ifdef PERLIO_IS_STDIO

void
PerlIO_init(void)
{
 /* Does nothing (yet) except force this file to be included
    in perl binary. That allows this file to force inclusion
    of other functions that may be required by loadable
    extensions e.g. for FileHandle::tmpfile
 */
}

#undef PerlIO_tmpfile
PerlIO *
PerlIO_tmpfile(void)
{
 return tmpfile();
}

#else /* PERLIO_IS_STDIO */

#ifdef USE_SFIO

#undef HAS_FSETPOS
#undef HAS_FGETPOS

/* This section is just to make sure these functions
   get pulled in from libsfio.a
*/

#undef PerlIO_tmpfile
PerlIO *
PerlIO_tmpfile(void)
{
 return sftmp(0);
}

void
PerlIO_init(void)
{
 /* Force this file to be included  in perl binary. Which allows
  *  this file to force inclusion  of other functions that may be
  *  required by loadable  extensions e.g. for FileHandle::tmpfile
  */

 /* Hack
  * sfio does its own 'autoflush' on stdout in common cases.
  * Flush results in a lot of lseek()s to regular files and
  * lot of small writes to pipes.
  */
 sfset(sfstdout,SF_SHARE,0);
}

#else /* USE_SFIO */

/*======================================================================================*/

/* Implement all the PerlIO interface ourselves.
*/

/* We _MUST_ have <unistd.h> if we are using lseek() and may have large files */
#ifdef I_UNISTD
#include <unistd.h>
#endif

#undef printf
void PerlIO_debug(char *fmt,...) __attribute__((format(printf,1,2)));

void
PerlIO_debug(char *fmt,...)
{
 static int dbg = 0;
 if (!dbg)
  {
   char *s = getenv("PERLIO_DEBUG");
   if (s && *s)
    dbg = open(s,O_WRONLY|O_CREAT|O_APPEND,0666);
   else
    dbg = -1;
  }
 if (dbg > 0)
  {
   dTHX;
   va_list ap;
   SV *sv = newSVpvn("",0);
   char *s;
   STRLEN len;
   va_start(ap,fmt);
   sv_vcatpvf(sv, fmt, &ap);
   s = SvPV(sv,len);
   write(dbg,s,len);
   va_end(ap);
   SvREFCNT_dec(sv);
  }
}

#define PERLIO_F_EOF		0x010000
#define PERLIO_F_ERROR		0x020000
#define PERLIO_F_LINEBUF	0x040000
#define PERLIO_F_TEMP		0x080000
#define PERLIO_F_RDBUF		0x100000
#define PERLIO_F_WRBUF		0x200000
#define PERLIO_F_OPEN		0x400000
#define PERLIO_F_USED		0x800000

struct _PerlIO
{
 IV       flags;      /* Various flags for state */
 IV       fd;         /* Maybe pointer on some OSes */
 int      oflags;     /* open/fcntl flags */
 STDCHAR *buf;        /* Start of buffer */
 STDCHAR *end;        /* End of valid part of buffer */
 STDCHAR *ptr;        /* Current position in buffer */
 Size_t   bufsiz;     /* Size of buffer */
 Off_t    posn;       /* Offset of f->buf into the file */
 int      oneword;    /* An if-all-else-fails area as a buffer */
};

/* Table of pointers to the PerlIO structs (malloc'ed) */
PerlIO **_perlio     = NULL;
int _perlio_size     = 0;

void
PerlIO_alloc_buf(PerlIO *f)
{
 if (!f->bufsiz)
  f->bufsiz = 4096;
 New('B',f->buf,f->bufsiz,char);
 if (!f->buf)
  {
   f->buf = (STDCHAR *)&f->oneword;
   f->bufsiz = sizeof(f->oneword);
  }
 f->ptr = f->buf;
 f->end = f->ptr;
}


/* This "flush" is akin to sfio's sync in that it handles files in either
   read or write state
*/
#undef PerlIO_flush
int
PerlIO_flush(PerlIO *f)
{
 int code = 0;
 if (f)
  {
   if (f->flags & PERLIO_F_WRBUF)
    {
     /* write() the buffer */
     STDCHAR *p = f->buf;
     int count;
     while (p < f->ptr)
      {
       count = write(f->fd,p,f->ptr - p);
       if (count > 0)
        {
         p += count;
        }
       else if (count < 0 && errno != EINTR)
        {
         f->flags |= PERLIO_F_ERROR;
         code = -1;
         break;
        }
      }
     f->posn += (p - f->buf);
    }
   else if (f->flags & PERLIO_F_RDBUF)
    {
     /* Note position change */
     f->posn += (f->ptr - f->buf);
     if (f->ptr < f->end)
      {
       /* We did not consume all of it */
       f->posn = lseek(f->fd,f->posn,SEEK_SET);
      }
    }
   f->ptr = f->end = f->buf;
   f->flags &= ~(PERLIO_F_RDBUF|PERLIO_F_WRBUF);
  }
 else
  {
   int i;
   for (i=_perlio_size-1; i >= 0; i--)
    {
     if ((f = _perlio[i]))
      {
       if (PerlIO_flush(f) != 0)
        code = -1;
      }
    }
  }
 return code;
}

int
PerlIO_oflags(const char *mode)
{
 int oflags = -1;
 switch(*mode)
  {
   case 'r':
    oflags = O_RDONLY;
    if (*++mode == '+')
     {
      oflags = O_RDWR;
      mode++;
     }
    break;

   case 'w':
    oflags = O_CREAT|O_TRUNC;
    if (*++mode == '+')
     {
      oflags |= O_RDWR;
      mode++;
     }
    else
     oflags |= O_WRONLY;
    break;

   case 'a':
    oflags = O_CREAT|O_APPEND;
    if (*++mode == '+')
     {
      oflags |= O_RDWR;
      mode++;
     }
    else
     oflags |= O_WRONLY;
    break;
  }
 if (*mode || oflags == -1)
  {
   errno = EINVAL;
   oflags = -1;
  }
 return oflags;
}

PerlIO *
PerlIO_allocate(void)
{
 /* Find a free slot in the table, growing table as necessary */
 PerlIO *f;
 int i = 0;
 while (1)
  {
   PerlIO **table = _perlio;
   while (i < _perlio_size)
    {
     f = table[i];
     if (!f)
      {
       Newz('F',f,1,PerlIO);
       if (!f)
        return NULL;
       table[i] = f;
      }
     if (!(f->flags & PERLIO_F_USED))
      {
       Zero(f,1,PerlIO);
       f->flags = PERLIO_F_USED;
       return f;
      }
     i++;
    }
   Newz('I',table,_perlio_size+16,PerlIO *);
   if (!table)
    return NULL;
   Copy(_perlio,table,_perlio_size,PerlIO *);
   if (_perlio)
    Safefree(_perlio);
   _perlio = table;
   _perlio_size += 16;
  }
}

#undef PerlIO_fdopen
PerlIO *
PerlIO_fdopen(int fd, const char *mode)
{
 PerlIO *f = NULL;
 if (fd >= 0)
  {
   if ((f = PerlIO_allocate()))
    {
     f->fd     = fd;
     f->oflags = PerlIO_oflags(mode);
     f->flags  |= (PERLIO_F_OPEN|PERLIO_F_USED);
    }
  }
 return f;
}

#undef PerlIO_fileno
int
PerlIO_fileno(PerlIO *f)
{
 if (f && (f->flags & PERLIO_F_OPEN))
  {
   return f->fd;
  }
 return -1;
}

#undef PerlIO_close
int
PerlIO_close(PerlIO *f)
{
 int code = 0;
 if (f)
  {
   if (PerlIO_flush(f) != 0)
    code = -1;
   while (close(f->fd) != 0)
    {
     if (errno != EINTR)
      {
       code = -1;
       break;
      }
    }
   f->flags &= ~PERLIO_F_OPEN;
   f->fd     = -1;
   if (f->buf && f->buf != (STDCHAR *) &f->oneword)
    {
     Safefree(f->buf);
    }
   f->buf = NULL;
   f->ptr = f->end = f->buf;
   f->flags &= ~(PERLIO_F_USED|PERLIO_F_RDBUF|PERLIO_F_WRBUF);
  }
 return code;
}

void
PerlIO_cleanup(void)
{
 /* Close all the files */
 int i;
 for (i=_perlio_size-1; i >= 0; i--)
  {
   PerlIO *f = _perlio[i];
   if (f)
    {
     PerlIO_close(f);
     Safefree(f);
    }
  }
 if (_perlio)
  Safefree(_perlio);
 _perlio      = NULL;
 _perlio_size = 0;
}

#undef PerlIO_open
PerlIO *
PerlIO_open(const char *path, const char *mode)
{
 PerlIO *f = NULL;
 int oflags = PerlIO_oflags(mode);
 if (oflags != -1)
  {
   int fd = open(path,oflags,0666);
   if (fd >= 0)
    {
     f = PerlIO_fdopen(fd,mode);
     if (!f)
      close(fd);
    }
  }
 return f;
}

#undef PerlIO_reopen
PerlIO *
PerlIO_reopen(const char *path, const char *mode, PerlIO *f)
{
 if (f)
  {
   int oflags = PerlIO_oflags(mode);
   PerlIO_close(f);
   if (oflags != -1)
    {
     int fd = open(path,oflags,0666);
     if (fd >= 0)
      {
       f->oflags = oflags;
       f->flags  |= (PERLIO_F_OPEN|PERLIO_F_USED);
      }
    }
   else
    {
     return NULL;
    }
  }
 return PerlIO_open(path,mode);
}

void
PerlIO_init(void)
{
 if (!_perlio)
  {
   atexit(&PerlIO_cleanup);
   PerlIO_fdopen(0,"r");
   PerlIO_fdopen(1,"w");
   PerlIO_fdopen(2,"w");
  }
}

#undef PerlIO_stdin
PerlIO *
PerlIO_stdin(void)
{
 if (!_perlio)
  PerlIO_init();
 return _perlio[0];
}

#undef PerlIO_stdout
PerlIO *
PerlIO_stdout(void)
{
 if (!_perlio)
  PerlIO_init();
 return _perlio[1];
}

#undef PerlIO_stderr
PerlIO *
PerlIO_stderr(void)
{
 if (!_perlio)
  PerlIO_init();
 return _perlio[2];
}

#undef PerlIO_fast_gets
int
PerlIO_fast_gets(PerlIO *f)
{
 return 1;
}

#undef PerlIO_has_cntptr
int
PerlIO_has_cntptr(PerlIO *f)
{
 return 1;
}

#undef PerlIO_canset_cnt
int
PerlIO_canset_cnt(PerlIO *f)
{
 return 1;
}

#undef PerlIO_set_cnt
void
PerlIO_set_cnt(PerlIO *f, int cnt)
{
 if (f)
  {
   dTHX;
   if (!f->buf)
    PerlIO_alloc_buf(f);
   f->ptr = f->end - cnt;
   assert(f->ptr >= f->buf);
  }
}

#undef PerlIO_get_cnt
int
PerlIO_get_cnt(PerlIO *f)
{
 if (f)
  {
   if (!f->buf)
    PerlIO_alloc_buf(f);
   if (f->flags & PERLIO_F_RDBUF)
    return (f->end - f->ptr);
  }
 return 0;
}

#undef PerlIO_set_ptrcnt
void
PerlIO_set_ptrcnt(PerlIO *f, STDCHAR *ptr, int cnt)
{
 if (f)
  {
   if (!f->buf)
    PerlIO_alloc_buf(f);
   f->ptr = ptr;
   if (PerlIO_get_cnt(f) != cnt || f->ptr < f->buf)
    {
     dTHX;
     assert(PerlIO_get_cnt(f) == cnt);
     assert(f->ptr >= f->buf);
    }
   f->flags |= PERLIO_F_RDBUF;
  }
}

#undef PerlIO_get_bufsiz
int
PerlIO_get_bufsiz(PerlIO *f)
{
 if (f)
  {
   if (!f->buf)
    PerlIO_alloc_buf(f);
   return f->bufsiz;
  }
 return -1;
}

#undef PerlIO_get_ptr
STDCHAR *
PerlIO_get_ptr(PerlIO *f)
{
 if (f)
  {
   if (!f->buf)
    PerlIO_alloc_buf(f);
   return f->ptr;
  }
 return NULL;
}

#undef PerlIO_get_base
STDCHAR *
PerlIO_get_base(PerlIO *f)
{
 if (f)
  {
   if (!f->buf)
    PerlIO_alloc_buf(f);
   return f->buf;
  }
 return NULL;
}

#undef PerlIO_has_base
int
PerlIO_has_base(PerlIO *f)
{
 if (f)
  {
   if (!f->buf)
    PerlIO_alloc_buf(f);
   return f->buf != NULL;
  }
}

#undef PerlIO_puts
int
PerlIO_puts(PerlIO *f, const char *s)
{
 STRLEN len = strlen(s);
 return PerlIO_write(f,s,len);
}

#undef PerlIO_eof
int
PerlIO_eof(PerlIO *f)
{
 if (f)
  {
   return (f->flags & PERLIO_F_EOF) != 0;
  }
 return 1;
}

#undef PerlIO_getname
char *
PerlIO_getname(PerlIO *f, char *buf)
{
 dTHX;
 Perl_croak(aTHX_ "Don't know how to get file name");
 return NULL;
}

#undef PerlIO_ungetc
int
PerlIO_ungetc(PerlIO *f, int ch)
{
 if (f->buf && (f->flags & PERLIO_F_RDBUF) && f->ptr > f->buf)
  {
   *--(f->ptr) = ch;
   return ch;
  }
 return -1;
}

#undef PerlIO_read
SSize_t
PerlIO_read(PerlIO *f, void *vbuf, Size_t count)
{
 STDCHAR *buf = (STDCHAR *) vbuf;
 if (f)
  {
   Size_t got = 0;
   if (!f->ptr)
    PerlIO_alloc_buf(f);
   if ((f->oflags & (O_RDONLY|O_WRONLY|O_RDWR)) == O_WRONLY)
    return 0;
   while (count > 0)
    {
     SSize_t avail = (f->end - f->ptr);
     if ((SSize_t) count < avail)
      avail = count;
     if (avail > 0)
      {
       Copy(f->ptr,buf,avail,char);
       got     += avail;
       f->ptr  += avail;
       count   -= avail;
       buf     += avail;
      }
     if (count && (f->ptr >= f->end))
      {
       PerlIO_flush(f);
       f->ptr = f->end = f->buf;
       avail = read(f->fd,f->ptr,f->bufsiz);
       if (avail <= 0)
        {
         if (avail == 0)
          f->flags |= PERLIO_F_EOF;
         else if (errno == EINTR)
          continue;
         else
          f->flags |= PERLIO_F_ERROR;
         break;
        }
       f->end   = f->buf+avail;
       f->flags |= PERLIO_F_RDBUF;
      }
    }
   return got;
  }
 return 0;
}

#undef PerlIO_getc
int
PerlIO_getc(PerlIO *f)
{
 STDCHAR buf;
 int count = PerlIO_read(f,&buf,1);
 if (count == 1)
  return (unsigned char) buf;
 return -1;
}

#undef PerlIO_error
int
PerlIO_error(PerlIO *f)
{
 if (f)
  {
   return f->flags & PERLIO_F_ERROR;
  }
 return 1;
}

#undef PerlIO_clearerr
void
PerlIO_clearerr(PerlIO *f)
{
 if (f)
  {
   f->flags &= ~PERLIO_F_ERROR;
  }
}

#undef PerlIO_setlinebuf
void
PerlIO_setlinebuf(PerlIO *f)
{
 if (f)
  {
   f->flags &= ~PERLIO_F_LINEBUF;
  }
}

#undef PerlIO_write
SSize_t
PerlIO_write(PerlIO *f, const void *vbuf, Size_t count)
{
 const STDCHAR *buf = (const STDCHAR *) vbuf;
 Size_t written = 0;
 if (f)
  {
   if (!f->buf)
    PerlIO_alloc_buf(f);
   if ((f->oflags & (O_RDONLY|O_WRONLY|O_RDWR)) == O_RDONLY)
    return 0;
   while (count > 0)
    {
     SSize_t avail = f->bufsiz - (f->ptr - f->buf);
     if ((SSize_t) count < avail)
      avail = count;
     f->flags |= PERLIO_F_WRBUF;
     if (f->flags & PERLIO_F_LINEBUF)
      {
       while (avail > 0)
        {
         int ch = *buf++;
         *(f->ptr)++ = ch;
         count--;
         avail--;
         written++;
         if (ch == '\n')
          {
           PerlIO_flush(f);
           break;
          }
        }
      }
     else
      {
       if (avail)
        {
         Copy(buf,f->ptr,avail,char);
         count   -= avail;
         buf     += avail;
         written += avail;
         f->ptr  += avail;
        }
      }
     if (f->ptr >= (f->buf + f->bufsiz))
      PerlIO_flush(f);
    }
  }
 return written;
}

#undef PerlIO_putc
int
PerlIO_putc(PerlIO *f, int ch)
{
 STDCHAR buf = ch;
 PerlIO_write(f,&buf,1);
}

#undef PerlIO_tell
Off_t
PerlIO_tell(PerlIO *f)
{
 Off_t posn = f->posn;
 if (f->buf)
  posn += (f->ptr - f->buf);
 return posn;
}

#undef PerlIO_seek
int
PerlIO_seek(PerlIO *f, Off_t offset, int whence)
{
 int code;
 code = PerlIO_flush(f);
 if (code == 0)
  {
   f->flags &= ~PERLIO_F_EOF;
   f->posn = PerlLIO_lseek(f->fd,offset,whence);
   if (f->posn == (Off_t) -1)
    {
     f->posn = 0;
     code = -1;
    }
  }
 return code;
}

#undef PerlIO_rewind
void
PerlIO_rewind(PerlIO *f)
{
 PerlIO_seek(f,(Off_t)0,SEEK_SET);
}

#undef PerlIO_vprintf
int
PerlIO_vprintf(PerlIO *f, const char *fmt, va_list ap)
{
 dTHX;
 SV *sv = newSVpvn("",0);
 char *s;
 STRLEN len;
 sv_vcatpvf(sv, fmt, &ap);
 s = SvPV(sv,len);
 return PerlIO_write(f,s,len);
}

#undef PerlIO_printf
int
PerlIO_printf(PerlIO *f,const char *fmt,...)
{
 va_list ap;
 int result;
 va_start(ap,fmt);
 result = PerlIO_vprintf(f,fmt,ap);
 va_end(ap);
 return result;
}

#undef PerlIO_stdoutf
int
PerlIO_stdoutf(const char *fmt,...)
{
 va_list ap;
 int result;
 va_start(ap,fmt);
 result = PerlIO_vprintf(PerlIO_stdout(),fmt,ap);
 va_end(ap);
 return result;
}

#undef PerlIO_tmpfile
PerlIO *
PerlIO_tmpfile(void)
{
 dTHX;
 /* I have no idea how portable mkstemp() is ... */
 SV *sv = newSVpv("/tmp/PerlIO_XXXXXX",0);
 int fd = mkstemp(SvPVX(sv));
 PerlIO *f = NULL;
 if (fd >= 0)
  {
   f = PerlIO_fdopen(fd,"w+");
   if (f)
    {
     f->flags |= PERLIO_F_TEMP;
    }
   unlink(SvPVX(sv));
   SvREFCNT_dec(sv);
  }
 return f;
}

#undef PerlIO_importFILE
PerlIO *
PerlIO_importFILE(FILE *f, int fl)
{
 int fd = fileno(f);
 /* Should really push stdio discipline when we have them */
 return PerlIO_fdopen(fd,"r+");
}

#undef PerlIO_exportFILE
FILE *
PerlIO_exportFILE(PerlIO *f, int fl)
{
 PerlIO_flush(f);
 /* Should really push stdio discipline when we have them */
 return fdopen(PerlIO_fileno(f),"r+");
}

#undef PerlIO_findFILE
FILE *
PerlIO_findFILE(PerlIO *f)
{
 return PerlIO_exportFILE(f,0);
}

#undef PerlIO_releaseFILE
void
PerlIO_releaseFILE(PerlIO *p, FILE *f)
{
}

#undef HAS_FSETPOS
#undef HAS_FGETPOS

/*======================================================================================*/

#endif /* USE_SFIO */
#endif /* PERLIO_IS_STDIO */

#ifndef HAS_FSETPOS
#undef PerlIO_setpos
int
PerlIO_setpos(PerlIO *f, const Fpos_t *pos)
{
 return PerlIO_seek(f,*pos,0);
}
#else
#ifndef PERLIO_IS_STDIO
#undef PerlIO_setpos
int
PerlIO_setpos(PerlIO *f, const Fpos_t *pos)
{
#if defined(USE_64_BIT_STDIO) && defined(USE_FSETPOS64)
 return fsetpos64(f, pos);
#else
 return fsetpos(f, pos);
#endif
}
#endif
#endif

#ifndef HAS_FGETPOS
#undef PerlIO_getpos
int
PerlIO_getpos(PerlIO *f, Fpos_t *pos)
{
 *pos = PerlIO_tell(f);
 return 0;
}
#else
#ifndef PERLIO_IS_STDIO
#undef PerlIO_getpos
int
PerlIO_getpos(PerlIO *f, Fpos_t *pos)
{
#if defined(USE_64_BIT_STDIO) && defined(USE_FSETPOS64)
 return fgetpos64(f, pos);
#else
 return fgetpos(f, pos);
#endif
}
#endif
#endif

#if (defined(PERLIO_IS_STDIO) || !defined(USE_SFIO)) && !defined(HAS_VPRINTF)

int
vprintf(char *pat, char *args)
{
    _doprnt(pat, args, stdout);
    return 0;		/* wrong, but perl doesn't use the return value */
}

int
vfprintf(FILE *fd, char *pat, char *args)
{
    _doprnt(pat, args, fd);
    return 0;		/* wrong, but perl doesn't use the return value */
}

#endif

#ifndef PerlIO_vsprintf
int
PerlIO_vsprintf(char *s, int n, const char *fmt, va_list ap)
{
 int val = vsprintf(s, fmt, ap);
 if (n >= 0)
  {
   if (strlen(s) >= (STRLEN)n)
    {
     dTHX;
     PerlIO_puts(Perl_error_log,"panic: sprintf overflow - memory corrupted!\n");
     my_exit(1);
    }
  }
 return val;
}
#endif

#ifndef PerlIO_sprintf
int
PerlIO_sprintf(char *s, int n, const char *fmt,...)
{
 va_list ap;
 int result;
 va_start(ap,fmt);
 result = PerlIO_vsprintf(s, n, fmt, ap);
 va_end(ap);
 return result;
}
#endif

#endif /* !PERL_IMPLICIT_SYS */

