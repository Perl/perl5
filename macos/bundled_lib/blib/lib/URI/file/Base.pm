package URI::file::Base;

use strict;
use URI::Escape qw();

sub new
{
    my $class = shift;
    my $path  = shift;
    $path = "" unless defined $path;

    my($auth, $escaped_auth, $escaped_path);

    ($auth, $escaped_auth) = $class->extract_authority($path);
    ($path, $escaped_path) = $class->extract_path($path);

    if (defined $auth) {
	$auth =~ s,%,%25,g unless $escaped_auth;
	$auth =~ s,([/?\#]),$URI::Escape::escapes{$1},g;
	$auth = "//$auth";
	if (defined $path) {
	    $path = "/$path" unless substr($path, 0, 1) eq "/";
	} else {
	    $path = "";
	}
    } else {
	return unless defined $path;
	$auth = "";
    }

    $path =~ s,([%;?]),$URI::Escape::escapes{$1},g unless $escaped_path;
    $path =~ s/\#/%23/g;

    my $uri = $auth . $path;
    $uri = "file:$uri" if substr($uri, 0, 1) eq "/";

    URI->new($uri, "file");
}

sub extract_authority
{
    undef;
}

sub extract_path
{
    undef;
}

sub is_this_host
{
    shift; # class
    my $host = lc(shift);
    return 1 if $host eq "localhost";
    eval {
	require Net::Domain;
	lc(Net::Domain::hostfqdn()) eq $host ||
	lc(Net::Domain::hostname()) eq $host;
    };
}

sub file
{
    undef;
}

sub dir
{
    my $self = shift;
    $self->file(@_);
}

1;
