/* VMS-specific routines for perl5
 *
 * Last revised: 09-Oct-1994
 */

#include <acedef.h>
#include <acldef.h>
#include <armdef.h>
#include <chpdef.h>
#include <descrip.h>
#include <dvidef.h>
#include <float.h>
#include <fscndef.h>
#include <iodef.h>
#include <jpidef.h>
#include <libdef.h>
#include <lib$routines.h>
#include <lnmdef.h>
#include <psldef.h>
#include <rms.h>
#include <shrdef.h>
#include <ssdef.h>
#include <starlet.h>
#include <stsdef.h>
#include <syidef.h>


#include "EXTERN.h"
#include "perl.h"

struct itmlst_3 {
  unsigned short int buflen;
  unsigned short int itmcode;
  void *bufadr;
  unsigned long int retlen;
};

static unsigned long int sts;

#define _cksts(call) \
  if (!(sts=(call))&1) { \
    errno = EVMSERR; vaxc$errno = sts; \
    croak("fatal error at %s, line %d",__FILE__,__LINE__); \
  } else { 1; }

/* my_getenv
 * Translate a logical name.  Substitute for CRTL getenv() to avoid
 * memory leak, and to keep my_getenv() and my_setenv() in the same
 * domain (mostly - my_getenv() need not return a translation from
 * the process logical name table)
 *
 * Note: Uses static buffer -- not thread-safe!
 */
/*{{{ char *my_getenv(char *lnm)*/
char *
my_getenv(char *lnm)
{
    static char __my_getenv_eqv[LNM$C_NAMLENGTH+1];
    char uplnm[LNM$C_NAMLENGTH], *cp1, *cp2;
    unsigned short int eqvlen;
    unsigned long int retsts, attr = LNM$M_CASE_BLIND;
    $DESCRIPTOR(sysdiskdsc,"SYS$DISK");
    $DESCRIPTOR(tabdsc,"LNM$FILE_DEV");
    struct dsc$descriptor_s lnmdsc = {0,DSC$K_DTYPE_T,DSC$K_CLASS_S,uplnm},
                            eqvdsc = {sizeof __my_getenv_eqv,DSC$K_DTYPE_T,
                                      DSC$K_CLASS_S, __my_getenv_eqv};
    struct itmlst_3 lnmlst[2] = {sizeof __my_getenv_eqv - 1, LNM$_STRING,
                                 __my_getenv_eqv, &eqvlen, 0, 0, 0, 0};

    for (cp1 = lnm, cp2= uplnm; *cp1; cp1++, cp2++) *cp2 = _toupper(*cp1);
    *cp2 = '\0';
    lnmdsc.dsc$w_length = cp1 - lnm;
    if (lnmdsc.dsc$w_length = 7 && !strncmp(uplnm,"DEFAULT",7)) {
      _cksts(sys$trnlnm(&attr,&tabdsc,&sysdiskdsc,0,lnmlst));
      eqvdsc.dsc$a_pointer += eqvlen;
      eqvdsc.dsc$w_length = sizeof __my_getenv_eqv - eqvlen - 1;
      _cksts(sys$setddir(0,&eqvlen,&eqvdsc));
      eqvdsc.dsc$a_pointer[eqvlen] = '\0';
      return __my_getenv_eqv;
    }
    else {
      retsts = sys$trnlnm(&attr,&tabdsc,&lnmdsc,0,lnmlst);
      if (retsts != SS$_NOLOGNAM) {
        if (retsts & 1) {
          __my_getenv_eqv[eqvlen] = '\0';
          return __my_getenv_eqv;
        }
        _cksts(retsts);
      }
      else {
        retsts = lib$get_symbol(&lnmdsc,&eqvdsc,&(eqvdsc.dsc$w_length),0);
        if (retsts != LIB$_NOSUCHSYM) {
          /* We want to return only logical names or CRTL Unix emulations */
          if (retsts & 1) return Nullch;
          _cksts(retsts);
        }
        else return getenv(lnm); /* Try for CRTL emulation of a Unix/POSIX name */
      }
    }
    return NULL;

}  /* end of my_getenv() */
/*}}}*/

/*{{{ void  my_setenv(char *lnm, char *eqv)*/
void
my_setenv(char *lnm,char *eqv)
/* Define a supervisor-mode logical name in the process table.
 * In the future we'll add tables, attribs, and acmodes,
 * probably through a different call.
 */
{
    char uplnm[LNM$C_NAMLENGTH], *cp1, *cp2;
    unsigned long int retsts, usermode = PSL$C_USER;
    $DESCRIPTOR(tabdsc,"LNM$PROCESS");
    struct dsc$descriptor_s lnmdsc = {0,DSC$K_DTYPE_T,DSC$K_CLASS_S,uplnm},
                            eqvdsc = {0,DSC$K_DTYPE_T,DSC$K_CLASS_S,0};

    for(cp1 = lnm, cp2 = uplnm; *cp1; cp1++, cp2++) *cp2 = _toupper(*cp1);
    lnmdsc.dsc$w_length = cp1 - lnm;

    if (!eqv || !*eqv) {  /* we're deleting a logical name */
      retsts = sys$dellnm(&tabdsc,&lnmdsc,&usermode); /* try user mode first */
      if (retsts != SS$_NOLOGNAM) _cksts(retsts);
      if (!(retsts & 1)) {
        retsts = lib$delete_logical(&lnmdsc,&tabdsc); /* then supervisor mode */
        if (retsts != SS$_NOLOGNAM) _cksts(retsts);
      }
    }
    else {
      eqvdsc.dsc$w_length = strlen(eqv);
      eqvdsc.dsc$a_pointer = eqv;

      _cksts(lib$set_logical(&lnmdsc,&eqvdsc,&tabdsc,0,0));
    }

}  /* end of my_setenv() */
/*}}}*/

static char *do_fileify_dirspec(char *, char *, int);
static char *do_tovmsspec(char *, char *, int);

/*{{{int do_rmdir(char *name)*/
int
do_rmdir(char *name)
{
    char dirfile[NAM$C_MAXRSS+1];
    int retval;
    stat_t st;

    if (do_fileify_dirspec(name,dirfile,0) == NULL) return -1;
    if (flex_stat(dirfile,&st) || !S_ISDIR(st.st_mode)) retval = -1;
    else retval = kill_file(dirfile);
    return retval;

}  /* end of do_rmdir */
/*}}}*/

/* kill_file
 * Delete any file to which user has control access, regardless of whether
 * delete access is explicitly allowed.
 * Limitations: User must have write access to parent directory.
 *              Does not block signals or ASTs; if interrupted in midstream
 *              may leave file with an altered ACL.
 * HANDLE WITH CARE!
 */
/*{{{int kill_file(char *name)*/
int
kill_file(char *name)
{
    char vmsname[NAM$C_MAXRSS+1];
    unsigned long int jpicode = JPI$_UIC, type = ACL$C_FILE;
    unsigned long int uics[2] = {0,0}, cxt = 0, aclsts, fndsts, rmsts = -1;
    struct dsc$descriptor_s fildsc = {0, DSC$K_DTYPE_T, DSC$K_CLASS_S, 0};
    struct myacedef {
      unsigned char ace$b_length;
      unsigned char ace$b_type;
      unsigned short int ace$w_flags;
      unsigned long int ace$l_access;
      unsigned long int ace$l_ident;
    } newace = { sizeof(struct myacedef), ACE$C_KEYID, 0,
                 ACE$M_READ | ACE$M_WRITE | ACE$M_DELETE | ACE$M_CONTROL, 0},
      oldace = { sizeof(struct myacedef), ACE$C_KEYID, 0, 0, 0};
     struct itmlst_3
       findlst[3] = {sizeof oldace, ACL$C_FNDACLENT, &oldace, 0,
                    sizeof oldace, ACL$C_READACE,   &oldace, 0, 0, 0, 0, 0},
       addlst[2] = {sizeof newace, ACL$C_ADDACLENT, &newace, 0, 0, 0, 0, 0},
       dellst[2] = {sizeof newace, ACL$C_DELACLENT, &newace, 0, 0, 0, 0, 0},
       lcklst[2] = {sizeof newace, ACL$C_WLOCK_ACL, &newace, 0, 0, 0, 0, 0},
       ulklst[2] = {sizeof newace, ACL$C_UNLOCK_ACL, &newace, 0, 0, 0, 0, 0};
      
    if (!remove(name)) return 0;  /* Can we just get rid of it? */

    /* No, so we get our own UIC to use as a rights identifier,
     * and the insert an ACE at the head of the ACL which allows us
     * to delete the file.
     */
    _cksts(lib$getjpi(&jpicode,0,0,&(oldace.ace$l_ident),0,0));
    if (do_tovmsspec(name,vmsname,0) == NULL) return -1;
    fildsc.dsc$w_length = strlen(vmsname);
    fildsc.dsc$a_pointer = vmsname;
    cxt = 0;
    newace.ace$l_ident = oldace.ace$l_ident;
    if (!((aclsts = sys$change_acl(0,&type,&fildsc,lcklst,0,0,0)) & 1)) {
      errno = EVMSERR;
      vaxc$errno = aclsts;
      return -1;
    }
    /* Grab any existing ACEs with this identifier in case we fail */
    aclsts = fndsts = sys$change_acl(0,&type,&fildsc,findlst,0,0,&cxt);
    if ( fndsts & 1 || fndsts == SS$_ACLEMPTY || fndsts == SS$_NOENTRY) {
      /* Add the new ACE . . . */
      if (!((aclsts = sys$change_acl(0,&type,&fildsc,addlst,0,0,0)) & 1))
        goto yourroom;
      if (rmsts = remove(name)) {
        /* We blew it - dir with files in it, no write priv for
         * parent directory, etc.  Put things back the way they were. */
        if (!((aclsts = sys$change_acl(0,&type,&fildsc,dellst,0,0,0)) & 1))
          goto yourroom;
        if (fndsts & 1) {
          addlst[0].bufadr = &oldace;
          if (!((aclsts = sys$change_acl(0,&type,&fildsc,addlst,0,0,&cxt)) & 1))
            goto yourroom;
        }
      }
    }

    yourroom:
    if (rmsts) {
      fndsts = sys$change_acl(0,&type,&fildsc,ulklst,0,0,0);
      if (aclsts & 1) aclsts = fndsts;
    }
    if (!(aclsts & 1)) {
      errno = EVMSERR;
      vaxc$errno = aclsts;
      return -1;
    }

    return rmsts;

}  /* end of kill_file() */
/*}}}*/

