#!/usr/bin/perl

use strict;
use warnings 'all';

use LWP::Simple qw /$ua getstore/;
use Errno;

my $out = "links.out";
my %urls;

my @dummy = qw(
	   http://something.here
	   http://www.pvhp.com
	      );
my %dummy;

@dummy{@dummy} = ();

foreach my $file (<pod/*.pod README README.* INSTALL>) {
    open my $fh => $file or die "Failed to open $file: $!\n";
    while (<$fh>) {
        if (m{(?:http|ftp)://(?:(?!\w<)[-\w~?@=.])+} && !exists $dummy{$&}) {
            my $url = $&;
            $url =~ s/\.$//;
            $urls {$url} ||= { };
            $urls {$url} {$file} = 1;
        }
    }
    close $fh;
}

my @urls = keys %urls;

while (@urls) {
    my @list = splice @urls, 0, 10;
    my $pid;
    my $retry;
    my $retrymax = 3;
    my $nap = 5;
    do {
	$pid = fork;
	unless (defined $pid) {
	    if ($!{EAGAIN}) {
		warn "Failed to fork: $!\n";
		if ($retry++ < $retrymax) {
		    warn "(sleeping...)\n";
		    sleep $nap;
		} else {
		    $nap  *= 2;
		    $retry = 0;
		}
		redo;
	    } else {
		die "Failed to fork: $!\n" unless defined $pid;
	    }
	}
    } until (defined $pid);

    unless ($pid) {
        # Child.
        foreach my $url (@list) {
            my $code = getstore $url, "/dev/null";
            next if $code == 200;
            my $f = join ", " => keys %{$urls {$url}};
            printf "%03d  %s: %s\n" => $code, $url, $f;
        }

        exit;
    }
}

1 until -1 == wait;


__END__
