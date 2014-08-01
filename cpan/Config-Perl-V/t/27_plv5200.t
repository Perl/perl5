#!/pro/bin/perl

use strict;
use warnings;

BEGIN {
    use Test::More;
    my $tests = 110;
    unless ($ENV{PERL_CORE}) {
	require Test::NoWarnings;
	Test::NoWarnings->import ();
	$tests++;
	}

    plan tests => $tests;
    }

use Config::Perl::V;

ok (my $conf = Config::Perl::V::plv2hash (<DATA>), "Read perl -v block");
ok (exists $conf->{$_}, "Has $_ entry") for qw( build environment config inc );

is ($conf->{build}{osname}, $conf->{config}{osname}, "osname");
is ($conf->{build}{stamp}, "Jun 30 2014 15:37:09", "No build time known");
is ($conf->{config}{version}, "5.20.0", "reconstructed \$Config{version}");

is ($conf->{build}{options}{$_}, 0, "Runtime option $_ unset") for qw(
    DEBUGGING DEBUG_LEAKING_SCALARS DEBUG_LEAKING_SCALARS_FORK_DUMP
    DECCRTL_SOCKETS FAKE_THREADS FCRYPT HAVE_INTERP_INTERN MYMALLOC NO_HASH_SEED
    NO_MATHOMS NO_TAINT_SUPPORT PERL_BOOL_AS_CHAR PERL_DEBUG_READONLY_COW
    PERL_DEBUG_READONLY_OPS PERL_DISABLE_PMC PERL_DONT_CREATE_GVSV
    PERL_EXTERNAL_GLOB PERL_GLOBAL_STRUCT PERL_GLOBAL_STRUCT_PRIVATE
    PERL_HASH_FUNC_DJB2 PERL_HASH_FUNC_MURMUR3 PERL_HASH_FUNC_ONE_AT_A_TIME
    PERL_HASH_FUNC_ONE_AT_A_TIME_HARD PERL_HASH_FUNC_ONE_AT_A_TIME_OLD
    PERL_HASH_FUNC_SDBM PERL_HASH_FUNC_SIPHASH PERL_HASH_FUNC_SUPERFAST
    PERL_IMPLICIT_CONTEXT PERL_IMPLICIT_SYS PERL_IS_MINIPERL PERL_MAD
    PERL_MALLOC_WRAP PERL_MEM_LOG PERL_MEM_LOG_ENV PERL_MEM_LOG_ENV_FD
    PERL_MEM_LOG_NOIMPL PERL_MEM_LOG_STDERR PERL_MEM_LOG_TIMESTAMP PERL_MICRO
    PERL_NEED_APPCTX PERL_NEED_TIMESBASE PERL_NEW_COPY_ON_WRITE
    PERL_OLD_COPY_ON_WRITE PERL_PERTURB_KEYS_DETERMINISTIC
    PERL_PERTURB_KEYS_DISABLED PERL_PERTURB_KEYS_RANDOM PERL_POISON
    PERL_PRESERVE_IVUV PERL_RELOCATABLE_INCPUSH PERL_SAWAMPERSAND
    PERL_TRACK_MEMPOOL PERL_USES_PL_PIDSTATUS PERL_USE_DEVEL
    PERL_USE_SAFE_PUTENV PL_OP_SLAB_ALLOC THREADS_HAVE_PIDS UNLINK_ALL_VERSIONS
    USE_64_BIT_ALL USE_64_BIT_INT USE_ATTRIBUTES_FOR_PERLIO USE_FAST_STDIO
    USE_HASH_SEED_EXPLICIT USE_IEEE USE_ITHREADS USE_LARGE_FILES USE_LOCALE
    USE_LOCALE_COLLATE USE_LOCALE_CTYPE USE_LOCALE_NUMERIC USE_LOCALE_TIME
    USE_LONG_DOUBLE USE_PERLIO USE_PERL_ATOF USE_REENTRANT_API USE_SFIO
    USE_SITECUSTOMIZE USE_SOCKS VMS_DO_SOCKETS VMS_SHORTEN_LONG_SYMBOLS
    VMS_SYMBOL_CASE_AS_IS
    );
is ($conf->{build}{options}{$_}, 1, "Runtime option $_ set") for qw(
    HAS_TIMES MULTIPLICITY PERLIO_LAYERS
    );

