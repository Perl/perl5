use ExtUtils::MakeMaker;

my @extra;
my $PERL_CORE = grep $_ eq "PERL_CORE=1", @ARGV;
push @extra, 'MAN3PODS' => {} if $PERL_CORE;
push @extra, 'INSTALLDIRS'  => 'perl' if $] >= 5.00903;

WriteMakefile(
    'NAME'		=> 'Math::BigInt::FastCalc',
    'VERSION_FROM'	=> 'FastCalc.pm',	# finds $VERSION
    'PREREQ_PM'		=> {
	Math::BigInt => 1.76,
    },
    @extra,
);
