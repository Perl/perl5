#!./perl -w

# Herein we apply abs2rel, rel2abs and canonpath against various real
# world files and make sure it all actually works.

BEGIN {
    chdir 't';
    @INC = '../lib';
}

use Config;
$ENV{'PATH'} = '.' . $Config{'path_sep'} . $ENV{'PATH'};

use Test::More tests => 5;
use File::Spec;

# Here we make sure File::Spec can properly deal with executables.
# VMS has some trouble with these.
my $perl = File::Spec->rel2abs($^X);
is( `$^X   -le "print 'ok'"`, "ok\n",   '`` works' );
is( `$perl -le "print 'ok'"`, "ok\n",   'rel2abs($^X)' );

$perl = File::Spec->canonpath($perl);
is( `$perl -le "print 'ok'"`, "ok\n",   'canonpath on abs executable' );

$perl = File::Spec->abs2rel($perl);
is( `$perl -le "print 'ok'"`, "ok\n",   'abs2rel()' );

$perl = File::Spec->canonpath($^X);
is( `$perl -le "print 'ok'"`, "ok\n",   'canonpath on rel executable' );
