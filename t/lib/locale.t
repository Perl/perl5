#!./perl -wT

print "1..67\n";

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use strict;
use POSIX qw(locale_h);

use vars qw($a
	    $English $German $French $Spanish
	    @C @English @German @French @Spanish
	    $Locale @Locale %iLocale %UPPER %lower @Neoalpha);

$a = 'abc %';

sub ok {
    my ($n, $result) = @_;

    print 'not ' unless ($result);
    print "ok $n\n";
}

# First we'll do a lot of taint checking for locales.
# This is the easiest to test, actually, as any locale,
# even the default locale will taint under 'use locale'.

sub is_tainted { # hello, camel two.
    my $dummy;
    not eval { $dummy = join("", @_), kill 0; 1 }
}

sub check_taint ($$) {
    ok $_[0], is_tainted($_[1]);
}

sub check_taint_not ($$) {
    ok $_[0], not is_tainted($_[1]);
}

use locale;	# engage locale and therefore locale taint.

check_taint_not   1, $a;

check_taint       2, uc($a);
check_taint       3, "\U$a";
check_taint       4, ucfirst($a);
check_taint       5, "\u$a";
check_taint       6, lc($a);
check_taint       7, "\L$a";
check_taint       8, lcfirst($a);
check_taint       9, "\l$a";

check_taint      10, sprintf('%e', 123.456);
check_taint      11, sprintf('%f', 123.456);
check_taint      12, sprintf('%g', 123.456);
check_taint_not  13, sprintf('%d', 123.456);
check_taint_not  14, sprintf('%x', 123.456);

$_ = $a;	# untaint $_

$_ = uc($a);	# taint $_

check_taint      15, $_;

/(\w)/;	# taint $&, $`, $', $+, $1.
check_taint      16, $&;
check_taint      17, $`;
check_taint      18, $';
check_taint      19, $+;
check_taint      20, $1;
check_taint_not  21, $2;

/(\W)/;	# taint $&, $`, $', $+, $1.
check_taint      22, $&;
check_taint      23, $`;
check_taint      24, $';
check_taint      25, $+;
check_taint      26, $1;
check_taint_not  27, $2;

/(\s)/;	# taint $&, $`, $', $+, $1.
check_taint      28, $&;
check_taint      29, $`;
check_taint      30, $';
check_taint      31, $+;
check_taint      32, $1;
check_taint_not  33, $2;

/(\S)/;	# taint $&, $`, $', $+, $1.
check_taint      34, $&;
check_taint      35, $`;
check_taint      36, $';
check_taint      37, $+;
check_taint      38, $1;
check_taint_not  39, $2;

$_ = $a;	# untaint $_

check_taint_not  40, $_;

/(b)/;		# this must not taint
check_taint_not  41, $&;
check_taint_not  42, $`;
check_taint_not  43, $';
check_taint_not  44, $+;
check_taint_not  45, $1;
check_taint_not  46, $2;

$_ = $a;	# untaint $_

check_taint_not  47, $_;

$b = uc($a);	# taint $b
s/(.+)/$b/;	# this must taint only the $_

check_taint      48, $_;
check_taint_not  49, $&;
check_taint_not  50, $`;
check_taint_not  51, $';
check_taint_not  52, $+;
check_taint_not  53, $1;
check_taint_not  54, $2;

$_ = $a;	# untaint $_

s/(.+)/b/;	# this must not taint
check_taint_not  55, $_;
check_taint_not  56, $&;
check_taint_not  57, $`;
check_taint_not  58, $';
check_taint_not  59, $+;
check_taint_not  60, $1;
check_taint_not  61, $2;

check_taint_not  62, $a;

# I think we've seen quite enough of taint.
# Let us do some *real* locale work now.

sub getalnum {
    sort grep /\w/, map { chr } 0..255
}

sub locatelocale ($$@) {
    my ($lcall, $alnum, @try) = @_;

    undef $$lcall;

    for (@try) {
	local $^W = 0; # suppress "Subroutine LC_ALL redefined"
	if (setlocale(LC_ALL, $_)) {
	    $$lcall = $_;
	    @$alnum = &getalnum;
	    last;
	}
    }

    @$alnum = () unless (defined $$lcall);
}

# Find some default locale

locatelocale(\$Locale, \@Locale, qw(C POSIX));

# Find some English locale

locatelocale(\$English, \@English,
	     qw(en_US.ISO8859-1 en_GB.ISO8859-1
		en en_US en_UK en_IE en_CA en_AU en_NZ
		english english.iso88591
		american american.iso88591
		british british.iso88591
		));

