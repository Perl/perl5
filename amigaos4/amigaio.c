/* amigaio.c mixes amigaos and perl APIs,
 * as opposed to amigaos.c which is pure amigaos */

#include "EXTERN.h"
#include "perl.h"

#include "amigaos4/amigaio.h"
#include "amigaos.h"

#ifdef WORD
#  undef WORD
#  define WORD int16
#endif

#include <stdio.h>

#include <exec/semaphores.h>
#include <exec/exectags.h>
#include <proto/exec.h>
#include <proto/dos.h>
#include <dos/dos.h>

void amigaos_stdio_get(pTHX_ StdioStore *store)
{
        store->astdin =
            amigaos_get_file(PerlIO_fileno(IoIFP(GvIO(PL_stdingv))));
        store->astderr =
            amigaos_get_file(PerlIO_fileno(IoIFP(GvIO(PL_stderrgv))));
        store->astdout = amigaos_get_file(
            PerlIO_fileno(IoIFP(GvIO(gv_fetchpv("STDOUT", TRUE, SVt_PVIO)))));
}

void amigaos_stdio_save(pTHX_ StdioStore *store)
{
        amigaos_stdio_get(aTHX_ store);
        store->oldstdin = IDOS->SelectInput(store->astdin);
        store->oldstderr = IDOS->SelectErrorOutput(store->astderr);
        store->oldstdout = IDOS->SelectOutput(store->astdout);
}

void amigaos_stdio_restore(pTHX_ const StdioStore *store)
{
        IDOS->SelectInput(store->oldstdin);
        IDOS->SelectErrorOutput(store->oldstderr);
        IDOS->SelectOutput(store->oldstdout);
}

void amigaos_post_exec(int fd, int do_report)
{
        /* We *must* write something to our pipe or else
         * the other end hangs */
        if (do_report)
        {
                int e = errno;
                PerlLIO_write(fd, (void *)&e, sizeof(e));
                PerlLIO_close(fd);
        }
}

PerlIO *Perl_my_popen(pTHX_ const char *cmd, const char *mode)
{
        PERL_FLUSHALL_FOR_CHILD;
        /* Call system's popen() to get a FILE *, then import it.
         * used 0 for 2nd parameter to PerlIO_importFILE;
         * apparently not used
        */
        //    FILE *f=amigaos_popen(cmd,mode);
        //    fprintf(stderr,"popen returned %d\n",f);
        return PerlIO_importFILE(amigaos_popen(cmd, mode), 0);
        //   return PerlIO_importFILE(f, 0);
}

#ifdef USE_ITHREADS

/* An arbitrary number to start with, should work out what the real max should
 * be */

#ifndef MAX_THREADS
#  define MAX_THREADS 64
#endif

#define REAPED 0
#define ACTIVE 1
#define EXITED -1

struct thread_info
{
        pthread_t ti_pid;
        int ti_children;
        pthread_t ti_parent;
        struct MsgPort *ti_port;
};

static struct thread_info pseudo_children[MAX_THREADS];
static int num_pseudo_children = 0;
static struct SignalSemaphore fork_array_sema;

void amigaos4_init_fork_array()
{
        IExec->InitSemaphore(&fork_array_sema);
        pseudo_children[0].ti_pid = (pthread_t)IExec->FindTask(0);
        pseudo_children[0].ti_parent = -1;
        pseudo_children[0].ti_port =
            (struct MsgPort *)IExec->AllocSysObjectTags(ASOT_PORT, TAG_DONE);
}

void amigaos4_dispose_fork_array()
{
        while (pseudo_children[0].ti_children > 0)
        {
                void *msg;
                IExec->WaitPort(pseudo_children[0].ti_port);
                msg = IExec->GetMsg(pseudo_children[0].ti_port);
                if (msg)
                        IExec->FreeSysObject(ASOT_MESSAGE, msg);
                pseudo_children[0].ti_children--;
        }
        IExec->FreeSysObject(ASOT_PORT, pseudo_children[0].ti_port);
}

struct thread_exit_message
{
        struct Message tem_Message;
        pthread_t tem_pid;
        int tem_status;
};

int getnextchild()
{
        int i;
        for (i = 0; i < MAX_THREADS; i++)
        {
                if (pseudo_children[i].ti_pid == 0)
                        return i;
        }
        return -1;
}

int findparent(pthread_t pid)
{
        int i;
        for (i = 0; i < MAX_THREADS; i++)
        {
                if (pseudo_children[i].ti_pid == pid)
                        return i;
        }
        return -1;
}

