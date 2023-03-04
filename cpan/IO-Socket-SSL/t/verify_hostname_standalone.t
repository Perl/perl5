use strict;
use warnings;
use Test::More;
use IO::Socket::SSL;
use IO::Socket::SSL::Utils;

my @tests = tests();
plan tests => 0+@tests;

my ($ca,$key) = CERT_create( CA => 1);
for my $test (@tests) {
    SKIP: {
	my ($expect_match,$hostname,$cn,$san_dns,$san_ip) = @$test;
	my (@san,$ip6);
	push @san, map { [ "DNS", $_ ] } $san_dns =~m{([^,\s]+)}g if $san_dns;
	for( ($san_ip||'') =~m{([^,\s]+)}g ) {
	    if ( my @h = m{^x(.{4})(.{4})(.{4})(.{4})(.{4})(.{4})(.{4})(.{4})$}) {
		$_ = join(':',@h);
		$ip6 = 1;
	    }
	    push @san, [ "IP", $_ ];
	}
	my $idn = $hostname =~m{[^a-zA-Z0-9_.\-]};

	my $diag = "$hostname: cn=$cn san=".
	    join(",", map { "$_->[0]:$_->[1]" } @san);
	$diag =~s{([\\\x00-\x1f\x7f-\xff])}{ sprintf("\\x%02x",ord($1)) }esg;

	if ($ip6 && !IO::Socket::SSL->can_ipv6) {
	    skip "no IPv6 support - $diag",1;
	}
	if ($idn && ! eval { IO::Socket::SSL::idn_to_ascii("fo") }) {
	    skip "no IDNA library installed - $diag",1
	}


	my %cert = (
	    subject => length($cn) ? { CN => $cn }:{},
	    @san ? ( subjectAltNames => \@san ):(),
	    issuer_cert => $ca,
	    issuer_key => $key,
	    key => $key
	);
	my $cert;
	eval { ($cert) = CERT_create(%cert) };
	if ($@) {
	    skip "failed to create cert: $diag\n$@",1
	}

	#diag($diag);
	my $match = IO::Socket::SSL::verify_hostname_of_cert($hostname,$cert,'www')||0;
	if ( $match == $expect_match ) {
	    pass("$expect_match|$diag");
	} else {
	    fail("$match != $expect_match |$diag");
	    #warn PEM_cert2string($cert);
	}

	CERT_free($cert);
    }
}



# based on 
# https://raw.githubusercontent.com/adobe/chromium/master/net/base/x509_certificate_unittest.cc
# 16.5.2014
#
# format: [ expect_match, hostname, CN, san_dns, san_ip ]

