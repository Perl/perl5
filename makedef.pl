#
# Create the export list for perl.
#
# Needed by WIN32 and OS/2 for creating perl.dll,
# and by AIX for creating libperl.a when -Dusershrplib is in effect,
# and by MacOS Classic.
#
# reads global.sym, pp.sym, perlvars.h, intrpvar.h, thrdvar.h, config.h
# On OS/2 reads miniperl.map as well

my $PLATFORM;
my $CCTYPE;

my %bincompat5005 =
      (
       Perl_call_atexit		=>	"perl_atexit",
       Perl_eval_sv		=>	"perl_eval_sv",
       Perl_eval_pv		=>	"perl_eval_pv",
       Perl_call_argv		=>	"perl_call_argv",
       Perl_call_method		=>	"perl_call_method",
       Perl_call_pv		=>	"perl_call_pv",
       Perl_call_sv		=>	"perl_call_sv",
       Perl_get_av		=>	"perl_get_av",
       Perl_get_cv		=>	"perl_get_cv",
       Perl_get_hv		=>	"perl_get_hv",
       Perl_get_sv		=>	"perl_get_sv",
       Perl_init_i18nl10n	=>	"perl_init_i18nl10n",
       Perl_init_i18nl14n	=>	"perl_init_i18nl14n",
       Perl_new_collate		=>	"perl_new_collate",
       Perl_new_ctype		=>	"perl_new_ctype",
       Perl_new_numeric		=>	"perl_new_numeric",
       Perl_require_pv		=>	"perl_require_pv",
       Perl_safesyscalloc	=>	"Perl_safecalloc",
       Perl_safesysfree		=>	"Perl_safefree",
       Perl_safesysmalloc	=>	"Perl_safemalloc",
       Perl_safesysrealloc	=>	"Perl_saferealloc",
       Perl_set_numeric_local	=>	"perl_set_numeric_local",
       Perl_set_numeric_standard  =>	"perl_set_numeric_standard",
       Perl_malloc		=>	"malloc",
       Perl_mfree		=>	"free",
       Perl_realloc		=>	"realloc",
       Perl_calloc		=>	"calloc",
      );

my $bincompat5005 = join("|", keys %bincompat5005);

while (@ARGV) {
    my $flag = shift;
    $define{$1} = 1 if ($flag =~ /^-D(\w+)$/);
    $define{$1} = $2 if ($flag =~ /^-D(\w+)=(.+)$/);
    $CCTYPE   = $1 if ($flag =~ /^CCTYPE=(\w+)$/);
    $PLATFORM = $1 if ($flag =~ /^PLATFORM=(\w+)$/);
	if ($PLATFORM eq 'netware') {
		$FILETYPE = $1 if ($flag =~ /^FILETYPE=(\w+)$/);
	}
}

my @PLATFORM = qw(aix win32 os2 MacOS netware);
my %PLATFORM;
@PLATFORM{@PLATFORM} = ();

defined $PLATFORM || die "PLATFORM undefined, must be one of: @PLATFORM\n";
exists $PLATFORM{$PLATFORM} || die "PLATFORM must be one of: @PLATFORM\n";

my $config_sh   = "config.sh";
my $config_h    = "config.h";
my $thrdvar_h   = "thrdvar.h";
my $intrpvar_h  = "intrpvar.h";
my $perlvars_h  = "perlvars.h";
my $global_sym  = "global.sym";
my $pp_sym      = "pp.sym";
my $globvar_sym = "globvar.sym";
my $perlio_sym  = "perlio.sym";

if ($PLATFORM eq 'aix') {
    # Nothing for now.
}
elsif ($PLATFORM eq 'win32' || $PLATFORM eq 'netware') {
    $CCTYPE = "MSVC" unless defined $CCTYPE;
    foreach ($thrdvar_h, $intrpvar_h, $perlvars_h, $global_sym,
		$pp_sym, $globvar_sym, $perlio_sym) {
	s!^!..\\!;
    }
}
elsif ($PLATFORM eq 'MacOS') {
    foreach ($thrdvar_h, $intrpvar_h, $perlvars_h, $global_sym,
		$pp_sym, $globvar_sym, $perlio_sym) {
	s!^!::!;
    }
}

