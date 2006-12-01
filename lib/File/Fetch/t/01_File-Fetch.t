BEGIN { chdir 't' if -d 't' };

use strict;
use lib '../lib';

use Test::More 'no_plan';

use Cwd             qw[cwd];
use File::Basename  qw[basename];
use Data::Dumper;

unless( $ENV{PERL_CORE} ) {
    warn qq[

####################### NOTE ##############################

Some of these tests assume you are connected to the
internet. If you are not, or if certain protocols or hosts
are blocked and/or firewalled, these tests will fail due
to no fault of the module itself.

###########################################################

];

    sleep 3;
}

use_ok('File::Fetch');
use_ok('File::Fetch::Item');

### optionally set debugging ###
$File::Fetch::DEBUG = $File::Fetch::DEBUG = 1 if $ARGV[0];

### _parse_uri tests
my $map = [
    {   uri     => 'ftp://cpan.org/pub/mirror/index.txt',
        scheme  => 'ftp',
        host    => 'cpan.org',
        path    => '/pub/mirror/',
        file    => 'index.txt'
    },
    {   uri     => 'file:///usr/local/tmp/foo.txt',
        scheme  => 'file',
        host    => '',
        path    => '/usr/local/tmp/',
        file    => 'foo.txt',
    },
    {	uri	=> 'rsync://cpan.pair.com/CPAN/MIRRORING.FROM',
	scheme	=> 'rsync',
	host	=> 'cpan.pair.com',
	path	=> '/CPAN/',
	file	=> 'MIRRORING.FROM',
    },
];

### parse uri tests ###
for my $entry (@$map ) {
    my $uri = $entry->{'uri'};

    my $href = File::Fetch->_parse_uri( $uri );
    ok( $href,  "Able to parse uri '$uri'" );

    for my $key ( sort keys %$entry ) {
        is( $href->{$key}, $entry->{$key},
                "   '$key' ok ($entry->{$key})");
    }
}

### File::Fetch::Item tests ###
for my $entry (@$map) {
    my $ffi = File::Fetch::Item->new( %$entry );
    isa_ok( $ffi, 'File::Fetch::Item' );

    for my $acc ( keys %$entry ) {
        is( $ffi->$acc(), $entry->{$acc},
                    "   Accessor '$acc' ok" );
    }
}

### File::Fetch->new tests ###
for my $entry (@$map) {
    my $ff = File::Fetch->new( uri => $entry->{uri} );
    isa_ok( $ff, "File::Fetch::Item" );
}

### fetch() tests ###

### file:// tests ###
{
    my $prefix = &File::Fetch::ON_UNIX ? 'file:/' : 'file://';
    my $uri = $prefix . cwd() .'/'. basename($0);

    for (qw[lwp file]) {
        _fetch_uri( file => $uri, $_ );
    }
}

### ftp:// tests ###
{   my $uri = 'ftp://ftp.funet.fi/pub/CPAN/index.html';
    for (qw[lwp netftp wget curl ncftp]) {

        ### STUPID STUPID warnings ###
        next if $_ eq 'ncftp' and $File::Fetch::FTP_PASSIVE
                              and $File::Fetch::FTP_PASSIVE;

        _fetch_uri( ftp => $uri, $_ );
    }
}

### http:// tests ###
{   my $uri = 'http://www.cpan.org/index.html';

    for (qw[lwp wget curl lynx]) {
        _fetch_uri( http => $uri, $_ );
    }
}

### rsync:// tests ###
{   my $uri = 'rsync://cpan.pair.com/CPAN/MIRRORING.FROM';

    for (qw[rsync]) {
        _fetch_uri( rsync => $uri, $_ );
    }
}

sub _fetch_uri {
    my $type    = shift;
    my $uri     = shift;
    my $method  = shift or return;

    SKIP: {
        skip "'$method' fetching tests disabled under perl core", 3
                if $ENV{PERL_CORE};
    
        ### stupid warnings ###
        $File::Fetch::METHODS =
        $File::Fetch::METHODS = { $type => [$method] };
    
        my $ff  = File::Fetch->new( uri => $uri );
    
        ok( $ff,        "FF object for $uri (will fetch with $method)" );
    
        my $file = $ff->fetch( to => 'tmp' );
    
        SKIP: {
            skip "You do not have '$method' installed", 2
                if $File::Fetch::METHOD_FAIL->{$method} &&
                   $File::Fetch::METHOD_FAIL->{$method};
    
            ok( $file,      "   File ($file) fetched using $method" );
            ok( -s $file,   "   File ($file) has size" );
    
            unlink $file;
        }
    }
}








