/*    perlio.c
 *
 *    Copyright (c) 1996-2001, Nick Ing-Simmons
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
 * which are not #defined in perlio.h.
 * Which these are depends on various Configure #ifdef's
 */

#include "EXTERN.h"
#define PERL_IN_PERLIO_C
#include "perl.h"

#undef PerlMemShared_calloc
#define PerlMemShared_calloc(x,y) calloc(x,y)
#undef PerlMemShared_free
#define PerlMemShared_free(x) free(x)

int
perlsio_binmode(FILE *fp, int iotype, int mode)
{
/* This used to be contents of do_binmode in doio.c */
#ifdef DOSISH
#  if defined(atarist) || defined(__MINT__)
    if (!fflush(fp)) {
	if (mode & O_BINARY)
	    ((FILE*)fp)->_flag |= _IOBIN;
	else
	    ((FILE*)fp)->_flag &= ~ _IOBIN;
	return 1;
    }
    return 0;
#  else
    dTHX;
    if (PerlLIO_setmode(fileno(fp), mode) != -1) {
#    if defined(WIN32) && defined(__BORLANDC__)
	/* The translation mode of the stream is maintained independent
	 * of the translation mode of the fd in the Borland RTL (heavy
	 * digging through their runtime sources reveal).  User has to
	 * set the mode explicitly for the stream (though they don't
	 * document this anywhere). GSAR 97-5-24
	 */
	fseek(fp,0L,0);
	if (mode & O_BINARY)
	    fp->flags |= _F_BIN;
	else
	    fp->flags &= ~ _F_BIN;
#    endif
	return 1;
    }
    else
	return 0;
#  endif
#else
#  if defined(USEMYBINMODE)
    if (my_binmode(fp, iotype, mode) != FALSE)
	return 1;
    else
	return 0;
#  else
    return 1;
#  endif
#endif
}

#ifndef PERLIO_LAYERS
int
PerlIO_apply_layers(pTHX_ PerlIO *f, const char *mode, const char *names)
{
 if (!names || !*names || strEQ(names,":crlf") || strEQ(names,":raw"))
  {
   return 0;
  }
 Perl_croak(aTHX_ "Cannot apply \"%s\" in non-PerlIO perl",names);
 /* NOTREACHED */
 return -1;
}

int
PerlIO_binmode(pTHX_ PerlIO *fp, int iotype, int mode, const char *names)
{
 return perlsio_binmode(fp,iotype,mode);
}

#endif


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

#include "perliol.h"

/* We _MUST_ have <unistd.h> if we are using lseek() and may have large files */
#ifdef I_UNISTD
#include <unistd.h>
#endif
#ifdef HAS_MMAP
#include <sys/mman.h>
#endif

#include "XSUB.h"

void PerlIO_debug(const char *fmt,...) __attribute__((format(__printf__,1,2)));

void
PerlIO_debug(const char *fmt,...)
{
 dTHX;
 static int dbg = 0;
 va_list ap;
 va_start(ap,fmt);
 if (!dbg)
  {
   char *s = PerlEnv_getenv("PERLIO_DEBUG");
   if (s && *s)
    dbg = PerlLIO_open3(s,O_WRONLY|O_CREAT|O_APPEND,0666);
   else
    dbg = -1;
  }
 if (dbg > 0)
  {
   dTHX;
   SV *sv = newSVpvn("",0);
   char *s;
   STRLEN len;
   s = CopFILE(PL_curcop);
   if (!s)
    s = "(none)";
   Perl_sv_catpvf(aTHX_ sv, "%s:%"IVdf" ", s, (IV)CopLINE(PL_curcop));
   Perl_sv_vcatpvf(aTHX_ sv, fmt, &ap);

   s = SvPV(sv,len);
   PerlLIO_write(dbg,s,len);
   SvREFCNT_dec(sv);
  }
 va_end(ap);
}

/*--------------------------------------------------------------------------------------*/

/* Inner level routines */

/* Table of pointers to the PerlIO structs (malloc'ed) */
PerlIO *_perlio      = NULL;
#define PERLIO_TABLE_SIZE 64

PerlIO *
PerlIO_allocate(pTHX)
{
 /* Find a free slot in the table, allocating new table as necessary */
 PerlIO **last;
 PerlIO *f;
 last = &_perlio;
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
 f = PerlMemShared_calloc(PERLIO_TABLE_SIZE,sizeof(PerlIO));
 if (!f)
  {
   return NULL;
  }
 *last = f;
 return f+1;
}

void
PerlIO_cleantable(pTHX_ PerlIO **tablep)
{
 PerlIO *table = *tablep;
 if (table)
  {
   int i;
   PerlIO_cleantable(aTHX_ (PerlIO **) &(table[0]));
   for (i=PERLIO_TABLE_SIZE-1; i > 0; i--)
    {
     PerlIO *f = table+i;
     if (*f)
      {
       PerlIO_close(f);
      }
    }
   PerlMemShared_free(table);
   *tablep = NULL;
  }
}

HV *PerlIO_layer_hv;
AV *PerlIO_layer_av;

void
PerlIO_cleanup()
{
 dTHX;
 PerlIO_cleantable(aTHX_ &_perlio);
}

void
PerlIO_pop(PerlIO *f)
{
 dTHX;
 PerlIOl *l = *f;
 if (l)
  {
   PerlIO_debug("PerlIO_pop f=%p %s\n",f,l->tab->name);
   if (l->tab->Popped)
    (*l->tab->Popped)(f);
   *f = l->next;
   PerlMemShared_free(l);
  }
}

/*--------------------------------------------------------------------------------------*/
/* XS Interface for perl code */

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
PerlIO_find_layer(const char *name, STRLEN len)
{
 dTHX;
 SV **svp;
 SV *sv;
 if ((SSize_t) len <= 0)
  len = strlen(name);
 svp  = hv_fetch(PerlIO_layer_hv,name,len,0);
 if (svp && (sv = *svp) && SvROK(sv))
  return *svp;
 return NULL;
}


static int
perlio_mg_set(pTHX_ SV *sv, MAGIC *mg)
{
 if (SvROK(sv))
  {
   IO *io = GvIOn((GV *)SvRV(sv));
   PerlIO *ifp = IoIFP(io);
   PerlIO *ofp = IoOFP(io);
   AV *av = (AV *) mg->mg_obj;
   Perl_warn(aTHX_ "set %"SVf" %p %p %p",sv,io,ifp,ofp);
  }
 return 0;
}

static int
perlio_mg_get(pTHX_ SV *sv, MAGIC *mg)
{
 if (SvROK(sv))
  {
   IO *io = GvIOn((GV *)SvRV(sv));
   PerlIO *ifp = IoIFP(io);
   PerlIO *ofp = IoOFP(io);
   AV *av = (AV *) mg->mg_obj;
   Perl_warn(aTHX_ "get %"SVf" %p %p %p",sv,io,ifp,ofp);
  }
 return 0;
}

static int
perlio_mg_clear(pTHX_ SV *sv, MAGIC *mg)
{
 Perl_warn(aTHX_ "clear %"SVf,sv);
 return 0;
}

static int
perlio_mg_free(pTHX_ SV *sv, MAGIC *mg)
{
 Perl_warn(aTHX_ "free %"SVf,sv);
 return 0;
}

MGVTBL perlio_vtab = {
 perlio_mg_get,
 perlio_mg_set,
 NULL, /* len */
 NULL,
 perlio_mg_free
};

XS(XS_io_MODIFY_SCALAR_ATTRIBUTES)
{
 dXSARGS;
 SV *sv    = SvRV(ST(1));
 AV *av    = newAV();
 MAGIC *mg;
 int count = 0;
 int i;
 sv_magic(sv, (SV *)av, '~', NULL, 0);
 SvRMAGICAL_off(sv);
 mg = mg_find(sv,'~');
 mg->mg_virtual = &perlio_vtab;
 mg_magical(sv);
 Perl_warn(aTHX_ "attrib %"SVf,sv);
 for (i=2; i < items; i++)
  {
   STRLEN len;
   const char *name = SvPV(ST(i),len);
   SV *layer  = PerlIO_find_layer(name,len);
   if (layer)
    {
     av_push(av,SvREFCNT_inc(layer));
    }
   else
    {
     ST(count) = ST(i);
     count++;
    }
  }
 SvREFCNT_dec(av);
 XSRETURN(count);
}