unless ($PLATFORM eq 'win32' || $PLATFORM eq 'MacOS' || $PLATFORM eq 'netware') {
    open(CFG,$config_sh) || die "Cannot open $config_sh: $!\n";
    while (<CFG>) {
	if (/^(?:ccflags|optimize)='(.+)'$/) {
	    $_ = $1;
	    $define{$1} = 1 while /-D(\w+)/g;
	}
	if ($PLATFORM eq 'os2') {
	    $CONFIG_ARGS = $1 if /^(?:config_args)='(.+)'$/;
	    $ARCHNAME =    $1 if /^(?:archname)='(.+)'$/;
	}
    }
    close(CFG);
}

open(CFG,$config_h) || die "Cannot open $config_h: $!\n";
while (<CFG>) {
    $define{$1} = 1 if /^\s*#\s*define\s+(MYMALLOC)\b/;
    $define{$1} = 1 if /^\s*#\s*define\s+(MULTIPLICITY)\b/;
    $define{$1} = 1 if /^\s*#\s*define\s+(PERL_\w+)\b/;
    $define{$1} = 1 if /^\s*#\s*define\s+(USE_\w+)\b/;
}
close(CFG);

# perl.h logic duplication begins

if ($define{USE_ITHREADS}) {
    if (!$define{MULTIPLICITY} && !$define{PERL_OBJECT}) {
        $define{MULTIPLICITY} = 1;
    }
}

$define{PERL_IMPLICIT_CONTEXT} ||=
    $define{USE_ITHREADS} ||
    $define{USE_5005THREADS}  ||
    $define{MULTIPLICITY} ;

if ($define{PERL_CAPI}) {
    delete $define{PERL_OBJECT};
    $define{MULTIPLICITY} = 1;
    $define{PERL_IMPLICIT_CONTEXT} = 1;
    $define{PERL_IMPLICIT_SYS}     = 1;
}

if ($define{PERL_OBJECT}) {
    $define{PERL_IMPLICIT_CONTEXT} = 1;
    $define{PERL_IMPLICIT_SYS}     = 1;
}

# perl.h logic duplication ends

if ($PLATFORM eq 'win32') {
    warn join(' ',keys %define)."\n";
    print "LIBRARY Perl57\n";
    print "DESCRIPTION 'Perl interpreter'\n";
    print "EXPORTS\n";
    if ($define{PERL_IMPLICIT_SYS}) {
	output_symbol("perl_get_host_info");
	output_symbol("perl_alloc_override");
    output_symbol("perl_clone_host");
    }
}
elsif ($PLATFORM eq 'os2') {
    ($v = $]) =~ s/(\d\.\d\d\d)(\d\d)$/$1_$2/;
    $v .= '-thread' if $ARCHNAME =~ /-thread/;
    ($dll = $define{PERL_DLL}) =~ s/\.dll$//i;
    $d = "DESCRIPTION '\@#perl5-porters\@perl.org:$v#\@ Perl interpreter, configured as $CONFIG_ARGS'";
    $d = substr($d, 0, 249) . "...'" if length $d > 253;
    print <<"---EOP---";
LIBRARY '$dll' INITINSTANCE TERMINSTANCE
$d
STACKSIZE 32768
CODE LOADONCALL
DATA LOADONCALL NONSHARED MULTIPLE
EXPORTS
---EOP---
}
elsif ($PLATFORM eq 'aix') {
    $OSVER = `uname -v`;
    chop $OSVER;
    $OSREL = `uname -r`;
    chop $OSREL;
    if ($OSVER > 4 || ($OSVER == 4 && $OSREL >= 3)) {
	print "#! ..\n";
    } else {
	print "#!\n";
    }
}
elsif ($PLATFORM eq 'netware') {
	if ($FILETYPE eq 'def') {
	print "LIBRARY Perl57\n";
	print "DESCRIPTION 'Perl interpreter for NetWare'\n";
	print "EXPORTS\n";
	}
	if ($define{PERL_IMPLICIT_SYS}) {
	output_symbol("perl_get_host_info");
	output_symbol("perl_alloc_override");
    output_symbol("perl_clone_host");
	}
}

my %skip;
my %export;

sub skip_symbols {
    my $list = shift;
    foreach my $symbol (@$list) {
	$skip{$symbol} = 1;
    }
}

sub emit_symbols {
    my $list = shift;
    foreach my $symbol (@$list) {
	my $skipsym = $symbol;
	# XXX hack
	if ($define{PERL_OBJECT} || $define{MULTIPLICITY}) {
	    $skipsym =~ s/^Perl_[GIT](\w+)_ptr$/PL_$1/;
	}
	emit_symbol($symbol) unless exists $skip{$skipsym};
    }
}

