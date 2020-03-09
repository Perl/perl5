#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';	# for which_perl() etc
    plan(3);
}

my $Perl = which_perl();

my $filename = tempfile();

my $x = `$Perl -le "print 'ok';"`;

is($x, "ok\n", "Got expected 'perl -le' output");

open(my $fh,">$filename") || (die "Can't open temp file.");
print {$fh} 'print "ok\n";'; print {$fh} "\n";
close($fh) or die "Could not close: $!";

$x = `$Perl $filename`;

is($x, "ok\n", "Got expected output of command from script");

$x = `$Perl <$filename`;

is($x, "ok\n", "Got expected output of command read from script");
