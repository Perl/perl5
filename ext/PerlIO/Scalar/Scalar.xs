#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef PERLIO_LAYERS

#include "perliol.h"

typedef struct
{
 struct _PerlIO base;       /* Base "class" info */
 SV *		var;
 Off_t		posn;
} PerlIOScalar;

IV
PerlIOScalar_pushed(PerlIO *f, const char *mode, SV *arg)
{
 dTHX;
 PerlIOScalar *s = PerlIOSelf(f,PerlIOScalar);
 /* If called (normally) via open() then arg is ref to scalar we are
    using, otherwise arg (from binmode presumably) is either NULL
    or the _name_ of the scalar
  */
 if  (arg)
  {
   if (SvROK(arg))
    {
     s->var = SvREFCNT_inc(SvRV(arg));
    }
   else
    {
     s->var = SvREFCNT_inc(perl_get_sv(SvPV_nolen(arg),GV_ADD|GV_ADDMULTI));
    }
  }
 else
  {
   s->var = newSVpvn("",0);
  }
 sv_upgrade(s->var,SVt_PV);
 s->posn = 0;
 return PerlIOBase_pushed(f,mode,Nullsv);
}

IV
PerlIOScalar_popped(PerlIO *f)
{
 PerlIOScalar *s = PerlIOSelf(f,PerlIOScalar);
 if (s->var)
  {
   dTHX;
   SvREFCNT_dec(s->var);
   s->var = Nullsv;
  }
 return 0;
}

IV
PerlIOScalar_close(PerlIO *f)
{
 dTHX;
 IV code = PerlIOBase_close(f);
 PerlIOScalar *s = PerlIOSelf(f,PerlIOScalar);
 PerlIOBase(f)->flags &= ~(PERLIO_F_RDBUF|PERLIO_F_WRBUF);
 return code;
}

IV
PerlIOScalar_fileno(PerlIO *f)
{
 return -1;
}

IV
PerlIOScalar_seek(PerlIO *f, Off_t offset, int whence)
{
 PerlIOScalar *s = PerlIOSelf(f,PerlIOScalar);
 switch(whence)
  {
   case 0:
    s->posn = offset;
    break;
   case 1:
    s->posn = offset + s->posn;
    break;
   case 2:
    s->posn = offset + SvCUR(s->var);
    break;
  }
 if (s->posn > SvCUR(s->var))
  {
   dTHX;
   (void) SvGROW(s->var,s->posn);
  }
 return 0;
}

Off_t
PerlIOScalar_tell(PerlIO *f)
{
 PerlIOScalar *s = PerlIOSelf(f,PerlIOScalar);
 return s->posn;
}

SSize_t
PerlIOScalar_unread(PerlIO *f, const void *vbuf, Size_t count)
{
 dTHX;
 PerlIOScalar *s = PerlIOSelf(f,PerlIOScalar);
 char *dst = SvGROW(s->var,s->posn+count);
 Move(vbuf,dst,count,char);
 s->posn += count;
 SvCUR_set(s->var,s->posn);
 SvPOK_on(s->var);
 return count;
}

SSize_t
PerlIOScalar_write(PerlIO *f, const void *vbuf, Size_t count)
{
 if (PerlIOBase(f)->flags & PERLIO_F_CANWRITE)
  {
   return PerlIOScalar_unread(f,vbuf,count);
  }
 return 0;
}

IV
PerlIOScalar_fill(PerlIO *f)
{
 return -1;
}

IV
PerlIOScalar_flush(PerlIO *f)
{
 return 0;
}

STDCHAR *
PerlIOScalar_get_base(PerlIO *f)
{
 PerlIOScalar *s = PerlIOSelf(f,PerlIOScalar);
 if (PerlIOBase(f)->flags & PERLIO_F_CANREAD)
  {
   dTHX;
   return (STDCHAR *)SvPV_nolen(s->var);
  }
 return (STDCHAR *) Nullch;
}

STDCHAR *
PerlIOScalar_get_ptr(PerlIO *f)
{
 if (PerlIOBase(f)->flags & PERLIO_F_CANREAD)
  {
   PerlIOScalar *s = PerlIOSelf(f,PerlIOScalar);
   return PerlIOScalar_get_base(f)+s->posn;
  }
 return (STDCHAR *) Nullch;
}

SSize_t
PerlIOScalar_get_cnt(PerlIO *f)
{
 if (PerlIOBase(f)->flags & PERLIO_F_CANREAD)
  {
   PerlIOScalar *s = PerlIOSelf(f,PerlIOScalar);
   return SvCUR(s->var) - s->posn;
  }
 return 0;
}

Size_t
PerlIOScalar_bufsiz(PerlIO *f)
{
 if (PerlIOBase(f)->flags & PERLIO_F_CANREAD)
  {
   PerlIOScalar *s = PerlIOSelf(f,PerlIOScalar);
   return SvCUR(s->var);
  }
 return 0;
}

void
PerlIOScalar_set_ptrcnt(PerlIO *f, STDCHAR *ptr, SSize_t cnt)
{
 PerlIOScalar *s = PerlIOSelf(f,PerlIOScalar);
 s->posn = SvCUR(s->var)-cnt;
}

PerlIO *
PerlIOScalar_open(pTHX_ PerlIO_funcs *self, AV *layers, IV n, const char *mode, int fd, int imode, int perm, PerlIO *f, int narg, SV **args)
{
 PerlIOScalar *s;
 SV *arg = (narg > 0) ? *args : PerlIOArg;
 if (SvROK(arg) || SvPOK(arg))
  {
   f = PerlIO_allocate(aTHX);
   s = PerlIOSelf(PerlIO_push(aTHX_ f,self,mode,arg),PerlIOScalar);
   PerlIOBase(f)->flags |= PERLIO_F_OPEN;
   return f;
  }
 return NULL;
}


PerlIO_funcs PerlIO_scalar = {
 "Scalar",
 sizeof(PerlIOScalar),
 PERLIO_K_BUFFERED,
 PerlIOScalar_pushed,
 PerlIOScalar_popped,
 PerlIOScalar_open,
 NULL,
 PerlIOScalar_fileno,
 PerlIOBase_read,
 PerlIOScalar_unread,
 PerlIOScalar_write,
 PerlIOScalar_seek,
 PerlIOScalar_tell,
 PerlIOScalar_close,
 PerlIOScalar_flush,
 PerlIOScalar_fill,
 PerlIOBase_eof,
 PerlIOBase_error,
 PerlIOBase_clearerr,
 PerlIOBase_setlinebuf,
 PerlIOScalar_get_base,
 PerlIOScalar_bufsiz,
 PerlIOScalar_get_ptr,
 PerlIOScalar_get_cnt,
 PerlIOScalar_set_ptrcnt,
};


#endif /* Layers available */

MODULE = PerlIO::Scalar	PACKAGE = PerlIO::Scalar

BOOT:
{
#ifdef PERLIO_LAYERS
 PerlIO_define_layer(aTHX_ &PerlIO_scalar);
#endif
}

