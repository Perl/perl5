package Config;
require Exporter;
@ISA = (Exporter);
@EXPORT = qw(%Config);

$] == 5.000 or die sprintf
    "Perl lib version (5.000) doesn't match executable version (%.3f)\n", $];

# config.sh
# This file was produced by running the Configure script.
$Config{'d_eunice'} = undef;
$Config{'define'} = 'define';
$Config{'eunicefix'} = ':';
$Config{'loclist'} = '
cat
cp
echo
expr
grep
mkdir
mv
rm
sed
sort
tr
uniq
';
$Config{'expr'} = '/bin/expr';
$Config{'sed'} = '/bin/sed';
$Config{'echo'} = '/bin/echo';
$Config{'cat'} = '/bin/cat';
$Config{'rm'} = '/bin/rm';
$Config{'mv'} = '/bin/mv';
$Config{'cp'} = '/bin/cp';
$Config{'tail'} = '';
$Config{'tr'} = '/bin/tr';
$Config{'mkdir'} = '/bin/mkdir';
$Config{'sort'} = '/bin/sort';
$Config{'uniq'} = '/bin/uniq';
$Config{'grep'} = '/bin/grep';
$Config{'trylist'} = '
Mcc
bison
cpp
csh
egrep
line
nroff
perl
test
uname
yacc
';
$Config{'test'} = 'test';
$Config{'inews'} = '';
$Config{'egrep'} = '/bin/egrep';
$Config{'more'} = '';
$Config{'pg'} = '';
$Config{'Mcc'} = 'Mcc';
$Config{'vi'} = '';
$Config{'mailx'} = '';
$Config{'mail'} = '';
$Config{'cpp'} = '/usr/lib/cpp';
$Config{'perl'} = '/home/netlabs1/lwall/pl/perl';
$Config{'emacs'} = '';
$Config{'ls'} = '';
$Config{'rmail'} = '';
$Config{'sendmail'} = '';
$Config{'shar'} = '';
$Config{'smail'} = '';
$Config{'tbl'} = '';
$Config{'troff'} = '';
$Config{'nroff'} = '/bin/nroff';
$Config{'uname'} = '/bin/uname';
$Config{'uuname'} = '';
$Config{'line'} = '/bin/line';
$Config{'chgrp'} = '';
$Config{'chmod'} = '';
$Config{'lint'} = '';
$Config{'sleep'} = '';
$Config{'pr'} = '';
$Config{'tar'} = '';
$Config{'ln'} = '';
$Config{'lpr'} = '';
$Config{'lp'} = '';
$Config{'touch'} = '';
$Config{'make'} = '';
$Config{'date'} = '';
$Config{'csh'} = '/bin/csh';
$Config{'bash'} = '';
$Config{'ksh'} = '';
$Config{'lex'} = '';
$Config{'flex'} = '';
$Config{'bison'} = '/usr/local/bin/bison';
$Config{'Log'} = '$Log';
$Config{'Header'} = '$Header';
$Config{'Id'} = '$Id';
$Config{'lastuname'} = 'SunOS scalpel 4.1.2 1 sun4c';
$Config{'alignbytes'} = '8';
$Config{'bin'} = '/usr/local/bin';
$Config{'installbin'} = '/usr/local/bin';
$Config{'byteorder'} = '4321';
$Config{'contains'} = 'grep';
$Config{'cppstdin'} = '/usr/lib/cpp';
$Config{'cppminus'} = '';
$Config{'d_bcmp'} = 'define';
$Config{'d_bcopy'} = 'define';
$Config{'d_safebcpy'} = 'define';
$Config{'d_bzero'} = 'define';
$Config{'d_castneg'} = 'define';
$Config{'castflags'} = '0';
$Config{'d_charsprf'} = 'define';
$Config{'d_chsize'} = undef;
$Config{'d_crypt'} = 'define';
$Config{'cryptlib'} = '';
$Config{'d_csh'} = 'define';
$Config{'d_dosuid'} = undef;
$Config{'d_dup2'} = 'define';
$Config{'d_fchmod'} = 'define';
$Config{'d_fchown'} = 'define';
$Config{'d_fcntl'} = 'define';
$Config{'d_flexfnam'} = 'define';
$Config{'d_flock'} = 'define';
$Config{'d_getgrps'} = 'define';
$Config{'d_gethent'} = undef;
$Config{'d_getpgrp'} = 'define';
$Config{'d_getpgrp2'} = undef;
$Config{'d_getprior'} = 'define';
$Config{'d_htonl'} = 'define';
$Config{'d_index'} = undef;
$Config{'d_isascii'} = 'define';
$Config{'d_killpg'} = 'define';
$Config{'d_lstat'} = 'define';
$Config{'d_memcmp'} = 'define';
$Config{'d_memcpy'} = 'define';
$Config{'d_safemcpy'} = undef;
$Config{'d_memmove'} = undef;
$Config{'d_memset'} = 'define';
$Config{'d_mkdir'} = 'define';
$Config{'d_msg'} = 'define';
$Config{'d_msgctl'} = 'define';
$Config{'d_msgget'} = 'define';
$Config{'d_msgrcv'} = 'define';
$Config{'d_msgsnd'} = 'define';
$Config{'d_ndbm'} = 'define';
$Config{'d_odbm'} = 'define';
$Config{'d_open3'} = 'define';
$Config{'d_readdir'} = 'define';
$Config{'d_rename'} = 'define';
$Config{'d_rewindir'} = undef;
$Config{'d_rmdir'} = 'define';
$Config{'d_seekdir'} = 'define';
$Config{'d_select'} = 'define';
$Config{'d_sem'} = 'define';
$Config{'d_semctl'} = 'define';
$Config{'d_semget'} = 'define';
$Config{'d_semop'} = 'define';
$Config{'d_setegid'} = 'define';
$Config{'d_seteuid'} = 'define';
$Config{'d_setpgrp'} = 'define';
$Config{'d_setpgrp2'} = undef;
$Config{'d_setprior'} = 'define';
$Config{'d_setregid'} = 'define';
$Config{'d_setresgid'} = undef;
$Config{'d_setreuid'} = 'define';
$Config{'d_setresuid'} = undef;
$Config{'d_setrgid'} = 'define';
$Config{'d_setruid'} = 'define';
$Config{'d_shm'} = 'define';
$Config{'d_shmat'} = 'define';
$Config{'d_voidshmat'} = undef;
$Config{'d_shmctl'} = 'define';
$Config{'d_shmdt'} = 'define';
$Config{'d_shmget'} = 'define';
$Config{'d_socket'} = 'define';
$Config{'d_sockpair'} = 'define';
$Config{'d_oldsock'} = undef;
$Config{'socketlib'} = '';
$Config{'d_statblks'} = 'define';
$Config{'d_stdstdio'} = 'define';
$Config{'d_strctcpy'} = 'define';
$Config{'d_strerror'} = undef;
$Config{'d_symlink'} = 'define';
$Config{'d_syscall'} = 'define';
$Config{'d_telldir'} = 'define';
$Config{'d_truncate'} = 'define';
$Config{'d_vfork'} = 'define';
$Config{'d_voidsig'} = 'define';
$Config{'d_tosignal'} = 'int';
$Config{'d_volatile'} = undef;
$Config{'d_vprintf'} = 'define';
$Config{'d_charvspr'} = 'define';
$Config{'d_wait4'} = 'define';
$Config{'d_waitpid'} = 'define';
$Config{'gidtype'} = 'gid_t';
$Config{'groupstype'} = 'int';
$Config{'i_fcntl'} = undef;
$Config{'i_gdbm'} = undef;
$Config{'i_grp'} = 'define';
$Config{'i_niin'} = 'define';
$Config{'i_sysin'} = undef;
$Config{'i_pwd'} = 'define';
$Config{'d_pwquota'} = undef;
$Config{'d_pwage'} = 'define';
$Config{'d_pwchange'} = undef;
$Config{'d_pwclass'} = undef;
$Config{'d_pwexpire'} = undef;
$Config{'d_pwcomment'} = 'define';
$Config{'i_sys_file'} = 'define';
$Config{'i_sysioctl'} = 'define';
$Config{'i_time'} = undef;
$Config{'i_sys_time'} = 'define';
$Config{'i_sys_select'} = undef;
$Config{'d_systimekernel'} = undef;
$Config{'i_utime'} = 'define';
$Config{'i_varargs'} = 'define';
$Config{'i_vfork'} = 'define';
$Config{'intsize'} = '4';
$Config{'libc'} = '/usr/lib/libc.so.1.7';
$Config{'nm_opts'} = '';
$Config{'libndir'} = '';
$Config{'i_my_dir'} = undef;
$Config{'i_ndir'} = undef;
$Config{'i_sys_ndir'} = undef;
$Config{'i_dirent'} = 'define';
$Config{'i_sys_dir'} = undef;
$Config{'d_dirnamlen'} = undef;
$Config{'ndirc'} = '';
$Config{'ndiro'} = '';
$Config{'mallocsrc'} = 'malloc.c';
$Config{'mallocobj'} = 'malloc.o';
$Config{'d_mymalloc'} = 'define';
$Config{'mallocptrtype'} = 'char';
$Config{'mansrc'} = '/usr/man/manl';
$Config{'manext'} = 'l';
$Config{'models'} = 'none';
$Config{'split'} = '';
$Config{'small'} = '';
$Config{'medium'} = '';
$Config{'large'} = '';
$Config{'huge'} = '';
$Config{'optimize'} = '-g';
$Config{'ccflags'} = '-DDEBUGGING -DHAS_SDBM';
$Config{'cppflags'} = '-DDEBUGGING -DHAS_SDBM';
$Config{'ldflags'} = '';
$Config{'cc'} = 'cc';
$Config{'nativegcc'} = '';
$Config{'libs'} = '-ldbm -lm -lposix';
$Config{'n'} = '-n';
$Config{'c'} = '';
$Config{'package'} = 'perl';
$Config{'randbits'} = '31';
$Config{'scriptdir'} = '/usr/local/bin';
$Config{'installscr'} = '/usr/local/bin';
$Config{'sig_name'} = 'ZERO HUP INT QUIT ILL TRAP ABRT EMT FPE KILL BUS SEGV SYS PIPE ALRM TERM URG STOP TSTP CONT CLD TTIN TTOU IO XCPU XFSZ VTALRM PROF WINCH LOST USR1 USR2';
$Config{'spitshell'} = 'cat';
$Config{'shsharp'} = 'true';
$Config{'sharpbang'} = '#!';
$Config{'startsh'} = '#!/bin/sh';
$Config{'stdchar'} = 'unsigned char';
$Config{'uidtype'} = 'uid_t';
$Config{'usrinclude'} = '/usr/include';
$Config{'inclPath'} = '';
$Config{'void'} = '';
$Config{'voidhave'} = '7';
$Config{'voidwant'} = '7';
$Config{'w_localtim'} = '1';
$Config{'w_s_timevl'} = '1';
$Config{'w_s_tm'} = '1';
$Config{'yacc'} = '/bin/yacc';
$Config{'lib'} = '';
$Config{'privlib'} = '/usr/local/lib/perl';
$Config{'installprivlib'} = '/usr/local/lib/perl';
$Config{'PATCHLEVEL'} = 34;
$Config{'CONFIG'} = true
