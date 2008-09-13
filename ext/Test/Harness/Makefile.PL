#!/usr/bin/perl -w

# This Makefile.PL is provided for installation compatibility.
# Extra developer actions are in the Build.PL.

use ExtUtils::MakeMaker qw/WriteMakefile prompt/;

use strict;

my $core = grep { $_ eq 'PERL_CORE=1' } @ARGV;

my %mm_args = (
    'NAME'         => 'Test::Harness',
    'VERSION_FROM' => 'lib/Test/Harness.pm',
    'PREREQ_PM'    => {
        'File::Spec' => 0.8,
    },
    'INSTALLDIRS' => 'perl',
    'PL_FILES'    => {},
    'test'        => { 'TESTS' => 't/*.t t/compat/*.t' },

    # In the core pods will be built by installman, and prove found by
    # utils/prove.PL
    $core
    ? ( 'MAN3PODS' => {} )
    : ( 'EXE_FILES' => ['bin/prove'],
    ),
);

{
    local $^W = 0;    # Silence warning about non-numeric version
    if ( $ExtUtils::MakeMaker::VERSION >= '6.31' ) {
        $mm_args{LICENSE} = 'perl';
    }
}

WriteMakefile(%mm_args);

package MY;

# Lifted from MM_Any.pm and modified so that make test tests against our
# own code rather than the incumbent. If we don't do this we end up
# loading a confused mixture of installed and new modules.
sub test_via_harness {
    my ( $self, $perl, $tests ) = @_;

    return $self->SUPER::test_via_harness(
        qq{$perl "-I\$(INST_LIB)" "-I\$(INST_ARCHLIB)"}, $tests );
}
