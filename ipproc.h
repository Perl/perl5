/*

    ipproc.h
    Interface for perl process functions

*/

#ifndef __Inc__IPerlProc___
#define __Inc__IPerlProc___

#ifndef Sighandler_t
typedef Signal_t (*Sighandler_t) _((int));
#endif
#ifndef jmp_buf
#include <setjmp.h>
#endif

class IPerlProc
{
public:
    virtual void Abort(void) = 0;
    virtual void Exit(int status) = 0;
    virtual void _Exit(int status) = 0;
    virtual int Execl(const char *cmdname, const char *arg0, const char *arg1, const char *arg2, const char *arg3) = 0;
    virtual int Execv(const char *cmdname, const char *const *argv) = 0;
    virtual int Execvp(const char *cmdname, const char *const *argv) = 0;
    virtual uid_t Getuid(void) = 0;
    virtual uid_t Geteuid(void) = 0;
    virtual gid_t Getgid(void) = 0;
    virtual gid_t Getegid(void) = 0;
    virtual char *Getlogin(void) = 0;
    virtual int Kill(int pid, int sig) = 0;
    virtual int Killpg(int pid, int sig) = 0;
    virtual int PauseProc(void) = 0;
    virtual PerlIO* Popen(const char *command, const char *mode) = 0;
    virtual int Pclose(PerlIO *stream) = 0;
    virtual int Pipe(int *phandles) = 0;
    virtual int Setuid(uid_t uid) = 0;
    virtual int Setgid(gid_t gid) = 0;
    virtual int Sleep(unsigned int) = 0;
    virtual int Times(struct tms *timebuf) = 0;
    virtual int Wait(int *status) = 0;
    virtual Sighandler_t Signal(int sig, Sighandler_t subcode) = 0;
#ifdef WIN32
    virtual void GetSysMsg(char*& msg, DWORD& dwLen, DWORD dwErr) = 0;
    virtual void FreeBuf(char* msg) = 0;
    virtual BOOL DoCmd(char *cmd) = 0;
    virtual int Spawn(char*cmds) = 0;
    virtual int Spawnvp(int mode, const char *cmdname, const char *const *argv) = 0;
    virtual int ASpawn(void *vreally, void **vmark, void **vsp) = 0;
#endif
};

#endif	/* __Inc__IPerlProc___ */

