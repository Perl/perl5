#include <libc/stubs.h>
#include <io.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <libc/file.h>
#include <process.h>
#include <fcntl.h>
#include <glob.h>
#include <sys/fsext.h>
#include <crt0.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#if DJGPP==2 && DJGPP_MINOR<2

/* XXX I should rewrite this stuff someday. ML */

/* This is from popen.c */

/* Copyright (C) 1997 DJ Delorie, see COPYING.DJ for details */
/* Copyright (C) 1996 DJ Delorie, see COPYING.DJ for details */
/* Copyright (C) 1995 DJ Delorie, see COPYING.DJ for details */

/* hold file pointer, descriptor, command, mode, temporary file name,
   and the status of the command  */
struct pipe_list {
  FILE *fp;
  int fd;
  int exit_status;
  char *command, mode[10], temp_name[L_tmpnam];
  struct pipe_list *next;
};

/* static, global list pointer */
static struct pipe_list *pl = NULL;

FILE *
popen (const char *cm, const char *md) /* program name, pipe mode */
{
  struct pipe_list *l1;

  /* make new node */
  if ((l1 = (struct pipe_list *) malloc (sizeof (struct pipe_list))) == NULL)
    return NULL;

  /* zero out elements to we'll get here */
  l1->fp = NULL;
  l1->next = pl;
  pl = l1;

  /* stick in elements we know already */
  l1->exit_status = -1;
  strcpy (l1->mode, md);
  if (tmpnam (l1->temp_name) == NULL)
    return NULL;

  /* if can save the program name, build temp file */
  if ((l1->command = malloc(strlen(cm)+1)))
  {
    strcpy(l1->command, cm);
    /* if caller wants to read */
    if (l1->mode[0] == 'r')
    {
      /* dup stdout */
      if ((l1->fd = dup (fileno (stdout))) == EOF)
	l1->fp = NULL;
      else if (!(l1->fp = freopen (l1->temp_name, "wb", stdout)))
	l1->fp = NULL;
      else
	/* exec cmd */
      {
        if ((l1->exit_status = system (cm)) == EOF)
          l1->fp = NULL;
      }
      /* reopen real stdout */
      if (dup2 (l1->fd, fileno (stdout)) == EOF)
	l1->fp = NULL;
      else
	/* open file for reader */
	l1->fp = fopen (l1->temp_name, l1->mode);
      close(l1->fd);
    }
    else
      /* if caller wants to write */
      if (l1->mode[0] == 'w')
        /* open temp file */
        l1->fp = fopen (l1->temp_name, l1->mode);
      else
        /* unknown mode */
        l1->fp = NULL;
  }
  return l1->fp;              /* return == NULL ? ERROR : OK */
}

int
pclose (FILE *pp)
{
  struct pipe_list *l1, *l2;    /* list pointers */
  int retval=0;			/* function return value */

  /* if pointer is first node */
  if (pl->fp == pp)
  {
    /* save node and take it out the list */
    l1 = pl;
    pl = l1->next;
  }
  else
    /* if more than one node in list */
    if (pl->next)
    {
      /* find right node */
      for (l2 = pl, l1 = pl->next; l1; l2 = l1, l1 = l2->next)
        if (l1->fp == pp)
          break;

      /* take node out of list */
      l2->next = l1->next;
    }
    else
      return -1;

  /* if FILE not in list - return error */
  if (l1->fp == pp)
  {
    /* close the (hopefully) popen()ed file */
    fclose (l1->fp);

    /* if pipe was opened to write */
    if (l1->mode[0] == 'w')
    {
      /* dup stdin */
      if ((l1->fd = dup (fileno (stdin))) == EOF)
	retval = -1;
      else
	/* open temp stdin */
	if (!(l1->fp = freopen (l1->temp_name, "rb", stdin)))
	  retval = -1;
	else
	  /* exec cmd */
          if ((retval = system (l1->command)) != EOF)
	  {
            /* reopen stdin */
	    if (dup2 (l1->fd, fileno (stdin)) == EOF)
	      retval = -1;
	  }
      close(l1->fd);
    }
    else
      /* if pipe was opened to read, return the exit status we saved */
      if (l1->mode[0] == 'r')
        retval = l1->exit_status;
      else
        /* invalid mode */
        retval = -1;
  }
  remove (l1->temp_name);       /* remove temporary file */
  free (l1->command);           /* dealloc memory */
  free (l1);                    /* dealloc memory */

  return retval;              /* retval==0 ? OK : ERROR */
}

