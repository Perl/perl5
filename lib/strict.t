#!./perl

chdir 't' if -d 't';
@INC = ( '.', '../lib' );

our $local_tests = 4 + 3*42 + 3*12 + 3*3*38 + 3*11 + 3*18;
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

{
    test_strict_all "use strict", "rvs";
    test_strict_all "no strict", "";
    test_strict_all "use strict; no strict", "";
    test_strict_all "no strict; use strict", "rvs";
    test_strict_all "use strict; no strict 'firmly'", "";
    test_strict_all "no strict; use strict 'firmly'", "rvs";
    test_strict_all "use strict; no strict 'softly';", "rvs";
    test_strict_all "no strict; use strict 'softly';", "";
    test_strict_all "use strict; no strict 'forcing_softness';", "";
    test_strict_all "no strict; use strict 'forcing_softness';", "rvs";
    test_strict_all "use strict 'firmly'", "rvs";
    test_strict_all "no strict 'firmly'", "";
    test_strict_all "use strict 'firmly'; no strict", "";
    test_strict_all "no strict 'firmly'; use strict", "rvs";
    test_strict_all "use strict 'firmly'; no strict 'firmly'", "";
    test_strict_all "no strict 'firmly'; use strict 'firmly'", "rvs";
    test_strict_all "use strict 'firmly'; no strict 'softly';", "rvs";
    test_strict_all "no strict 'firmly'; use strict 'softly';", "";
    test_strict_all "use strict 'firmly'; no strict 'forcing_softness';", "";
    test_strict_all "no strict 'firmly'; use strict 'forcing_softness';", "rvs";
    test_strict_all "use strict 'softly'", "rvs";
    test_strict_all "no strict 'softly'", "";
    test_strict_all "use strict 'softly'; no strict", "";
    test_strict_all "no strict 'softly'; use strict", "rvs";
    test_strict_all "use strict 'softly'; no strict 'firmly'", "";
    test_strict_all "no strict 'softly'; use strict 'firmly'", "rvs";
    test_strict_all "use strict 'softly'; no strict 'softly'", "";
    test_strict_all "no strict 'softly'; use strict 'softly'", "rvs";
    test_strict_all "use strict 'softly'; no strict 'forcing_softness'", "";
    test_strict_all "no strict 'softly'; use strict 'forcing_softness'", "rvs";
    test_strict_all "use strict 'forcing_softness'", "rvs";
    test_strict_all "no strict 'forcing_softness'", "";
    test_strict_all "use strict 'forcing_softness'; no strict", "";
    test_strict_all "no strict 'forcing_softness'; use strict", "rvs";
    test_strict_all "use strict 'forcing_softness'; no strict 'firmly'", "";
    test_strict_all "no strict 'forcing_softness'; use strict 'firmly'", "rvs";
    test_strict_all "use strict 'forcing_softness'; no strict 'softly'", "";
    test_strict_all "no strict 'forcing_softness'; use strict 'softly'", "rvs";
    test_strict_all "use strict 'forcing_softness'; no strict 'forcing_softness'", "";
    test_strict_all "no strict 'forcing_softness'; use strict 'forcing_softness'", "rvs";
    test_strict_all "use strict; no strict 'forcing_softness'; use strict 'softly'", "rvs";
    test_strict_all "no strict; use strict 'forcing_softness'; no strict 'softly'", "";
}

{
    test_strict_all "use strict 'refs'; no strict 'softly'", "r";
    test_strict_all "use strict 'vars'; no strict 'softly'", "v";
    test_strict_all "use strict 'subs'; no strict 'softly'", "s";
    test_strict_all "no strict 'refs'; use strict 'softly'", "vs";
    test_strict_all "no strict 'vars'; use strict 'softly'", "rs";
    test_strict_all "no strict 'subs'; use strict 'softly'", "rv";
    test_strict_all "use strict softly => 'refs'", "r";
    test_strict_all "use strict softly => 'vars'", "v";
    test_strict_all "use strict softly => 'subs'", "s";
    test_strict_all "no strict; use strict softly => 'refs'", "";
    test_strict_all "no strict; use strict softly => 'vars'", "";
    test_strict_all "no strict; use strict softly => 'subs'", "";
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
