/* dl_vms.xs
 * 
 * Platform:  OpenVMS, VAX or AXP
 * Author:    Charles Bailey  bailey@genetics.upenn.edu
 * Revised:   4-Sep-1994
 *
 *                           Implementation Note
 *     This section is added as an aid to users and DynaLoader developers, in
 * order to clarify the process of dynamic linking under VMS.
 *     dl_vms.xs uses the supported VMS dynamic linking call, which allows
 * a running program to map an arbitrary file of executable code and call
 * routines within that file.  This is done via the VMS RTL routine
 * lib$find_image_symbol, whose calling sequence is as follows:
 *   status = lib$find_image_symbol(imgname,symname,symval,defspec);
 *   where
 *     status  = a standard VMS status value (unsigned long int)
 *     imgname = a fixed-length string descriptor, passed by
 *               reference, containing the NAME ONLY of the image
 *               file to be mapped.  An attempt will be made to
 *               translate this string as a logical name, so it may
 *               not contain any characters which are not allowed in
 *               logical names.  If no translation is found, imgname
 *               is used directly as the name of the image file.
 *     symname = a fixed-length string descriptor, passed by
 *               reference, containing the name of the routine
 *               to be located.
 *     symval  = an unsigned long int, passed by reference, into
 *               which is written the entry point address of the
 *               routine whose name is specified in symname.
 *     defspec = a fixed-length string descriptor, passed by
 *               reference, containing a default file specification
 *               whichis used to fill in any missing parts of the
 *               image file specification after the imgname argument
 *               is processed.
 * In order to accommodate the handling of the imgname argument, the routine
 * dl_expandspec() is provided for use by perl code (e.g. dl_findfile)
 * which wants to see what image file lib$find_image_symbol would use if
 * it were passed a given file specification.  The file specification passed
 * to dl_expandspec() and dl_load_file() can be partial or complete, and can
 * use VMS or Unix syntax; these routines perform the necessary conversions.
 *    In general, writers of perl extensions need only conform to the
 * procedures set out in the DynaLoader documentation, and let the details
 * be taken care of by the routines here and in DynaLoader.pm.  If anyone
 * comes across any incompatibilities, please let me know.  Thanks.
 *
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "dlutils.c"    /* dl_debug, LastError; SaveError not used  */
/* N.B.:
 * dl_debug and LastError are static vars; you'll need to deal
 * with them appropriately if you need context independence
 */

#include <descrip.h>
#include <fscndef.h>
#include <lib$routines.h>
#include <rms.h>
#include <ssdef.h>

typedef unsigned long int vmssts;

struct libref {
  struct dsc$descriptor_s name;
  struct dsc$descriptor_s defspec;
};

/* Static data for dl_expand_filespec() - This is static to save
 * initialization on each call; if you need context-independence,
 * just make these auto variables in dl_expandspec() and dl_load_file()
 */
static char dlesa[NAM$C_MAXRSS], dlrsa[NAM$C_MAXRSS];
static struct FAB dlfab;
static struct NAM dlnam;

/* $PutMsg action routine - records error message in LastError */
static vmssts
copy_errmsg(msg,unused)
    struct dsc$descriptor_s *   msg;
    vmssts  unused;
{
    if (*(msg->dsc$a_pointer) = '%') { /* first line */
      if (LastError)
        strncpy((LastError = saferealloc(LastError,msg->dsc$w_length)),
                 msg->dsc$a_pointer, msg->dsc$w_length);
      else
        strncpy((LastError = safemalloc(msg->dsc$w_length)),
                 msg->dsc$a_pointer, msg->dsc$w_length);
      return 0;
    }
    else { /* continuation line */
      int errlen = strlen(LastError);
      LastError = saferealloc(LastError, errlen + msg->dsc$w_length + 1);
      LastError[errlen] = '\n';  LastError[errlen+1] = '\0';
      strncat(LastError, msg->dsc$a_pointer, msg->dsc$w_length);
    }
}

/* Use $PutMsg to retrieve error message for failure status code */
static void
dl_set_error(sts,stv)
    vmssts  sts;
    vmssts  stv;
{
    vmssts vec[3],pmsts;

    vec[0] = stv ? 2 : 1;
    vec[1] = sts;  vec[2] = stv;
    if (!(pmsts = sys$putmsg(vec,copy_errmsg,0,0)) & 1)
      croak("Fatal $PUTMSG error: %d",pmsts);
}