struct child_arg
{
        struct Task *ca_parent_task;
        pthread_t ca_parent;
        PerlInterpreter *ca_interp;
};

static THREAD_RET_TYPE amigaos4_start_child(void *arg)
{

        PerlInterpreter *my_perl =
            (PerlInterpreter *)((struct child_arg *)arg)->ca_interp;
        ;

        GV *tmpgv;
        int status;
        int parent;
        int nextchild;
        pthread_t pseudo_id = pthread_self();

#ifdef PERL_SYNC_FORK
        static long sync_fork_id = 0;
        long id = ++sync_fork_id;
#endif

        /* before we do anything set up our process semaphore and add
           a new entry to the pseudochildren */

        /* get next available slot */
        /* should not fail here! */

        IExec->ObtainSemaphore(&fork_array_sema);

        nextchild = getnextchild();

        pseudo_children[nextchild].ti_pid = pseudo_id;
        pseudo_children[nextchild].ti_parent =
            ((struct child_arg *)arg)->ca_parent;
        pseudo_children[nextchild].ti_port =
            (struct MsgPort *)IExec->AllocSysObjectTags(ASOT_PORT, TAG_DONE);

        num_pseudo_children++;
        IExec->ReleaseSemaphore(&fork_array_sema);

        /* We're set up let the parent continue */

        IExec->Signal(((struct child_arg *)arg)->ca_parent_task,
                      SIGBREAKF_CTRL_F);

        PERL_SET_THX(my_perl);
        if ((tmpgv = gv_fetchpv("$", TRUE, SVt_PV)))
        {
                SV *sv = GvSV(tmpgv);
                SvREADONLY_off(sv);
                sv_setiv(sv, (IV)pseudo_id);
                SvREADONLY_on(sv);
        }
        hv_clear(PL_pidstatus);

        /* push a zero on the stack (we are the child) */
        {
                dSP;
                dTARGET;
                PUSHi(0);
                PUTBACK;
        }

        /* continue from next op */
        PL_op = PL_op->op_next;

        {
                dJMPENV;
                volatile int oldscope = PL_scopestack_ix;

        restart:
                JMPENV_PUSH(status);
                switch (status)
                {
                case 0:
                        CALLRUNOPS(aTHX);
                        status = 0;
                        break;
                case 2:
                        while (PL_scopestack_ix > oldscope)
                        {
                                LEAVE;
                        }
                        FREETMPS;
                        PL_curstash = PL_defstash;
                        if (PL_endav && !PL_minus_c)
                                call_list(oldscope, PL_endav);
                        status = STATUS_EXIT;
                        break;
                case 3:
                        if (PL_restartop)
                        {
                                POPSTACK_TO(PL_mainstack);
                                PL_op = PL_restartop;
                                PL_restartop = (OP *)NULL;
                                ;
                                goto restart;
                        }
                        PerlIO_printf(Perl_error_log, "panic: restartop\n");
                        FREETMPS;
                        status = 1;
                        break;
                }
                JMPENV_POP;

                /* XXX hack to avoid perl_destruct() freeing optree */
                PL_main_root = (OP *)NULL;
        }

        {
                do_close(PL_stdingv, FALSE);
                do_close(gv_fetchpv("STDOUT", TRUE, SVt_PVIO),
                         FALSE); /* PL_stdoutgv - ISAGN */
                do_close(PL_stderrgv, FALSE);
        }

        /* destroy everything (waits for any pseudo-forked children) */

        /* wait for any remaining children */

        while (pseudo_children[nextchild].ti_children > 0)
        {
                if (IExec->WaitPort(pseudo_children[nextchild].ti_port))
                {
                        void *msg =
                            IExec->GetMsg(pseudo_children[nextchild].ti_port);
                        IExec->FreeSysObject(ASOT_MESSAGE, msg);
                        pseudo_children[nextchild].ti_children--;
                }
        }
        if (PL_scopestack_ix <= 1)
        {
                perl_destruct(my_perl);
        }
        perl_free(my_perl);

        IExec->ObtainSemaphore(&fork_array_sema);
        parent = findparent(pseudo_children[nextchild].ti_parent);
        pseudo_children[nextchild].ti_pid = 0;
        pseudo_children[nextchild].ti_parent = 0;
        IExec->FreeSysObject(ASOT_PORT, pseudo_children[nextchild].ti_port);
        pseudo_children[nextchild].ti_port = NULL;

        IExec->ReleaseSemaphore(&fork_array_sema);

        {
                if (parent >= 0)
                {
                        struct thread_exit_message *tem =
                            (struct thread_exit_message *)
                                IExec->AllocSysObjectTags(
                                    ASOT_MESSAGE, ASOMSG_Size,
                                    sizeof(struct thread_exit_message),
                                    ASOMSG_Length,
                                    sizeof(struct thread_exit_message));
                        if (tem)
                        {
                                tem->tem_pid = pseudo_id;
                                tem->tem_status = status;
                                IExec->PutMsg(pseudo_children[parent].ti_port,
                                              (struct Message *)tem);
                        }
                }
        }
#ifdef PERL_SYNC_FORK
        return id;
#else
        return (void *)status;
#endif
}

