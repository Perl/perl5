BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use File::Spec;

my $CF = File::Spec->catfile(File::Spec->catdir(File::Spec->updir,
					       "lib", "unicore"),
			    "CaseFold.txt");

if (open(CF, $CF)) {
    my @CF;

    while (<CF>) {
        if (/^([0-9A-F]+); ([CFSI]); ((?:[0-9A-F]+)(?: [0-9A-F]+)*); \# (.+)/) {
            next if $2 eq 'S'; # we are going for 'F'ull case folding
	    push @CF, [$1, $2, $3, $4];
	}
    }

    die qq[$0: failed to find casefoldings from "$CF"\n] unless @CF;

    print "1..", scalar @CF, "\n";

    my $i = 0;
    for my $cf (@CF) {
	my ($code, $status, $mapping, $name) = @$cf;
	$i++;
	my $a = pack("U0U*", hex $code);
	my $b = pack("U0U*", map { hex } split " ", $mapping);
	my $t0 = ":$a:" =~ /:$a:/   ?  1 : 0;
	my $t1 = ":$a:" =~ /:$a:/i  ?  1 : 0;
	my $t2 = ":$a:" =~ /:[$a]:/i ? 1 : 0;
	my $t3 = ":$a:" =~ /:$b:/i   ? 1 : 0;
	my $t4 = ":$a:" =~ /:[$b]:/i ? 1 : 0;
	my $t5 = ":$b:" =~ /:$a:/i   ? 1 : 0;
	my $t6 = ":$b:" =~ /:[$a]:/i ? 1 : 0;
	print $t0 && $t1 && $t2 && $t3 && $t4 && $t5 && $t6 ?
	    "ok $i \# - $code - $name - $mapping - - $status\n" :
	    "not ok $i \# - $code - $name - $mapping - $t0 $t1 $t2 $t3 $t4 $t5 $t6 - $status\n";
    }
} else {
    die qq[$0: failed to open "$CF": $!\n];
}
