
# creates a C API file from proto.h
# takes one argument, the path to lib/CORE directory.
# creates 2 files: "PerlCAPI.cpp" and "PerlCAPI.h".

my $hdrfile = "$ARGV[0]\\PerlCAPI.h";
my $infile = '..\\proto.h';
my $embedfile = '..\\embed.h';
my $separateObj = 0;

my %skip_list;
my %embed;

sub readembed(\%$) {
    my ($syms, $file) = @_;
    my ($line, @words);
    %$syms = ();
    local (*FILE, $_);
    open(FILE, "< $file")
	or die "$0: Can't open $file: $!\n";
    while ($line = <FILE>) {
	chop($line);
	if ($line =~ /^#define\s+\w+/) {
	    $line =~ s/^#define\s+//;
	    @words = split ' ', $line;
#	    print "$words[0]\t$words[1]\n";
	    $$syms{$words[0]} = $words[1];
	}
    }
    close(FILE);
}

readembed %embed, $embedfile;

sub skip_these {
    my $list = shift;
    foreach my $symbol (@$list) {
	$skip_list{$symbol} = 1;
    }
}

skip_these [qw(
cando
cast_ulong
my_chsize
condpair_magic
deb
deb_growlevel
debprofdump
debop
debstack
debstackptrs
fprintf
find_threadsv
magic_mutexfree
my_pclose
my_popen
my_swap
my_htonl
my_ntohl
new_struct_thread
same_dirent
unlnk
unlock_condpair
safexmalloc
safexcalloc
safexrealloc
safexfree
Perl_GetVars
)];



if (!open(INFILE, "<$infile")) {
    print "open of $infile failed: $!\n";
    return 1;
}

if (!open(OUTFILE, ">PerlCAPI.cpp")) {
    print "open of PerlCAPI.cpp failed: $!\n";
    return 1;
}

print OUTFILE "#include \"EXTERN.h\"\n#include \"perl.h\"\n#include \"XSUB.h\"\n\n";
print OUTFILE "#define DESTRUCTORFUNC (void (*)(void*))\n\n";
print OUTFILE "#ifdef SetCPerlObj_defined\n" unless ($separateObj == 0); 
print OUTFILE "extern \"C\" void SetCPerlObj(CPerlObj* pP)\n{\n\tpPerl = pP;\n}\n";
print OUTFILE "#endif\n" unless ($separateObj == 0); 

