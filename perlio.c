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
#ifdef HAS_MMAP
#include <sys/mman.h>
#endif

#include "XSUB.h"

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
   s = CopFILE(PL_curcop);
   if (!s)
    s = "(none)";
   Perl_sv_catpvf(aTHX_ sv, "%s:%"IVdf" ", s, (IV)CopLINE(PL_curcop));
   Perl_sv_vcatpvf(aTHX_ sv, fmt, &ap);

   s = SvPV(sv,len);
   write(dbg,s,len);
   va_end(ap);
   SvREFCNT_dec(sv);
  }
}

/*--------------------------------------------------------------------------------------*/

typedef struct _PerlIO_funcs PerlIO_funcs;
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

struct _PerlIO
{
 PerlIOl *	next;       /* Lower layer */
 PerlIO_funcs *	tab;        /* Functions for this layer */
 IV		flags;      /* Various flags for state */
};

/*--------------------------------------------------------------------------------------*/

/* Flag values */
#define PERLIO_F_EOF		0x00010000
#define PERLIO_F_CANWRITE	0x00020000
#define PERLIO_F_CANREAD	0x00040000
#define PERLIO_F_ERROR		0x00080000
#define PERLIO_F_TRUNCATE	0x00100000
#define PERLIO_F_APPEND		0x00200000
#define PERLIO_F_BINARY		0x00400000
#define PERLIO_F_UTF8		0x00800000
#define PERLIO_F_LINEBUF	0x01000000
#define PERLIO_F_WRBUF		0x02000000
#define PERLIO_F_RDBUF		0x04000000
#define PERLIO_F_TEMP		0x08000000
#define PERLIO_F_OPEN		0x10000000

#define PerlIOBase(f)      (*(f))
#define PerlIOSelf(f,type) ((type *)PerlIOBase(f))
#define PerlIONext(f)      (&(PerlIOBase(f)->next))

/*--------------------------------------------------------------------------------------*/
/* Inner level routines */

/* Table of pointers to the PerlIO structs (malloc'ed) */
PerlIO *_perlio      = NULL;
#define PERLIO_TABLE_SIZE 64

PerlIO *
PerlIO_allocate(void)
{
 /* Find a free slot in the table, allocating new table as necessary */
 PerlIO **last = &_perlio;
 PerlIO *f;
 while ((f = *last))
  {
   int i;
   last = (PerlIO **)(f);
   for (i=1; i < PERLIO_TABLE_SIZE; i++)
    {
     if (!*++f)
      {
       return f;
      }
    }
  }
 Newz('I',f,PERLIO_TABLE_SIZE,PerlIO);
 if (!f)
  return NULL;
 *last = f;
 return f+1;
}

void
PerlIO_cleantable(PerlIO **tablep)
{
 PerlIO *table = *tablep;
 if (table)
  {
   int i;
   PerlIO_cleantable((PerlIO **) &(table[0]));
   for (i=PERLIO_TABLE_SIZE-1; i > 0; i--)
    {
     PerlIO *f = table+i;
     if (*f)
      PerlIO_close(f);
    }
   Safefree(table);
   *tablep = NULL;
  }
}

HV *PerlIO_layer_hv;
AV *PerlIO_layer_av;

void
PerlIO_cleanup(void)
{
 PerlIO_cleantable(&_perlio);
}

void
PerlIO_pop(PerlIO *f)
{
 PerlIOl *l = *f;
 if (l)
  {
   (*l->tab->Popped)(f);
   *f = l->next;
   Safefree(l);
  }
}

#undef PerlIO_close
int
PerlIO_close(PerlIO *f)
{
 int code = (*PerlIOBase(f)->tab->Close)(f);
 while (*f)
  {
   PerlIO_pop(f);
  }
 return code;
}


/*--------------------------------------------------------------------------------------*/
/* Given the abstraction above the public API functions */

#undef PerlIO_fileno
int
PerlIO_fileno(PerlIO *f)
{
 return (*PerlIOBase(f)->tab->Fileno)(f);
}


extern PerlIO_funcs PerlIO_unix;
extern PerlIO_funcs PerlIO_perlio;
extern PerlIO_funcs PerlIO_stdio;
#ifdef HAS_MMAP
extern PerlIO_funcs PerlIO_mmap;
#endif

XS(XS_perlio_import)
{
 dXSARGS;
 GV *gv = CvGV(cv);
 char *s = GvNAME(gv);
 STRLEN l = GvNAMELEN(gv);
 PerlIO_debug("%.*s\n",(int) l,s);
 XSRETURN_EMPTY;
}

XS(XS_perlio_unimport)
{
 dXSARGS;
 GV *gv = CvGV(cv);
 char *s = GvNAME(gv);
 STRLEN l = GvNAMELEN(gv);
 PerlIO_debug("%.*s\n",(int) l,s);
 XSRETURN_EMPTY;
}

SV *
PerlIO_find_layer(char *name, STRLEN len)
{
 dTHX;
 SV **svp;
 SV *sv;
 if (len <= 0)
  len = strlen(name);
 svp  = hv_fetch(PerlIO_layer_hv,name,len,0);
 if (svp && (sv = *svp) && SvROK(sv))
  return *svp;
 return NULL;
}

void
PerlIO_define_layer(PerlIO_funcs *tab)
{
 dTHX;
 HV *stash = gv_stashpv("perlio::Layer", TRUE);
 SV *sv = sv_bless(newRV_noinc(newSViv(PTR2IV(tab))),stash);
 hv_store(PerlIO_layer_hv,tab->name,strlen(tab->name),sv,0);
}

PerlIO_funcs *
PerlIO_default_layer(I32 n)
{
 dTHX;
 SV **svp;
 SV *layer;
 PerlIO_funcs *tab = &PerlIO_stdio;
 int len;
 if (!PerlIO_layer_hv)
  {
   char *s  = getenv("PERLIO");
   newXS("perlio::import",XS_perlio_import,__FILE__);
   newXS("perlio::unimport",XS_perlio_unimport,__FILE__);
   PerlIO_layer_hv = get_hv("perlio::layers",GV_ADD|GV_ADDMULTI);
   PerlIO_layer_av = get_av("perlio::layers",GV_ADD|GV_ADDMULTI);
   PerlIO_define_layer(&PerlIO_unix);
   PerlIO_define_layer(&PerlIO_perlio);
   PerlIO_define_layer(&PerlIO_stdio);
#ifdef HAS_MMAP
   PerlIO_define_layer(&PerlIO_mmap);
#endif
   av_push(PerlIO_layer_av,SvREFCNT_inc(PerlIO_find_layer(PerlIO_unix.name,0)));
   if (s)
    {
     while (*s)
      {
       while (*s && isspace((unsigned char)*s))
        s++;
       if (*s)
        {
         char *e = s;
         SV *layer;
         while (*e && !isspace((unsigned char)*e))
          e++;
         layer = PerlIO_find_layer(s,e-s);
         if (layer)
          {
           PerlIO_debug("Pushing %.*s\n",(e-s),s);
           av_push(PerlIO_layer_av,SvREFCNT_inc(layer));
          }
         else
          Perl_warn(aTHX_ "Unknown layer %.*s",(e-s),s);
         s = e;
        }
      }
    }
  }
 len  = av_len(PerlIO_layer_av);
 if (len < 1)
  {
   if (PerlIO_stdio.Set_ptrcnt)
    {
     av_push(PerlIO_layer_av,SvREFCNT_inc(PerlIO_find_layer(PerlIO_stdio.name,0)));
    }
   else
    {
     av_push(PerlIO_layer_av,SvREFCNT_inc(PerlIO_find_layer(PerlIO_perlio.name,0)));
    }
   len  = av_len(PerlIO_layer_av);
  }
 if (n < 0)
  n += len+1;
 svp = av_fetch(PerlIO_layer_av,n,0);
 if (svp && (layer = *svp) && SvROK(layer) && SvIOK((layer = SvRV(layer))))
  {
   tab = INT2PTR(PerlIO_funcs *, SvIV(layer));
  }
 /* PerlIO_debug("Layer %d is %s\n",n,tab->name); */
 return tab;
}

