#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require Config; import Config;
    if ($Config{'extensions'} !~ m!\bI18N/Langinfo\b! ||
	$Config{'extensions'} !~ m!\bPOSIX\b!)
    {
	print "1..0 # skip: I18N::Langinfo or POSIX unavailable\n";
	exit 0;
    }
}
    
use I18N::Langinfo qw(langinfo);
use POSIX qw(setlocale LC_ALL);

setlocale(LC_ALL, $ENV{LC_ALL} = $ENV{LANG} = "C");

my %want =
    (
     ABDAY_1	=> "Sun",
     DAY_1	=> "Sunday",
     ABMON_1	=> "Jan",
     MON_1	=> "January",
     RADIXCHAR	=> ".",
     YESSTR     => qr{^y(?:es)?$}i,
     AM_STR	=> qr{^(?:am|a\.m\.)$}i,
     THOUSEP	=> "",
     D_T_FMT	=> qr{^%a %b %[de] %H:%M:%S %Y$},
     D_FMT	=> qr{^%m/%d/%y$},
     T_FMT	=> qr{^%H:%M:%S$},
     );

    
my @want = sort keys %want;

print "1..", scalar @want, "\n";
    
for my $i (1..@want) {
    my $try = $want[$i-1];
    eval { I18N::Langinfo->import($try) };
    unless ($@) {
	my $got = langinfo(&$try);
	if (ref $want{$try} && $got =~ $want{$try} || $got eq $want{$try}) {
	    print qq[ok $i - $try is "$got"\n];
	} else {
	    print qq[not ok $i - $try is "$got" not "$want{$try}"\n];
	}
    } else {
	print qq[ok $i - Skip: $try not defined\n];
    }
}

