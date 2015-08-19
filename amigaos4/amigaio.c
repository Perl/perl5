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
                value = (I32)do_aexec5(really, MARK, SP, pp, did_pipes);
        }
        else if (SP - MARK != 1)
        {
                value = (I32)do_aexec5(NULL, MARK, SP, pp, did_pipes);
        }
        else
        {
                value = (I32)do_exec3(SvPVx(sv_mortalcopy(*SP), n_a), pp,
                                      did_pipes);
        }

        //    Forbid();
        //    Signal(parent, SIGBREAKF_CTRL_F);

        amigaos_stdio_restore(aTHX_ & store);

        return value;
}