static void
dl_private_init()
{
    dl_generic_private_init();
    /* Set up the static control blocks for dl_expand_filespec() */
    dlfab = cc$rms_fab;
    dlnam = cc$rms_nam;
    dlfab.fab$l_nam = &dlnam;
    dlnam.nam$l_esa = dlesa;
    dlnam.nam$b_ess = sizeof dlesa;
    dlnam.nam$l_rsa = dlrsa;
    dlnam.nam$b_rss = sizeof dlrsa;
}
MODULE = DynaLoader PACKAGE = DynaLoader

BOOT:
    (void)dl_private_init();

SV *
dl_expandspec(filespec)
    char *	filespec
    CODE:
    char vmsspec[NAM$C_MAXRSS], defspec[NAM$C_MAXRSS];
    size_t deflen;
    vmssts sts;

    tovmsspec(filespec,vmsspec);
    dlfab.fab$l_fna = vmsspec;
    dlfab.fab$b_fns = strlen(vmsspec);
    dlfab.fab$l_dna = 0;
    dlfab.fab$b_dns = 0;
    DLDEBUG(1,fprintf(stderr,"dl_expand_filespec(%s):\n",vmsspec));
    /* On the first pass, just parse the specification string */
    dlnam.nam$b_nop = NAM$M_SYNCHK;
    sts = sys$parse(&dlfab);
    DLDEBUG(2,fprintf(stderr,"\tSYNCHK sys$parse = %d\n",sts));
    if (!(sts & 1)) {
      dl_set_error(dlfab.fab$l_sts,dlfab.fab$l_stv);
      ST(0) = &sv_undef;
    }
    else {
      /* Now set up a default spec - everything but the name */
      deflen = dlnam.nam$l_type - dlesa;
      memcpy(defspec,dlesa,deflen);
      memcpy(defspec+deflen,dlnam.nam$l_type,
             dlnam.nam$b_type + dlnam.nam$b_ver);
      deflen += dlnam.nam$b_type + dlnam.nam$b_ver;
      memcpy(vmsspec,dlnam.nam$l_name,dlnam.nam$b_name);
      DLDEBUG(2,fprintf(stderr,"\tsplit filespec: name = %.*s, default = %.*s\n",
                        dlnam.nam$b_name,vmsspec,defspec,deflen));
      /* . . . and go back to expand it */
      dlnam.nam$b_nop = 0;
      dlfab.fab$l_dna = defspec;
      dlfab.fab$b_dns = deflen;
      dlfab.fab$b_fns = dlnam.nam$b_name;
      sts = sys$parse(&dlfab);
      DLDEBUG(2,fprintf(stderr,"\tname/default sys$parse = %d\n",sts));
      if (!(sts & 1)) {
        dl_set_error(dlfab.fab$l_sts,dlfab.fab$l_stv);
        ST(0) = &sv_undef;
      }
      else {
        /* Now find the actual file */
        sts = sys$search(&dlfab);
        DLDEBUG(2,fprintf(stderr,"\tsys$search = %d\n",sts));
        if (!(sts & 1) && sts != RMS$_FNF) {
          dl_set_error(dlfab.fab$l_sts,dlfab.fab$l_stv);
          ST(0) = &sv_undef;
        }
        else {
          ST(0) = sv_2mortal(newSVpv(dlnam.nam$l_rsa,dlnam.nam$b_rsl));
          DLDEBUG(1,fprintf(stderr,"\tresult = \\%.*s\\\n",
                            dlnam.nam$b_rsl,dlnam.nam$l_rsa));
        }
      }
    }

