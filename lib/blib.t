#!./perl -Tw

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use strict;

sub _cleanup {
    rmdir foreach reverse qw(blib blib/arch blib/lib);
    unlink "stderr";
}

sub _mkdirs {
    for my $dir (@_) {
        next if -d $dir;
        mkdir $dir or die "Can't mkdir $dir: $!" if ! -d $dir;
    }
}
    

BEGIN { _cleanup }

use Test::More tests => 7;

eval 'use blib;';
ok( $@ =~ /Cannot find blib/, 'Fails if blib directory not found' );

_mkdirs(qw(blib blib/arch blib/lib));

{
    my $warnings;
    local $SIG{__WARN__} = sub { $warnings = join '', @_ };
    use_ok('blib');
    is( $warnings, '',  'use blib is niiiice and quiet' );
}

is( @INC, 3, '@INC now has 3 elements' );
is( $INC[2],    '../lib',       'blib added to the front of @INC' );

ok( grep(m|blib/lib$|, @INC[0,1])  == 1,     '  blib/lib in @INC');
ok( grep(m|blib/arch$|, @INC[0,1]) == 1,     '  blib/arch in @INC');

END { _cleanup(); }
