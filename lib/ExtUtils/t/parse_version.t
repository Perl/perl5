#!/usr/bin/perl -w

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = '../lib';
    }
    else {
        unshift @INC, 't/lib';
    }
}
chdir 't';

use Test::More;
use ExtUtils::MakeMaker;

my %versions = (q[$VERSION = '1.00']        => '1.00',
                q[*VERSION = \'1.01']       => '1.01',
                q[($VERSION) = q$Revision: 32208 $ =~ /(\d+)/g;] => 32208,
                q[$FOO::VERSION = '1.10';]  => '1.10',
                q[*FOO::VERSION = \'1.11';] => '1.11',
                '$VERSION = 0.02'   => 0.02,
                '$VERSION = 0.0'    => 0.0,
                '$VERSION = -1.0'   => -1.0,
                '$VERSION = undef'  => 'undef',
                '$wibble  = 1.0'    => 'undef',
                q[my $VERSION = '1.01']         => 'undef',
                q[local $VERISON = '1.02']      => 'undef',
                q[local $FOO::VERSION = '1.30'] => 'undef',
               );

if( eval 'our $foo' ) {
    $versions{q[our $VERSION = '1.23';]}   = '1.23',
}

if( eval 'require version; "version"->import' ) {
    $versions{q[use version; $VERSION = qv(1.2.3);]} = qv(1.2.3);
    $versions{q[$VERSION = qv(1.2.3)]}               = qv(1.2.3);
}

plan tests => 2 * keys %versions;

while( my($code, $expect) = each %versions ) {
    open(FILE, ">VERSION.tmp") || die $!;
    print FILE "$code\n";
    close FILE;

    $_ = 'foo';
    is( MM->parse_version('VERSION.tmp'), $expect, $code );
    is( $_, 'foo', '$_ not leaked by parse_version' );

    unlink "VERSION.tmp";
}