while () {
    last unless defined ($_ = <INFILE>);
    if (/^VIRTUAL\s/) {
        while (!/;$/) {
            chomp;
            $_ .= <INFILE>;
        }
        $_ =~ s/^VIRTUAL\s*//;
        $_ =~ s/\s*__attribute__.*$/;/;
        if ( /(.*)\s([A-z_]*[0-9A-z_]+\s)_\(\((.*)\)\);/ ||
             /(.*)\*([A-z_]*[0-9A-z_]+\s)_\(\((.*)\)\);/ ) {
            $type = $1;
            $name = $2;
            $args = $3;
 
            $name =~ s/\s*$//;
            $type =~ s/\s*$//;
	    next if (defined $skip_list{$name});

	    if($args eq "ARGSproto") {
		$args = "void";
	    }

            $return = ($type eq "void" or $type eq "Free_t") ? "\t" : "\treturn";

	    if(defined $embed{$name}) {
		$funcName = $embed{$name};
	    } else {
		$funcName = $name;
	    }

            @args = split(',', $args);
            if ($args[$#args] =~ /\s*\.\.\.\s*/) {
                if(($name eq "croak") or ($name eq "deb") or ($name eq "die")
		        or ($name eq "form") or ($name eq "warn")) {
                    print OUTFILE "\n#ifdef $name" . "_defined" unless ($separateObj == 0);
                    print OUTFILE "\n#undef $name\nextern \"C\" $type $funcName ($args)\n{\n";
                    $args[0] =~ /(\w+)\W*$/; 
                    $arg = $1;
                    print OUTFILE "\tva_list args;\n\tva_start(args, $arg);\n";
                    print OUTFILE "$return pPerl->Perl_$name(pPerl->Perl_mess($arg, &args));\n";
                    print OUTFILE "\tva_end(args);\n}\n";
                    print OUTFILE "#endif\n" unless ($separateObj == 0);
                }
                elsif($name eq "newSVpvf") {
                    print OUTFILE "\n#ifdef $name" . "_defined" unless ($separateObj == 0);
                    print OUTFILE "\n#undef $name\nextern \"C\" $type $funcName ($args)\n{\n";
                    $args[0] =~ /(\w+)\W*$/; 
                    $arg = $1;
                    print OUTFILE "\tSV *sv;\n\tva_list args;\n\tva_start(args, $arg);\n";
                    print OUTFILE "\tsv = pPerl->Perl_newSV(0);\n";
                    print OUTFILE "\tpPerl->Perl_sv_vcatpvfn(sv, $arg, strlen($arg), &args, NULL, 0, NULL);\n";
                    print OUTFILE "\tva_end(args);\n\treturn sv;\n}\n";
                    print OUTFILE "#endif\n" unless ($separateObj == 0);
                }
                elsif($name eq "sv_catpvf") {
                    print OUTFILE "\n#ifdef $name" . "_defined" unless ($separateObj == 0);
                    print OUTFILE "\n#undef $name\nextern \"C\" $type $funcName ($args)\n{\n";
                    $args[0] =~ /(\w+)\W*$/; 
                    $arg0 = $1;
                    $args[1] =~ /(\w+)\W*$/; 
                    $arg1 = $1;
                    print OUTFILE "\tva_list args;\n\tva_start(args, $arg1);\n";
                    print OUTFILE "\tpPerl->Perl_sv_vcatpvfn($arg0, $arg1, strlen($arg1), &args, NULL, 0, NULL);\n";
                    print OUTFILE "\tva_end(args);\n}\n";
                    print OUTFILE "#endif\n" unless ($separateObj == 0);
                }
                elsif($name eq "sv_setpvf") {
                    print OUTFILE "\n#ifdef $name" . "_defined" unless ($separateObj == 0);
                    print OUTFILE "\n#undef $name\nextern \"C\" $type $funcName ($args)\n{\n";
                    $args[0] =~ /(\w+)\W*$/; 
                    $arg0 = $1;
                    $args[1] =~ /(\w+)\W*$/; 
                    $arg1 = $1;
                    print OUTFILE "\tva_list args;\n\tva_start(args, $arg1);\n";
                    print OUTFILE "\tpPerl->Perl_sv_vsetpvfn($arg0, $arg1, strlen($arg1), &args, NULL, 0, NULL);\n";
                    print OUTFILE "\tva_end(args);\n}\n";
                    print OUTFILE "#endif\n" unless ($separateObj == 0);
                }
                elsif($name eq "fprintf") {
                    print OUTFILE "\n#ifdef $name" . "_defined" unless ($separateObj == 0);
                    print OUTFILE "\n#undef $name\nextern \"C\" $type $name ($args)\n{\n";
                    $args[0] =~ /(\w+)\W*$/; 
                    $arg0 = $1;
                    $args[1] =~ /(\w+)\W*$/; 
                    $arg1 = $1;
                    print OUTFILE "\tint nRet;\n\tva_list args;\n\tva_start(args, $arg1);\n";
                    print OUTFILE "\tnRet = PerlIO_vprintf($arg0, $arg1, args);\n";
                    print OUTFILE "\tva_end(args);\n\treturn nRet;\n}\n";
                    print OUTFILE "#endif\n" unless ($separateObj == 0);
                } else {
                    print "Warning: can't handle varargs function '$name'\n";
                }
                next;
            }

	    # newXS special case
	    if ($name eq "newXS") {
		next;
	    }
            
            print OUTFILE "\n#ifdef $name" . "defined" unless ($separateObj == 0);

	    # handle specical case for save_destructor
	    if ($name eq "save_destructor") {
		next;
	    }
	    # handle specical case for sighandler
	    if ($name eq "sighandler") {
		next;
	    }
	    # handle special case for sv_grow
	    if ($name eq "sv_grow" and $args eq "SV* sv, unsigned long newlen") {
		next;
	    }
	    # handle special case for newSV
	    if ($name eq "newSV" and $args eq "I32 x, STRLEN len") {
		next;
	    }
	    # handle special case for perl_parse
	    if ($name eq "perl_parse") {
		print OUTFILE "\n#undef $name\nextern \"C\" $type $name ($args)\n{\n";
		print OUTFILE "\treturn pPerl->perl_parse(xsinit, argc, argv, env);\n}\n";
                print OUTFILE "#endif\n" unless ($separateObj == 0);
		next;
	    }

            # foo(void);
            if ($args eq "void") {
                print OUTFILE "\n#undef $name\nextern \"C\" $type $funcName ()\n{\n$return pPerl->$funcName();\n}\n";
                print OUTFILE "#endif\n" unless ($separateObj == 0);
                next;
            }

            # foo(char *s, const int bar);
            print OUTFILE "\n#undef $name\nextern \"C\" $type $funcName ($args)\n{\n$return pPerl->$funcName";
            $doneone = 0;
            foreach $arg (@args) {
                if ($arg =~ /(\w+)\W*$/) {
                    if ($doneone) {
                        print OUTFILE ", $1";
                    }
                    else {
                        print OUTFILE "($1";
                        $doneone++;
                    }
                }
            }
            print OUTFILE ");\n}\n";
            print OUTFILE "#endif\n" unless ($separateObj == 0);
        }
        else {
            print "failed to match $_";
        }
    }
}

close INFILE;

%skip_list = ();

skip_these [qw(
strchop
filemode
lastfd
oldname
curinterp
Argv
Cmd
sortcop
sortstash
firstgv
secondgv
sortstack
signalstack
mystrk
dumplvl
oldlastpm
gensym
preambled
preambleav
Ilaststatval
Ilaststype
mess_sv
ors
opsave
eval_mutex
orslen
ofmt
mh
modcount
generation
DBcv
archpat_auto
sortcxix
lastgotoprobe
regdummy
regparse
regxend
regcode
regnaughty
regsawback
regprecomp
regnpar
regsize
regflags
regseen
seen_zerolen
rx
extralen
colorset
colors
reginput
regbol
regeol
regstartp
regendp
reglastparen
regtill
regprev
reg_start_tmp
reg_start_tmpl
regdata
bostr
reg_flags
reg_eval_set
regnarrate
regprogram
regindent
regcc
in_clean_objs
in_clean_all
linestart
pending_ident
statusvalue_vms
sublex_info
thrsv
threadnum
piMem
piENV
piStdIO
piLIO
piDir
piSock
piProc
cshname
threadsv_names
thread
nthreads
thr_key
threads_mutex
malloc_mutex
svref_mutex
sv_mutex
nthreads_cond
eval_cond
cryptseen
cshlen
)];

sub readvars(\%$$) {
    my ($syms, $file, $pre) = @_;
    %$syms = ();
    local (*FILE, $_);
    open(FILE, "< $file")
	or die "$0: Can't open $file: $!\n";
    while (<FILE>) {
	s/[ \t]*#.*//;		# Delete comments.
	if (/PERLVARI?C?\($pre(\w+),\s*([^,)]+)/) {
	    $$syms{$1} = $2;
	}
    }
    close(FILE);
}

my %intrp;
my %thread;
my %globvar;

readvars %intrp,  '..\intrpvar.h','I';
readvars %thread, '..\thrdvar.h','T';
readvars %globvar, '..\perlvars.h','G';

open(HDRFILE, ">$hdrfile") or die "$0: Can't open $hdrfile: $!\n";
print HDRFILE "\nvoid SetCPerlObj(void* pP);";
print HDRFILE "\nCV* Perl_newXS(char* name, void (*subaddr)(CV* cv), char* filename);\n";

sub DoVariable($$) {
    my $name = shift;
    my $type = shift;

    return if (defined $skip_list{$name});
    return if ($type eq 'struct perl_thread *');

    print OUTFILE "\n#ifdef $name" . "_defined" unless ($separateObj == 0);
    print OUTFILE "\nextern \"C\" $type * _Perl_$name ()\n{\n";
    print OUTFILE "\treturn (($type *)&pPerl->Perl_$name);\n}\n";
    print OUTFILE "#endif\n" unless ($separateObj == 0);

    print HDRFILE "\n#undef Perl_$name\n$type * _Perl_$name ();";
    print HDRFILE "\n#define Perl_$name (*_Perl_$name())\n\n";
}

foreach $key (keys %intrp) {
    DoVariable ($key, $intrp{$key});
}

foreach $key (keys %thread) {
    DoVariable ($key, $thread{$key});
}

foreach $key (keys %globvar) {
    DoVariable ($key, $globvar{$key});
}

print OUTFILE <<EOCODE;


extern "C" {
void xs_handler(CV* cv, CPerlObj* pPerl)
{
    void(*func)(CV*);
    SV* sv;
    MAGIC* m = pPerl->Perl_mg_find((SV*)cv, '~');
    if(m != NULL)
    {
	sv = m->mg_obj;
	if(SvIOK(sv))
	{
	    func = (void(*)(CV*))SvIVX(sv);
	}
	else
	{
	    func = (void(*)(CV*))pPerl->Perl_sv_2iv(sv);
	}
	SetCPerlObj(pPerl);
	func(cv);
    }
}

CV* Perl_newXS(char* name, void (*subaddr)(CV* cv), char* filename)
{
    CV* cv = pPerl->Perl_newXS(name, xs_handler, filename);
    pPerl->Perl_sv_magic((SV*)cv, pPerl->Perl_sv_2mortal(pPerl->Perl_newSViv((IV)subaddr)), '~', "CAPI", 4);
    return cv;
}

#undef piMem
#undef piENV
#undef piStdIO
#undef piLIO
#undef piDir
#undef piSock
#undef piProc

int *        _win32_errno(void)
{
    return &pPerl->ErrorNo();
}

FILE*        _win32_stdin(void)
{
    return (FILE*)pPerl->piStdIO->Stdin();
}

FILE*        _win32_stdout(void)
{
    return (FILE*)pPerl->piStdIO->Stdout();
}

FILE*        _win32_stderr(void)
{
    return (FILE*)pPerl->piStdIO->Stderr();
}

int          _win32_ferror(FILE *fp)
{
    return pPerl->piStdIO->Error((PerlIO*)fp, ErrorNo());
}

int          _win32_feof(FILE *fp)
{
    return pPerl->piStdIO->Eof((PerlIO*)fp, ErrorNo());
}

char*	     _win32_strerror(int e)
{
    return strerror(e);
}

void	     _win32_perror(const char *str)
{
    perror(str);
}

int          _win32_vfprintf(FILE *pf, const char *format, va_list arg)
{
    return pPerl->piStdIO->Vprintf((PerlIO*)pf, ErrorNo(), format, arg);
}

int          _win32_vprintf(const char *format, va_list arg)
{
    return pPerl->piStdIO->Vprintf(pPerl->piStdIO->Stdout(), ErrorNo(), format, arg);
}

int          _win32_fprintf(FILE *pf, const char *format, ...)
{
    int ret;
    va_list args;
    va_start(args, format);
    ret = _win32_vfprintf(pf, format, args);
    va_end(args);
    return ret;
}

int          _win32_printf(const char *format, ...)
{
    int ret;
    va_list args;
    va_start(args, format);
    ret = _win32_vprintf(format, args);
    va_end(args);
    return ret;
}

size_t       _win32_fread(void *buf, size_t size, size_t count, FILE *pf)
{
    return pPerl->piStdIO->Read((PerlIO*)pf, buf, (size*count), ErrorNo());
}

size_t       _win32_fwrite(const void *buf, size_t size, size_t count, FILE *pf)
{
    return pPerl->piStdIO->Write((PerlIO*)pf, buf, (size*count), ErrorNo());
}

FILE*        _win32_fopen(const char *path, const char *mode)
{
    return (FILE*)pPerl->piStdIO->Open(path, mode, ErrorNo());
}

FILE*        _win32_fdopen(int fh, const char *mode)
{
    return (FILE*)pPerl->piStdIO->Fdopen(fh, mode, ErrorNo());
}

FILE*        _win32_freopen(const char *path, const char *mode, FILE *pf)
{
    return (FILE*)pPerl->piStdIO->Reopen(path, mode, (PerlIO*)pf, ErrorNo());
}

int          _win32_fclose(FILE *pf)
{
    return pPerl->piStdIO->Close((PerlIO*)pf, ErrorNo());
}

int          _win32_fputs(const char *s,FILE *pf)
{
    return pPerl->piStdIO->Puts((PerlIO*)pf, s, ErrorNo());
}

int          _win32_fputc(int c,FILE *pf)
{
    return pPerl->piStdIO->Putc((PerlIO*)pf, c, ErrorNo());
}

int          _win32_ungetc(int c,FILE *pf)
{
    return pPerl->piStdIO->Ungetc((PerlIO*)pf, c, ErrorNo());
}

int          _win32_getc(FILE *pf)
{
    return pPerl->piStdIO->Getc((PerlIO*)pf, ErrorNo());
}

int          _win32_fileno(FILE *pf)
{
    return pPerl->piStdIO->Fileno((PerlIO*)pf, ErrorNo());
}

void         _win32_clearerr(FILE *pf)
{
    pPerl->piStdIO->Clearerr((PerlIO*)pf, ErrorNo());
}

int          _win32_fflush(FILE *pf)
{
    return pPerl->piStdIO->Flush((PerlIO*)pf, ErrorNo());
}

long         _win32_ftell(FILE *pf)
{
    return pPerl->piStdIO->Tell((PerlIO*)pf, ErrorNo());
}

int          _win32_fseek(FILE *pf,long offset,int origin)
{
    return pPerl->piStdIO->Seek((PerlIO*)pf, offset, origin, ErrorNo());
}

int          _win32_fgetpos(FILE *pf,fpos_t *p)
{
    return pPerl->piStdIO->Getpos((PerlIO*)pf, p, ErrorNo());
}

int          _win32_fsetpos(FILE *pf,const fpos_t *p)
{
    return pPerl->piStdIO->Setpos((PerlIO*)pf, p, ErrorNo());
}

void         _win32_rewind(FILE *pf)
{
    pPerl->piStdIO->Rewind((PerlIO*)pf, ErrorNo());
}

FILE*        _win32_tmpfile(void)
{
    return (FILE*)pPerl->piStdIO->Tmpfile(ErrorNo());
}

void         _win32_setbuf(FILE *pf, char *buf)
{
    pPerl->piStdIO->SetBuf((PerlIO*)pf, buf, ErrorNo());
}

int          _win32_setvbuf(FILE *pf, char *buf, int type, size_t size)
{
    return pPerl->piStdIO->SetVBuf((PerlIO*)pf, buf, type, size, ErrorNo());
}

int          _win32_fgetc(FILE *pf)
{
    return pPerl->piStdIO->Getc((PerlIO*)pf, ErrorNo());
}

int          _win32_putc(int c, FILE *pf)
{
    return pPerl->piStdIO->Putc((PerlIO*)pf, c, ErrorNo());
}

int          _win32_puts(const char *s)
{
    return pPerl->piStdIO->Puts(pPerl->piStdIO->Stdout(), s, ErrorNo());
}

int          _win32_getchar(void)
{
    return pPerl->piStdIO->Getc(pPerl->piStdIO->Stdin(), ErrorNo());
}

int          _win32_putchar(int c)
{
    return pPerl->piStdIO->Putc(pPerl->piStdIO->Stdout(), c, ErrorNo());
}

void*        _win32_malloc(size_t size)
{
    return pPerl->piMem->Malloc(size);
}

void*        _win32_calloc(size_t numitems, size_t size)
{
    return pPerl->piMem->Malloc(numitems*size);
}

void*        _win32_realloc(void *block, size_t size)
{
    return pPerl->piMem->Realloc(block, size);
}

void         _win32_free(void *block)
{
    pPerl->piMem->Free(block);
}

void         _win32_abort(void)
{
    pPerl->piProc->Abort();
}

int          _win32_pipe(int *phandles, unsigned int psize, int textmode)
{
    return pPerl->piProc->Pipe(phandles);
}

FILE*        _win32_popen(const char *command, const char *mode)
{
    return (FILE*)pPerl->piProc->Popen(command, mode);
}

int          _win32_pclose(FILE *pf)
{
    return pPerl->piProc->Pclose((PerlIO*)pf);
}

unsigned     _win32_sleep(unsigned int t)
{
    return pPerl->piProc->Sleep(t);
}

int	_win32_spawnvp(int mode, const char *cmdname, const char *const *argv)
{
    return pPerl->piProc->Spawnvp(mode, cmdname, argv);
}

int          _win32_mkdir(const char *dir, int mode)
{
    return pPerl->piDir->Makedir(dir, mode, ErrorNo());
}

int          _win32_rmdir(const char *dir)
{
    return pPerl->piDir->Rmdir(dir, ErrorNo());
}

int          _win32_chdir(const char *dir)
{
    return pPerl->piDir->Chdir(dir, ErrorNo());
}

#undef stat
int          _win32_fstat(int fd,struct stat *sbufptr)
{
    return pPerl->piLIO->FileStat(fd, sbufptr, ErrorNo());
}

int          _win32_stat(const char *name,struct stat *sbufptr)
{
    return pPerl->piLIO->NameStat(name, sbufptr, ErrorNo());
}

int          _win32_setmode(int fd, int mode)
{
    return pPerl->piLIO->Setmode(fd, mode, ErrorNo());
}

long         _win32_lseek(int fd, long offset, int origin)
{
    return pPerl->piLIO->Lseek(fd, offset, origin, ErrorNo());
}

long         _win32_tell(int fd)
{
    return pPerl->piStdIO->Tell((PerlIO*)fd, ErrorNo());
}

int          _win32_dup(int fd)
{
    return pPerl->piLIO->Dup(fd, ErrorNo());
}

int          _win32_dup2(int h1, int h2)
{
    return pPerl->piLIO->Dup2(h1, h2, ErrorNo());
}

int          _win32_open(const char *path, int oflag,...)
{
    return pPerl->piLIO->Open(path, oflag, ErrorNo());
}

int          _win32_close(int fd)
{
    return pPerl->piLIO->Close(fd, ErrorNo());
}

int          _win32_read(int fd, void *buf, unsigned int cnt)
{
    return pPerl->piLIO->Read(fd, buf, cnt, ErrorNo());
}

int          _win32_write(int fd, const void *buf, unsigned int cnt)
{
    return pPerl->piLIO->Write(fd, buf, cnt, ErrorNo());
}

int          _win32_times(struct tms *timebuf)
{
    return pPerl->piProc->Times(timebuf);
}

int          _win32_ioctl(int i, unsigned int u, char *data)
{
    return pPerl->piLIO->IOCtl(i, u, data, ErrorNo());
}

int          _win32_utime(const char *f, struct utimbuf *t)
{
    return pPerl->piLIO->Utime((char*)f, t, ErrorNo());
}

char*   _win32_getenv(const char *name)
{
    return pPerl->piENV->Getenv(name, ErrorNo());
}

int          _win32_open_osfhandle(long handle, int flags)
{
    return pPerl->piStdIO->OpenOSfhandle(handle, flags);
}

long         _win32_get_osfhandle(int fd)
{
    return pPerl->piStdIO->GetOSfhandle(fd);
}
} /* extern "C" */
EOCODE


print HDRFILE <<EOCODE;
#undef win32_errno
#undef win32_stdin
#undef win32_stdout
#undef win32_stderr
#undef win32_ferror
#undef win32_feof
#undef win32_fprintf
#undef win32_printf
#undef win32_vfprintf
#undef win32_vprintf
#undef win32_fread
#undef win32_fwrite
#undef win32_fopen
#undef win32_fdopen
#undef win32_freopen
#undef win32_fclose
#undef win32_fputs
#undef win32_fputc
#undef win32_ungetc
#undef win32_getc
#undef win32_fileno
#undef win32_clearerr
#undef win32_fflush
#undef win32_ftell
#undef win32_fseek
#undef win32_fgetpos
#undef win32_fsetpos
#undef win32_rewind
#undef win32_tmpfile
#undef win32_abort
#undef win32_fstat
#undef win32_stat
#undef win32_pipe
#undef win32_popen
#undef win32_pclose
#undef win32_setmode
#undef win32_lseek
#undef win32_tell
#undef win32_dup
#undef win32_dup2
#undef win32_open
#undef win32_close
#undef win32_eof
#undef win32_read
#undef win32_write
#undef win32_mkdir
#undef win32_rmdir
#undef win32_chdir
#undef win32_setbuf
#undef win32_setvbuf
#undef win32_fgetc
#undef win32_putc
#undef win32_puts
#undef win32_getchar
#undef win32_putchar
#undef win32_malloc
#undef win32_calloc
#undef win32_realloc
#undef win32_free
#undef win32_sleep
#undef win32_times
#undef win32_stat
#undef win32_ioctl
#undef win32_utime
#undef win32_getenv

#define win32_errno    _win32_errno
#define win32_stdin    _win32_stdin
#define win32_stdout   _win32_stdout
#define win32_stderr   _win32_stderr
#define win32_ferror   _win32_ferror
#define win32_feof     _win32_feof
#define win32_strerror _win32_strerror
#define win32_perror   _win32_perror
#define win32_fprintf  _win32_fprintf
#define win32_printf   _win32_printf
#define win32_vfprintf _win32_vfprintf
#define win32_vprintf  _win32_vprintf
#define win32_fread    _win32_fread
#define win32_fwrite   _win32_fwrite
#define win32_fopen    _win32_fopen
#define win32_fdopen   _win32_fdopen
#define win32_freopen  _win32_freopen
#define win32_fclose   _win32_fclose
#define win32_fputs    _win32_fputs
#define win32_fputc    _win32_fputc
#define win32_ungetc   _win32_ungetc
#define win32_getc     _win32_getc
#define win32_fileno   _win32_fileno
#define win32_clearerr _win32_clearerr
#define win32_fflush   _win32_fflush
#define win32_ftell    _win32_ftell
#define win32_fseek    _win32_fseek
#define win32_fgetpos  _win32_fgetpos
#define win32_fsetpos  _win32_fsetpos
#define win32_rewind   _win32_rewind
#define win32_tmpfile  _win32_tmpfile
#define win32_abort    _win32_abort
#define win32_fstat    _win32_fstat
#define win32_stat     _win32_stat
#define win32_pipe     _win32_pipe
#define win32_popen    _win32_popen
#define win32_pclose   _win32_pclose
#define win32_setmode  _win32_setmode
#define win32_lseek    _win32_lseek
#define win32_tell     _win32_tell
#define win32_dup      _win32_dup
#define win32_dup2     _win32_dup2
#define win32_open     _win32_open
#define win32_close    _win32_close
#define win32_eof      _win32_eof
#define win32_read     _win32_read
#define win32_write    _win32_write
#define win32_mkdir    _win32_mkdir
#define win32_rmdir    _win32_rmdir
#define win32_chdir    _win32_chdir
#define win32_setbuf   _win32_setbuf
#define win32_setvbuf  _win32_setvbuf
#define win32_fgetc    _win32_fgetc
#define win32_putc     _win32_putc
#define win32_puts     _win32_puts
#define win32_getchar  _win32_getchar
#define win32_putchar  _win32_putchar
#define win32_malloc   _win32_malloc
#define win32_calloc   _win32_calloc
#define win32_realloc  _win32_realloc
#define win32_free     _win32_free
#define win32_sleep    _win32_sleep
#define win32_spawnvp  _win32_spawnvp
#define win32_times    _win32_times
#define win32_stat     _win32_stat
#define win32_ioctl    _win32_ioctl
#define win32_utime    _win32_utime
#define win32_getenv   _win32_getenv
#define win32_open_osfhandle _win32_open_osfhandle
#define win32_get_osfhandle  _win32_get_osfhandle

int * 	_win32_errno(void);
FILE*	_win32_stdin(void);
FILE*	_win32_stdout(void);
FILE*	_win32_stderr(void);
int	_win32_ferror(FILE *fp);
int	_win32_feof(FILE *fp);
char*	_win32_strerror(int e);
void    _win32_perror(const char *str);
int	_win32_fprintf(FILE *pf, const char *format, ...);
int	_win32_printf(const char *format, ...);
int	_win32_vfprintf(FILE *pf, const char *format, va_list arg);
int	_win32_vprintf(const char *format, va_list arg);
size_t	_win32_fread(void *buf, size_t size, size_t count, FILE *pf);
size_t	_win32_fwrite(const void *buf, size_t size, size_t count, FILE *pf);
FILE*	_win32_fopen(const char *path, const char *mode);
FILE*	_win32_fdopen(int fh, const char *mode);
FILE*	_win32_freopen(const char *path, const char *mode, FILE *pf);
int	_win32_fclose(FILE *pf);
int	_win32_fputs(const char *s,FILE *pf);
int	_win32_fputc(int c,FILE *pf);
int	_win32_ungetc(int c,FILE *pf);
int	_win32_getc(FILE *pf);
int	_win32_fileno(FILE *pf);
void	_win32_clearerr(FILE *pf);
int	_win32_fflush(FILE *pf);
long	_win32_ftell(FILE *pf);
int	_win32_fseek(FILE *pf,long offset,int origin);
int	_win32_fgetpos(FILE *pf,fpos_t *p);
int	_win32_fsetpos(FILE *pf,const fpos_t *p);
void	_win32_rewind(FILE *pf);
FILE*	_win32_tmpfile(void);
void	_win32_abort(void);
int  	_win32_fstat(int fd,struct stat *sbufptr);
int  	_win32_stat(const char *name,struct stat *sbufptr);
int	_win32_pipe( int *phandles, unsigned int psize, int textmode );
FILE*	_win32_popen( const char *command, const char *mode );
int	_win32_pclose( FILE *pf);
int	_win32_setmode( int fd, int mode);
long	_win32_lseek( int fd, long offset, int origin);
long	_win32_tell( int fd);
int	_win32_dup( int fd);
int	_win32_dup2(int h1, int h2);
int	_win32_open(const char *path, int oflag,...);
int	_win32_close(int fd);
int	_win32_eof(int fd);
int	_win32_read(int fd, void *buf, unsigned int cnt);
int	_win32_write(int fd, const void *buf, unsigned int cnt);
int	_win32_mkdir(const char *dir, int mode);
int	_win32_rmdir(const char *dir);
int	_win32_chdir(const char *dir);
void	_win32_setbuf(FILE *pf, char *buf);
int	_win32_setvbuf(FILE *pf, char *buf, int type, size_t size);
char*	_win32_fgets(char *s, int n, FILE *pf);
char*	_win32_gets(char *s);
int	_win32_fgetc(FILE *pf);
int	_win32_putc(int c, FILE *pf);
int	_win32_puts(const char *s);
int	_win32_getchar(void);
int	_win32_putchar(int c);
void*	_win32_malloc(size_t size);
void*	_win32_calloc(size_t numitems, size_t size);
void*	_win32_realloc(void *block, size_t size);
void	_win32_free(void *block);
unsigned _win32_sleep(unsigned int);
int	_win32_spawnvp(int mode, const char *cmdname, const char *const *argv);
int	_win32_times(struct tms *timebuf);
int	_win32_stat(const char *path, struct stat *buf);
int	_win32_ioctl(int i, unsigned int u, char *data);
int	_win32_utime(const char *f, struct utimbuf *t);
char*   _win32_getenv(const char *name);
int     _win32_open_osfhandle(long handle, int flags);
long    _win32_get_osfhandle(int fd);

#pragma warning(once : 4113)
EOCODE


close HDRFILE;
close OUTFILE;