static void
create_mbx(unsigned short int *chan, struct dsc$descriptor_s *namdsc)
{
  static unsigned long int mbxbufsiz;
  long int syiitm = SYI$_MAXBUF, dviitm = DVI$_DEVNAM;
  
  if (!mbxbufsiz) {
    /*
     * Get the SYSGEN parameter MAXBUF, and the smaller of it and the
     * preprocessor consant BUFSIZ from stdio.h as the size of the
     * 'pipe' mailbox.
     */
    _cksts(lib$getsyi(&syiitm, &mbxbufsiz, 0, 0, 0, 0));
    if (mbxbufsiz > BUFSIZ) mbxbufsiz = BUFSIZ; 
  }
  _cksts(sys$crembx(0,chan,mbxbufsiz,mbxbufsiz,0,0,0));

  _cksts(lib$getdvi(&dviitm, chan, NULL, NULL, namdsc, &namdsc->dsc$w_length));
  namdsc->dsc$a_pointer[namdsc->dsc$w_length] = '\0';

}  /* end of create_mbx() */

/*{{{  my_popen and my_pclose*/
struct pipe_details
{
    struct pipe_details *next;
    FILE *fp;
    int pid;
    unsigned long int completion;
};

static struct pipe_details *open_pipes = NULL;
static $DESCRIPTOR(nl_desc, "NL:");
static int waitpid_asleep = 0;

static void
popen_completion_ast(unsigned long int unused)
{
  if (waitpid_asleep) {
    waitpid_asleep = 0;
    sys$wake(0,0);
  }
}

/*{{{  FILE *my_popen(char *cmd, char *mode)*/
FILE *
my_popen(char *cmd, char *mode)
{
    char mbxname[64];
    unsigned short int chan;
    unsigned long int flags=1;  /* nowait - gnu c doesn't allow &1 */
    struct pipe_details *info;
    struct dsc$descriptor_s namdsc = {sizeof mbxname, DSC$K_DTYPE_T,
                                      DSC$K_CLASS_S, mbxname},
                            cmddsc = {0, DSC$K_DTYPE_T,
                                      DSC$K_CLASS_S, 0};
                            

    New(7001,info,1,struct pipe_details);

    info->completion=0;  /* I assume this will remain 0 until terminates */
        
    /* create mailbox */
    create_mbx(&chan,&namdsc);

    /* open a FILE* onto it */
    info->fp=fopen(mbxname, mode);

    /* give up other channel onto it */
    _cksts(sys$dassgn(chan));

    if (!info->fp)
        return Nullfp;
        
    cmddsc.dsc$w_length=strlen(cmd);
    cmddsc.dsc$a_pointer=cmd;

    if (strcmp(mode,"r")==0) {
      _cksts(lib$spawn(&cmddsc, &nl_desc, &namdsc, &flags,
                     0  /* name */, &info->pid, &info->completion,
                     0, popen_completion_ast,0,0,0,0));
    }
    else {
      _cksts(lib$spawn(&cmddsc, &namdsc, 0 /* sys$output */,
                     0  /* name */, &info->pid, &info->completion));
    }

    info->next=open_pipes;  /* prepend to list */
    open_pipes=info;
        
    return info->fp;
}
/*}}}*/

/*{{{  I32 my_pclose(FILE *fp)*/
I32 my_pclose(FILE *fp)
{
    struct pipe_details *info, *last = NULL;
    unsigned long int abort = SS$_TIMEOUT, retsts;
    
    for (info = open_pipes; info != NULL; last = info, info = info->next)
        if (info->fp == fp) break;

    if (info == NULL)
      /* get here => no such pipe open */
      croak("my_pclose() - no such pipe open ???");

    if (!info->completion) { /* Tap them gently on the shoulder . . .*/
      _cksts(sys$forcex(&info->pid,0,&abort));
      sleep(1);
    }
    if (!info->completion)  /* We tried to be nice . . . */
      _cksts(sys$delprc(&info->pid));
    
    fclose(info->fp);
    /* remove from list of open pipes */
    if (last) last->next = info->next;
    else open_pipes = info->next;
    retsts = info->completion;
    Safefree(info);

    return retsts;
}  /* end of my_pclose() */

#ifndef HAS_WAITPID
/* sort-of waitpid; use only with popen() */
/*{{{unsigned long int waitpid(unsigned long int pid, int *statusp, int flags)*/
unsigned long int
waitpid(unsigned long int pid, int *statusp, int flags)
{
    struct pipe_details *info;
    unsigned long int abort = SS$_TIMEOUT;
    
    for (info = open_pipes; info != NULL; info = info->next)
        if (info->pid == pid) break;

    if (info != NULL) {  /* we know about this child */
      while (!info->completion) {
        waitpid_asleep = 1;
        sys$hiber();
      }

      *statusp = info->completion;
      return pid;
    }
    else {  /* we haven't heard of this child */
      $DESCRIPTOR(intdsc,"0 00:00:01");
      unsigned long int ownercode = JPI$_OWNER, ownerpid, mypid;
      unsigned long int interval[2];

      _cksts(lib$getjpi(&ownercode,&pid,0,&ownerpid,0,0));
      _cksts(lib$getjpi(&ownercode,0,0,&mypid,0,0));
      if (ownerpid != mypid)
        croak("pid %d not a child",pid);

      _cksts(sys$bintim(&intdsc,interval));
      while ((sts=lib$getjpi(&ownercode,&pid,0,&ownerpid,0,0)) & 1) {
        _cksts(sys$schdwk(0,0,interval,0));
        _cksts(sys$hiber());
      }
      _cksts(sts);

      /* There's no easy way to find the termination status a child we're
       * not aware of beforehand.  If we're really interested in the future,
       * we can go looking for a termination mailbox, or chase after the
       * accounting record for the process.
       */
      *statusp = 0;
      return pid;
    }
                    
}  /* end of waitpid() */
#endif   
/*}}}*/
/*}}}*/
/*}}}*/

/*{{{ char *my_gconvert(double val, int ndig, int trail, char *buf) */
char *
my_gconvert(double val, int ndig, int trail, char *buf)
{
  static char __gcvtbuf[DBL_DIG+1];
  char *loc;

  loc = buf ? buf : __gcvtbuf;
  if (val) {
    if (!buf && ndig > DBL_DIG) ndig = DBL_DIG;
    return gcvt(val,ndig,loc);
  }
  else {
    loc[0] = '0'; loc[1] = '\0';
    return loc;
  }

}
/*}}}*/

/*
** The following routines are provided to make life easier when
** converting among VMS-style and Unix-style directory specifications.
** All will take input specifications in either VMS or Unix syntax. On
** failure, all return NULL.  If successful, the routines listed below
** return a pointer to a static buffer containing the appropriately
** reformatted spec (and, therefore, subsequent calls to that routine
** will clobber the result), while the routines of the same names with
** a _ts suffix appended will return a pointer to a mallocd string
** containing the appropriately reformatted spec.
** In all cases, only explicit syntax is altered; no check is made that
** the resulting string is valid or that the directory in question
** actually exists.
**
**   fileify_dirspec() - convert a directory spec into the name of the
**     directory file (i.e. what you can stat() to see if it's a dir).
**     The style (VMS or Unix) of the result is the same as the style
**     of the parameter passed in.
**   pathify_dirspec() - convert a directory spec into a path (i.e.
**     what you prepend to a filename to indicate what directory it's in).
**     The style (VMS or Unix) of the result is the same as the style
**     of the parameter passed in.
**   tounixpath() - convert a directory spec into a Unix-style path.
**   tovmspath() - convert a directory spec into a VMS-style path.
**   tounixspec() - convert any file spec into a Unix-style file spec.
**   tovmsspec() - convert any file spec into a VMS-style spec.
 */