void
PerlIO_define_layer(PerlIO_funcs *tab)
{
 dTHX;
 HV *stash = gv_stashpv("perlio::Layer", TRUE);
 SV *sv = sv_bless(newRV_noinc(newSViv(PTR2IV(tab))),stash);
 if (!PerlIO_layer_hv)
  {
   PerlIO_layer_hv = get_hv("open::layers",GV_ADD|GV_ADDMULTI);
  }
 hv_store(PerlIO_layer_hv,tab->name,strlen(tab->name),sv,0);
 PerlIO_debug("define %s %p\n",tab->name,tab);
}

void
PerlIO_default_buffer(pTHX)
{
 PerlIO_funcs *tab = &PerlIO_perlio;
 if (O_BINARY != O_TEXT)
  {
   tab = &PerlIO_crlf;
  }
 else
  {
   if (PerlIO_stdio.Set_ptrcnt)
    {
     tab = &PerlIO_stdio;
    }
  }
 PerlIO_debug("Pushing %s\n",tab->name);
 av_push(PerlIO_layer_av,SvREFCNT_inc(PerlIO_find_layer(tab->name,0)));
}


PerlIO_funcs *
PerlIO_default_layer(I32 n)
{
 dTHX;
 SV **svp;
 SV *layer;
 PerlIO_funcs *tab = &PerlIO_stdio;
 int len;
 if (!PerlIO_layer_av)
  {
   const char *s  = PerlEnv_getenv("PERLIO");
   PerlIO_layer_av = get_av("open::layers",GV_ADD|GV_ADDMULTI);
   newXS("perlio::import",XS_perlio_import,__FILE__);
   newXS("perlio::unimport",XS_perlio_unimport,__FILE__);
#if 0
   newXS("io::MODIFY_SCALAR_ATTRIBUTES",XS_io_MODIFY_SCALAR_ATTRIBUTES,__FILE__);
#endif
   PerlIO_define_layer(&PerlIO_raw);
   PerlIO_define_layer(&PerlIO_unix);
   PerlIO_define_layer(&PerlIO_perlio);
   PerlIO_define_layer(&PerlIO_stdio);
   PerlIO_define_layer(&PerlIO_crlf);
#ifdef HAS_MMAP
   PerlIO_define_layer(&PerlIO_mmap);
#endif
   PerlIO_define_layer(&PerlIO_utf8);
   PerlIO_define_layer(&PerlIO_byte);
   av_push(PerlIO_layer_av,SvREFCNT_inc(PerlIO_find_layer(PerlIO_unix.name,0)));
   if (s)
    {
     IV buffered = 0;
     while (*s)
      {
       while (*s && isSPACE((unsigned char)*s))
        s++;
       if (*s)
        {
         const char *e = s;
         SV *layer;
         while (*e && !isSPACE((unsigned char)*e))
          e++;
         if (*s == ':')
          s++;
         layer = PerlIO_find_layer(s,e-s);
         if (layer)
          {
           PerlIO_funcs *tab = INT2PTR(PerlIO_funcs *, SvIV(SvRV(layer)));
           if ((tab->kind & PERLIO_K_DUMMY) && (tab->kind & PERLIO_K_BUFFERED))
            {
             if (!buffered)
              PerlIO_default_buffer(aTHX);
            }
           PerlIO_debug("Pushing %.*s\n",(e-s),s);
           av_push(PerlIO_layer_av,SvREFCNT_inc(layer));
           buffered |= (tab->kind & PERLIO_K_BUFFERED);
          }
         else
          Perl_warn(aTHX_ "perlio: unknown layer \"%.*s\"",(e-s),s);
         s = e;
        }
      }
    }
  }
 len  = av_len(PerlIO_layer_av);
 if (len < 1)
  {
   PerlIO_default_buffer(aTHX);
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
   dTHX;
   PerlIO_allocate(aTHX);
   PerlIO_fdopen(0,"Ir" PERLIO_STDTEXT);
   PerlIO_fdopen(1,"Iw" PERLIO_STDTEXT);
   PerlIO_fdopen(2,"Iw" PERLIO_STDTEXT);
  }
}

PerlIO *
PerlIO_push(PerlIO *f,PerlIO_funcs *tab,const char *mode,const char *arg,STRLEN len)
{
 dTHX;
 PerlIOl *l = NULL;
 l = PerlMemShared_calloc(tab->size,sizeof(char));
 if (l)
  {
   Zero(l,tab->size,char);
   l->next = *f;
   l->tab  = tab;
   *f      = l;
   PerlIO_debug("PerlIO_push f=%p %s %s\n",f,tab->name,(mode) ? mode : "(Null)");
   if ((*l->tab->Pushed)(f,mode,arg,len) != 0)
    {
     PerlIO_pop(f);
     return NULL;
    }
  }
 return f;
}

IV
PerlIORaw_pushed(PerlIO *f, const char *mode, const char *arg, STRLEN len)
{
 /* Pop back to bottom layer */
 if (f && *f && *PerlIONext(f))
  {
   PerlIO_flush(PerlIONext(f));
   while (*PerlIONext(f))
    {
     PerlIO_pop(f);
    }
   PerlIO_debug(":raw f=%p :%s\n",f,PerlIOBase(f)->tab->name);
   return 0;
  }
 return -1;
}

int
PerlIO_apply_layers(pTHX_ PerlIO *f, const char *mode, const char *names)
{
 if (names)
  {
   const char *s = names;
   while (*s)
    {
     while (isSPACE(*s) || *s == ':')
      s++;
     if (*s)
      {
       const char *e = s;
       const char *as = Nullch;
       const char *ae = Nullch;
       int count = 0;
       while (*e && *e != ':' && !isSPACE(*e))
        {
         if (*e == '(')
          {
           if (!as)
            as = e;
           count++;
          }
         else if (*e == ')')
          {
           if (as && --count == 0)
            ae = e;
          }
         e++;
        }
       if (e > s)
        {
         if ((e - s) == 3 && strncmp(s,"raw",3) == 0)
          {
           /* Pop back to bottom layer */
           if (PerlIONext(f))
            {
             PerlIO_flush(f);
             while (*PerlIONext(f))
              {
               PerlIO_pop(f);
              }
            }
           PerlIO_debug(":raw f=%p => :%s\n",f,PerlIOBase(f)->tab->name);
          }
         else if ((e - s) == 4 && strncmp(s,"utf8",4) == 0)
          {
           PerlIOBase(f)->flags |= PERLIO_F_UTF8;
          }
         else if ((e - s) == 5 && strncmp(s,"bytes",5) == 0)
          {
           PerlIOBase(f)->flags &= ~PERLIO_F_UTF8;
          }
         else
          {
           STRLEN len = ((as) ? as : e)-s;
           SV *layer = PerlIO_find_layer(s,len);
           if (layer)
            {
             PerlIO_funcs *tab = INT2PTR(PerlIO_funcs *, SvIV(SvRV(layer)));
             if (tab)
              {
	       if (as && (ae == Nullch)) {
		ae = e;
		Perl_warn(aTHX_ "perlio: argument list not closed for layer \"%.*s\"",(int)(e - s),s);
	       }
               len = (as) ? (ae-(as++)-1) : 0;
               if (!PerlIO_push(f,tab,mode,as,len))
                return -1;
              }
            }
           else
            Perl_warn(aTHX_ "perlio: unknown layer \"%.*s\"",(int)len,s);
          }
        }
       s = e;
      }
    }
  }
 return 0;
}



/*--------------------------------------------------------------------------------------*/
/* Given the abstraction above the public API functions */

int
PerlIO_binmode(pTHX_ PerlIO *f, int iotype, int mode, const char *names)
{
 PerlIO_debug("PerlIO_binmode f=%p %s %c %x %s\n",
              f,PerlIOBase(f)->tab->name,iotype,mode, (names) ? names : "(Null)");
 if (!names && (O_TEXT != O_BINARY && (mode & O_BINARY)))
  {
   PerlIO *top = f;
   PerlIOl *l;
   while (l = *top)
    {
     if (PerlIOBase(top)->tab == &PerlIO_crlf)
      {
       PerlIO_flush(top);
       PerlIOBase(top)->flags &= ~PERLIO_F_CRLF;
       break;
      }
     top = PerlIONext(top);
    }
  }
 return PerlIO_apply_layers(aTHX_ f, NULL, names) == 0 ? TRUE : FALSE;
}

