/* config.H:  This is a sample config.h file.  config.h is produced 
   from config_h.SH by Configure.  This file is intended only for
   those having problems with the regular Configure process.
*/
/*
 * This file was produced by running the config_h.SH script, which
 * gets its values from config.sh, which is generally produced by
 * running Configure.
 *
 * Feel free to modify any of this as the need arises.  Note, however,
 * that running config.h.SH again will wipe out any changes you've made.
 * For a more permanent change edit config.sh and rerun config.h.SH.
 *
 * $Id: Config_h.U,v 3.0.1.2 1993/08/24 12:13:20 ram Exp $
 */

/* Configuration time: Thu Apr 28 11:13:38 EDT 1994
 * Configured by: doughera
 * Target system: sunos einstein 4.1.3 3 sun4c 
 */

#ifndef _config_h_
#define _config_h_

/* BIN:
 *	This symbol holds the path of the bin directory where the package will
 *	be installed. Program must be prepared to deal with ~name substitution.
 */
#define BIN "/usr/local/bin"	/**/

/* BYTEORDER:
 *	This symbol hold the hexadecimal constant defined in byteorder,
 *	i.e. 0x1234 or 0x4321, etc...
 */
#define BYTEORDER 0x4321	/* large digits for MSB */

/* CPPSTDIN:
 *	This symbol contains the first part of the string which will invoke
 *	the C preprocessor on the standard input and produce to standard
 *	output.	 Typical value of "cc -E" or "/lib/cpp", but it can also
 *	call a wrapper. See CPPRUN.
 */
/* CPPMINUS:
 *	This symbol contains the second part of the string which will invoke
 *	the C preprocessor on the standard input and produce to standard
 *	output.  This symbol will have the value "-" if CPPSTDIN needs a minus
 *	to specify standard input, otherwise the value is "".
 */
#define CPPSTDIN "/home/doughera/src/perl5a8-ad/cppstdin"
#define CPPMINUS ""

/* HAS_BCMP:
 *	This symbol is defined if the bcmp() routine is available to
 *	compare blocks of memory.
 */
#define HAS_BCMP	/**/

/* HAS_BCOPY:
 *	This symbol is defined if the bcopy() routine is available to
 *	copy blocks of memory.
 */
#define HAS_BCOPY	/**/

/* HAS_BZERO:
 *	This symbol is defined if the bzero() routine is available to
 *	set a memory block to 0.
 */
#define HAS_BZERO	/**/

/* CASTNEGFLOAT:
 *	This symbol is defined if the C compiler can cast negative
 *	numbers to unsigned longs, ints and shorts.
 */
/* CASTFLAGS:
 *	This symbol contains flags that say what difficulties the compiler
 *	has casting odd floating values to unsigned long:
 *		0 = ok
 *		1 = couldn't cast < 0
 *		2 = couldn't cast >= 0x80000000
 */
#define	CASTNEGFLOAT		/**/
#define CASTFLAGS 0		/**/

/* CHARSPRINTF:
 *	This symbol is defined if this system declares "char *sprintf()" in
 *	stdio.h.  The trend seems to be to declare it as "int sprintf()".  It
 *	is up to the package author to declare sprintf correctly based on the
 *	symbol.
 */
#define	CHARSPRINTF 	/**/

/* HAS_CHSIZE:
 *	This symbol, if defined, indicates that the chsize routine is available
 *	to truncate files.  You might need a -lx to get this routine.
 */
/*#define	HAS_CHSIZE		/**/

/* HASCONST:
 *	This symbol, if defined, indicates that this C compiler knows about
 *	the const type. There is no need to actually test for that symbol
 *	within your programs. The mere use of the "const" keyword will
 *	trigger the necessary tests.
 */
/*#define HASCONST	/**/
#ifndef HASCONST
#define const
#endif

/* HAS_CRYPT:
 *	This symbol, if defined, indicates that the crypt routine is available
 *	to encrypt passwords and the like.
 */
#define HAS_CRYPT		/**/

/* CSH:
 *	This symbol, if defined, indicates that the C-shell exists.
 *	If defined, contains the full pathname of csh.
 */
#define CSH "/usr/bin/csh"		/**/

/* DOSUID:
 *	This symbol, if defined, indicates that the C program should
 *	check the script that it is executing for setuid/setgid bits, and
 *	attempt to emulate setuid/setgid on systems that have disabled
 *	setuid #! scripts because the kernel can't do it securely.
 *	It is up to the package designer to make sure that this emulation
 *	is done securely.  Among other things, it should do an fstat on
 *	the script it just opened to make sure it really is a setuid/setgid
 *	script, it should make sure the arguments passed correspond exactly
 *	to the argument on the #! line, and it should not trust any
 *	subprocesses to which it must pass the filename rather than the
 *	file descriptor of the script to be executed.
 */