if ($PLATFORM eq 'win32') {
    skip_symbols [qw(
		     PL_statusvalue_vms
		     PL_archpat_auto
		     PL_cryptseen
		     PL_DBcv
		     PL_generation
		     PL_lastgotoprobe
		     PL_linestart
		     PL_modcount
		     PL_pending_ident
		     PL_sortcxix
		     PL_sublex_info
		     PL_timesbuf
		     main
		     Perl_ErrorNo
		     Perl_GetVars
		     Perl_do_exec3
		     Perl_do_ipcctl
		     Perl_do_ipcget
		     Perl_do_msgrcv
		     Perl_do_msgsnd
		     Perl_do_semop
		     Perl_do_shmio
		     Perl_dump_fds
		     Perl_init_thread_intern
		     Perl_my_bzero
		     Perl_my_bcopy
		     Perl_my_htonl
		     Perl_my_ntohl
		     Perl_my_swap
		     Perl_my_chsize
		     Perl_same_dirent
		     Perl_setenv_getix
		     Perl_unlnk
		     Perl_watch
		     Perl_safexcalloc
		     Perl_safexmalloc
		     Perl_safexfree
		     Perl_safexrealloc
		     Perl_my_memcmp
		     Perl_my_memset
		     PL_cshlen
		     PL_cshname
		     PL_opsave
		     Perl_do_exec
		     Perl_getenv_len
		     Perl_my_pclose
		     Perl_my_popen
		     )];
}
elsif ($PLATFORM eq 'aix') {
    skip_symbols([qw(
		     Perl_dump_fds
		     Perl_ErrorNo
		     Perl_GetVars
		     Perl_my_bcopy
		     Perl_my_bzero
		     Perl_my_chsize
		     Perl_my_htonl
		     Perl_my_memcmp
		     Perl_my_memset
		     Perl_my_ntohl
		     Perl_my_swap
		     Perl_safexcalloc
		     Perl_safexfree
		     Perl_safexmalloc
		     Perl_safexrealloc
		     Perl_same_dirent
		     Perl_unlnk
		     Perl_sys_intern_clear
		     Perl_sys_intern_dup
		     Perl_sys_intern_init
		     PL_cryptseen
		     PL_opsave
		     PL_statusvalue_vms
		     PL_sys_intern
		     )]);
}
elsif ($PLATFORM eq 'os2') {
    emit_symbols([qw(
		    ctermid
		    get_sysinfo
		    Perl_OS2_init
		    OS2_Perl_data
		    dlopen
		    dlsym
		    dlerror
		    dlclose
		    my_tmpfile
		    my_tmpnam
		    my_flock
		    my_rmdir
		    my_mkdir
		    my_getpwuid
		    my_getpwnam
		    my_getpwent
		    my_setpwent
		    my_endpwent
		    setgrent
		    endgrent
		    getgrent
		    malloc_mutex
		    threads_mutex
		    nthreads
		    nthreads_cond
		    os2_cond_wait
		    os2_stat
		    pthread_join
		    pthread_create
		    pthread_detach
		    XS_Cwd_change_drive
		    XS_Cwd_current_drive
		    XS_Cwd_extLibpath
		    XS_Cwd_extLibpath_set
		    XS_Cwd_sys_abspath
		    XS_Cwd_sys_chdir
		    XS_Cwd_sys_cwd
		    XS_Cwd_sys_is_absolute
		    XS_Cwd_sys_is_relative
		    XS_Cwd_sys_is_rooted
		    XS_DynaLoader_mod2fname
		    XS_File__Copy_syscopy
		    Perl_Register_MQ
		    Perl_Deregister_MQ
		    Perl_Serve_Messages
		    Perl_Process_Messages
		    init_PMWIN_entries
		    PMWIN_entries
		    Perl_hab_GET
		    loadByOrdinal
		    pExtFCN
		    )]);
}
elsif ($PLATFORM eq 'MacOS') {
    skip_symbols [qw(
		    Perl_GetVars
		    PL_cryptseen
		    PL_cshlen
		    PL_cshname
		    PL_statusvalue_vms
		    PL_sys_intern
		    PL_opsave
		    PL_timesbuf
		    Perl_dump_fds
		    Perl_my_bcopy
		    Perl_my_bzero
		    Perl_my_chsize
		    Perl_my_htonl
		    Perl_my_memcmp
		    Perl_my_memset
		    Perl_my_ntohl
		    Perl_my_swap
		    Perl_safexcalloc
		    Perl_safexfree
		    Perl_safexmalloc
		    Perl_safexrealloc
		    Perl_unlnk
		    Perl_sys_intern_clear
		    Perl_sys_intern_init
		    )];
}
elsif ($PLATFORM eq 'netware') {
	skip_symbols [qw(
			PL_statusvalue_vms
			PL_archpat_auto
			PL_cryptseen
			PL_DBcv
			PL_generation
			PL_lastgotoprobe
			PL_linestart
			PL_modcount
			PL_pending_ident
			PL_sortcxix
			PL_sublex_info
			PL_timesbuf
			main
			Perl_ErrorNo
			Perl_GetVars
			Perl_do_exec3
			Perl_do_ipcctl
			Perl_do_ipcget
			Perl_do_msgrcv
			Perl_do_msgsnd
			Perl_do_semop
			Perl_do_shmio
			Perl_dump_fds
			Perl_init_thread_intern
			Perl_my_bzero
			Perl_my_htonl
			Perl_my_ntohl
			Perl_my_swap
			Perl_my_chsize
			Perl_same_dirent
			Perl_setenv_getix
			Perl_unlnk
			Perl_watch
			Perl_safexcalloc
			Perl_safexmalloc
			Perl_safexfree
			Perl_safexrealloc
			Perl_my_memcmp
			Perl_my_memset
			PL_cshlen
			PL_cshname
			PL_opsave
			Perl_do_exec
			Perl_getenv_len
			Perl_my_pclose
			Perl_my_popen
			)];
}

