#!./perl

# Test the Internal::* functions and other tibits in universal.c

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
    plan( tests => 5 );
}

for my $arg ('', 'q[]', qw( 1 undef )) {
    fresh_perl_is(<<"----", <<'====', "Internals::* functions check their argument under func() AND &func() [perl #77776]");
sub tryit { eval shift or warn \$@ }
tryit "&Internals::SvREADONLY($arg)";
tryit "&Internals::SvREFCNT($arg)";
tryit "&Internals::hv_clear_placeholders($arg)";
tryit "&Internals::HvREHASH($arg)";
----
Usage: Internals::SvREADONLY(SCALAR[, ON]) at (eval 1) line 1.
Usage: Internals::SvREFCNT(SCALAR[, REFCOUNT]) at (eval 2) line 1.
Usage: Internals::hv_clear_placeholders(hv) at (eval 3) line 1.
Internals::HvREHASH $hashref at (eval 4) line 1.
====
}

# Various conundrums with SvREADONLY

$x = *foo;
Internals::SvREADONLY $x, 1;
eval { $x = [] };
like $@, qr/Modification of a read-only value attempted at/,
    'read-only glob copies';