/*#define DOSUID		/**/

/* HAS_DUP2:
 *	This symbol, if defined, indicates that the dup2 routine is
 *	available to duplicate file descriptors.
 */
#define HAS_DUP2	/**/

/* HAS_FCHMOD:
 *	This symbol, if defined, indicates that the fchmod routine is available
 *	to change mode of opened files.  If unavailable, use chmod().
 */
#define HAS_FCHMOD		/**/

/* HAS_FCHOWN:
 *	This symbol, if defined, indicates that the fchown routine is available
 *	to change ownership of opened files.  If unavailable, use chown().
 */
#define HAS_FCHOWN		/**/

/* HAS_FCNTL:
 *	This symbol, if defined, indicates to the C program that
 *	the fcntl() function exists.
 */
#define HAS_FCNTL		/**/

/* FLEXFILENAMES:
 *	This symbol, if defined, indicates that the system supports filenames
 *	longer than 14 characters.
 */
#define	FLEXFILENAMES		/**/

/* HAS_FLOCK:
 *	This symbol, if defined, indicates that the flock routine is
 *	available to do file locking.
 */
#define HAS_FLOCK		/**/

/* HAS_GETGROUPS:
 *	This symbol, if defined, indicates that the getgroups() routine is
 *	available to get the list of process groups.  If unavailable, multiple
 *	groups are probably not supported.
 */
#define HAS_GETGROUPS		/**/

/* HAS_GETHOSTENT:
 *	This symbol, if defined, indicates that the gethostent routine is
 *	available to lookup host names in some data base or other.
 */
#define HAS_GETHOSTENT		/**/

/* HAS_UNAME:
 *	This symbol, if defined, indicates that the C program may use the
 *	uname() routine to derive the host name.  See also HAS_GETHOSTNAME
 *	and PHOSTNAME.
 */
#define HAS_UNAME		/**/

/* HAS_GETPGRP:
 *	This symbol, if defined, indicates that the getpgrp routine is
 *	available to get the current process group.
 */
#define HAS_GETPGRP		/**/

/* HAS_GETPGRP2:
 *	This symbol, if defined, indicates that the getpgrp2() (as in DG/UX)
 *	routine is available to get the current process group.
 */
/*#define HAS_GETPGRP2		/**/

/* HAS_GETPRIORITY:
 *	This symbol, if defined, indicates that the getpriority routine is
 *	available to get a process's priority.
 */
#define HAS_GETPRIORITY		/**/

/* HAS_KILLPG:
 *	This symbol, if defined, indicates that the killpg routine is available
 *	to kill process groups.  If unavailable, you probably should use kill
 *	with a negative process number.
 */
#define HAS_KILLPG	/**/

/* HAS_LINK:
 *	This symbol, if defined, indicates that the link routine is
 *	available to create hard links.
 */
#define HAS_LINK	/**/

/* HAS_LSTAT:
 *	This symbol, if defined, indicates that the lstat routine is
 *	available to do file stats on symbolic links.
 */
#define HAS_LSTAT		/**/

/* HAS_MEMCMP:
 *	This symbol, if defined, indicates that the memcmp routine is available
 *	to compare blocks of memory.
 */
#define HAS_MEMCMP	/**/

/* HAS_MEMCPY:
 *	This symbol, if defined, indicates that the memcpy routine is available
 *	to copy blocks of memory.
 */
#define HAS_MEMCPY	/**/

/* HAS_MEMMOVE:
 *	This symbol, if defined, indicates that the memmove routine is available
 *	to copy potentially overlapping blocks of memory. This should be used
 *	only when HAS_SAFE_BCOPY is not defined. If neither is there, roll your
 *	own version.
 */
/*#define HAS_MEMMOVE	/**/

/* HAS_MEMSET:
 *	This symbol, if defined, indicates that the memset routine is available
 *	to set blocks of memory.
 */
#define HAS_MEMSET	/**/

/* HAS_MKDIR:
 *	This symbol, if defined, indicates that the mkdir routine is available
 *	to create directories.  Otherwise you should fork off a new process to
 *	exec /bin/mkdir.
 */
#define HAS_MKDIR		/**/

/* HAS_MSG:
 *	This symbol, if defined, indicates that the entire msg*(2) library is
 *	supported (IPC mechanism based on message queues).
 */
#define HAS_MSG		/**/

/* HAS_MSGCTL:
 *	This symbol, if defined, indicates that the msgctl() routine is
 *	available to perform message control operations.
 */
