#!perl -w
while (<>) {
	chomp;
	next if /^\s*#/;
	if (/^::macos:perl .* (\S+)$/) {
		if ($script) {
			$tests{$script}{num}   = $num;
			$tests{$script}{tests} = [@tests];
		}
		$script = $1;
		$line   = 1;
		@tests  = ();
	} elsif ($line) {
		next unless /1\.\.(\d+)/;
		$num = $1;
		$line = 0;
	} else {
		if (/^ok (\d+)/) {
			$tests[$1]++;
		} elsif (/^not ok (\d+)/) {
			$tests[$1] = -1;
		}
	}
}

for my $script (sort keys %tests) {
	my @not    = grep {
		$tests{$script}{tests}[$_] && $tests{$script}{tests}[$_] == -1
	} 1..$tests{$script}{num};

	my @missed = grep {
		!$tests{$script}{tests}[$_]
	} 1..$tests{$script}{num};

	my @extra  = grep {
		$tests{$script}{tests}[$_] && $tests{$script}{tests}[$_] > 1
	} 1..$tests{$script}{num};

	if (@not || @missed || @extra) {
		$str = "$script";
		$str .= " missed: @missed" if @missed;
		$str .= " not ok: @not"    if @not;
		$str .= " extra : @extra"  if @extra;
		push @notok, $str;
	} else {
		push @ok, $script;
	}
}

print "Test results begin\n";
print join("\n  ", "OK:", @ok), "\n\n";
print join("\n  ", "Not OK:", @notok), "\n\n";
printf "Test results: %s OK, %s not OK\n\n", scalar @ok, scalar @notok;
__END__
