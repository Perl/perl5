#!/usr/bin/env perl -w

# Examples from test_pl.pod

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc( '../lib' );
}

use strict;
use warnings;

watchdog(10);

{
    my $pi = 3.14159265;
    within(sin($pi/6), 0.5, 0.0001, "sin(PI/6) is sane");
    within(cos($pi/2), 0, 0.0001, "cos(PI/2) is sane");
}

{
    my $x = \(1+1);
    refcount_is($x, 1, "only one reference");
    my $ref = $x;
    refcount_is($x, 2, "two references");
}
{
    object_ok(*STDERR{IO}, "IO::Handle", "check STDERR is IO");
}
{
    use IO::File;
    class_ok("IO::File", "IO::Handle", "Check IO::File is a class");
}
{
    warnings_like(sub { my $x; $x+1 },
                  [ qr/^Use of uninitialized value \$x in addition/ ],
                  "undefined value in addition");
}
{
    warning_is(sub {
#line 1 "fake.pl"
    my $x; $x+1
}, "Use of uninitialized value \$x in addition (+) at fake.pl line 1.\n",
              "exact warning check");
}

{
    warning_like(sub { my $x; $x+1 },
                 qr/^Use of uninitialized value \$x in addition/,
                 "undefined value in addition");
}

{
    fresh_perl_is(<<~'CODE', "Hello\n", {}, "test print");
    print "Hello\n";
    CODE
    fresh_perl_like(<<~'CODE', qr/^Hello at/, {}, "test print like");
    die "Hello";
    CODE
}

{
    run_multiple_progs('', \*DATA);
}

{
    my $out = runperl(prog => "print qq(Hello\n)");
    is($out, "Hello\n", "runperl");
}
{
    my @warnings = capture_warnings(sub { my $x; $x+1 });
    is(@warnings, 1, "captured one warning");
    like($warnings[0], qr/^Use of uninitialized value \$x in addition/,
         "check undefined value in addition warning");
}
watchdog(0);

done_testing;

__END__
# NAME first multi test
print "One\n";
EXPECT
One
########
# NAME second multi test
die "Two";
EXPECT
OPTIONS fatal
Two at - line 1.
