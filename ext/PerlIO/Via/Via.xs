#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef PERLIO_LAYERS

#include "perliol.h"

typedef struct
{
 struct _PerlIO base;       /* Base "class" info */
 HV *		stash;
 SV *		obj;
 SV *		var;
 SSize_t	cnt;
 Off_t		posn;
 IO *		io;
 SV *		fh;
 CV *PUSHED;
 CV *POPPED;
 CV *OPEN;
 CV *FDOPEN;
 CV *SYSOPEN;
 CV *GETARG;
 CV *FILENO;
 CV *READ;
 CV *WRITE;
 CV *FILL;
 CV *CLOSE;
 CV *SEEK;
 CV *TELL;
 CV *UNREAD;
 CV *FLUSH;
 CV *SETLINEBUF;
 CV *CLEARERR;
 CV *mERROR;
 CV *mEOF;
} PerlIOVia;

#define MYMethod(x) #x,&s->x

CV *
PerlIOVia_fetchmethod(pTHX_ PerlIOVia *s,char *method,CV **save)
{
 GV *gv = gv_fetchmeth(s->stash,method,strlen(method),0);
#if 0
 Perl_warn(aTHX_ "Lookup %s::%s => %p",HvNAME(s->stash),method,gv);
#endif
 if (gv)
  {
   return *save = GvCV(gv);
  }
 else
  {
   return *save = (CV *) -1;
  }

}

SV *
PerlIOVia_method(pTHX_ PerlIO *f,char *method,CV **save,int flags,...)
{
 PerlIOVia *s = PerlIOSelf(f,PerlIOVia);
 CV *cv = (*save) ? *save : PerlIOVia_fetchmethod(aTHX_ s,method,save);
 SV *result = Nullsv;
 va_list ap;
 va_start(ap,flags);
 if (cv != (CV *)-1)
  {
   IV count;
   dSP;
   SV *arg;
   ENTER;
   PUSHMARK(sp);
   XPUSHs(s->obj);
   while ((arg = va_arg(ap,SV *)))
    {
     XPUSHs(arg);
    }
   if (*PerlIONext(f))
    {
     if (!s->fh)
      {
       GV *gv = newGVgen(HvNAME(s->stash));
       GvIOp(gv) = newIO();
       s->fh  = newRV_noinc((SV *)gv);
       s->io  = GvIOp(gv);
      }
     IoIFP(s->io) = PerlIONext(f);
     IoOFP(s->io) = PerlIONext(f);
     XPUSHs(s->fh);
    }
   PUTBACK;
   count = call_sv((SV *)cv,flags);
   if (count)
    {
     SPAGAIN;
     result = POPs;
     PUTBACK;
    }
   else
    {
     result = &PL_sv_undef;
    }
   LEAVE;
  }
 va_end(ap);
 return result;
}

IV
PerlIOVia_pushed(PerlIO *f, const char *mode, SV *arg)
{
 IV code = PerlIOBase_pushed(f,mode,Nullsv);
 if (code == 0)
  {
   dTHX;
   PerlIOVia *s = PerlIOSelf(f,PerlIOVia);
   if (!arg)
    {
     Perl_warn(aTHX_ "No package specified");
     code = -1;
    }
   else
    {
     STRLEN pkglen = 0;
     char *pkg = SvPV(arg,pkglen);
     s->obj = SvREFCNT_inc(arg);
     s->stash  = gv_stashpvn(pkg, pkglen, FALSE);
     if (s->stash)
      {
       SV *modesv = (mode) ? sv_2mortal(newSVpvn(mode,strlen(mode))) : Nullsv;
       SV *result = PerlIOVia_method(aTHX_ f,MYMethod(PUSHED),G_SCALAR,modesv,Nullsv);
       if (result)
        {
         if (sv_isobject(result))
          {
           s->obj = SvREFCNT_inc(result);
           SvREFCNT_dec(arg);
          }
         else if (SvIV(result) != 0)
          return SvIV(result);
        }
       if (PerlIOVia_fetchmethod(aTHX_ s,MYMethod(FILL)) == (CV *) -1)
        PerlIOBase(f)->flags &= ~PERLIO_F_FASTGETS;
       else
        PerlIOBase(f)->flags |= PERLIO_F_FASTGETS;
      }
     else
      {
       Perl_warn(aTHX_ "Cannot find package '%.*s'",(int) pkglen,pkg);
#ifdef ENOSYS
       errno = ENOSYS;
#else
#ifdef ENOENT
       errno = ENOENT;
#endif
#endif
       code = -1;
      }
    }
  }
 return code;
}

