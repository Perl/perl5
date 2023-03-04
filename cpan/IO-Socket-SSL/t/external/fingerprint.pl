# to update fingerprints in this file:
# perl -e 'do q[./t/external/fingerprint.pl]; update_fingerprints()'

use strict;
use warnings;
use IO::Socket::SSL;

# --- BEGIN-FINGERPRINTS ----
my $fingerprints= [
  {
    _ => 'this should give us OCSP stapling',
    fingerprint => 'sha1$pub$39d64bbaea90c6035e25ff990ba4ce565350bac5',
    host => 'www.chksum.de',
    ocsp => {
              staple => 1
            },
    port => 443
  },
  {
    _ => 'no OCSP stapling',
    fingerprint => 'sha1$pub$c8ba0806b887fc15e9d98e73107a17150f847bbf',
    host => 'www.bild.de',
    ocsp => {
              staple => 0
            },
    port => 443,
    subject_hash_ca => '3513523f'
  },
  {
    _ => 'this is revoked',
    fingerprint => 'sha1$pub$f0f0c49b8a04a2dd2110e10f7806c97d87d0b26f',
    host => 'revoked.grc.com',
    ocsp => {
              revoked => 1
            },
    port => 443
  },
  {
    fingerprint => 'sha1$pub$7397f9dea15c007ad1eabe7a0c895ccac60389b1',
    host => 'www.yahoo.com',
    port => 443,
    subject_hash_ca => '244b5494'
  },
  {
    fingerprint => 'sha1$pub$c40d9bc2496fa2db198b27b6c1f94d1c703e7039',
    host => 'www.comdirect.de',
    port => 443,
    subject_hash_ca => '062cdee6'
  },
  {
    fingerprint => 'sha1$pub$26907a3f3088cf57264f7a0f083767e400ea871e',
    host => 'meine.deutsche-bank.de',
    port => 443,
    subject_hash_ca => '607986c7'
  },
  {
    fingerprint => 'sha1$pub$232e02961a493a2e528460d0d3c0720a8f533428',
    host => 'www.twitter.com',
    port => 443,
    subject_hash_ca => '3513523f'
  },
  {
    fingerprint => 'sha1$pub$12b35a6d540bcba5f9ff055fdcc5af0dac67fc73',
    host => 'www.facebook.com',
    port => 443,
    subject_hash_ca => '244b5494'
  },
  {
    fingerprint => 'sha1$pub$6ad05c9dd77463152389f755cb6a81c41c33c987',
    host => 'www.live.com',
    port => 443,
    subject_hash_ca => '3513523f'
  }
]
;
# --- END-FINGERPRINTS ----


sub update_fingerprints {
    my $changed;
    for my $fp (@$fingerprints) {
	my $cl = IO::Socket::INET->new(
	    PeerHost => $fp->{host},
	    PeerPort => $fp->{port} || 443,
	    Timeout => 10,
	);
	my $root;
	if (!$cl) {
	    warn "E $fp->{host}:$fp->{port} - TCP connect failed: $!\n";
	} elsif (!IO::Socket::SSL->start_SSL($cl,
	    Timeout => 10,
	    SSL_ocsp_mode => 0,
	    SSL_hostname => $fp->{host},
	    SSL_verify_callback => sub {
		my ($cert,$depth) = @_[4,5];
		$root ||= $cert;
		return 1;
	    }
	)) {
	    warn "E $fp->{host}:$fp->{port} - SSL handshake failed: $SSL_ERROR\n";
	} else {
	    my $sha1 = $cl->get_fingerprint('sha1',undef,1);
	    if ($sha1 eq $fp->{fingerprint}) {
		warn "N $fp->{host}:$fp->{port} - fingerprint as expected\n";
	    } else {
		warn "W $fp->{host}:$fp->{port} - fingerprint changed from $fp->{fingerprint} to $sha1\n";
		$fp->{fingerprint} = $sha1;
		$changed++;
	    }
	    if ($root and $fp->{subject_hash_ca}) {
		my $hash = sprintf("%08x",Net::SSLeay::X509_subject_name_hash($root));
		if ($fp->{subject_hash_ca} eq $hash) {
		    warn "N $fp->{host}:$fp->{port} - subject_hash_ca as expected\n";
		} else {
		    warn "N $fp->{host}:$fp->{port} - subject_hash_ca changed from $fp->{subject_hash_ca} to $hash\n";
		    $fp->{subject_hash_ca} = $hash;
		    $changed++;
		}
	    }
	}
    }
    if ($changed) {
	require Data::Dumper;
	open(my $fh,'<',__FILE__) or die $!;
	my $pl = do { local $/; <$fh> };
	my $new = 'my $fingerprints= '.Data::Dumper->new([$fingerprints])->Terse(1)->Quotekeys(0)->Sortkeys(1)->Dump().";\n";
	$pl =~ s{^(# --- BEGIN-FINGERPRINTS ----\s*\n)(.*)^(# --- END-FINGERPRINTS ----\s*\n)}{$1$new$3}ms
	    or die "did not find BEGIN and END markers in ".__FILE__;
	open($fh,'>',__FILE__) or die $!;
	print $fh $pl;
	warn __FILE__." updated\n";
    }
}

$fingerprints;