/*{{{ char *fileify_dirspec[_ts](char *path, char *buf)*/
static char *do_fileify_dirspec(char *dir,char *buf,int ts)
{
    static char __fileify_retbuf[NAM$C_MAXRSS+1];
    unsigned long int dirlen, retlen, addmfd = 0;
    char *retspec, *cp1, *cp2, *lastdir;

    if (dir == NULL) return NULL;

    dirlen = strlen(dir);
    if (!strpbrk(dir,"]:>")) { /* Unix-style path or plain dir name */
      if (dir[dirlen-1] == '/') {    /* path ends with '/'; just add .dir;1 */
        dirlen -= 1;                 /* to last element */
        lastdir = strrchr(dir,'/');
      }
      else {
        if (!(lastdir = cp1 = strrchr(dir,'/'))) cp1 = dir;
        if ((cp2 = strchr(cp1,'.'))) {  /* look for explicit type */
          if (toupper(*(cp2+1)) == 'D' &&    /* Yep.  Is it .dir? */
              toupper(*(cp2+2)) == 'I' &&
              toupper(*(cp2+3)) == 'R') {
            if ((cp1 = strchr(cp2,';')) || (cp1 = strchr(cp2+1,'.'))) {
              if (*(cp1+1) != '1' || *(cp1+2) != '\0') { /* Version is not ;1 */
                errno = ENOTDIR;                         /* Bzzt. */
                return NULL;
              }
            }
            dirlen = cp2 - dir;
          }
          else {  /* There's a type, and it's not .dir.  Bzzt. */
            errno = ENOTDIR;
            return NULL;
          }
        }
        /* If we lead off with a device or rooted logical, add the MFD
           if we're specifying a top-level directory. */
        if (lastdir && *dir == '/') {
          addmfd = 1;
          for (cp1 = lastdir - 1; cp1 > dir; cp1--) {
            if (*cp1 == '/') {
              addmfd = 0;
              break;
            }
          }
        }
        retlen = dirlen + addmfd ? 13 : 6;
        if (buf) retspec = buf;
        else if (ts) New(7009,retspec,retlen+6,char);
        else retspec = __fileify_retbuf;
        if (addmfd) {
          dirlen = lastdir - dir;
          memcpy(retspec,dir,dirlen);
          strcpy(&retspec[dirlen],"/000000");
          strcpy(&retspec[dirlen+7],lastdir);
        }
        else {
          memcpy(retspec,dir,dirlen);
          retspec[dirlen] = '\0';
        }
      }
      /* We've picked up everything up to the directory file name.
         Now just add the type and version, and we're set. */
      strcat(retspec,".dir;1");
      return retspec;
    }
    else {  /* VMS-style directory spec */
      char esa[NAM$C_MAXRSS+1], term;
      unsigned long int sts, cmplen;
      struct FAB dirfab = cc$rms_fab;
      struct NAM savnam, dirnam = cc$rms_nam;

      dirfab.fab$b_fns = strlen(dir);
      dirfab.fab$l_fna = dir;
      dirfab.fab$l_nam = &dirnam;
      dirnam.nam$b_ess = NAM$C_MAXRSS;
      dirnam.nam$l_esa = esa;
      dirnam.nam$b_nop = NAM$M_SYNCHK;
      if (!(sys$parse(&dirfab)&1)) {
        errno = EVMSERR;
        vaxc$errno = dirfab.fab$l_sts;
        return NULL;
      }
      savnam = dirnam;
      if (sys$search(&dirfab)&1) {  /* Does the file really exist? */
        /* Yes; fake the fnb bits so we'll check type below */
        dirnam.nam$l_fnb |= NAM$M_EXP_TYPE | NAM$M_EXP_VER;
      }
      else {
        if (dirfab.fab$l_sts != RMS$_FNF) {
          errno = EVMSERR;
          vaxc$errno = dirfab.fab$l_sts;
          return NULL;
        }
        dirnam = savnam; /* No; just work with potential name */
      }

      if (dirnam.nam$l_fnb & NAM$M_EXP_TYPE) {  /* Was type specified? */
        /* Yep; check version while we're at it, if it's there. */
        cmplen = (dirnam.nam$l_fnb & NAM$M_EXP_VER) ? 6 : 4;
        if (strncmp(dirnam.nam$l_type,".DIR;1",cmplen)) { 
          /* Something other than .DIR[;1].  Bzzt. */
          errno = ENOTDIR;
          return NULL;
        }
        else {  /* Ok, it was .DIR[;1]; copy over everything up to the */
          retlen = dirnam.nam$l_type - esa;           /* file name. */
          if (buf) retspec = buf;
          else if (ts) New(7010,retspec,retlen+6,char);
          else retspec = __fileify_retbuf;
          strncpy(retspec,esa,retlen);
          retspec[retlen] = '\0';
        }
      }
      else {
        /* They didn't explicitly specify the directory file.  Ignore
           any file names in the input, pull off the last element of the
           directory path, and make it the file name.  If you want to
           pay attention to filenames without .dir in the input, just use
           ".DIR;1" as a default filespec for the $PARSE */
        esa[dirnam.nam$b_esl] = '\0';
        if ((cp1 = strrchr(esa,']')) == NULL) cp1 = strrchr(esa,'>');
        if (cp1 == NULL) return NULL; /* should never happen */
        term = *cp1;
        *cp1 = '\0';
        retlen = strlen(esa);
        if ((cp1 = strrchr(esa,'.')) != NULL) {
          /* There's more than one directory in the path.  Just roll back. */
          *cp1 = term;
          if (buf) retspec = buf;
          else if (ts) New(7011,retspec,retlen+6,char);
          else retspec = __fileify_retbuf;
          strcpy(retspec,esa);
        }
        else { /* This is a top-level dir.  Add the MFD to the path. */
          if (buf) retspec = buf;
          else if (ts) New(7012,retspec,retlen+14,char);
          else retspec = __fileify_retbuf;
          cp1 = esa;
          cp2 = retspec;
          while (*cp1 != ':') *(cp2++) = *(cp1++);
          strcpy(cp2,":[000000]");
          cp1 += 2;
          strcpy(cp2+9,cp1);
        }
      } 
      /* Again, we've set up the string up through the filename.  Add the
         type and version, and we're done. */
      strcat(retspec,".DIR;1");
      return retspec;
    }
}  /* end of do_fileify_dirspec() */
/*}}}*/
/* External entry points */
char *fileify_dirspec(char *dir, char *buf)
{ return do_fileify_dirspec(dir,buf,0); }
char *fileify_dirspec_ts(char *dir, char *buf)
{ return do_fileify_dirspec(dir,buf,1); }

/*{{{ char *pathify_dirspec[_ts](char *path, char *buf)*/
static char *do_pathify_dirspec(char *dir,char *buf, int ts)
{
    static char __pathify_retbuf[NAM$C_MAXRSS+1];
    unsigned long int retlen;
    char *retpath, *cp1, *cp2;

    if (dir == NULL) return NULL;

    if (!strpbrk(dir,"]:>")) { /* Unix-style path or plain dir name */
      if (!(cp1 = strrchr(dir,'/'))) cp1 = dir;
      if (cp2 = strchr(cp1,'.')) {
        if (toupper(*(cp2+1)) == 'D' &&  /* They specified .dir. */
            toupper(*(cp2+2)) == 'I' &&  /* Trim it off. */
            toupper(*(cp2+3)) == 'R') {
          retlen = cp2 - dir + 1;
        }
        else {  /* Some other file type.  Bzzt. */
          errno = ENOTDIR;
          return NULL;
        }
      }
      else {  /* No file type present.  Treat the filename as a directory. */
        retlen = strlen(dir) + 1;
      }
      if (buf) retpath = buf;
      else if (ts) New(7013,retpath,retlen,char);
      else retpath = __pathify_retbuf;
      strncpy(retpath,dir,retlen-1);
      if (retpath[retlen-2] != '/') { /* If the path doesn't already end */
        retpath[retlen-1] = '/';      /* with '/', add it. */
        retpath[retlen] = '\0';
      }
      else retpath[retlen-1] = '\0';
    }
    else {  /* VMS-style directory spec */
      char esa[NAM$C_MAXRSS+1];
      unsigned long int sts, cmplen;
      struct FAB dirfab = cc$rms_fab;
      struct NAM savnam, dirnam = cc$rms_nam;

      dirfab.fab$b_fns = strlen(dir);
      dirfab.fab$l_fna = dir;
      dirfab.fab$l_nam = &dirnam;
      dirnam.nam$b_ess = sizeof esa;
      dirnam.nam$l_esa = esa;
      dirnam.nam$b_nop = NAM$M_SYNCHK;
      if (!(sys$parse(&dirfab)&1)) {
        errno = EVMSERR;
        vaxc$errno = dirfab.fab$l_sts;
        return NULL;
      }
      savnam = dirnam;
      if (sys$search(&dirfab)&1) {  /* Does the file really exist? */
        /* Yes; fake the fnb bits so we'll check type below */
        dirnam.nam$l_fnb |= NAM$M_EXP_TYPE | NAM$M_EXP_VER;
      }
      else {
        if (dirfab.fab$l_sts != RMS$_FNF) {
          errno = EVMSERR;
          vaxc$errno = dirfab.fab$l_sts;
          return NULL;
        }
        dirnam = savnam; /* No; just work with potential name */
      }

      if (dirnam.nam$l_fnb & NAM$M_EXP_TYPE) {  /* Was type specified? */
        /* Yep; check version while we're at it, if it's there. */
        cmplen = (dirnam.nam$l_fnb & NAM$M_EXP_VER) ? 6 : 4;
        if (strncmp(dirnam.nam$l_type,".DIR;1",cmplen)) { 
          /* Something other than .DIR[;1].  Bzzt. */
          errno = ENOTDIR;
          return NULL;
        }
        /* OK, the type was fine.  Now pull any file name into the
           directory path. */
        if (cp1 = strrchr(esa,']')) *dirnam.nam$l_type = ']';
        else {
          cp1 = strrchr(esa,'>');
          *dirnam.nam$l_type = '>';
        }
        *cp1 = '.';
        *(dirnam.nam$l_type + 1) = '\0';
        retlen = dirnam.nam$l_type - esa + 2;
      }
      else {
        /* There wasn't a type on the input, so ignore any file names as
           well.  If you want to pay attention to filenames without .dir
           in the input, just use ".DIR;1" as a default filespec for
           the $PARSE and set retlen thus
        retlen = (dirnam.nam$b_rsl ? dirnam.nam$b_rsl : dirnam.nam$b_esl);
        */
        retlen = dirnam.nam$l_name - esa;
        esa[retlen] = '\0';
      }
      if (buf) retpath = buf;
      else if (ts) New(7014,retpath,retlen,char);
      else retpath = __pathify_retbuf;
      strcpy(retpath,esa);
    }

    return retpath;
}  /* end of do_pathify_dirspec() */
/*}}}*/
/* External entry points */
char *pathify_dirspec(char *dir, char *buf)
{ return do_pathify_dirspec(dir,buf,0); }
char *pathify_dirspec_ts(char *dir, char *buf)
{ return do_pathify_dirspec(dir,buf,1); }