#define PerlIO_default_top() PerlIO_default_layer(-1)
#define PerlIO_default_btm() PerlIO_default_layer(0)

void
PerlIO_stdstreams()
{
 if (!_perlio)
  {
   PerlIO_allocate();
   PerlIO_fdopen(0,"Ir");
   PerlIO_fdopen(1,"Iw");
   PerlIO_fdopen(2,"Iw");
  }
}

#undef PerlIO_fdopen
PerlIO *
PerlIO_fdopen(int fd, const char *mode)
{
 PerlIO_funcs *tab = PerlIO_default_top();
 if (!_perlio)
  PerlIO_stdstreams();
 return (*tab->Fdopen)(tab,fd,mode);
}

#undef PerlIO_open
PerlIO *
PerlIO_open(const char *path, const char *mode)
{
 PerlIO_funcs *tab = PerlIO_default_top();
 if (!_perlio)
  PerlIO_stdstreams();
 return (*tab->Open)(tab,path,mode);
}

IV
PerlIOBase_pushed(PerlIO *f, const char *mode)
{
 PerlIOl *l = PerlIOBase(f);
 l->flags  &= ~(PERLIO_F_CANREAD|PERLIO_F_CANWRITE|
                PERLIO_F_TRUNCATE|PERLIO_F_APPEND|PERLIO_F_BINARY);
 if (mode)
  {
   switch (*mode++)
    {
     case 'r':
      l->flags = PERLIO_F_CANREAD;
      break;
     case 'a':
      l->flags = PERLIO_F_APPEND|PERLIO_F_CANWRITE;
      break;
     case 'w':
      l->flags = PERLIO_F_TRUNCATE|PERLIO_F_CANWRITE;
      break;
     default:
      errno = EINVAL;
      return -1;
    }
   while (*mode)
    {
     switch (*mode++)
      {
       case '+':
        l->flags |= PERLIO_F_CANREAD|PERLIO_F_CANWRITE;
        break;
       case 'b':
        l->flags |= PERLIO_F_BINARY;
        break;
      default:
       errno = EINVAL;
       return -1;
      }
    }
  }
 else
  {
   if (l->next)
    {
     l->flags |= l->next->flags &
                 (PERLIO_F_CANREAD|PERLIO_F_CANWRITE|
                   PERLIO_F_TRUNCATE|PERLIO_F_APPEND|PERLIO_F_BINARY);
    }
  }
 return 0;
}

#undef PerlIO_reopen
PerlIO *
PerlIO_reopen(const char *path, const char *mode, PerlIO *f)
{
 if (f)
  {
   PerlIO_flush(f);
   if ((*PerlIOBase(f)->tab->Reopen)(path,mode,f) == 0)
    {
     if ((*PerlIOBase(f)->tab->Pushed)(f,mode) == 0)
      return f;
    }
   return NULL;
  }
 else
  return PerlIO_open(path,mode);
}

#undef PerlIO_read
SSize_t
PerlIO_read(PerlIO *f, void *vbuf, Size_t count)
{
 return (*PerlIOBase(f)->tab->Read)(f,vbuf,count);
}

#undef PerlIO_unread
SSize_t
PerlIO_unread(PerlIO *f, const void *vbuf, Size_t count)
{
 return (*PerlIOBase(f)->tab->Unread)(f,vbuf,count);
}

#undef PerlIO_write
SSize_t
PerlIO_write(PerlIO *f, const void *vbuf, Size_t count)
{
 return (*PerlIOBase(f)->tab->Write)(f,vbuf,count);
}

#undef PerlIO_seek
int
PerlIO_seek(PerlIO *f, Off_t offset, int whence)
{
 return (*PerlIOBase(f)->tab->Seek)(f,offset,whence);
}

#undef PerlIO_tell
Off_t
PerlIO_tell(PerlIO *f)
{
 return (*PerlIOBase(f)->tab->Tell)(f);
}

#undef PerlIO_flush
int
PerlIO_flush(PerlIO *f)
{
 if (f)
  {
   return (*PerlIOBase(f)->tab->Flush)(f);
  }
 else
  {
   PerlIO **table = &_perlio;
   int code = 0;
   while ((f = *table))
    {
     int i;
     table = (PerlIO **)(f++);
     for (i=1; i < PERLIO_TABLE_SIZE; i++)
      {
       if (*f && PerlIO_flush(f) != 0)
        code = -1;
       f++;
      }
    }
   return code;
  }
}

#undef PerlIO_fill
int
PerlIO_fill(PerlIO *f)
{
 return (*PerlIOBase(f)->tab->Fill)(f);
}

#undef PerlIO_isutf8
int
PerlIO_isutf8(PerlIO *f)
{
 return (PerlIOBase(f)->flags & PERLIO_F_UTF8) != 0;
}

#undef PerlIO_eof
int
PerlIO_eof(PerlIO *f)
{
 return (*PerlIOBase(f)->tab->Eof)(f);
}

#undef PerlIO_error
int
PerlIO_error(PerlIO *f)
{
 return (*PerlIOBase(f)->tab->Error)(f);
}

#undef PerlIO_clearerr
void
PerlIO_clearerr(PerlIO *f)
{
 (*PerlIOBase(f)->tab->Clearerr)(f);
}

#undef PerlIO_setlinebuf
void
PerlIO_setlinebuf(PerlIO *f)
{
 (*PerlIOBase(f)->tab->Setlinebuf)(f);
}

#undef PerlIO_has_base
int
PerlIO_has_base(PerlIO *f)
{
 if (f && *f)
  {
   return (PerlIOBase(f)->tab->Get_base != NULL);
  }
 return 0;
}

#undef PerlIO_fast_gets
int
PerlIO_fast_gets(PerlIO *f)
{
 if (f && *f)
  {
   PerlIOl *l = PerlIOBase(f);
   return (l->tab->Set_ptrcnt != NULL);
  }
 return 0;
}

#undef PerlIO_has_cntptr
int
PerlIO_has_cntptr(PerlIO *f)
{
 if (f && *f)
  {
   PerlIO_funcs *tab = PerlIOBase(f)->tab;
   return (tab->Get_ptr != NULL && tab->Get_cnt != NULL);
  }
 return 0;
}

#undef PerlIO_canset_cnt
int
PerlIO_canset_cnt(PerlIO *f)
{
 if (f && *f)
  {
   PerlIOl *l = PerlIOBase(f);
   return (l->tab->Set_ptrcnt != NULL);
  }
 return 0;
}

