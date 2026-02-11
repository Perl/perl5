#!/pro/bin/perl

use strict;
use warnings;

BEGIN {
    use Test::More;
    my $tests = 137;
    unless ($ENV{PERL_CORE}) {
	require Test::NoWarnings;
	Test::NoWarnings->import ();
	$tests++;
	}

    plan tests => $tests;
    }

use Config::Perl::V qw( summary );

ok (my $conf = Config::Perl::V::plv2hash (<DATA>), "Read perl -v block");
ok (exists $conf->{$_}, "Has $_ entry") for qw( build environment config inc );

is ($conf->{build}{osname}, $conf->{config}{osname}, "osname");
is ($conf->{build}{stamp}, "Jan 20 2026 12:22:09", "Build time");
is ($conf->{config}{version}, "5.43.7", "reconstructed \$Config{version}");

my $opt = Config::Perl::V::plv2hash ("")->{build}{options};
foreach my $o (sort qw(
	DEBUGGING HAS_LONG_DOUBLE HAS_STRTOLD HAS_TIMES
	PERL_COPY_ON_WRITE PERL_DONT_CREATE_GVSV PERL_HASH_FUNC_SIPHASH13
	PERL_HASH_USE_SBOX32 PERL_MALLOC_WRAP PERL_OP_PARENT PERL_PRESERVE_IVUV
	PERL_USE_SAFE_PUTENV PERLIO_LAYERS PERL_USE_DEVEL USE_64_BIT_ALL
	USE_64_BIT_INT USE_LARGE_FILES USE_LOCALE
	USE_LOCALE_COLLATE USE_LOCALE_CTYPE USE_LOCALE_NUMERIC USE_LOCALE_TIME
	USE_PERL_ATOF USE_PERLIO
	)) {
    is ($conf->{build}{options}{$o}, 1, "Runtime option $o set");
    delete $opt->{$o};
    }
foreach my $o (sort keys %$opt) {
    is ($conf->{build}{options}{$o}, 0, "Runtime option $o unset");
    }

eval { require Digest::MD5; };
my $md5 = $@ ? "0" x 32 : "3e9e3a27c1579ee4753d46680bc469df";
ok (my $sig = Config::Perl::V::signature ($conf), "Get signature");

SKIP: {
    ord "A" == 65 or skip "ASCII-centric test", 1;
    is ($sig, $md5, "MD5");
    }

is_deeply ($conf->{build}{patches}, [ ], "No patches");

my %check = (
    alignbytes      => 8,
    api_version     => 43,
    bincompat5005   => undef,	# GONE, chainsawed
    byteorder       => 12345678,
    cc              => "cc",
    cccdlflags      => "-fPIC",
    ccdlflags       => "-Wl,-E",
    config_args     => "-Dusedevel -Duse64bitall -desr -Dusedevel -Uinstallusrbinperl -Dprefix=/media/Tux/perls",
    gccversion      => "15.2.1 20251006",
    gnulibc_version => "2.42",
    ivsize          => 8,
    ivtype          => "long",
    ld              => "cc",
    lddlflags       => "-shared -O2 -L/pro/local/lib -fstack-protector-strong",
    ldflags         => "-L/pro/local/lib -fstack-protector-strong",
    libc            => "/lib/../lib64/libc.so.6",
    lseektype       => "off_t",
    osvers          => "6.18.5-1-default",
    use64bitall     => "define",
    use64bitint     => "define",
    usemymalloc     => "n",
    default_inc_excludes_dot
		    => "define",
    );
is ($conf->{config}{$_}, $check{$_}, "reconstructed \$Config{$_}") for sort keys %check;

ok (my $info = summary ($conf), "A summary");
ok (exists $info->{$_}, "Summary has $_") for qw( cc config_args usemymalloc default_inc_excludes_dot );
is ($info->{default_inc_excludes_dot}, "define", "This build has . NOT in INC");

