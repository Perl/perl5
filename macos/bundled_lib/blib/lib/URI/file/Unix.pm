package URI::file::Unix;

require URI::file::Base;
@ISA=qw(URI::file::Base);

use strict;
use URI::Escape qw(uri_unescape);

sub extract_path
{
    my($class, $path) = @_;
    # tidy path
    $path =~ s,//+,/,g;
    $path =~ s,(/\.)+/,/,g;
    $path = "./$path" if $path =~ m,^[^:/]+:,,; # look like "scheme:"
    $path;
}

sub file
{
    my $class = shift;
    my $uri = shift;

    my @path;

    my $auth = $uri->authority;
    if (defined($auth)) {
	if (lc($auth) ne "localhost") {
	    $auth = uri_unescape($auth);
	    unless ($class->is_this_host($auth)) {
		push(@path, "", "", $auth);
	    }
	}
    }

    my @ps = $uri->path_segments;
    shift @ps if @path;
    push(@path, @ps);

    for (@path) {
	# Unix file/directory names are not allowed to contain '\0' or '/'
	return if /\0/;
	return if /\//;  # should we really?
    }
    join("/", @path);
}

1;