#endif /* USE_ITHREADS */

Pid_t amigaos_fork()
{
        dTHX;
        pthread_t id;
        int handle;
        struct child_arg arg;
        if (num_pseudo_children >= MAX_THREADS)
        {
                errno = EAGAIN;
                return -1;
        }
        arg.ca_interp = perl_clone((PerlInterpreter *)aTHX, CLONEf_COPY_STACKS);
        arg.ca_parent_task = IExec->FindTask(NULL);
        arg.ca_parent =
            pthread_self() ? pthread_self() : (pthread_t)IExec->FindTask(0);

        handle = pthread_create(&id, NULL, amigaos4_start_child, (void *)&arg);
        pseudo_children[findparent(arg.ca_parent)].ti_children++;

        IExec->Wait(SIGBREAKF_CTRL_F);

        PERL_SET_THX(aTHX); /* XXX perl_clone*() set TLS */
        if (handle)
        {
                errno = EAGAIN;
                return -1;
        }
        return id;
}

Pid_t amigaos_waitpid(pTHX_ int optype, Pid_t pid, void *argflags)
{
        int result;
        if (PL_signals & PERL_SIGNALS_UNSAFE_FLAG)
        {
                result = pthread_join(pid, argflags);
        }
        else
        {
                while ((result = pthread_join(pid, argflags)) == -1 &&
                       errno == EINTR)
                {
                        //          PERL_ASYNC_CHECK();
                }
        }
        return result;
}

void amigaos_fork_set_userdata(
    pTHX_ struct UserData *userdata, I32 did_pipes, int pp, SV **sp, SV **mark)
{
        userdata->parent = IExec->FindTask(0);
        userdata->did_pipes = did_pipes;
        userdata->pp = pp;
        userdata->sp = sp;
        userdata->mark = mark;
        userdata->my_perl = aTHX;
}

/* AmigaOS specific versions of #?exec#? solely for use in amigaos_system_child
 */

static void S_exec_failed(pTHX_ const char *cmd, int fd, int do_report)
{
        const int e = errno;
//    PERL_ARGS_ASSERT_EXEC_FAILED;
        if (e)
        {
                if (ckWARN(WARN_EXEC))
                        Perl_warner(aTHX_ packWARN(WARN_EXEC),
                                    "Can't exec \"%s\": %s", cmd, Strerror(e));
        }
        if (do_report)
        {
                /* XXX silently ignore failures */
                PERL_UNUSED_RESULT(PerlLIO_write(fd, (void *)&e, sizeof(int)));
                PerlLIO_close(fd);
        }
}