#define HAS_MSGCTL		/**/

/* HAS_MSGGET:
 *	This symbol, if defined, indicates that the msgget() routine is
 *	available to get a new message queue.
 */
#define HAS_MSGGET		/**/

/* HAS_MSGRCV:
 *	This symbol, if defined, indicates that the msgrcv() routine is
 *	available to extract a message from the message queue.
 */
#define HAS_MSGRCV		/**/

/* HAS_MSGSND:
 *	This symbol, if defined, indicates that the msgsnd() routine is
 *	available to send a message into the message queue.
 */
#define HAS_MSGSND		/**/

/* HAS_OPEN3:
 *	This manifest constant lets the C program know that the three
 *	argument form of open(2) is available.
 */
#define HAS_OPEN3		/**/

/* HAS_RENAME:
 *	This symbol, if defined, indicates that the rename routine is available
 *	to rename files.  Otherwise you should do the unlink(), link(), unlink()
 *	trick.
 */
#define HAS_RENAME	/**/

/* HAS_RMDIR:
 *	This symbol, if defined, indicates that the rmdir routine is
 *	available to remove directories. Otherwise you should fork off a
 *	new process to exec /bin/rmdir.
 */
#define HAS_RMDIR		/**/

/* HAS_SELECT:
 *	This symbol, if defined, indicates that the select routine is
 *	available to select active file descriptors. If the timeout field
 *	is used, <sys/time.h> may need to be included.
 */
#define HAS_SELECT	/**/

/* HAS_SEM:
 *	This symbol, if defined, indicates that the entire sem*(2) library is
 *	supported.
 */
#define HAS_SEM		/**/

/* HAS_SEMCTL:
 *	This symbol, if defined, indicates that the semctl() routine is
 *	available to perform semaphore control operations.
 */
#define HAS_SEMCTL	/**/

/* HAS_SEMGET:
 *	This symbol, if defined, indicates that the semget() routine is
 *	available to get a set of semaphores.
 */
#define HAS_SEMGET	/**/

/* HAS_SEMOP:
 *	This symbol, if defined, indicates that the semop() routine is
 *	available to execute semaphore operations.
 */
#define HAS_SEMOP		/**/

/* HAS_SETEGID:
 *	This symbol, if defined, indicates that the setegid routine is available
 *	to change the effective gid of the current program.
 */
#define HAS_SETEGID		/**/

/* HAS_SETEUID:
 *	This symbol, if defined, indicates that the seteuid routine is available
 *	to change the effective uid of the current program.
 */
#define HAS_SETEUID		/**/

/* HAS_SETPGID:
 *	This symbol, if defined, indicates that the setpgid routine is
 *	available to set process group ID.
 */
#define HAS_SETPGID	/**/

/* HAS_SETPGRP:
 *	This symbol, if defined, indicates that the setpgrp routine is
 *	available to set the current process group.
 */
#define HAS_SETPGRP		/**/

/* HAS_SETPGRP2:
 *	This symbol, if defined, indicates that the setpgrp2() (as in DG/UX)
 *	routine is available to set the current process group.
 */
/*#define HAS_SETPGRP2		/**/

/* HAS_SETPRIORITY:
 *	This symbol, if defined, indicates that the setpriority routine is
 *	available to set a process's priority.
 */
#define HAS_SETPRIORITY		/**/

/* HAS_SETREGID:
 *	This symbol, if defined, indicates that the setregid routine is
 *	available to change the real and effective gid of the current
 *	process.
 */
/* HAS_SETRESGID:
 *	This symbol, if defined, indicates that the setresgid routine is
 *	available to change the real, effective and saved gid of the current
 *	process.
 */
#define HAS_SETREGID		/**/
/*#define HAS_SETRESGID		/**/

/* HAS_SETREUID:
 *	This symbol, if defined, indicates that the setreuid routine is
 *	available to change the real and effective uid of the current
 *	process.
 */
/* HAS_SETRESUID:
 *	This symbol, if defined, indicates that the setresuid routine is
 *	available to change the real, effective and saved uid of the current
 *	process.
 */
#define HAS_SETREUID		/**/
/*#define HAS_SETRESUID		/**/

/* HAS_SETRGID:
 *	This symbol, if defined, indicates that the setrgid routine is available
 *	to change the real gid of the current program.
 */
#define HAS_SETRGID		/**/

/* HAS_SETRUID:
 *	This symbol, if defined, indicates that the setruid routine is available
 *	to change the real uid of the current program.
 */
#define HAS_SETRUID		/**/

/* HAS_SETSID:
 *	This symbol, if defined, indicates that the setsid routine is
 *	available to set the process group ID.
 */
