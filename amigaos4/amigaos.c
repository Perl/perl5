/* amigaos.c uses only amigaos APIs,
 * as opposed to amigaio.c which mixes amigaos and perl APIs */

#include <string.h>

#include <sys/stat.h>
#include <unistd.h>
#include <assert.h>

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#if defined(__CLIB2__)
#  include <dos.h>
#endif
#if defined(__NEWLIB__)
#  include <amiga_platform.h>
#endif
#include <fcntl.h>
#include <ctype.h>
#include <stdarg.h>
#include <stdbool.h>
#undef WORD
#define WORD int16

#include <dos/dos.h>
#include <proto/dos.h>
#include <proto/exec.h>
#include <proto/utility.h>

#include "amigaos.h"

struct UtilityIFace *IUtility = NULL;

/***************************************************************************/

struct Interface *OpenInterface(CONST_STRPTR libname, uint32 libver)
{
        struct Library *base = IExec->OpenLibrary(libname, libver);
        struct Interface *iface = IExec->GetInterface(base, "main", 1, NULL);
        if (iface == NULL)
        {
                // We should probably post some kind of error message here.

                IExec->CloseLibrary(base);
        }

        return iface;
}

/***************************************************************************/

void CloseInterface(struct Interface *iface)
{
        if (iface != NULL)
        {
                struct Library *base = iface->Data.LibBase;
                IExec->DropInterface(iface);
                IExec->CloseLibrary(base);
        }
}

BOOL __unlink_retries = FALSE;

void ___makeenviron() __attribute__((constructor));
void ___freeenviron() __attribute__((destructor));

void ___openinterfaces() __attribute__((constructor));
void ___closeinterfaces() __attribute__((destructor));

void ___openinterfaces()
{
        if (!IDOS)
                IDOS = (struct DOSIFace *)OpenInterface("dos.library", 53);
        if (!IUtility)
                IUtility =
                    (struct UtilityIFace *)OpenInterface("utility.library", 53);
}

void ___closeinterfaces()
{
        CloseInterface((struct Interface *)IDOS);
        CloseInterface((struct Interface *)IUtility);
}
int VARARGS68K araddebug(UBYTE *fmt, ...);
int VARARGS68K adebug(UBYTE *fmt, ...);

#define __USE_RUNCOMMAND__

char **myenviron = NULL;
char **origenviron = NULL;

static void createvars(char **envp);

struct args
{
        BPTR seglist;
        int stack;
        char *command;
        int length;
        int result;
        char **envp;
};

int __myrc(char *arg)
{
        struct Task *thisTask = IExec->FindTask(0);
        struct args *myargs = (struct args *)thisTask->tc_UserData;
        if (myargs->envp)
                createvars(myargs->envp);
        // adebug("%s %ld %s \n",__FUNCTION__,__LINE__,myargs->command);
        myargs->result = IDOS->RunCommand(myargs->seglist, myargs->stack,
                                          myargs->command, myargs->length);
        return 0;
}

int32 myruncommand(
    BPTR seglist, int stack, char *command, int length, char **envp)
{
        struct args myargs;
        struct Task *thisTask = IExec->FindTask(0);
        struct Process *proc;

        // adebug("%s %ld  %s\n",__FUNCTION__,__LINE__,command?command:"NULL");

        myargs.seglist = seglist;
        myargs.stack = stack;
        myargs.command = command;
        myargs.length = length;
        myargs.result = -1;
        myargs.envp = envp;

        if ((proc = IDOS->CreateNewProcTags(
                 NP_Entry, __myrc, NP_Child, TRUE, NP_Input, IDOS->Input(),
                 NP_Output, IDOS->Output(), NP_Error, IDOS->ErrorOutput(),
                 NP_CloseInput, FALSE, NP_CloseOutput, FALSE, NP_CloseError,
                 FALSE, NP_CopyVars, FALSE,

                 //           NP_StackSize,           ((struct Process
                 //           *)myargs.parent)->pr_StackSize,
                 NP_Cli, TRUE, NP_UserData, (int)&myargs,
                 NP_NotifyOnDeathSigTask, thisTask, TAG_DONE)))

        {
                IExec->Wait(SIGF_CHILD);
        }
        return myargs.result;
}

