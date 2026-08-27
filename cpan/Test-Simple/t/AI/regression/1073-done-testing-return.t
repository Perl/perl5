use strict;
use warnings;

use Test2::V0;
use File::Temp qw/tempdir/;
use File::Spec;

# done_testing() returns the number of assertions made, so a test file that
# ends with it is true to do() when it ran anything.

my $dir = tempdir(CLEANUP => 1);

my $write = sub {
    my ($name, $body) = @_;

    my $file = File::Spec->catfile($dir, $name);
    open(my $fh, '>', $file) or die "Could not write '$file': $!";
    print $fh $body;
    close($fh) or die "Could not close '$file': $!";

    return $file;
};

# The program the child runs lives in a file, so only paths and the perl
# binary are passed on the command line. A '$' cannot be escaped in a way both
# a POSIX shell and cmd.exe understand, so no program text may go there.
my $run = sub {
    my ($name, $body, @args) = @_;

    my $file = $write->("$name.pl", $body);
    my $cmd_args = join ' ', map { qq{"$_"} } $file, @args;

    # Assign before returning: returning the backticks directly would evaluate
    # them in the caller's context, giving a list of lines to a list caller.
    my $out = `"$^X" "-I" "lib" $cmd_args 2>&1`;

    return $out;
};

subtest tools_basic => sub {
    my ($out) = $run->(basic_three => <<'    EOT');
        use Test2::Tools::Basic;
        ok(1, "one"); ok(1, "two"); ok(1, "three");
        print STDERR "RETURN(" . done_testing() . ")\n";
    EOT
    like($out, qr/RETURN\(3\)/, "returns the number of assertions made");

    ($out) = $run->(basic_none => <<'    EOT');
        use Test2::Tools::Basic;
        my $got = done_testing();
        print STDERR "RETURN(" . (defined($got) ? $got : 'undef') . ")\n";
    EOT
    like($out, qr/RETURN\(0\)/, "returns zero when nothing ran");
};

subtest tools_tiny => sub {
    my ($out) = $run->(tiny_two => <<'    EOT');
        use Test2::Tools::Tiny;
        ok(1, "one"); ok(1, "two");
        print STDERR "RETURN(" . done_testing() . ")\n";
    EOT
    like($out, qr/RETURN\(2\)/, "returns the number of assertions made");

    ($out) = $run->(tiny_none => <<'    EOT');
        use Test2::Tools::Tiny;
        my $got = done_testing();
        print STDERR "RETURN(" . (defined($got) ? $got : 'undef') . ")\n";
    EOT
    like($out, qr/RETURN\(0\)/, "returns zero when nothing ran");
};

subtest do_a_test_file => sub {
    my $target = $write->("as_do.t", "use Test2::V0;\nok(1, 'ran');\ndone_testing;\n");

    my $out = $run->(do_driver => <<'    EOT', $target);
        my $got = do $ARGV[0];
        print STDERR "DO(" . (defined($got) ? $got : 'undef') . ")\n";
    EOT

    like($out, qr/DO\(1\)/, "do() on a test file is true when it ran an assertion");
};

done_testing;