#define HAS_SETSID	/**/

/* HAS_SHM:
 *	This symbol, if defined, indicates that the entire shm*(2) library is
 *	supported.
 */
#define HAS_SHM		/**/

/* HAS_SHMCTL:
 *	This symbol, if defined, indicates that the shmctl() routine is
 *	available to perform shared memory control operations.
 */
#define HAS_SHMCTL		/**/

/* HAS_SHMDT:
 *	This symbol, if defined, indicates that the shmdt() routine is
 *	available to detach a shared memory segment from the process space.
 */
#define HAS_SHMDT		/**/

/* HAS_SHMGET:
 *	This symbol, if defined, indicates that the shmget() routine is
 *	available to request a shared memory segment from the kernel.
 */
#define HAS_SHMGET		/**/

/* HAS_SOCKET:
 *	This symbol, if defined, indicates that the BSD socket interface is
 *	supported.
 */
/* HAS_SOCKETPAIR:
 *	This symbol, if defined, indicates that the BSD socketpair() call is
 *	supported.
 */
/* USE_OLDSOCKET:
 *	This symbol, if defined, indicates that the 4.1c BSD socket interface
 *	is supported instead of the 4.2/4.3 BSD socket interface. For instance,
 *	there is no setsockopt() call.
 */
#define HAS_SOCKET		/**/
#define HAS_SOCKETPAIR	/**/
/*#define USE_OLDSOCKET	/**/

/* USE_STAT_BLOCKS:
 *	This symbol is defined if this system has a stat structure declaring
 *	st_blksize and st_blocks.
 */
#define USE_STAT_BLOCKS 	/**/

/* USE_STD_STDIO:
 *	This symbol is defined if this system has a FILE structure declaring
 *	_ptr and _cnt in stdio.h.
 */
#define USE_STD_STDIO 	/**/

/* USE_STRUCT_COPY:
 *	This symbol, if defined, indicates that this C compiler knows how
 *	to copy structures.  If undefined, you'll need to use a block copy
 *	routine of some sort instead.
 */
#define	USE_STRUCT_COPY	/**/

/* HAS_SYMLINK:
 *	This symbol, if defined, indicates that the symlink routine is available
 *	to create symbolic links.
 */
#define HAS_SYMLINK	/**/

/* HAS_SYSCALL:
 *	This symbol, if defined, indicates that the syscall routine is
 *	available to call arbitrary system calls. If undefined, that's tough.
 */
#define HAS_SYSCALL	/**/

/* HAS_SYSTEM:
 *	This symbol, if defined, indicates that the system routine is
 *	available to issue a shell command.
 */
#define HAS_SYSTEM	/**/

/* Time_t:
 *	This symbol holds the type returned by time(). It can be long,
 *	or time_t on BSD sites (in which case <sys/types.h> should be
 *	included).
 */
#define Time_t long		/* Time type */

/* HAS_TIMES:
 *	This symbol, if defined, indicates that the times() routine exists.
 *	Note that this became obsolete on some systems (SUNOS), which now
 * use getrusage(). It may be necessary to include <sys/times.h>.
 */
#define HAS_TIMES		/**/

/* HAS_TRUNCATE:
 *	This symbol, if defined, indicates that the truncate routine is
 *	available to truncate files.
 */
#define HAS_TRUNCATE	/**/

/* I_NDIR:
 *	This symbol, if defined, indicates that the program should include the
 *	system's version of ndir.h, rather than the one with this package.
 */
/*#define I_NDIR		/**/

/* VOIDSIG:
 *	This symbol is defined if this system declares "void (*signal(...))()" in
 *	signal.h.  The old way was to declare it as "int (*signal(...))()".  It
 *	is up to the package author to declare things correctly based on the
 *	symbol.
 */
#define VOIDSIG 	/**/

/* HASVOLATILE:
 *	This symbol, if defined, indicates that this C compiler knows about
 *	the volatile declaration.
 */
/*#define	HASVOLATILE	/**/
#ifndef HASVOLATILE
#define volatile
#endif

/* HAS_VPRINTF:
 *	This symbol, if defined, indicates that the vprintf routine is available
 *	to printf with a pointer to an argument list.  If unavailable, you
 *	may need to write your own, probably in terms of _doprnt().
 */
/* USE_CHAR_VSPRINTF:
 *	This symbol is defined if this system has vsprintf() returning type
 *	(char*).  The trend seems to be to declare it as "int vsprintf()".  It
 *	is up to the package author to declare vsprintf correctly based on the
 *	symbol.
 */
#define HAS_VPRINTF	/**/
#define USE_CHAR_VSPRINTF 	/**/

