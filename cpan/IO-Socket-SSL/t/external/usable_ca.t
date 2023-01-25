use strict;
use warnings;
use Test::More;
use IO::Socket::SSL;
use IO::Socket::SSL::Utils;

my $ipclass = 'IO::Socket::INET';
for( qw( IO::Socket::IP IO::Socket::INET6  )) {
    eval { require $_ } or next;
    $ipclass = $_;
    last;
}

my $fingerprints = do './fingerprint.pl'
    || do './t/external/fingerprint.pl'
    || die "no fingerprints for sites";
my @tests = grep { $_->{subject_hash_ca} } @$fingerprints;

my %ca = IO::Socket::SSL::default_ca();
plan skip_all => "no default CA store found" if ! %ca;

my %have_ca;
# some systems seems to have junk in the CA stores
# so better wrap it into eval
eval {
    for my $f (
	( $ca{SSL_ca_file} ? ($ca{SSL_ca_file}) : ()),
	( $ca{SSL_ca_path} ? glob("$ca{SSL_ca_path}/*") :()),
	) {
	open( my $fh,'<',$f ) or next;
	my $pem;
	while (<$fh>) {
	    if ( m{^--+END} ) {
		my $cert = PEM_string2cert($pem.$_);
		$pem = undef;
		$cert or next;
		my $hash = Net::SSLeay::X509_subject_name_hash($cert);
		$have_ca{sprintf("%08x",$hash)} = 1;
	    } elsif ( m{^--+BEGIN (TRUSTED |X509 |)CERTIFICATE-+} ) {
		$pem = $_;
	    } elsif ( $pem ) {
		$pem .= $_;
	    }
	}
    }
};
diag( "found ".(0+keys %have_ca)." CA certs");
plan skip_all => "no CA certs found" if ! %have_ca;

my $proxy = ( $ENV{https_proxy} || $ENV{http_proxy} || '' )
    =~m{^(?:\w+://)?([\w\-.:\[\]]+:\d+)/?$} && $1;

my @cap = ('SSL_verifycn_name');
push @cap, 'SSL_hostname' if IO::Socket::SSL->can_client_sni();
plan tests => (1+@cap)*@tests;

for my $test (@tests) {
    my $host = $test->{host};
    my $port = $test->{port} || 443;
    my $fp   = $test->{fingerprint};
    my $ca_hash = $test->{subject_hash_ca};

    SKIP: {

	# first check if we have the CA in store
	skip "no root CA $ca_hash for $host in store",1+@cap
	    if ! $have_ca{$ca_hash};
	diag("have root CA for $host in store");

	# then build inet connections for later SSL upgrades
	my @cl;
	for my $cap ('fp','nocn',@cap,'noca') {
	    my $cl;
	    if ( ! $proxy ) {
		# direct connection
		$cl = $ipclass->new(
		    PeerAddr => $host,
		    PeerPort => $port,
		    Timeout => 15,
		)
	    } elsif ( $cl = $ipclass->new(
		PeerAddr => $proxy,
		Timeout => 15
		)) {
		# try to establish tunnel via proxy with CONNECT
		my $reply = '';
		if ( eval {
		    local $SIG{ALRM} = sub { die "timed out" };
		    alarm(15);
		    print $cl "CONNECT $host:443 HTTP/1.0\r\n\r\n";
		    while (<$cl>) {
			$reply .= $_;
			last if m{\A\r?\n\Z};
		    }
		    $reply =~m{\AHTTP/1\.[01] 200\b} or
			die "unexpected response from proxy: $reply";
		}) {
		} else {
		    $cl = undef
		}
	    }

	    skip "cannot connect to $host:443 with $ipclass: $!",1+@cap
		if ! $cl;
	    push @cl,$cl;
	}

	diag(int(@cl)." connections to $host ok");

	# check if we have SSL interception by comparing the fingerprint we get
	my $cl = shift(@cl);
	skip "ssl upgrade failed even without verification",1+@cap
	    if ! IO::Socket::SSL->start_SSL($cl, SSL_verify_mode => 0 );
	my $pubkey_fp = $test->{fingerprint} =~m{\$pub\$};
	my $clfp = $cl->get_fingerprint('sha1',undef,$pubkey_fp);
	skip "fingerprint mismatch ($clfp) - probably SSL interception or certificate changed",1+@cap
	    if $clfp ne $fp;
	diag("fingerprint $host matches");

	# check if it can verify against builtin CA store
	$cl = shift(@cl);
	if ( ! IO::Socket::SSL->start_SSL($cl)) {
	    skip "ssl upgrade failed with builtin CA store",1+@cap;
	}
	diag("check $host against builtin CA store ok");

	for my $cap (@cap) {
	    my $cl = shift(@cl);
	    # try to upgrade with SSL using default CA path
	    if ( IO::Socket::SSL->start_SSL($cl,
		SSL_verify_mode => 1,
		SSL_verifycn_scheme => 'http',
		$cap => $host,
	    )) {
		pass("SSL upgrade $host with default CA and $cap");
	    } elsif ( $SSL_ERROR =~m{verify failed} ) {
		fail("SSL upgrade $host with default CA and $cap: $SSL_ERROR");
	    } else {
		pass("SSL upgrade $host with default CA and $cap failed but not because of verify problem: $SSL_ERROR");
	    }
	}

	# it should fail when we use no default ca, even on OS X
	# https://hynek.me/articles/apple-openssl-verification-surprises/
	$cl = shift(@cl);
	if ( IO::Socket::SSL->start_SSL($cl, SSL_ca_file => \'' )) {
	    fail("SSL upgrade $host with no CA succeeded");
	} elsif ( $SSL_ERROR =~m{verify failed} ) {
	    pass("SSL upgrade $host with no CA failed");
	} else {
	    pass("SSL upgrade $host with no CA failed but not because of verify problem: $SSL_ERROR");
	}
    }
}