char *mystrdup(const char *s)
{
        char *result = NULL;
        size_t size;

        size = strlen(s) + 1;

        if ((result = (char *)IExec->AllocVec(size, MEMF_ANY)))
        {
                memmove(result, s, size);
        }
        return result;
}

static int pipenum = 0;

int pipe(int filedes[2])
{
        char pipe_name[1024];

//   adebug("%s %ld \n",__FUNCTION__,__LINE__);
#ifdef USE_TEMPFILES
        sprintf(pipe_name, "/T/%x.%08lx", pipenum++, IUtility->GetUniqueID());
#else
        sprintf(pipe_name, "/PIPE/%x%08lx/4096/0", pipenum++,
                IUtility->GetUniqueID());
#endif

        /*      printf("pipe: %s \n", pipe_name);*/

        filedes[1] = open(pipe_name, O_WRONLY | O_CREAT);
        filedes[0] = open(pipe_name, O_RDONLY);
        if (filedes[0] == -1 || filedes[1] == -1)
        {
                if (filedes[0] != -1)
                        close(filedes[0]);
                if (filedes[1] != -1)
                        close(filedes[1]);
                return -1;
        }
        /*      printf("filedes %d %d\n", filedes[0],
         * filedes[1]);fflush(stdout);*/

        return 0;
}

int fork(void)
{
        fprintf(stderr, "Can not bloody fork\n");
        errno = ENOMEM;
        return -1;
}

int wait(int *status)
{
        fprintf(stderr, "No wait try waitpid instead\n");
        errno = ECHILD;
        return -1;
}

char *convert_path_a2u(const char *filename)
{
        struct NameTranslationInfo nti;

        if (!filename)
        {
                return 0;
        }

        __translate_amiga_to_unix_path_name(&filename, &nti);

        return mystrdup(filename);
}
char *convert_path_u2a(const char *filename)
{
        struct NameTranslationInfo nti;

        if (!filename)
        {
                return 0;
        }

        if (strcmp(filename, "/dev/tty") == 0)
        {
                return mystrdup("CONSOLE:");
                ;
        }

        __translate_unix_to_amiga_path_name(&filename, &nti);

        return mystrdup(filename);
}

static struct SignalSemaphore environ_sema;

void amigaos4_init_environ_sema() { IExec->InitSemaphore(&environ_sema); }

void amigaos4_obtain_environ() { IExec->ObtainSemaphore(&environ_sema); }

void amigaos4_release_environ() { IExec->ReleaseSemaphore(&environ_sema); }