/* HAS_WAIT4:
 *	This symbol, if defined, indicates that wait4() exists.
 */
#define HAS_WAIT4	/**/

/* HAS_WAITPID:
 *	This symbol, if defined, indicates that the waitpid routine is
 *	available to wait for child process.
 */
#define HAS_WAITPID	/**/

/* I_DBM:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <dbm.h>.
 */
#define I_DBM	/**/

/* I_DIRENT:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <dirent.h>. Using this symbol also triggers the definition
 *	of the Direntry_t define which ends up being 'struct dirent' or
 *	'struct direct' depending on the availability of <dirent.h>.
 */
/* DIRNAMLEN:
 *	This symbol, if defined, indicates to the C program that the length
 *	of directory entry names is provided by a d_namlen field.  Otherwise
 *	you need to do strlen() on the d_name field.
 */
#define I_DIRENT		/**/
/*#define DIRNAMLEN	/**/
#ifdef I_DIRENT
#define Direntry_t struct dirent
#else
#define Direntry_t struct direct
#endif

/* I_FCNTL:
 *	This manifest constant tells the C program to include <fcntl.h>.
 */
/*#define I_FCNTL	/**/

/* I_GDBM:
 *	This symbol, if defined, indicates that gdbm.h exists and should
 *	be included.
 */
/*#define I_GDBM	/**/

/* I_GRP:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <grp.h>.
 */
#define I_GRP		/**/

/* I_NDBM:
 *	This symbol, if defined, indicates that ndbm.h exists and should
 *	be included.
 */
#define I_NDBM	/**/

/* I_NETINET_IN:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <netinet/in.h>. Otherwise, you may try <sys/in.h>.
 */
/* I_SYS_IN:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <sys/in.h> instead of <netinet/in.h>.
 */
#define I_NETINET_IN	/**/
/*#define I_SYS_IN		/**/

/* I_STDARG:
 *	This symbol, if defined, indicates that <stdarg.h> exists and should
 *	be included.
 */
/*#define I_STDARG		/**/

/* I_STDDEF:
 *	This symbol, if defined, indicates that <stddef.h> exists and should
 *	be included.
 */
#define I_STDDEF	/**/

/* I_STRING:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <string.h> (USG systems) instead of <strings.h> (BSD systems).
 */
#define I_STRING		/**/

/* I_SYS_DIR:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <sys/dir.h>.
 */
#define I_SYS_DIR		/**/

/* I_SYS_FILE:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <sys/file.h> to get definition of R_OK and friends.
 */
#define I_SYS_FILE		/**/

/* I_SYS_IOCTL:
 *	This symbol, if defined, indicates that <sys/ioctl.h> exists and should
 *	be included. Otherwise, include <sgtty.h> or <termio.h>.
 */
#define	I_SYS_IOCTL		/**/

/* I_SYS_NDIR:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <sys/ndir.h>.
 */
/*#define I_SYS_NDIR	/**/

/* I_SYS_SELECT:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <sys/select.h> in order to get definition of struct timeval.
 */
/*#define I_SYS_SELECT	/**/

/* I_TIME:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <time.h>.
 */
/* I_SYS_TIME:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <sys/time.h>.
 */
/* I_SYS_TIME_KERNEL:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <sys/time.h> with KERNEL defined.
 */
/*#define I_TIME		/**/
#define I_SYS_TIME		/**/
/*#define I_SYS_TIME_KERNEL		/**/

/* I_UTIME:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <utime.h>.
 */
#define I_UTIME		/**/

/* I_VARARGS:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <varargs.h>.
 */
#define I_VARARGS		/**/

/* INTSIZE:
 *	This symbol contains the size of an int, so that the C preprocessor
 *	can make decisions based on it.
 */
#define INTSIZE 4		/**/

/* Off_t:
 *	This symbol holds the type used to declare offsets in the kernel.
 *	It can be int, long, off_t, etc... It may be necessary to include
 *	<sys/types.h> to get any typedef'ed information.
 */
#define Off_t off_t		/* <offset> type */

/* PRIVLIB:
 *	This symbol contains the name of the private library for this package.
 *	The library is private in the sense that it needn't be in anyone's
 *	execution path, but it should be accessible by the world.  The program
 *	should be prepared to do ~ expansion.
 */
#define PRIVLIB "/usr/local/lib/perl"		/**/

/* RANDBITS:
 *	This symbol contains the number of bits of random number the rand()
 *	function produces.  Usual values are 15, 16, and 31.
 */
#define RANDBITS 31		/**/

/* SCRIPTDIR:
 *	This symbol holds the name of the directory in which the user wants
 *	to put publicly executable scripts for the package in question.  It
 *	is often a directory that is mounted across diverse architectures.
 *	Programs must be prepared to deal with ~name expansion.
 */
