use File::Spec;

require "test.pl";

sub unidump {
    join " ", map { sprintf "%04X", $_ } unpack "U*", $_[0];
}

sub casetest {
    my ($base, $spec, $func) = @_;
    my $file = File::Spec->catfile(File::Spec->catdir(File::Spec->updir,
						      "lib", "unicore", "To"),
				   "$base.pl");
    my $simple = do $file;
    my %simple;
    for my $i (split(/\n/, $simple)) {
	my ($k, $v) = split(' ', $i);
	$simple{$k} = $v;
    }
    my %seen;

    for my $i (sort keys %simple) {
	$seen{hex $i}++;
    }
    print "# ", scalar keys %simple, " simple mappings\n";

    my $both;

    for my $i (sort keys %$spec) {
	if (++$seen{hex $i} == 2) {
	    warn "$base: $i seen twice\n";
	    $both++;
	}
    }
    print "# ", scalar keys %$spec, " special mappings\n";

    exit(1) if $both;

    my %none;
    for my $i (map { ord } split //,
	       "\e !\"#\$%&'()+,-./0123456789:;<=>?\@[\\]^_{|}~\b") {
	next if pack("U0U", $i) =~ /\w/;
	$none{$i}++ unless $seen{$i};
    }
    print "# ", scalar keys %none, " noncase mappings\n";

    my $tests = 
	(scalar keys %simple) +
	(scalar keys %$spec) +
	(scalar keys %none);
    print "1..$tests\n";

    my $test = 1;

    for my $i (sort { hex $a <=> hex $b } keys %simple) {
	my $w = $simple{$i};
	my $c = pack "U0U", hex $i;
	my $d = $func->($c);
	my $e = unidump($d);
	print $d eq pack("U0U", hex $simple{$i}) ?
	    "ok $test # $i -> $w\n" : "not ok $test # $i -> $e ($w)\n";
	$test++;
    }

    for my $i (sort { hex $a <=> hex $b } keys %$spec) {
	my $w = unidump($spec->{$i});
	my $c = pack "U0U", hex $i;
	my $d = $func->($c);
	my $e = unidump($d);
	print $d eq $spec->{$i} ?
	    "ok $test # $i -> $w\n" : "not ok $test # $i -> $e ($w)\n";
	$test++;
    }

    for my $i (sort { $a <=> $b } keys %none) {
	my $w = $i = sprintf "%04X", $i;
	my $c = pack "U0U", hex $i;
	my $d = $func->($c);
	my $e = unidump($d);
	print $d eq $c ?
	    "ok $test # $i -> $w\n" : "not ok $test # $i -> $e ($w)\n";
	$test++;
    }
}

1;
