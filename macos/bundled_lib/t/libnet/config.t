#!./perl -w

BEGIN {
    if ($ENV{PERL_CORE}) {
	chdir 't' if -d 't';
	@INC = '../lib';
    }
}

(my $libnet_t = __FILE__) =~ s/config.t/libnet_t.pl/;
require $libnet_t;

print "1..10\n";

use Net::Config;
ok( exists $INC{'Net/Config.pm'}, 'Net::Config should have been used' );
ok( keys %NetConfig, '%NetConfig should be imported' );

undef $NetConfig{'ftp_firewall'};
is( Net::Config->requires_firewall(), 0, 
	'requires_firewall() should return 0 without ftp_firewall defined' );

$NetConfig{'ftp_firewall'} = 1;
is( Net::Config->requires_firewall(''), -1,
	'... should return -1 without a valid hostname' );

delete $NetConfig{'local_netmask'};
is( Net::Config->requires_firewall('127.0.0.1'), 0,
	'... should return 0 without local_netmask defined' );

$NetConfig{'local_netmask'} = '127.0.0.1/24';
is( Net::Config->requires_firewall('127.0.0.1'), 0,
	'... should return false if host is within netmask' );
is( Net::Config->requires_firewall('192.168.10.0'), 1,
	'... should return true if host is outside netmask' );

# now try more netmasks
$NetConfig{'local_netmask'} = [ '127.0.0.1/24', '10.0.0.0/8' ];
is( Net::Config->requires_firewall('10.10.255.254'), 0,
	'... should find success with mutiple local netmasks' );
is( Net::Config->requires_firewall('192.168.10.0'), 1,
	'... should handle failure with multiple local netmasks' );

is( \&Net::Config::is_external, \&Net::Config::requires_firewall,
	'is_external() should be an alias for requires_firewall()' );
