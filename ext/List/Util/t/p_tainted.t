#!./perl -T

# force perl-only version to be tested
sub List::Util::bootstrap {}

(my $f = __FILE__) =~ s/p_//;
do "./$f";
