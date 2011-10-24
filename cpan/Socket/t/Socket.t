#!./perl

BEGIN {
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bSocket\b/ &&
        !(($^O eq 'VMS') && $Config{d_socket})) {
	print "1..0\n";
	exit 0;
    }
    $has_alarm = $Config{d_alarm};
}

use Socket qw(:all);
use Test::More tests => 26;

$has_echo = $^O ne 'MSWin32';
$alarmed = 0;
sub arm      { $alarmed = 0; alarm(shift) if $has_alarm }
sub alarmed  { $alarmed = 1 }
$SIG{ALRM} = 'alarmed'                    if $has_alarm;

SKIP: {
    unless(socket(T, PF_INET, SOCK_STREAM, IPPROTO_TCP)) {
	skip "No PF_INET", 3;
    }

    pass "socket(PF_INET)";

    arm(5);
    my $host = $^O eq 'MacOS' || ($^O eq 'irix' && $Config{osvers} == 5) ?
				 '127.0.0.1' : 'localhost';
    my $localhost = inet_aton($host);

    SKIP: {
	unless($has_echo && defined $localhost && connect(T,pack_sockaddr_in(7,$localhost))) {
	    skip "Unable to connect to localhost:7", 2;
	}

	arm(0);

	pass "PF_INET echo localhost connected";

	diag "Connected to " .
		inet_ntoa((unpack_sockaddr_in(getpeername(T)))[1])."\n";

	arm(5);
	syswrite(T,"hello",5);
	arm(0);

	arm(5);
	$read = sysread(T,$buff,10);	# Connection may be granted, then closed!
	arm(0);

	while ($read > 0 && length($buff) < 5) {
	    # adjust for fact that TCP doesn't guarantee size of reads/writes
	    arm(5);
	    $read = sysread(T,$buff,10,length($buff));
	    arm(0);
	}

	is(($read == 0 || $buff eq "hello"), "PF_INET echo localhost reply");
    }
}

SKIP: {
    unless(socket(S, PF_INET, SOCK_STREAM, IPPROTO_TCP)) {
	skip "No PF_INET", 3;
    }

    pass "socket(PF_INET)";

    SKIP: {
	arm(5);
	unless($has_echo && connect(S,pack_sockaddr_in(7,INADDR_LOOPBACK))) {
	    skip "Unable to connect to localhost:7", 2;
	}

        arm(0);

	pass "PF_INET echo INADDR_LOOPBACK connected";

	diag "Connected to " .
		inet_ntoa((unpack_sockaddr_in(getpeername(S)))[1])."\n";

	arm(5);
	syswrite(S,"olleh",5);
	arm(0);

	arm(5);
	$read = sysread(S,$buff,10);	# Connection may be granted, then closed!
	arm(0);

	while ($read > 0 && length($buff) < 5) {
	    # adjust for fact that TCP doesn't guarantee size of reads/writes
	    arm(5);
	    $read = sysread(S,$buff,10,length($buff));
	    arm(0);
	}

	is(($read == 0 || $buff eq "olleh"), "PF_INET echo INADDR_LOOPBACK reply");
    }
}

# warnings
{
    my $w = 0;
    local $SIG{__WARN__} = sub {
	++ $w if $_[0] =~ /^6-ARG sockaddr_in call is deprecated/ ;
    };

    no warnings 'Socket';
    sockaddr_in(1,2,3,4,5,6) ;
    is($w, 0, "sockaddr_in deprecated form doesn't warn without lexical warnings");

    use warnings 'Socket';
    sockaddr_in(1,2,3,4,5,6) ;
    is($w, 1, "sockaddr_in deprecated form warns with lexical warnings");
}

# Test that whatever we give into pack/unpack_sockaddr retains
# the value thru the entire chain.
is(inet_ntoa((unpack_sockaddr_in(pack_sockaddr_in(100,inet_aton("10.250.230.10"))))[1]), '10.250.230.10',
   'inet_aton->pack_sockaddr_in->unpack_sockaddr_in->inet_ntoa roundtrip');

is(inet_ntoa(inet_aton("10.20.30.40")), "10.20.30.40", 'inet_aton->inet_ntoa roundtrip');
is(inet_ntoa(v10.20.30.40), "10.20.30.40", 'inet_ntoa from v-string');

{
    my ($port,$addr) = unpack_sockaddr_in(pack_sockaddr_in(100,v10.10.10.10));
    is($port, 100, 'pack_sockaddr_in->unpack_sockaddr_in port');
    is(inet_ntoa($addr), "10.10.10.10", 'pack_sockaddr_in->unpack_sockaddr_in addr');
}

{
    local $@;
    eval { inet_ntoa(v10.20.30.400) };
    like($@, qr/^Wide character in Socket::inet_ntoa at/, 'inet_ntoa warns about wide characters');
}

is(sockaddr_family(pack_sockaddr_in(100,inet_aton("10.250.230.10"))), AF_INET, 'pack_sockaddr_in->sockaddr_family');

{
    local $@;
    eval { sockaddr_family("") };
    like($@, qr/^Bad arg length for Socket::sockaddr_family, length is 0, should be at least \d+/, 'sockaddr_family warns about argument length');
}

SKIP: {
    # see if we can handle abstract sockets
    skip "Abstract AF_UNIX paths unsupported", 2 unless $^O eq "linux";

    my $test_abstract_socket = chr(0) . '/org/perl/hello'. chr(0) . 'world';
    my $addr = sockaddr_un ($test_abstract_socket);
    my ($path) = sockaddr_un ($addr);
    is($path, $test_abstract_socket, 'sockaddr_un can handle abstract AF_UNIX paths');

    # see if we calculate the address structure length correctly
    is(length ($test_abstract_socket) + 2, length $addr, 'sockaddr_un abstract address length');
}

SKIP: {
    skip "No inet_ntop", 3 unless $Config{d_inetntop} && $Config{d_inetaton};

    is(inet_ntop(AF_INET, inet_pton(AF_INET, "10.20.30.40")), "10.20.30.40", 'inet_pton->inet_ntop AF_INET roundtrip');
    is(inet_ntop(AF_INET, inet_aton("10.20.30.40")), "10.20.30.40", 'inet_aton->inet_ntop AF_INET roundtrip');

    SKIP: {
	skip "No AF_INET6", 1 unless defined eval { AF_INET6() };
	is(lc inet_ntop(AF_INET6, inet_pton(AF_INET6, "2001:503:BA3E::2:30")), "2001:503:ba3e::2:30", 'inet_pton->inet_ntop AF_INET6 roundtrip');
    }
}

SKIP: {
    skip "No AF_INET6", 5 unless defined eval { AF_INET6() };

    my $sin6 = pack_sockaddr_in6(0x1234, "0123456789abcdef", 0, 89);

    is(sockaddr_family($sin6), AF_INET6, 'sockaddr_family of pack_sockaddr_in6');

    is((unpack_sockaddr_in6($sin6))[0], 0x1234,             'pack_sockaddr_in6->unpack_sockaddr_in6 port');
    is((unpack_sockaddr_in6($sin6))[1], "0123456789abcdef", 'pack_sockaddr_in6->unpack_sockaddr_in6 addr');
    is((unpack_sockaddr_in6($sin6))[2], 0,                  'pack_sockaddr_in6->unpack_sockaddr_in6 scope_id');
    is((unpack_sockaddr_in6($sin6))[3], 89,                 'pack_sockaddr_in6->unpack_sockaddr_in6 flowinfo');
}
