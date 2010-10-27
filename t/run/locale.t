#!./perl
BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';    # for fresh_perl_is() etc
}

use strict;

########
# This test is here instead of lib/locale.t because
# the bug depends on in the internal state of the locale
# settings and pragma/locale messes up that state pretty badly.
# We need a "fresh run".
BEGIN {
    eval { require POSIX };
    if ($@) {
	skip_all("could not load the POSIX module"); # running minitest?
    }
}
use Config;
my $have_setlocale = $Config{d_setlocale} eq 'define';
$have_setlocale = 0 if $@;
# Visual C's CRT goes silly on strings of the form "en_US.ISO8859-1"
# and mingw32 uses said silly CRT
$have_setlocale = 0 if (($^O eq 'MSWin32' || $^O eq 'NetWare') && $Config{cc} =~ /^(cl|gcc)/i);
skip_all("no setlocale available") unless $have_setlocale;
my @locales;
if (-x "/usr/bin/locale" && open(LOCALES, "/usr/bin/locale -a 2>/dev/null|")) {
    while(<LOCALES>) {
        chomp;
        push(@locales, $_);
    }
    close(LOCALES);
}
skip_all("no locales available") unless @locales;

plan tests => &last;
fresh_perl_is("for (qw(@locales)) {\n" . <<'EOF',
    use POSIX qw(locale_h);
    use locale;
    setlocale(LC_NUMERIC, "$_") or next;
    my $s = sprintf "%g %g", 3.1, 3.1;
    next if $s eq '3.1 3.1' || $s =~ /^(3.+1) \1$/;
    print "$_ $s\n";
}
EOF
    "", {}, "no locales where LC_NUMERIC breaks");

sub last { 1 }