unless ($define{'DEBUGGING'}) {
    skip_symbols [qw(
		    Perl_deb_growlevel
		    Perl_debop
		    Perl_debprofdump
		    Perl_debstack
		    Perl_debstackptrs
		    Perl_runops_debug
		    Perl_sv_peek
		    PL_block_type
		    PL_watchaddr
		    PL_watchok
		    )];
}

if ($define{'PERL_IMPLICIT_SYS'}) {
    skip_symbols [qw(
		    Perl_getenv_len
		    Perl_my_popen
		    Perl_my_pclose
		    )];
}
else {
    skip_symbols [qw(
		    PL_Mem
		    PL_MemShared
		    PL_MemParse
		    PL_Env
		    PL_StdIO
		    PL_LIO
		    PL_Dir
		    PL_Sock
		    PL_Proc
		    )];
}

unless ($define{'PERL_FLEXIBLE_EXCEPTIONS'}) {
    skip_symbols [qw(
		    PL_protect
		    Perl_default_protect
		    Perl_vdefault_protect
		    )];
}

if ($define{'MYMALLOC'}) {
    emit_symbols [qw(
		    Perl_dump_mstats
		    Perl_get_mstats
		    Perl_strdup
		    Perl_putenv
		    )];
    if ($define{'USE_5005THREADS'} || $define{'USE_ITHREADS'}) {
	emit_symbols [qw(
			PL_malloc_mutex
			)];
    }
    else {
	skip_symbols [qw(
			PL_malloc_mutex
			)];
    }
}
else {
    skip_symbols [qw(
		    PL_malloc_mutex
		    Perl_dump_mstats
		    Perl_get_mstats
		    Perl_malloced_size
		    )];
}

unless ($define{'USE_5005THREADS'} || $define{'USE_ITHREADS'}) {
    skip_symbols [qw(
		    PL_thr_key
		    )];
}

unless ($define{'USE_5005THREADS'}) {
    skip_symbols [qw(
		    PL_sv_mutex
		    PL_strtab_mutex
		    PL_svref_mutex
		    PL_cred_mutex
		    PL_eval_mutex
		    PL_fdpid_mutex
		    PL_sv_lock_mutex
		    PL_eval_cond
		    PL_eval_owner
		    PL_threads_mutex
		    PL_nthreads
		    PL_nthreads_cond
		    PL_threadnum
		    PL_threadsv_names
		    PL_thrsv
		    PL_vtbl_mutex
		    Perl_condpair_magic
		    Perl_new_struct_thread
		    Perl_per_thread_magicals
		    Perl_thread_create
		    Perl_find_threadsv
		    Perl_unlock_condpair
		    Perl_magic_mutexfree
		    Perl_sv_lock
		    )];
}

