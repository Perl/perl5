#!perl
use 5.020;
use feature 'signatures';
no warnings 'experimental::signatures';

use Getopt::Long;
use Pod::Usage;
use File::Find;
use Algorithm::Diff 'diff';

=head1 NAME

directory-diff.pl - Output a diff between the filenames of two directories

=head1 OPTIONS

B<--expression>, B<-e> - apply the transformation to the filenames

C<$_> will be set to the filename

  -e 's/5\.10\.0/5.10.1/g'

B<--expression-left>, B<-l> - apply the transformation to the filenames in the left directory

B<--expression-right>, B<-r> - apply the transformation to the filenames in the right directory

=cut

GetOptions(
    'expression|e=s' => \my $expr,
    'left|l=s' => \my $left_expr,
    'right|r=s' => \my $right_expr,
);

my $prev_release = ($] =~ s/(\d+)$/$1-1/re);
$expr //= "s/$prev_release/$]/g";

$left_expr //= $expr;
$right_expr //= '';

my $apply_expression_left = sub( $str ) {
    $_ = $str;
    eval $left_expr;
    die $@ if $@;
    return $_
};

my $apply_expression_right = sub( $str ) {
    $_ = $str;
    eval $left_expr;
    die $@ if $@;
    return $_
};

sub read_tree( $dir ) {
    my @files;
    File::Find::find( { wanted => sub {
        push @files, $File::Find::name
            if -f $File::Find::name
    }}, $dir);
    return sort @files
}

my ($dir_left, $dir_right) = @ARGV;

my @left  = map { s/^\Q$dir_left//;  $apply_expression_left->( $_ )  } read_tree( $dir_left );
my @right = map { s/^\Q$dir_right//; $apply_expression_right->( $_ ) } read_tree( $dir_right );

my $diff = Algorithm::Diff->new( \@left, \@right );
$diff->Base( 1 );   # Return line numbers, not indices
while(  $diff->Next()  ) {
    next   if  $diff->Same();
    my $sep = '';
    if(  ! $diff->Items(2)  ) {
        printf "%d,%dd%d\n",
            $diff->Get(qw( Min1 Max1 Max2 ));
    } elsif(  ! $diff->Items(1)  ) {
        printf "%da%d,%d\n",
            $diff->Get(qw( Max1 Min2 Max2 ));
    } else {
        $sep = "---\n";
        printf "%d,%dc%d,%d\n",
            $diff->Get(qw( Min1 Max1 Min2 Max2 ));
    }
    say "< $dir_left$_"   for  $diff->Items(1);
    print $sep;
    say "> $dir_right$_"   for  $diff->Items(2);
}