#endif

/**/

#define EXECF_SPAWN 0
#define EXECF_EXEC 1

static int
convretcode (int rc,char *prog,int fl)
{
    if (rc < 0 && dowarn)
        warn ("Can't %s \"%s\": %s",fl ? "exec" : "spawn",prog,Strerror (errno));
    if (rc > 0)
        return rc <<= 8;
    if (rc < 0)
        return 255 << 8;
    return 0;
}

int
do_aspawn (SV *really,SV **mark,SV **sp)
{
    dTHR;
    int  rc;
    char **a,*tmps,**argv; 

    if (sp<=mark)
        return -1;
    a=argv=(char**) alloca ((sp-mark+3)*sizeof (char*));

    while (++mark <= sp)
        if (*mark)
            *a++ = SvPVx(*mark, na);
        else
            *a++ = "";
    *a = Nullch;

    if (argv[0][0] != '/' && argv[0][0] != '\\'
        && !(argv[0][0] && argv[0][1] == ':'
        && (argv[0][2] == '/' || argv[0][2] != '\\'))
     ) /* will swawnvp use PATH? */
         TAINT_ENV();	/* testing IFS here is overkill, probably */

    if (really && *(tmps = SvPV(really, na)))
        rc=spawnvp (P_WAIT,tmps,argv);
    else
        rc=spawnvp (P_WAIT,argv[0],argv);

    return convretcode (rc,argv[0],EXECF_SPAWN);
}

#define EXTRA "\x00\x00\x00\x00\x00\x00"

int
do_spawn2 (char *cmd,int execf)
{
    char **a,*s,*shell,*metachars;
    int  rc,unixysh;

    if ((shell=getenv("SHELL"))==NULL && (shell=getenv("COMSPEC"))==NULL)
    	shell="c:\\command.com" EXTRA;

    unixysh=_is_unixy_shell (shell);
    metachars=unixysh ? "$&*(){}[]'\";\\?>|<~`\n" EXTRA : "*?[|<>\"\\" EXTRA;

    while (*cmd && isSPACE(*cmd))
	cmd++;

    if (strnEQ (cmd,"/bin/sh",7) && isSPACE (cmd[7]))
        cmd+=5;

    /* save an extra exec if possible */
    /* see if there are shell metacharacters in it */
    if (strstr (cmd,"..."))
        goto doshell;
    if (unixysh)
    {
        if (*cmd=='.' && isSPACE (cmd[1]))
            goto doshell;
        if (strnEQ (cmd,"exec",4) && isSPACE (cmd[4]))
            goto doshell;
        for (s=cmd; *s && isALPHA (*s); s++) ;	/* catch VAR=val gizmo */
            if (*s=='=')
                goto doshell;
    }
    for (s=cmd; *s; s++)
	if (strchr (metachars,*s))
	{
	    if (*s=='\n' && s[1]=='\0')
	    {
		*s='\0';
		break;
	    }
doshell:
	    if (execf==EXECF_EXEC)
                return convretcode (execl (shell,shell,unixysh ? "-c" : "/c",cmd,NULL),cmd,execf);
            return convretcode (system (cmd),cmd,execf);
	}

    New (1303,Argv,(s-cmd)/2+2,char*);
    Cmd=savepvn (cmd,s-cmd);
    a=Argv;
    for (s=Cmd; *s;) {
	while (*s && isSPACE (*s)) s++;
	if (*s)
	    *(a++)=s;
	while (*s && !isSPACE (*s)) s++;
	if (*s)
	    *s++='\0';
    }
    *a=Nullch;
    if (!Argv[0])
        return -1;

    if (execf==EXECF_EXEC)
        rc=execvp (Argv[0],Argv);
    else
        rc=spawnvp (P_WAIT,Argv[0],Argv);
    return convretcode (rc,Argv[0],execf);
}

int
do_spawn (char *cmd)
{
    return do_spawn2 (cmd,EXECF_SPAWN);
}

bool
do_exec (char *cmd)
{
    do_spawn2 (cmd,EXECF_EXEC);
    return FALSE;
}

/**/

struct globinfo
{
    int    fd;
    char   *matches;
    size_t size;
};

#define MAXOPENGLOBS 10

static struct globinfo myglobs[MAXOPENGLOBS];

