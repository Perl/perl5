package POSIX;

require Exporter;
require AutoLoader;
@ISA = (Exporter, AutoLoader, DynamicLoader);

$H{assert_h} =	[qw(assert NDEBUG)];

$H{ctype_h} =	[qw(isalnum isalpha iscntrl isdigit isgraph islower
		isprint ispunct isspace isupper isxdigit tolower toupper)];

$H{dirent_h} =	[qw(closedir opendir readdir rewinddir)];

$H{errno_h} =   [qw(E2BIG EACCES EAGAIN EBADF EBUSY ECHILD EDEADLK EDOM
		EEXIST EFAULT EFBIG EINTR EINVAL EIO EISDIR EMFILE
		EMLINK ENAMETOOLONG ENFILE ENODEV ENOENT ENOEXEC ENOLCK
		ENOMEM ENOSPC ENOSYS ENOTDIR ENOTEMPTY ENOTTY ENXIO
		EPERM EPIPE ERANGE EROFS ESPIPE ESRCH EXDEV errno)];

$H{fcntl_h} =   [qw(FD_CLOEXEC F_DUPFD F_GETFD F_GETFL F_GETLK F_RDLCK
		F_SETFD F_SETFL F_SETLK F_SETLKW F_UNLCK F_WRLCK
		O_ACCMODE O_APPEND O_CREAT O_EXCL O_NOCTTY O_NONBLOCK
		O_RDONLY O_RDWR O_TRUNC O_WRONLY
		creat fcntl open
		SEEK_CUR SEEK_END SEEK_SET
		S_IRGRP S_IROTH S_IRUSR S_IRWXG S_IRWXO S_IRWXU
		S_ISBLK S_ISCHR S_ISDIR S_ISFIFO S_ISGID S_ISREG S_ISUID
		S_IWGRP S_IWOTH S_IWUSR)];

$H{float_h} =	[qw(DBL_DIG DBL_EPSILON DBL_MANT_DIG
		DBL_MAX DBL_MAX_10_EXP DBL_MAX_EXP
		DBL_MIN DBL_MIN_10_EXP DBL_MIN_EXP
		FLT_DIG FLT_EPSILON FLT_MANT_DIG
		FLT_MAX FLT_MAX_10_EXP FLT_MAX_EXP
		FLT_MIN FLT_MIN_10_EXP FLT_MIN_EXP
		FLT_RADIX FLT_ROUNDS
		LDBL_DIG LDBL_EPSILON LDBL_MANT_DIG
		LDBL_MAX LDBL_MAX_10_EXP LDBL_MAX_EXP
		LDBL_MIN LDBL_MIN_10_EXP LDBL_MIN_EXP)];

$H{grp_h} =	[qw(getgrgid getgrnam)];

$H{limits_h} =	[qw( ARG_MAX CHAR_BIT CHAR_MAX CHAR_MIN CHILD_MAX
		INT_MAX INT_MIN LINK_MAX LONG_MAX LONG_MIN MAX_CANON
		MAX_INPUT MB_LEN_MAX NAME_MAX NGROUPS_MAX OPEN_MAX
		PATH_MAX PIPE_BUF SCHAR_MAX SCHAR_MIN SHRT_MAX SHRT_MIN
		SSIZE_MAX STREAM_MAX TZNAME_MAX UCHAR_MAX UINT_MAX
		ULONG_MAX USHRT_MAX _POSIX_ARG_MAX _POSIX_CHILD_MAX
		_POSIX_LINK_MAX _POSIX_MAX_CANON _POSIX_MAX_INPUT
		_POSIX_NAME_MAX _POSIX_NGROUPS_MAX _POSIX_OPEN_MAX
		_POSIX_PATH_MAX _POSIX_PIPE_BUF _POSIX_SSIZE_MAX
		_POSIX_STREADM_MAX _POSIX_TZNAME_MAX)];

$H{locale_h} =  [qw(LC_ALL LC_COLLATE LC_CTYPE LC_MONETARY LC_NUMERIC
		LC_TIME NULL localeconf setlocale)];

$H{math_h} =    [qw(HUGE_VAL acos asin atan2 atan ceil cos cosh exp
		fabs floor fmod frexp ldexp log10 log modf pow sin sinh
		sqrt tan tanh)];

$H{pwd_h} =	[qw(getpwnam getpwuid)];

$H{setjmp_h} =	[qw(longjmp setjmp siglongjmp sigsetjmp)];

$H{signal_h} =  [qw(SA_NOCLDSTOP SIGABRT SIGALRM SIGCHLD SIGCONT SIGFPE
		SIGHUP SIGILL SIGINT SIGKILL SIGPIPE SIGQUIT SIGSEGV
		SIGSTOP SIGTERM SIGTSTP SIGTTIN SIGTTOU SIGUSR1 SIGUSR2
		SIG_BLOCK SIG_DFL SIG_ERR SIG_IGN SIG_SETMASK SIG_UNBLOCK
		kill raise sigaction sigaddset sigdelset sigemptyset
		sigfillset sigismember signal sigpending sigprocmask
		sigsuspend)];

$H{stdarg_h} =	[qw()];

$H{stddef_h} =	[qw(NULL offsetof)];

$H{stdio_h} =   [qw(BUFSIZ EOF FILENAME_MAX L_ctermid L_cuserid
		L_tmpname NULL SEEK_CUR SEEK_END SEEK_SET STREAM_MAX
		TMP_MAX stderr stdin stdout _IOFBF _IOLBF _IONBF
		clearerr fclose fdopen feof ferror fflush fgetc fgetpos
		fgets fileno fopen fprintf fputc fputs fread freopen
		fscanf fseek fsetpos ftell fwrite getc getchar gets
		perror printf putc putchar puts remove rename rewind
		scanf setbuf setvbuf sprintf sscanf tmpfile tmpnam
		ungetc vfprintf vprintf vsprintf)];