#undef PerlIO_get_base
STDCHAR *
PerlIO_get_base(PerlIO *f)
{
 return (*PerlIOBase(f)->tab->Get_base)(f);
}

#undef PerlIO_get_bufsiz
int
PerlIO_get_bufsiz(PerlIO *f)
{
 return (*PerlIOBase(f)->tab->Get_bufsiz)(f);
}

#undef PerlIO_get_ptr
STDCHAR *
PerlIO_get_ptr(PerlIO *f)
{
 return (*PerlIOBase(f)->tab->Get_ptr)(f);
}

#undef PerlIO_get_cnt
int
PerlIO_get_cnt(PerlIO *f)
{
 return (*PerlIOBase(f)->tab->Get_cnt)(f);
}

#undef PerlIO_set_cnt
void
PerlIO_set_cnt(PerlIO *f,int cnt)
{
 (*PerlIOBase(f)->tab->Set_ptrcnt)(f,NULL,cnt);
}

#undef PerlIO_set_ptrcnt
void
PerlIO_set_ptrcnt(PerlIO *f, STDCHAR *ptr, int cnt)
{
 (*PerlIOBase(f)->tab->Set_ptrcnt)(f,ptr,cnt);
}

/*--------------------------------------------------------------------------------------*/
/* "Methods" of the "base class" */

IV
PerlIOBase_fileno(PerlIO *f)
{
 return PerlIO_fileno(PerlIONext(f));
}

PerlIO *
PerlIO_push(PerlIO *f,PerlIO_funcs *tab,const char *mode)
{
 PerlIOl *l = NULL;
 Newc('L',l,tab->size,char,PerlIOl);
 if (l)
  {
   Zero(l,tab->size,char);
   l->next = *f;
   l->tab  = tab;
   *f      = l;
   if ((*l->tab->Pushed)(f,mode) != 0)
    {
     PerlIO_pop(f);
     return NULL;
    }
  }
 return f;
}

SSize_t
PerlIOBase_unread(PerlIO *f, const void *vbuf, Size_t count)
{
 Off_t old = PerlIO_tell(f);
 if (PerlIO_seek(f,-((Off_t)count),SEEK_CUR) == 0)
  {
   Off_t new = PerlIO_tell(f);
   return old - new;
  }
 return 0;
}

IV
PerlIOBase_noop_ok(PerlIO *f)
{
 return 0;
}

IV
PerlIOBase_noop_fail(PerlIO *f)
{
 return -1;
}

IV
PerlIOBase_close(PerlIO *f)
{
 IV code = 0;
 if (PerlIO_flush(f) != 0)
  code = -1;
 if (PerlIO_close(PerlIONext(f)) != 0)
  code = -1;
 PerlIOBase(f)->flags &= ~(PERLIO_F_CANREAD|PERLIO_F_CANWRITE|PERLIO_F_OPEN);
 return code;
}

IV
PerlIOBase_eof(PerlIO *f)
{
 if (f && *f)
  {
   return (PerlIOBase(f)->flags & PERLIO_F_EOF) != 0;
  }
 return 1;
}

IV
PerlIOBase_error(PerlIO *f)
{
 if (f && *f)
  {
   return (PerlIOBase(f)->flags & PERLIO_F_ERROR) != 0;
  }
 return 1;
}

void
PerlIOBase_clearerr(PerlIO *f)
{
 if (f && *f)
  {
   PerlIOBase(f)->flags &= ~PERLIO_F_ERROR;
  }
}

void
PerlIOBase_setlinebuf(PerlIO *f)
{

}



/*--------------------------------------------------------------------------------------*/
/* Bottom-most level for UNIX-like case */

typedef struct
{
 struct _PerlIO base;       /* The generic part */
 int		fd;         /* UNIX like file descriptor */
 int		oflags;     /* open/fcntl flags */
} PerlIOUnix;

int
PerlIOUnix_oflags(const char *mode)
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

IV
PerlIOUnix_fileno(PerlIO *f)
{
 return PerlIOSelf(f,PerlIOUnix)->fd;
}

PerlIO *
PerlIOUnix_fdopen(PerlIO_funcs *self, int fd,const char *mode)
{
 PerlIO *f = NULL;
 if (*mode == 'I')
  mode++;
 if (fd >= 0)
  {
   int oflags = PerlIOUnix_oflags(mode);
   if (oflags != -1)
    {
     PerlIOUnix *s = PerlIOSelf(PerlIO_push(f = PerlIO_allocate(),self,mode),PerlIOUnix);
     s->fd     = fd;
     s->oflags = oflags;
     PerlIOBase(f)->flags |= PERLIO_F_OPEN;
    }
  }
 return f;
}

PerlIO *
PerlIOUnix_open(PerlIO_funcs *self, const char *path,const char *mode)
{
 PerlIO *f = NULL;
 int oflags = PerlIOUnix_oflags(mode);
 if (oflags != -1)
  {
   int fd = open(path,oflags,0666);
   if (fd >= 0)
    {
     PerlIOUnix *s = PerlIOSelf(PerlIO_push(f = PerlIO_allocate(),self,mode),PerlIOUnix);
     s->fd     = fd;
     s->oflags = oflags;
     PerlIOBase(f)->flags |= PERLIO_F_OPEN;
    }
  }
 return f;
}

int
PerlIOUnix_reopen(const char *path, const char *mode, PerlIO *f)
{
 PerlIOUnix *s = PerlIOSelf(f,PerlIOUnix);
 int oflags = PerlIOUnix_oflags(mode);
 if (PerlIOBase(f)->flags & PERLIO_F_OPEN)
  (*PerlIOBase(f)->tab->Close)(f);
 if (oflags != -1)
  {
   int fd = open(path,oflags,0666);
   if (fd >= 0)
    {
     s->fd = fd;
     s->oflags = oflags;
     PerlIOBase(f)->flags |= PERLIO_F_OPEN;
     return 0;
    }
  }
 return -1;
}

SSize_t
PerlIOUnix_read(PerlIO *f, void *vbuf, Size_t count)
{
 int fd = PerlIOSelf(f,PerlIOUnix)->fd;
 if (!(PerlIOBase(f)->flags & PERLIO_F_CANREAD))
  return 0;
 while (1)
  {
   SSize_t len = read(fd,vbuf,count);
   if (len >= 0 || errno != EINTR)
    {
     if (len < 0)
      PerlIOBase(f)->flags |= PERLIO_F_ERROR;
     else if (len == 0 && count != 0)
      PerlIOBase(f)->flags |= PERLIO_F_EOF;
     return len;
    }
  }
}

SSize_t
PerlIOUnix_write(PerlIO *f, const void *vbuf, Size_t count)
{
 int fd = PerlIOSelf(f,PerlIOUnix)->fd;
 while (1)
  {
   SSize_t len = write(fd,vbuf,count);
   if (len >= 0 || errno != EINTR)
    {
     if (len < 0)
      PerlIOBase(f)->flags |= PERLIO_F_ERROR;
     return len;
    }
  }
}

IV
PerlIOUnix_seek(PerlIO *f, Off_t offset, int whence)
{
 Off_t new = lseek(PerlIOSelf(f,PerlIOUnix)->fd,offset,whence);
 PerlIOBase(f)->flags &= ~PERLIO_F_EOF;
 return (new == (Off_t) -1) ? -1 : 0;
}

