use strict;
use warnings;
use Test::More qw/modern/;
use Test::Tester2;
use PerlIO;
use utf8;

our $default_utf8 = grep { $_ eq 'utf8' } PerlIO::get_layers(\*STDOUT);

helpers qw/my_ok/;
sub my_ok { Test::Builder->new->ok(@_) }

helpers qw/my_nester/;
sub my_nester(&) {
    my $code = shift;
    Test::Builder->new->ok(
        nest {$code->()},
        "my_nester exit"
    )
}

my @lines;

my $events = intercept {
    my_ok( 1, "good" ); push @lines => __LINE__;
    my_ok( 0, "bad" );  push @lines => __LINE__;

    my_nester { 1 }; push @lines => __LINE__;

    my_nester {
        my_ok( 1, "good nested" ); push @lines => __LINE__;
        my_ok( 0, "bad nested" );  push @lines => __LINE__;
        0;
    }; push @lines => __LINE__;
};

events_are(
    $events,

    ok   => { line => $lines[0], bool => 1, name => "good" },
    ok   => { line => $lines[1], bool => 0, name => "bad" },
    diag => { line => $lines[1], message => qr/failed test 'bad'/i },

    ok   => { line => $lines[2], bool => 1, name => "my_nester exit" },

    ok   => { line => $lines[3], bool => 1, name => "good nested" },
    ok   => { line => $lines[4], bool => 0, name => "bad nested" },
    diag => { line => $lines[4], message => qr/failed test 'bad nested'/i },
    ok   => { line => $lines[5], bool => 0, name => "my_nester exit" },
);

helpers 'helped';

my %place;
sub helped(&) {
    my ($CODE) = @_;

    diag( 'setup' );
    ok( nest(\&$CODE), 'test ran' );
    diag( 'teardown' );
};

$events = intercept {
    helped {
        ok(0 ,'helped test' ); $place{helped} = __LINE__; 0;
    }; $place{inhelp} = __LINE__;
};

events_are(
    $events,

    diag => { message => 'setup' },

    ok => { bool => 0, line => $place{helped} },
    diag => { message => qr/failed test.*$place{helped}/ism, line => $place{helped} },

    ok => { bool => 0, line => $place{inhelp} },
    diag => { message => qr/failed test.*$place{inhelp}/ism, line => $place{inhelp} },

    diag => { message => 'teardown' },
);

my $ok = eval { Test::More->import(import => ['$TODO']) };
ok($ok, "Can import \$TODO");

{
    package main_modern;
    use Test::More 'utf8';
    use Test::Tester2;

    my $events = intercept { ok(1, "blah") };
    is($events->[0]->encoding, 'utf8', "utf8 encoding set for modern");

    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings => @_ };
        ok(1, "Ճȴģȳф utf8 name");
        subtest 'Ճȴģȳф utf8 name - subtest name' => sub {
            ok(1, "Ճȴģȳф utf8 name - in subtest");
        };
        ok(1, "Ճȴģȳф utf8 name - after subtest");
    }
    ok(!@warnings, "no warnings");
}

SKIP: {
    package main_old;
    use Test::More;
    use Test::Tester2;

    skip "UTF8 by default, skipping legacy" => 5
        if $main::default_utf8;

    my $events = intercept { ok(1, "blah") };
    is($events->[0]->encoding, 'legacy', "legacy encoding set for non-modern");

    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings => @_ };
        ok(1, "Ճȴģȳф utf8 name");
        subtest 'Ճȴģȳф utf8 name - subtest name' => sub {
            ok(1, "Ճȴģȳф utf8 name - in subtest");
        };
        ok(1, "Ճȴģȳф utf8 name - after subtest");
    }

    chomp(@warnings);
    is_deeply(
        [ map { s/ at.*$//; $_ } @warnings],
        [
            'Wide character in print',
            'Wide character in print',
            'Wide character in print',
            'Wide character in print',
            'Wide character in print',
        ],
        "utf8 is not on."
    );
}

{
    package main_oblivious;
    use Test::Tester2;

    my $events = intercept { Test::More::ok(1, "blah") };
    Test::More::is($events->[0]->encoding, undef, "no encoding set for non-consumer");
}

{
    package arg_encoding;
    use Test::More encoding => 'utf8';
    use Test::Tester2;

    my $events = intercept { ok(1, "blah") };
    is($events->[0]->encoding, 'utf8', "utf8 encoding set by arg encoding");

    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings => @_ };
        ok(1, "Ճȴģȳф utf8 name");
    }
    ok(!@warnings, "no warnings - argument 'encoding'");
}


require PerlIO;
my $legacy = Test::Builder->new->tap->io_set('legacy')->[0];
my $modern = Test::Builder->new->tap->io_set('utf8')->[0];
ok( (grep { $_ eq 'utf8' } PerlIO::get_layers($modern)),  "Did add utf8 to UTF8 handle" );
SKIP: {
    skip "UTF8 by default, skipping legacy" => 2
        if $main::default_utf8;
    ok( !(grep { $_ eq 'utf8' } PerlIO::get_layers(\*STDOUT)), "Did not add utf8 to STDOUT" );
    ok( !(grep { $_ eq 'utf8' } PerlIO::get_layers($legacy)),  "Did not add utf8 to legacy" );
}

done_testing;
