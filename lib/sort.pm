package sort;

our $VERSION = '1.00';

$sort::hint_bits       = 0x00020000; # HINT_LOCALIZE_HH, really...

$sort::quicksort_bit   = 0x00000001;
$sort::mergesort_bit   = 0x00000002;
$sort::sort_bits       = 0x000000FF; # allow 256 different ones
$sort::stable_bit      = 0x00000100;
$sort::insensitive_bit = 0x00000200;
$sort::safe_bits       = 0x00000300;
$sort::fast_bit        = 0x00000400;

use strict;

sub import {
    shift;
    if (@_ == 0) {
	require Carp;
	Carp::croak("sort pragma requires arguments");
    }
    $^H |= $sort::hint_bits;
    local $_;
    no warnings 'uninitialized';	# $^H{SORT} bitops would warn
    while ($_ = shift(@_)) {
	if (/^q(?:uick)?sort$/) {
	    $^H{SORT} &= ~$sort::sort_bits;
	    $^H{SORT} |=  $sort::quicksort_bit;
	    return;
	} elsif ($_ eq 'mergesort') {
	    $^H{SORT} &= ~$sort::sort_bits;
	    $^H{SORT} |=  $sort::mergesort_bit;
	    return;
	} elsif ($_ eq 'safe') {
	    $^H{SORT} &= ~$sort::fast_bit;
	    $^H{SORT} |=  $sort::safe_bits;
	    $_ = 'mergesort';
	    redo;
	} elsif ($_ eq 'fast') {
	    $^H{SORT} &= ~$sort::safe_bits;
	    $^H{SORT} |=  $sort::fast_bit;
	    $_ = 'quicksort';
	    redo;
	} else {
	    require Carp;
	    Carp::croak("sort: unknown subpragma '@_'");
	}
    }
}

sub current {
    my @sort;
    if ($^H{SORT}) {
	push @sort, 'quicksort' if $^H{SORT} & $sort::quicksort_bit;
	push @sort, 'mergesort' if $^H{SORT} & $sort::mergesort_bit;
	push @sort, 'safe'      if $^H{SORT} & $sort::safe_bits;
	push @sort, 'fast'      if $^H{SORT} & $sort::fast_bit;
    }
    push @sort, 'mergesort' unless @sort;
    join(' ', @sort);
}

1;
__END__

=head1 NAME

sort - perl pragma to control sort() behaviour

=head1 SYNOPSIS

    use sort 'quicksort';
    use sort 'mergesort';

    use sort 'qsort';		# alias for quicksort

    # alias for mergesort: insensitive and stable
    use sort 'safe';		

    # alias for raw quicksort: sensitive and nonstable
    use sort 'fast';

    my $current = sort::current();

=head1 DESCRIPTION

With the sort pragma you can control the behaviour of the builtin
sort() function.

In Perl versions 5.6 and earlier the quicksort algorithm was used to
implement sort(), but in Perl 5.8 the algorithm was changed to mergesort,
mainly to guarantee insensitiveness to sort input: the worst case of
quicksort is O(N**2), while mergesort is always O(N log N).

On the other hand, for same cases (especially for shorter inputs)
quicksort is faster.

In Perl 5.8 and later by default quicksort is wrapped into a
stabilizing layer.  A stable sort means that for records that compare
equal, the original input ordering is preserved.  Mergesort is stable;
quicksort is not.

The metapragmas 'fast' and 'safe' select quicksort without the
stabilizing layer and mergesort, respectively.  In other words,
'safe' is the default.

Finally, the sort performance is also dependent on the platform
(smaller CPU caches favour quicksort).

=cut

