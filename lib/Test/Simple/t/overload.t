#!perl -w

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}
chdir 't';

BEGIN {
    # There was a bug with overloaded objects and threads.
    # See rt.cpan.org 4218
    eval { require threads; 'threads'->import; 1; };
}

use Test::More;

BEGIN {
    if( !eval "require overload" ) {
        plan skip_all => "needs overload.pm";
    }
    else {
        plan tests => 3;
    }
}


package Overloaded;

use overload
  q{""} => sub { $_[0]->{string} };

sub new {
    my $class = shift;
    bless { string => shift }, $class;
}


package main;

my $warnings = '';
local $SIG{__WARN__} = sub { $warnings = join '', @_ };
my $obj = Overloaded->new('foo');
ok( 1, $obj );

my $undef = Overloaded->new(undef);
pass( $undef );

is( $warnings, '' );