PerlIO *
PerlIOVia_open(pTHX_ PerlIO_funcs *self, AV *layers, IV n, const char *mode, int fd, int imode, int perm, PerlIO *f, int narg, SV **args)
{
 if (!f)
  {
   f = PerlIO_push(aTHX_ PerlIO_allocate(aTHX),self,mode,PerlIOArg);
  }
 else
  {
   if (!PerlIO_push(aTHX_ f,self,mode,PerlIOArg))
    return NULL;
  }
 if (f)
  {
   PerlIOVia *s = PerlIOSelf(f,PerlIOVia);
   SV *result = Nullsv;
   if (fd >= 0)
    {
     SV *fdsv = sv_2mortal(newSViv(fd));
     result = PerlIOVia_method(aTHX_ f,MYMethod(FDOPEN),G_SCALAR,fdsv,Nullsv);
    }
   else if (narg > 0)
    {
     if (*mode == '#')
      {
       SV *imodesv = sv_2mortal(newSViv(imode));
       SV *permsv  = sv_2mortal(newSViv(perm));
       result = PerlIOVia_method(aTHX_ f,MYMethod(SYSOPEN),G_SCALAR,*args,imodesv,permsv,Nullsv);
      }
     else
      {
       result = PerlIOVia_method(aTHX_ f,MYMethod(OPEN),G_SCALAR,*args,Nullsv);
      }
    }
   if (result)
    {
     if (sv_isobject(result))
      s->obj = SvREFCNT_inc(result);
     else if (!SvTRUE(result))
      {
       return NULL;
      }
    }
   else
    return NULL;
  }
 return f;
}

IV
PerlIOVia_popped(PerlIO *f)
{
 dTHX;
 PerlIOVia *s = PerlIOSelf(f,PerlIOVia);
 PerlIOVia_method(aTHX_ f,MYMethod(POPPED),G_VOID,Nullsv);
 if (s->var)
  {
   SvREFCNT_dec(s->var);
   s->var = Nullsv;
  }

 if (s->io)
  {
   IoIFP(s->io) = NULL;
   IoOFP(s->io) = NULL;
  }
 if (s->fh)
  {
   SvREFCNT_dec(s->fh);
   s->fh  = Nullsv;
   s->io  = NULL;
  }
 if (s->obj)
  {
   SvREFCNT_dec(s->obj);
   s->obj = Nullsv;
  }
 return 0;
}

IV
PerlIOVia_close(PerlIO *f)
{
 dTHX;
 PerlIOVia *s = PerlIOSelf(f,PerlIOVia);
 IV code = PerlIOBase_close(f);
 SV *result = PerlIOVia_method(aTHX_ f,MYMethod(CLOSE),G_SCALAR,Nullsv);
 if (result && SvIV(result) != 0)
  code = SvIV(result);
 PerlIOBase(f)->flags &= ~(PERLIO_F_RDBUF|PERLIO_F_WRBUF);
 return code;
}

IV
PerlIOVia_fileno(PerlIO *f)
{
 dTHX;
 PerlIOVia *s = PerlIOSelf(f,PerlIOVia);
 SV *result = PerlIOVia_method(aTHX_ f,MYMethod(FILENO),G_SCALAR,Nullsv);
 return (result) ? SvIV(result) : PerlIO_fileno(PerlIONext(f));
}

IV
PerlIOVia_seek(PerlIO *f, Off_t offset, int whence)
{
 dTHX;
 PerlIOVia *s = PerlIOSelf(f,PerlIOVia);
 SV *offsv  = sv_2mortal(newSViv(offset));
 SV *whsv   = sv_2mortal(newSViv(offset));
 SV *result = PerlIOVia_method(aTHX_ f,MYMethod(SEEK),G_SCALAR,offsv,whsv,Nullsv);
 return (result) ? SvIV(result) : -1;
}

