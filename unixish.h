
/*
 * The following symbols are defined if your operating system supports
 * functions by that name.  All Unixes I know of support them, thus they
 * are not checked by the configuration script, but are directly defined
 * here.
 */
#define HAS_ALARM
#define HAS_CHOWN
#define HAS_CHROOT
#define HAS_FORK
#define HAS_GETLOGIN
#define HAS_GETPPID
#define HAS_KILL
#define HAS_LINK
#define HAS_PIPE
#define HAS_WAIT
#define HAS_UMASK
#define HAS_PAUSE
/*
 * The following symbols are defined if your operating system supports
 * password and group functions in general.  All Unix systems do.
 */
#ifdef I_GRP
#define HAS_GROUP
#endif
#ifdef I_PWD
#define HAS_PASSWD
#endif

#ifndef SIGABRT
#    define SIGABRT SIGILL
#endif
#ifndef SIGILL
#    define SIGILL 6         /* blech */
#endif
#define ABORT() kill(getpid(),SIGABRT);

