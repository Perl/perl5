#!./perl

chdir 't' if -d 't';
@INC = ( '.', '../lib' );

our $local_tests = 6 + 3*3*40 + 3*11 + 3*18;
require "../t/lib/common.pl";

eval qq(use strict 'garbage');
like($@, qr/^Unknown 'strict' tag\(s\) 'garbage'/);

eval qq(no strict 'garbage');
like($@, qr/^Unknown 'strict' tag\(s\) 'garbage'/);

eval qq(use strict qw(foo bar));
like($@, qr/^Unknown 'strict' tag\(s\) 'foo bar'/);

eval qq(no strict qw(foo bar));
like($@, qr/^Unknown 'strict' tag\(s\) 'foo bar'/);

{
    my $warnings = "";
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    eval 'use v5.12; use v5.10; ${"c"}';
    is($@, '', 'use v5.10 disables implicit strict refs');
    like($warnings,
        qr/^Downgrading a use VERSION declaration to below v5.11 is deprecated, and will become fatal in Perl 5.40 at /,
        'use v5.10 after use v5.12 provokes deprecation warning');
}

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
foreach my $minor (11..38) {
    test_strict_all "use v5.$minor", "rvs";
    test_strict_all "use strict; use v5.$minor", "rvs";
    test_strict_all "no strict; use v5.$minor", "";
}
foreach my $minor (39..39) {
    test_strict_all "use v5.$minor", "rvs";
    test_strict_all "use strict; use v5.$minor", "rvs";
    test_strict_all "no strict; use v5.$minor", "rvs";
}

{
    test_strict_all "use v5.8; use v5.10", "";
    test_strict_all "use v5.10; use v5.8", "";
    test_strict_all "use v5.10; use v5.16", "rvs";
    test_strict_all "use v5.10; use v5.39", "rvs";
    {
        local $SIG{__WARN__} = sub {};
        test_strict_all "use v5.16; use v5.10", "";
    }
    test_strict_all "use v5.16; use v5.20", "rvs";
    test_strict_all "use v5.20; use v5.16", "rvs";
    test_strict_all "use v5.16; use v5.39", "rvs";
    {
        local $SIG{__WARN__} = sub {};
        test_strict_all "use v5.39; use v5.10", "rvs";
    }
    test_strict_all "use v5.39; use v5.16", "rvs";
    test_strict_all "use v5.39; use v5.39", "rvs";
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
    test_strict_all "use strict 'refs'; use v5.39", "rvs";
    test_strict_all "use strict 'vars'; use v5.39", "rvs";
    test_strict_all "use strict 'subs'; use v5.39", "rvs";
    test_strict_all "no strict 'refs'; use v5.39", "rvs";
    test_strict_all "no strict 'vars'; use v5.39", "rvs";
    test_strict_all "no strict 'subs'; use v5.39", "rvs";
}