Off_t
PerlIOUnix_tell(PerlIO *f)
{
 return lseek(PerlIOSelf(f,PerlIOUnix)->fd,0,SEEK_CUR);
}

IV
PerlIOUnix_close(PerlIO *f)
{
 int fd = PerlIOSelf(f,PerlIOUnix)->fd;
 int code = 0;
 while (close(fd) != 0)
  {
   if (errno != EINTR)
    {
     code = -1;
     break;
    }
  }
 if (code == 0)
  {
   PerlIOBase(f)->flags &= ~PERLIO_F_OPEN;
  }
 return code;
}

PerlIO_funcs PerlIO_unix = {
 "unix",
 sizeof(PerlIOUnix),
 0,
 PerlIOUnix_fileno,
 PerlIOUnix_fdopen,
 PerlIOUnix_open,
 PerlIOUnix_reopen,
 PerlIOBase_pushed,
 PerlIOBase_noop_ok,
 PerlIOUnix_read,
 PerlIOBase_unread,
 PerlIOUnix_write,
 PerlIOUnix_seek,
 PerlIOUnix_tell,
 PerlIOUnix_close,
 PerlIOBase_noop_ok,
 PerlIOBase_noop_fail,
 PerlIOBase_eof,
 PerlIOBase_error,
 PerlIOBase_clearerr,
 PerlIOBase_setlinebuf,
 NULL, /* get_base */
 NULL, /* get_bufsiz */
 NULL, /* get_ptr */
 NULL, /* get_cnt */
 NULL, /* set_ptrcnt */
};

/*--------------------------------------------------------------------------------------*/
/* stdio as a layer */

#if defined(USE_64_BIT_STDIO) && defined(HAS_FSEEKO) && !defined(USE_FSEEK64)
#define fseek fseeko
#endif

#if defined(USE_64_BIT_STDIO) && defined(HAS_FTELLO) && !defined(USE_FTELL64)
#define ftell ftello
#endif


typedef struct
{
 struct _PerlIO	base;
 FILE *		stdio;      /* The stream */
} PerlIOStdio;

IV
PerlIOStdio_fileno(PerlIO *f)
{
 return fileno(PerlIOSelf(f,PerlIOStdio)->stdio);
}


PerlIO *
PerlIOStdio_fdopen(PerlIO_funcs *self, int fd,const char *mode)
{
 PerlIO *f = NULL;
 int init = 0;
 if (*mode == 'I')
  {
   init = 1;
   mode++;
  }
 if (fd >= 0)
  {
   FILE *stdio = NULL;
   if (init)
    {
     switch(fd)
      {
       case 0:
        stdio = stdin;
        break;
       case 1:
        stdio = stdout;
        break;
       case 2:
        stdio = stderr;
        break;
      }
    }
   else
    stdio = fdopen(fd,mode);
   if (stdio)
    {
     PerlIOStdio *s = PerlIOSelf(PerlIO_push(f = PerlIO_allocate(),self,mode),PerlIOStdio);
     s->stdio  = stdio;
    }
  }
 return f;
}

#undef PerlIO_importFILE
PerlIO *
PerlIO_importFILE(FILE *stdio, int fl)
{
 PerlIO *f = NULL;
 if (stdio)
  {
   PerlIOStdio *s = PerlIOSelf(PerlIO_push(f = PerlIO_allocate(),&PerlIO_stdio,"r+"),PerlIOStdio);
   s->stdio  = stdio;
  }
 return f;
}

PerlIO *
PerlIOStdio_open(PerlIO_funcs *self, const char *path,const char *mode)
{
 PerlIO *f = NULL;
 FILE *stdio = fopen(path,mode);
 if (stdio)
  {
   PerlIOStdio *s = PerlIOSelf(PerlIO_push(f = PerlIO_allocate(),self,mode),PerlIOStdio);
   s->stdio  = stdio;
  }
 return f;
}

int
PerlIOStdio_reopen(const char *path, const char *mode, PerlIO *f)
{
 PerlIOStdio *s = PerlIOSelf(f,PerlIOStdio);
 FILE *stdio = freopen(path,mode,s->stdio);
 if (!s->stdio)
  return -1;
 s->stdio = stdio;
 return 0;
}

SSize_t
PerlIOStdio_read(PerlIO *f, void *vbuf, Size_t count)
{
 FILE *s = PerlIOSelf(f,PerlIOStdio)->stdio;
 SSize_t got = 0;
 if (count == 1)
  {
   STDCHAR *buf = (STDCHAR *) vbuf;
   /* Perl is expecting PerlIO_getc() to fill the buffer
    * Linux's stdio does not do that for fread()
    */
   int ch = fgetc(s);
   if (ch != EOF)
    {
     *buf = ch;
     got = 1;
    }
  }
 else
  got = fread(vbuf,1,count,s);
 return got;
}

SSize_t
PerlIOStdio_unread(PerlIO *f, const void *vbuf, Size_t count)
{
 FILE *s = PerlIOSelf(f,PerlIOStdio)->stdio;
 STDCHAR *buf = ((STDCHAR *)vbuf)+count-1;
 SSize_t unread = 0;
 while (count > 0)
  {
   int ch = *buf-- & 0xff;
   if (ungetc(ch,s) != ch)
    break;
   unread++;
   count--;
  }
 return unread;
}

SSize_t
PerlIOStdio_write(PerlIO *f, const void *vbuf, Size_t count)
{
 return fwrite(vbuf,1,count,PerlIOSelf(f,PerlIOStdio)->stdio);
}

IV
PerlIOStdio_seek(PerlIO *f, Off_t offset, int whence)
{
 FILE *stdio = PerlIOSelf(f,PerlIOStdio)->stdio;
 return fseek(stdio,offset,whence);
}

Off_t
PerlIOStdio_tell(PerlIO *f)
{
 FILE *stdio = PerlIOSelf(f,PerlIOStdio)->stdio;
 return ftell(stdio);
}

IV
PerlIOStdio_close(PerlIO *f)
{
 return fclose(PerlIOSelf(f,PerlIOStdio)->stdio);
}

IV
PerlIOStdio_flush(PerlIO *f)
{
 FILE *stdio = PerlIOSelf(f,PerlIOStdio)->stdio;
 return fflush(stdio);
}

IV
PerlIOStdio_fill(PerlIO *f)
{
 FILE *stdio = PerlIOSelf(f,PerlIOStdio)->stdio;
 int c;
 if (fflush(stdio) != 0)
  return EOF;
 c = fgetc(stdio);
 if (c == EOF || ungetc(c,stdio) != c)
  return EOF;
 return 0;
}

IV
PerlIOStdio_eof(PerlIO *f)
{
 return feof(PerlIOSelf(f,PerlIOStdio)->stdio);
}

IV
PerlIOStdio_error(PerlIO *f)
{
 return ferror(PerlIOSelf(f,PerlIOStdio)->stdio);
}

void
PerlIOStdio_clearerr(PerlIO *f)
{
 clearerr(PerlIOSelf(f,PerlIOStdio)->stdio);
}

