#!perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

# Can't use Test.pm, that's a 5.005 thing.
print "1..3\n";

my $test_num = 1;
# Utility testing functions.
sub ok ($;$) {
    my($test, $name) = @_;
    my $ok = '';
    $ok .= "not " unless $test;
    $ok .= "ok $test_num";
    $ok .= " - $name" if defined $name;
    $ok .= "\n";
    print $ok;
    $test_num++;
}

use Test::Builder;
my $Test = Test::Builder->new();

my $result;
my $out = $Test->output('foo');

ok( defined $out );

print $out "hi!\n";
close *$out;

undef $out;
open(IN, 'foo') or die $!;
chomp(my $line = <IN>);
close IN;

ok($line eq 'hi!');

open(FOO, ">>foo") or die $!;
$out = $Test->output(\*FOO);
$old = select *$out;
print "Hello!\n";
close *$out;
undef $out;
select $old;
open(IN, 'foo') or die $!;
my @lines = <IN>;
close IN;

ok($lines[1] =~ /Hello!/);

unlink('foo');