#undef PerlIO__close
int
PerlIO__close(PerlIO *f)
{
 return (*PerlIOBase(f)->tab->Close)(f);
}

#undef PerlIO_fdupopen
PerlIO *
PerlIO_fdupopen(pTHX_ PerlIO *f)
{
 char buf[8];
 int fd = PerlLIO_dup(PerlIO_fileno(f));
 PerlIO *new = PerlIO_fdopen(fd,PerlIO_modestr(f,buf));
 if (new)
  {
   Off_t posn = PerlIO_tell(f);
   PerlIO_seek(new,posn,SEEK_SET);
  }
 return new;
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

#undef PerlIO_fileno
int
PerlIO_fileno(PerlIO *f)
{
 return (*PerlIOBase(f)->tab->Fileno)(f);
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

#undef PerlIO_reopen
PerlIO *
PerlIO_reopen(const char *path, const char *mode, PerlIO *f)
{
 if (f)
  {
   PerlIO_flush(f);
   if ((*PerlIOBase(f)->tab->Reopen)(path,mode,f) == 0)
    {
     if ((*PerlIOBase(f)->tab->Pushed)(f,mode,Nullch,0) == 0)
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
   PerlIO_funcs *tab = PerlIOBase(f)->tab;
   if (tab && tab->Flush)
    {
     return (*tab->Flush)(f);
    }
   else
    {
     PerlIO_debug("Cannot flush f=%p :%s\n",f,tab->name);
     errno = EINVAL;
     return -1;
    }
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
 if (f && *f)
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
 if (f && *f && (PerlIOBase(f)->flags & PERLIO_F_FASTGETS))
  {
   PerlIO_funcs *tab = PerlIOBase(f)->tab;
   return (tab->Set_ptrcnt != NULL);
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
 PerlIO_funcs *tab = PerlIOBase(f)->tab;
 if (tab->Get_ptr == NULL)
  return NULL;
 return (*tab->Get_ptr)(f);
}

#undef PerlIO_get_cnt
int
PerlIO_get_cnt(PerlIO *f)
{
 PerlIO_funcs *tab = PerlIOBase(f)->tab;
 if (tab->Get_cnt == NULL)
  return 0;
 return (*tab->Get_cnt)(f);
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
 PerlIO_funcs *tab = PerlIOBase(f)->tab;
 if (tab->Set_ptrcnt == NULL)
  {
   dTHX;
   Perl_croak(aTHX_ "PerlIO buffer snooping abuse");
  }
 (*PerlIOBase(f)->tab->Set_ptrcnt)(f,ptr,cnt);
}

/*--------------------------------------------------------------------------------------*/
/* utf8 and raw dummy layers */

IV
PerlIOUtf8_pushed(PerlIO *f, const char *mode, const char *arg, STRLEN len)
{
 if (PerlIONext(f))
  {
   PerlIO_funcs *tab = PerlIOBase(f)->tab;
   PerlIO_pop(f);
   if (tab->kind & PERLIO_K_UTF8)
    PerlIOBase(f)->flags |= PERLIO_F_UTF8;
   else
    PerlIOBase(f)->flags &= ~PERLIO_F_UTF8;
   return 0;
  }
 return -1;
}

PerlIO *
PerlIOUtf8_fdopen(PerlIO_funcs *self, int fd,const char *mode)
{
 PerlIO_funcs *tab = PerlIO_default_layer(-2);
 PerlIO *f = (*tab->Fdopen)(tab,fd,mode);
 if (f)
  {
   PerlIOl *l = PerlIOBase(f);
   if (tab->kind & PERLIO_K_UTF8)
    l->flags |= PERLIO_F_UTF8;
   else
    l->flags &= ~PERLIO_F_UTF8;
 }
 return f;
}

PerlIO *
PerlIOUtf8_open(PerlIO_funcs *self, const char *path,const char *mode)
{
 PerlIO_funcs *tab = PerlIO_default_layer(-2);
 PerlIO *f = (*tab->Open)(tab,path,mode);
 if (f)
  {
   PerlIOl *l = PerlIOBase(f);
   if (tab->kind & PERLIO_K_UTF8)
    l->flags |= PERLIO_F_UTF8;
   else
    l->flags &= ~PERLIO_F_UTF8;
  }
 return f;
}

PerlIO_funcs PerlIO_utf8 = {
 "utf8",
 sizeof(PerlIOl),
 PERLIO_K_DUMMY|PERLIO_F_UTF8,
 NULL,
 PerlIOUtf8_fdopen,
 PerlIOUtf8_open,
 NULL,
 PerlIOUtf8_pushed,
 NULL,
 NULL,
 NULL,
 NULL,
 NULL,
 NULL,
 NULL,
 NULL, /* flush */
 NULL, /* fill */
 NULL,
 NULL,
 NULL,
 NULL,
 NULL, /* get_base */
 NULL, /* get_bufsiz */
 NULL, /* get_ptr */
 NULL, /* get_cnt */
 NULL, /* set_ptrcnt */
};

PerlIO_funcs PerlIO_byte = {
 "bytes",
 sizeof(PerlIOl),
 PERLIO_K_DUMMY,
 NULL,
 PerlIOUtf8_fdopen,
 PerlIOUtf8_open,
 NULL,
 PerlIOUtf8_pushed,
 NULL,
 NULL,
 NULL,
 NULL,
 NULL,
 NULL,
 NULL,
 NULL, /* flush */
 NULL, /* fill */
 NULL,
 NULL,
 NULL,
 NULL,
 NULL, /* get_base */
 NULL, /* get_bufsiz */
 NULL, /* get_ptr */
 NULL, /* get_cnt */
 NULL, /* set_ptrcnt */
};

PerlIO *
PerlIORaw_fdopen(PerlIO_funcs *self, int fd,const char *mode)
{
 PerlIO_funcs *tab = PerlIO_default_layer(0);
 return (*tab->Fdopen)(tab,fd,mode);
}

PerlIO *
PerlIORaw_open(PerlIO_funcs *self, const char *path,const char *mode)
{
 PerlIO_funcs *tab = PerlIO_default_layer(0);
 return (*tab->Open)(tab,path,mode);
}

PerlIO_funcs PerlIO_raw = {
 "raw",
 sizeof(PerlIOl),
 PERLIO_K_DUMMY|PERLIO_K_RAW,
 NULL,
 PerlIORaw_fdopen,
 PerlIORaw_open,
 NULL,
 PerlIORaw_pushed,
 PerlIOBase_popped,
 NULL,
 NULL,
 NULL,
 NULL,
 NULL,
 NULL,
 NULL, /* flush */
 NULL, /* fill */
 NULL,
 NULL,
 NULL,
 NULL,
 NULL, /* get_base */
 NULL, /* get_bufsiz */
 NULL, /* get_ptr */
 NULL, /* get_cnt */
 NULL, /* set_ptrcnt */
};
/*--------------------------------------------------------------------------------------*/
/*--------------------------------------------------------------------------------------*/
/* "Methods" of the "base class" */

IV
PerlIOBase_fileno(PerlIO *f)
{
 return PerlIO_fileno(PerlIONext(f));
}

char *
PerlIO_modestr(PerlIO *f,char *buf)
{
 char *s = buf;
 IV flags = PerlIOBase(f)->flags;
 if (flags & PERLIO_F_APPEND)
  {
   *s++ = 'a';
   if (flags & PERLIO_F_CANREAD)
    {
     *s++ = '+';
    }
  }
 else if (flags & PERLIO_F_CANREAD)
  {
   *s++ = 'r';
   if (flags & PERLIO_F_CANWRITE)
    *s++ = '+';
  }
 else if (flags & PERLIO_F_CANWRITE)
  {
   *s++ = 'w';
   if (flags & PERLIO_F_CANREAD)
    {
     *s++ = '+';
    }
  }
#if O_TEXT != O_BINARY
 if (!(flags & PERLIO_F_CRLF))
  *s++ = 'b';
#endif
 *s = '\0';
 return buf;
}

IV
PerlIOBase_pushed(PerlIO *f, const char *mode, const char *arg, STRLEN len)
{
 PerlIOl *l = PerlIOBase(f);
 const char *omode = mode;
 char temp[8];
 PerlIO_funcs *tab = PerlIOBase(f)->tab;
 l->flags  &= ~(PERLIO_F_CANREAD|PERLIO_F_CANWRITE|
                PERLIO_F_TRUNCATE|PERLIO_F_APPEND);
 if (tab->Set_ptrcnt != NULL)
  l->flags |= PERLIO_F_FASTGETS;
 if (mode)
  {
   switch (*mode++)
    {
     case 'r':
      l->flags |= PERLIO_F_CANREAD;
      break;
     case 'a':
      l->flags |= PERLIO_F_APPEND|PERLIO_F_CANWRITE;
      break;
     case 'w':
      l->flags |= PERLIO_F_TRUNCATE|PERLIO_F_CANWRITE;
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
        l->flags &= ~PERLIO_F_CRLF;
        break;
       case 't':
        l->flags |= PERLIO_F_CRLF;
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
                 (PERLIO_F_CANREAD|PERLIO_F_CANWRITE|PERLIO_F_TRUNCATE|PERLIO_F_APPEND);
    }
  }
#if 0
 PerlIO_debug("PerlIOBase_pushed f=%p %s %s fl=%08"UVxf" (%s)\n",
              f,PerlIOBase(f)->tab->name,(omode) ? omode : "(Null)",
              l->flags,PerlIO_modestr(f,temp));
#endif
 return 0;
}

IV
PerlIOBase_popped(PerlIO *f)
{
 return 0;
}

SSize_t
PerlIOBase_unread(PerlIO *f, const void *vbuf, Size_t count)
{
 Off_t old = PerlIO_tell(f);
 SSize_t done;
 PerlIO_push(f,&PerlIO_pending,"r",Nullch,0);
 done = PerlIOBuf_unread(f,vbuf,count);
 PerlIOSelf(f,PerlIOBuf)->posn = old - done;
 return done;
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
 PerlIO *n = PerlIONext(f);
 if (PerlIO_flush(f) != 0)
  code = -1;
 if (n && (*PerlIOBase(n)->tab->Close)(n) != 0)
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
   PerlIO *n = PerlIONext(f);
   PerlIOBase(f)->flags &= ~(PERLIO_F_ERROR|PERLIO_F_EOF);
   if (n)
    PerlIO_clearerr(n);
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
 if (*mode == 'b')
  {
   oflags |=  O_BINARY;
   oflags &= ~O_TEXT;
   mode++;
  }
 else if (*mode == 't')
  {
   oflags |=  O_TEXT;
   oflags &= ~O_BINARY;
   mode++;
  }
 /* Always open in binary mode */
 oflags |= O_BINARY;
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
 dTHX;
 PerlIO *f = NULL;
 if (*mode == 'I')
  mode++;
 if (fd >= 0)
  {
   int oflags = PerlIOUnix_oflags(mode);
   if (oflags != -1)
    {
     PerlIOUnix *s = PerlIOSelf(PerlIO_push(f = PerlIO_allocate(aTHX),self,mode,Nullch,0),PerlIOUnix);
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
 dTHX;
 PerlIO *f = NULL;
 int oflags = PerlIOUnix_oflags(mode);
 if (oflags != -1)
  {
   int fd = PerlLIO_open3(path,oflags,0666);
   if (fd >= 0)
    {
     PerlIOUnix *s = PerlIOSelf(PerlIO_push(f = PerlIO_allocate(aTHX),self,mode,Nullch,0),PerlIOUnix);
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
   dTHX;
   int fd = PerlLIO_open3(path,oflags,0666);
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
 dTHX;
 int fd = PerlIOSelf(f,PerlIOUnix)->fd;
 if (!(PerlIOBase(f)->flags & PERLIO_F_CANREAD))
  return 0;
 while (1)
  {
   SSize_t len = PerlLIO_read(fd,vbuf,count);
   if (len >= 0 || errno != EINTR)
    {
     if (len < 0)
      PerlIOBase(f)->flags |= PERLIO_F_ERROR;
     else if (len == 0 && count != 0)
      PerlIOBase(f)->flags |= PERLIO_F_EOF;
     return len;
    }
   PERL_ASYNC_CHECK();
  }
}

SSize_t
PerlIOUnix_write(PerlIO *f, const void *vbuf, Size_t count)
{
 dTHX;
 int fd = PerlIOSelf(f,PerlIOUnix)->fd;
 while (1)
  {
   SSize_t len = PerlLIO_write(fd,vbuf,count);
   if (len >= 0 || errno != EINTR)
    {
     if (len < 0)
      PerlIOBase(f)->flags |= PERLIO_F_ERROR;
     return len;
    }
   PERL_ASYNC_CHECK();
  }
}

IV
PerlIOUnix_seek(PerlIO *f, Off_t offset, int whence)
{
 dTHX;
 Off_t new = PerlLIO_lseek(PerlIOSelf(f,PerlIOUnix)->fd,offset,whence);
 PerlIOBase(f)->flags &= ~PERLIO_F_EOF;
 return (new == (Off_t) -1) ? -1 : 0;
}

Off_t
PerlIOUnix_tell(PerlIO *f)
{
 dTHX;
 Off_t posn = PerlLIO_lseek(PerlIOSelf(f,PerlIOUnix)->fd,0,SEEK_CUR);
 return PerlLIO_lseek(PerlIOSelf(f,PerlIOUnix)->fd,0,SEEK_CUR);
}

IV
PerlIOUnix_close(PerlIO *f)
{
 dTHX;
 int fd = PerlIOSelf(f,PerlIOUnix)->fd;
 int code = 0;
 while (PerlLIO_close(fd) != 0)
  {
   if (errno != EINTR)
    {
     code = -1;
     break;
    }
   PERL_ASYNC_CHECK();
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
 PERLIO_K_RAW,
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
 PerlIOBase_noop_ok,   /* flush */
 PerlIOBase_noop_fail, /* fill */
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

typedef struct
{
 struct _PerlIO	base;
 FILE *		stdio;      /* The stream */
} PerlIOStdio;

IV
PerlIOStdio_fileno(PerlIO *f)
{
 dTHX;
 return PerlSIO_fileno(PerlIOSelf(f,PerlIOStdio)->stdio);
}

char *
PerlIOStdio_mode(const char *mode,char *tmode)
{
 char *ret = tmode;
 while (*mode)
  {
   *tmode++ = *mode++;
  }
 if (O_BINARY != O_TEXT)
  {
   *tmode++ = 'b';
  }
 *tmode = '\0';
 return ret;
}

PerlIO *
PerlIOStdio_fdopen(PerlIO_funcs *self, int fd,const char *mode)
{
 dTHX;
 PerlIO *f = NULL;
 int init = 0;
 char tmode[8];
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
        stdio = PerlSIO_stdin;
        break;
       case 1:
        stdio = PerlSIO_stdout;
        break;
       case 2:
        stdio = PerlSIO_stderr;
        break;
      }
    }
   else
    {
     stdio = PerlSIO_fdopen(fd,mode = PerlIOStdio_mode(mode,tmode));
    }
   if (stdio)
    {
     PerlIOStdio *s = PerlIOSelf(PerlIO_push(f = PerlIO_allocate(aTHX),self,mode,Nullch,0),PerlIOStdio);
     s->stdio  = stdio;
    }
  }
 return f;
}

#undef PerlIO_importFILE
PerlIO *
PerlIO_importFILE(FILE *stdio, int fl)
{
 dTHX;
 PerlIO *f = NULL;
 if (stdio)
  {
   PerlIOStdio *s = PerlIOSelf(PerlIO_push(f = PerlIO_allocate(aTHX),&PerlIO_stdio,"r+",Nullch,0),PerlIOStdio);
   s->stdio  = stdio;
  }
 return f;
}

PerlIO *
PerlIOStdio_open(PerlIO_funcs *self, const char *path,const char *mode)
{
 dTHX;
 PerlIO *f = NULL;
 FILE *stdio = PerlSIO_fopen(path,mode);
 if (stdio)
  {
   char tmode[8];
   PerlIOStdio *s = PerlIOSelf(PerlIO_push(f = PerlIO_allocate(aTHX), self,
                               (mode = PerlIOStdio_mode(mode,tmode)),Nullch,0),
                               PerlIOStdio);
   s->stdio  = stdio;
  }
 return f;
}

int
PerlIOStdio_reopen(const char *path, const char *mode, PerlIO *f)
{
 dTHX;
 PerlIOStdio *s = PerlIOSelf(f,PerlIOStdio);
 char tmode[8];
 FILE *stdio = PerlSIO_freopen(path,(mode = PerlIOStdio_mode(mode,tmode)),s->stdio);
 if (!s->stdio)
  return -1;
 s->stdio = stdio;
 return 0;
}

SSize_t
PerlIOStdio_read(PerlIO *f, void *vbuf, Size_t count)
{
 dTHX;
 FILE *s = PerlIOSelf(f,PerlIOStdio)->stdio;
 SSize_t got = 0;
 if (count == 1)
  {
   STDCHAR *buf = (STDCHAR *) vbuf;
   /* Perl is expecting PerlIO_getc() to fill the buffer
    * Linux's stdio does not do that for fread()
    */
   int ch = PerlSIO_fgetc(s);
   if (ch != EOF)
    {
     *buf = ch;
     got = 1;
    }
  }
 else
  got = PerlSIO_fread(vbuf,1,count,s);
 return got;
}

SSize_t
PerlIOStdio_unread(PerlIO *f, const void *vbuf, Size_t count)
{
 dTHX;
 FILE *s = PerlIOSelf(f,PerlIOStdio)->stdio;
 STDCHAR *buf = ((STDCHAR *)vbuf)+count-1;
 SSize_t unread = 0;
 while (count > 0)
  {
   int ch = *buf-- & 0xff;
   if (PerlSIO_ungetc(ch,s) != ch)
    break;
   unread++;
   count--;
  }
 return unread;
}

SSize_t
PerlIOStdio_write(PerlIO *f, const void *vbuf, Size_t count)
{
 dTHX;
 return PerlSIO_fwrite(vbuf,1,count,PerlIOSelf(f,PerlIOStdio)->stdio);
}

IV
PerlIOStdio_seek(PerlIO *f, Off_t offset, int whence)
{
 dTHX;
 FILE *stdio = PerlIOSelf(f,PerlIOStdio)->stdio;
 return PerlSIO_fseek(stdio,offset,whence);
}

Off_t
PerlIOStdio_tell(PerlIO *f)
{
 dTHX;
 FILE *stdio = PerlIOSelf(f,PerlIOStdio)->stdio;
 return PerlSIO_ftell(stdio);
}

IV
PerlIOStdio_close(PerlIO *f)
{
 dTHX;
#ifdef HAS_SOCKET
 int optval, optlen = sizeof(int);
#endif
 FILE *stdio = PerlIOSelf(f,PerlIOStdio)->stdio;
 return(
#ifdef HAS_SOCKET
   (getsockopt(PerlIO_fileno(f), SOL_SOCKET, SO_TYPE, (char *)&optval, &optlen) < 0) ?
       PerlSIO_fclose(stdio) :
       close(PerlIO_fileno(f))
#else
   PerlSIO_fclose(stdio)
#endif
     );

}

IV
PerlIOStdio_flush(PerlIO *f)
{
 dTHX;
 FILE *stdio = PerlIOSelf(f,PerlIOStdio)->stdio;
 if (PerlIOBase(f)->flags & PERLIO_F_CANWRITE)
  {
   return PerlSIO_fflush(stdio);
  }
 else
  {
#if 0
   /* FIXME: This discards ungetc() and pre-read stuff which is
      not right if this is just a "sync" from a layer above
      Suspect right design is to do _this_ but not have layer above
      flush this layer read-to-read
    */
   /* Not writeable - sync by attempting a seek */
   int err = errno;
   if (PerlSIO_fseek(stdio,(Off_t) 0, SEEK_CUR) != 0)
    errno = err;
#endif
  }
 return 0;
}

IV
PerlIOStdio_fill(PerlIO *f)
{
 dTHX;
 FILE *stdio = PerlIOSelf(f,PerlIOStdio)->stdio;
 int c;
 /* fflush()ing read-only streams can cause trouble on some stdio-s */
 if ((PerlIOBase(f)->flags & PERLIO_F_CANWRITE))
  {
   if (PerlSIO_fflush(stdio) != 0)
    return EOF;
  }
 c = PerlSIO_fgetc(stdio);
 if (c == EOF || PerlSIO_ungetc(c,stdio) != c)
  return EOF;
 return 0;
}

IV
PerlIOStdio_eof(PerlIO *f)
{
 dTHX;
 return PerlSIO_feof(PerlIOSelf(f,PerlIOStdio)->stdio);
}

IV
PerlIOStdio_error(PerlIO *f)
{
 dTHX;
 return PerlSIO_ferror(PerlIOSelf(f,PerlIOStdio)->stdio);
}

void
PerlIOStdio_clearerr(PerlIO *f)
{
 dTHX;
 PerlSIO_clearerr(PerlIOSelf(f,PerlIOStdio)->stdio);
}

void
PerlIOStdio_setlinebuf(PerlIO *f)
{
 dTHX;
#ifdef HAS_SETLINEBUF
 PerlSIO_setlinebuf(PerlIOSelf(f,PerlIOStdio)->stdio);
#else
 PerlSIO_setvbuf(PerlIOSelf(f,PerlIOStdio)->stdio, Nullch, _IOLBF, 0);
#endif
}

#ifdef FILE_base
STDCHAR *
PerlIOStdio_get_base(PerlIO *f)
{
 dTHX;
 FILE *stdio  = PerlIOSelf(f,PerlIOStdio)->stdio;
 return PerlSIO_get_base(stdio);
}

Size_t
PerlIOStdio_get_bufsiz(PerlIO *f)
{
 dTHX;
 FILE *stdio = PerlIOSelf(f,PerlIOStdio)->stdio;
 return PerlSIO_get_bufsiz(stdio);
}
#endif

#ifdef USE_STDIO_PTR
STDCHAR *
PerlIOStdio_get_ptr(PerlIO *f)
{
 dTHX;
 FILE *stdio = PerlIOSelf(f,PerlIOStdio)->stdio;
 return PerlSIO_get_ptr(stdio);
}

SSize_t
PerlIOStdio_get_cnt(PerlIO *f)
{
 dTHX;
 FILE *stdio = PerlIOSelf(f,PerlIOStdio)->stdio;
 return PerlSIO_get_cnt(stdio);
}

void
PerlIOStdio_set_ptrcnt(PerlIO *f,STDCHAR *ptr,SSize_t cnt)
{
 dTHX;
 FILE *stdio = PerlIOSelf(f,PerlIOStdio)->stdio;
 if (ptr != NULL)
  {
#ifdef STDIO_PTR_LVALUE
   PerlSIO_set_ptr(stdio,ptr);
#ifdef STDIO_PTR_LVAL_SETS_CNT
   if (PerlSIO_get_cnt(stdio) != (cnt))
    {
     dTHX;
     assert(PerlSIO_get_cnt(stdio) == (cnt));
    }
#endif
#if (!defined(STDIO_PTR_LVAL_NOCHANGE_CNT))
   /* Setting ptr _does_ change cnt - we are done */
   return;
#endif
#else  /* STDIO_PTR_LVALUE */
   PerlProc_abort();
#endif /* STDIO_PTR_LVALUE */
  }
/* Now (or only) set cnt */
#ifdef STDIO_CNT_LVALUE
 PerlSIO_set_cnt(stdio,cnt);
#else  /* STDIO_CNT_LVALUE */
#if (defined(STDIO_PTR_LVALUE) && defined(STDIO_PTR_LVAL_SETS_CNT))
 PerlSIO_set_ptr(stdio,PerlSIO_get_ptr(stdio)+(PerlSIO_get_cnt(stdio)-cnt));
#else  /* STDIO_PTR_LVAL_SETS_CNT */
 PerlProc_abort();
#endif /* STDIO_PTR_LVAL_SETS_CNT */
#endif /* STDIO_CNT_LVALUE */
}

#endif

PerlIO_funcs PerlIO_stdio = {
 "stdio",
 sizeof(PerlIOStdio),
 PERLIO_K_BUFFERED,
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
 FILE *stdio;
 PerlIO_flush(f);
 stdio = fdopen(PerlIO_fileno(f),"r+");
 if (stdio)
  {
   PerlIOStdio *s = PerlIOSelf(PerlIO_push(f,&PerlIO_stdio,"r+",Nullch,0),PerlIOStdio);
   s->stdio  = stdio;
  }
 return stdio;
}

#undef PerlIO_findFILE
FILE *
PerlIO_findFILE(PerlIO *f)
{
 PerlIOl *l = *f;
 while (l)
  {
   if (l->tab == &PerlIO_stdio)
    {
     PerlIOStdio *s = PerlIOSelf(&l,PerlIOStdio);
     return s->stdio;
    }
   l = *PerlIONext(&l);
  }
 return PerlIO_exportFILE(f,0);
}

#undef PerlIO_releaseFILE
void
PerlIO_releaseFILE(PerlIO *p, FILE *f)
{
}

/*--------------------------------------------------------------------------------------*/
/* perlio buffer layer */

IV
PerlIOBuf_pushed(PerlIO *f, const char *mode, const char *arg, STRLEN len)
{
 PerlIOBuf *b = PerlIOSelf(f,PerlIOBuf);
 b->posn = PerlIO_tell(PerlIONext(f));
 return PerlIOBase_pushed(f,mode,arg,len);
}

PerlIO *
PerlIOBuf_fdopen(PerlIO_funcs *self, int fd, const char *mode)
{
 dTHX;
 PerlIO_funcs *tab = PerlIO_default_btm();
 int init = 0;
 PerlIO *f;
 if (*mode == 'I')
  {
   init = 1;
   mode++;
  }
#if O_BINARY != O_TEXT
 /* do something about failing setmode()? --jhi */
 PerlLIO_setmode(fd, O_BINARY);
#endif
 f = (*tab->Fdopen)(tab,fd,mode);
 if (f)
  {
   PerlIOBuf *b = PerlIOSelf(PerlIO_push(f,self,mode,Nullch,0),PerlIOBuf);
   if (init && fd == 2)
    {
     /* Initial stderr is unbuffered */
     PerlIOBase(f)->flags |= PERLIO_F_UNBUF;
    }
#if 0
   PerlIO_debug("PerlIOBuf_fdopen %s f=%p fd=%d m=%s fl=%08"UVxf"\n",
                self->name,f,fd,mode,PerlIOBase(f)->flags);
#endif
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
   PerlIO_push(f,self,mode,Nullch,0);
  }
 return f;
}

int
PerlIOBuf_reopen(const char *path, const char *mode, PerlIO *f)
{
 PerlIO *next = PerlIONext(f);
 int code = (*PerlIOBase(next)->tab->Reopen)(path,mode,next);
 if (code = 0)
  code = (*PerlIOBase(f)->tab->Pushed)(f,mode,Nullch,0);
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
   STDCHAR *buf = b->buf;
   STDCHAR *p = buf;
   int count;
   PerlIO *n = PerlIONext(f);
   while (p < b->ptr)
    {
     count = PerlIO_write(n,p,b->ptr - p);
     if (count > 0)
      {
       p += count;
      }
     else if (count < 0 || PerlIO_error(n))
      {
       PerlIOBase(f)->flags |= PERLIO_F_ERROR;
       code = -1;
       break;
      }
    }
   b->posn += (p - buf);
  }
 else if (PerlIOBase(f)->flags & PERLIO_F_RDBUF)
  {
   STDCHAR *buf = PerlIO_get_base(f);
   /* Note position change */
   b->posn += (b->ptr - buf);
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
 /* FIXME: Is this right for read case ? */
 if (PerlIO_flush(PerlIONext(f)) != 0)
  code = -1;
 return code;
}

IV
PerlIOBuf_fill(PerlIO *f)
{
 PerlIOBuf *b = PerlIOSelf(f,PerlIOBuf);
 PerlIO *n = PerlIONext(f);
 SSize_t avail;
 /* FIXME: doing the down-stream flush is a bad idea if it causes
    pre-read data in stdio buffer to be discarded
    but this is too simplistic - as it skips _our_ hosekeeping
    and breaks tell tests.
 if (!(PerlIOBase(f)->flags & PERLIO_F_RDBUF))
  {
  }
  */
 if (PerlIO_flush(f) != 0)
  return -1;

 if (!b->buf)
  PerlIO_get_base(f); /* allocate via vtable */

 b->ptr = b->end = b->buf;
 if (PerlIO_fast_gets(n))
  {
   /* Layer below is also buffered
    * We do _NOT_ want to call its ->Read() because that will loop
    * till it gets what we asked for which may hang on a pipe etc.
    * Instead take anything it has to hand, or ask it to fill _once_.
    */
   avail  = PerlIO_get_cnt(n);
   if (avail <= 0)
    {
     avail = PerlIO_fill(n);
     if (avail == 0)
      avail = PerlIO_get_cnt(n);
     else
      {
       if (!PerlIO_error(n) && PerlIO_eof(n))
        avail = 0;
      }
    }
   if (avail > 0)
    {
     STDCHAR *ptr = PerlIO_get_ptr(n);
     SSize_t cnt  = avail;
     if (avail > b->bufsiz)
      avail = b->bufsiz;
     Copy(ptr,b->buf,avail,STDCHAR);
     PerlIO_set_ptrcnt(n,ptr+avail,cnt-avail);
    }
  }
 else
  {
   avail = PerlIO_read(n,b->ptr,b->bufsiz);
  }
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
 PerlIOBuf *b  = PerlIOSelf(f,PerlIOBuf);
 STDCHAR *buf  = (STDCHAR *) vbuf;
 if (f)
  {
   if (!b->ptr)
    PerlIO_get_base(f);
   if (!(PerlIOBase(f)->flags & PERLIO_F_CANREAD))
    return 0;
   while (count > 0)
    {
     SSize_t avail = PerlIO_get_cnt(f);
     SSize_t take  = (count < avail) ? count : avail;
     if (take > 0)
      {
       STDCHAR *ptr = PerlIO_get_ptr(f);
       Copy(ptr,buf,take,STDCHAR);
       PerlIO_set_ptrcnt(f,ptr+take,(avail -= take));
       count   -= take;
       buf     += take;
      }
     if (count > 0  && avail <= 0)
      {
       if (PerlIO_fill(f) != 0)
        break;
      }
    }
   return (buf - (STDCHAR *) vbuf);
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
    }
   else
    {
     avail = b->bufsiz;
     b->end = b->buf + avail;
     b->ptr = b->end;
     PerlIOBase(f)->flags |= PERLIO_F_RDBUF;
     b->posn -= b->bufsiz;
    }
   if (avail > (SSize_t) count)
    avail = count;
   if (avail > 0)
    {
     b->ptr -= avail;
     buf    -= avail;
     if (buf != b->ptr)
      {
       Copy(buf,b->ptr,avail,STDCHAR);
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
       Copy(buf,b->ptr,avail,STDCHAR);
       count   -= avail;
       buf     += avail;
       written += avail;
       b->ptr  += avail;
      }
    }
   if (b->ptr >= (b->buf + b->bufsiz))
    PerlIO_flush(f);
  }
 if (PerlIOBase(f)->flags & PERLIO_F_UNBUF)
  PerlIO_flush(f);
 return written;
}

IV
PerlIOBuf_seek(PerlIO *f, Off_t offset, int whence)
{
 IV code;
 if ((code = PerlIO_flush(f)) == 0)
  {
   PerlIOBuf *b = PerlIOSelf(f,PerlIOBuf);
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
 dTHX;
 IV code = PerlIOBase_close(f);
 PerlIOBuf *b = PerlIOSelf(f,PerlIOBuf);
 if (b->buf && b->buf != (STDCHAR *) &b->oneword)
  {
   PerlMemShared_free(b->buf);
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
   dTHX;
   if (!b->bufsiz)
    b->bufsiz = 4096;
   b->buf = PerlMemShared_calloc(b->bufsiz,sizeof(STDCHAR));
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
 PERLIO_K_BUFFERED,
 PerlIOBase_fileno,
 PerlIOBuf_fdopen,
 PerlIOBuf_open,
 PerlIOBuf_reopen,
 PerlIOBuf_pushed,
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

/*--------------------------------------------------------------------------------------*/
/* Temp layer to hold unread chars when cannot do it any other way */

IV
PerlIOPending_fill(PerlIO *f)
{
 /* Should never happen */
 PerlIO_flush(f);
 return 0;
}

IV
PerlIOPending_close(PerlIO *f)
{
 /* A tad tricky - flush pops us, then we close new top */
 PerlIO_flush(f);
 return PerlIO_close(f);
}

IV
PerlIOPending_seek(PerlIO *f, Off_t offset, int whence)
{
 /* A tad tricky - flush pops us, then we seek new top */
 PerlIO_flush(f);
 return PerlIO_seek(f,offset,whence);
}


IV
PerlIOPending_flush(PerlIO *f)
{
 PerlIOBuf *b = PerlIOSelf(f,PerlIOBuf);
 if (b->buf && b->buf != (STDCHAR *) &b->oneword)
  {
   dTHX;
   PerlMemShared_free(b->buf);
   b->buf = NULL;
  }
 PerlIO_pop(f);
 return 0;
}

void
PerlIOPending_set_ptrcnt(PerlIO *f, STDCHAR *ptr, SSize_t cnt)
{
 if (cnt <= 0)
  {
   PerlIO_flush(f);
  }
 else
  {
   PerlIOBuf_set_ptrcnt(f,ptr,cnt);
  }
}

IV
PerlIOPending_pushed(PerlIO *f,const char *mode,const char *arg,STRLEN len)
{
 IV code    = PerlIOBase_pushed(f,mode,arg,len);
 PerlIOl *l = PerlIOBase(f);
 /* Our PerlIO_fast_gets must match what we are pushed on,
    or sv_gets() etc. get muddled when it changes mid-string
    when we auto-pop.
  */
 l->flags   = (l->flags & ~(PERLIO_F_FASTGETS|PERLIO_F_UTF8)) |
              (PerlIOBase(PerlIONext(f))->flags & (PERLIO_F_FASTGETS|PERLIO_F_UTF8));
 return code;
}

SSize_t
PerlIOPending_read(PerlIO *f, void *vbuf, Size_t count)
{
 SSize_t avail = PerlIO_get_cnt(f);
 SSize_t got   = 0;
 if (count < avail)
  avail = count;
 if (avail > 0)
  got = PerlIOBuf_read(f,vbuf,avail);
 if (got < count)
  got += PerlIO_read(f,((STDCHAR *) vbuf)+got,count-got);
 return got;
}


PerlIO_funcs PerlIO_pending = {
 "pending",
 sizeof(PerlIOBuf),
 PERLIO_K_BUFFERED,
 PerlIOBase_fileno,
 NULL,
 NULL,
 NULL,
 PerlIOPending_pushed,
 PerlIOBase_noop_ok,
 PerlIOPending_read,
 PerlIOBuf_unread,
 PerlIOBuf_write,
 PerlIOPending_seek,
 PerlIOBuf_tell,
 PerlIOPending_close,
 PerlIOPending_flush,
 PerlIOPending_fill,
 PerlIOBase_eof,
 PerlIOBase_error,
 PerlIOBase_clearerr,
 PerlIOBuf_setlinebuf,
 PerlIOBuf_get_base,
 PerlIOBuf_bufsiz,
 PerlIOBuf_get_ptr,
 PerlIOBuf_get_cnt,
 PerlIOPending_set_ptrcnt,
};



/*--------------------------------------------------------------------------------------*/
/* crlf - translation
   On read translate CR,LF to "\n" we do this by overriding ptr/cnt entries
   to hand back a line at a time and keeping a record of which nl we "lied" about.
   On write translate "\n" to CR,LF
 */

typedef struct
{
 PerlIOBuf	base;         /* PerlIOBuf stuff */
 STDCHAR       *nl;           /* Position of crlf we "lied" about in the buffer */
} PerlIOCrlf;

IV
PerlIOCrlf_pushed(PerlIO *f, const char *mode,const char *arg,STRLEN len)
{
 IV code;
 PerlIOBase(f)->flags |= PERLIO_F_CRLF;
 code = PerlIOBuf_pushed(f,mode,arg,len);
#if 0
 PerlIO_debug("PerlIOCrlf_pushed f=%p %s %s fl=%08"UVxf"\n",
              f,PerlIOBase(f)->tab->name,(mode) ? mode : "(Null)",
              PerlIOBase(f)->flags);
#endif
 return code;
}


SSize_t
PerlIOCrlf_unread(PerlIO *f, const void *vbuf, Size_t count)
{
 PerlIOCrlf *c = PerlIOSelf(f,PerlIOCrlf);
 if (c->nl)
  {
   *(c->nl) = 0xd;
   c->nl = NULL;
  }
 if (!(PerlIOBase(f)->flags & PERLIO_F_CRLF))
  return PerlIOBuf_unread(f,vbuf,count);
 else
  {
   const STDCHAR *buf = (const STDCHAR *) vbuf+count;
   PerlIOBuf *b = PerlIOSelf(f,PerlIOBuf);
   SSize_t unread = 0;
   if (PerlIOBase(f)->flags & PERLIO_F_WRBUF)
    PerlIO_flush(f);
   if (!b->buf)
    PerlIO_get_base(f);
   if (b->buf)
    {
     if (!(PerlIOBase(f)->flags & PERLIO_F_RDBUF))
      {
       b->end = b->ptr = b->buf + b->bufsiz;
       PerlIOBase(f)->flags |= PERLIO_F_RDBUF;
       b->posn -= b->bufsiz;
      }
     while (count > 0 && b->ptr > b->buf)
      {
       int ch = *--buf;
       if (ch == '\n')
        {
         if (b->ptr - 2 >= b->buf)
          {
           *--(b->ptr) = 0xa;
           *--(b->ptr) = 0xd;
           unread++;
           count--;
          }
         else
          {
           buf++;
           break;
          }
        }
       else
        {
         *--(b->ptr) = ch;
         unread++;
         count--;
        }
      }
    }
   return unread;
  }
}

SSize_t
PerlIOCrlf_get_cnt(PerlIO *f)
{
 PerlIOBuf *b = PerlIOSelf(f,PerlIOBuf);
 if (!b->buf)
  PerlIO_get_base(f);
 if (PerlIOBase(f)->flags & PERLIO_F_RDBUF)
  {
   PerlIOCrlf *c = PerlIOSelf(f,PerlIOCrlf);
   if ((PerlIOBase(f)->flags & PERLIO_F_CRLF) && !c->nl)
    {
     STDCHAR *nl   = b->ptr;
    scan:
     while (nl < b->end && *nl != 0xd)
      nl++;
     if (nl < b->end && *nl == 0xd)
      {
     test:
       if (nl+1 < b->end)
        {
         if (nl[1] == 0xa)
          {
           *nl   = '\n';
           c->nl = nl;
          }
         else
          {
           /* Not CR,LF but just CR */
           nl++;
           goto scan;
          }
        }
       else
        {
         /* Blast - found CR as last char in buffer */
         if (b->ptr < nl)
          {
           /* They may not care, defer work as long as possible */
           return (nl - b->ptr);
          }
         else
          {
           int code;
           dTHX;
           b->ptr++;               /* say we have read it as far as flush() is concerned */
           b->buf++;               /* Leave space an front of buffer */
           b->bufsiz--;            /* Buffer is thus smaller */
           code = PerlIO_fill(f);  /* Fetch some more */
           b->bufsiz++;            /* Restore size for next time */
           b->buf--;               /* Point at space */
           b->ptr = nl = b->buf;   /* Which is what we hand off */
           b->posn--;              /* Buffer starts here */
           *nl = 0xd;              /* Fill in the CR */
           if (code == 0)
            goto test;             /* fill() call worked */
           /* CR at EOF - just fall through */
          }
        }
      }
    }
   return (((c->nl) ? (c->nl+1) : b->end) - b->ptr);
  }
 return 0;
}

void
PerlIOCrlf_set_ptrcnt(PerlIO *f, STDCHAR *ptr, SSize_t cnt)
{
 PerlIOBuf *b  = PerlIOSelf(f,PerlIOBuf);
 PerlIOCrlf *c = PerlIOSelf(f,PerlIOCrlf);
 IV flags = PerlIOBase(f)->flags;
 if (!b->buf)
  PerlIO_get_base(f);
 if (!ptr)
  {
   if (c->nl)
    ptr = c->nl+1;
   else
    {
     ptr = b->end;
     if ((flags & PERLIO_F_CRLF) && ptr > b->buf && ptr[-1] == 0xd)
      ptr--;
    }
   ptr -= cnt;
  }
 else
  {
   /* Test code - delete when it works ... */
   STDCHAR *chk;
   if (c->nl)
    chk = c->nl+1;
   else
    {
     chk = b->end;
     if ((flags & PERLIO_F_CRLF) && chk > b->buf && chk[-1] == 0xd)
      chk--;
    }
   chk -= cnt;

   if (ptr != chk)
    {
     dTHX;
     Perl_croak(aTHX_ "ptr wrong %p != %p fl=%08"UVxf" nl=%p e=%p for %d",
                ptr, chk, flags, c->nl, b->end, cnt);
    }
  }
 if (c->nl)
  {
   if (ptr > c->nl)
    {
     /* They have taken what we lied about */
     *(c->nl) = 0xd;
     c->nl = NULL;
     ptr++;
    }
  }
 b->ptr = ptr;
 PerlIOBase(f)->flags |= PERLIO_F_RDBUF;
}

SSize_t
PerlIOCrlf_write(PerlIO *f, const void *vbuf, Size_t count)
{
 if (!(PerlIOBase(f)->flags & PERLIO_F_CRLF))
  return PerlIOBuf_write(f,vbuf,count);
 else
  {
   PerlIOBuf *b = PerlIOSelf(f,PerlIOBuf);
   const STDCHAR *buf  = (const STDCHAR *) vbuf;
   const STDCHAR *ebuf = buf+count;
   if (!b->buf)
    PerlIO_get_base(f);
   if (!(PerlIOBase(f)->flags & PERLIO_F_CANWRITE))
    return 0;
   while (buf < ebuf)
    {
     STDCHAR *eptr = b->buf+b->bufsiz;
     PerlIOBase(f)->flags |= PERLIO_F_WRBUF;
     while (buf < ebuf && b->ptr < eptr)
      {
       if (*buf == '\n')
        {
         if ((b->ptr + 2) > eptr)
          {
           /* Not room for both */
           PerlIO_flush(f);
           break;
          }
         else
          {
           *(b->ptr)++ = 0xd; /* CR */
           *(b->ptr)++ = 0xa; /* LF */
           buf++;
           if (PerlIOBase(f)->flags & PERLIO_F_LINEBUF)
            {
             PerlIO_flush(f);
             break;
            }
          }
        }
       else
        {
         int ch = *buf++;
         *(b->ptr)++ = ch;
        }
       if (b->ptr >= eptr)
        {
         PerlIO_flush(f);
         break;
        }
      }
    }
   if (PerlIOBase(f)->flags & PERLIO_F_UNBUF)
    PerlIO_flush(f);
   return (buf - (STDCHAR *) vbuf);
  }
}

IV
PerlIOCrlf_flush(PerlIO *f)
{
 PerlIOCrlf *c = PerlIOSelf(f,PerlIOCrlf);
 if (c->nl)
  {
   *(c->nl) = 0xd;
   c->nl = NULL;
  }
 return PerlIOBuf_flush(f);
}

PerlIO_funcs PerlIO_crlf = {
 "crlf",
 sizeof(PerlIOCrlf),
 PERLIO_K_BUFFERED|PERLIO_K_CANCRLF,
 PerlIOBase_fileno,
 PerlIOBuf_fdopen,
 PerlIOBuf_open,
 PerlIOBuf_reopen,
 PerlIOCrlf_pushed,
 PerlIOBase_noop_ok,   /* popped */
 PerlIOBuf_read,       /* generic read works with ptr/cnt lies ... */
 PerlIOCrlf_unread,    /* Put CR,LF in buffer for each '\n' */
 PerlIOCrlf_write,     /* Put CR,LF in buffer for each '\n' */
 PerlIOBuf_seek,
 PerlIOBuf_tell,
 PerlIOBuf_close,
 PerlIOCrlf_flush,
 PerlIOBuf_fill,
 PerlIOBase_eof,
 PerlIOBase_error,
 PerlIOBase_clearerr,
 PerlIOBuf_setlinebuf,
 PerlIOBuf_get_base,
 PerlIOBuf_bufsiz,
 PerlIOBuf_get_ptr,
 PerlIOCrlf_get_cnt,
 PerlIOCrlf_set_ptrcnt,
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
		       Perl_croak(aTHX_ "panic: sysconf: %s", msg);
		   }
		   else
		       Perl_croak(aTHX_ "panic: sysconf: pagesize unknown");
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
	    Perl_croak(aTHX_ "panic: bad pagesize %"IVdf, (IV)page_size);
       }
       if (b->posn < 0)
        {
         /* This is a hack - should never happen - open should have set it ! */
         b->posn = PerlIO_tell(PerlIONext(f));
        }
       posn = (b->posn / page_size) * page_size;
       len  = st.st_size - posn;
       m->mptr = mmap(NULL, len, PROT_READ, MAP_SHARED, fd, posn);
       if (m->mptr && m->mptr != (Mmap_t) -1)
        {
#if 0 && defined(HAS_MADVISE) && defined(MADV_SEQUENTIAL)
         madvise(m->mptr, len, MADV_SEQUENTIAL);
#endif
#if 0 && defined(HAS_MADVISE) && defined(MADV_WILLNEED)
         madvise(m->mptr, len, MADV_WILLNEED);
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
 PERLIO_K_BUFFERED,
 PerlIOBase_fileno,
 PerlIOBuf_fdopen,
 PerlIOBuf_open,
 PerlIOBuf_reopen,
 PerlIOBuf_pushed,
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
#ifndef WIN32
   atexit(&PerlIO_cleanup);
#endif
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
#ifdef NEED_VA_COPY
 va_list apc;
 Perl_va_copy(ap, apc);
 sv_vcatpvf(sv, fmt, &apc);
#else
 sv_vcatpvf(sv, fmt, &ap);
#endif
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
 /* I have no idea how portable mkstemp() is ... */
#if defined(WIN32) || !defined(HAVE_MKSTEMP)
 dTHX;
 PerlIO *f = NULL;
 FILE *stdio = PerlSIO_tmpfile();
 if (stdio)
  {
   PerlIOStdio *s = PerlIOSelf(PerlIO_push(f = PerlIO_allocate(aTHX),&PerlIO_stdio,"w+",Nullch,0),PerlIOStdio);
   s->stdio  = stdio;
  }
 return f;
#else
 dTHX;
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
   PerlLIO_unlink(SvPVX(sv));
   SvREFCNT_dec(sv);
  }
 return f;
#endif
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
PerlIO_setpos(PerlIO *f, SV *pos)
{
 dTHX;
 if (SvOK(pos))
  {
   STRLEN len;
   Off_t *posn = (Off_t *) SvPV(pos,len);
   if (f && len == sizeof(Off_t))
    return PerlIO_seek(f,*posn,SEEK_SET);
  }
 errno = EINVAL;
 return -1;
}
#else
#undef PerlIO_setpos
int
PerlIO_setpos(PerlIO *f, SV *pos)
{
 dTHX;
 if (SvOK(pos))
  {
   STRLEN len;
   Fpos_t *fpos = (Fpos_t *) SvPV(pos,len);
   if (f && len == sizeof(Fpos_t))
    {
#if defined(USE_64_BIT_STDIO) && defined(USE_FSETPOS64)
     return fsetpos64(f, fpos);
#else
     return fsetpos(f, fpos);
#endif
    }
  }
 errno = EINVAL;
 return -1;
}
#endif

#ifndef HAS_FGETPOS
#undef PerlIO_getpos
int
PerlIO_getpos(PerlIO *f, SV *pos)
{
 dTHX;
 Off_t posn = PerlIO_tell(f);
 sv_setpvn(pos,(char *)&posn,sizeof(posn));
 return (posn == (Off_t)-1) ? -1 : 0;
}
#else
#undef PerlIO_getpos
int
PerlIO_getpos(PerlIO *f, SV *pos)
{
 dTHX;
 Fpos_t fpos;
 int code;
#if defined(USE_64_BIT_STDIO) && defined(USE_FSETPOS64)
 code = fgetpos64(f, &fpos);
#else
 code = fgetpos(f, &fpos);
#endif
 sv_setpvn(pos,(char *)&fpos,sizeof(fpos));
 return code;
}
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
     (void)PerlIO_puts(Perl_error_log,
		       "panic: sprintf overflow - memory corrupted!\n");
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