/*{{{ char *tounixspec[_ts](char *path, char *buf)*/
static char *do_tounixspec(char *spec, char *buf, int ts)
{
  static char __tounixspec_retbuf[NAM$C_MAXRSS+1];
  char *dirend, *rslt, *cp1, *cp2, *cp3, tmp[NAM$C_MAXRSS+1];
  int devlen, dirlen;

  if (spec == NULL || *spec == '\0') return NULL;
  if (buf) rslt = buf;
  else if (ts) New(7015,rslt,NAM$C_MAXRSS+1,char);
  else rslt = __tounixspec_retbuf;
  if (strchr(spec,'/') != NULL) {
    strcpy(rslt,spec);
    return rslt;
  }

  cp1 = rslt;
  cp2 = spec;
  dirend = strrchr(spec,']');
  if (dirend == NULL) dirend = strrchr(spec,'>');
  if (dirend == NULL) dirend = strchr(spec,':');
  if (dirend == NULL) {
    strcpy(rslt,spec);
    return rslt;
  }
  if (*cp2 != '[') {
    *(cp1++) = '/';
  }
  else {  /* the VMS spec begins with directories */
    cp2++;
    if (*cp2 == '-') {
      while (*cp2 == '-') {
        *(cp1++) = '.'; *(cp1++) = '.'; *(cp1++) = '/';
        cp2++;
      }
      if (*cp2 != '.' && *cp2 != ']' && *cp2 != '>') { /* we don't allow */
        if (ts) Safefree(rslt);                        /* filespecs like */
        errno = EVMSERR; vaxc$errno = RMS$_SYN;        /* [--foo.bar] */
        return NULL;
      }
      cp2++;
    }
    else if ( *(cp2) != '.') { /* add the implied device into the Unix spec */
      *(cp1++) = '/';
      if (getcwd(tmp,sizeof tmp,1) == NULL) {
        if (ts) Safefree(rslt);
        return NULL;
      }
      do {
        cp3 = tmp;
        while (*cp3 != ':' && *cp3) cp3++;
        *(cp3++) = '\0';
        if (strchr(cp3,']') != NULL) break;
      } while (((cp3 = getenv(tmp)) != NULL) && strcpy(tmp,cp3));
      cp3 = tmp;
      while (*cp3) *(cp1++) = *(cp3++);
      *(cp1++) = '/';
      if ((devlen = strlen(tmp)) + (dirlen = strlen(cp2)) + 1 > NAM$C_MAXRSS) {
        if (ts) Safefree(rslt);
        errno = ERANGE;
        return NULL;
      }
    }
    else cp2++;
  }
  for (; cp2 <= dirend; cp2++) {
    if (*cp2 == ':') {
      *(cp1++) = '/';
      if (*(cp2+1) == '[') cp2++;
    }
    else if (*cp2 == ']' || *cp2 == '>') *(cp1++) = '/';
    else if (*cp2 == '.') {
      *(cp1++) = '/';
      while (*(cp2+1) == ']' || *(cp2+1) == '>' ||
             *(cp2+1) == '[' || *(cp2+1) == '<') cp2++;
    }
    else if (*cp2 == '-') {
      if (*(cp2-1) == '[' || *(cp2-1) == '<' || *(cp2-1) == '.') {
        while (*cp2 == '-') {
          cp2++;
          *(cp1++) = '.'; *(cp1++) = '.'; *(cp1++) = '/';
        }
        if (*cp2 != '.' && *cp2 != ']' && *cp2 != '>') { /* we don't allow */
          if (ts) Safefree(rslt);                        /* filespecs like */
          errno = EVMSERR; vaxc$errno = RMS$_SYN;        /* [--foo.bar] */
          return NULL;
        }
        cp2++;
      }
      else *(cp1++) = *cp2;
    }
    else *(cp1++) = *cp2;
  }
  while (*cp2) *(cp1++) = *(cp2++);
  *cp1 = '\0';

  return rslt;

}  /* end of do_tounixspec() */
/*}}}*/
/* External entry points */
char *tounixspec(char *spec, char *buf) { return do_tounixspec(spec,buf,0); }
char *tounixspec_ts(char *spec, char *buf) { return do_tounixspec(spec,buf,1); }

/*{{{ char *tovmsspec[_ts](char *path, char *buf)*/
static char *do_tovmsspec(char *path, char *buf, int ts) {
  static char __tovmsspec_retbuf[NAM$C_MAXRSS+1];
  char *rslt, *dirend, *cp1, *cp2;

  if (path == NULL || *path == '\0') return NULL;
  if (buf) rslt = buf;
  else if (ts) New(7016,rslt,strlen(path)+1,char);
  else rslt = __tovmsspec_retbuf;
  if (strchr(path,']') != NULL || strchr(path,'>') != NULL ||
      (dirend = strrchr(path,'/')) == NULL) {
    strcpy(rslt,path);
    return rslt;
  }
  cp1 = rslt;
  cp2 = path;
  if (*cp2 == '/') {
    while (*(++cp2) != '/' && *cp2) *(cp1++) = *cp2;
    *(cp1++) = ':';
    *(cp1++) = '[';
    cp2++;
    }
  else {
    *(cp1++) = '[';
    *(cp1++) = '.';
  }
  for (; cp2 < dirend; cp2++) *(cp1++) = (*cp2 == '/') ? '.' : *cp2;
  *(cp1++) = ']';
  cp2++;
  while (*cp2) *(cp1++) = *(cp2++);
  *cp1 = '\0';

  return rslt;

}  /* end of do_tovmsspec() */
/*}}}*/
/* External entry points */
char *tovmsspec(char *path, char *buf) { return do_tovmsspec(path,buf,0); }
char *tovmsspec_ts(char *path, char *buf) { return do_tovmsspec(path,buf,1); }

/*{{{ char *tovmspath[_ts](char *path, char *buf)*/
static char *do_tovmspath(char *path, char *buf, int ts) {
  static char __tovmspath_retbuf[NAM$C_MAXRSS+1];
  int vmslen;
  char pathified[NAM$C_MAXRSS+1], vmsified[NAM$C_MAXRSS+1], *cp;

  if (path == NULL || *path == '\0') return NULL;
  if (do_pathify_dirspec(path,pathified,0) == NULL) return NULL;
  if (do_tovmsspec(pathified,buf ? buf : vmsified,0) == NULL) return NULL;
  if (buf) return buf;
  else if (ts) {
    vmslen = strlen(vmsified);
    New(7017,cp,vmslen,char);
    memcpy(cp,vmsified,vmslen);
    cp[vmslen] = '\0';
    return cp;
  }
  else {
    strcpy(__tovmspath_retbuf,vmsified);
    return __tovmspath_retbuf;
  }

}  /* end of do_tovmspath() */
/*}}}*/
/* External entry points */
char *tovmspath(char *path, char *buf) { return do_tovmspath(path,buf,0); }
char *tovmspath_ts(char *path, char *buf) { return do_tovmspath(path,buf,1); }


/*{{{ char *tounixpath[_ts](char *path, char *buf)*/
static char *do_tounixpath(char *path, char *buf, int ts) {
  static char __tounixpath_retbuf[NAM$C_MAXRSS+1];
  int unixlen;
  char pathified[NAM$C_MAXRSS+1], unixified[NAM$C_MAXRSS+1], *cp;

  if (path == NULL || *path == '\0') return NULL;
  if (do_pathify_dirspec(path,pathified,0) == NULL) return NULL;
  if (do_tounixspec(pathified,buf ? buf : unixified,0) == NULL) return NULL;
  if (buf) return buf;
  else if (ts) {
    unixlen = strlen(unixified);
    New(7017,cp,unixlen,char);
    memcpy(cp,unixified,unixlen);
    cp[unixlen] = '\0';
    return cp;
  }
  else {
    strcpy(__tounixpath_retbuf,unixified);
    return __tounixpath_retbuf;
  }

}  /* end of do_tounixpath() */
/*}}}*/
/* External entry points */
char *tounixpath(char *path, char *buf) { return do_tounixpath(path,buf,0); }
char *tounixpath_ts(char *path, char *buf) { return do_tounixpath(path,buf,1); }

/*
 * @(#)argproc.c 2.2 94/08/16	Mark Pizzolato (mark@infocomm.com)
 *
 *****************************************************************************
 *                                                                           *
 *  Copyright (C) 1989-1994 by                                               *
 *  Mark Pizzolato - INFO COMM, Danville, California  (510) 837-5600         *
 *                                                                           *
 *  Permission is hereby  granted for the reproduction of this software,     *
 *  on condition that this copyright notice is included in the reproduction, *
 *  and that such reproduction is not for purposes of profit or material     *
 *  gain.                                                                    *
 *                                                                           *
 *  27-Aug-1994 Modified for inclusion in perl5                              *
 *              by Charles Bailey  bailey@genetics.upenn.edu                 *
 *****************************************************************************
 */

