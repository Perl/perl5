package Search::Dict;
require 5.000;
require Exporter;

use strict;

our $VERSION = '1.01';
our @ISA = qw(Exporter);
our @EXPORT = qw(look);

=head1 NAME

Search::Dict, look - search for key in dictionary file

=head1 SYNOPSIS

    use Search::Dict;
    look *FILEHANDLE, $key, $dict, $fold, $comp;

=head1 DESCRIPTION

Sets file position in FILEHANDLE to be first line greater than or equal
(stringwise) to I<$key>.  Returns the new file position, or -1 if an error
occurs.

The flags specify dictionary order and case folding:

If I<$dict> is true, search by dictionary order (ignore anything but word
characters and whitespace).  The default is honour all characters.

If I<$fold> is true, ignore case.  The default is to honour case.

If I<$comp> is defined, use that as a reference to the comparison subroutine,
which must return less than zero, zero, or greater than zero, if the
first comparand is less than, equal, or greater than the second comparand.

If there are only three arguments and the third argument is a hash
reference, the keys of that hash can have values C<dict>, C<fold>, and
C<comp>, and their correponding values will be used as the parameters.

=cut

sub look {
    my($fh,$key,$dict,$fold,$comp) = @_;
    if (@_ == 3 && ref $dict eq 'HASH') {
	my $opt = $dict;
	$dict = 0;
	$dict = $opt->{dict} if exists $opt->{dict};
	$fold = $opt->{fold} if exists $opt->{fold};
	$comp = $opt->{comp} if exists $opt->{comp};
    }
    $comp = sub { $_[0] cmp $_[1] } unless defined $comp;
    local($_);
    my(@stat) = stat($fh)
	or return -1;
    my($size, $blksize) = @stat[7,11];
    $blksize ||= 8192;
    $key =~ s/[^\w\s]//g if $dict;
    $key = lc $key       if $fold;
    # find the right block
    my($min, $max) = (0, int($size / $blksize));
    my $mid;
    while ($max - $min > 1) {
	$mid = int(($max + $min) / 2);
	seek($fh, $mid * $blksize, 0)
	    or return -1;
	<$fh> if $mid;			# probably a partial line
	$_ = <$fh>;
	chomp;
	s/[^\w\s]//g if $dict;
	$_ = lc $_   if $fold;
	if (defined($_) && $comp->($_, $key) < 0) {
	    $min = $mid;
	}
	else {
	    $max = $mid;
	}
    }
    # find the right line
    $min *= $blksize;
    seek($fh,$min,0)
	or return -1;
    <$fh> if $min;
    for (;;) {
	$min = tell($fh);
	defined($_ = <$fh>)
	    or last;
	chomp;
	s/[^\w\s]//g if $dict;
	$_ = lc $_   if $fold;
	last if $comp->($_, $key) >= 0;
    }
    seek($fh,$min,0);
    $min;
}

1;