static I32 S_do_amigaos_exec3(pTHX_ const char *incmd, int fd, int do_report)
{
        dVAR;
        const char **a;
        char *s;
        char *buf;
        char *cmd;
        /* Make a copy so we can change it */
        const Size_t cmdlen = strlen(incmd) + 1;
        I32 result = -1;

        PERL_ARGS_ASSERT_DO_EXEC3;

        Newx(buf, cmdlen, char);
        cmd = buf;
        memcpy(cmd, incmd, cmdlen);

        while (*cmd && isSPACE(*cmd))
                cmd++;

        /* see if there are shell metacharacters in it */

        if (*cmd == '.' && isSPACE(cmd[1]))
                goto doshell;

        if (strnEQ(cmd, "exec", 4) && isSPACE(cmd[4]))
                goto doshell;

        s = cmd;
        while (isWORDCHAR(*s))
                s++; /* catch VAR=val gizmo */
        if (*s == '=')
                goto doshell;

        for (s = cmd; *s; s++)
        {
                if (*s != ' ' && !isALPHA(*s) &&
                    strchr("$&*(){}[]'\";\\|?<>~`\n", *s))
                {
                        if (*s == '\n' && !s[1])
                        {
                                *s = '\0';
                                break;
                        }
                        /* handle the 2>&1 construct at the end */
                        if (*s == '>' && s[1] == '&' && s[2] == '1' &&
                            s > cmd + 1 && s[-1] == '2' && isSPACE(s[-2]) &&
                            (!s[3] || isSPACE(s[3])))
                        {
                                const char *t = s + 3;

                                while (*t && isSPACE(*t))
                                        ++t;
                                if (!*t && (PerlLIO_dup2(1, 2) != -1))
                                {
                                        s[-2] = '\0';
                                        break;
                                }
                        }
                doshell:
                        PERL_FPU_PRE_EXEC
                        result = myexecl(FALSE, PL_sh_path, "sh", "-c", cmd,
                                         (char *)NULL);
                        PERL_FPU_POST_EXEC
                        S_exec_failed(aTHX_ PL_sh_path, fd, do_report);
                        amigaos_post_exec(fd, do_report);
                        Safefree(buf);
                        return result;
                }
        }

        Newx(PL_Argv, (s - cmd) / 2 + 2, const char *);
        PL_Cmd = savepvn(cmd, s - cmd);
        a = PL_Argv;
        for (s = PL_Cmd; *s;)
        {
                while (isSPACE(*s))
                        s++;
                if (*s)
                        *(a++) = s;
                while (*s && !isSPACE(*s))
                        s++;
                if (*s)
                        *s++ = '\0';
        }
        *a = NULL;
        if (PL_Argv[0])
        {
                PERL_FPU_PRE_EXEC
                result = myexecvp(FALSE, PL_Argv[0], EXEC_ARGV_CAST(PL_Argv));
                PERL_FPU_POST_EXEC
                if (errno == ENOEXEC)
                { /* for system V NIH syndrome */
                        do_execfree();
                        goto doshell;
                }
                S_exec_failed(aTHX_ PL_Argv[0], fd, do_report);
                amigaos_post_exec(fd, do_report);
        }
        do_execfree();
        Safefree(buf);
        return result;
}

I32 S_do_amigaos_aexec5(
    pTHX_ SV *really, SV **mark, SV **sp, int fd, int do_report)
{
	dVAR;
	I32 result = -1;
	PERL_ARGS_ASSERT_DO_AEXEC5;
	if (sp > mark)
	{
		const char **a;
		const char *tmps = NULL;
		Newx(PL_Argv, sp - mark + 1, const char *);
		a = PL_Argv;

		while (++mark <= sp)
		{
			if (*mark)
				*a++ = SvPV_nolen_const(*mark);
			else
				*a++ = "";
		}
		*a = NULL;
		if (really)
			tmps = SvPV_nolen_const(really);
		if ((!really && *PL_Argv[0] != '/') ||
		        (really && *tmps != '/')) /* will execvp use PATH? */
			TAINT_ENV(); /* testing IFS here is overkill, probably
                                        */
                PERL_FPU_PRE_EXEC
                if (really && *tmps)
                {
                        result = myexecvp(FALSE, tmps, EXEC_ARGV_CAST(PL_Argv));
                }
                else
                {
                        result = myexecvp(FALSE, PL_Argv[0],
                                          EXEC_ARGV_CAST(PL_Argv));
                }
                PERL_FPU_POST_EXEC
                S_exec_failed(aTHX_(really ? tmps : PL_Argv[0]), fd, do_report);
        }
        amigaos_post_exec(fd, do_report);
        do_execfree();
        return result;
}

void *amigaos_system_child(void *userdata)
{
        struct Task *parent;
        I32 did_pipes;
        int pp;
        I32 value;
        STRLEN n_a;
        /* these next are declared by macros else where but I may be
         * passing modified values here so declare them explictly but
         * still referred to by macro below */

        register SV **sp;
        register SV **mark;
        register PerlInterpreter *my_perl;

        StdioStore store;

        struct UserData *ud = (struct UserData *)userdata;

        did_pipes = ud->did_pipes;
        parent = ud->parent;
        pp = ud->pp;
        SP = ud->sp;
        MARK = ud->mark;
        my_perl = ud->my_perl;
        PERL_SET_THX(my_perl);

        amigaos_stdio_save(aTHX_ & store);

        if (did_pipes)
        {
                //    PerlLIO_close(pp[0]);
        }
        if (PL_op->op_flags & OPf_STACKED)
        {
                SV *really = *++MARK;
                value = (I32)S_do_amigaos_aexec5(aTHX_ really, MARK, SP, pp,
                                                 did_pipes);
        }
        else if (SP - MARK != 1)
        {
                value = (I32)S_do_amigaos_aexec5(aTHX_ NULL, MARK, SP, pp,
                                                 did_pipes);
        }
        else
        {
                value = (I32)S_do_amigaos_exec3(
                    aTHX_ SvPVx(sv_mortalcopy(*SP), n_a), pp, did_pipes);
        }

        //    Forbid();
        //    Signal(parent, SIGBREAKF_CTRL_F);

        amigaos_stdio_restore(aTHX_ & store);

        return value;
}