static void createvars(char **envp)
{
        if (envp)
        {
                /* Set a local var to indicate to any subsequent sh that it is
                * not
                * the top level shell and so should only inherit local amigaos
                * vars */
                IDOS->SetVar("ABCSH_IMPORT_LOCAL", "TRUE", 5, GVF_LOCAL_ONLY);

                amigaos4_obtain_environ();

                envp = myenviron;

                while ((envp != NULL) && (*envp != NULL))
                {
                        int len;
                        char *var;
                        char *val;
                        if ((len = strlen(*envp)))
                        {
                                if ((var = (char *)IExec->AllocVec(
                                         len + 1, MEMF_ANY | MEMF_CLEAR)))
                                {
                                        strcpy(var, *envp);

                                        val = strchr(var, '=');
                                        if (val)
                                        {
                                                *val++ = '\0';
                                                if (*val)
                                                {
                                                        IDOS->SetVar(
                                                            var, val,
                                                            strlen(val) + 1,
                                                            GVF_LOCAL_ONLY);
                                                }
                                        }
                                        IExec->FreeVec(var);
                                }
                        }
                        envp++;
                }
                amigaos4_release_environ();
        }
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

int myexecvp(bool isperlthread, const char *filename, char *argv[])
{
        //	adebug("%s %ld
        //%s\n",__FUNCTION__,__LINE__,filename?filename:"NULL");
        /* if there's a slash or a colon consider filename a path and skip
         * search */
        int res;
        if ((strchr(filename, '/') == NULL) && (strchr(filename, ':') == NULL))
        {
                char *path;
                char *name;
                char *pathpart;
                char *p;
                size_t len;
                struct stat st;

                if (!(path = getenv("PATH")))
                {
                        path = ".:/bin:/usr/bin:/c";
                }

                len = strlen(filename) + 1;
                name = (char *)alloca(strlen(path) + len);
                pathpart = (char *)alloca(strlen(path) + 1);
                p = path;
                do
                {
                        path = p;

                        if (!(p = strchr(path, ':')))
                        {
                                p = strchr(path, '\0');
                        }

                        memcpy(pathpart, path, p - path);
                        pathpart[p - path] = '\0';
                        if (!(strlen(pathpart) == 0))
                        {
                                sprintf(name, "%s/%s", pathpart, filename);
                        }
                        else
                                sprintf(name, "%s", filename);

                        if ((stat(name, &st) == 0) && (S_ISREG(st.st_mode)))
                        {
                                /* we stated it and it's a regular file */
                                /* let's boogie! */
                                filename = name;
                                break;
                        }

                } while (*p++ != '\0');
        }
        res = myexecve(isperlthread, filename, argv, myenviron);
        return res;
}

int myexecv(bool isperlthread, const char *path, char *argv[])
{
        return myexecve(isperlthread, path, argv, myenviron);
}

int myexecl(bool isperlthread, const char *path, ...)
{
        va_list va;
        char *argv[1024]; /* 1024 enough? let's hope so! */
        int i = 0;
        // adebug("%s %ld\n",__FUNCTION__,__LINE__);

        va_start(va, path);
        i = 0;

        do
        {
                argv[i] = va_arg(va, char *);
        } while (argv[i++] != NULL);

        va_end(va);
        return myexecve(isperlthread, path, argv, myenviron);
}

#if 0

int myexecve(const char *filename, char *argv[], char *envp[])
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

		dTHX;
		if(aTHX) // I hope this is NULL when not on a interpreteer thread nor to level.
		{
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

    amigaos_stdio_restore(aTHX_ &store);
    STATUS_NATIVE_CHILD_SET(result);
    PL_exit_flags |= PERL_EXIT_EXPECTED;
    if (result != -1) my_exit(result);

        return(result);
}

#endif

int pause(void)
{
        fprintf(stderr, "Pause not implemented\n");

        errno = EINTR;
        return -1;
}

uint32 size_env(struct Hook *hook, APTR userdata, struct ScanVarsMsg *message)
{
        if (strlen(message->sv_GDir) <= 4)
        {
                hook->h_Data = (APTR)(((uint32)hook->h_Data) + 1);
        }
        return 0;
}

uint32 copy_env(struct Hook *hook, APTR userdata, struct ScanVarsMsg *message)
{
        if (strlen(message->sv_GDir) <= 4)
        {
                char **env = (char **)hook->h_Data;
                uint32 size =
                    strlen(message->sv_Name) + 1 + message->sv_VarLen + 1 + 1;
                char *buffer = (char *)IExec->AllocVec((uint32)size,
                                                       MEMF_ANY | MEMF_CLEAR);

                snprintf(buffer, size - 1, "%s=%s", message->sv_Name,
                         message->sv_Var);

                *env = buffer;
                env++;
                hook->h_Data = env;
        }
        return 0;
}

void ___makeenviron()
{
        struct Hook hook;

        char varbuf[8];
        uint32 flags = 0;

        struct DOSIFace *myIDOS =
            (struct DOSIFace *)OpenInterface("dos.library", 53);
        if (myIDOS)
        {
                if (myIDOS->GetVar("ABCSH_IMPORT_LOCAL", varbuf, 8,
                                   GVF_LOCAL_ONLY) > 0)
                {
                        flags = GVF_LOCAL_ONLY;
                }
                else
                {
                        flags = GVF_GLOBAL_ONLY;
                }

                hook.h_Entry = size_env;
                hook.h_Data = 0;

                myIDOS->ScanVars(&hook, flags, 0);
                hook.h_Data = (APTR)(((uint32)hook.h_Data) + 1);

                myenviron = (char **)IExec->AllocVec((uint32)hook.h_Data *
                                                         sizeof(char **),
                                                     MEMF_ANY | MEMF_CLEAR);
                origenviron = myenviron;
                if (!myenviron)
                {
                        return;
                }
                hook.h_Entry = copy_env;
                hook.h_Data = myenviron;

                myIDOS->ScanVars(&hook, flags, 0);
                CloseInterface((struct Interface *)myIDOS);
        }
}

void ___freeenviron()
{
        char **i;
        /* perl might change environ, it puts it back except for ctrl-c */
        /* so restore our own copy here */
        struct DOSIFace *myIDOS =
            (struct DOSIFace *)OpenInterface("dos.library", 53);
        if (myIDOS)
        {
                myenviron = origenviron;

                if (myenviron)
                {
                        for (i = myenviron; *i != NULL; i++)
                        {
                                IExec->FreeVec(*i);
                        }
                        IExec->FreeVec(myenviron);
                        myenviron = NULL;
                }
                CloseInterface((struct Interface *)myIDOS);
        }
}

/* reimplementation of popen, clib2's doesn't do all we want */

static BOOL is_final_quote_character(const char *str)
{
        BOOL result;

        result = (BOOL)(str[0] == '\"' && (str[1] == '\0' || isspace(str[1])));

        return (result);
}

static BOOL is_final_squote_character(const char *str)
{
        BOOL result;

        result = (BOOL)(str[0] == '\'' && (str[1] == '\0' || isspace(str[1])));

        return (result);
}

int popen_child()
{
        struct Task *thisTask = IExec->FindTask(0);

        char *command = (char *)thisTask->tc_UserData;
        size_t len;
        char *str;
        int argc;
        int number_of_arguments;
        char *argv[4];

        argv[0] = "sh";
        argv[1] = "-c";
        argv[2] = command ? command : NULL;
        argv[3] = NULL;

        // adebug("%s %ld  %s\n",__FUNCTION__,__LINE__,command?command:"NULL");

        /* We need to give this to sh via execvp, execvp expects filename,
         * argv[]
         */

        myexecvp(FALSE, argv[0], argv);
        if (command)
                IExec->FreeVec(command);

        IExec->Forbid();
        return 0;
}

FILE *amigaos_popen(const char *cmd, const char *mode)
{
        FILE *result = NULL;
        char pipe_name[50];
        char unix_pipe[50];
        char ami_pipe[50];
        char *cmd_copy;
        BPTR input = 0;
        BPTR output = 0;
        struct Process *proc = NULL;
        struct Task *thisTask = IExec->FindTask(0);

        /* First we need to check the mode
         * We can only have unidirectional pipes
         */
        //    adebug("%s %ld cmd %s mode %s \n",__FUNCTION__,__LINE__,cmd,
        //    mode);

        switch (mode[0])
        {
        case 'r':
        case 'w':
                break;

        default:

                errno = EINVAL;
                return result;
        }

        /* Make a unique pipe name
         * we need a unix one and an amigaos version (of the same pipe!)
         * as were linking with libunix.
         */

        sprintf(pipe_name, "%x%08lx/4096/0", pipenum++,
                IUtility->GetUniqueID());
        sprintf(unix_pipe, "/PIPE/%s", pipe_name);
        sprintf(ami_pipe, "PIPE:%s", pipe_name);

        /* Now we open the AmigaOs Filehandles That we wil pass to our
         * Sub process
         */

        if (mode[0] == 'r')
        {
                /* A read mode pipe: Output from pipe input from NIL:*/
                input = IDOS->Open("NIL:", MODE_NEWFILE);
                if (input != 0)
                {
                        output = IDOS->Open(ami_pipe, MODE_NEWFILE);
                }
        }
        else
        {

                input = IDOS->Open(ami_pipe, MODE_NEWFILE);
                if (input != 0)
                {
                        output = IDOS->Open("NIL:", MODE_NEWFILE);
                }
        }
        if ((input == 0) || (output == 0))
        {
                /* Ouch stream opening failed */
                /* Close and bail */
                if (input)
                        IDOS->Close(input);
                if (output)
                        IDOS->Close(output);
                return result;
        }

        /* We have our streams now start our new process
         * We're using a new process so that execve can modify the environment
         * with messing things up for the shell that launched perl
         * Copy cmd before we launch the subprocess as perl seems to waste
         * no time in overwriting it! The subprocess will free the copy.
         */

        if ((cmd_copy = mystrdup(cmd)))
        {
                // adebug("%s %ld
                // %s\n",__FUNCTION__,__LINE__,cmd_copy?cmd_copy:"NULL");
                proc = IDOS->CreateNewProcTags(
                    NP_Entry, popen_child, NP_Child, TRUE, NP_StackSize,
                    ((struct Process *)thisTask)->pr_StackSize, NP_Input, input,
                    NP_Output, output, NP_Error, IDOS->ErrorOutput(),
                    NP_CloseError, FALSE, NP_Cli, TRUE, NP_Name,
                    "Perl: popen process", NP_UserData, (int)cmd_copy,
                    TAG_DONE);
        }
        if (!proc)
        {
                /* New Process Failed to start
                 * Close and bail out
                 */
                if (input)
                        IDOS->Close(input);
                if (output)
                        IDOS->Close(output);
                if (cmd_copy)
                        IExec->FreeVec(cmd_copy);
        }

        /* Our new process is running and will close it streams etc
         * once its done. All we need to is open the pipe via stdio
         */

        return fopen(unix_pipe, mode);
}

/* Work arround for clib2 fstat */
#ifndef S_IFCHR
#define S_IFCHR 0x0020000
#endif

#define SET_FLAG(u, v) ((void)((u) |= (v)))

int afstat(int fd, struct stat *statb)
{
        int result;
        BPTR fh;
        int mode;
        BOOL input;
        /* In the first instance pass it to fstat */
        // adebug("fd %ld ad %ld\n",fd,amigaos_get_file(fd));

        if ((result = fstat(fd, statb) >= 0))
                return result;

/* Now we've got a file descriptor but we failed to stat it */
/* Could be a nil: or could be a std#? */

/* if get_default_file fails we had a dud fd so return failure */
#if !defined(__CLIB2__)

        fh = amigaos_get_file(fd);

        /* if nil: return failure*/
        if (fh == 0)
                return -1;

        /* Now compare with our process Input() Output() etc */
        /* if these were regular files sockets or pipes we had already
         * succeeded */
        /* so we can guess they a character special console.... I hope */

        struct ExamineData *data;
        char name[120];
        name[0] = '\0';

        data = IDOS->ExamineObjectTags(EX_FileHandleInput, fh, TAG_END);
        if (data != NULL)
        {

                IUtility->Strlcpy(name, data->Name, sizeof(name));

                IDOS->FreeDosObject(DOS_EXAMINEDATA, data);
        }

        // adebug("ad %ld '%s'\n",amigaos_get_file(fd),name);
        mode = S_IFCHR;

        if (fh == IDOS->Input())
        {
                input = TRUE;
                SET_FLAG(mode, S_IRUSR);
                SET_FLAG(mode, S_IRGRP);
                SET_FLAG(mode, S_IROTH);
        }
        else if (fh == IDOS->Output() || fh == IDOS->ErrorOutput())
        {
                input = FALSE;
                SET_FLAG(mode, S_IWUSR);
                SET_FLAG(mode, S_IWGRP);
                SET_FLAG(mode, S_IWOTH);
        }
        else
        {
                /* we got a filehandle not handle by fstat or the above */
                /* most likely it's NIL: but lets check */
                struct ExamineData *exd = NULL;
                if ((exd = IDOS->ExamineObjectTags(EX_FileHandleInput, fh,
                                                   TAG_DONE)))
                {
                        BOOL isnil = FALSE;
                        if (exd->Type ==
                            (20060920)) // Ugh yes I know nasty.....
                        {
                                isnil = TRUE;
                        }
                        IDOS->FreeDosObject(DOS_EXAMINEDATA, exd);
                        if (isnil)
                        {
                                /* yep we got NIL: */
                                SET_FLAG(mode, S_IRUSR);
                                SET_FLAG(mode, S_IRGRP);
                                SET_FLAG(mode, S_IROTH);
                                SET_FLAG(mode, S_IWUSR);
                                SET_FLAG(mode, S_IWGRP);
                                SET_FLAG(mode, S_IWOTH);
                        }
                        else
                        {
                                IExec->DebugPrintF(
                                    "unhandled filehandle in afstat()\n");
                                return -1;
                        }
                }
        }

        memset(statb, 0, sizeof(statb));

        statb->st_mode = mode;

#endif
        return 0;
}

BPTR amigaos_get_file(int fd)
{
        BPTR fh = (BPTR)NULL;
        if (!(fh = _get_osfhandle(fd)))
        {
                switch (fd)
                {
                case 0:
                        fh = IDOS->Input();
                        break;
                case 1:
                        fh = IDOS->Output();
                        break;
                case 2:
                        fh = IDOS->ErrorOutput();
                        break;
                default:
                        break;
                }
        }
        return fh;
}

/*########################################################################*/

#define LOCK_START 0xFFFFFFFFFFFFFFFELL
#define LOCK_LENGTH 1LL

// No wait forever option so lets wait for a loooong time.
#define TIMEOUT 0x7FFFFFFF

int amigaos_flock(int fd, int oper)
{
        BPTR fh;
        int32 success = -1;

        if (!(fh = amigaos_get_file(fd)))
        {
                errno = EBADF;
                return -1;
        }

        switch (oper)
        {
        case LOCK_SH:
        {
                if (IDOS->LockRecord(fh, LOCK_START, LOCK_LENGTH,
                                     REC_SHARED | RECF_DOS_METHOD_ONLY,
                                     TIMEOUT))
                {
                        success = 0;
                }
                break;
        }
        case LOCK_EX:
        {
                if (IDOS->LockRecord(fh, LOCK_START, LOCK_LENGTH,
                                     REC_EXCLUSIVE | RECF_DOS_METHOD_ONLY,
                                     TIMEOUT))
                {
                        success = 0;
                }
                break;
        }
        case LOCK_SH | LOCK_NB:
        {
                if (IDOS->LockRecord(fh, LOCK_START, LOCK_LENGTH,
                                     REC_SHARED_IMMED | RECF_DOS_METHOD_ONLY,
                                     TIMEOUT))
                {
                        success = 0;
                }
                else
                {
                        errno = EWOULDBLOCK;
                }
                break;
        }
        case LOCK_EX | LOCK_NB:
        {
                if (IDOS->LockRecord(fh, LOCK_START, LOCK_LENGTH,
                                     REC_EXCLUSIVE_IMMED | RECF_DOS_METHOD_ONLY,
                                     TIMEOUT))
                {
                        success = 0;
                }
                else
                {
                        errno = EWOULDBLOCK;
                }
                break;
        }
        case LOCK_UN:
        {
                if (IDOS->UnLockRecord(fh, LOCK_START, LOCK_LENGTH))
                {
                        success = 0;
                }
                break;
        }
        default:
        {
                errno = EINVAL;
                return -1;
        }
        }
        return success;
}
