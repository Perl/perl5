package URI::file::Win32;

require URI::file::Base;
@ISA=qw(URI::file::Base);

use strict;
use URI::Escape qw(uri_unescape);

sub extract_authority
{
    my $class = shift;
    return $1 if $_[0] =~ s,^\\\\([^\\]+),,;  # UNC
    return $1 if $_[0] =~ s,^//([^/]+),,;     # UNC too?

    if ($_[0] =~ s,^([a-zA-Z]:),,) {
	my $auth = $1;
	$auth .= "relative" if $_[0] !~ m,^[\\/],;
	return $auth;
    }
    return;
}

sub extract_path
{
    my($class, $path) = @_;
    $path =~ s,\\,/,g;
    $path =~ s,//+,/,g;
    $path =~ s,(/\.)+/,/,g;
    $path;
}

sub file
{
    my $class = shift;
    my $uri = shift;
    my $auth = $uri->authority;
    my $rel; # is filename relative to drive specified in authority
    if (defined $auth) {
        $auth = uri_unescape($auth);
	if ($auth =~ /^([a-zA-Z])[:|](relative)?/) {
	    $auth = uc($1) . ":";
	    $rel++ if $2;
	} elsif (lc($auth) eq "localhost") {
	    $auth = "";
	} elsif (length $auth) {
	    $auth = "\\\\" . $auth;  # UNC
	}
    } else {
	$auth = "";
    }

    my @path = $uri->path_segments;
    for (@path) {
	return if /\0/;
	return if /\//;
	#return if /\\/;        # URLs with "\" is not uncommon
	
    }
    return unless $class->fix_path(@path);

    my $path = join("\\", @path);
    $path =~ s/^\\// if $rel;
    $path = $auth . $path;
    $path =~ s,^\\([a-zA-Z])[:|],\u$1:,;
    $path;
}

sub fix_path { 1; }

1;