void
PerlIOStdio_setlinebuf(PerlIO *f)
{
#ifdef HAS_SETLINEBUF
 setlinebuf(PerlIOSelf(f,PerlIOStdio)->stdio);
#else
 setvbuf(PerlIOSelf(f,PerlIOStdio)->stdio, Nullch, _IOLBF, 0);
#endif
}

#ifdef FILE_base
STDCHAR *
PerlIOStdio_get_base(PerlIO *f)
{
 FILE *stdio  = PerlIOSelf(f,PerlIOStdio)->stdio;
 return FILE_base(stdio);
}

Size_t
PerlIOStdio_get_bufsiz(PerlIO *f)
{
 FILE *stdio = PerlIOSelf(f,PerlIOStdio)->stdio;
 return FILE_bufsiz(stdio);
}
#endif

#ifdef USE_STDIO_PTR
STDCHAR *
PerlIOStdio_get_ptr(PerlIO *f)
{
 FILE *stdio = PerlIOSelf(f,PerlIOStdio)->stdio;
 return FILE_ptr(stdio);
}

SSize_t
PerlIOStdio_get_cnt(PerlIO *f)
{
 FILE *stdio = PerlIOSelf(f,PerlIOStdio)->stdio;
 return FILE_cnt(stdio);
}

void
PerlIOStdio_set_ptrcnt(PerlIO *f,STDCHAR *ptr,SSize_t cnt)
{
 FILE *stdio = PerlIOSelf(f,PerlIOStdio)->stdio;
 if (ptr != NULL)
  {
#ifdef STDIO_PTR_LVALUE
   FILE_ptr(stdio) = ptr;
#ifdef STDIO_PTR_LVAL_SETS_CNT
   if (FILE_cnt(stdio) != (cnt))
    {
     dTHX;
     assert(FILE_cnt(stdio) == (cnt));
    }
#endif
#if (!defined(STDIO_PTR_LVAL_NOCHANGE_CNT))
   /* Setting ptr _does_ change cnt - we are done */
   return;
#endif
#else  /* STDIO_PTR_LVALUE */
   abort();
#endif /* STDIO_PTR_LVALUE */
  }
/* Now (or only) set cnt */
#ifdef STDIO_CNT_LVALUE
 FILE_cnt(stdio) = cnt;
#else  /* STDIO_CNT_LVALUE */
#if (defined(STDIO_PTR_LVALUE) && defined(STDIO_PTR_LVAL_SETS_CNT))
 FILE_ptr(stdio) = FILE_ptr(stdio)+(FILE_cnt(stdio)-cnt);
#else  /* STDIO_PTR_LVAL_SETS_CNT */
 abort();
#endif /* STDIO_PTR_LVAL_SETS_CNT */
#endif /* STDIO_CNT_LVALUE */
}

#endif

PerlIO_funcs PerlIO_stdio = {
 "stdio",
 sizeof(PerlIOStdio),
 0,
 PerlIOStdio_fileno,
 PerlIOStdio_fdopen,
 PerlIOStdio_open,
 PerlIOStdio_reopen,
 PerlIOBase_pushed,
 PerlIOBase_noop_ok,
 PerlIOStdio_read,
 PerlIOStdio_unread,
 PerlIOStdio_write,
 PerlIOStdio_seek,
 PerlIOStdio_tell,
 PerlIOStdio_close,
 PerlIOStdio_flush,
 PerlIOStdio_fill,
 PerlIOStdio_eof,
 PerlIOStdio_error,
 PerlIOStdio_clearerr,
 PerlIOStdio_setlinebuf,
#ifdef FILE_base
 PerlIOStdio_get_base,
 PerlIOStdio_get_bufsiz,
#else
 NULL,
 NULL,
#endif
#ifdef USE_STDIO_PTR
 PerlIOStdio_get_ptr,
 PerlIOStdio_get_cnt,
#if (defined(STDIO_PTR_LVALUE) && (defined(STDIO_CNT_LVALUE) || defined(STDIO_PTR_LVAL_SETS_CNT)))
 PerlIOStdio_set_ptrcnt
#else  /* STDIO_PTR_LVALUE */
 NULL
#endif /* STDIO_PTR_LVALUE */
#else  /* USE_STDIO_PTR */
 NULL,
 NULL,
 NULL
#endif /* USE_STDIO_PTR */
};

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

/*--------------------------------------------------------------------------------------*/
/* perlio buffer layer */

typedef struct
{
 struct _PerlIO base;
 Off_t		posn;       /* Offset of buf into the file */
 STDCHAR *	buf;        /* Start of buffer */
 STDCHAR *	end;        /* End of valid part of buffer */
 STDCHAR *	ptr;        /* Current position in buffer */
 Size_t		bufsiz;     /* Size of buffer */
 IV		oneword;    /* Emergency buffer */
} PerlIOBuf;


PerlIO *
PerlIOBuf_fdopen(PerlIO_funcs *self, int fd, const char *mode)
{
 PerlIO_funcs *tab = PerlIO_default_btm();
 int init = 0;
 PerlIO *f;
 if (*mode == 'I')
  {
   init = 1;
   mode++;
  }
 f = (*tab->Fdopen)(tab,fd,mode);
 if (f)
  {
   /* Initial stderr is unbuffered */
   if (!init || fd != 2)
    {
     PerlIOBuf *b = PerlIOSelf(PerlIO_push(f,self,NULL),PerlIOBuf);
     b->posn = PerlIO_tell(PerlIONext(f));
    }
  }
 return f;
}


PerlIO *
PerlIOBuf_open(PerlIO_funcs *self, const char *path, const char *mode)
{
 PerlIO_funcs *tab = PerlIO_default_btm();
 PerlIO *f = (*tab->Open)(tab,path,mode);
 if (f)
  {
   PerlIOBuf *b = PerlIOSelf(PerlIO_push(f,self,NULL),PerlIOBuf);
   b->posn = PerlIO_tell(PerlIONext(f));
  }
 return f;
}

int
PerlIOBuf_reopen(const char *path, const char *mode, PerlIO *f)
{
 PerlIO *next = PerlIONext(f);
 int code = (*PerlIOBase(next)->tab->Reopen)(path,mode,next);
 if (code = 0)
  code = (*PerlIOBase(f)->tab->Pushed)(f,mode);
 if (code == 0)
  {
   PerlIOBuf *b = PerlIOSelf(f,PerlIOBuf);
   b->posn = PerlIO_tell(PerlIONext(f));
  }
 return code;
}

/* This "flush" is akin to sfio's sync in that it handles files in either
   read or write state
*/
IV
PerlIOBuf_flush(PerlIO *f)
{
 PerlIOBuf *b = PerlIOSelf(f,PerlIOBuf);
 int code = 0;
 if (PerlIOBase(f)->flags & PERLIO_F_WRBUF)
  {
   /* write() the buffer */
   STDCHAR *p = b->buf;
   int count;
   while (p < b->ptr)
    {
     count = PerlIO_write(PerlIONext(f),p,b->ptr - p);
     if (count > 0)
      {
       p += count;
      }
     else if (count < 0)
      {
       PerlIOBase(f)->flags |= PERLIO_F_ERROR;
       code = -1;
       break;
      }
    }
   b->posn += (p - b->buf);
  }
 else if (PerlIOBase(f)->flags & PERLIO_F_RDBUF)
  {
   /* Note position change */
   b->posn += (b->ptr - b->buf);
   if (b->ptr < b->end)
    {
     /* We did not consume all of it */
     if (PerlIO_seek(PerlIONext(f),b->posn,SEEK_SET) == 0)
      {
       b->posn = PerlIO_tell(PerlIONext(f));
      }
    }
  }
 b->ptr = b->end = b->buf;
 PerlIOBase(f)->flags &= ~(PERLIO_F_RDBUF|PERLIO_F_WRBUF);
 if (PerlIO_flush(PerlIONext(f)) != 0)
  code = -1;
 return code;
}