/*
 * getredirection() is intended to aid in porting C programs
 * to VMS (Vax-11 C).  The native VMS environment does not support 
 * '>' and '<' I/O redirection, or command line wild card expansion, 
 * or a command line pipe mechanism using the '|' AND background 
 * command execution '&'.  All of these capabilities are provided to any
 * C program which calls this procedure as the first thing in the 
 * main program.
 * The piping mechanism will probably work with almost any 'filter' type
 * of program.  With suitable modification, it may useful for other
 * portability problems as well.
 *
 * Author:  Mark Pizzolato	mark@infocomm.com
 */
struct list_item
    {
    struct list_item *next;
    char *value;
    };

static void add_item(struct list_item **head,
		     struct list_item **tail,
		     char *value,
		     int *count);

static void expand_wild_cards(char *item,
			      struct list_item **head,
			      struct list_item **tail,
			      int *count);

static int background_process(int argc, char **argv);

static void pipe_and_fork(char **cmargv);

/*{{{ void getredirection(int *ac, char ***av)*/
void
getredirection(int *ac, char ***av)
/*
 * Process vms redirection arg's.  Exit if any error is seen.
 * If getredirection() processes an argument, it is erased
 * from the vector.  getredirection() returns a new argc and argv value.
 * In the event that a background command is requested (by a trailing "&"),
 * this routine creates a background subprocess, and simply exits the program.
 *
 * Warning: do not try to simplify the code for vms.  The code
 * presupposes that getredirection() is called before any data is
 * read from stdin or written to stdout.
 *
 * Normal usage is as follows:
 *
 *	main(argc, argv)
 *	int		argc;
 *    	char		*argv[];
 *	{
 *		getredirection(&argc, &argv);
 *	}
 */
{
    int			argc = *ac;	/* Argument Count	  */
    char		**argv = *av;	/* Argument Vector	  */
    char		*ap;   		/* Argument pointer	  */
    int	       		j;		/* argv[] index		  */
    int			item_count = 0;	/* Count of Items in List */
    struct list_item 	*list_head = 0;	/* First Item in List	    */
    struct list_item	*list_tail;	/* Last Item in List	    */
    char 		*in = NULL;	/* Input File Name	    */
    char 		*out = NULL;	/* Output File Name	    */
    char 		*outmode = "w";	/* Mode to Open Output File */
    char 		*err = NULL;	/* Error File Name	    */
    char 		*errmode = "w";	/* Mode to Open Error File  */
    int			cmargc = 0;    	/* Piped Command Arg Count  */
    char		**cmargv = NULL;/* Piped Command Arg Vector */
    stat_t		statbuf;	/* fstat buffer		    */

    /*
     * First handle the case where the last thing on the line ends with
     * a '&'.  This indicates the desire for the command to be run in a
     * subprocess, so we satisfy that desire.
     */
    ap = argv[argc-1];
    if (0 == strcmp("&", ap))
	exit(background_process(--argc, argv));
    if ('&' == ap[strlen(ap)-1])
	{
	ap[strlen(ap)-1] = '\0';
	exit(background_process(argc, argv));
	}
    /*
     * Now we handle the general redirection cases that involve '>', '>>',
     * '<', and pipes '|'.
     */
    for (j = 0; j < argc; ++j)
	{
	if (0 == strcmp("<", argv[j]))
	    {
	    if (j+1 >= argc)
		{
		errno = EINVAL;
		croak("No input file");
		}
	    in = argv[++j];
	    continue;
	    }
	if ('<' == *(ap = argv[j]))
	    {
	    in = 1 + ap;
	    continue;
	    }
	if (0 == strcmp(">", ap))
	    {
	    if (j+1 >= argc)
		{
		errno = EINVAL;
		croak("No input file");
		}
	    out = argv[++j];
	    continue;
	    }
	if ('>' == *ap)
	    {
	    if ('>' == ap[1])
		{
		outmode = "a";
		if ('\0' == ap[2])
		    out = argv[++j];
		else
		    out = 2 + ap;
		}
	    else
		out = 1 + ap;
	    if (j >= argc)
		{
		errno = EINVAL;
		croak("No output file");
		}
	    continue;
	    }
	if (('2' == *ap) && ('>' == ap[1]))
	    {
	    if ('>' == ap[2])
		{
		errmode = "a";
		if ('\0' == ap[3])
		    err = argv[++j];
		else
		    err = 3 + ap;
		}
	    else
		if ('\0' == ap[2])
		    err = argv[++j];
		else
		    err = 1 + ap;
	    if (j >= argc)
		{
		errno = EINVAL;
		croak("No error file");
		}
	    continue;
	    }
	if (0 == strcmp("|", argv[j]))
	    {
	    if (j+1 >= argc)
		{
		errno = EPIPE;
		croak("No command into which to pipe");
		}
	    cmargc = argc-(j+1);
	    cmargv = &argv[j+1];
	    argc = j;
	    continue;
	    }
	if ('|' == *(ap = argv[j]))
	    {
	    ++argv[j];
	    cmargc = argc-j;
	    cmargv = &argv[j];
	    argc = j;
	    continue;
	    }
	expand_wild_cards(ap, &list_head, &list_tail, &item_count);
	}
    /*
     * Allocate and fill in the new argument vector, Some Unix's terminate
     * the list with an extra null pointer.
     */
    New(7002, argv, item_count+1, char *);
    *av = argv;
    for (j = 0; j < item_count; ++j, list_head = list_head->next)
	argv[j] = list_head->value;
    *ac = item_count;
    if (cmargv != NULL)
	{
	if (out != NULL)
	    {
	    errno = EINVAL;
	    croak("'|' and '>' may not both be specified on command line");
	    }
	pipe_and_fork(cmargv);
	}
	
    /* Check for input from a pipe (mailbox) */

    if (1 == isapipe(0))
	{
	char mbxname[L_tmpnam];
	long int bufsize;
	long int dvi_item = DVI$_DEVBUFSIZ;
	$DESCRIPTOR(mbxnam, "");
	$DESCRIPTOR(mbxdevnam, "");

	/* Input from a pipe, reopen it in binary mode to disable	*/
	/* carriage control processing.	 				*/

	if (in != NULL)
	    {
	    errno = EINVAL;
	    croak("'|' and '<' may not both be specified on command line");
	    }
	fgetname(stdin, mbxname);
	mbxnam.dsc$a_pointer = mbxname;
	mbxnam.dsc$w_length = strlen(mbxnam.dsc$a_pointer);	
	lib$getdvi(&dvi_item, 0, &mbxnam, &bufsize, 0, 0);
	mbxdevnam.dsc$a_pointer = mbxname;
	mbxdevnam.dsc$w_length = sizeof(mbxname);
	dvi_item = DVI$_DEVNAM;
	lib$getdvi(&dvi_item, 0, &mbxnam, 0, &mbxdevnam, &mbxdevnam.dsc$w_length);
	mbxdevnam.dsc$a_pointer[mbxdevnam.dsc$w_length] = '\0';
	errno = 0;
	freopen(mbxname, "rb", stdin);
	if (errno != 0)
	    {
	    croak("Error reopening pipe (name: %s) in binary mode",mbxname);
	    }
	}
    if ((in != NULL) && (NULL == freopen(in, "r", stdin, "mbc=32", "mbf=2")))
	{
	croak("Can't open input file %s",in);
	}
    if ((out != NULL) && (NULL == freopen(out, outmode, stdout, "mbc=32", "mbf=2")))
	{	
	croak("Can't open output file %s",out);
	}
    if ((err != NULL) && (NULL == freopen(err, errmode, stderr, "mbc=32", "mbf=2")))
	{	
	croak("Can't open error file %s",err);
	}
#ifdef ARGPROC_DEBUG
    fprintf(stderr, "Arglist:\n");
    for (j = 0; j < *ac;  ++j)
	fprintf(stderr, "argv[%d] = '%s'\n", j, argv[j]);
#endif
}  /* end of getredirection() */
/*}}}*/

static void add_item(struct list_item **head,
		     struct list_item **tail,
		     char *value,
		     int *count)
{
    if (*head == 0)
	{
	New(7003,*head,1,struct list_item);
	*tail = *head;
	}
    else {
	New(7004,(*tail)->next,1,struct list_item);
	*tail = (*tail)->next;
	}
    (*tail)->value = value;
    ++(*count);
}

