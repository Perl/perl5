#!./perl -wT

BEGIN {
    chdir 't' if -d 't';
    unshift @INC, '../lib';
    require Config; import Config;
    if (!$Config{d_setlocale} || $Config{ccflags} =~ /\bD?NO_LOCALE\b/) {
	print "1..0\n";
	exit;
    }
}

use strict;

my $debug = 1;

my $have_setlocale = 0;
eval {
    require POSIX;
    import POSIX ':locale_h';
    $have_setlocale++;
};

use vars qw(&LC_ALL);

# Visual C's CRT goes silly on strings of the form "en_US.ISO8859-1"
# and mingw32 uses said silly CRT
$have_setlocale = 0 if $^O eq 'MSWin32' && $Config{cc} =~ /^(cl|gcc)/i;

# 103 (the last test) may fail but that is sort-of okay.
# (It indicates something broken in the environment, not Perl)

print "1..", ($have_setlocale ? 103 : 98), "\n";

use vars qw($a
	    $English $German $French $Spanish
	    @C @English @German @French @Spanish
	    $Locale @Locale %UPPER %lower %bothcase @Neoalpha);

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
    local $^W;	# no warnings 'undef'
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
# Let us do some *real* locale work now,
# unless setlocale() is missing (i.e. minitest).

exit unless $have_setlocale;

# Find locales.

my $locales = <<EOF;
Arabic:ar:dz eg sa:6 arabic8
Bulgarian:bg:bg:5
Chinese:zh:cn tw:cn.EUC eucCN eucTW euc.CN euc.TW tw.EUC
Croation:hr:hr:2
Czech:cs:cz:2
Danish:dk:da:1
Danish:dk:da:1
Dutch:nl:nl:1
English American British:en:au ca gb ie nz us uk:1 cp850
Estonian:et:ee:1
Finnish:fi:fi:1
French:fr:be ca ch fr:1
German:de:de at ch:1
Greek:el:gr:7 g8
Hebrew:iw:il:8 hebrew8
Hungarian:hu:hu:2
Icelandic:is:is:1
Italian:it:it:1
Japanese:ja:jp:euc eucJP jp.EUC sjis
Korean:ko:kr:
Latin:la:va:1
Latvian:lv:lv:1
Lithuanian:lt:lt:1
Polish:pl:pl:2
Portuguese:po:po br:1
Rumanian:ro:ro:2
Russian:ru:ru su:5 koi8 koi8r koi8u cp1251
Slovak:sk:sk:2
Slovene:sl:si:2
Spanish:es:ar bo cl co cr ec es gt mx ni pa pe py sv uy ve:1
Swedish:sv:se:1
Thai:th:th:tis620
Turkish:tr:tr:9 turkish8
EOF

my @Locale;
my $Locale;
my @Alnum_;

sub getalnum_ {
    sort grep /\w/, map { chr } 0..255
}

sub trylocale {
    my $locale = shift;
    if (setlocale(LC_ALL, $locale)) {
	push @Locale, $locale;
    }
}

sub decode_encodings {
    my @enc;

    foreach (split(/ /, shift)) {
	if (/^(\d+)$/) {
	    push @enc, "ISO8859-$1";
	    push @enc, "iso8859$1";	# HP
	    if ($1 eq '1') {
		 push @enc, "roman8";	# HP
	    }
	} else {
	    push @enc, $_;
	}
    }

    return @enc;
}

trylocale("C");
trylocale("POSIX");
foreach (0..15) {
    trylocale("ISO8859-$_");
    trylocale("iso_8859_$_");
    trylocale("iso8859$_");
}

foreach my $locale (split(/\n/, $locales)) {
    my ($locale_name, $language_codes, $country_codes, $encodings) =
	split(/:/, $locale);
    my @enc = decode_encodings($encodings);
    foreach my $loc (split(/ /, $locale_name)) {
	trylocale($loc);
	foreach my $enc (@enc) {
	    trylocale("$loc.$enc");
	}
	$loc = lc $loc;
	foreach my $enc (@enc) {
	    trylocale("$loc.$enc");
	}
    }
    foreach my $lang (split(/ /, $language_codes)) {
	trylocale($lang);
	foreach my $country (split(/ /, $country_codes)) {
	    my $lc = "${lang}_${country}";
	    trylocale($lc);
	    foreach my $enc (@enc) {
		trylocale("$lc.$enc");
	    }
	    my $lC = "${lang}_\U${country}";
	    trylocale($lC);
	    foreach my $enc (@enc) {
		trylocale("$lC.$enc");
	    }
	}
    }
}

