#!./perl

BEGIN {
    chdir 't';
    @INC = '../lib';
    require './test.pl';
}

plan tests => 11;

eval { for (\2) { $_ = <FH> } };
like($@, 'Modification of a read-only value attempted', '[perl #19566]');

{
  open A,"+>a"; $a = 3;
  is($a .= <A>, 3, '#21628 - $a .= <A> , A eof');
  close A; $a = 4;
  is($a .= <A>, 4, '#21628 - $a .= <A> , A closed');
  unlink "a";
}

# 82 is chosen to exceed the length for sv_grow in do_readline (80)
foreach my $k ('k', 'k'x82) {
  my $result
    = runperl (switches => '-l', stdin => '', stderr => 1,
	       prog => "%a = qw($k v); \$_ = <> foreach keys %a; print qw(end)",
	      );
  is ($result, "end", '[perl #21614] for length ' . length $k);
}


foreach my $k ('perl', 'perl'x21) {
  my $result
    = runperl (switches => '-l', stdin => ' rules', stderr => 1,
	       prog => "%a = qw($k v); foreach (keys %a) {\$_ .= <>; print}",
	      );
  is ($result, "$k rules", 'rcatline to shared sv for length ' . length $k);
}

foreach my $l (1, 82) {
  my $k = $l;
  $k = 'k' x $k;
  my $copy = $k;
  $k = <DATA>;
  is ($k, "moo\n", 'catline to COW sv for length ' . length $copy);
}


foreach my $l (1, 21) {
  my $k = $l;
  $k = 'perl' x $k;
  my $perl = $k;
  $k .= <DATA>;
  is ($k, "$perl rules\n", 'rcatline to COW sv for length ' . length $perl);
}
__DATA__
moo
moo
 rules
 rules
