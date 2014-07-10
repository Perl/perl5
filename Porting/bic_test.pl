use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use Hash::Util qw(hash_value);


sub _update_bits_changed_buckets {
    my ($buckets, $last_hash, $this_hash)= @_;
    my $xor= $last_hash ^ $this_hash;
    for my $bit ( 0 .. 31 ) {
        $buckets->[$bit]++ if $xor & (1 << $bit);
    }
}
    
sub _bic_test_rand {
    my ($num_bytes, $count)= @_;
    
    my $num_bits= $num_bytes * 8;
    my $last_n= $count ? $count - 1 : (2 ** 24) - 1;

    my $buf= "\0" x $num_bytes;
    my $last_hash= hash_value($buf);
    my $last_bit= -1;
    my $bit;
    my @buckets;

    print "Doing a statistical BIC check on strings of length $num_bytes (0..$last_n)\n";

    # we step through all of the possible keys of this length, but in *grey code* order
    # which means each iteration only one bit of the key changes. 
    for my $num ( 1 .. $last_n ) {
        printf "%-10d %5.2f \r", $num, ($num / $last_n) * 100 if $num % 100_000 == 0;

        do{ $bit= int rand $num_bits } until $bit != $last_bit;

        vec($buf, $bit, 1) ^= 1;

        my $this_hash= hash_value($buf);
        _update_bits_changed_buckets(\@buckets, $last_hash, $this_hash);
        $last_hash= $this_hash;
        $last_bit= $bit;
    }
    return( $last_n, \@buckets );

   
}

sub _bic_test_full {
    my ($num_bytes)= @_;
    
    my $num_bits= $num_bytes * 8;
    my $last_n= (2 ** $num_bits) - 1;

    my $buf= "\0" x $num_bytes;
    my $last_hash= hash_value($buf);
    my @buckets;

    print "Doing a full BIC check on strings of length $num_bytes (0..$last_n)\n";

    # we step through all of the possible keys of this length, but in *grey code* order
    # which means each iteration only one bit of the key changes. 
    for my $num ( 1 .. $last_n ) {
        printf "%-10d %5.2f \r", $num, ($num / $last_n) * 100 if $num % 100_000 == 0;
        my $grey= ($num >> 1) ^ $num;
        $buf= pack "N", $grey;
        my $this_hash= hash_value($buf);
        _update_bits_changed_buckets(\@buckets, $last_hash, $this_hash);
        $last_hash= $this_hash;
    }
    return( $last_n, \@buckets );
}


sub bic_test {
    my ($num_bytes, $count)= @_;

    my ($expect, $buckets);

    if ($num_bytes > 3) {
        ($expect, $buckets)= _bic_test_rand($num_bytes, $count);
    } else {
        ($expect, $buckets)= _bic_test_full($num_bytes);
    }
    my $l= length($expect);
    for my $row (reverse 0..3) {
        printf "bit %2d | ", $row * 8;
        for my $col (reverse 0..7) {
            my $bckt= ($row * 8) + $col;
            printf "%5.2f (%*d) | ", $buckets->[$bckt]/$expect*100, $l, $buckets->[$bckt];
        }
        print "\n";
    }
}





my $man = 0;
my $help = 0;
my $len  = 2;
my $count;

GetOptions('help|?' => \$help, man => \$man, 'len=i'=>\$len, 'count=i'=>\$count) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;

$|++;
bic_test($len, $count);





__END__

=head1 NAME

bic_test - test perls hash function for bitwise independence

=head1 SYNOPSIS

bic_test [options] [file ...]

 Options:
   -help            brief help message
   -man             full documentation

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<This program> will read the given input file(s) and do something
useful with the contents thereof.

=cut