static void expand_wild_cards(char *item,
			      struct list_item **head,
			      struct list_item **tail,
			      int *count)
{
int expcount = 0;
int context = 0;
int isunix = 0;
int status;
int status_value;
char *had_version;
char *had_device;
int had_directory;
char *devdir;
char vmsspec[NAM$C_MAXRSS+1];
$DESCRIPTOR(filespec, "");
$DESCRIPTOR(defaultspec, "SYS$DISK:[]*.*;");
$DESCRIPTOR(resultspec, "");
unsigned long int zero = 0;

    if (strcspn(item, "*%") == strlen(item))
	{
	add_item(head, tail, item, count);
	return;
	}
    resultspec.dsc$b_dtype = DSC$K_DTYPE_T;
    resultspec.dsc$b_class = DSC$K_CLASS_D;
    resultspec.dsc$a_pointer = NULL;
    if (isunix = strchr(item,'/'))
      filespec.dsc$a_pointer = do_tovmsspec(item,vmsspec,0);
    if (!isunix || !filespec.dsc$a_pointer)
      filespec.dsc$a_pointer = item;
    filespec.dsc$w_length = strlen(filespec.dsc$a_pointer);
    /*
     * Only return version specs, if the caller specified a version
     */
    had_version = strchr(item, ';');
    /*
     * Only return device and directory specs, if the caller specifed either.
     */
    had_device = strchr(item, ':');
    had_directory = (isunix || NULL != strchr(item, '[')) || (NULL != strchr(item, '<'));
    
    while (1 == (1&lib$find_file(&filespec, &resultspec, &context,
    				 &defaultspec, 0, &status_value, &zero)))
	{
	char *string;
	char *c;

	New(7005,string,resultspec.dsc$w_length+1,char);
	strncpy(string, resultspec.dsc$a_pointer, resultspec.dsc$w_length);
	string[resultspec.dsc$w_length] = '\0';
	if (NULL == had_version)
	    *((char *)strrchr(string, ';')) = '\0';
	if ((!had_directory) && (had_device == NULL))
	    {
	    if (NULL == (devdir = strrchr(string, ']')))
		devdir = strrchr(string, '>');
	    strcpy(string, devdir + 1);
	    }
	/*
	 * Be consistent with what the C RTL has already done to the rest of
	 * the argv items and lowercase all of these names.
	 */
	for (c = string; *c; ++c)
	    if (isupper(*c))
		*c = tolower(*c);
	if (isunix) trim_unixpath(item,string);
	add_item(head, tail, string, count);
	++expcount;
	}
    if (expcount == 0)
	add_item(head, tail, item, count);
    lib$sfree1_dd(&resultspec);
    lib$find_file_end(&context);
}

static int child_st[2];/* Event Flag set when child process completes	*/

static short child_chan;/* I/O Channel for Pipe Mailbox		*/

static exit_handler(int *status)
{
short iosb[4];

    if (0 == child_st[0])
	{
#ifdef ARGPROC_DEBUG
	fprintf(stderr, "Waiting for Child Process to Finish . . .\n");
#endif
	fflush(stdout);	    /* Have to flush pipe for binary data to	*/
			    /* terminate properly -- <tp@mccall.com>	*/
	sys$qiow(0, child_chan, IO$_WRITEOF, iosb, 0, 0, 0, 0, 0, 0, 0, 0);
	sys$dassgn(child_chan);
	fclose(stdout);
	sys$synch(0, child_st);
	}
    return(1);
}

static void sig_child(int chan)
{
#ifdef ARGPROC_DEBUG
    fprintf(stderr, "Child Completion AST\n");
#endif
    if (child_st[0] == 0)
	child_st[0] = 1;
}

static struct exit_control_block
    {
    struct exit_control_block *flink;
    int	(*exit_routine)();
    int arg_count;
    int *status_address;
    int exit_status;
    } exit_block =
    {
    0,
    exit_handler,
    1,
    &exit_block.exit_status,
    0
    };

static void pipe_and_fork(char **cmargv)
{
    char subcmd[2048];
    $DESCRIPTOR(cmddsc, "");
    static char mbxname[64];
    $DESCRIPTOR(mbxdsc, mbxname);
    short iosb[4];
    int status;
    int pid, j;
    short dvi_item = DVI$_DEVNAM;
    unsigned long int zero = 0, one = 1;

    strcpy(subcmd, cmargv[0]);
    for (j = 1; NULL != cmargv[j]; ++j)
	{
	strcat(subcmd, " \"");
	strcat(subcmd, cmargv[j]);
	strcat(subcmd, "\"");
	}
    cmddsc.dsc$a_pointer = subcmd;
    cmddsc.dsc$w_length = strlen(cmddsc.dsc$a_pointer);

	create_mbx(&child_chan,&mbxdsc);
#ifdef ARGPROC_DEBUG
    fprintf(stderr, "Pipe Mailbox Name = '%s'\n", mbxdsc.dsc$a_pointer);
    fprintf(stderr, "Sub Process Command = '%s'\n", cmddsc.dsc$a_pointer);
#endif
    if (0 == (1&(vaxc$errno = lib$spawn(&cmddsc, &mbxdsc, 0, &one,
    					0, &pid, child_st, &zero, sig_child,
    					&child_chan))))
	{
	errno = EVMSERR;
	croak("Can't spawn subprocess");
	}
#ifdef ARGPROC_DEBUG
    fprintf(stderr, "Subprocess's Pid = %08X\n", pid);
#endif
    sys$dclexh(&exit_block);
    if (NULL == freopen(mbxname, "wb", stdout))
	{
	croak("Can't open pipe mailbox for output");
	}
}

static int background_process(int argc, char **argv)
{
char command[2048] = "$";
$DESCRIPTOR(value, "");
static $DESCRIPTOR(cmd, "BACKGROUND$COMMAND");
static $DESCRIPTOR(null, "NLA0:");
static $DESCRIPTOR(pidsymbol, "SHELL_BACKGROUND_PID");
char pidstring[80];
$DESCRIPTOR(pidstr, "");
int pid;
unsigned long int flags = 17, one = 1;

    strcat(command, argv[0]);
    while (--argc)
	{
	strcat(command, " \"");
	strcat(command, *(++argv));
	strcat(command, "\"");
	}
    value.dsc$a_pointer = command;
    value.dsc$w_length = strlen(value.dsc$a_pointer);
    if (0 == (1&(vaxc$errno = lib$set_symbol(&cmd, &value))))
	{
	errno = EVMSERR;
	croak("Can't create symbol for subprocess command");
	}
    if ((0 == (1&(vaxc$errno = lib$spawn(&cmd, &null, 0, &flags, 0, &pid)))) &&
	(vaxc$errno != 0x38250))
	{
	errno = EVMSERR;
	croak("Can't spawn subprocess");
	}
    if (vaxc$errno == 0x38250) /* We must be BATCH, so retry */
	if (0 == (1&(vaxc$errno = lib$spawn(&cmd, &null, 0, &one, 0, &pid))))
	    {
	    errno = EVMSERR;
	    croak("Can't spawn subprocess");
	    }
#ifdef ARGPROC_DEBUG
    fprintf(stderr, "%s\n", command);
#endif
    sprintf(pidstring, "%08X", pid);
    fprintf(stderr, "%s\n", pidstring);
    pidstr.dsc$a_pointer = pidstring;
    pidstr.dsc$w_length = strlen(pidstr.dsc$a_pointer);
    lib$set_symbol(&pidsymbol, &pidstr);
    return(SS$_NORMAL);
}
/*}}}*/
/***** End of code taken from Mark Pizzolato's argproc.c package *****/

/*
 * flex_stat, flex_fstat
 * basic stat, but gets it right when asked to stat
 * a Unix-style path ending in a directory name (e.g. dir1/dir2/dir3)
 */

static char namecache[NAM$C_MAXRSS+1];

static int
is_null_device(name)
    const char *name;
{
    /* The VMS null device is named "_NLA0:", usually abbreviated as "NL:".
       The underscore prefix, controller letter, and unit number are
       independently optional; for our purposes, the colon punctuation
       is not.  The colon can be trailed by optional directory and/or
       filename, but two consecutive colons indicates a nodename rather
       than a device.  [pr]  */
  if (*name == '_') ++name;
  if (tolower(*name++) != 'n') return 0;
  if (tolower(*name++) != 'l') return 0;
  if (tolower(*name) == 'a') ++name;
  if (*name == '0') ++name;
  return (*name++ == ':') && (*name != ':');
}

/*{{{ int flex_fstat(int fd, struct stat *statbuf)*/
int
flex_fstat(int fd, struct stat *statbuf)
{
  char fspec[NAM$C_MAXRSS+1];

  if (!getname(fd,fspec)) return -1;
  return flex_stat(fspec,statbuf);

}  /* end of flex_fstat() */
/*}}}*/

/*{{{ int flex_stat(char *fspec, struct stat *statbufp)*/
flex_stat(char *fspec, struct stat *statbufp)
{
    char fileified[NAM$C_MAXRSS+1];
    int retval,myretval;
    struct stat tmpbuf;

    
    if (statbufp == &statcache) strcpy(namecache,fspec);
    if (is_null_device(fspec)) { /* Fake a stat() for the null device */
      memset(statbufp,0,sizeof *statbufp);
      statbufp->st_dev = "_NLA0:";
      statbufp->st_mode = S_IFBLK | S_IREAD | S_IWRITE | S_IEXEC;
      statbufp->st_uid = 0x00010001;
      statbufp->st_gid = 0x0001;
      time(&statbufp->st_mtime);
      statbufp->st_atime = statbufp->st_ctime = statbufp->st_mtime;
      return 0;
    }
    if (do_fileify_dirspec(fspec,fileified,0) == NULL) myretval = -1;
    else {
      myretval = stat(fileified,&tmpbuf);
    }
    retval = stat(fspec,statbufp);
    if (!myretval) {
      if (retval == -1) {
        *statbufp = tmpbuf;
        retval = 0;
      }
      else if (!retval) { /* Dir with same name.  Substitute it. */
        statbufp->st_mode &= ~S_IFDIR;
        statbufp->st_mode |= tmpbuf.st_mode & S_IFDIR;
        strcpy(namecache,fileified);
      }
    }
    return retval;

}  /* end of flex_stat() */
/*}}}*/

/* trim_unixpath()
 * Trim Unix-style prefix off filespec, so it looks like what a shell
 * glob expansion would return (i.e. from specified prefix on, not
 * full path).  Note that returned filespec is Unix-style, regardless
 * of whether input filespec was VMS-style or Unix-style.
 *
 * Returns !=0 on success, 0 on failure.
 */