$H{stdlib_h} =  [qw(EXIT_FAILURE EXIT_SUCCESS MB_CUR_MAX NULL RAND_MAX
		abort abs atexit atof atoi atol bsearch calloc div exit
		free getenv labs ldiv malloc mblen mbstowcs mbtowc
		qsort rand realloc srand strtod strtol stroul system
		wcstombs wctomb)];

$H{string_h} =  [qw(NULL memchr memcmp memcpy memmove memset strcat
		strchr strcmp strcoll strcpy strcspn strerror strlen
		strncat strncmp strncpy strpbrk strrchr strspn strstr
		strtok strxfrm)];

$H{sys_stat_h} = [qw(S_IRGRP S_IROTH S_IRUSR S_IRWXG S_IRWXO S_IRWXU
		S_ISBLK S_ISCHR S_ISDIR S_ISFIFO S_ISGID S_ISREG
		S_ISUID S_IWGRP S_IWOTH S_IWUSR S_IXGRP S_IXOTH S_IXUSR
		chmod fstat mkdir mkfifo stat umask)];

$H{sys_times_h} = [qw(times)];

$H{sys_types_h} = [qw()];

$H{sys_utsname_h} = [qw(uname)];

$H{sys_wait_h} = [qw(WEXITSTATUS WIFEXITED WIFSIGNALED WIFSTOPPED
		WNOHANG WSTOPSIG WTERMSIG WUNTRACED wait waitpid)];

$H{termios_h} = [qw( B0 B110 B1200 B134 B150 B1800 B19200 B200 B2400
		B300 B38400 B4800 B50 B600 B75 B9600 BRKINT CLOCAL
		CREAD CS5 CS6 CS7 CS8 CSIZE CSTOPB ECHO ECHOE ECHOK
		ECHONL HUPCL ICANON ICRNL IEXTEN IGNBRK IGNCR IGNPAR
		INLCR INPCK ISIG ISTRIP IXOFF IXON NCCS NOFLSH OPOST
		PARENB PARMRK PARODD TCIFLUSH TCIOFF TCIOFLUSH TCION
		TCOFLUSH TCOOFF TCOON TCSADRAIN TCSAFLUSH TCSANOW
		TOSTOP VEOF VEOL VERASE VINTR VKILL VMIN VQUIT VSTART
		VSTOP VSUSP VTIME
		cfgetispeed cfgetospeed cfsetispeed cfsetospeed tcdrain
		tcflow tcflush tcgetattr tcsendbreak tcsetattr )];

$H{time_h} =    [qw(CLK_TCK CLOCKS_PER_SEC NULL asctime clock ctime
		difftime gmtime localtime mktime strftime time tzset tzname)];

$H{unistd_h} =  [qw(F_OK NULL R_OK SEEK_CUR SEEK_END SEEK_SET
		STRERR_FILENO STDIN_FILENO STDOUT_FILENO W_OK X_OK
		_PC_CHOWN_RESTRICTED _PC_LINK_MAX _PC_MAX_CANON
		_PC_MAX_INPUT _PC_NAME_MAX _PC_NO_TRUNC _PC_PATH_MAX
		_PC_PIPE_BUF _PC_VDISABLE _POSIX_CHOWN_RESTRICTED
		_POSIX_JOB_CONTROL _POSIX_NO_TRUNC _POSIX_SAVED_IDS
		_POSIX_VDISABLE _POSIX_VERSION _SC_ARG_MAX
		_SC_CHILD_MAX _SC_CLK_TCK _SC_JOB_CONTROL
		_SC_NGROUPS_MAX _SC_OPEN_MAX _SC_SAVED_IDS
		_SC_STREAM_MAX _SC_TZNAME_MAX _SC_VERSION
		_exit access alarm chdir chown close ctermid cuserid
		dup2 dup execl execle execlp execv execve execvp fork
		fpathconf getcwd getegid geteuid getgid getgroups
		getlogin getpgrp getpid getppid getuid isatty link
		lseek pathconf pause pipe read rmdir setgid setpgid
		setsid setuid sleep sysconf tcgetpgrp tcsetpgrp ttyname
		unlink write)];

$H{utime_h} =	[qw(utime)];

sub expand {
    local (@mylist);
    foreach $entry (@_) {
	if ($H{$entry}) {
	    push(@mylist, @{$H{$entry}});
	}
	else {
	    push(@mylist, $entry);
	}
    }
    @mylist;
}

@EXPORT = expand qw(assert_h ctype_h dirent_h errno_h fcntl_h float_h
		grp_h limits_h locale_h math_h pwd_h setjmp_h signal_h
		stdarg_h stddef_h stdio_h stdlib_h string_h sys_stat_h
		sys_times_h sys_types_h sys_utsname_h sys_wait_h
		termios_h time_h unistd_h utime_h);

sub import {
    my $this = shift;
    my @list = expand @_;
    local $Exporter::ExportLevel = 1;
    Exporter::import($this,@list);
}

bootstrap POSIX;

sub usage { local ($mess, $pack, $file, $line) = @_;
    die "Usage: POSIX::$_[0] at $file line $line\n";
}

1;

__END__
sub getpid {
    usage "getpid()", caller if @_ != 0;
    $$;
}

sub getppid {
    usage "getppid()", caller if @_ != 0;
    getppid;
}

sub fork {
    usage "fork()", caller if @_ != 0;
    fork;
}

sub kill {
    usage "kill(pid, sig)", caller if @_ != 2;
    kill $_[1], $_[0];
}
