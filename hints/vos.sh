# $Id: vos.sh,v 1.0 2001-12-11 09:30:00-05 Green Exp $

# This is a hints file for Stratus VOS, using the POSIX environment
# in VOS 14.4.0 and higher.
#
# VOS POSIX is based on POSIX.1-1996.  It ships with gcc as the standard
# compiler.
#
# Paul Green (Paul.Green@stratus.com)

# C compiler and default options.
cc=gcc
ccflags="-D_SVID_SOURCE -D_POSIX_C_SOURCE=199509L"

# Make command.
make="/system/gnu_library/bin/gmake"
# indented to not put it into config.sh
  _make="/system/gnu_library/bin/gmake"

# Architecture name
archname="hppa1.1"

# Executable suffix.
# No, this is not a typo.  The ".pm" really is the native
# executable suffix in VOS.  Talk about cosmic resonance.
_exe=".pm"

# Object library paths.
loclibpth="/system/stcp/object_library"
loclibpth="$loclibpth /system/stcp/object_library/common"
loclibpth="$loclibpth /system/stcp/object_library/net"
loclibpth="$loclibpth /system/stcp/object_library/socket"
loclibpth="$loclibpth /system/posix_object_library/sysv"
loclibpth="$loclibpth /system/posix_object_library"
loclibpth="$loclibpth /system/c_object_library"
loclibpth="$loclibpth /system/object_library"
glibpth="$loclibpth"

# Include library paths
locincpth="/system/stcp/include_library"
locincpth="$locincpth /system/stcp/include_library/arpa"
locincpth="$locincpth /system/stcp/include_library/net"
locincpth="$locincpth /system/stcp/include_library/netinet"
locincpth="$locincpth /system/stcp/include_library/protocols"
locincpth="$locincpth /system/include_library/sysv"
usrinc="/system/include_library"

# Where to install perl5.
prefix=/system/ported/perl5

# Linker is gcc.
ld="gcc"

# No shared libraries.
so="none"

# Don't use nm.
usenm="n"

# Make the default be no large file support.
uselargefiles="n"

# Don't use malloc that comes with perl.
usemymalloc="n"

# Make bison the default compiler-compiler.
yacc="/system/gnu_library/bin/bison"

# VOS doesn't have (or need) a pager, but perl needs one.
pager="/system/gnu_library/bin/cat.pm"

# VOS has a bug that causes _exit() to flush all files.
# This confuses the tests.  Make 'em happy here.
fflushNULL=define

# VOS has a link() function but it is a dummy.
d_link="undef"

# VOS does not have truncate() but we supply one in vos.c
d_truncate="define"
archobjs="vos.o"

# Help gmake find vos.c
test -h vos.c || ln -s vos/vos.c vos.c

# VOS returns a constant 1 for st_nlink when stat'ing a
# directory. Therefore, we must set this variable to stop
# File::Find using the link count to determine whether there are
# subdirectories to be searched.
dont_use_nlink=define

# Tell Configure where to find the hosts file.
hostcat="cat /system/stcp/hosts"
