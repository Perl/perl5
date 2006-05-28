use re Debug=>qw(COMPILE EXECUTE);
my @tests=(
  XY     =>  'X(A|[B]Q||C|D)Y' ,
  foobar =>  '[f][o][o][b][a][r]',
  x  =>  '.[XY].',
  'ABCD' => '(?:ABCP|ABCG|ABCE|ABCB|ABCA|ABCD)',
);
while (@tests) {
    my ($str,$pat)=splice @tests,0,2;
    warn "\n";
    # string eval to get the free regex message in the right place.
    eval qq[
        warn "$str"=~/$pat/ ? "%MATCHED%" : "%FAILED%","\n";
    ];
    die $@ if $@;
}