/*{{{int trim_unixpath(char *template, char *fspec)*/
int
trim_unixpath(char *template, char *fspec)
{
  char unixified[NAM$C_MAXRSS+1], *base, *cp1, *cp2;
  register int tmplen;

  if (strpbrk(fspec,"]>:") != NULL) {
    if (do_tounixspec(fspec,unixified,0) == NULL) return 0;
    else base = unixified;
  }
  else base = fspec;
  for (cp2 = base; *cp2; cp2++) ;  /* Find end of filespec */

  /* Find prefix to template consisting of path elements without wildcards */
  if ((cp1 = strpbrk(template,"*%?")) == NULL)
    for (cp1 = template; *cp1; cp1++) ;
  else while (cp1 >= template && *cp1 != '/') cp1--;
  if (cp1 == template) return 1;  /* Wildcard was up front - no prefix to clip */
  tmplen = cp1 - template;

  /* Try to find template prefix on filespec */
  if (!memcmp(base,template,tmplen)) return 1;  /* Nothing before prefix - we're done */
  for (; cp2 - base > tmplen; base++) {
     if (*base != '/') continue;
     if (!memcmp(base + 1,template,tmplen)) break;
  }
  if (cp2 - base == tmplen) return 0;  /* Not there - not good */
  base++;  /* Move past leading '/' */
  /* Copy down remaining portion of filespec, including trailing NUL */
  memmove(fspec,base,cp2 - base + 1);
  return 1;

}  /* end of trim_unixpath() */
/*}}}*/

/* Do the permissions allow some operation?  Assumes statcache already set. */
/* Do this via $Check_Access on VMS, since the CRTL stat() returns only a
 * subset of the applicable information.
 */
/*{{{I32 cando(I32 bit, I32 effective, struct stat *statbufp)*/
I32
cando(I32 bit, I32 effective, struct stat *statbufp)
{
  unsigned long int objtyp = ACL$C_FILE, access, retsts;
  unsigned short int retlen;
  struct dsc$descriptor_s namdsc = {0, DSC$K_DTYPE_T, DSC$K_CLASS_S, namecache};
  static char usrname[L_cuserid];
  static struct dsc$descriptor_s usrdsc =
         {0, DSC$K_DTYPE_T, DSC$K_CLASS_S, usrname};
  struct itmlst_3 armlst[2] = {sizeof access, CHP$_ACCESS, &access, &retlen,
                                           0,           0,       0,       0};

  if (!usrdsc.dsc$w_length) {
    cuserid(usrname);
    usrdsc.dsc$w_length = strlen(usrname);
  }
  namdsc.dsc$w_length = strlen(namecache);
  switch (bit) {
    case S_IXUSR:
    case S_IXGRP:
    case S_IXOTH:
      access = ARM$M_EXECUTE;
      break;
    case S_IRUSR:
    case S_IRGRP:
    case S_IROTH:
      access = ARM$M_READ;
      break;
    case S_IWUSR:
    case S_IWGRP:
    case S_IWOTH:
      access = ARM$M_READ;
      break;
    default:
      return FALSE;
  }

  retsts = sys$check_access(&objtyp,&namdsc,&usrdsc,armlst);
  if (retsts == SS$_NORMAL) return TRUE;
  if (retsts == SS$_NOPRIV) return FALSE;
  _cksts(retsts);

  return FALSE;  /* Should never get here */

}  /* end of cando() */
/*}}}*/

/*
 *  VMS readdir() routines.
 *  Written by Rich $alz, <rsalz@bbn.com> in August, 1990.
 *  This code has no copyright.
 *
 *  21-Jul-1994  Charles Bailey  bailey@genetics.upenn.edu
 *  Minor modifications to original routines.
 */

    /* Number of elements in vms_versions array */
#define VERSIZE(e)	(sizeof e->vms_versions / sizeof e->vms_versions[0])

/*
 *  Open a directory, return a handle for later use.
 */
/*{{{ DIR *opendir(char*name) */
DIR *
opendir(char *name)
{
    DIR *dd;
    char dir[NAM$C_MAXRSS+1];
      
    /* Get memory for the handle, and the pattern. */
    New(7006,dd,1,DIR);
    if (do_tovmspath(name,dir,0) == NULL) {
      Safefree((char *)dd);
      return(NULL);
    }
    New(7007,dd->pattern,strlen(dir)+sizeof "*.*" + 1,char);

    /* Fill in the fields; mainly playing with the descriptor. */
    (void)sprintf(dd->pattern, "%s*.*",dir);
    dd->context = 0;
    dd->count = 0;
    dd->vms_wantversions = 0;
    dd->pat.dsc$a_pointer = dd->pattern;
    dd->pat.dsc$w_length = strlen(dd->pattern);
    dd->pat.dsc$b_dtype = DSC$K_DTYPE_T;
    dd->pat.dsc$b_class = DSC$K_CLASS_S;

    return dd;
}  /* end of opendir() */
/*}}}*/

/*
 *  Set the flag to indicate we want versions or not.
 */
/*{{{ void vmsreaddirversions(DIR *dd, int flag)*/
void
vmsreaddirversions(DIR *dd, int flag)
{
    dd->vms_wantversions = flag;
}
/*}}}*/

/*
 *  Free up an opened directory.
 */
/*{{{ void closedir(DIR *dd)*/
void
closedir(DIR *dd)
{
    (void)lib$find_file_end(&dd->context);
    Safefree(dd->pattern);
    Safefree((char *)dd);
}
/*}}}*/

/*
 *  Collect all the version numbers for the current file.
 */
static void
collectversions(dd)
    DIR *dd;
{
    struct dsc$descriptor_s	pat;
    struct dsc$descriptor_s	res;
    struct dirent *e;
    char *p, *text, buff[sizeof dd->entry.d_name];
    int i;
    unsigned long context, tmpsts;

    /* Convenient shorthand. */
    e = &dd->entry;

    /* Add the version wildcard, ignoring the "*.*" put on before */
    i = strlen(dd->pattern);
    New(7008,text,i + e->d_namlen + 3,char);
    (void)strcpy(text, dd->pattern);
    (void)sprintf(&text[i - 3], "%s;*", e->d_name);

    /* Set up the pattern descriptor. */
    pat.dsc$a_pointer = text;
    pat.dsc$w_length = i + e->d_namlen - 1;
    pat.dsc$b_dtype = DSC$K_DTYPE_T;
    pat.dsc$b_class = DSC$K_CLASS_S;

    /* Set up result descriptor. */
    res.dsc$a_pointer = buff;
    res.dsc$w_length = sizeof buff - 2;
    res.dsc$b_dtype = DSC$K_DTYPE_T;
    res.dsc$b_class = DSC$K_CLASS_S;

    /* Read files, collecting versions. */
    for (context = 0, e->vms_verscount = 0;
         e->vms_verscount < VERSIZE(e);
         e->vms_verscount++) {
	tmpsts = lib$find_file(&pat, &res, &context);
	if (tmpsts == RMS$_NMF || context == 0) break;
	_cksts(tmpsts);
	buff[sizeof buff - 1] = '\0';
	if (p = strchr(buff, ';'))
	    e->vms_versions[e->vms_verscount] = atoi(p + 1);
	else
	    e->vms_versions[e->vms_verscount] = -1;
    }

    _cksts(lib$find_file_end(&context));
    Safefree(text);

}  /* end of collectversions() */

/*
 *  Read the next entry from the directory.
 */
/*{{{ struct dirent *readdir(DIR *dd)*/
struct dirent *
readdir(DIR *dd)
{
    struct dsc$descriptor_s	res;
    char *p, buff[sizeof dd->entry.d_name];
    int i;
    unsigned long int tmpsts;

    /* Set up result descriptor, and get next file. */
    res.dsc$a_pointer = buff;
    res.dsc$w_length = sizeof buff - 2;
    res.dsc$b_dtype = DSC$K_DTYPE_T;
    res.dsc$b_class = DSC$K_CLASS_S;
    dd->count++;
    tmpsts = lib$find_file(&dd->pat, &res, &dd->context);
    if ( tmpsts == RMS$_NMF || dd->context == 0) return NULL;  /* None left. */

    /* Force the buffer to end with a NUL, and downcase name to match C convention. */
    buff[sizeof buff - 1] = '\0';
    for (p = buff; !isspace(*p); p++) *p = _tolower(*p);
    *p = '\0';

    /* Skip any directory component and just copy the name. */
    if (p = strchr(buff, ']')) (void)strcpy(dd->entry.d_name, p + 1);
    else (void)strcpy(dd->entry.d_name, buff);

    /* Clobber the version. */
    if (p = strchr(dd->entry.d_name, ';')) *p = '\0';

    dd->entry.d_namlen = strlen(dd->entry.d_name);
    dd->entry.vms_verscount = 0;
    if (dd->vms_wantversions) collectversions(dd);
    return &dd->entry;

}  /* end of readdir() */
/*}}}*/

/*
 *  Return something that can be used in a seekdir later.
 */
/*{{{ long telldir(DIR *dd)*/
long
telldir(DIR *dd)
{
    return dd->count;
}
/*}}}*/

/*
 *  Return to a spot where we used to be.  Brute force.
 */
/*{{{ void seekdir(DIR *dd,long count)*/
void
seekdir(DIR *dd, long count)
{
    int vms_wantversions;
    unsigned long int tmpsts;

    /* If we haven't done anything yet... */
    if (dd->count == 0)
	return;

    /* Remember some state, and clear it. */
    vms_wantversions = dd->vms_wantversions;
    dd->vms_wantversions = 0;
    _cksts(lib$find_file_end(&dd->context));
    dd->context = 0;

    /* The increment is in readdir(). */
    for (dd->count = 0; dd->count < count; )
	(void)readdir(dd);

    dd->vms_wantversions = vms_wantversions;

}  /* end of seekdir() */
/*}}}*/