#define SCRIPTDIR "/usr/local/bin"	/**/

/* STDCHAR:
 *	This symbol is defined to be the type of char used in stdio.h.
 *	It has the values "unsigned char" or "char".
 */
#define STDCHAR unsigned char	/**/

/* Uid_t:
 *	This symbol holds the type used to declare user ids in the kernel.
 *	It can be int, ushort, uid_t, etc... It may be necessary to include
 *	<sys/types.h> to get any typedef'ed information.
 */
#define Uid_t uid_t		/* UID type */

/* EUNICE:
 *	This symbol, if defined, indicates that the program is being compiled
 *	under the EUNICE package under VMS.  The program will need to handle
 *	things like files that don't go away the first time you unlink them,
 *	due to version numbering.  It will also need to compensate for lack
 *	of a respectable link() command.
 */
/* VMS:
 *	This symbol, if defined, indicates that the program is running under
 *	VMS.  It is currently only set in conjunction with the EUNICE symbol.
 */
/*#define EUNICE		/**/
/*#define VMS		/**/

/* MEM_ALIGNBYTES:
 *	This symbol contains the number of bytes required to align a
 *	double. Usual values are 2, 4 and 8.
 */
#define MEM_ALIGNBYTES 8	/**/

/* CASTI32:
 *	This symbol is defined if the C compiler can cast negative
 *	or large floating point numbers to 32-bit ints.
 */
#define	CASTI32		/**/

/* HAS_HTONL:
 *	This symbol, if defined, indicates that the htonl() routine (and
 *	friends htons() ntohl() ntohs()) are available to do network
 *	order byte swapping.
 */
/* HAS_HTONS:
 *	This symbol, if defined, indicates that the htons() routine (and
 *	friends htonl() ntohl() ntohs()) are available to do network
 *	order byte swapping.
 */
/* HAS_NTOHL:
 *	This symbol, if defined, indicates that the ntohl() routine (and
 *	friends htonl() htons() ntohs()) are available to do network
 *	order byte swapping.
 */
/* HAS_NTOHS:
 *	This symbol, if defined, indicates that the ntohs() routine (and
 *	friends htonl() htons() ntohl()) are available to do network
 *	order byte swapping.
 */
#define HAS_HTONL		/**/
#define HAS_HTONS		/**/
#define HAS_NTOHL		/**/
#define HAS_NTOHS		/**/

/* HAS_ISASCII:
 *	This manifest constant lets the C program know that the
 *	isascii is available.
 */
#define HAS_ISASCII		/**/

/* HAS_READDIR:
 *	This symbol, if defined, indicates that the readdir routine is
 *	available to read directory entries. You may have to include
 *	<dirent.h>. See I_DIRENT.
 */
#define HAS_READDIR		/**/

/* HAS_SEEKDIR:
 *	This symbol, if defined, indicates that the seekdir routine is
 *	available. You may have to include <dirent.h>. See I_DIRENT.
 */
#define HAS_SEEKDIR		/**/

/* HAS_TELLDIR:
 *	This symbol, if defined, indicates that the telldir routine is
 *	available. You may have to include <dirent.h>. See I_DIRENT.
 */
#define HAS_TELLDIR		/**/

/* HAS_REWINDDIR:
 *	This symbol, if defined, indicates that the rewinddir routine is
 *	available. You may have to include <dirent.h>. See I_DIRENT.
 */
#define HAS_REWINDDIR		/**/

/* HAS_SAFE_BCOPY:
 *	This symbol, if defined, indicates that the bcopy routine is available
 *	to copy potentially overlapping memory blocks. Otherwise you should
 *	probably use memmove() or memcpy(). If neither is defined, roll your
 *	own version.
 */
#define HAS_SAFE_BCOPY	/**/

/* HAS_SAFE_MEMCPY:
 *	This symbol, if defined, indicates that the memcpy routine is available
 *	to copy potentially overlapping memory blocks. Otherwise you should
 *	probably use memmove() or memcpy(). If neither is defined, roll your
 *	own version.
 */
/*#define HAS_SAFE_MEMCPY	/**/

/* HAS_SETLOCALE:
 *	This symbol, if defined, indicates that the setlocale routine is
 *	available to handle locale-specific ctype implementations.
 */
#define HAS_SETLOCALE	/**/

/* HAS_SHMAT:
 *	This symbol, if defined, indicates that the shmat() routine is
 *	available to attach a shared memory segment to the process space.
 */
#define HAS_SHMAT		/**/

