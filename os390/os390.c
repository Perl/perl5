#include <string.h>
#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/ps.h>
#include <unistd.h>
#include <stdarg.h>
#include <varargs.h>
#include <limits.h>
#include <_Nascii.h>
#include <fcntl.h>
#include <libgen.h>
#include <termios.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

void
zos_copytags_fd(pTHX_ CV *cv)
{
  dXSARGS;
  int ret = 0;

  if (items != 2)
    Perl_croak(aTHX_ "Usage: ZOS::Filespec::copytags_fd(f1, f2])");

  int from_fd = (int)SvIV(ST(0));
  int to_fd = (int)SvIV(ST(1));

  char path[_XOPEN_PATH_MAX] = {0};
  int rc = w_ioctl(from_fd, _IOCC_GPN, _XOPEN_PATH_MAX, path);
  if (rc == 0) {
    __e2a_l(path, _XOPEN_PATH_MAX);
  }

  struct stat src_statsbuf;
  if (stat(path, &src_statsbuf)) {
    ret = -1;
  }
  if (ret != -1) {
    ret = __setfdccsid(to_fd,  (src_statsbuf.st_tag.ft_txtflag << 16) | src_statsbuf.st_tag.ft_ccsid);
  }

  XSRETURN_IV(ret);
}

void
init_os_extras(void)
{
  dTHX;
  char* file = __FILE__;

  newXSproto("ZOS::Filespec::copytags_fd",zos_copytags_fd,file,"$;$");

  return;
}
