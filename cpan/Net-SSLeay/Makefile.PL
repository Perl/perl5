use 5.008001;
use utf8;
use strict;
use warnings;

use Config;
use English qw( $OSNAME -no_match_vars );
use ExtUtils::MakeMaker;
use File::Basename ();
use File::Spec;
use File::Spec::Functions qw(catfile);
use Symbol qw(gensym);
use Text::Wrap;

# According to http://cpanwiki.grango.org/wiki/CPANAuthorNotes, the ideal
# behaviour to exhibit when a prerequisite does not exist is to use exit code 0
# to ensure smoke testers stop immediately without reporting a FAIL; in all
# other environments, we want to fail more loudly
use constant {
    MISSING_PREREQ     => ( $ENV{AUTOMATED_TESTING} ? 0 : 1 ),
    UNSUPPORTED_LIBSSL => ( $ENV{AUTOMATED_TESTING} ? 0 : 1 ),
};

# Error messages displayed with alert() will be this many columns wide
use constant ALERT_WIDTH => 78;

# Define this to one if you want to link the openssl libraries statically into 
# the Net-SSLeay loadable object on Windows
my $win_link_statically = 0;

my $tests = prompt(
  "Do you want to run external tests?\n".
  "These tests *will* *fail* if you do not have network connectivity.",
  'n',
) =~ /^y/i ? 't/*/*.t t/*/*/*.t' : 't/local/*.t t/handle/local/*.t';