/* VOIDSHMAT:
 *	This symbol, if defined, indicates that the shmat() routine
 *	returns a pointer of type void*.  Otherwise, char* is assumed.
 */
/*#define	VOIDSHMAT		/**/

/* HAS_STRERROR:
 *	This symbol, if defined, indicates that the strerror routine is
 *	available to translate error numbers to strings. See the writeup
 *	of Strerror() in this file before you try to define your own.
 */
/* HAS_SYS_ERRLIST:
 *	This symbol, if defined, indicates that the sys_errlist array is
 *	available to translate error numbers to strings. The extern int
 *	sys_nerr gives the size of that table.
 */
/* Strerror:
 *	This preprocessor symbol is defined as a macro if strerror() is
 *	not available to translate error numbers to strings but sys_errlist[]
 *	array is there.
 */
/*#define HAS_STRERROR		/**/
#define HAS_SYS_ERRLIST	/**/
#ifdef HAS_STRERROR
#  define Strerror strerror
#else
#define Strerror(e) ((e)<0||(e)>=sys_nerr?"unknown":sys_errlist[e]) /**/
#endif

/* HAS_VFORK:
 *	This symbol, if defined, indicates that vfork() exists.
 */
/*#define HAS_VFORK	/**/

/* USE_DYNAMIC_LOADING:
 *	This symbol, if defined, indicates that dynamic loading of
 *	some sort is available.
 */
#define USE_DYNAMIC_LOADING		/**/

/* Gid_t:
 *	This symbol holds the return type of getgid() and the type of
 *	argument to setrgid() and related functions.  Typically,
 *	it is the type of group ids in the kernel.
 *	It can be int, ushort, uid_t, etc... It may be necessary to include
 *	<sys/types.h> to get any typedef'ed information.
 */
#define Gid_t gid_t		/* Type for getgid(), etc... */

/* GROUPSTYPE:
 *	This symbol holds the type used for the second argument to
 *	getgroups().  Usually, this is the same of gidtype, but
 *	sometimes it isn't.  It can be int, ushort, uid_t, etc... 
 *	It may be necessary to include <sys/types.h> to get any 
 *	typedef'ed information.  This is only required if you have
 *	getgroups().
 */
#ifdef HAS_GETGROUPS
#define GROUPSTYPE int	/* Type for 2nd arg to getgroups() */
#endif

/* I_DLFCN:
 *	This symbol, if defined, indicates that <dlfcn.h> exists and should
 *	be included.
 */
#define I_DLFCN		/**/

/* I_MEMORY:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <memory.h>.
 */
#define I_MEMORY		/**/

/* I_NET_ERRNO:
 *	This symbol, if defined, indicates that <net/errno.h> exists and 
 *	should be included.
 */
/*#define I_NET_ERRNO		/**/

/* I_PWD:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <pwd.h>.
 */
/* PWQUOTA:
 *	This symbol, if defined, indicates to the C program that struct passwd
 *	contains pw_quota.
 */
/* PWAGE:
 *	This symbol, if defined, indicates to the C program that struct passwd
 *	contains pw_age.
 */
/* PWCHANGE:
 *	This symbol, if defined, indicates to the C program that struct passwd
 *	contains pw_change.
 */
/* PWCLASS:
 *	This symbol, if defined, indicates to the C program that struct passwd
 *	contains pw_class.
 */
/* PWEXPIRE:
 *	This symbol, if defined, indicates to the C program that struct passwd
 *	contains pw_expire.
 */
/* PWCOMMENT:
 *	This symbol, if defined, indicates to the C program that struct passwd
 *	contains pw_comment.
 */
#define I_PWD		/**/
/*#define PWQUOTA	/**/
#define PWAGE	/**/
/*#define PWCHANGE	/**/
/*#define PWCLASS	/**/
/*#define PWEXPIRE	/**/
#define PWCOMMENT	/**/

/* I_TERMIO:
 *	This symbol, if defined, indicates that the program should include
 *	<termio.h> rather than <sgtty.h>.  There are also differences in
 *	the ioctl() calls that depend on the value of this symbol.
 */
/* I_TERMIOS:
 *	This symbol, if defined, indicates that the program should include
 *	the POSIX termios.h rather than sgtty.h or termio.h.
 *	There are also differences in the ioctl() calls that depend on the
 *	value of this symbol.
 */
/* I_SGTTY:
 *	This symbol, if defined, indicates that the program should include
 *	<sgtty.h> rather than <termio.h>.  There are also differences in
 *	the ioctl() calls that depend on the value of this symbol.
 */
/*#define I_TERMIO		/**/
#define I_TERMIOS		/**/
/*#define I_SGTTY		/**/

/* I_VFORK:
 *	This symbol, if defined, indicates to the C program that it should
 *	include vfork.h.
 */
