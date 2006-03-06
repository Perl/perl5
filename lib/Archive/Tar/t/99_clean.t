#!perl
BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir '../lib/Archive/Tar' if -d '../lib/Archive/Tar';
    }       
    use lib '../../..';
}

BEGIN { chdir 't' if -d 't' }

use lib '../lib';
use File::Spec ();
use Test::More 'no_plan';

for my $d (qw(long short)) { 
    for my $f (qw(b bar.tar foo.tgz)) {

        my $path = File::Spec->catfile('src', $d, $f);
        ok( -e $path,   "File $path exists" );

        1 while unlink $path;

        ok(!-e $path,   "   File deleted" );
    }

    my $dir = File::Spec->catdir('src', $d);

    ok( -d $dir,        "Dir $dir exists" );
    1 while rmdir $dir;
    ok(!-d $dir,        "   Dir deleted" );
    
}

{   my $dir = 'src';
    ok( -d $dir,        "Dir $dir exists" );
    1 while rmdir $dir;
    ok(!-d $dir,        "   Dir deleted" );
}