IV
PerlIOBuf_fill(PerlIO *f)
{
 PerlIOBuf *b = PerlIOSelf(f,PerlIOBuf);
 SSize_t avail;
 if (PerlIO_flush(f) != 0)
  return -1;
 b->ptr = b->end = b->buf;
 avail = PerlIO_read(PerlIONext(f),b->ptr,b->bufsiz);
 if (avail <= 0)
  {
   if (avail == 0)
    PerlIOBase(f)->flags |= PERLIO_F_EOF;
   else
    PerlIOBase(f)->flags |= PERLIO_F_ERROR;
   return -1;
  }
 b->end      = b->buf+avail;
 PerlIOBase(f)->flags |= PERLIO_F_RDBUF;
 return 0;
}

SSize_t
PerlIOBuf_read(PerlIO *f, void *vbuf, Size_t count)
{
 PerlIOBuf *b = PerlIOSelf(f,PerlIOBuf);
 STDCHAR *buf = (STDCHAR *) vbuf;
 if (f)
  {
   Size_t got = 0;
   if (!b->ptr)
    PerlIO_get_base(f);
   if (!(PerlIOBase(f)->flags & PERLIO_F_CANREAD))
    return 0;
   while (count > 0)
    {
     SSize_t avail = (b->end - b->ptr);
     if ((SSize_t) count < avail)
      avail = count;
     if (avail > 0)
      {
       Copy(b->ptr,buf,avail,char);
       got     += avail;
       b->ptr  += avail;
       count   -= avail;
       buf     += avail;
      }
     if (count && (b->ptr >= b->end))
      {
       if (PerlIO_fill(f) != 0)
        break;
      }
    }
   return got;
  }
 return 0;
}

SSize_t
PerlIOBuf_unread(PerlIO *f, const void *vbuf, Size_t count)
{
 const STDCHAR *buf = (const STDCHAR *) vbuf+count;
 PerlIOBuf *b = PerlIOSelf(f,PerlIOBuf);
 SSize_t unread = 0;
 SSize_t avail;
 if (PerlIOBase(f)->flags & PERLIO_F_WRBUF)
  PerlIO_flush(f);
 if (!b->buf)
  PerlIO_get_base(f);
 if (b->buf)
  {
   if (PerlIOBase(f)->flags & PERLIO_F_RDBUF)
    {
     avail = (b->ptr - b->buf);
     if (avail > (SSize_t) count)
      avail = count;
     b->ptr -= avail;
    }
   else
    {
     avail = b->bufsiz;
     if (avail > (SSize_t) count)
      avail = count;
     b->end = b->ptr + avail;
    }
   if (avail > 0)
    {
     buf    -= avail;
     if (buf != b->ptr)
      {
       Copy(buf,b->ptr,avail,char);
      }
     count  -= avail;
     unread += avail;
     PerlIOBase(f)->flags &= ~ PERLIO_F_EOF;
    }
  }
 return unread;
}

SSize_t
PerlIOBuf_write(PerlIO *f, const void *vbuf, Size_t count)
{
 PerlIOBuf *b = PerlIOSelf(f,PerlIOBuf);
 const STDCHAR *buf = (const STDCHAR *) vbuf;
 Size_t written = 0;
 if (!b->buf)
  PerlIO_get_base(f);
 if (!(PerlIOBase(f)->flags & PERLIO_F_CANWRITE))
  return 0;
 while (count > 0)
  {
   SSize_t avail = b->bufsiz - (b->ptr - b->buf);
   if ((SSize_t) count < avail)
    avail = count;
   PerlIOBase(f)->flags |= PERLIO_F_WRBUF;
   if (PerlIOBase(f)->flags & PERLIO_F_LINEBUF)
    {
     while (avail > 0)
      {
       int ch = *buf++;
       *(b->ptr)++ = ch;
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
       Copy(buf,b->ptr,avail,char);
       count   -= avail;
       buf     += avail;
       written += avail;
       b->ptr  += avail;
      }
    }
   if (b->ptr >= (b->buf + b->bufsiz))
    PerlIO_flush(f);
  }
 return written;
}

IV
PerlIOBuf_seek(PerlIO *f, Off_t offset, int whence)
{
 PerlIOBuf *b = PerlIOSelf(f,PerlIOBuf);
 int code = PerlIO_flush(f);
 if (code == 0)
  {
   PerlIOBase(f)->flags &= ~PERLIO_F_EOF;
   code = PerlIO_seek(PerlIONext(f),offset,whence);
   if (code == 0)
    {
     b->posn = PerlIO_tell(PerlIONext(f));
    }
  }
 return code;
}

Off_t
PerlIOBuf_tell(PerlIO *f)
{
 PerlIOBuf *b = PerlIOSelf(f,PerlIOBuf);
 Off_t posn = b->posn;
 if (b->buf)
  posn += (b->ptr - b->buf);
 return posn;
}

IV
PerlIOBuf_close(PerlIO *f)
{
 IV code = PerlIOBase_close(f);
 PerlIOBuf *b = PerlIOSelf(f,PerlIOBuf);
 if (b->buf && b->buf != (STDCHAR *) &b->oneword)
  {
   Safefree(b->buf);
  }
 b->buf = NULL;
 b->ptr = b->end = b->buf;
 PerlIOBase(f)->flags &= ~(PERLIO_F_RDBUF|PERLIO_F_WRBUF);
 return code;
}

void
PerlIOBuf_setlinebuf(PerlIO *f)
{
 if (f)
  {
   PerlIOBase(f)->flags &= ~PERLIO_F_LINEBUF;
  }
}

void
PerlIOBuf_set_cnt(PerlIO *f, int cnt)
{
 PerlIOBuf *b = PerlIOSelf(f,PerlIOBuf);
 dTHX;
 if (!b->buf)
  PerlIO_get_base(f);
 b->ptr = b->end - cnt;
 assert(b->ptr >= b->buf);
}

STDCHAR *
PerlIOBuf_get_ptr(PerlIO *f)
{
 PerlIOBuf *b = PerlIOSelf(f,PerlIOBuf);
 if (!b->buf)
  PerlIO_get_base(f);
 return b->ptr;
}

SSize_t
PerlIOBuf_get_cnt(PerlIO *f)
{
 PerlIOBuf *b = PerlIOSelf(f,PerlIOBuf);
 if (!b->buf)
  PerlIO_get_base(f);
 if (PerlIOBase(f)->flags & PERLIO_F_RDBUF)
  return (b->end - b->ptr);
 return 0;
}

STDCHAR *
PerlIOBuf_get_base(PerlIO *f)
{
 PerlIOBuf *b = PerlIOSelf(f,PerlIOBuf);
 if (!b->buf)
  {
   if (!b->bufsiz)
    b->bufsiz = 4096;
   New('B',b->buf,b->bufsiz,STDCHAR);
   if (!b->buf)
    {
     b->buf = (STDCHAR *)&b->oneword;
     b->bufsiz = sizeof(b->oneword);
    }
   b->ptr = b->buf;
   b->end = b->ptr;
  }
 return b->buf;
}