my %eumm_args = (
  NAME => 'Net::SSLeay',
  ABSTRACT => 'Perl bindings for OpenSSL and LibreSSL',
  LICENSE => 'artistic_2',
  AUTHOR => [
    'Sampo Kellomäki <sampo@iki.fi>',
    'Florian Ragwitz <rafl@debian.org>',
    'Mike McCauley <mikem@airspayce.com>',
    'Chris Novakovic <chris@chrisn.me.uk>',
    'Tuure Vartiainen <vartiait@radiatorsoftware.com>',
    'Heikki Vatiainen <hvn@radiatorsoftware.com>'
  ],
  VERSION_FROM => 'lib/Net/SSLeay.pm',
  MIN_PERL_VERSION => '5.8.1',
  CONFIGURE_REQUIRES => {
    'English' => '0',
    'ExtUtils::MakeMaker' => '0',
    'File::Spec::Functions' => '0',
    'Text::Wrap' => '0',
    'constant' => '0',
  },
  TEST_REQUIRES => {
    'Carp' => '0',
    'Config' => '0',
    'Cwd' => '0',
    'English' => '0',
    'File::Basename' => '0',
    'File::Spec::Functions' => '0',
    'Scalar::Util' => '0',
    'SelectSaver' => '0',
    'Socket' => '0',
    'Storable' => '0',
    'Test::Builder' => '0',
    'Test::More' => '0.60_01',
    'base' => '0',
  },
  PREREQ_PM => {
    'MIME::Base64' => '0',
  },
  test => { TESTS => $tests },
  clean => { FILES => join ' ', map fixpath($_), qw(
      makecert.out
      makecert.err
      sslecho.log
      tcpecho.log
      t/local/ptr_cast_test
      examples/cert.pem
      examples/key.pem
      examples/key.pem.e
      examples/*.0
  ) },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      repository => {
        type => 'git',
        url => 'git://github.com/radiator-software/p5-net-ssleay.git',
        web => 'https://github.com/radiator-software/p5-net-ssleay',
      },
      bugtracker  => {
        web => 'https://github.com/radiator-software/p5-net-ssleay/issues',
      },
    },
    no_index => { directory => [ qw(helper_script examples) ] },
    prereqs => {
      develop => {
        requires => {
          'Test::Pod::Coverage' => '1.00',
          'Test::Kwalitee' => '1.00',
        },
      },
    },
  },
  ssleay(),
);

# See if integers are only 32 bits long. If they are, add a flag to
# CCFLAGS. Since OpenSSL 1.1.0, a growing number of APIs are using 64
# bit integers. This causes a problem if Perl is compiled without 64
# bit integers. DEFINE is not used because Makefile.PL command line
# DEFINE argument is used for enabling compile time PR1
# etc. debugging.
#
# Note: 32bit integers are treated as the non-default case. When you
# use this define, do it so that 64bit case is the default whenever
# possible. This is safer for future library and Net::SSLeay releases.
$eumm_args{CCFLAGS} = "-DNET_SSLEAY_32BIT_INT_PERL $Config{ccflags}" if !defined $Config{use64bitint} || $Config{use64bitint} ne 'define';

# This can go when EU::MM older than 6.58 are gone
$eumm_args{AUTHOR} = join(', ', @{$eumm_args{AUTHOR}}) unless eval { ExtUtils::MakeMaker->VERSION(6.58); };

# This can go when EU::MM older than 6.64 are gone
delete $eumm_args{TEST_REQUIRES} unless eval { ExtUtils::MakeMaker->VERSION(6.64); };

$eumm_args{DEFINE} = '-DUSE_PPPORT_H' unless $ENV{PERL_CORE};

WriteMakefile(%eumm_args);

sub MY::postamble {
<<"MAKE";
SSLeay$Config{'obj_ext'} : constants.c

MAKE
}

sub ssleay {
    my $prefix = find_openssl_prefix();
    my $exec   = find_openssl_exec($prefix);
    unless (defined $exec && -x $exec) {
        print <<EOM;
*** Could not find OpenSSL
    If it's already installed, please set the OPENSSL_PREFIX environment
    variable accordingly. If it isn't installed yet, get the latest version
    from http://www.openssl.org/.
EOM
        exit 0; # according https://wiki.cpantesters.org/wiki/CPANAuthorNotes this is best-practice when "missing library"
    }

    my $opts = ssleay_get_build_opts($prefix);

    # Ensure libssl headers exist before continuing - compilation will fail
    # without them
    if ( !defined $opts->{inc_path} ) {
        my $detail =
              'The libssl header files are required to build Net-SSLeay, but '
            . 'they are missing from ' . $prefix . '. They would typically '
            . 'reside in ' . catfile( $prefix, 'include', 'openssl' ) . '.';

        if ( $OSNAME eq 'linux' ) {
            $detail .=
                  "\n\n"
                . 'If you are using the version of OpenSSL/LibreSSL packaged '
                . 'by your Linux distribution, you may need to install the '
                . 'corresponding "development" package via your package '
                . 'manager (e.g. libssl-dev for OpenSSL on Debian and Ubuntu, '
                . 'or openssl-devel for OpenSSL on Red Hat Enterprise Linux '
                . 'and Fedora).';
        }

        alert( 'Could not find libssl headers', $detail );

        exit MISSING_PREREQ;
    }

    check_openssl_version($prefix, $exec);
    my %args = (
        CCCDLFLAGS => $opts->{cccdlflags},
        OPTIMIZE => $opts->{optimize},
        INC => qq{-I"$opts->{inc_path}"},
        LIBS => join(' ', (map '-L'.maybe_quote($_), @{$opts->{lib_paths}}), (map {"-l$_"} @{$opts->{lib_links}})),
    );
    # From HMBRAND to handle multple version of OPENSSL installed
    if (my $lp = join " " => map '-L'.maybe_quote($_), @{$opts->{lib_paths} || []})
    {
	($args{uc $_} = $Config{$_}) =~ s/-L/$lp -L/ for qw(lddlflags ldflags);
    }
    %args;
}

sub maybe_quote { $_[0] =~ / / ? qq{"$_[0]"} : $_[0] }

sub ssleay_get_build_opts {
    my ($prefix) = @_;

    my $opts = {
        lib_links  => [],
        cccdlflags => '',
    };

    my @try_includes = (
        'include' => sub { 1 },
        'inc32'   => sub { $OSNAME eq 'MSWin32' },
    );

    while (
           !defined $opts->{inc_path}
        && defined( my $dir = shift @try_includes )
        && defined( my $cond = shift @try_includes )
    ) {
        if ( $cond->() && (-f "$prefix/$dir/openssl/ssl.h"
                           || -f "$prefix/$dir/ssl.h")) {
            $opts->{inc_path} = "$prefix/$dir";
        }
    }

    # Directory order matters. With macOS Monterey a poisoned dylib is
    # returned if the directory exists without the desired
    # library. See GH-329 for more information. With Strawberry Perl
    # 5.26 and later the paths must be in different order or the link
    # phase fails.
    my @try_lib_paths = (
	["$prefix/lib64", "$prefix/lib", "$prefix/out32dll", $prefix] => sub {$OSNAME eq 'darwin' },
	[$prefix, "$prefix/lib64", "$prefix/lib", "$prefix/out32dll"] => sub { 1 },
	);

    while (
	!defined $opts->{lib_paths}
	&& defined( my $dirs = shift @try_lib_paths )
	&& defined( my $cond = shift @try_lib_paths )
    ) {
	if ( $cond->() ) {
	    foreach my $dir (@{$dirs}) {
		push @{$opts->{lib_paths}}, $dir if -d $dir;
	    }
	}
    }

    print <<EOM;
*** Be sure to use the same compiler and options to compile your OpenSSL, perl,
    and Net::SSLeay. Mixing and matching compilers is not supported.
EOM

    if ($^O eq 'MSWin32') {
        if ($win_link_statically) {
            # Link to static libs
            push @{ $opts->{lib_paths} }, "$prefix/lib/VC/static" if -d "$prefix/lib/VC/static";
        }
        else {
            push @{ $opts->{lib_paths} }, "$prefix/lib/VC" if -d "$prefix/lib/VC";
        }

        my $found = 0;
        my @pairs = ();
        # Library names depend on the compiler
        @pairs = (['eay32','ssl32'],['crypto.dll','ssl.dll'],['crypto','ssl']) if $Config{cc} =~ /gcc/;
        @pairs = (['libeay32','ssleay32'],['libeay32MD','ssleay32MD'],['libeay32MT','ssleay32MT'],['libcrypto','libssl'],['crypto','ssl']) if $Config{cc} =~ /cl/;
        for my $dir (@{$opts->{lib_paths}}) {
          for my $p (@pairs) {
            $found = 1 if ($Config{cc} =~ /gcc/ && -f "$dir/lib$p->[0].a" && -f "$dir/lib$p->[1].a");
            $found = 1 if ($Config{cc} =~ /cl/ && -f "$dir/$p->[0].lib" && -f "$dir/$p->[1].lib");
            if ($found) {
              $opts->{lib_links} = [$p->[0], $p->[1], 'crypt32']; # Some systems need this system lib crypt32 too
              $opts->{lib_paths} = [$dir];
              last;
            }
          }
        }
        if (!$found) {
          #fallback to the old behaviour
          push @{ $opts->{lib_links} }, qw( libeay32MD ssleay32MD libeay32 ssleay32 libssl32 crypt32);
        }
    }
    elsif ($^O eq 'VMS') {
        if (-r 'sslroot:[000000]openssl.cnf') {      # openssl.org source install
          @{ $opts->{lib_paths} } = 'SSLLIB';
          @{ $opts->{lib_links} } = qw( ssl_libssl32.olb ssl_libcrypto32.olb );
        }
        elsif (-r 'ssl111$root:[000000]openssl.cnf') {  # VSI SSL111 install
            @{ $opts->{lib_paths} } = 'SYS$SHARE';
            @{ $opts->{lib_links} } = qw( SSL111$LIBSSL_SHR32 SSL111$LIBCRYPTO_SHR32 );
        }
        elsif (-r 'ssl1$root:[000000]openssl.cnf') {  # VSI or HPE SSL1 install
            @{ $opts->{lib_paths} } = 'SYS$SHARE';
            @{ $opts->{lib_links} } = qw( SSL1$LIBSSL_SHR32 SSL1$LIBCRYPTO_SHR32 );
        }
        elsif (-r 'ssl$root:[000000]openssl.cnf') {  # HP install
            @{ $opts->{lib_paths} } = 'SYS$SHARE';
            @{ $opts->{lib_links} } = qw( SSL$LIBSSL_SHR32 SSL$LIBCRYPTO_SHR32 );
        }
        @{ $opts->{lib_links} } = map { $_ =~ s/32\b//g } @{ $opts->{lib_links} } if $Config{use64bitall};
    }
    else {
        push @{ $opts->{lib_links} }, qw( ssl crypto z );

        if (($Config{cc} =~ /aCC/i) && $^O eq 'hpux') {
            print "*** Enabling HPUX aCC options (+e)\n";
            $opts->{optimize} = '+e -O2 -g';
        }

        if ( (($Config{ccname} || $Config{cc}) eq 'gcc') && ($Config{cccdlflags} =~ /-fpic/) ) {
            print "*** Enabling gcc -fPIC optimization\n";
            $opts->{cccdlflags} .= '-fPIC';
        }
    }
    return $opts;
}

my $other_try = 0;
my @nopath;
sub check_no_path {            # On OS/2 it would be typically on default paths
    my $p;
    if (not($other_try++) and $] >= 5.008001) {
       use ExtUtils::MM;
       my $mm = MM->new();
       my ($list) = $mm->ext("-lssl");
       return unless $list =~ /-lssl\b/;
        for $p (split /\Q$Config{path_sep}/, $ENV{PATH}) {
           @nopath = ("$p/openssl$Config{_exe}",       # exe name
                      '.')             # dummy lib path
               if -x "$p/openssl$Config{_exe}"
       }
    }
    @nopath;
}

sub find_openssl_prefix {
    my ($dir) = @_;

    if (defined $ENV{OPENSSL_PREFIX}) {
        return $ENV{OPENSSL_PREFIX};
    }

    my @guesses = (
	'/home/linuxbrew/.linuxbrew/opt/openssl/bin/openssl' => '/home/linuxbrew/.linuxbrew/opt/openssl', # LinuxBrew openssl
	'/opt/homebrew/opt/openssl/bin/openssl' => '/opt/homebrew/opt/openssl', # macOS ARM homebrew
	'/usr/local/opt/openssl/bin/openssl' => '/usr/local/opt/openssl', # OSX homebrew openssl
	'/usr/local/bin/openssl'         => '/usr/local', # OSX homebrew openssl
	'/opt/local/bin/openssl'         => '/opt/local', # Macports openssl
	'/usr/bin/openssl'               => '/usr',
	'/usr/sbin/openssl'              => '/usr',
	'/opt/ssl/bin/openssl'           => '/opt/ssl',
	'/opt/ssl/sbin/openssl'          => '/opt/ssl',
	'/usr/local/ssl/bin/openssl'     => '/usr/local/ssl',
	'/usr/local/openssl/bin/openssl' => '/usr/local/openssl',
	'/apps/openssl/std/bin/openssl'  => '/apps/openssl/std',
	'/usr/sfw/bin/openssl'           => '/usr/sfw', # Open Solaris
	'C:\OpenSSL\bin\openssl.exe'     => 'C:\OpenSSL',
	'C:\OpenSSL-Win32\bin\openssl.exe'        => 'C:\OpenSSL-Win32',
	$Config{prefix} . '\bin\openssl.exe'      => $Config{prefix},           # strawberry perl
	$Config{prefix} . '\..\c\bin\openssl.exe' => $Config{prefix} . '\..\c', # strawberry perl
	'/sslexe/openssl.exe'            => '/sslroot',  # VMS, openssl.org
	'/ssl111$exe/openssl.exe'        => '/ssl111$root',# VMS, VSI install
	'/ssl1$exe/openssl.exe'          => '/ssl1$root',# VMS, VSI or HPE install
	'/ssl$exe/openssl.exe'           => '/ssl$root', # VMS, HP install
    );

    while (my $k = shift @guesses
           and my $v = shift @guesses) {
        if ( -x $k ) {
            return $v;
        }
    }
    (undef, $dir) = check_no_path()
       and return $dir;

    return;
}

sub find_openssl_exec {
    my ($prefix) = @_;

    my $exe_path;
    for my $subdir (qw( bin sbin out32dll x86_64_exe ia64_exe alpha_exe )) {
        my $path = File::Spec->catfile($prefix, $subdir, "openssl$Config{_exe}");
        if ( -x $path ) {
            return $path;
        }
    }
    ($prefix) = check_no_path()
       and return $prefix;
    return;
}

sub check_openssl_version {
    my ($prefix, $exec) = @_;
    my ( $output, $libssl, $major, $minor, $letter );

    {
        my $pipe = gensym();
        open($pipe, qq{"$exec" version |})
            or die "Could not execute $exec";
        $output = <$pipe>;
        chomp $output;
        close $pipe;

	if ( ($major, $minor, $letter) = $output =~ /^OpenSSL\s+(\d+\.\d+)\.(\d+)([a-z]?)/ ) {
	    print "*** Found OpenSSL-${major}.${minor}${letter} installed in $prefix\n";
	    $libssl = 'openssl';
	} elsif ( ($major, $minor) = $output =~ /^LibreSSL\s+(\d+\.\d+)(?:\.(\d+))?/ ) {
	    # LibreSSL 2.0.x releases only identify themselves as "LibreSSL 2.0",
	    # with no patch release number
	    if ( !defined $minor ) {
	        $minor = "x";
	    }
	    print "*** Found LibreSSL-${major}.${minor} installed in $prefix\n";
	    $libssl = 'libressl';
	} else {
            die <<EOM
*** OpenSSL version test failed
    (`$output' has been returned)
    Either you have bogus OpenSSL or a new version has changed the version
    number format. Please inform the authors!
EOM
        }
    }

    if ($major < 0.9 || ($major == 0.9 && $minor < 8)) {
        print <<EOM;
*** That's too old!
    Please upgrade OpenSSL to the latest version (http://www.openssl.org/)
EOM
        exit 0; # according https://wiki.cpantesters.org/wiki/CPANAuthorNotes this is best-practice when "missing library"
    }

    # On Windows, 64-bit versions of OpenSSL from 1.0.0-beta1 to 1.0.0b are
    # known to malfunction when used in conjunction with pseudoforking processes
    # (see GH-189)
    if (    $Config{archname} =~ m{^MSWin32-x64}
         && $output =~ m{^OpenSSL \s+ 1\.0\.0 (?:-beta[1-5]|[ab])}x ) {
        print <<EOM;
*** 64-bit versions of OpenSSL from 1.0.0-beta1 to 1.0.0b are broken on Windows.
    Please upgrade to OpenSSL 1.0.0c or newer.
EOM
        exit 0;
    }

    # In the LibreSSL 3.2 series, versions below 3.2.4 are not supported because
    # of their libssl-incompatible X.509 verification behaviour (see GH-232)
    if ( $libssl eq 'libressl' && $major eq '3.2' && $minor < 4 ) {
        print <<EOM;
*** LibreSSL 3.2 releases prior to version 3.2.4 are not supported.
    Upgrade to a newer version of LibreSSL.
EOM
        exit UNSUPPORTED_LIBSSL;
    }

    if ($major == 1.1 && $minor > 1) {
        print <<EOM;
*** That's newer than what this module was tested with
    You should consider checking if there is a newer release of this module
    available. Everything will probably work OK, though.
EOM
    }
}

sub fixpath {
    my ($text) = @_;
    my $sep = File::Spec->catdir('');
    $text =~ s{\b/}{$sep}g;
    return $text;
}

sub alert {
    my ( $err, $detail ) = @_;

    local $Text::Wrap::columns = ALERT_WIDTH - 4;

    print "\n";

    print '*' x ALERT_WIDTH, "\n";
    print '* ', uc($err), ' ' x ( ALERT_WIDTH - length($err) - 4 ), ' *', "\n";
    print '*', ' ' x ( ALERT_WIDTH - 2 ), '*', "\n";

    for ( split /\n/, Text::Wrap::wrap( '', '', $detail ) ) {
        print '* ', $_, ' ' x ( ALERT_WIDTH - length($_) - 4 ), ' *', "\n";
    }

    print '*' x ALERT_WIDTH, "\n";
}