static BOOL contains_whitespace(char *string)
{

        if (string)
        {

                if (strchr(string, ' '))
                        return TRUE;
                if (strchr(string, '\t'))
                        return TRUE;
                if (strchr(string, '\n'))
                        return TRUE;
                if (strchr(string, 0xA0))
                        return TRUE;
                if (strchr(string, '"'))
                        return TRUE;
        }
        return FALSE;
}

static int no_of_escapes(char *string)
{
        int cnt = 0;
        char *p;
        for (p = string; p < string + strlen(string); p++)
        {
                if (*p == '"')
                        cnt++;
                if (*p == '*')
                        cnt++;
                if (*p == '\n')
                        cnt++;
                if (*p == '\t')
                        cnt++;
        }
        return cnt;
}

struct command_data
{
        STRPTR args;
        BPTR seglist;
        struct Task *parent;
};

#undef fopen
#undef fgetc
#undef fgets
#undef fclose

#define __USE_RUNCOMMAND__

int myexecve(bool isperlthread,
             const char *filename,
             char *argv[],
             char *envp[])
{
        FILE *fh;
        char buffer[1000];
        int size = 0;
        char **cur;
        char *interpreter = 0;
        char *interpreter_args = 0;
        char *full = 0;
        char *filename_conv = 0;
        char *interpreter_conv = 0;
        //        char *tmp = 0;
        char *fname;
        //        int tmpint;
        //        struct Task *thisTask = IExec->FindTask(0);
        int result = -1;

        StdioStore store;

        pTHX = NULL;

        if (isperlthread)
        {
                aTHX = PERL_GET_THX;
                /* Save away our stdio */
                amigaos_stdio_save(aTHX_ & store);
        }

        // adebug("%s %ld %s\n",__FUNCTION__,__LINE__,filename?filename:"NULL");

        /* Calculate the size of filename and all args, including spaces and
         * quotes */
        size = 0; // strlen(filename) + 1;
        for (cur = (char **)argv /* +1 */; *cur; cur++)
        {
                size +=
                    strlen(*cur) + 1 +
                    (contains_whitespace(*cur) ? (2 + no_of_escapes(*cur)) : 0);
        }
        /* Check if it's a script file */

        fh = fopen(filename, "r");
        if (fh)
        {
                if (fgetc(fh) == '#' && fgetc(fh) == '!')
                {
                        char *p;
                        char *q;
                        fgets(buffer, 999, fh);
                        p = buffer;
                        while (*p == ' ' || *p == '\t')
                                p++;
                        if (buffer[strlen(buffer) - 1] == '\n')
                                buffer[strlen(buffer) - 1] = '\0';
                        if ((q = strchr(p, ' ')))
                        {
                                *q++ = '\0';
                                if (*q != '\0')
                                {
                                        interpreter_args = mystrdup(q);
                                }
                        }
                        else
                                interpreter_args = mystrdup("");

                        interpreter = mystrdup(p);
                        size += strlen(interpreter) + 1;
                        size += strlen(interpreter_args) + 1;
                }

                fclose(fh);
        }
        else
        {
                /* We couldn't open this why not? */
                if (errno == ENOENT)
                {
                        /* file didn't exist! */
                        goto out;
                }
        }

        /* Allocate the command line */
        filename_conv = convert_path_u2a(filename);

        if (filename_conv)
                size += strlen(filename_conv);
        size += 1;
        full = (char *)IExec->AllocVec(size + 10, MEMF_ANY | MEMF_CLEAR);
        if (full)
        {
                if (interpreter)
                {
                        interpreter_conv = convert_path_u2a(interpreter);
#if !defined(__USE_RUNCOMMAND__)
#warning(using system!)
                        sprintf(full, "%s %s %s ", interpreter_conv,
                                interpreter_args, filename_conv);
#else
                        sprintf(full, "%s %s ", interpreter_args,
                                filename_conv);
#endif
                        IExec->FreeVec(interpreter);
                        IExec->FreeVec(interpreter_args);

                        if (filename_conv)
                                IExec->FreeVec(filename_conv);
                        fname = mystrdup(interpreter_conv);

                        if (interpreter_conv)
                                IExec->FreeVec(interpreter_conv);
                }
                else
                {
#ifndef __USE_RUNCOMMAND__
                        sprintf(full, "%s ", filename_conv);
#else
                        sprintf(full, "");
#endif
                        fname = mystrdup(filename_conv);
                        if (filename_conv)
                                IExec->FreeVec(filename_conv);
                }

                for (cur = (char **)(argv + 1); *cur != 0; cur++)
                {
                        if (contains_whitespace(*cur))
                        {
                                int esc = no_of_escapes(*cur);

                                if (esc > 0)
                                {
                                        char *buff = IExec->AllocVec(
                                            strlen(*cur) + 4 + esc,
                                            MEMF_ANY | MEMF_CLEAR);
                                        char *p = *cur;
                                        char *q = buff;

                                        *q++ = '"';
                                        while (*p != '\0')
                                        {

                                                if (*p == '\n')
                                                {
                                                        *q++ = '*';
                                                        *q++ = 'N';
                                                        p++;
                                                        continue;
                                                }
                                                else if (*p == '"')
                                                {
                                                        *q++ = '*';
                                                        *q++ = '"';
                                                        p++;
                                                        continue;
                                                }
                                                else if (*p == '*')
                                                {
                                                        *q++ = '*';
                                                }
                                                *q++ = *p++;
                                        }
                                        *q++ = '"';
                                        *q++ = ' ';
                                        *q = '\0';
                                        strcat(full, buff);
                                        IExec->FreeVec(buff);
                                }
                                else
                                {
                                        strcat(full, "\"");
                                        strcat(full, *cur);
                                        strcat(full, "\" ");
                                }
                        }
                        else
                        {
                                strcat(full, *cur);
                                strcat(full, " ");
                        }
                }
                strcat(full, "\n");

//            if(envp)
//                 createvars(envp);

#ifndef __USE_RUNCOMMAND__
                result = IDOS->SystemTags(
                    full, SYS_UserShell, TRUE, NP_StackSize,
                    ((struct Process *)thisTask)->pr_StackSize, SYS_Input,
                    ((struct Process *)thisTask)->pr_CIS, SYS_Output,
                    ((struct Process *)thisTask)->pr_COS, SYS_Error,
                    ((struct Process *)thisTask)->pr_CES, TAG_DONE);
#else

                if (fname)
                {
                        BPTR seglist = IDOS->LoadSeg(fname);
                        if (seglist)
                        {
                                /* check if we have an executable! */
                                struct PseudoSegList *ps = NULL;
                                if (!IDOS->GetSegListInfoTags(
                                        seglist, GSLI_Native, &ps, TAG_DONE))
                                {
                                        IDOS->GetSegListInfoTags(
                                            seglist, GSLI_68KPS, &ps, TAG_DONE);
                                }
                                if (ps != NULL)
                                {
                                        //                    adebug("%s %ld %s
                                        //                    %s\n",__FUNCTION__,__LINE__,fname,full);
                                        IDOS->SetCliProgramName(fname);
                                        //                        result=RunCommand(seglist,8*1024,full,strlen(full));
                                        //                        result=myruncommand(seglist,8*1024,full,strlen(full),envp);
                                        result = myruncommand(seglist, 8 * 1024,
                                                              full, -1, envp);
                                        errno = 0;
                                }
                                else
                                {
                                        errno = ENOEXEC;
                                }
                                IDOS->UnLoadSeg(seglist);
                        }
                        else
                        {
                                errno = ENOEXEC;
                        }
                        IExec->FreeVec(fname);
                }

#endif /* USE_RUNCOMMAND */

                IExec->FreeVec(full);
                if (errno == ENOEXEC)
                {
                        result = -1;
                }
                goto out;
        }

        if (interpreter)
                IExec->FreeVec(interpreter);
        if (filename_conv)
                IExec->FreeVec(filename_conv);

        errno = ENOMEM;

out:
        if (isperlthread)
        {
                amigaos_stdio_restore(aTHX_ & store);
                STATUS_NATIVE_CHILD_SET(result);
                PL_exit_flags |= PERL_EXIT_EXPECTED;
                if (result != -1)
                        my_exit(result);
        }
        return (result);
}