sub tests {(
    [ 1, 'foo.com', 'foo.com' ],
    [ 1, 'f', 'f' ],
    [ 0, 'h', 'i' ],
    [ 1, 'bar.foo.com', '*.foo.com' ],
    [ 1, 'www.test.fr', 'common.name', '*.test.com,*.test.co.uk,*.test.de,*.test.fr' ],
    [ 1, 'wwW.tESt.fr',  'common.name', ',*.*,*.test.de,*.test.FR,www' ],
    [ 0, 'f.uk', '.uk' ],
    [ 0, 'w.bar.foo.com', '?.bar.foo.com' ],
    [ 0, 'www.foo.com', '(www|ftp).foo.com' ],
    [ 0, 'www.foo.com', "www.foo.com\0" ], 

# CERT_create just strips everything after \0 so we get not the expected
# certificate and thus cannot run this test
#   [ 0, 'www.foo.com', '', "www.foo.com\0*.foo.com,\0,\0" ],

    [ 0, 'www.house.example', 'ww.house.example' ],
    [ 0, 'test.org', '', 'www.test.org,*.test.org,*.org' ],
    [ 0, 'w.bar.foo.com', 'w*.bar.foo.com' ],
    [ 0, 'www.bar.foo.com', 'ww*ww.bar.foo.com' ],
    [ 0, 'wwww.bar.foo.com', 'ww*ww.bar.foo.com' ],
    [ 1, 'wwww.bar.foo.com', 'w*w.bar.foo.com' ],
    [ 0, 'wwww.bar.foo.com', 'w*w.bar.foo.c0m' ],
    [ 1, 'WALLY.bar.foo.com', 'wa*.bar.foo.com' ],
    [ 1, 'wally.bar.foo.com', '*Ly.bar.foo.com' ],

# disabled test: we don't accept URL encoded hostnames
#   [ 1, 'ww%57.foo.com', '', 'www.foo.com' ],

# disabled test: & is not allowed in hostname - and CN should not
# allow URL encoding
#   [ 1, 'www&.foo.com', 'www%26.foo.com' ],

    # Common name must not be used if subject alternative name was provided.
    [ 0, 'www.test.co.jp',  'www.test.co.jp', '*.test.de,*.jp,www.test.co.uk,www.*.co.jp' ],
    [ 0, 'www.bar.foo.com', 'www.bar.foo.com', '*.foo.com,*.*.foo.com,*.*.bar.foo.com,*..bar.foo.com,' ],

# I think they got this test wrong
# common name should not be checked only if SAN contains DNS names
# so in this case common name should be checked -> match
# corrected test therefore
#   [ 0, 'www.bath.org', 'www.bath.org', '', '20.30.40.50' ],
    [ 1, 'www.bath.org', 'www.bath.org', '', '20.30.40.50' ],

    [ 0, '66.77.88.99', 'www.bath.org', 'www.bath.org' ],

    # IDN tests
    [ 1, 'xn--poema-9qae5a.com.br', 'xn--poema-9qae5a.com.br' ],
    [ 1, 'www.xn--poema-9qae5a.com.br', '*.xn--poema-9qae5a.com.br' ],
    [ 0, 'xn--poema-9qae5a.com.br', '', '*.xn--poema-9qae5a.com.br,xn--poema-*.com.br,xn--*-9qae5a.com.br,*--poema-9qae5a.com.br' ],

# There should be no *.com.br certificates and public suffix catches this.
# So this example is bad and we change it to .foo.com.br
#   [ 1, 'xn--poema-9qae5a.com.br', '*.com.br' ],
    [ 1, 'xn--poema-9qae5a.foo.com.br', '*.foo.com.br' ],

    # The following are adapted from the  examples quoted from
    # http://tools.ietf.org/html/rfc6125#section-6.4.3
    #  (e.g., *.example.com would match foo.example.com but
    #   not bar.foo.example.com or example.com).
    [ 1, 'foo.example.com', '*.example.com' ],
    [ 0, 'bar.foo.example.com', '*.example.com' ],
    [ 0, 'example.com', '*.example.com' ],
    #   (e.g., baz*.example.net and *baz.example.net and b*z.example.net would
    #   be taken to match baz1.example.net and foobaz.example.net and
    #   buzz.example.net, respectively)
    [ 1, 'baz1.example.net', 'baz*.example.net' ],
    [ 1, 'foobaz.example.net', '*baz.example.net' ],
    [ 1, 'buzz.example.net', 'b*z.example.net' ],
    # Wildcards should not be valid unless there are at least three name
    # components.

# There should be no *.co.uk certificates and public suffix catches this.
# So change example to *.foo.com instead
#   [ 1,  'h.co.uk', '*.co.uk' ],
    [ 1,  'h.foo.com', '*.foo.com' ],
    [ 0, 'foo.com', '*.com' ],
    [ 0, 'foo.us', '*.us' ],
    [ 0, 'foo', '*' ],
    # Multiple wildcards are not valid.
    [ 0, 'foo.example.com', '*.*.com' ],
    [ 0, 'foo.bar.example.com', '*.bar.*.com' ],
    # Absolute vs relative DNS name tests. Although not explicitly specified
    # in RFC 6125, absolute reference names (those ending in a .) should
    # match either absolute or relative presented names.
    [ 1, 'foo.com', 'foo.com.' ],
    [ 1, 'foo.com.', 'foo.com' ],
    [ 1, 'foo.com.', 'foo.com.' ],
    [ 1, 'f', 'f.' ],
    [ 1, 'f.', 'f' ],
    [ 1, 'f.', 'f.' ],
    [ 1, 'www-3.bar.foo.com', '*.bar.foo.com.' ],
    [ 1, 'www-3.bar.foo.com.', '*.bar.foo.com' ],
    [ 1, 'www-3.bar.foo.com.', '*.bar.foo.com.' ],
    [ 0, '.', '.' ],
    [ 0, 'example.com', '*.com.' ],
    [ 0, 'example.com.', '*.com' ],
    [ 0, 'example.com.', '*.com.' ],
    [ 0, 'foo.', '*.' ],
    # IP addresses in common name; IPv4 only.
    [ 1, '127.0.0.1', '127.0.0.1' ],
    [ 1, '192.168.1.1', '192.168.1.1' ],

# we expect proper IP and not this junk, so we will not allow these
#   [ 1,  '676768', '0.10.83.160' ],
#   [ 1,  '1.2.3', '1.2.0.3' ],
    [ 0, '192.169.1.1', '192.168.1.1' ],
    [ 0, '12.19.1.1', '12.19.1.1/255.255.255.0' ],
    [ 0, 'FEDC:ba98:7654:3210:FEDC:BA98:7654:3210', 'FEDC:BA98:7654:3210:FEDC:ba98:7654:3210' ],
    [ 0, '1111:2222:3333:4444:5555:6666:7777:8888', '1111:2222:3333:4444:5555:6666:7777:8888' ],
    [ 0, '::192.9.5.5', '[::192.9.5.5]' ],
    # No wildcard matching in valid IP addresses
    [ 0, '::192.9.5.5', '*.9.5.5' ],
    [ 0, '2010:836B:4179::836B:4179', '*:836B:4179::836B:4179' ],
    [ 0, '192.168.1.11', '*.168.1.11' ],
    [ 0, 'FEDC:BA98:7654:3210:FEDC:BA98:7654:3210', '*.]' ],
    # IP addresses in subject alternative name (common name ignored)
    [ 1, '10.1.2.3', '', '', '10.1.2.3' ],
# we expect proper IP and not this junk, so we will not allow this
#   [ 1,  '14.15', '', '', '14.0.0.15' ],

# according to RFC2818 common name should be checked if no DNS entries in SAN
# so this must match if we match IP in common name -> changed expected result
#   [ 0, '10.1.2.7', '10.1.2.7', '', '10.1.2.6,10.1.2.8' ],
    [ 1, '10.1.2.7', '10.1.2.7', '', '10.1.2.6,10.1.2.8' ],

    [ 0, '10.1.2.8', '10.20.2.8', 'foo' ],
    [ 1, '::4.5.6.7', '', '', 'x00000000000000000000000004050607' ],
    [ 0, '::6.7.8.9', '::6.7.8.9', '::6.7.8.9', 'x00000000000000000000000006070808,x0000000000000000000000000607080a,xff000000000000000000000006070809,6.7.8.9' ],
    [ 1, 'FE80::200:f8ff:fe21:67cf', 'no.common.name', '', 'x00000000000000000000000006070808,xfe800000000000000200f8fffe2167cf,xff0000000000000000000000060708ff,10.0.0.1' ],
    # Numeric only hostnames (none of these are considered valid IP addresses).
    [ 0,  '12345.6', '12345.6' ],
    [ 0, '121.2.3.512', '', '1*1.2.3.512,*1.2.3.512,1*.2.3.512,*.2.3.512', '121.2.3.0'],
    [ 0, '1.2.3.4.5.6', '*.2.3.4.5.6' ],

# IP address should not be matched against SAN DNS entry -> skip test
#   [ 1, '1.2.3.4.5', '', '1.2.3.4.5' ],

    # Invalid host names.

# this cert cannot be created currently
#   [ 0, "junk)(£)\$*!\@~\0", "junk)(£)\$*!\@~\0" ],

    [ 0, 'www.*.com', 'www.*.com' ],
    [ 0, 'w$w.f.com', 'w$w.f.com' ],
    [ 0, 'nocolonallowed:example', '', 'nocolonallowed:example' ],
    [ 0, 'www-1.[::FFFF:129.144.52.38]', '*.[::FFFF:129.144.52.38]' ],
    [ 0, '[::4.5.6.9]', '', '', 'x00000000000000000000000004050609' ],
)}
