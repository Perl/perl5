#!./perl
#
# Tests for Perl mad environment
#
# $PERL_XMLDUMP

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require Config; import Config;
    require './test.pl';
    skip_all_without_config('mad');
}

use File::Path;

my $tempdir = tempfile;

mkdir $tempdir, 0700 or die "Can't mkdir '$tempdir': $!";
chdir $tempdir or die die "Can't chdir '$tempdir': $!";
unshift @INC, '../../lib';
my $cleanup = 1;

END {
    if ($cleanup) {
	chdir '..' or die "Couldn't chdir .. for cleanup: $!";
	rmtree($tempdir);
    }
}

plan tests => 4;

{
    local %ENV = %ENV;
    $ENV{PERL_XMLDUMP} = "withoutT.xml";
    fresh_perl_is('print q/hello/', '', {}, 'mad without -T');
    ok(-f "withoutT.xml", "xml file created without -T as expected");
}

{
    local %ENV = %ENV;
    $ENV{PERL_XMLDUMP} = "withT.xml";
    fresh_perl_is('print q/hello/', 'hello', { switches => [ "-T" ] },
		  'mad with -T');
    ok(!-e "withT.xml", "no xml file created with -T as expected");
}