Off_t
PerlIOVia_tell(PerlIO *f)
{
 dTHX;
 PerlIOVia *s = PerlIOSelf(f,PerlIOVia);
 SV *result = PerlIOVia_method(aTHX_ f,MYMethod(TELL),G_SCALAR,Nullsv);
 return (result) ? (Off_t) SvIV(result) : s->posn;
}

SSize_t
PerlIOVia_unread(PerlIO *f, const void *vbuf, Size_t count)
{
 dTHX;
 PerlIOVia *s = PerlIOSelf(f,PerlIOVia);
 SV *buf    = sv_2mortal(newSVpvn((char *)vbuf,count));
 SV *result = PerlIOVia_method(aTHX_ f,MYMethod(UNREAD),G_SCALAR,buf,Nullsv);
 if (result)
  return (SSize_t) SvIV(result);
 else
  {
   return PerlIOBase_unread(f,vbuf,count);
  }
}

SSize_t
PerlIOVia_read(PerlIO *f, void *vbuf, Size_t count)
{
 SSize_t rd = 0;
 if (PerlIOBase(f)->flags & PERLIO_F_CANREAD)
  {
   if (PerlIOBase(f)->flags & PERLIO_F_FASTGETS)
    {
     rd = PerlIOBase_read(f,vbuf,count);
    }
   else
    {
     dTHX;
     PerlIOVia *s = PerlIOSelf(f,PerlIOVia);
     SV *buf    = sv_2mortal(newSV(count));
     SV *n      = sv_2mortal(newSViv(count));
     SV *result = PerlIOVia_method(aTHX_ f,MYMethod(READ),G_SCALAR,buf,n,Nullsv);
     if (result)
      {
       rd = (SSize_t) SvIV(result);
       Move(SvPVX(buf),vbuf,rd,char);
       return rd;
      }
    }
  }
 return rd;
}

SSize_t
PerlIOVia_write(PerlIO *f, const void *vbuf, Size_t count)
{
 if (PerlIOBase(f)->flags & PERLIO_F_CANWRITE)
  {
   dTHX;
   PerlIOVia *s = PerlIOSelf(f,PerlIOVia);
   SV *buf    = newSVpvn((char *)vbuf,count);
   SV *result = PerlIOVia_method(aTHX_ f,MYMethod(WRITE),G_SCALAR,buf,Nullsv);
   SvREFCNT_dec(buf);
   if (result)
    return (SSize_t) SvIV(result);
   return -1;
  }
 return 0;
}

IV
PerlIOVia_fill(PerlIO *f)
{
 if (PerlIOBase(f)->flags & PERLIO_F_CANREAD)
  {
   dTHX;
   PerlIOVia *s = PerlIOSelf(f,PerlIOVia);
   SV *result = PerlIOVia_method(aTHX_ f,MYMethod(FILL),G_SCALAR,Nullsv);
   if (s->var)
    {
     SvREFCNT_dec(s->var);
     s->var = Nullsv;
    }
   if (result && SvOK(result))
    {
     STRLEN len = 0;
     char *p = SvPV(result,len);
     s->var = newSVpvn(p,len);
     s->cnt = SvCUR(s->var);
     return 0;
    }
   else
    PerlIOBase(f)->flags |= PERLIO_F_EOF;
  }
 return -1;
}

IV
PerlIOVia_flush(PerlIO *f)
{
 dTHX;
 PerlIOVia *s = PerlIOSelf(f,PerlIOVia);
 SV *result = PerlIOVia_method(aTHX_ f,MYMethod(FLUSH),G_SCALAR,Nullsv);
 if (s->var && s->cnt > 0)
  {
   SvREFCNT_dec(s->var);
   s->var = Nullsv;
  }
 return (result) ? SvIV(result) : 0;
}

STDCHAR *
PerlIOVia_get_base(PerlIO *f)
{
 if (PerlIOBase(f)->flags & PERLIO_F_CANREAD)
  {
   dTHX;
   PerlIOVia *s = PerlIOSelf(f,PerlIOVia);
   if (s->var)
    {
     return (STDCHAR *)SvPVX(s->var);
    }
  }
 return (STDCHAR *) Nullch;
}