void *
dl_load_file(filespec)
    char *	filespec
    CODE:
    char vmsspec[NAM$C_MAXRSS];
    AV *reqAV;
    SV *reqSV, **reqSVhndl;
    STRLEN deflen;
    struct dsc$descriptor_s
      specdsc = {0, DSC$K_DTYPE_T, DSC$K_CLASS_S, 0},
      symdsc  = {0, DSC$K_DTYPE_T, DSC$K_CLASS_S, 0};
    struct fscnlst {
      unsigned short int len;
      unsigned short int code;
      char *string;
    }  namlst[2] = {0,FSCN$_NAME,0, 0,0,0};
    struct libref *dlptr;
    vmssts sts, failed = 0;
    void *entry;

    DLDEBUG(1,fprintf(stderr,"dl_load_file(%s):\n",filespec));
    specdsc.dsc$a_pointer = tovmsspec(filespec,vmsspec);
    specdsc.dsc$w_length = strlen(specdsc.dsc$a_pointer);
    DLDEBUG(2,fprintf(stderr,"\tVMS-ified filespec is %s\n",
                      specdsc.dsc$a_pointer));
    dlptr = safemalloc(sizeof(struct libref));
    dlptr->name.dsc$b_dtype = dlptr->defspec.dsc$b_dtype = DSC$K_DTYPE_T;
    dlptr->name.dsc$b_class = dlptr->defspec.dsc$b_class = DSC$K_CLASS_S;
    sts = sys$filescan(&specdsc,namlst,0);
    DLDEBUG(2,fprintf(stderr,"\tsys$filescan: returns %d, name is %.*s\n",
                      sts,namlst[0].len,namlst[0].string));
    if (!(sts & 1)) {
      failed = 1;
      dl_set_error(sts,0);
    }
    else {
      dlptr->name.dsc$w_length = namlst[0].len;
      dlptr->name.dsc$a_pointer = savepvn(namlst[0].string,namlst[0].len);
      dlptr->defspec.dsc$w_length = specdsc.dsc$w_length - namlst[0].len;
      dlptr->defspec.dsc$a_pointer = safemalloc(dlptr->defspec.dsc$w_length + 1);
      deflen = namlst[0].string - specdsc.dsc$a_pointer; 
      memcpy(dlptr->defspec.dsc$a_pointer,specdsc.dsc$a_pointer,deflen);
      memcpy(dlptr->defspec.dsc$a_pointer + deflen,
             namlst[0].string + namlst[0].len,
             dlptr->defspec.dsc$w_length - deflen);
      DLDEBUG(2,fprintf(stderr,"\tlibref = name: %s, defspec: %.*s\n",
                        dlptr->name.dsc$a_pointer,
                        dlptr->defspec.dsc$w_length,
                        dlptr->defspec.dsc$a_pointer));
      if (!(reqAV = GvAV(gv_fetchpv("DynaLoader::dl_require_symbols",
                                     FALSE,SVt_PVAV)))
          || !(reqSVhndl = av_fetch(reqAV,0,FALSE)) || !(reqSV = *reqSVhndl)) {
        DLDEBUG(2,fprintf(stderr,"\t@dl_require_symbols empty, returning untested libref\n"));
      }
      else {
        symdsc.dsc$w_length = SvCUR(reqSV);
        symdsc.dsc$a_pointer = SvPVX(reqSV);
        DLDEBUG(2,fprintf(stderr,"\t$dl_require_symbols[0] = %.*s\n",
                          symdsc.dsc$w_length, symdsc.dsc$a_pointer));
        sts = lib$find_image_symbol(&(dlptr->name),&symdsc,
                                    &entry,&(dlptr->defspec));
        DLDEBUG(2,fprintf(stderr,"\tlib$find_image_symbol returns %d\n",sts));
        if (!(sts&1)) {
          failed = 1;
          dl_set_error(sts,0);
        }
      }
    }

    if (failed) {
      Safefree(dlptr->name.dsc$a_pointer);
      Safefree(dlptr->defspec.dsc$a_pointer);
      Safefree(dlptr);
      ST(0) = &sv_undef;
    }
    else {
      ST(0) = sv_2mortal(newSViv(dlptr));
    }


void *
dl_find_symbol(librefptr,symname)
    void *	librefptr
    SV *	symname
    CODE:
    struct libref thislib = *((struct libref *)librefptr);
    struct dsc$descriptor_s
      symdsc = {SvCUR(symname),DSC$K_DTYPE_T,DSC$K_CLASS_S,SvPVX(symname)};
    void (*entry)();
    vmssts sts;

    DLDEBUG(1,fprintf(stderr,"dl_find_dymbol(%.*s,%.*s):\n",
                      thislib.name.dsc$w_length, thislib.name.dsc$a_pointer,
                      symdsc.dsc$w_length,symdsc.dsc$a_pointer));
    sts = lib$find_image_symbol(&(thislib.name),&symdsc,
                                &entry,&(thislib.defspec));
    DLDEBUG(2,fprintf(stderr,"\tlib$find_image_symbol returns %d\n",sts));
    DLDEBUG(2,fprintf(stderr,"\tentry point is %d\n",
                      (unsigned long int) entry));
    if (!(sts & 1)) {
      dl_set_error(sts,0);
      ST(0) = &sv_undef;
    }
    else ST(0) = sv_2mortal(newSViv(entry));


void
dl_undef_symbols()
    PPCODE:


# These functions should not need changing on any platform:

void
dl_install_xsub(perl_name, symref, filename="$Package")
    char *	perl_name
    void *	symref 
    char *	filename
    CODE:
    DLDEBUG(2,fprintf(stderr,"dl_install_xsub(name=%s, symref=%x)\n",
        perl_name, symref));
    ST(0)=sv_2mortal(newRV((SV*)newXS(perl_name, (void(*)())symref, filename)));


char *
dl_error()
    CODE:
    RETVAL = LastError ;
    OUTPUT:
      RETVAL

# end.