my %check = (
    alignbytes      => 4,
    api_version     => 20,
    bincompat5005   => "undef",
    byteorder       => 12345678,
    cc              => "cc",
    cccdlflags      => "-fPIC",
    ccdlflags       => "-Wl,-E",
    config_args     => "-Dusedevel -Uversiononly -Dinc_version_list=none -Duse64bitint -Dusethreads -Duseithreads -Duselongdouble -des",
    gccversion      => "4.8.1 20130909 [gcc-4_8-branch revision 202388]",
    gnulibc_version => "2.18",
    ivsize          => 8,
    ivtype          => "long long",
    ld              => "cc",
    lddlflags       => "-shared -O2 -L/pro/local/lib -fstack-protector",
    ldflags         => "-L/pro/local/lib -fstack-protector",
    libc            => "libc-2.18.so",
    lseektype       => "off_t",
    osvers          => "3.11.10-17-desktop",
    use64bitint     => "define",
    );
is ($conf->{config}{$_}, $check{$_}, "reconstructed \$Config{$_}") for sort keys %check;

__END__
Summary of my perl5 (revision 5 version 20 subversion 0) configuration:
   
  Platform:
    osname=linux, osvers=3.11.10-17-desktop, archname=i686-linux-thread-multi-64int-ld
    uname='linux lx09 3.11.10-17-desktop #1 smp preempt mon jun 16 15:28:13 utc 2014 (fba7c1f) i686 i686 i386 gnulinux '
    config_args='-Dusedevel -Uversiononly -Dinc_version_list=none -Duse64bitint -Dusethreads -Duseithreads -Duselongdouble -des'
    hint=recommended, useposix=true, d_sigaction=define
    useithreads=define, usemultiplicity=define
    use64bitint=define, use64bitall=undef, uselongdouble=define
    usemymalloc=n, bincompat5005=undef
  Compiler:
    cc='cc', ccflags ='-D_REENTRANT -D_GNU_SOURCE -fwrapv -fno-strict-aliasing -pipe -fstack-protector -I/pro/local/include -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64',
    optimize='-O2',
    cppflags='-D_REENTRANT -D_GNU_SOURCE -fwrapv -fno-strict-aliasing -pipe -fstack-protector -I/pro/local/include'
    ccversion='', gccversion='4.8.1 20130909 [gcc-4_8-branch revision 202388]', gccosandvers=''
    intsize=4, longsize=4, ptrsize=4, doublesize=8, byteorder=12345678
    d_longlong=define, longlongsize=8, d_longdbl=define, longdblsize=12
    ivtype='long long', ivsize=8, nvtype='long double', nvsize=12, Off_t='off_t', lseeksize=8
    alignbytes=4, prototype=define
  Linker and Libraries:
    ld='cc', ldflags ='-L/pro/local/lib -fstack-protector'
    libpth=/usr/local/lib /usr/lib/gcc/i586-suse-linux/4.8/include-fixed /usr/lib/gcc/i586-suse-linux/4.8/../../../../i586-suse-linux/lib /usr/lib /pro/local/lib /lib
    libs=-lnsl -lgdbm -ldb -ldl -lm -lcrypt -lutil -lpthread -lc -lgdbm_compat
    perllibs=-lnsl -ldl -lm -lcrypt -lutil -lpthread -lc
    libc=libc-2.18.so, so=so, useshrplib=false, libperl=libperl.a
    gnulibc_version='2.18'
  Dynamic Linking:
    dlsrc=dl_dlopen.xs, dlext=so, d_dlsymun=undef, ccdlflags='-Wl,-E'
    cccdlflags='-fPIC', lddlflags='-shared -O2 -L/pro/local/lib -fstack-protector'


Characteristics of this binary (from libperl): 
  Compile-time options: HAS_TIMES MULTIPLICITY PERLIO_LAYERS
                        PERL_DONT_CREATE_GVSV
                        PERL_HASH_FUNC_ONE_AT_A_TIME_HARD
                        PERL_IMPLICIT_CONTEXT PERL_MALLOC_WRAP
                        PERL_NEW_COPY_ON_WRITE PERL_PRESERVE_IVUV
                        PERL_USE_DEVEL USE_64_BIT_INT USE_ITHREADS
                        USE_LARGE_FILES USE_LOCALE USE_LOCALE_COLLATE
                        USE_LOCALE_CTYPE USE_LOCALE_NUMERIC USE_LONG_DOUBLE
                        USE_PERLIO USE_PERL_ATOF USE_REENTRANT_API
  Built under linux
  Compiled at Jun 30 2014 15:37:09
  @INC:
    /pro/lib/perl5/site_perl/5.20.0/i686-linux-thread-multi-64int-ld
    /pro/lib/perl5/site_perl/5.20.0
    /pro/lib/perl5/5.20.0/i686-linux-thread-multi-64int-ld
    /pro/lib/perl5/5.20.0
    .
