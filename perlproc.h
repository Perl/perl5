#ifndef H_PERLPROC
#define H_PERLPROC 1

#ifdef PERL_OBJECT
#else
#define PerlProc_abort() abort()
#define PerlProc_exit(s) exit((s))
#define PerlProc__exit(s) _exit((s))
#define PerlProc_execl(c, w, x, y, z) execl((c), (w), (x), (y), (z))
#define PerlProc_execv(c, a) execv((c), (a))
#define PerlProc_execvp(c, a) execvp((c), (a))
#define PerlProc_kill(i, a) kill((i), (a))
#define PerlProc_killpg(i, a) killpg((i), (a))
#define PerlProc_popen(c, m) my_popen((c), (m))
#define PerlProc_pclose(f) my_pclose((f))
#define PerlProc_pipe(fd) pipe((fd))
#define PerlProc_setjmp(b, n) Sigsetjmp((b), (n))
#define PerlProc_longjmp(b, n) Siglongjmp((b), (n))
#define PerlProc_signal(n, h) signal((n), (h))
#endif	/* PERL_OBJECT */

#endif /* Include guard */