# Find some German locale

locatelocale(\$German, \@German,
	     qw(de_DE.ISO8859-1 de_AT.ISO8859-1 de_CH.ISO8859-1
		de de_DE de_AT de_CH
		german german.iso88591));

# Find some French locale

locatelocale(\$French, \@French,
	     qw(fr_FR.ISO8859-1 fr_BE.ISO8859-1 fr_CA.ISO8859-1 fr_CH.ISO8859-1
		fr fr_FR fr_BE fr_CA fr_CH
		french french.iso88591));

# Find some Spanish locale

locatelocale(\$Spanish, \@Spanish,
	     qw(es_AR.ISO8859-1 es_BO.ISO8859-1 es_CL.ISO8859-1
		es_CO.ISO8859-1 es_CR.ISO8859-1 es_EC.ISO8859-1
		es_ES.ISO8859-1 es_GT.ISO8859-1 es_MX.ISO8859-1
		es_NI.ISO8859-1 es_PA.ISO8859-1 es_PE.ISO8859-1
		es_PY.ISO8859-1 es_SV.ISO8859-1 es_UY.ISO8859-1 es_VE.ISO8859-1
		es es_AR es_BO es_CL
		es_CO es_CR es_EC
		es_ES es_GT es_MX
		es_NI es_PA es_PE
		es_PY es_SV es_UY es_VE
		spanish spanish.iso88591));

# Select the largest of the alpha(num)bets.

($Locale, @Locale) = ($English, @English)
    if (length(@English) > length(@Locale));
($Locale, @Locale) = ($German, @German)
    if (length(@German)  > length(@Locale));
($Locale, @Locale) = ($French, @French)
    if (length(@French)  > length(@Locale));
($Locale, @Locale) = ($Spanish, @Spanish)
    if (length(@Spanish) > length(@Locale));

print "# Locale = $Locale\n";
print "# Alnum_ = @Locale\n";

{
    local $^W = 0;
    setlocale(LC_ALL, $Locale);
}

{
    my $i = 0;

    for (@Locale) {
	$iLocale{$_} = $i++;
    }
}

# Sieve the uppercase and the lowercase.

for (@Locale) {
    if (/[^\d_]/) { # skip digits and the _
	if (lc eq $_) {
	    $UPPER{$_} = uc;
	} else {
	    $lower{$_} = lc;
	}
    }
}

# Cross-check the upper and the lower.
# Yes, this is broken when the upper<->lower changes the number of
# the glyphs (e.g. the German sharp-s aka double-s aka sz-ligature.
# But so far all the implementations do this wrong so we can do it wrong too.

for (keys %UPPER) {
    if (defined $lower{$UPPER{$_}}) {
	if ($_ ne $lower{$UPPER{$_}}) {
	    print 'not ';
	    last;
	}
    }
}
print "ok 63\n";

for (keys %lower) {
    if (defined $UPPER{$lower{$_}}) {
	if ($_ ne $UPPER{$lower{$_}}) {
	    print 'not ';
	    last;
	}
    }
}
print "ok 64\n";

# Find the alphabets that are not alphabets in the default locale.

{
    no locale;
    
    for (keys %UPPER, keys %lower) {
	push(@Neoalpha, $_) if (/\W/);
    }
}

@Neoalpha = sort @Neoalpha;

# Test \w.

{
    my $word = join('', @Neoalpha);

    $word =~ /^(\w*)$/;

    print 'not ' if ($1 ne $word);
}
print "ok 65\n";

# Find places where the collation order differs from the default locale.

{
    no locale;

    my @k = sort (keys %UPPER, keys %lower); 
    my ($i, $j, @d);

    for ($i = 0; $i < @k; $i++) {
	for ($j = $i + 1; $j < @k; $j++) {
	    if ($iLocale{$k[$j]} < $iLocale{$k[$i]}) {
		push(@d, [$k[$j], $k[$i]]);
	    }
	}
    }

    # Cross-check those places.

    for (@d) {
	($i, $j) = @$_;
	print 'not ' if ($i le $j or not (($i cmp $j) == 1));
    }
}
print "ok 66\n";

# Cross-check whole character set.

for (map { chr } 0..255) {
    if (/\w/ and /\W/) { print 'not '; last }
    if (/\d/ and /\D/) { print 'not '; last }
    if (/\s/ and /\S/) { print 'not '; last }
    if (/\w/ and /\D/ and not /_/ and
	not (exists $UPPER{$_} or exists $lower{$_})) {
	print 'not '; last
    }
}
print "ok 67\n";
