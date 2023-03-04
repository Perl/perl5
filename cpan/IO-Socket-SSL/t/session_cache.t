my $DEBUG = 0;

use strict;
use warnings;
use Net::SSLeay;
use Socket;
use IO::Socket::SSL;
do './testlib.pl' || do './t/testlib.pl' || die "no testlib";

$|=1;
my $numtests = 11;
print "1..$numtests\n";

my $ctx = IO::Socket::SSL::SSL_Context->new(
     SSL_ca_file => "t/certs/test-ca.pem",
     SSL_session_cache_size => 3,
);

my $cache = $ctx->{session_cache} or do {
    print "not ok \# Context init\n";
    exit;
};
ok("Context init");

my $dump_cache = $DEBUG ? sub { diag($cache->_dump) } : sub {};

print "not " if $cache->{room} != 3;
ok("0 entries in cache, room for 3 more");
&$dump_cache;

$cache->add_session("bogus", 0);
print "not " if $cache->{ghead}[1] ne 'bogus';
ok("cache head at 'bogus'");
&$dump_cache;

$cache->add_session("bogus1", 0);
print "not " if $cache->{room} != 1;
ok("two entries in cache, room for 1 more");
print "not " if $cache->{ghead}[1] ne 'bogus1';
ok("cache head at 'bogus1'");
&$dump_cache;

$cache->get_session("bogus");
print "not " if $cache->{ghead}[1] ne 'bogus';
ok("get_session moves cache head to 'bogus'");
&$dump_cache;

$cache->add_session("bogus", 0);
print "not " if $cache->{room} != 0;
ok("3 entries in cache, room for no more");
&$dump_cache;

# add another bogus and bogus1 should be removed to make room
print "not " if ! $cache->{shead}{bogus1};
ok("bogus1 still in cache");
&$dump_cache;

$cache->add_session("bogus", 0);
print "not " if $cache->{room} != 0;
ok("still 3 entries in cache, room for no more");
&$dump_cache;

print "not " if $cache->{shead}{bogus1};
ok("bogus1 removed from cache to make room");

# when removing 'bogus' the cache should be empty again
$cache->del_session('bogus');
print "not " if $cache->{room} != 3;
ok("0 entries in cache, room for 3");
&$dump_cache;


sub ok {
    my $line = (caller)[2];
    print "ok # $_[0]\n";
}
sub diag {
    my $msg = shift;
    $msg =~s{^}{ # }mg;
    print STDERR $msg;
}
