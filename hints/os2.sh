# Problems:
# a) warning from fcntl: Third argument is int in emx - patched
# b) gr_password is not a structure in struct group - patched
# c) (gone)
# d) Makefile needs sh before ./makedir
# e) (gone)
# f) (gone)
# g) (gone)
# h) (gone)
# i) (gone)
# j) the rule true in Makefile should become sh -c true
# k) Cwd does not work. ===> the extensions cannot be compiled - patched
# l) TEST expects to get -e 'perl' - patched
# m) (gone)

# Tests failing with .o compile (this is probably obsolete, but now it is .obj):

# comp/cpp (because of sed above)
# io/fs.t : (patched) 2..5 7..11 18 (why 11?)
# io/inplace.t ???? (ak works)
# io/tell.t 10 ????
# op/exec.t 1 ???? 4 ????
# op/glob.t 1 (bug in sh)
# op/magic.t 4 1/2 (????) adding sleep 5 does not help
# op/readdir.t 3 (same bug in ksh)
# op/stat.t 3 4 9 10 20 >34

# Newer results with .obj without i/o optimization, fail:

# io/fs.t	: 2+
# io/pipe.t	: 1+
# io/tell.t	: 8, 10
# op/exec.t	: 4, 6 (ok 1 comes as "ok \1")
# op/fork.t	: 1+
# op/misc.t	: 9
# op/pack.t	: 8
# op/stat.t	: 3 4 9 10 20 >34
# lib/sdbm.t	: sdbm store returned -1, errno 0, key "21" at lib/sdbm.t line 112.
# lib/posix.t	: coredump on 3

# If compiled with i/o optimization, then 15% speedup on input, and
# io/tell.t	: 11 only
# no coredump in posix.t


# Note that during the .obj compile you need to move the perl.dll file
# to LIBPATH :-(

#osname="OS/2"
sysman=`../UU/loc . /man/man1 /usr/man/man1 c:/man/man1 c:/usr/man/man1`
cc='gcc'
usrinc='/emx/include'
libpth='/emx/lib/st /emx/lib'

so='dll'

# Additional definitions:

d_shrplib='define'
firstmakefile='GNUmakefile'
obj_ext='.obj'
obj_ext_regexp='\.obj'
lib_ext='.lib'
ar='emxomfar'
plibext='.lib'
exe_ext='.exe'
archobjs="os2$obj_ext"
cldlibs=''

libc="/emx/lib/st/c_import$lib_ext"

# otherwise puts -lc ???

libs='-lsocket -lm'

# Run files without extension with sh - feature of patched ksh
NOHASHBANG=sh

cccdlflags='-Zdll'
dlsrc='dl_os2.xs'
lddlflags='-Zdll -Zomf -Zcrtdll'
ldflags='-Zexe -Zomf -Zcrtdll'
ld='gcc'
usedl='define'
ccflags='-Zomf -DDOSISH -DOS2=2 -DEMBED -I.'
cppflags='-DDOSISH -DOS2=2 -DEMBED -I.'

# This variables taken from recommended config.sh
alignbytes='8'

d_fork='undef'

# for speedup: (some patches to ungetc are also needed):
# Note that without this guy tests 8 and 10 of io/tell.t fail, with it 11 fails

d_stdstdio='define'
d_stdiobase='define'
d_stdio_ptr_lval='define'
d_stdio_cnt_lval='define'
stdio_ptr='((fp)->ptr)'
stdio_cnt='((fp)->rcount)'
stdio_base='((fp)->buffer)'
stdio_bufsiz='((fp)->rcount + (fp)->ptr - (fp)->buffer)'


# I do not have these:
#dynamic_ext='Fcntl GDBM_File SDBM_File POSIX Socket UPM REXXCALL'
dynamic_ext='Fcntl POSIX Socket SDBM_File Devel/DProf'
#extensions='Fcntl GDBM_File SDBM_File POSIX Socket UPM REXXCALL'
extensions='Fcntl SDBM_File POSIX Socket Devel/DProf'

# To have manpages installed
echo nroff is "'$nroff'"
nroff='nroff.cmd'
_nroff='nroff.cmd'
echo nroff is "'$nroff'"

# Unknown reasons for:
#cpio='cpio'
#csh=''
#date=''
#byacc=''
#d_charsprf='undef'
#d_drem='undef'
#d_fmod='define'
#d_linuxstd='undef'
#d_socket='define'
#gcc='gcc'
#gidtype='gid_t'
#glibpth='c:/usr/lib/emx h:/emx/lib /emx/lib'
#groupstype='gid_t'
#h_fcntl='true'
#i_time='define'
#line=''
#lseektype='off_t'
#man1ext='1'
#man3ext='3'
#modetype='mode_t'
#more='more'
#mv='mv'
#sleep='sleep'
#socketlib='-lsocket'
#ssizetype='ssize_t'
#tar='tar'
#timetype='time_t'
#uidtype='uid_t'
#uname=''
#uniq=''
#xlibpth=''
#yacc='yacc'
#yaccflags=''
#zcat='zcat'
#orderlib='false'
#pg='pg'
#pr='pr'
#ranlib=':'

# Misfound by configure:

#gcc='gcc'
#more='more'
#mv='mv'
#pr='pr'
#sleep='sleep'
#tar='tar'

xlibpth=''

# I cannot stand it, but did not test with:
# d_dirnamlen='undef'

# I try to do without these:

#d_pwage='undef'
#d_pwcomment='undef'

ln='cp'
lns='cp'

# ????
#mallocobj=''
#mallocsrc=''
#usemymalloc='false'

nm_opt='-p'

# The next two are commented. pdksh handles #!
# sharpbang='extproc '
# shsharp='false'

# Commented:
#startsh='extproc ksh\\n#! sh'
