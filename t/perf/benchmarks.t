#!./perl
#
# Execute the various code snippets in t/perf/benchmarks
# to ensure that they are all syntactically correct

BEGIN {
    chdir 't';
    require './test.pl';
    @INC = ('.', '../lib');
}

use warnings;
use strict;


my $file = 'perf/benchmarks';
my $benchmarks = do $file;
die $@ if $@;
die "$! while trying to read '$file'" if $!;
die "'$file' did not return a hash ref\n" unless ref $benchmarks eq 'HASH';

plan keys(%$benchmarks) * 3;


# check the hash of hashes is minimally consistent in format

for my $token (sort keys %$benchmarks) {
    like($token, qr/^[a-zA-z]\w*$/a, "legal token: $token");
    my $keys = join('-', sort keys %{$benchmarks->{$token}});
    is($keys, 'code-desc-setup', "legal keys:  $token");
}

# check that each bit of code compiles and runs

for my $token (sort keys %$benchmarks) {
    my $b = $benchmarks->{$token};
    my $code = "package $token; $b->{setup}; for (1..1) { $b->{code} } 1;";
    ok(eval $code, "running $token")
        or do {
            diag("code:");
            diag($code);
            diag("gave:");
            diag($@);
        }
}


