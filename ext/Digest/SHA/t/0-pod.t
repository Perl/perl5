BEGIN {
	if ($ENV{PERL_CORE}) {
		chdir 't' if -d 't';
		@INC = '../lib';
	}
}

BEGIN {
	eval "use Test::More";
	if ($@) {
		print "1..0 # Skipped: Test::More not installed\n";
		exit;
	}
}

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();