STDCHAR *
PerlIOVia_get_ptr(PerlIO *f)
{
 if (PerlIOBase(f)->flags & PERLIO_F_CANREAD)
  {
   PerlIOVia *s = PerlIOSelf(f,PerlIOVia);
   if (s->var)
    {
     STDCHAR *p = (STDCHAR *)(SvEND(s->var) - s->cnt);
     return p;
    }
  }
 return (STDCHAR *) Nullch;
}

SSize_t
PerlIOVia_get_cnt(PerlIO *f)
{
 if (PerlIOBase(f)->flags & PERLIO_F_CANREAD)
  {
   PerlIOVia *s = PerlIOSelf(f,PerlIOVia);
   if (s->var)
    {
     return s->cnt;
    }
  }
 return 0;
}

Size_t
PerlIOVia_bufsiz(PerlIO *f)
{
 if (PerlIOBase(f)->flags & PERLIO_F_CANREAD)
  {
   PerlIOVia *s = PerlIOSelf(f,PerlIOVia);
   if (s->var)
    return SvCUR(s->var);
  }
 return 0;
}

void
PerlIOVia_set_ptrcnt(PerlIO *f, STDCHAR *ptr, SSize_t cnt)
{
 PerlIOVia *s = PerlIOSelf(f,PerlIOVia);
 s->cnt = cnt;
}

void
PerlIOVia_setlinebuf(PerlIO *f)
{
 dTHX;
 PerlIOVia *s = PerlIOSelf(f,PerlIOVia);
 PerlIOVia_method(aTHX_ f,MYMethod(SETLINEBUF),G_VOID,Nullsv);
 PerlIOBase_setlinebuf(f);
}

void
PerlIOVia_clearerr(PerlIO *f)
{
 dTHX;
 PerlIOVia *s = PerlIOSelf(f,PerlIOVia);
 PerlIOVia_method(aTHX_ f,MYMethod(CLEARERR),G_VOID,Nullsv);
 PerlIOBase_clearerr(f);
}

SV *
PerlIOVia_getarg(PerlIO *f)
{
 dTHX;
 PerlIOVia *s = PerlIOSelf(f,PerlIOVia);
 return PerlIOVia_method(aTHX_ f,MYMethod(GETARG),G_SCALAR,Nullsv);
}

IV
PerlIOVia_error(PerlIO *f)
{
 dTHX;
 PerlIOVia *s = PerlIOSelf(f,PerlIOVia);
 SV *result = PerlIOVia_method(aTHX_ f,"ERROR",&s->mERROR,G_SCALAR,Nullsv);
 return (result) ? SvIV(result) : PerlIOBase_error(f);
}

IV
PerlIOVia_eof(PerlIO *f)
{
 dTHX;
 PerlIOVia *s = PerlIOSelf(f,PerlIOVia);
 SV *result = PerlIOVia_method(aTHX_ f,"EOF",&s->mEOF,G_SCALAR,Nullsv);
 return (result) ? SvIV(result) : PerlIOBase_eof(f);
}

PerlIO_funcs PerlIO_object = {
 "Via",
 sizeof(PerlIOVia),
 PERLIO_K_BUFFERED|PERLIO_K_DESTRUCT,
 PerlIOVia_pushed,
 PerlIOVia_popped,
 NULL, /* PerlIOVia_open, */
 PerlIOVia_getarg,
 PerlIOVia_fileno,
 PerlIOVia_read,
 PerlIOVia_unread,
 PerlIOVia_write,
 PerlIOVia_seek,
 PerlIOVia_tell,
 PerlIOVia_close,
 PerlIOVia_flush,
 PerlIOVia_fill,
 PerlIOVia_eof,
 PerlIOVia_error,
 PerlIOVia_clearerr,
 PerlIOVia_setlinebuf,
 PerlIOVia_get_base,
 PerlIOVia_bufsiz,
 PerlIOVia_get_ptr,
 PerlIOVia_get_cnt,
 PerlIOVia_set_ptrcnt,
};


#endif /* Layers available */

MODULE = PerlIO::Via	PACKAGE = PerlIO::Via
PROTOTYPES: ENABLE;

BOOT:
{
#ifdef PERLIO_LAYERS
 PerlIO_define_layer(aTHX_ &PerlIO_object);
#endif
}

