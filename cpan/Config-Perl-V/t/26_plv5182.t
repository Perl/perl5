#!/pro/bin/perl

use strict;
use warnings;

BEGIN {
    use Test::More;
    my $tests = 118;
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
is ($conf->{build}{stamp}, "Jan  9 2014 09:22:04", "Build time");
is ($conf->{config}{version}, "5.18.2", "reconstructed \$Config{version}");

# Some random checks
is ($conf->{build}{options}{$_}, 0, "Runtime option $_") for qw(
    DEBUG_LEAKING_SCALARS NO_HASH_SEED PERL_MEM_LOG_STDERR PERL_MEM_LOG_ENV
    PERL_MEM_LOG_TIMESTAMP PERL_MICRO USE_ATTRIBUTES_FOR_PERLIO VMS_DO_SOCKETS );
is ($conf->{build}{options}{$_}, 0, "Runtime option $_ unset") for qw(
    DEBUGGING DEBUG_LEAKING_SCALARS DEBUG_LEAKING_SCALARS_FORK_DUMP
    DECCRTL_SOCKETS FAKE_THREADS FCRYPT HAVE_INTERP_INTERN MULTIPLICITY
    MYMALLOC NO_HASH_SEED NO_MATHOMS NO_TAINT_SUPPORT PERL_BOOL_AS_CHAR
    PERL_DEBUG_READONLY_COW PERL_DEBUG_READONLY_OPS PERL_DISABLE_PMC
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
    HAS_TIMES PERL_DONT_CREATE_GVSV PERLIO_LAYERS
    );

my %check = (
    alignbytes      => 4,
    api_version     => 18,
    bincompat5005   => "undef",
    byteorder       => 12345678,
    cc              => "cc",
    cccdlflags      => "-fPIC",
    ccdlflags       => "-Wl,-E",
    config_args     => "-Duse64bitint -Duselongdouble -des",
    gccversion      => "4.8.1 20130909 [gcc-4_8-branch revision 202388]",
    gnulibc_version => "2.18",
    ivsize          => 8,
    ivtype          => "long long",
    ld              => "cc",
    lddlflags       => "-shared -O2 -L/pro/local/lib -fstack-protector",
    ldflags         => "-L/pro/local/lib -fstack-protector",
    libc            => "/lib/libc-2.18.so",
    lseektype       => "off_t",
    osvers          => "3.11.6-4-desktop",
    use64bitint     => "define",
    );
is ($conf->{config}{$_}, $check{$_}, "reconstructed \$Config{$_}") for sort keys %check;

__END__
Summary of my perl5 (revision 5 version 18 subversion 2) configuration:
   
  Platform:
    osname=linux, osvers=3.11.6-4-desktop, archname=i686-linux-64int-ld
    uname='linux lx09 3.11.6-4-desktop #1 smp preempt wed oct 30 18:04:56 utc 2013 (e6d4a27) i686 i686 i386 gnulinux '
    config_args='-Duse64bitint -Duselongdouble -des'
    hint=recommended, useposix=true, d_sigaction=define
    useithreads=undef, usemultiplicity=undef
    useperlio=define, d_sfio=undef, uselargefiles=define, usesocks=undef
    use64bitint=define, use64bitall=undef, uselongdouble=define
    usemymalloc=n, bincompat5005=undef
  Compiler:
    cc='cc', ccflags ='-fno-strict-aliasing -pipe -fstack-protector -I/pro/local/include -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64',
    optimize='-O2',
    cppflags='-fno-strict-aliasing -pipe -fstack-protector -I/pro/local/include'
    ccversion='', gccversion='4.8.1 20130909 [gcc-4_8-branch revision 202388]', gccosandvers=''
    intsize=4, longsize=4, ptrsize=4, doublesize=8, byteorder=12345678
    d_longlong=define, longlongsize=8, d_longdbl=define, longdblsize=12
    ivtype='long long', ivsize=8, nvtype='long double', nvsize=12, Off_t='off_t', lseeksize=8
    alignbytes=4, prototype=define
  Linker and Libraries:
    ld='cc', ldflags ='-L/pro/local/lib -fstack-protector'
    libpth=/pro/local/lib /lib /usr/lib /usr/local/lib
    libs=-lnsl -lgdbm -ldb -ldl -lm -lcrypt -lutil -lc -lgdbm_compat
    perllibs=-lnsl -ldl -lm -lcrypt -lutil -lc
    libc=/lib/libc-2.18.so, so=so, useshrplib=false, libperl=libperl.a
    gnulibc_version='2.18'
  Dynamic Linking:
    dlsrc=dl_dlopen.xs, dlext=so, d_dlsymun=undef, ccdlflags='-Wl,-E'
    cccdlflags='-fPIC', lddlflags='-shared -O2 -L/pro/local/lib -fstack-protector'


Characteristics of this binary (from libperl): 
  Compile-time options: HAS_TIMES PERLIO_LAYERS PERL_DONT_CREATE_GVSV
                        PERL_HASH_FUNC_ONE_AT_A_TIME_HARD PERL_MALLOC_WRAP
                        PERL_PRESERVE_IVUV PERL_SAWAMPERSAND USE_64_BIT_INT
                        USE_LARGE_FILES USE_LOCALE USE_LOCALE_COLLATE
                        USE_LOCALE_CTYPE USE_LOCALE_NUMERIC USE_LONG_DOUBLE
                        USE_PERLIO USE_PERL_ATOF
  Built under linux
  Compiled at Jan  9 2014 09:22:04
  @INC:
    /pro/lib/perl5/site_perl/5.18.2/i686-linux-64int-ld
    /pro/lib/perl5/site_perl/5.18.2
    /pro/lib/perl5/5.18.2/i686-linux-64int-ld
    /pro/lib/perl5/5.18.2
    .
