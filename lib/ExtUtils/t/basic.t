#!/usr/bin/perl -w

# This test puts MakeMaker through the paces of a basic perl module
# build, test and installation of the Big::Fat::Dummy module.

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't' if -d 't';
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}

# The test logic is shared between MakeMaker and Install
# because in MakeMaker we test aspects that we are uninterested
# in with Install.pm, however MakeMaker needs to know if it 
# accidentally breaks Install. So we have this two stage test file
# thing happening.

# This version is distinct to MakeMaker and the core.

use vars qw/$TESTS $TEST_INSTALL_ONLY/;
use Cwd qw(cwd);

$::TESTS= 55 + 30;
$::TEST_INSTALL_ONLY= 0;

(my $start=$0)=~s/\.t$/.pl/;
(my $finish=$start)=~s/\.pl$/_finish.pl/;
my $code;
for my $file ($start,$finish) {
    open my $fh,$file or die "Failed to read: $file";
    $code .= do {
        local $/;
        <$fh>;
    };
    close $fh;
    $code .= "\n;\n";
}
eval $code or die $@,$code;

