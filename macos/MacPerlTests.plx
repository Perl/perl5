#!perl -w
while (<>) {
	chomp;
	next if /^\s*#/;
	if (/^(?:\S+)\bperl(?:\.\w+)? .* (\S+)\s*$/) {
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
		if      (/^ok (\d+)/) {
			$tests[$1]++;
		} elsif (/^not ok (\d+)[^#]+#\s+TODO/) {
			$tests[$1]++;
		} elsif (/^ok (\d+)[^#]+#\s+TODO/) {
			$tests[$1] = -1;
		} elsif (/^not ok (\d+)/) {
			$tests[$1] = -1;
		}
	}
}
if ($script) {
	$tests{$script}{num}   = $num;
	$tests{$script}{tests} = [@tests];
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
	$total{not} += @not;
	$total{missed} += @missed;
	$total{extra} += @extra;
	$total{total} += $tests{$script}{num};

	push @none, $script if $tests{$script}{num} == 0;
}

print "\n\nTest results begin\n";
print join("\n  ", "OK:", @ok), "\n\n";
print join("\n  ", "None executed:", @none), "\n\n";
print join("\n  ", "Not OK:", @notok), "\n\n";
printf "Test files: %s OK, %s not OK, %s none executed\n\n",
	scalar @ok, scalar @notok, scalar @none;
$total{ok} = ($total{total} + $total{extra}) - ($total{not} + $total{missed});
printf "Individual tests: %s total, %s OK, %s not OK, %s missed, %s extra\n\n",
	@total{qw(total ok not missed extra)};


__END__
