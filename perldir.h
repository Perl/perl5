#ifndef H_PERLDIR
#define H_PERLDIR 1

#ifdef PERL_OBJECT

#include "ipdir.h"

#define PerlDir_mkdir(name, mode) piDir->Makedir((name), (mode), ErrorNo())
#define PerlDir_chdir(name) piDir->Chdir((name), ErrorNo())
#define PerlDir_rmdir(name) piDir->Rmdir((name), ErrorNo())
#define PerlDir_close(dir) piDir->Close((dir), ErrorNo())
#define PerlDir_open(name) piDir->Open((name), ErrorNo())
#define PerlDir_read(dir) piDir->Read((dir), ErrorNo())
#define PerlDir_rewind(dir) piDir->Rewind((dir), ErrorNo())
#define PerlDir_seek(dir, loc) piDir->Seek((dir), (loc), ErrorNo())
#define PerlDir_tell(dir) piDir->Tell((dir), ErrorNo())
#else
#define PerlDir_mkdir(name, mode) Mkdir((name), (mode))
#ifdef VMS
#  define PerlDir_chdir(name) chdir(((name) && *(name)) ? (name) : "SYS$LOGIN")
#else 
#  define PerlDir_chdir(name) chdir((name))
#endif
#define PerlDir_rmdir(name) rmdir((name))
#define PerlDir_close(dir) closedir((dir))
#define PerlDir_open(name) opendir((name))
#define PerlDir_read(dir) readdir((dir))
#define PerlDir_rewind(dir) rewinddir((dir))
#define PerlDir_seek(dir, loc) seekdir((dir), (loc))
#define PerlDir_tell(dir) telldir((dir))
#endif	/* PERL_OBJECT */

#endif /* Include guard */

