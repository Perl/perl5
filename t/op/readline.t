#!./perl

BEGIN {
    chdir 't';
    @INC = '../lib';
    require './test.pl';
}

plan tests => 5;

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