/*#define I_VFORK	/**/

/* LOC_SED:
 *	This symbol holds the complete pathname to the sed program.
 */
#define LOC_SED 	"/usr/bin/sed"	/**/

/* Malloc_t:
 *	This symbol is the type of pointer returned by malloc and realloc.
 */
#define Malloc_t char *			/**/

/* MYMALLOC:
 *	This symbol, if defined, indicates that we're using our own malloc.
 */
#define MYMALLOC			/**/

/* CAN_PROTOTYPE:
 *	If defined, this macro indicates that the C compiler can handle
 *	function prototypes.
 */
/*#define	CAN_PROTOTYPE	/**/
#ifdef CAN_PROTOTYPE
#else
#endif

/* PTRSIZE:
 *	This symbol contains the size of a pointer to a long so that 
 *	the C preprocessor can make decisions based on it.
 */
#define PTRSIZE 4		/**/

/* SIG_NAME:
 *	This symbol contains a list of signal names in order. This is intended
 *	to be used as a static array initialization, like this:
 *		char *sig_name[] = { SIG_NAME };
 *	The signals in the list are separated with commas, and each signal
 *	is surrounded by double quotes. There is no leading SIG in the signal
 *	name, i.e. SIGQUIT is known as "QUIT".
 */
#define SIG_NAME "ZERO","HUP","INT","QUIT","ILL","TRAP","ABRT","EMT","FPE","KILL","BUS","SEGV","SYS","PIPE","ALRM","TERM","URG","STOP","TSTP","CONT","CLD","TTIN","TTOU","IO","XCPU","XFSZ","VTALRM","PROF","WINCH","LOST","USR1","USR2"	/**/

/* VOIDFLAGS:
 *	This symbol indicates how much support of the void type is given by this
 *	compiler.  What various bits mean:
 *
 *	    1 = supports declaration of void
 *	    2 = supports arrays of pointers to functions returning void
 *	    4 = supports comparisons between pointers to void functions and
 *		    addresses of void functions
 *	    8 = suports declaration of generic void pointers
 *
 *	The package designer should define VOIDUSED to indicate the requirements
 *	of the package.  This can be done either by #defining VOIDUSED before
 *	including config.h, or by defining defvoidused in Myinit.U.  If the
 *	latter approach is taken, only those flags will be tested.  If the
 *	level of void support necessary is not present, defines void to int.
 */
#ifndef VOIDUSED
#  define VOIDUSED 15
#endif
#define VOIDFLAGS 15
#if (VOIDFLAGS & VOIDUSED) != VOIDUSED
#  define void int		/* is void to be avoided? */
#  define M_VOID			/* Xenix strikes again */
#  define VOID
#else
#  define VOID void
#endif

/*
 * The following symbols are obsolete. They are mapped to the the new
 * symbols only to ease the transition process. The sources should be
 * updated so as to use the new symbols only, as the support for these
 * obsolete symbols may end without notice.
 */

#ifdef MEM_ALIGNBYTES
#define ALIGNBYTES MEM_ALIGNBYTES
#endif

#ifdef USE_CHAR_VSPRINTF
#define CHARVSPRINTF USE_CHAR_VSPRINTF
#endif

#ifdef Gid_t
#define GIDTYPE Gid_t
#endif

#ifdef I_GDBM
#define HAS_GDBM I_GDBM
#endif

#ifdef I_NDBM
#define HAS_NDBM I_NDBM
#endif

#ifdef I_DBM
#define HAS_ODBM I_DBM
#endif

#ifdef I_SYS_IOCTL
#define I_SYSIOCTL I_SYS_IOCTL
#endif

#ifdef Malloc_t
#define MALLOCPTRTYPE Malloc_t
#endif

#ifdef USE_OLDSOCKET
#define OLDSOCKET USE_OLDSOCKET
#endif

#ifdef HAS_SAFE_BCOPY
#define SAFE_BCOPY HAS_SAFE_BCOPY
#endif

#ifdef HAS_SAFE_MEMCPY
#define SAFE_MEMCPY HAS_SAFE_MEMCPY
#endif

#ifdef USE_STAT_BLOCKS
#define STATBLOCKS USE_STAT_BLOCKS
#endif

#ifdef USE_STD_STDIO
#define STDSTDIO USE_STD_STDIO
#endif

#ifdef USE_STRUCT_COPY
#define STRUCTCOPY USE_STRUCT_COPY
#endif

#ifdef Uid_t
#define UIDTYPE Uid_t
#endif

#ifdef HAS_SYSTEM
#define SYSTEM HAS_SYSTEM
#endif

#endif
