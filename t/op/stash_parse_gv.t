#!./perl

BEGIN {
    chdir 't' if -d 't';
    require "./test.pl";
    set_up_inc(qw(../lib));
}

plan( tests => 3 );

my $long  = 'x' x 100;
my $short = 'abcd';

my @tests = (
    [ $long, 'long package name: one word' ],
    [ join( '::', $long, $long ), 'long package name: multiple words' ],
    [ join( '::', $long, $short, $long ), 'long & short package name: multiple words' ],
);

foreach my $t (@tests) {
    my ( $sub, $name ) = @$t;

    fresh_perl_is(
        qq[no warnings qw(syntax deprecated); sub $sub { print qq[ok\n]} &{"$sub"}; my \$d = defined *{"foo$sub"} ],
        q[ok],
        { switches => ['-w'] },
        $name
    );
}