__END__
Summary of my perl5 (revision 5 version 43 subversion 7) configuration:
   
  Platform:
    osname=linux
    osvers=6.18.5-1-default
    archname=x86_64-linux
    uname='linux lx09 6.18.5-1-default #1 smp preempt_dynamic mon jan 12 07:24:59 utc 2026 (c0cb237) x86_64 x86_64 x86_64 gnulinux '
    config_args='-Dusedevel -Duse64bitall -desr -Dusedevel -Uinstallusrbinperl -Dprefix=/media/Tux/perls'
    hint=recommended
    useposix=true
    d_sigaction=define
    useithreads=undef
    usemultiplicity=undef
    use64bitint=define
    use64bitall=define
    uselongdouble=undef
    usemymalloc=n
    default_inc_excludes_dot=define
  Compiler:
    cc='cc'
    ccflags ='-DDEBUGGING -fwrapv -fno-strict-aliasing -pipe -fstack-protector-strong -I/pro/local/include -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -D_FORTIFY_SOURCE=2'
    optimize='-O2'
    cppflags='-DDEBUGGING -fwrapv -fno-strict-aliasing -pipe -fstack-protector-strong -I/pro/local/include'
    ccversion=''
    gccversion='15.2.1 20251006'
    gccosandvers=''
    intsize=4
    longsize=8
    ptrsize=8
    doublesize=8
    byteorder=12345678
    doublekind=3
    d_longlong=define
    longlongsize=8
    d_longdbl=define
    longdblsize=16
    longdblkind=3
    ivtype='long'
    ivsize=8
    nvtype='double'
    nvsize=8
    Off_t='off_t'
    lseeksize=8
    alignbytes=8
    prototype=define
  Linker and Libraries:
    ld='cc'
    ldflags ='-L/pro/local/lib -fstack-protector-strong'
    libpth=/usr/local/lib /usr/x86_64-suse-linux/lib /usr/lib /pro/local/lib /usr/lib64 /usr/local/lib64
    libs=-lpthread -lgdbm -ldb -ldl -lm -lcrypt -lutil -lc -lgdbm_compat
    perllibs=-lpthread -ldl -lm -lcrypt -lutil -lc
    libc=/lib/../lib64/libc.so.6
    so=so
    useshrplib=false
    libperl=libperl.a
    gnulibc_version='2.42'
  Dynamic Linking:
    dlsrc=dl_dlopen.xs
    dlext=so
    d_dlsymun=undef
    ccdlflags='-Wl,-E'
    cccdlflags='-fPIC'
    lddlflags='-shared -O2 -L/pro/local/lib -fstack-protector-strong'


Characteristics of this binary (from libperl): 
  Compile-time options:
    DEBUGGING
    HAS_LONG_DOUBLE
    HAS_STRTOLD
    HAS_TIMES
    PERLIO_LAYERS
    PERL_COPY_ON_WRITE
    PERL_DONT_CREATE_GVSV
    PERL_HASH_FUNC_SIPHASH13
    PERL_HASH_USE_SBOX32
    PERL_MALLOC_WRAP
    PERL_OP_PARENT
    PERL_PRESERVE_IVUV
    PERL_USE_DEVEL
    PERL_USE_SAFE_PUTENV
    USE_64_BIT_ALL
    USE_64_BIT_INT
    USE_LARGE_FILES
    USE_LOCALE
    USE_LOCALE_COLLATE
    USE_LOCALE_CTYPE
    USE_LOCALE_NUMERIC
    USE_LOCALE_TIME
    USE_PERLIO
    USE_PERL_ATOF
  Built under linux
  Compiled at Jan 20 2026 12:22:09
  %ENV:
    PERL6LIB="inst#/pro/3gl/CPAN/rakudo/install"
  @INC:
    /media/Tux/perls/lib/site_perl/5.43.7/x86_64-linux
    /media/Tux/perls/lib/site_perl/5.43.7
    /media/Tux/perls/lib/5.43.7/x86_64-linux
    /media/Tux/perls/lib/5.43.7
