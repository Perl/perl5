#!./perl -wT

print "1..104\n";

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

/(.)/;	# untaint $&, $`, $', $+, $1.
check_taint_not  22, $&;
check_taint_not  23, $`;
check_taint_not  24, $';
check_taint_not  25, $+;
check_taint_not  26, $1;
check_taint_not  27, $2;

/(\W)/;	# taint $&, $`, $', $+, $1.
check_taint      28, $&;
check_taint      29, $`;
check_taint      30, $';
check_taint      31, $+;
check_taint      32, $1;
check_taint_not  33, $2;

/(\s)/;	# taint $&, $`, $', $+, $1.
check_taint      34, $&;
check_taint      35, $`;
check_taint      36, $';
check_taint      37, $+;
check_taint      38, $1;
check_taint_not  39, $2;

/(\S)/;	# taint $&, $`, $', $+, $1.
check_taint      40, $&;
check_taint      41, $`;
check_taint      42, $';
check_taint      43, $+;
check_taint      44, $1;
check_taint_not  45, $2;

$_ = $a;	# untaint $_

check_taint_not  46, $_;

/(b)/;		# this must not taint
check_taint_not  47, $&;
check_taint_not  48, $`;
check_taint_not  49, $';
check_taint_not  50, $+;
check_taint_not  51, $1;
check_taint_not  52, $2;

$_ = $a;	# untaint $_

check_taint_not  53, $_;

$b = uc($a);	# taint $b
s/(.+)/$b/;	# this must taint only the $_

check_taint      54, $_;
check_taint_not  55, $&;
check_taint_not  56, $`;
check_taint_not  57, $';
check_taint_not  58, $+;
check_taint_not  59, $1;
check_taint_not  60, $2;

$_ = $a;	# untaint $_

s/(.+)/b/;	# this must not taint
check_taint_not  61, $_;
check_taint_not  62, $&;
check_taint_not  63, $`;
check_taint_not  64, $';
check_taint_not  65, $+;
check_taint_not  66, $1;
check_taint_not  67, $2;

$b = $a;	# untaint $b

($b = $a) =~ s/\w/$&/;
check_taint      68, $b;	# $b should be tainted.
check_taint_not  69, $a;	# $a should be not.

$_ = $a;	# untaint $_

s/(\w)/\l$1/;	# this must taint
check_taint      70, $_;
check_taint      71, $&;
check_taint      72, $`;
check_taint      73, $';
check_taint      74, $+;
check_taint      75, $1;
check_taint_not  76, $2;

$_ = $a;	# untaint $_

s/(\w)/\L$1/;	# this must taint
check_taint      77, $_;
check_taint      78, $&;
check_taint      79, $`;
check_taint      80, $';
check_taint      81, $+;
check_taint      82, $1;
check_taint_not  83, $2;

$_ = $a;	# untaint $_

s/(\w)/\u$1/;	# this must taint
check_taint      84, $_;
check_taint      85, $&;
check_taint      86, $`;
check_taint      87, $';
check_taint      88, $+;
check_taint      89, $1;
check_taint_not  90, $2;

$_ = $a;	# untaint $_

s/(\w)/\U$1/;	# this must taint
check_taint      91, $_;
check_taint      92, $&;
check_taint      93, $`;
check_taint      94, $';
check_taint      95, $+;
check_taint      96, $1;
check_taint_not  97, $2;

# After all this tainting $a should be cool.

check_taint_not  98, $a;

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
# the glyphs (e.g. the German sharp-s aka double-s aka sz-ligature,
# or the Dutch IJ or the Spanish LL or ...)
# But so far all the implementations do this wrong so we can do it wrong too.

for (keys %UPPER) {
    if (defined $lower{$UPPER{$_}}) {
	if ($_ ne $lower{$UPPER{$_}}) {
	    print 'not ';
	    last;
	}
    }
}
print "ok 99\n";

for (keys %lower) {
    if (defined $UPPER{$lower{$_}}) {
	if ($_ ne $UPPER{$lower{$_}}) {
	    print 'not ';
	    last;
	}
    }
}
print "ok 100\n";

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
print "ok 101\n";

# Find places where the collation order differs from the default locale.

{
    my (@k, $i, $j, @d);

    {
	no locale;

	@k = sort (keys %UPPER, keys %lower); 
    }

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
	if ($i gt $j) {
	    print "# i = $i, j = $j, i ",
	          $i le $j ? 'le' : 'gt', " j\n";
	    print 'not ';
	    last;
	}
    }
}
print "ok 102\n";

# Cross-check whole character set.

for (map { chr } 0..255) {
    if (/\w/ and /\W/) { print 'not '; last }
    if (/\d/ and /\D/) { print 'not '; last }
    if (/\s/ and /\S/) { print 'not '; last }
    if (/\w/ and /\D/ and not /_/ and
	not (exists $UPPER{$_} or exists $lower{$_})) {
	print 'not ';
	last;
    }
}
print "ok 103\n";

# The @Locale should be internally consistent.

{
    my ($from, $to, , $lesser, $greater);

    for (0..9) {
	# Select a slice.
	$from = int(($_*@Locale)/10);
	$to = $from + int(@Locale/10);
        $to = $#Locale if ($to > $#Locale);
	$lesser  = join('', @Locale[$from..$to]);
	# Select a slice one character on.
	$from++; $to++;
        $to = $#Locale if ($to > $#Locale);
	$greater = join('', @Locale[$from..$to]);
	if (not ($lesser  lt $greater) or
	    not ($lesser  le $greater) or
	    not ($lesser  ne $greater) or
	        ($lesser  eq $greater) or
	        ($lesser  ge $greater) or
	        ($lesser  gt $greater) or
	        ($greater lt $lesser ) or
	        ($greater le $lesser ) or
	    not ($greater ne $lesser ) or
	        ($greater eq $lesser ) or
	    not ($greater ge $lesser ) or
	    not ($greater gt $lesser ) or
	    # Well, these two are sort of redundant because @Locale
	    # was derived using cmp.
	    not (($lesser  cmp $greater) == -1) or
	    not (($greater cmp $lesser ) ==  1)
	   ) {
	    print 'not ';
	    last;
	}
    }
}
print "ok 104\n";
