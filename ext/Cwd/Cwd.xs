#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Originally written in Perl by John Bazik; rewritten in C by Ben Sugars.
 * Comments from the orignal:
 *     This is a faster version of getcwd.  It's also more dangerous
 *     because you might chdir out of a directory that you can't chdir
 *     back into. */
char *
_cwdxs_fastcwd(void)
{
/* XXX Should we just use getcwd(3) if available? */
  struct stat statbuf;
  int orig_cdev, orig_cino, cdev, cino, odev, oino, tdev, tino;
  int i = 0, j = 0, k = 0, ndirs = 16, pathlen = 0, namelen;
  DIR *dir;
  Direntry_t *dp;
  char **names, *path;

  Newz(0, names, ndirs, char*);

  if (PerlLIO_lstat(".", &statbuf) < 0) {
    Safefree(names);
    return FALSE;
  }
  orig_cdev = statbuf.st_dev;
  orig_cino = statbuf.st_ino;
  cdev = orig_cdev;
  cino = orig_cino;
  for (;;) {
    odev = cdev;
    oino = cino;

    if (PerlDir_chdir("..") < 0) {
      Safefree(names);
      return FALSE;
    }
    if (PerlLIO_stat(".", &statbuf) < 0) {
      Safefree(names);
      return FALSE;
    }
    cdev = statbuf.st_dev;
    cino = statbuf.st_ino;
    if (odev == cdev && oino == cino)
      break;

    if (!(dir = PerlDir_open("."))) {
      Safefree(names);
      return FALSE;
    }

    while ((dp = PerlDir_read(dir)) != NULL) {
      if (PerlLIO_lstat(dp->d_name, &statbuf) < 0) {
	Safefree(names);
	return FALSE;
      }
      if (strEQ(dp->d_name, "."))
	continue;
      if (strEQ(dp->d_name, ".."))
	continue;
      tdev = statbuf.st_dev;
      tino = statbuf.st_ino;
      if (tino == oino && tdev == odev)
	break;
    }

    if (!dp) {
      Safefree(names);
      return FALSE;
    }

    if (i >= ndirs) {
      ndirs += 16;
      Renew(names, ndirs, char*);
    }
#ifdef DIRNAMLEN
    namelen = dp->d_namlen;
#else
    namelen = strlen(dp->d_name);
#endif
    Newz(0, *(names + i), namelen + 1, char);
    Copy(dp->d_name, *(names + i), namelen, char);
    *(names[i] + namelen) = '\0';
    pathlen += (namelen + 1);
    ++i;

#ifdef VOID_CLOSEDIR
    PerlDir_close(dir);
#else
    if (PerlDir_close(dir) < 0) {
      Safefree(names);
      return FALSE;
    }
#endif
  }

  Newz(0, path, pathlen + 1, char);
  for (j = i - 1; j >= 0; j--) {
    *(path + k) = '/';
    Copy(names[j], path + k + 1, strlen(names[j]) + 1, char);
    k = k + strlen(names[j]) + 1;
    Safefree(names[j]);
  }

  if (PerlDir_chdir(path) < 0) {
    Safefree(names);
    Safefree(path);
    return FALSE;
  }
  if (PerlLIO_stat(".", &statbuf) < 0) {
    Safefree(names);
    Safefree(path);
    return FALSE;
  }
  cdev = statbuf.st_dev;
  cino = statbuf.st_ino;
  if (cdev != orig_cdev || cino != orig_cino)
    Perl_croak(aTHX_ "Unstable directory path, current directory changed unexpectedly");

  Safefree(names);
  return(path);
}

char *
_cwdxs_abs_path(char *start)
{
  DIR *parent;
  Direntry_t *dp;
  char dotdots[MAXPATHLEN] = { 0 };
  char dir[MAXPATHLEN]     = { 0 };
  char name[MAXPATHLEN]    = { 0 };
  char *cwd;
  int namelen;
  struct stat cst, pst, tst;

  if (PerlLIO_stat(start, &cst) < 0) {
    warn("abs_path: stat(\"%s\"): %s", start, Strerror(errno));
    return FALSE;
  }

  Newz(0, cwd, MAXPATHLEN, char);
  Copy(start, dotdots, strlen(start), char);

  for (;;) {
    strcat(dotdots, "/..");
    StructCopy(&cst, &pst, struct stat);

    if (PerlLIO_stat(dotdots, &cst) < 0) {
      Safefree(cwd);
      warn("abs_path: stat(\"%s\"): %s", dotdots, Strerror(errno));
      return FALSE;
    }
    
    if (pst.st_dev == cst.st_dev && pst.st_ino == cst.st_ino) {
      /* We've reached the root: previous is same as current */
      break;
    } else {
      STRLEN dotdotslen = strlen(dotdots);

      /* Scan through the dir looking for name of previous */
      if (!(parent = PerlDir_open(dotdots))) {
        Safefree(cwd);
        warn("abs_path: opendir(\"%s\"): %s", dotdots, Strerror(errno));
        return FALSE;
      }
    
      SETERRNO(0,SS$_NORMAL); /* for readdir() */
      while ((dp = PerlDir_read(parent)) != NULL) {
        if (strEQ(dp->d_name, "."))
          continue;
        if (strEQ(dp->d_name, ".."))
          continue;
        
        Copy(dotdots, name, dotdotslen, char);
        name[dotdotslen] = '/';
#ifdef DIRNAMLEN
	namelen = dp->d_namlen;
#else
	namelen = strlen(dp->d_name);
#endif
        Copy(dp->d_name, name + dotdotslen + 1, namelen, char);
	name[dotdotslen + 1 + namelen] = 0;
        
        if (PerlLIO_lstat(name, &tst) < 0) {
          Safefree(cwd);
          PerlDir_close(parent);
          warn("abs_path: lstat(\"%s\"): %s", name, Strerror(errno));
          return FALSE;
        }
        
        if (tst.st_dev == pst.st_dev && tst.st_ino == pst.st_ino)
          break;

	SETERRNO(0,SS$_NORMAL); /* for readdir() */
      }
      

      if (!dp && errno) {
        warn("abs_path: readdir(\"%s\"): %s", dotdots, Strerror(errno));
        Safefree(cwd);
        return FALSE;
      }

      Move(cwd, cwd + namelen + 1, strlen(cwd), char);
      Copy(dp->d_name, cwd + 1, namelen, char);
#ifdef VOID_CLOSEDIR
      PerlDir_close(parent);
#else
      if (PerlDir_close(parent) < 0) {
        warn("abs_path: closedir(\"%s\"): %s", dotdots, Strerror(errno));
        Safefree(cwd);
        return FALSE;
      }
#endif
      *cwd = '/';
    }
  }

  return cwd;
}
  

MODULE = Cwd		PACKAGE = Cwd

PROTOTYPES: ENABLE

char *
_fastcwd()
PPCODE:
    char * buf;
    buf = _cwdxs_fastcwd();
    if (buf) {
        PUSHs(sv_2mortal(newSVpv(buf, 0)));
        Safefree(buf);
    }
    else
	XSRETURN_UNDEF;

char *
_abs_path(start = ".")
    char * start
PREINIT:
    char * buf;
PPCODE:
    buf = _cwdxs_abs_path(start);
    if (buf) {
        PUSHs(sv_2mortal(newSVpv(buf, 0)));
        Safefree(buf);
    }
    else
	XSRETURN_UNDEF;
