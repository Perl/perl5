use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;

my $perl_core = grep { $_ eq 'PERL_CORE=1' } @ARGV;
my $u64uf = $Config{d_PRIu64} && $Config{sPRIu64};

die "This Perl cannot format unsigned 64-bit integers\n"
    unless $perl_core || defined $u64uf;

my $define = $perl_core ? '' : qq{-DU64uf=$u64uf};
$define =~ s/"/\\"/g;

# SystemFunction036 (RtlGenRandom) is exported by advapi32.  -l spelling is
# accepted by both MinGW and the Microsoft toolchain through MakeMaker.
my @libs = $^O eq 'MSWin32' ? ('-ladvapi32') : ();

WriteMakefile(
    NAME         => 'RNG',
    VERSION_FROM => 'lib/RNG.pm',
    ABSTRACT_FROM => 'lib/RNG.pm',
    AUTHOR       => 'Perl Porters',
    LICENSE      => 'perl',
    MIN_PERL_VERSION => '5.024000',
    PREREQ_PM    => { 'List::Util' => '1.54' },
    LIBS         => \@libs,
    DEFINE       => $define,
    XS           => { 'RNG.xs' => 'RNG.c' },
    clean        => { FILES => 'RNG.c' },
    ( $perl_core
        ? ()
        : ( INSTALLDIRS => ( $] < 5.011 ? 'perl' : 'site' ) )
    ),
);
