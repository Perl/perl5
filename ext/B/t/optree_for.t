#!perl

BEGIN {
    unshift @INC, 't';
    require Config;
    if (($Config::Config{'extensions'} !~ /\bB\b/) ){
        print "1..0 # Skip -- Perl configured without B module\n";
        exit 0;
    }
}
use OptreeCheck;
plan tests => 11;

pass("FOR LOOPS");

checkOptree ( name      => 'for (@a)',
              code      => sub {for (@a) {}},
              bcopts    => '-exec',
              strip_open_hints => 1,
              expect    => <<'EOT_EOT', expect_nt => <<'EONT_EONT');
1  <;> nextstate(main 424 optree_for.t:14) v:>,<,%
2  <0> pushmark sM
3  <#> gv[*a] s
4  <1> rv2av[t2] sKRM/1
5  <#> gv[*_] s
6  <{> enteriter(next->8 last->b redo->7) KS/DEF
9  <0> iter s
a  <|> and(other->7) K/1
7      <0> stub v
8      <0> unstack s
           goto 9
b  <2> leaveloop K/2
c  <1> leavesub[1 ref] K/REFC,1
EOT_EOT
1  <;> nextstate(main 424 optree_for.t:14) v:>,<,%
2  <0> pushmark sM
3  <$> gv(*a) s
4  <1> rv2av[t1] sKRM/1
5  <$> gv(*_) s
6  <{> enteriter(next->8 last->b redo->7) KS/DEF
9  <0> iter s
a  <|> and(other->7) K/1
7      <0> stub v
8      <0> unstack s
           goto 9
b  <2> leaveloop K/2
c  <1> leavesub[1 ref] K/REFC,1
EONT_EONT

my @lexical;

checkOptree ( name      => 'for (@lexical)',
              code      => sub {for (@lexical) {}},
              bcopts    => '-exec',
              strip_open_hints => 1,
              expect    => <<'EOT_EOT', expect_nt => <<'EONT_EONT');
1  <;> nextstate(main 424 optree_for.t:14) v:>,<,%
2  <0> pushmark sM
3  <0> padav[@lexical:FAKE::7] sRM
4  <#> gv[*_] s
5  <{> enteriter(next->7 last->a redo->6) KS/DEF
8  <0> iter s
9  <|> and(other->6) K/1
6      <0> stub v
7      <0> unstack s
           goto 8
a  <2> leaveloop K/2
b  <1> leavesub[2 refs] K/REFC,1
EOT_EOT
1  <;> nextstate(main 424 optree_for.t:14) v:>,<,%
2  <0> pushmark sM
3  <0> padav[@lexical:FAKE::2] sRM
4  <$> gv(*_) s
5  <{> enteriter(next->7 last->a redo->6) KS/DEF
8  <0> iter s
9  <|> and(other->6) K/1
6      <0> stub v
7      <0> unstack s
           goto 8
a  <2> leaveloop K/2
b  <1> leavesub[2 refs] K/REFC,1
EONT_EONT

checkOptree ( name      => 'for $var (@a)',
              code      => sub {for $var (@a) {}},
              bcopts    => '-exec',
              strip_open_hints => 1,
              expect    => <<'EOT_EOT', expect_nt => <<'EONT_EONT');
1  <;> nextstate(main 1453 optree_for.t:68) v:{
2  <0> pushmark sM
3  <#> gv[*a] s
4  <1> rv2av[t3] sKRM/1
5  <#> gv[*var] s
6  <1> rv2gv sKRM/1
7  <{> enteriter(next->9 last->c redo->8) KS
a  <0> iter s
b  <|> and(other->8) K/1
8      <0> stub v
9      <0> unstack s
           goto a
c  <2> leaveloop KP/2
d  <1> leavesub[1 ref] K/REFC,1
EOT_EOT
1  <;> nextstate(main 1453 optree_for.t:67) v:{
2  <0> pushmark sM
3  <$> gv(*a) s
4  <1> rv2av[t1] sKRM/1
5  <$> gv(*var) s
6  <1> rv2gv sKRM/1
7  <{> enteriter(next->9 last->c redo->8) KS
a  <0> iter s
b  <|> and(other->8) K/1
8      <0> stub v
9      <0> unstack s
           goto a
c  <2> leaveloop KP/2
d  <1> leavesub[1 ref] K/REFC,1
EONT_EONT

checkOptree ( name      => 'for my $var (@a)',
              code      => sub {for my $var (@a) {}},
              bcopts    => '-exec',
              strip_open_hints => 1,
              expect    => <<'EOT_EOT', expect_nt => <<'EONT_EONT');
1  <;> nextstate(main 1459 optree_for.t:90) v
2  <0> pushmark sM
3  <#> gv[*a] s
4  <1> rv2av[t3] sKRM/1
5  <{> enteriter(next->7 last->a redo->6)[$var:1460,1463] KS/LVINTRO
8  <0> iter s
9  <|> and(other->6) K/1
6      <0> stub v
7      <0> unstack s
           goto 8
a  <2> leaveloop K/2
b  <1> leavesub[1 ref] K/REFC,1
EOT_EOT
1  <;> nextstate(main 424 optree_for.t:14) v:>,<,%
2  <0> pushmark sM
3  <$> gv(*a) s
4  <1> rv2av[t2] sKRM/1
5  <{> enteriter(next->7 last->a redo->6)[$var:1460,1463] KS/LVINTRO
8  <0> iter s
9  <|> and(other->6) K/1
6      <0> stub v
7      <0> unstack s
           goto 8
a  <2> leaveloop K/2
b  <1> leavesub[1 ref] K/REFC,1
EONT_EONT

checkOptree ( name      => 'for our $var (@a)',
              code      => sub {for our $var (@a) {}},
              bcopts    => '-exec',
              strip_open_hints => 1,
              expect    => <<'EOT_EOT', expect_nt => <<'EONT_EONT');
1  <;> nextstate(main 1466 optree_for.t:100) v
2  <0> pushmark sM
3  <#> gv[*a] s
4  <1> rv2av[t4] sKRM/1
5  <#> gv[*var] s
6  <1> rv2gv sK/FAKE,1
7  <{> enteriter(next->9 last->c redo->8) KS/OURINTR
a  <0> iter s
b  <|> and(other->8) K/1
8      <0> stub v
9      <0> unstack s
           goto a
c  <2> leaveloop K/2
d  <1> leavesub[1 ref] K/REFC,1
EOT_EOT
1  <;> nextstate(main 424 optree_for.t:111) v:>,<,%
2  <0> pushmark sM
3  <$> gv(*a) s
4  <1> rv2av[t2] sKRM/1
5  <$> gv(*var) s
6  <1> rv2gv sK/FAKE,1
7  <{> enteriter(next->9 last->c redo->8) KS/OURINTR
a  <0> iter s
b  <|> and(other->8) K/1
8      <0> stub v
9      <0> unstack s
           goto a
c  <2> leaveloop K/2
d  <1> leavesub[1 ref] K/REFC,1
EONT_EONT
