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

    if (PerlDir_close(dir) < 0) {
      Safefree(names);
      return FALSE;
    }
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
