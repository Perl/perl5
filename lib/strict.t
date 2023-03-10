#!./perl

chdir 't' if -d 't';
@INC = ( '.', '../lib' );

our $local_tests = 4 + 3*3*38 + 3*11 + 3*18;
require "../t/lib/common.pl";

eval qq(use strict 'garbage');
like($@, qr/^Unknown 'strict' tag\(s\) 'garbage'/);

eval qq(no strict 'garbage');
like($@, qr/^Unknown 'strict' tag\(s\) 'garbage'/);

eval qq(use strict qw(foo bar));
like($@, qr/^Unknown 'strict' tag\(s\) 'foo bar'/);

eval qq(no strict qw(foo bar));
like($@, qr/^Unknown 'strict' tag\(s\) 'foo bar'/);

my $varname = "ccccc";
sub test_strict_all {
    my($preamble, $expect) = @_;
    my $expect_r = $expect =~ /r/;
    eval $preamble.'; ${"ccc"}';
    like($@,
        $expect_r ?
            qr/\ACan't\ use\ string\ \("ccc"\)\ as\ a\ SCALAR\ ref
                \ while\ "strict\ refs"\ in\ use/x :
        qr/\A\z/,
        "\"$preamble\" yields strict refs @{[$expect_r ? q(on) : q(off)]}");
    my $expect_v = $expect =~ /v/;
    ++$varname;
    eval $preamble.'; $'.$varname;
    like($@,
        $expect_v ?
            qr/\AGlobal\ symbol\ "\$\Q${varname}\E"\ requires
                \ explicit\ package\ name\ /x :
            qr/\A\z/,
        "\"$preamble\" yields strict vars @{[$expect_v ? q(on) : q(off)]}");
    my $expect_s = $expect =~ /s/;
    eval $preamble.'; Ccc';
    like($@,
        $expect_s ?
            qr/\ABareword\ "Ccc"\ not\ allowed
                \ while\ "strict\ subs"\ in\ use/x :
            qr/\A\z/,
        "\"$preamble\" yields strict subs @{[$expect_s ? q(on) : q(off)]}");
}

foreach my $minor (0..10) {
    test_strict_all "use v5.$minor", "";
    test_strict_all "use strict; use v5.$minor", "rvs";
    test_strict_all "no strict; use v5.$minor", "";
}
foreach my $minor (11..36) {
    test_strict_all "use v5.$minor", "rvs";
    test_strict_all "use strict; use v5.$minor", "rvs";
    test_strict_all "no strict; use v5.$minor", "";
}
foreach my $minor (37..37) {
    test_strict_all "use v5.$minor", "rvs";
    test_strict_all "use strict; use v5.$minor", "rvs";
    test_strict_all "no strict; use v5.$minor", "rvs";
}

{
    test_strict_all "use v5.8; use v5.10", "";
    test_strict_all "use v5.10; use v5.8", "";
    test_strict_all "use v5.10; use v5.16", "rvs";
    test_strict_all "use v5.10; use v5.37", "rvs";
    test_strict_all "use v5.16; use v5.10", "";
    test_strict_all "use v5.16; use v5.20", "rvs";
    test_strict_all "use v5.20; use v5.16", "rvs";
    test_strict_all "use v5.16; use v5.37", "rvs";
    test_strict_all "use v5.37; use v5.10", "rvs";
    test_strict_all "use v5.37; use v5.16", "rvs";
    test_strict_all "use v5.37; use v5.37", "rvs";
}

{
    test_strict_all "use strict 'refs'; use v5.10", "r";
    test_strict_all "use strict 'vars'; use v5.10", "v";
    test_strict_all "use strict 'subs'; use v5.10", "s";
    test_strict_all "no strict 'refs'; use v5.10", "";
    test_strict_all "no strict 'vars'; use v5.10", "";
    test_strict_all "no strict 'subs'; use v5.10", "";
    test_strict_all "use strict 'refs'; use v5.16", "rvs";
    test_strict_all "use strict 'vars'; use v5.16", "rvs";
    test_strict_all "use strict 'subs'; use v5.16", "rvs";
    test_strict_all "no strict 'refs'; use v5.16", "vs";
    test_strict_all "no strict 'vars'; use v5.16", "rs";
    test_strict_all "no strict 'subs'; use v5.16", "rv";
    test_strict_all "use strict 'refs'; use v5.37", "rvs";
    test_strict_all "use strict 'vars'; use v5.37", "rvs";
    test_strict_all "use strict 'subs'; use v5.37", "rvs";
    test_strict_all "no strict 'refs'; use v5.37", "rvs";
    test_strict_all "no strict 'vars'; use v5.37", "rvs";
    test_strict_all "no strict 'subs'; use v5.37", "rvs";
}
