#!./perl -w

# Herein we apply abs2rel, rel2abs and canonpath against various real
# world files and make sure it all actually works.

BEGIN {
    chdir 't';
    @INC = '../lib';
}

use Config;

use Test::More tests => 5;
use File::Spec;

# Change 'perl' to './perl' so the shell doesn't go looking through PATH.
sub safe_rel {
    return File::Spec->catfile(File::Spec->curdir, $_[0]);
}

# Here we make sure File::Spec can properly deal with executables.
# VMS has some trouble with these.
my $perl = File::Spec->rel2abs($^X);
is( `$^X   -le "print 'ok'"`, "ok\n",   '`` works' );
is( `$perl -le "print 'ok'"`, "ok\n",   'rel2abs($^X)' );

$perl = File::Spec->canonpath($perl);
is( `$perl -le "print 'ok'"`, "ok\n",   'canonpath on abs executable' );

$perl = safe_rel($perl);
is( `$perl -le "print 'ok'"`, "ok\n",   'abs2rel()' );

$perl = File::Spec->canonpath($^X);
is( `$perl -le "print 'ok'"`, "ok\n",   'canonpath on rel executable' );
