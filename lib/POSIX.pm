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
		LC_TIME NULL localeconv setlocale)];

$H{math_h} =    [qw(HUGE_VAL acos asin atan2 atan ceil cos cosh exp
		fabs floor fmod frexp ldexp log10 log modf pow sin sinh
		sqrt tan tanh)];

$H{pwd_h} =	[qw(getpwnam getpwuid)];

$H{setjmp_h} =	[qw(longjmp setjmp siglongjmp sigsetjmp)];

$H{signal_h} =  [qw(SA_NOCLDSTOP SIGABRT SIGALRM SIGCHLD SIGCONT SIGFPE
		SIGHUP SIGILL SIGINT SIGKILL SIGPIPE SIGQUIT SIGSEGV
		SIGSTOP SIGTERM SIGTSTP SIGTTIN SIGTTOU SIGUSR1 SIGUSR2
		SIG_BLOCK SIG_DFL SIG_ERR SIG_IGN SIG_SETMASK SIG_UNBLOCK
		kill raise sigaction signal sigpending sigprocmask
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

sub AUTOLOAD {
    if ($AUTOLOAD =~ /::(_?[a-z])/) {
	$AutoLoader::AUTOLOAD = $AUTOLOAD;
	goto &AutoLoader::AUTOLOAD
    }
    local $constname = $AUTOLOAD;
    $constname =~ s/.*:://;
    $val = constant($constname, $_[0]);
    if ($! != 0) {
	($pack,$file,$line) = caller;
	if ($! =~ /Invalid/) {
	    die "$constname is not a valid POSIX macro at $file line $line.\n";
	}
	else {
	    die "Your vendor has not defined POSIX macro $constname, used at $file line $line.\n";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap POSIX;

sub usage { 
    local ($mess, $pack, $file, $line) = @_;
    die "Usage: POSIX::$mess at $file line $line\n";
}

sub unimpl { 
    local ($mess, $pack, $file, $line) = @_;
    $mess =~ s/xxx//;
    die "Unimplemented: POSIX::$mess at $file line $line\n";
}

$gensym = "SYM000";

sub gensym {
    $gensym++;
}

sub ungensym {
    delete $_POSIX{$_[0]};
}

1;

package POSIX::SigAction;

sub new {
    bless {HANDLER => $_[1], MASK => $_[2], FLAGS => $_[3]};
}
__END__

sub assert {
    usage "assert(expr)", caller if @_ != 1;
    if (!$_[0]) {
	local ($pack,$file,$line) = caller;
	die "Assertion failed at $file line $line\n";
    }
}

sub tolower {
    usage "tolower(string)", caller if @_ != 1;
    lc($_[0]);
}

sub toupper {
    usage "toupper(string)", caller if @_ != 1;
    uc($_[0]);
}

sub closedir {
    usage "closedir(dirhandle)", caller if @_ != 1;
    closedir($_[0]);
    ungensym($_[0]);
}

sub opendir {
    usage "opendir(directory)", caller if @_ != 1;
    local($dirhandle) = &gensym;
    opendir($dirhandle, $_[0])
	? $dirhandle
	: (ungensym($dirhandle), undef);
}

sub readdir {
    usage "readdir(dirhandle)", caller if @_ != 1;
    readdir($_[0]);
}

sub rewinddir {
    usage "rewinddir(dirhandle)", caller if @_ != 1;
    rewinddir($_[0]);
}

sub errno {
    usage "errno()", caller if @_ != 0;
    $! + 0;
}

sub creat {
    usage "creat(filename, mode)", caller if @_ != 2;
    &open($_[0], &O_WRONLY | &O_CREAT | &O_TRUNC, $_[2]);
}

sub fcntl {
    usage "fcntl(filehandle, cmd, arg)", caller if @_ != 3;
    fcntl($_[0], $_[1], $_[2]);
}

sub getgrgid {
    usage "getgrgid(gid)", caller if @_ != 1;
    getgrgid($_[0]);
}

sub getgrnam {
    usage "getgrnam(name)", caller if @_ != 1;
    getgrnam($_[0]);
}

sub atan2 {
    usage "atan2(x,y)", caller if @_ != 2;
    atan2($_[0], $_[1]);
}

sub cos {
    usage "cos(x)", caller if @_ != 1;
    cos($_[0]);
}

sub exp {
    usage "exp(x)", caller if @_ != 1;
    exp($_[0]);
}

sub fabs {
    usage "fabs(x)", caller if @_ != 1;
    abs($_[0]);
}

sub log {
    usage "log(x)", caller if @_ != 1;
    log($_[0]);
}

sub pow {
    usage "pow(x,exponent)", caller if @_ != 2;
    $_[0] ** $_[1];
}

sub sin {
    usage "sin(x)", caller if @_ != 1;
    sin($_[0]);
}

sub sqrt {
    usage "sqrt(x)", caller if @_ != 1;
    sqrt($_[0]);
}

sub tan {
    usage "tan(x)", caller if @_ != 1;
    tan($_[0]);
}

sub getpwnam {
    usage "getpwnam(name)", caller if @_ != 1;
    getpwnam($_[0]);
}

sub getpwuid {
    usage "getpwuid(uid)", caller if @_ != 1;
    getpwuid($_[0]);
}

sub longjmp {
    unimpl "longjmp() is C-specific: use die instead", caller;
}

sub setjmp {
    unimpl "setjmp() is C-specific: use eval {} instead", caller;
}

sub siglongjmp {
    unimpl "siglongjmp() is C-specific: use die instead", caller;
}

sub sigsetjmp {
    unimpl "sigsetjmp() is C-specific: use eval {} instead", caller;
}

sub kill {
    usage "kill(pid, sig)", caller if @_ != 2;
    kill $_[1], $_[0];
}

sub raise {
    usage "raise(sig)", caller if @_ != 1;
    kill $$, $_[0];	# Is this good enough?
}

sub offsetof {
    unimpl "offsetof() is C-specific, stopped", caller;
}

sub clearerr {
    usage "clearerr(filehandle)", caller if @_ != 1;
    seek($_[0], 0, 1);
}

sub fclose {
    unimpl "fclose() is C-specific--use close instead", caller;
}

sub feof {
    usage "feof(filehandle)", caller if @_ != 1;
    eof($_[0]);
}

sub fgetc {
    usage "fgetc(filehandle)", caller if @_ != 1;
    getc($_[0]);
}

sub fgetpos {
    unimpl "fgetpos(xxx)", caller if @_ != 123;
    fgetpos($_[0]);
}

sub fgets {
    usage "fgets(filehandle)", caller if @_ != 1;
    local($handle) = @_;
    scalar <$handle>;
}

sub fileno {
    usage "fileno(filehandle)", caller if @_ != 1;
    fileno($_[0]);
}

sub fopen {
    unimpl "fopen() is C-specific--use open instead", caller;
}

sub fprintf {
    unimpl "fprintf() is C-specific--use printf instead", caller;
}

sub fputc {
    unimpl "fputc() is C-specific--use print instead", caller;
}

sub fputs {
    unimpl "fputs() is C-specific--use print instead", caller;
    usage "fputs(string, handle)", caller if @_ != 2;
    local($handle) = pop;
    print $handle @_;
}

sub fread {
    unimpl "fread() is C-specific--use read instead", caller;
    unimpl "fread(xxx)", caller if @_ != 123;
    fread($_[0]);
}

sub freopen {
    unimpl "freopen() is C-specific--use open instead", caller;
    unimpl "freopen(xxx)", caller if @_ != 123;
    freopen($_[0]);
}

sub fscanf {
    unimpl "fscanf() is C-specific--use <> and regular expressions instead", caller;
    unimpl "fscanf(xxx)", caller if @_ != 123;
    fscanf($_[0]);
}

sub fseek {
    unimpl "fseek() is C-specific--use seek instead", caller;
    unimpl "fseek(xxx)", caller if @_ != 123;
    fseek($_[0]);
}

sub fsetpos {
    unimpl "fsetpos() is C-specific--use seek instead", caller;
    unimpl "fsetpos(xxx)", caller if @_ != 123;
    fsetpos($_[0]);
}

sub ftell {
    unimpl "ftell() is C-specific--use tell instead", caller;
    unimpl "ftell(xxx)", caller if @_ != 123;
    ftell($_[0]);
}

sub fwrite {
    unimpl "fwrite() is C-specific--use print instead", caller;
    unimpl "fwrite(xxx)", caller if @_ != 123;
    fwrite($_[0]);
}

sub getc {
    usage "getc(handle)", caller if @_ != 1;
    getc($_[0]);
}

sub getchar {
    usage "getchar()", caller if @_ != 0;
    getc(STDIN);
}

sub gets {
    usage "gets(handle)", caller if @_ != 1;
    local($handle) = shift;
    scalar <$handle>;
}

sub perror {
    unimpl "perror() is C-specific--print $! instead", caller;
    unimpl "perror(xxx)", caller if @_ != 123;
    perror($_[0]);
}

sub printf {
    usage "printf(pattern, args...)", caller if @_ < 1;
    printf STDOUT @_;
}

sub putc {
    unimpl "putc() is C-specific--use print instead", caller;
    unimpl "putc(xxx)", caller if @_ != 123;
    putc($_[0]);
}

sub putchar {
    unimpl "putchar() is C-specific--use print instead", caller;
    unimpl "putchar(xxx)", caller if @_ != 123;
    putchar($_[0]);
}

sub puts {
    unimpl "puts() is C-specific--use print instead", caller;
    unimpl "puts(xxx)", caller if @_ != 123;
    puts($_[0]);
}

sub remove {
    unimpl "remove(xxx)", caller if @_ != 123;
    remove($_[0]);
}

sub rename {
    unimpl "rename(xxx)", caller if @_ != 123;
    rename($_[0]);
}

sub rewind {
    unimpl "rewind(xxx)", caller if @_ != 123;
    rewind($_[0]);
}

sub scanf {
    unimpl "scanf(xxx)", caller if @_ != 123;
    scanf($_[0]);
}

sub setbuf {
    unimpl "setbuf(xxx)", caller if @_ != 123;
    setbuf($_[0]);
}

sub setvbuf {
    unimpl "setvbuf(xxx)", caller if @_ != 123;
    setvbuf($_[0]);
}

sub sprintf {
    unimpl "sprintf(xxx)", caller if @_ != 123;
    sprintf($_[0]);
}

sub sscanf {
    unimpl "sscanf(xxx)", caller if @_ != 123;
    sscanf($_[0]);
}

sub tmpfile {
    unimpl "tmpfile(xxx)", caller if @_ != 123;
    tmpfile($_[0]);
}

sub tmpnam {
    unimpl "tmpnam(xxx)", caller if @_ != 123;
    tmpnam($_[0]);
}

sub ungetc {
    unimpl "ungetc(xxx)", caller if @_ != 123;
    ungetc($_[0]);
}

sub vfprintf {
    unimpl "vfprintf(xxx)", caller if @_ != 123;
    vfprintf($_[0]);
}

sub vprintf {
    unimpl "vprintf(xxx)", caller if @_ != 123;
    vprintf($_[0]);
}

sub vsprintf {
    unimpl "vsprintf(xxx)", caller if @_ != 123;
    vsprintf($_[0]);
}

sub abort {
    unimpl "abort(xxx)", caller if @_ != 123;
    abort($_[0]);
}

sub abs {
    usage "abs(x)", caller if @_ != 1;
    abs($_[0]);
}

sub atexit {
    unimpl "atexit() is C-specific: use END {} instead", caller;
}

sub atof {
    unimpl "atof() is C-specific, stopped", caller;
}

sub atoi {
    unimpl "atoi() is C-specific, stopped", caller;
}

sub atol {
    unimpl "atol() is C-specific, stopped", caller;
}

sub bsearch {
    unimpl "bsearch(xxx)", caller if @_ != 123;
    bsearch($_[0]);
}

sub calloc {
    unimpl "calloc(xxx)", caller if @_ != 123;
    calloc($_[0]);
}

sub div {
    unimpl "div(xxx)", caller if @_ != 123;
    div($_[0]);
}

sub exit {
    unimpl "exit(xxx)", caller if @_ != 123;
    exit($_[0]);
}

sub free {
    unimpl "free(xxx)", caller if @_ != 123;
    free($_[0]);
}

sub getenv {
    unimpl "getenv(xxx)", caller if @_ != 123;
    getenv($_[0]);
}

sub labs {
    unimpl "labs(xxx)", caller if @_ != 123;
    labs($_[0]);
}

sub ldiv {
    unimpl "ldiv(xxx)", caller if @_ != 123;
    ldiv($_[0]);
}

sub malloc {
    unimpl "malloc(xxx)", caller if @_ != 123;
    malloc($_[0]);
}

sub mblen {
    unimpl "mblen(xxx)", caller if @_ != 123;
    mblen($_[0]);
}

sub mbstowcs {
    unimpl "mbstowcs(xxx)", caller if @_ != 123;
    mbstowcs($_[0]);
}

sub mbtowc {
    unimpl "mbtowc(xxx)", caller if @_ != 123;
    mbtowc($_[0]);
}

sub qsort {
    unimpl "qsort(xxx)", caller if @_ != 123;
    qsort($_[0]);
}

sub rand {
    unimpl "rand(xxx)", caller if @_ != 123;
    rand($_[0]);
}

sub realloc {
    unimpl "realloc(xxx)", caller if @_ != 123;
    realloc($_[0]);
}

sub srand {
    unimpl "srand(xxx)", caller if @_ != 123;
    srand($_[0]);
}

sub strtod {
    unimpl "strtod(xxx)", caller if @_ != 123;
    strtod($_[0]);
}

sub strtol {
    unimpl "strtol(xxx)", caller if @_ != 123;
    strtol($_[0]);
}

sub stroul {
    unimpl "stroul(xxx)", caller if @_ != 123;
    stroul($_[0]);
}

sub system {
    unimpl "system(xxx)", caller if @_ != 123;
    system($_[0]);
}

sub wcstombs {
    unimpl "wcstombs(xxx)", caller if @_ != 123;
    wcstombs($_[0]);
}

sub wctomb {
    unimpl "wctomb(xxx)", caller if @_ != 123;
    wctomb($_[0]);
}

sub memchr {
    unimpl "memchr(xxx)", caller if @_ != 123;
    memchr($_[0]);
}

sub memcmp {
    unimpl "memcmp(xxx)", caller if @_ != 123;
    memcmp($_[0]);
}

sub memcpy {
    unimpl "memcpy(xxx)", caller if @_ != 123;
    memcpy($_[0]);
}

sub memmove {
    unimpl "memmove(xxx)", caller if @_ != 123;
    memmove($_[0]);
}

sub memset {
    unimpl "memset(xxx)", caller if @_ != 123;
    memset($_[0]);
}

sub strcat {
    unimpl "strcat(xxx)", caller if @_ != 123;
    strcat($_[0]);
}

sub strchr {
    unimpl "strchr(xxx)", caller if @_ != 123;
    strchr($_[0]);
}

sub strcmp {
    unimpl "strcmp(xxx)", caller if @_ != 123;
    strcmp($_[0]);
}

sub strcoll {
    unimpl "strcoll(xxx)", caller if @_ != 123;
    strcoll($_[0]);
}

sub strcpy {
    unimpl "strcpy(xxx)", caller if @_ != 123;
    strcpy($_[0]);
}

sub strcspn {
    unimpl "strcspn(xxx)", caller if @_ != 123;
    strcspn($_[0]);
}

sub strerror {
    unimpl "strerror(xxx)", caller if @_ != 123;
    strerror($_[0]);
}

sub strlen {
    unimpl "strlen(xxx)", caller if @_ != 123;
    strlen($_[0]);
}

sub strncat {
    unimpl "strncat(xxx)", caller if @_ != 123;
    strncat($_[0]);
}

sub strncmp {
    unimpl "strncmp(xxx)", caller if @_ != 123;
    strncmp($_[0]);
}

sub strncpy {
    unimpl "strncpy(xxx)", caller if @_ != 123;
    strncpy($_[0]);
}

sub strpbrk {
    unimpl "strpbrk(xxx)", caller if @_ != 123;
    strpbrk($_[0]);
}

sub strrchr {
    unimpl "strrchr(xxx)", caller if @_ != 123;
    strrchr($_[0]);
}

sub strspn {
    unimpl "strspn(xxx)", caller if @_ != 123;
    strspn($_[0]);
}

sub strstr {
    unimpl "strstr(xxx)", caller if @_ != 123;
    strstr($_[0]);
}

sub strtok {
    unimpl "strtok(xxx)", caller if @_ != 123;
    strtok($_[0]);
}

sub strxfrm {
    unimpl "strxfrm(xxx)", caller if @_ != 123;
    strxfrm($_[0]);
}

sub chmod {
    unimpl "chmod(xxx)", caller if @_ != 123;
    chmod($_[0]);
}

sub fstat {
    unimpl "fstat(xxx)", caller if @_ != 123;
    fstat($_[0]);
}

sub mkdir {
    unimpl "mkdir(xxx)", caller if @_ != 123;
    mkdir($_[0]);
}

sub mkfifo {
    unimpl "mkfifo(xxx)", caller if @_ != 123;
    mkfifo($_[0]);
}

sub stat {
    unimpl "stat(xxx)", caller if @_ != 123;
    stat($_[0]);
}

sub umask {
    unimpl "umask(xxx)", caller if @_ != 123;
    umask($_[0]);
}

sub times {
    unimpl "times(xxx)", caller if @_ != 123;
    times($_[0]);
}

sub wait {
    unimpl "wait(xxx)", caller if @_ != 123;
    wait($_[0]);
}

sub waitpid {
    unimpl "waitpid(xxx)", caller if @_ != 123;
    waitpid($_[0]);
}

sub cfgetispeed {
    unimpl "cfgetispeed(xxx)", caller if @_ != 123;
    cfgetispeed($_[0]);
}

sub cfgetospeed {
    unimpl "cfgetospeed(xxx)", caller if @_ != 123;
    cfgetospeed($_[0]);
}

sub cfsetispeed {
    unimpl "cfsetispeed(xxx)", caller if @_ != 123;
    cfsetispeed($_[0]);
}

sub cfsetospeed {
    unimpl "cfsetospeed(xxx)", caller if @_ != 123;
    cfsetospeed($_[0]);
}

sub tcdrain {
    unimpl "tcdrain(xxx)", caller if @_ != 123;
    tcdrain($_[0]);
}

sub tcflow {
    unimpl "tcflow(xxx)", caller if @_ != 123;
    tcflow($_[0]);
}

sub tcflush {
    unimpl "tcflush(xxx)", caller if @_ != 123;
    tcflush($_[0]);
}

sub tcgetattr {
    unimpl "tcgetattr(xxx)", caller if @_ != 123;
    tcgetattr($_[0]);
}

sub tcsendbreak {
    unimpl "tcsendbreak(xxx)", caller if @_ != 123;
    tcsendbreak($_[0]);
}

sub tcsetattr {
    unimpl "tcsetattr(xxx)", caller if @_ != 123;
    tcsetattr($_[0]);
}

sub asctime {
    unimpl "asctime(xxx)", caller if @_ != 123;
    asctime($_[0]);
}

sub clock {
    unimpl "clock(xxx)", caller if @_ != 123;
    clock($_[0]);
}

sub ctime {
    unimpl "ctime(xxx)", caller if @_ != 123;
    ctime($_[0]);
}

sub difftime {
    unimpl "difftime(xxx)", caller if @_ != 123;
    difftime($_[0]);
}

sub gmtime {
    unimpl "gmtime(xxx)", caller if @_ != 123;
    gmtime($_[0]);
}

sub localtime {
    unimpl "localtime(xxx)", caller if @_ != 123;
    localtime($_[0]);
}

sub mktime {
    unimpl "mktime(xxx)", caller if @_ != 123;
    mktime($_[0]);
}

sub strftime {
    unimpl "strftime(xxx)", caller if @_ != 123;
    strftime($_[0]);
}

sub time {
    unimpl "time(xxx)", caller if @_ != 123;
    time($_[0]);
}

sub tzset {
    unimpl "tzset(xxx)", caller if @_ != 123;
    tzset($_[0]);
}

sub tzname {
    unimpl "tzname(xxx)", caller if @_ != 123;
    tzname($_[0]);
}

sub _exit {
    unimpl "_exit(xxx)", caller if @_ != 123;
    _exit($_[0]);
}

sub access {
    unimpl "access(xxx)", caller if @_ != 123;
    access($_[0]);
}

sub alarm {
    unimpl "alarm(xxx)", caller if @_ != 123;
    alarm($_[0]);
}

sub chdir {
    unimpl "chdir(xxx)", caller if @_ != 123;
    chdir($_[0]);
}

sub chown {
    unimpl "chown(xxx)", caller if @_ != 123;
    chown($_[0]);
}

sub close {
    unimpl "close(xxx)", caller if @_ != 123;
    close($_[0]);
}

sub ctermid {
    unimpl "ctermid(xxx)", caller if @_ != 123;
    ctermid($_[0]);
}

sub cuserid {
    unimpl "cuserid(xxx)", caller if @_ != 123;
    cuserid($_[0]);
}

sub dup2 {
    unimpl "dup2(xxx)", caller if @_ != 123;
    dup2($_[0]);
}

sub dup {
    unimpl "dup(xxx)", caller if @_ != 123;
    dup($_[0]);
}

sub execl {
    unimpl "execl(xxx)", caller if @_ != 123;
    execl($_[0]);
}

sub execle {
    unimpl "execle(xxx)", caller if @_ != 123;
    execle($_[0]);
}

sub execlp {
    unimpl "execlp(xxx)", caller if @_ != 123;
    execlp($_[0]);
}

sub execv {
    unimpl "execv(xxx)", caller if @_ != 123;
    execv($_[0]);
}

sub execve {
    unimpl "execve(xxx)", caller if @_ != 123;
    execve($_[0]);
}

sub execvp {
    unimpl "execvp(xxx)", caller if @_ != 123;
    execvp($_[0]);
}

sub fork {
    usage "fork()", caller if @_ != 0;
    fork;
}

sub fpathconf {
    unimpl "fpathconf(xxx)", caller if @_ != 123;
    fpathconf($_[0]);
}

sub getcwd {
    unimpl "getcwd(xxx)", caller if @_ != 123;
    getcwd($_[0]);
}

sub getegid {
    unimpl "getegid(xxx)", caller if @_ != 123;
    getegid($_[0]);
}

sub geteuid {
    unimpl "geteuid(xxx)", caller if @_ != 123;
    geteuid($_[0]);
}

sub getgid {
    unimpl "getgid(xxx)", caller if @_ != 123;
    getgid($_[0]);
}

sub getgroups {
    unimpl "getgroups(xxx)", caller if @_ != 123;
    getgroups($_[0]);
}

sub getlogin {
    unimpl "getlogin(xxx)", caller if @_ != 123;
    getlogin($_[0]);
}

sub getpgrp {
    unimpl "getpgrp(xxx)", caller if @_ != 123;
    getpgrp($_[0]);
}

sub getpid {
    usage "getpid()", caller if @_ != 0;
    $$;
}

sub getppid {
    usage "getppid()", caller if @_ != 0;
    getppid;
}

sub getuid {
    unimpl "getuid(xxx)", caller if @_ != 123;
    getuid($_[0]);
}

sub isatty {
    unimpl "isatty(xxx)", caller if @_ != 123;
    isatty($_[0]);
}

sub link {
    unimpl "link(xxx)", caller if @_ != 123;
    link($_[0]);
}

sub lseek {
    unimpl "lseek(xxx)", caller if @_ != 123;
    lseek($_[0]);
}

sub pathconf {
    unimpl "pathconf(xxx)", caller if @_ != 123;
    pathconf($_[0]);
}

sub pause {
    unimpl "pause(xxx)", caller if @_ != 123;
    pause($_[0]);
}

sub pipe {
    unimpl "pipe(xxx)", caller if @_ != 123;
    pipe($_[0]);
}

sub read {
    unimpl "read(xxx)", caller if @_ != 123;
    read($_[0]);
}

sub rmdir {
    unimpl "rmdir(xxx)", caller if @_ != 123;
    rmdir($_[0]);
}

sub setgid {
    unimpl "setgid(xxx)", caller if @_ != 123;
    setgid($_[0]);
}

sub setpgid {
    unimpl "setpgid(xxx)", caller if @_ != 123;
    setpgid($_[0]);
}

sub setsid {
    unimpl "setsid(xxx)", caller if @_ != 123;
    setsid($_[0]);
}

sub setuid {
    unimpl "setuid(xxx)", caller if @_ != 123;
    setuid($_[0]);
}

sub sleep {
    unimpl "sleep(xxx)", caller if @_ != 123;
    sleep($_[0]);
}

sub sysconf {
    unimpl "sysconf(xxx)", caller if @_ != 123;
    sysconf($_[0]);
}

sub tcgetpgrp {
    unimpl "tcgetpgrp(xxx)", caller if @_ != 123;
    tcgetpgrp($_[0]);
}

sub tcsetpgrp {
    unimpl "tcsetpgrp(xxx)", caller if @_ != 123;
    tcsetpgrp($_[0]);
}

sub ttyname {
    unimpl "ttyname(xxx)", caller if @_ != 123;
    ttyname($_[0]);
}

sub unlink {
    unimpl "unlink(xxx)", caller if @_ != 123;
    unlink($_[0]);
}

sub write {
    unimpl "write(xxx)", caller if @_ != 123;
    write($_[0]);
}

sub utime {
    unimpl "utime(xxx)", caller if @_ != 123;
    utime($_[0]);
}

