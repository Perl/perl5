#!perl -w
BEGIN { @INC = "::lib" }
use strict;

my $o = "::macos:MacPerlTests.out";
my $x = ">> $o";
my $last;
my @files;

@files = <:*:*.t>;

open MANI, "::MANIFEST" or die "Can't open ::MANIFEST: $!";
while (<MANI>) {
	chomp;
	if (m!^(ext/\S+/?([^/]+\.t|test\.pl)|lib/\S+?(\.t|test\.pl))\s!) {
		$_ = $1;
		tr|/|:|;
		$_ = "::$_";
		push @files, $_;
	}
}

for (@files) {
	/^(:+\w+:)/;
	if (!$last) {
		$last = $1;
	} elsif ($last ne $1) {
		$last = $1;
		print "\n";
	}
	get();
}

sub get {
	open my $fh, "<$_" or die "Can't open $_: $!";
	my $t = <$fh> =~/\bperl.+(t)/i ? "-$1" : "  ";
	my $s = "$^X -I::lib $t $_";
	print qq[echo "$s" $x\n$s $x\nsave $o\n];
}

__END__
:perl -I::lib -e 'for(<:*:*.t>){open my $fh,"<$_";$t=<$fh>=~/(t)/i?"-$1":"  ";$s="$^X -I::lib $t $_ "; $o = "::macos:MacPerlTests.out"; $t = ">> $o";print qq[echo "$s" $t\n$s $t\nsave $o\n]}'
