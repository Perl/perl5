#!./perl

# force perl-only version to be tested
sub List::Util::bootstrap {}

(my $f = __FILE__) =~ s/p_//;
$::PERL_ONLY = $::PERL_ONLY = 1; # Mustn't use it only once!
do $f;