static struct globinfo *
searchfd (int fd)
{
    int ic;
    for (ic=0; ic<MAXOPENGLOBS; ic++)
        if (myglobs[ic].fd==fd)
            return myglobs+ic;
    return NULL;
}

static int
glob_handler (__FSEXT_Fnumber n,int *rv,va_list args)
{
    unsigned ic;
    struct globinfo *gi;
    switch (n)
    {
        case __FSEXT_open:
        {
            char   *p1,*pattern,*name=va_arg (args,char*);
            STRLEN len;
            glob_t pglob;

            if (strnNE (name,"/dev/dosglob/",13))
                break;
            if ((gi=searchfd (-1)) == NULL)
                break;

            pattern=alloca (strlen (name+=13)+1);
            strcpy (pattern,name);
            if (!_USE_LFN)
                strlwr (pattern);
            ic=pglob.gl_pathc=0;
            pglob.gl_pathv=NULL;
            while (pattern)
            {
                if ((p1=strchr (pattern,' '))!=NULL)
                    *p1=0;
                glob (pattern,ic,0,&pglob);
                ic=GLOB_APPEND;
                if ((pattern=p1)!=NULL)
                    pattern++;
            }
            for (ic=len=0; ic<pglob.gl_pathc; ic++)
                len+=1+strlen (pglob.gl_pathv[ic]);
            if (len)
            {
                if ((gi->matches=p1=(char*) malloc (gi->size=len))==NULL)
                    break;
                for (ic=0; ic<pglob.gl_pathc; ic++)
                {
                    strcpy (p1,pglob.gl_pathv[ic]);
                    p1+=strlen (p1)+1;
                }
            }
            else
            {
                if ((gi->matches=strdup (name))==NULL)
                    break;
                gi->size=strlen (name)+1;
            }
            globfree (&pglob);
            gi->fd=*rv=__FSEXT_alloc_fd (glob_handler);
            return 1;
        }
        case __FSEXT_read:
        {
            int      fd=va_arg (args,int);
            char   *buf=va_arg (args,char*);
            size_t  siz=va_arg (args,size_t);

            if ((gi=searchfd (fd))==NULL)
                break;

            ic=tell (fd);
            if (siz+ic>=gi->size)
                siz=gi->size-ic;
            memcpy (buf,ic+gi->matches,siz);
            lseek (fd,siz,1);
            *rv=siz;
            return 1;
        }
        case __FSEXT_close:
        {
            int fd=va_arg (args,int);

            if ((gi=searchfd (fd))==NULL)
                break;
            free (gi->matches);
            gi->fd=-1;
            break;
        }
        default:
            break;
    }
    return 0;
}

static
XS(dos_GetCwd)
{
    dXSARGS;

    if (items)
        croak ("Usage: Dos::GetCwd()");
    {
        char tmp[PATH_MAX+2];
        ST(0)=sv_newmortal ();
        if (getcwd (tmp,PATH_MAX+1)!=NULL)
            sv_setpv ((SV*)ST(0),tmp);
    }
    XSRETURN (1);
}

static
XS(dos_UseLFN)
{
    dXSARGS;
    XSRETURN_IV (_USE_LFN);
}

void
init_os_extras()
{
    char *file = __FILE__;

    dXSUB_SYS;
    
    newXS ("Dos::GetCwd",dos_GetCwd,file);
    newXS ("Dos::UseLFN",dos_UseLFN,file);

    /* install my File System Extension for globbing */
    __FSEXT_add_open_handler (glob_handler);
    memset (myglobs,-1,sizeof (myglobs));
}

static char *perlprefix;

#define PERL5 "/perl5"

char *djgpp_pathexp (const char *p)
{
    static char expp[PATH_MAX];
    strcpy (expp,perlprefix);
    switch (p[0])
    {
        case 'B':
            strcat (expp,"/bin");
            break;
        case 'S':
            strcat (expp,"/lib" PERL5 "/site");
            break;
        default:
            strcat (expp,"/lib" PERL5);
            break;
    }
    return expp;
}

void
Perl_DJGPP_init (int *argcp,char ***argvp)
{
    char *p;

    perlprefix=strdup (**argvp);
    strlwr (perlprefix);
    if ((p=strrchr (perlprefix,'/'))!=NULL)
    {
        *p=0;
        if (strEQ (p-4,"/bin"))
            p[-4]=0;
    }
    else
        strcpy (perlprefix,"..");
}

