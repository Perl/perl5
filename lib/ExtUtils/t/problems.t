# Test problems in Makefile.PL's and hint files.

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't' if -d 't';
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}
$ENV{PERL_CORE} ? chdir '../lib/ExtUtils/t' : chdir 't';

use strict;
use Test::More tests => 3;
use ExtUtils::MM;
use TieOut;

my $MM = bless { DIR => ['subdir'] }, 'MM';

ok( chdir 'Problem-Module', "chdir'd to Problem-Module" ) ||
  diag("chdir failed: $!");


# Make sure when Makefile.PL's break, they issue a warning.
# Also make sure Makefile.PL's in subdirs still have '.' in @INC.
my $stdout;
$stdout = tie *STDOUT, 'TieOut' or die;
{
    my $warning = '';
    local $SIG{__WARN__} = sub { $warning = join '', @_ };
    $MM->eval_in_subdirs;

    is( $stdout->read, qq{\@INC has .\n}, 'cwd in @INC' );
    like( $warning, 
          qr{^WARNING from evaluation of .*subdir.*Makefile.PL: YYYAaaaakkk},
          'Makefile.PL death in subdir warns' );

    untie *STDOUT;
}