@Locale = sort @Locale;

sub debug {
    print @_ if $debug;
}

sub debugf {
    printf @_ if $debug;
}

debug "# Locales = @Locale\n";

my %Problem;

foreach $Locale (@Locale) {
    debug "# Locale = $Locale\n";
    @Alnum_ = getalnum_();
    debug "# \\w = @Alnum_\n";

    unless (setlocale(LC_ALL, $Locale)) {
	foreach (99..103) {
	    $Problem{$_}{$Locale} = -1;
	}
	next;
    }

    # Sieve the uppercase and the lowercase.
    
    %UPPER = %lower = %bothcase = ();
    for (@Alnum_) {
	if (/[^\d_]/) { # skip digits and the _
	    if (uc($_) eq $_) {
		$UPPER{$_} = $_;
	    }
	    if (lc($_) eq $_) {
		$lower{$_} = $_;
	    }
	}
    }
    foreach (keys %UPPER) {
	$bothcase{$_}++ if exists $lower{$_};
    }
    foreach (keys %lower) {
	$bothcase{$_}++ if exists $UPPER{$_};
    }
    foreach (keys %bothcase) {
	delete $UPPER{$_};
	delete $lower{$_};
    }

    debug "# UPPER    = ", join(" ", sort keys %UPPER   ), "\n";
    debug "# lower    = ", join(" ", sort keys %lower   ), "\n";
    debug "# bothcase = ", join(" ", sort keys %bothcase), "\n";

    # Find the alphabets that are not alphabets in the default locale.

    {
	no locale;
    
	@Neoalpha = ();
	for (keys %UPPER, keys %lower) {
	    push(@Neoalpha, $_) if (/\W/);
	}
    }

    @Neoalpha = sort @Neoalpha;

    debug "# Neoalpha = @Neoalpha\n";

    if (@Neoalpha == 0) {
	# If we have no Neoalphas the remaining tests are no-ops.
	debug "# no Neoalpha, skipping tests 99..103 for locale '$Locale'\n";
	next;
    }

    # Test \w.
    
    debug "# testing 99 with locale '$Locale'\n";
    {
	my $word = join('', @Neoalpha);

	$word =~ /^(\w+)$/;

	if ($1 ne $word) {
	    $Problem{99}{$Locale} = 1;
	    debug "# failed 99 ($1 vs $word)\n";
	}
    }

    # Test #100 removed but to preserve historical test number
    # consistency we do not renumber the remaining tests.

    # Cross-check whole character set.

    debug "# testing 101 with locale '$Locale'\n";
    for (map { chr } 0..255) {
	if ((/\w/ and /\W/) or (/\d/ and /\D/) or (/\s/ and /\S/)) {
	    $Problem{101}{$Locale} = 1;
	    debug "# failed 101\n";
	    last;
	}
    }

    # Test for read-only scalars' locale vs non-locale comparisons.

    debug "# testing 102 with locale '$Locale'\n";
    {
	no locale;
	$a = "qwerty";
	{
	    use locale;
	    if ($a cmp "qwerty") {
		$Problem{102}{$Locale} = 1;
		debug "# failed 102\n";
	    }
	}
    }

    # This test must be the last one because its failure is not fatal.
    # The @Alnum_ should be internally consistent.
    # Thanks to Hallvard Furuseth <h.b.furuseth@usit.uio.no>
    # for inventing a way to test for ordering consistency
    # without requiring any particular order.
    # <jhi@iki.fi>
    
    debug "# testing 103 with locale '$Locale'\n";
    {
	my ($from, $to, $lesser, $greater,
	    @test, %test, $test, $yes, $no, $sign);

	for (0..9) {
	    # Select a slice.
	    $from = int(($_*@Alnum_)/10);
	    $to = $from + int(@Alnum_/10);
	    $to = $#Alnum_ if ($to > $#Alnum_);
	    $lesser  = join('', @Alnum_[$from..$to]);
	    # Select a slice one character on.
	    $from++; $to++;
	    $to = $#Alnum_ if ($to > $#Alnum_);
	    $greater = join('', @Alnum_[$from..$to]);
	    ($yes, $no, $sign) = ($lesser lt $greater
				  ? ("    ", "not ", 1)
				  : ("not ", "    ", -1));
	    # all these tests should FAIL (return 0).
	    # Exact lt or gt cannot be tested because
	    # in some locales, say, eacute and E may test equal.
	    @test = 
		(
		 $no.'    ($lesser  le $greater)',  # 1
		 'not      ($lesser  ne $greater)', # 2
		 '         ($lesser  eq $greater)', # 3
		 $yes.'    ($lesser  ge $greater)', # 4
		 $yes.'    ($lesser  ge $greater)', # 5
		 $yes.'    ($greater le $lesser )', # 7
		 'not      ($greater ne $lesser )', # 8
		 '         ($greater eq $lesser )', # 9
		 $no.'     ($greater ge $lesser )', # 10
		 'not (($lesser cmp $greater) == -$sign)' # 12
		 );
	    @test{@test} = 0 x @test;
	    $test = 0;
	    for my $ti (@test) { $test{$ti} = eval $ti ; $test ||= $test{$ti} }
	    if ($test) {
		$Problem{103}{$Locale} = 1;
		debug "# failed 103 at:\n";
		debug "# lesser  = '$lesser'\n";
		debug "# greater = '$greater'\n";
		debug "# lesser cmp greater = ", $lesser cmp $greater, "\n";
		debug "# greater cmp lesser = ", $greater cmp $lesser, "\n";
		debug "# (greater) from = $from, to = $to\n";
		for my $ti (@test) {
		    debugf("# %-40s %-4s", $ti,
			   $test{$ti} ? 'FAIL' : 'ok');
		    if ($ti =~ /\(\.*(\$.+ +cmp +\$[^\)]+)\.*\)/) {
			debugf("(%s == %4d)", $1, eval $1);
		    }
		    debug "\n#";
		}

		last;
	    }
	}
    }
}