/* VMS subprocess management
 *
 * my_vfork() - just a vfork(), after setting a flag to record that
 * the current script is trying a Unix-style fork/exec.
 *
 * vms_do_aexec() and vms_do_exec() are called in response to the
 * perl 'exec' function.  If this follows a vfork call, then they
 * call out the the regular perl routines in doio.c which do an
 * execvp (for those who really want to try this under VMS).
 * Otherwise, they do exactly what the perl docs say exec should
 * do - terminate the current script and invoke a new command
 * (See below for notes on command syntax.)
 *
 * do_aspawn() and do_spawn() implement the VMS side of the perl
 * 'system' function.
 *
 * Note on command arguments to perl 'exec' and 'system': When handled
 * in 'VMSish fashion' (i.e. not after a call to vfork) The args
 * are concatenated to form a DCL command string.  If the first arg
 * begins with '$' (i.e. the perl script had "\$ Type" or some such),
 * the the command string is hrnded off to DCL directly.  Otherwise,
 * the first token of the command is taken as the filespec of an image
 * to run.  The filespec is expanded using a default type of '.EXE' and
 * the process defaults for device, directory, etc., and the resultant
 * filespec is invoked using the DCL verb 'MCR', and passed the rest of
 * the command string as parameters.  This is perhaps a bit compicated,
 * but I hope it will form a happy medium between what VMS folks expect
 * from lib$spawn and what Unix folks expect from exec.
 */

static int vfork_called;

/*{{{int my_vfork()*/
int
my_vfork()
{
  vfork_called = 1;
  return vfork();
}
/*}}}*/

static void
setup_argstr(SV *really, SV **mark, SV **sp, char **argstr)
{
  char *tmps, *junk;
  register size_t cmdlen = 0;
  size_t rlen;
  register SV **idx;

  idx = mark;
  if (really && *(tmps = SvPV(really,rlen))) {
    cmdlen += rlen + 1;
    idx++;
  }
  
  for (idx++; idx <= sp; idx++) {
    if (*idx) {
      junk = SvPVx(*idx,rlen);
      cmdlen += rlen ? rlen + 1 : 0;
    }
  }
  New(401,*argstr,cmdlen, char);

  if (*tmps) {
    strcpy(*argstr,tmps);
    mark++;
  }
  else **argstr = '\0';
  while (++mark <= sp) {
    if (*mark) {
      strcat(*argstr," ");
      strcat(*argstr,SvPVx(*mark,na));
    }
  }

}  /* end of setup_argstr() */

static unsigned long int
setup_cmddsc(char *cmd, struct dsc$descriptor_s *cmddsc, int check_img)
{
  char resspec[NAM$C_MAXRSS+1];
  $DESCRIPTOR(defdsc,".EXE");
  $DESCRIPTOR(resdsc,resspec);
  struct dsc$descriptor_s imgdsc = {0, DSC$K_DTYPE_T, DSC$K_CLASS_S, 0};
  unsigned long int cxt = 0, flags = 1, retsts;
  register char *s, *rest, *cp;
  register int isdcl = 0;

  s = cmd;
  while (*s && isspace(*s)) s++;
  if (check_img) {
    if (*s == '$') { /* Check whether this is a DCL command: leading $ and */
      isdcl = 1;     /* no dev/dir separators (i.e. not a foreign command) */
      for (cp = s; *cp && *cp != '/' && !isspace(*cp); cp++) {
        if (*cp == ':' || *cp == '[' || *cp == '<') {
          isdcl = 0;
          break;
        }
      }
    }
  }
  else isdcl = 1;
  if (isdcl) {  /* It's a DCL command, just do it. */
    cmddsc->dsc$a_pointer = cmd;
    cmddsc->dsc$w_length = strlen(cmd);
  }
  else {                           /* assume first token is an image spec */
    cmd = s;
    while (*s && !isspace(*s)) s++;
    rest = *s ? s : 0;
    imgdsc.dsc$a_pointer = cmd;
    imgdsc.dsc$w_length = s - cmd;
    retsts = lib$find_file(&imgdsc,&resdsc,&cxt,&defdsc,0,0,&flags);
    if ((retsts & STS$M_CODE) == (SHR$_NOWILD & STS$M_CODE)) return retsts;
    else {
      _cksts(retsts);
      _cksts(lib$find_file_end(&cxt));
      s = resspec;
      while (*s && !isspace(*s)) s++;
      *s = '\0';
      New(402,Cmd,6 + s - resspec + (rest ? strlen(rest) : 0),char);
      strcpy(Cmd,"$ MCR ");
      strcat(Cmd,resspec);
      if (rest) strcat(Cmd,rest);
      cmddsc->dsc$a_pointer = Cmd;
      cmddsc->dsc$w_length = strlen(Cmd);
    }
  }

  return SS$_NORMAL;
}  /* end of setup_cmddsc() */

/* {{{ bool vms_do_aexec(SV *really,SV **mark,SV **sp) */
bool
vms_do_aexec(SV *really,SV **mark,SV **sp)
{

  if (sp > mark) {
    if (vfork_called) {           /* this follows a vfork - act Unixish */
      vfork_called = 0;
      do_aexec(really,mark,sp);
    }
    else {                        /* no vfork - act VMSish */
      setup_argstr(really,mark,sp,&Argv);
      return vms_do_exec(Argv);
    }
  }

  return FALSE;
}  /* end of vms_do_aexec() */
/*}}}*/

/* {{{bool vms_do_exec(char *cmd) */
bool
vms_do_exec(char *cmd)
{

  if (vfork_called) {             /* this follows a vfork - act Unixish */
    vfork_called = 0;
    do_exec(cmd);
  }
  else {                          /* no vfork - act VMSish */
    struct dsc$descriptor_s cmddsc = {0, DSC$K_DTYPE_T, DSC$K_CLASS_S, 0};

    if ((vaxc$errno = setup_cmddsc(cmd,&cmddsc,1)) & 1)
      vaxc$errno = lib$do_command(&cmddsc);

    errno = EVMSERR;
    if (dowarn)
      warn("Can't exec \"%s\": %s", cmddsc.dsc$a_pointer, Strerror(errno));
    do_execfree();
  }

  return FALSE;

}  /* end of vms_do_exec() */
/*}}}*/

unsigned long int do_spawn(char *);

/* {{{ unsigned long int do_aspawn(SV *really,SV **mark,SV **sp) */
unsigned long int
do_aspawn(SV *really,SV **mark,SV **sp)
{

  if (sp > mark) {
    setup_argstr(really,mark,sp,&Argv);
    return do_spawn(Argv);
  }

  return SS$_ABORT;
}  /* end of do_aspawn() */
/*}}}*/

/* {{{unsigned long int do_spawn(char *cmd) */
unsigned long int
do_spawn(char *cmd)
{
  struct dsc$descriptor_s cmddsc = {0, DSC$K_DTYPE_T, DSC$K_CLASS_S, 0};
  unsigned long int substs;

  if ((substs = setup_cmddsc(cmd,&cmddsc,0)) & 1)
    _cksts(lib$spawn(&cmddsc,&nl_desc,0,0,0,&substs,0,0,0,0,0));
  
  if (!(substs&1)) {
    vaxc$errno = substs;
    errno = EVMSERR;
    if (dowarn)
      warn("Can't exec \"%s\": %s", cmddsc.dsc$a_pointer, Strerror(errno));
  }
  return substs;

}  /* end of do_spawn() */
/*}}}*/

/* 
 * A simple fwrite replacement which outputs itmsz*nitm chars without
 * introducing record boundaries every itmsz chars.
 */
/*{{{ int my_fwrite(void *src, size_t itmsz, size_t nitm, FILE *dest)*/
int
my_fwrite(void *src, size_t itmsz, size_t nitm, FILE *dest)
{
  register char *cp, *end;

  end = (char *)src + itmsz * nitm;

  while ((char *)src <= end) {
    for (cp = src; cp <= end; cp++) if (!*cp) break;
    if (fputs(src,dest) == EOF) return EOF;
    if (cp < end)
      if (fputc('\0',dest) == EOF) return EOF;
    src = cp + 1;
  }

  return 1;

}  /* end of my_fwrite() */
/*}}}*/

#ifndef VMS_DO_SOCKETS
/***** The following two routines are temporary, and should be removed,
 * along with the corresponding #defines in vmsish.h, when TCP/IP support
 * has been added to the VMS port of perl5.  (The temporary hacks are
 * here now sho that pack can handle type N elements.)
 * - C. Bailey 16-Aug-1994
 *****/

/*{{{ unsigned short int tmp_shortflip(unsigned short int val)*/
unsigned short int
tmp_shortflip(unsigned short int val)
{
    return val << 8 | val >> 8;
}
/*}}}*/

/*{{{ unsigned long int tmp_longflip(unsigned long int val)*/
unsigned long int
tmp_longflip(unsigned long int val)
{
    unsigned long int scratch = val;
    unsigned char savbyte, *tmp;

    tmp = (unsigned char *) &scratch;
    savbyte = tmp[0]; tmp[0] = tmp[3]; tmp[3] = savbyte;
    savbyte = tmp[1]; tmp[1] = tmp[2]; tmp[2] = savbyte;

    return scratch;
}
/*}}}*/
#endif