unless ($define{'USE_ITHREADS'}) {
    skip_symbols [qw(
		    PL_ptr_table
		    PL_op_mutex
		    Perl_dirp_dup
		    Perl_cx_dup
		    Perl_si_dup
		    Perl_any_dup
		    Perl_ss_dup
		    Perl_fp_dup
		    Perl_gp_dup
		    Perl_he_dup
		    Perl_mg_dup
		    Perl_re_dup
		    Perl_sv_dup
		    Perl_sys_intern_dup
		    Perl_ptr_table_clear
		    Perl_ptr_table_fetch
		    Perl_ptr_table_free
		    Perl_ptr_table_new
		    Perl_ptr_table_clear
		    Perl_ptr_table_free
		    Perl_ptr_table_split
		    Perl_ptr_table_store
		    perl_clone
		    perl_clone_using
		    )];
}

unless ($define{'PERL_IMPLICIT_CONTEXT'}) {
    skip_symbols [qw(
		    Perl_croak_nocontext
		    Perl_die_nocontext
		    Perl_deb_nocontext
		    Perl_form_nocontext
		    Perl_load_module_nocontext
		    Perl_mess_nocontext
		    Perl_warn_nocontext
		    Perl_warner_nocontext
		    Perl_newSVpvf_nocontext
		    Perl_sv_catpvf_nocontext
		    Perl_sv_setpvf_nocontext
		    Perl_sv_catpvf_mg_nocontext
		    Perl_sv_setpvf_mg_nocontext
		    )];
}

unless ($define{'PERL_IMPLICIT_SYS'}) {
    skip_symbols [qw(
		    perl_alloc_using
		    perl_clone_using
		    )];
}

unless ($define{'FAKE_THREADS'}) {
    skip_symbols [qw(PL_curthr)];
}