no locale;

foreach (99..103) {
    if ($Problem{$_}) {
	if ($_ == 103) {
	    print "# The failure of test 103 is not necessarily fatal.\n";
	    print "# It usually indicates a problem in the enviroment,\n";
	    print "# not in Perl itself.\n";
	}
	print "not ";
    }
    print "ok $_\n";
}

my $didwarn = 0;

foreach (99..103) {
    if ($Problem{$_}) {
	my @f = sort keys %{ $Problem{$_} };
	my $f = join(" ", @f);
	$f =~ s/(.{50,60}) /$1\n#\t/g;
	warn
	    "# The locale ", (@f == 1 ? "definition" : "definitions"), "\n#\n",
	    "#\t", $f, "\n#\n",
	    "# on your system may have errors because the locale test $_\n",
            "# failed in ", (@f == 1 ? "that locale" : "those locales"),
            ".\n";
	warn <<EOW;
#
# If your users are not using these locales you are safe for the moment,
# but please report this failure first to perlbug\@perl.com using the
# perlbug script (as described in the INSTALL file) so that the exact
# details of the failures can be sorted out first and then your operating
# system supplier can be alerted about these anomalies.
#
EOW
	$didwarn = 1;
    }
}

if ($didwarn) {
    my @s;
    
    foreach my $l (@Locale) {
	my $p = 0;
	foreach my $t (99..103) {
	    $p++ if $Problem{$t}{$l};
	}
	push @s, $l if $p == 0;
    }
    
    my $s = join(" ", @s);
    $s =~ s/(.{50,60}) /$1\n#\t/g;

    warn
	"# The following locales\n#\n",
        "#\t", $s, "\n#\n",
	"# tested okay.\n#\n",
}

# eof