Size_t
PerlIOBuf_bufsiz(PerlIO *f)
{
 PerlIOBuf *b = PerlIOSelf(f,PerlIOBuf);
 if (!b->buf)
  PerlIO_get_base(f);
 return (b->end - b->buf);
}

void
PerlIOBuf_set_ptrcnt(PerlIO *f, STDCHAR *ptr, SSize_t cnt)
{
 PerlIOBuf *b = PerlIOSelf(f,PerlIOBuf);
 if (!b->buf)
  PerlIO_get_base(f);
 b->ptr = ptr;
 if (PerlIO_get_cnt(f) != cnt || b->ptr < b->buf)
  {
   dTHX;
   assert(PerlIO_get_cnt(f) == cnt);
   assert(b->ptr >= b->buf);
  }
 PerlIOBase(f)->flags |= PERLIO_F_RDBUF;
}

PerlIO_funcs PerlIO_perlio = {
 "perlio",
 sizeof(PerlIOBuf),
 0,
 PerlIOBase_fileno,
 PerlIOBuf_fdopen,
 PerlIOBuf_open,
 PerlIOBuf_reopen,
 PerlIOBase_pushed,
 PerlIOBase_noop_ok,
 PerlIOBuf_read,
 PerlIOBuf_unread,
 PerlIOBuf_write,
 PerlIOBuf_seek,
 PerlIOBuf_tell,
 PerlIOBuf_close,
 PerlIOBuf_flush,
 PerlIOBuf_fill,
 PerlIOBase_eof,
 PerlIOBase_error,
 PerlIOBase_clearerr,
 PerlIOBuf_setlinebuf,
 PerlIOBuf_get_base,
 PerlIOBuf_bufsiz,
 PerlIOBuf_get_ptr,
 PerlIOBuf_get_cnt,
 PerlIOBuf_set_ptrcnt,
};

#ifdef HAS_MMAP
/*--------------------------------------------------------------------------------------*/
/* mmap as "buffer" layer */

typedef struct
{
 PerlIOBuf	base;         /* PerlIOBuf stuff */
 Mmap_t		mptr;        /* Mapped address */
 Size_t		len;          /* mapped length */
 STDCHAR	*bbuf;        /* malloced buffer if map fails */

} PerlIOMmap;

static size_t page_size = 0;

IV
PerlIOMmap_map(PerlIO *f)
{
 dTHX;
 PerlIOMmap *m = PerlIOSelf(f,PerlIOMmap);
 PerlIOBuf  *b = &m->base;
 IV flags = PerlIOBase(f)->flags;
 IV code  = 0;
 if (m->len)
  abort();
 if (flags & PERLIO_F_CANREAD)
  {
   PerlIOBuf *b = PerlIOSelf(f,PerlIOBuf);
   int fd   = PerlIO_fileno(f);
   struct stat st;
   code = fstat(fd,&st);
   if (code == 0 && S_ISREG(st.st_mode))
    {
     SSize_t len = st.st_size - b->posn;
     if (len > 0)
      {
       Off_t posn;
       if (!page_size) {
#if defined(HAS_SYSCONF) && (defined(_SC_PAGESIZE) || defined(_SC_PAGE_SIZE))
	   {
	       SETERRNO(0,SS$_NORMAL);
#   ifdef _SC_PAGESIZE
	       page_size = sysconf(_SC_PAGESIZE);
#   else
	       page_size = sysconf(_SC_PAGE_SIZE);
#   endif 
	       if ((long)page_size < 0) {
		   if (errno) {
		       SV *error = ERRSV;
		       char *msg;
		       STRLEN n_a;
		       (void)SvUPGRADE(error, SVt_PV);
		       msg = SvPVx(error, n_a);
		       Perl_croak("panic: sysconf: %s", msg);
		   }
		   else
		       Perl_croak("panic: sysconf: pagesize unknown");
	       }
	   }
#else
#   ifdef HAS_GETPAGESIZE
        page_size = getpagesize();
#   else
#       if defined(I_SYS_PARAM) && defined(PAGESIZE)
        page_size = PAGESIZE; /* compiletime, bad */
#       endif
#   endif
#endif
	if ((IV)page_size <= 0)
	    Perl_croak("panic: bad pagesize %"IVdf, (IV)page_size);
       }
       if (b->posn < 0)
        {
         /* This is a hack - should never happen - open should have set it ! */
         b->posn = PerlIO_tell(PerlIONext(f));
        }
       posn = (b->posn / page_size) * page_size;
       len  = st.st_size - posn;
       m->mptr = mmap(NULL, len, PROT_READ, MAP_PRIVATE, fd, posn);
       if (m->mptr && m->mptr != (Mmap_t) -1)
        {
#if defined(HAS_MADVISE) && defined(MADV_SEQUENTIAL)
         madvise(m->mptr, len, MADV_SEQUENTIAL);
#endif
         PerlIOBase(f)->flags = (flags & ~PERLIO_F_EOF) | PERLIO_F_RDBUF;
         b->end  = ((STDCHAR *)m->mptr) + len;
         b->buf  = ((STDCHAR *)m->mptr) + (b->posn - posn);
         b->ptr  = b->buf;
         m->len  = len;
        }
       else
        {
         b->buf = NULL;
        }
      }
     else
      {
       PerlIOBase(f)->flags = flags | PERLIO_F_EOF | PERLIO_F_RDBUF;
       b->buf = NULL;
       b->ptr = b->end = b->ptr;
       code = -1;
      }
    }
  }
 return code;
}

IV
PerlIOMmap_unmap(PerlIO *f)
{
 PerlIOMmap *m = PerlIOSelf(f,PerlIOMmap);
 PerlIOBuf  *b = &m->base;
 IV code = 0;
 if (m->len)
  {
   if (b->buf)
    {
     code = munmap(m->mptr, m->len);
     b->buf  = NULL;
     m->len  = 0;
     m->mptr = NULL;
     if (PerlIO_seek(PerlIONext(f),b->posn,SEEK_SET) != 0)
      code = -1;
    }
   b->ptr = b->end = b->buf;
   PerlIOBase(f)->flags &= ~(PERLIO_F_RDBUF|PERLIO_F_WRBUF);
  }
 return code;
}

STDCHAR *
PerlIOMmap_get_base(PerlIO *f)
{
 PerlIOMmap *m = PerlIOSelf(f,PerlIOMmap);
 PerlIOBuf  *b = &m->base;
 if (b->buf && (PerlIOBase(f)->flags & PERLIO_F_RDBUF))
  {
   /* Already have a readbuffer in progress */
   return b->buf;
  }
 if (b->buf)
  {
   /* We have a write buffer or flushed PerlIOBuf read buffer */
   m->bbuf = b->buf;  /* save it in case we need it again */
   b->buf  = NULL;    /* Clear to trigger below */
  }
 if (!b->buf)
  {
   PerlIOMmap_map(f);     /* Try and map it */
   if (!b->buf)
    {
     /* Map did not work - recover PerlIOBuf buffer if we have one */
     b->buf = m->bbuf;
    }
  }
 b->ptr  = b->end = b->buf;
 if (b->buf)
  return b->buf;
 return PerlIOBuf_get_base(f);
}