sub readvar {
    my $file = shift;
    my $proc = shift || sub { "PL_$_[2]" };
    open(VARS,$file) || die "Cannot open $file: $!\n";
    my @syms;
    while (<VARS>) {
	# All symbols have a Perl_ prefix because that's what embed.h
	# sticks in front of them.
	push(@syms, &$proc($1,$2,$3)) if (/\bPERLVAR(A?I?C?)\(([IGT])(\w+)/);
    }
    close(VARS);
    return \@syms;
}

if ($define{'USE_5005THREADS'}) {
    my $thrd = readvar($thrdvar_h);
    skip_symbols $thrd;
}

if ($define{'PERL_GLOBAL_STRUCT'}) {
    my $global = readvar($perlvars_h);
    skip_symbols $global;
    emit_symbol('Perl_GetVars');
    emit_symbols [qw(PL_Vars PL_VarsPtr)] unless $CCTYPE eq 'GCC';
}

# functions from *.sym files

my @syms = ($global_sym, $globvar_sym); # $pp_sym is not part of the API

my @layer_syms = qw(
			 PerlIOBase_clearerr
			 PerlIOBase_close
			 PerlIOBase_eof
			 PerlIOBase_error
			 PerlIOBase_fileno
			 PerlIOBase_setlinebuf
			 PerlIOBase_pushed
			 PerlIOBase_read
		         PerlIOBase_unread
			 PerlIOBuf_bufsiz
			 PerlIOBuf_fill
			 PerlIOBuf_flush
			 PerlIOBuf_get_cnt
			 PerlIOBuf_get_ptr
			 PerlIOBuf_open
			 PerlIOBuf_pushed
			 PerlIOBuf_read
			 PerlIOBuf_seek
			 PerlIOBuf_set_ptrcnt
			 PerlIOBuf_tell
			 PerlIOBuf_unread
			 PerlIOBuf_write
			 PerlIO_define_layer
			 PerlIO_arg_fetch
			 PerlIO_pending
			 PerlIO_allocate
			 PerlIO_push
			 PerlIO_unread
);

if ($define{'USE_PERLIO'}) {
    push @syms, $perlio_sym;
    if ($define{'USE_SFIO'}) {
	skip_symbols \@layer_syms;
	# SFIO defines most of the PerlIO routines as macros
	skip_symbols [qw(
			 PerlIO_canset_cnt
			 PerlIO_clearerr
			 PerlIO_close
			 PerlIO_eof
			 PerlIO_error
			 PerlIO_exportFILE
			 PerlIO_fast_gets
			 PerlIO_fdopen
			 PerlIO_fileno
			 PerlIO_findFILE
			 PerlIO_flush
			 PerlIO_get_base
			 PerlIO_get_bufsiz
			 PerlIO_get_cnt
			 PerlIO_get_ptr
			 PerlIO_getc
			 PerlIO_getname
			 PerlIO_has_base
			 PerlIO_has_cntptr
			 PerlIO_importFILE
			 PerlIO_open
			 PerlIO_printf
			 PerlIO_putc
			 PerlIO_puts
			 PerlIO_read
			 PerlIO_releaseFILE
			 PerlIO_reopen
			 PerlIO_rewind
			 PerlIO_seek
			 PerlIO_set_cnt
			 PerlIO_set_ptrcnt
			 PerlIO_setlinebuf
			 PerlIO_sprintf
			 PerlIO_stderr
			 PerlIO_stdin
			 PerlIO_stdout
			 PerlIO_stdoutf
			 PerlIO_tell
			 PerlIO_ungetc
			 PerlIO_vprintf
			 PerlIO_write
			 )];
    }
} else {
	# Skip the PerlIO New Generation symbols.
	skip_symbols \@layer_syms;
}

for my $syms (@syms) {
    open (GLOBAL, "<$syms") || die "failed to open $syms: $!\n";
    while (<GLOBAL>) {
	next if (!/^[A-Za-z]/);
	# Functions have a Perl_ prefix
	# Variables have a PL_ prefix
	chomp($_);
	my $symbol = ($syms =~ /var\.sym$/i ? "PL_" : "");
	$symbol .= $_;
	emit_symbol($symbol) unless exists $skip{$symbol};
    }
    close(GLOBAL);
}

# variables

if ($define{'PERL_OBJECT'} || $define{'MULTIPLICITY'}) {
    for my $f ($perlvars_h, $intrpvar_h, $thrdvar_h) {
	my $glob = readvar($f, sub { "Perl_" . $_[1] . $_[2] . "_ptr" });
	emit_symbols $glob;
    }
    # XXX AIX seems to want the perlvars.h symbols, for some reason
    if ($PLATFORM eq 'aix') {
	my $glob = readvar($perlvars_h);
	emit_symbols $glob;
    }
}
else {
    unless ($define{'PERL_GLOBAL_STRUCT'}) {
	my $glob = readvar($perlvars_h);
	emit_symbols $glob;
    }
    unless ($define{'MULTIPLICITY'}) {
	my $glob = readvar($intrpvar_h);
	emit_symbols $glob;
    }
    unless ($define{'MULTIPLICITY'} || $define{'USE_5005THREADS'}) {
	my $glob = readvar($thrdvar_h);
	emit_symbols $glob;
    }
}

sub try_symbol {
    my $symbol = shift;

    return if $symbol !~ /^[A-Za-z]/;
    return if $symbol =~ /^\#/;
    $symbol =~s/\r//g;
    chomp($symbol);
    return if exists $skip{$symbol};
    emit_symbol($symbol);
}

while (<DATA>) {
    try_symbol($_);
}

if ($PLATFORM eq 'win32') {
    foreach my $symbol (qw(
			    setuid
			    setgid
			    boot_DynaLoader
			    Perl_init_os_extras
			    Perl_thread_create
			    Perl_win32_init
			    RunPerl
			    win32_errno
			    win32_environ
			    win32_abort
			    win32_fstat
			    win32_stat
			    win32_pipe
			    win32_popen
			    win32_pclose
			    win32_rename
			    win32_setmode
			    win32_lseek
			    win32_tell
			    win32_dup
			    win32_dup2
			    win32_open
			    win32_close
			    win32_eof
			    win32_read
			    win32_write
			    win32_spawnvp
			    win32_mkdir
			    win32_rmdir
			    win32_chdir
			    win32_flock
			    win32_execv
			    win32_execvp
			    win32_htons
			    win32_ntohs
			    win32_htonl
			    win32_ntohl
			    win32_inet_addr
			    win32_inet_ntoa
			    win32_socket
			    win32_bind
			    win32_listen
			    win32_accept
			    win32_connect
			    win32_send
			    win32_sendto
			    win32_recv
			    win32_recvfrom
			    win32_shutdown
			    win32_closesocket
			    win32_ioctlsocket
			    win32_setsockopt
			    win32_getsockopt
			    win32_getpeername
			    win32_getsockname
			    win32_gethostname
			    win32_gethostbyname
			    win32_gethostbyaddr
			    win32_getprotobyname
			    win32_getprotobynumber
			    win32_getservbyname
			    win32_getservbyport
			    win32_select
			    win32_endhostent
			    win32_endnetent
			    win32_endprotoent
			    win32_endservent
			    win32_getnetent
			    win32_getnetbyname
			    win32_getnetbyaddr
			    win32_getprotoent
			    win32_getservent
			    win32_sethostent
			    win32_setnetent
			    win32_setprotoent
			    win32_setservent
			    win32_getenv
			    win32_putenv
			    win32_perror
			    win32_malloc
			    win32_calloc
			    win32_realloc
			    win32_free
			    win32_sleep
			    win32_times
			    win32_access
			    win32_alarm
			    win32_chmod
			    win32_open_osfhandle
			    win32_get_osfhandle
			    win32_ioctl
			    win32_link
			    win32_unlink
			    win32_utime
			    win32_uname
			    win32_wait
			    win32_waitpid
			    win32_kill
			    win32_str_os_error
			    win32_opendir
			    win32_readdir
			    win32_telldir
			    win32_seekdir
			    win32_rewinddir
			    win32_closedir
			    win32_longpath
			    win32_os_id
			    win32_getpid
			    win32_crypt
			    win32_dynaload

			    win32_stdin
			    win32_stdout
			    win32_stderr
			    win32_ferror
			    win32_feof
			    win32_strerror
			    win32_fprintf
			    win32_printf
			    win32_vfprintf
			    win32_vprintf
			    win32_fread
			    win32_fwrite
			    win32_fopen
			    win32_fdopen
			    win32_freopen
			    win32_fclose
			    win32_fputs
			    win32_fputc
			    win32_ungetc
			    win32_getc
			    win32_fileno
			    win32_clearerr
			    win32_fflush
			    win32_ftell
			    win32_fseek
			    win32_fgetpos
			    win32_fsetpos
			    win32_rewind
			    win32_tmpfile
			    win32_setbuf
			    win32_setvbuf
			    win32_flushall
			    win32_fcloseall
			    win32_fgets
			    win32_gets
			    win32_fgetc
			    win32_putc
			    win32_puts
			    win32_getchar
			    win32_putchar
			   ))
    {
	try_symbol($symbol);
    }
}
elsif ($PLATFORM eq 'os2') {
    open MAP, 'miniperl.map' or die 'Cannot read miniperl.map';
    /^\s*[\da-f:]+\s+(\w+)/i and $mapped{$1}++ foreach <MAP>;
    close MAP or die 'Cannot close miniperl.map';

    @missing = grep { !exists $mapped{$_} and !exists $bincompat5005{$_} }
		    keys %export;
    delete $export{$_} foreach @missing;
}
elsif ($PLATFORM eq 'MacOS') {
    open MACSYMS, 'macperl.sym' or die 'Cannot read macperl.sym';

    while (<MACSYMS>) {
	try_symbol($_);
    }

    close MACSYMS;
}
elsif ($PLATFORM eq 'netware') {
foreach my $symbol (qw(
			boot_DynaLoader
			Perl_init_os_extras
			Perl_thread_create
			Perl_nw5_init
			RunPerl
			AllocStdPerl
			FreeStdPerl
			do_spawn2
			do_aspawn
			nw_uname
			nw_stdin
			nw_stdout
			nw_stderr
			nw_feof
			nw_ferror
			nw_fopen
			nw_fclose
			nw_clearerr
			nw_getc
			nw_fgets
			nw_fputc
			nw_fputs
			nw_fflush
			nw_ungetc
			nw_fileno
			nw_fdopen
			nw_freopen
			nw_fread
			nw_fwrite
			nw_setbuf
			nw_setvbuf
			nw_vfprintf
			nw_ftell
			nw_fseek
			nw_rewind
			nw_tmpfile
			nw_fgetpos
			nw_fsetpos
			nw_dup
			nw_access
			nw_chmod
			nw_chsize
			nw_close
			nw_dup2
			nw_flock
			nw_isatty
			nw_link
			nw_lseek
			nw_stat
			nw_mktemp
			nw_open
			nw_read
			nw_rename
			nw_setmode
			nw_unlink
			nw_utime
			nw_write
			nw_chdir
			nw_rmdir
			nw_closedir
			nw_opendir
			nw_readdir
			nw_rewinddir
			nw_seekdir
			nw_telldir
			nw_htonl
			nw_htons
			nw_ntohl
			nw_ntohs
			nw_accept
			nw_bind
			nw_connect
			nw_endhostent
			nw_endnetent
			nw_endprotoent
			nw_endservent
			nw_gethostbyaddr
			nw_gethostbyname
			nw_gethostent
			nw_gethostname
			nw_getnetbyaddr
			nw_getnetbyname
			nw_getnetent
			nw_getpeername
			nw_getprotobyname
			nw_getprotobynumber
			nw_getprotoent
			nw_getservbyname
			nw_getservbyport
			nw_getservent
			nw_getsockname
			nw_getsockopt
			nw_inet_addr
			nw_listen
			nw_socket
			nw_recv
			nw_recvfrom
			nw_select
			nw_send
			nw_sendto
			nw_sethostent
			nw_setnetent
			nw_setprotoent
			nw_setservent
			nw_shutdown
			nw_crypt
			nw_execvp
			nw_kill
			nw_Popen
			nw_Pclose
			nw_Pipe
			nw_times
			nw_waitpid
			nw_getpid
			nw_spawnvp
			nw_os_id
			nw_open_osfhandle
			nw_get_osfhandle
			nw_abort
			nw_sleep
			nw_wait
			nw_dynaload
			nw_strerror
			fnFpSetMode
			fnInsertHashListAddrs
			fnGetHashListAddrs
			Perl_deb
			   ))
    {
	try_symbol($symbol);
    }
}

# Now all symbols should be defined because
# next we are going to output them.

foreach my $symbol (sort keys %export) {
    output_symbol($symbol);
}

if ($PLATFORM eq 'netware') {
	# This may not be the right way to do.  This is to make sure
	# that the last symbol will not contain a comma else
	# Watcom linker cribs
	print "\tdummy\n";
}

sub emit_symbol {
    my $symbol = shift;
    chomp($symbol);
    $export{$symbol} = 1;
}

my $sym_ord = 0;

sub output_symbol {
    my $symbol = shift;
    $symbol = $bincompat5005{$symbol}
	if $define{PERL_BINCOMPAT_5005} and $symbol =~ /^($bincompat5005)$/;
    if ($PLATFORM eq 'win32') {
	$symbol = "_$symbol" if $CCTYPE eq 'BORLAND';
	print "\t$symbol\n";
# XXX: binary compatibility between compilers is an exercise
# in frustration :-(
#        if ($CCTYPE eq "BORLAND") {
#	    # workaround Borland quirk by exporting both the straight
#	    # name and a name with leading underscore.  Note the
#	    # alias *must* come after the symbol itself, if both
#	    # are to be exported. (Linker bug?)
#	    print "\t_$symbol\n";
#	    print "\t$symbol = _$symbol\n";
#	}
#	elsif ($CCTYPE eq 'GCC') {
#	    # Symbols have leading _ whole process is $%@"% slow
#	    # so skip aliases for now
#	    nprint "\t$symbol\n";
#	}
#	else {
#	    # for binary coexistence, export both the symbol and
#	    # alias with leading underscore
#	    print "\t$symbol\n";
#	    print "\t_$symbol = $symbol\n";
#	}
    }
    elsif ($PLATFORM eq 'os2') {
	printf qq(    %-31s \@%s\n), qq("$symbol"), ++$sym_ord;
    }
    elsif ($PLATFORM eq 'aix' || $PLATFORM eq 'MacOS') {
	print "$symbol\n";
    }
	elsif ($PLATFORM eq 'netware') {
	print "\t$symbol,\n";
	}
}

1;
__DATA__
# extra globals not included above.
perl_alloc
perl_alloc_using
perl_clone
perl_clone_using
perl_construct
perl_destruct
perl_free
perl_parse
perl_run
PerlIO_define_layer
PerlIOBuf_set_ptrcnt
PerlIOBuf_get_cnt
PerlIOBuf_get_ptr
PerlIOBuf_bufsiz
PerlIOBase_clearerr
PerlIOBase_setlinebuf
PerlIOBase_pushed
PerlIOBase_read
PerlIOBase_unread
PerlIOBase_error
PerlIOBase_eof
PerlIOBuf_tell
PerlIOBuf_seek
PerlIOBuf_write
PerlIOBuf_unread
PerlIOBuf_read
PerlIOBuf_open
PerlIOBase_fileno
PerlIOBuf_pushed
PerlIOBuf_fill
PerlIOBuf_flush
PerlIOBase_close
PerlIO_define_layer
PerlIO_pending
PerlIO_unread
PerlIO_push
PerlIO_allocate
PerlIO_arg_fetch
PerlIO_apply_layers
perlsio_binmode
PerlIO_binmode
PerlIO_init
PerlIO_tmpfile
PerlIO_setpos
PerlIO_getpos
PerlIO_vsprintf
PerlIO_sprintf
