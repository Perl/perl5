use ExtUtils::MakeMaker;
require 5.003;
die qq{

Your perl is too old for this version of DProf. The last version of
DProf that works for perls older than 5.004 is DProf-19960930 and
should be available from Dean Roehrich\'s directory on CPAN:

    CPAN/authors/id/DMR/

Please either upgrade your perl or get that older DProf from CPAN.

} if $] < 5.004;

if ($] < 5.005) {
  $defines = '';
} else {
  $defines = '-DPERLDBf_NONAME=0x40 -DPERLDBf_GOTO=0x80 -DG_NODEBUG=32 -DPL_NEEDED';
}

$Verbose = 1;
WriteMakefile(
	'NAME'		=> 'Devel::DProf',
	'DISTNAME'	=> 'DProf',
	'VERSION_FROM'	=> 'DProf.pm',
	'clean'		=> {'FILES' => 'tmon.out t/tmon.out t/err dprofpp T/tmon.out'},
	'EXE_FILES'	=> ['dprofpp'],
	'PL_FILES'	=> {'dprofpp.PL' => 'dprofpp'},
	'XSPROTOARG'	=> '-noprototypes',
	'DEFINE'	=> $defines,
	'dist' => { COMPRESS => 'gzip', SUFFIX => 'gz' },
);

sub MY::test_via_harness { "" }
#sub MY::test_via_harness {
#	my( $self, $perl, $tests ) = @_;
#	my $t = quotemeta( $tests );
#	my $res;
#
#	$res = $self->MM::test_via_harness( $perl, $tests );
#	$res =~ s/^(\s+)/$1-/;
#	$res =~ s/(&runtests)/\$\$switches $1/;
#	$res =~ s/(; runtests)/; \$\$switches=q{-d:DProf}$1/;
#	$res =~ s,$t,t/bug.t,;
#	$res;
#}

sub MY::test_via_script {
	my( $self, $perl, $script ) = @_;
	my $res;

	$res = $self->MM::test_via_script( $perl, $script );
	$res =~ s/(test.pl)/$1 -p $perl/;
	$res;
}
