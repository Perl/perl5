package FileCache;

our $VERSION = '1.01';

=head1 NAME

FileCache - keep more files open than the system permits

=head1 SYNOPSIS

    cacheout $path;
    print $path @data;

=head1 DESCRIPTION

The C<cacheout> function will make sure that there's a filehandle open
for writing available as the pathname you give it.  It automatically
closes and re-opens files if you exceed your system file descriptor
maximum.

=head1 CAVEATS

If the argument passed to cacheout does not begin with a valid mode
(>, +>, <, +<, >>, |) then the file will be clobbered the first time
it is opened.

    cacheout '>>' . $path;
    print $path @data;

If $path includes the filemode the filehandle will not be accessible
as $path.

=head1 BUGS

F<sys/param.h> lies with its C<NOFILE> define on some systems,
so you may have to set $FileCache::cacheout_maxopen yourself.

=cut

require 5.000;
use Carp;
use Exporter;
use strict;
use vars qw(@ISA @EXPORT %saw $cacheout_maxopen);

@ISA = qw(Exporter);
@EXPORT = qw(
    cacheout
);

my %isopen;
my $cacheout_seq = 0;

# Open in their package.

sub cacheout_open {
    my $pack = caller(1);
    no strict 'refs';
    open(*{$pack . '::' . $_[0]}, $_[1]);
}

sub cacheout_close {
    my $pack = caller(1);
    close(*{$pack . '::' . $_[0]});
}

# But only this sub name is visible to them.

sub cacheout {
    my($file) = @_;
    unless (defined $cacheout_maxopen) {
	if (open(PARAM,'/usr/include/sys/param.h')) {
	    local ($_, $.);
	    while (<PARAM>) {
		$cacheout_maxopen = $1 - 4
		    if /^\s*#\s*define\s+NOFILE\s+(\d+)/;
	    }
	    close PARAM;
	}
	$cacheout_maxopen = 16 unless $cacheout_maxopen;
    }
    if (!$isopen{$file}) {
	if ( scalar keys(%isopen) + 1 > $cacheout_maxopen) {
	    my @lru = sort {$isopen{$a} <=> $isopen{$b};} keys(%isopen);
	    splice(@lru, $cacheout_maxopen / 3);
	    for (@lru) { &cacheout_close($_); delete $isopen{$_}; }
	}
	my $symbol = $file;
	unless( $symbol =~ s/^(\s?(?:>>)|(?:\+?>)|(?:\+?<)|\|)// ){
	  $file = ($saw{$file}++ ? '>>' : '>') . $file;
	}
	cacheout_open($symbol, $file)
	    or croak("Can't create $file: $!");
    }
    $isopen{$file} = ++$cacheout_seq;
}

1;