SSize_t
PerlIOMmap_unread(PerlIO *f, const void *vbuf, Size_t count)
{
 PerlIOMmap *m = PerlIOSelf(f,PerlIOMmap);
 PerlIOBuf  *b = &m->base;
 if (PerlIOBase(f)->flags & PERLIO_F_WRBUF)
  PerlIO_flush(f);
 if (b->ptr && (b->ptr - count) >= b->buf && memEQ(b->ptr - count,vbuf,count))
  {
   b->ptr -= count;
   PerlIOBase(f)->flags &= ~ PERLIO_F_EOF;
   return count;
  }
 if (m->len)
  {
   /* Loose the unwritable mapped buffer */
   PerlIO_flush(f);
   /* If flush took the "buffer" see if we have one from before */
   if (!b->buf && m->bbuf)
    b->buf = m->bbuf;
   if (!b->buf)
    {
     PerlIOBuf_get_base(f);
     m->bbuf = b->buf;
    }
  }
 return PerlIOBuf_unread(f,vbuf,count);
}

SSize_t
PerlIOMmap_write(PerlIO *f, const void *vbuf, Size_t count)
{
 PerlIOMmap *m = PerlIOSelf(f,PerlIOMmap);
 PerlIOBuf  *b = &m->base;
 if (!b->buf || !(PerlIOBase(f)->flags & PERLIO_F_WRBUF))
  {
   /* No, or wrong sort of, buffer */
   if (m->len)
    {
     if (PerlIOMmap_unmap(f) != 0)
      return 0;
    }
   /* If unmap took the "buffer" see if we have one from before */
   if (!b->buf && m->bbuf)
    b->buf = m->bbuf;
   if (!b->buf)
    {
     PerlIOBuf_get_base(f);
     m->bbuf = b->buf;
    }
  }
 return PerlIOBuf_write(f,vbuf,count);
}

IV
PerlIOMmap_flush(PerlIO *f)
{
 PerlIOMmap *m = PerlIOSelf(f,PerlIOMmap);
 PerlIOBuf  *b = &m->base;
 IV code = PerlIOBuf_flush(f);
 /* Now we are "synced" at PerlIOBuf level */
 if (b->buf)
  {
   if (m->len)
    {
     /* Unmap the buffer */
     if (PerlIOMmap_unmap(f) != 0)
      code = -1;
    }
   else
    {
     /* We seem to have a PerlIOBuf buffer which was not mapped
      * remember it in case we need one later
      */
     m->bbuf = b->buf;
    }
  }
 return code;
}

IV
PerlIOMmap_fill(PerlIO *f)
{
 PerlIOBuf *b = PerlIOSelf(f,PerlIOBuf);
 IV code = PerlIO_flush(f);
 if (code == 0 && !b->buf)
  {
   code = PerlIOMmap_map(f);
  }
 if (code == 0 && !(PerlIOBase(f)->flags & PERLIO_F_RDBUF))
  {
   code = PerlIOBuf_fill(f);
  }
 return code;
}

IV
PerlIOMmap_close(PerlIO *f)
{
 PerlIOMmap *m = PerlIOSelf(f,PerlIOMmap);
 PerlIOBuf  *b = &m->base;
 IV code = PerlIO_flush(f);
 if (m->bbuf)
  {
   b->buf  = m->bbuf;
   m->bbuf = NULL;
   b->ptr  = b->end = b->buf;
  }
 if (PerlIOBuf_close(f) != 0)
  code = -1;
 return code;
}


PerlIO_funcs PerlIO_mmap = {
 "mmap",
 sizeof(PerlIOMmap),
 0,
 PerlIOBase_fileno,
 PerlIOBuf_fdopen,
 PerlIOBuf_open,
 PerlIOBuf_reopen,
 PerlIOBase_pushed,
 PerlIOBase_noop_ok,
 PerlIOBuf_read,
 PerlIOMmap_unread,
 PerlIOMmap_write,
 PerlIOBuf_seek,
 PerlIOBuf_tell,
 PerlIOBuf_close,
 PerlIOMmap_flush,
 PerlIOMmap_fill,
 PerlIOBase_eof,
 PerlIOBase_error,
 PerlIOBase_clearerr,
 PerlIOBuf_setlinebuf,
 PerlIOMmap_get_base,
 PerlIOBuf_bufsiz,
 PerlIOBuf_get_ptr,
 PerlIOBuf_get_cnt,
 PerlIOBuf_set_ptrcnt,
};

#endif /* HAS_MMAP */



void
PerlIO_init(void)
{
 if (!_perlio)
  {
   atexit(&PerlIO_cleanup);
  }
}

#undef PerlIO_stdin
PerlIO *
PerlIO_stdin(void)
{
 if (!_perlio)
  PerlIO_stdstreams();
 return &_perlio[1];
}

#undef PerlIO_stdout
PerlIO *
PerlIO_stdout(void)
{
 if (!_perlio)
  PerlIO_stdstreams();
 return &_perlio[2];
}

#undef PerlIO_stderr
PerlIO *
PerlIO_stderr(void)
{
 if (!_perlio)
  PerlIO_stdstreams();
 return &_perlio[3];
}

/*--------------------------------------------------------------------------------------*/

#undef PerlIO_getname
char *
PerlIO_getname(PerlIO *f, char *buf)
{
 dTHX;
 Perl_croak(aTHX_ "Don't know how to get file name");
 return NULL;
}


/*--------------------------------------------------------------------------------------*/
/* Functions which can be called on any kind of PerlIO implemented
   in terms of above
*/

#undef PerlIO_getc
int
PerlIO_getc(PerlIO *f)
{
 STDCHAR buf[1];
 SSize_t count = PerlIO_read(f,buf,1);
 if (count == 1)
  {
   return (unsigned char) buf[0];
  }
 return EOF;
}

#undef PerlIO_ungetc
int
PerlIO_ungetc(PerlIO *f, int ch)
{
 if (ch != EOF)
  {
   STDCHAR buf = ch;
   if (PerlIO_unread(f,&buf,1) == 1)
    return ch;
  }
 return EOF;
}

#undef PerlIO_putc
int
PerlIO_putc(PerlIO *f, int ch)
{
 STDCHAR buf = ch;
 return PerlIO_write(f,&buf,1);
}

#undef PerlIO_puts
int
PerlIO_puts(PerlIO *f, const char *s)
{
 STRLEN len = strlen(s);
 return PerlIO_write(f,s,len);
}

#undef PerlIO_rewind
void
PerlIO_rewind(PerlIO *f)
{
 PerlIO_seek(f,(Off_t)0,SEEK_SET);
 PerlIO_clearerr(f);
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
     PerlIOBase(f)->flags |= PERLIO_F_TEMP;
    }
   unlink(SvPVX(sv));
   SvREFCNT_dec(sv);
  }
 return f;
}

#undef HAS_FSETPOS
#undef HAS_FGETPOS

#endif /* USE_SFIO */
#endif /* PERLIO_IS_STDIO */

/*======================================================================================*/
/* Now some functions in terms of above which may be needed even if
   we are not in true PerlIO mode
 */

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

