package deprecate;
use strict;
use warnings;
our $VERSION = 0.01;

# our %Config can ignore %Config::Config, e.g. for testing
our %Config;
unless (%Config) { require Config; *Config = \%Config::Config; }

sub import {
    my ($package, $file, $line) = caller;
    my $expect_leaf = "$package.pm";
    $expect_leaf =~ s!::!/!g;

    foreach my $pair ([qw(sitearchexp archlibexp)],
		      [qw(sitelibexp privlibexp)]) {
	my ($site, $priv) = @Config{@$pair};
	# Just in case anyone managed to configure with trailing /s
	s!/*$!!g foreach $site, $priv;

	next if $site eq $priv;
	if ("$priv/$expect_leaf" eq $file) {
	    my $call_depth=1;
	    my @caller;
	    while (@caller = caller $call_depth++) {
		last if $caller[7]			# use/require
		    and $caller[6] eq $expect_leaf;	# the package file
	    }
	    unless (@caller) {
		require Carp;
		Carp::cluck(<<"EOM");
Can't find use/require $expect_leaf in caller stack
EOM
		next;
	    }

	    # This is fragile, because it
	    # is directly poking in the internals of warnings.pm
	    my ($call_file, $call_line, $callers_bitmask) = @caller[1,2,9];

	    if (defined $callers_bitmask
            	&& (vec($callers_bitmask, $warnings::Offsets{deprecated}, 1)
		    || vec($callers_bitmask, $warnings::Offsets{all}, 1))) {
		warn <<"EOM";
$package will be removed from the Perl core distribution in the next major release. Please install it from CPAN. It is being used at $call_file, line $call_line.
EOM
	    }
	    return;
	}
    }
}

1;
