#ifndef H_PERLDIR
#define H_PERLDIR 1

#ifdef PERL_OBJECT
#else
#define PerlDir_mkdir(name, mode) Mkdir((name), (mode))
#define PerlDir_chdir(name) chdir((name))
#define PerlDir_rmdir(name) rmdir((name))
#define PerlDir_close(dir) closedir((dir))
#define PerlDir_open(name) opendir((name))
#define PerlDir_read(dir) readdir((dir))
#define PerlDir_rewind(dir) rewinddir((dir))
#define PerlDir_seek(dir, loc) seekdir((dir), (loc))
#define PerlDir_tell(dir) telldir((dir))
#endif	/* PERL_OBJECT */

#endif /* Include guard */

