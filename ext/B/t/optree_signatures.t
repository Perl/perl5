#!perl

BEGIN {
    unshift @INC, 't';
    require Config;
    if (($Config::Config{'extensions'} !~ /\bB\b/) ){
        print "1..0 # Skip -- Perl configured without B module\n";
        exit 0;
    }
}
use feature 'signatures';
use OptreeCheck;
plan tests => 14;

checkOptree( name => '0 args',
             code => sub () {},
             expect => <<'EOT_EOT');
4  <1> leavesub[1 ref] K/REFC,1 ->(end)
-     <1> ex-argcheck KP/1 ->4
-        <@> lineseq K ->-
1           <;> nextstate(main 1587 optree_signature.t:14) :%,fea=15 ->2
2           <+> multiparam(0) ->3
3           <;> nextstate(main 1587 optree_signature.t:15) :%,fea=15 ->4
EOT_EOT

checkOptree( name => '2 args',
             code => sub ($x, $y) {},
             expect => <<'EOT_EOT');
4  <1> leavesub[1 ref] K/REFC,1 ->(end)
-     <1> ex-argcheck KP/1 ->4
-        <@> lineseq K ->-
1           <;> nextstate(main 1587 optree_signature.t:14) :%,fea=15 ->2
2           <+> multiparam(2 $x,$y) ->3
3           <;> nextstate(main 1587 optree_signature.t:15) :%,fea=15 ->4
EOT_EOT

checkOptree( name => '2 anon args',
             code => sub ($, $) {},
             expect => <<'EOT_EOT');
4  <1> leavesub[1 ref] K/REFC,1 ->(end)
-     <1> ex-argcheck KP/1 ->4
-        <@> lineseq K ->-
1           <;> nextstate(main 1587 optree_signature.t:14) :%,fea=15 ->2
2           <+> multiparam(2 $,$) ->3
3           <;> nextstate(main 1587 optree_signature.t:15) :%,fea=15 ->4
EOT_EOT

checkOptree( name => '2 + 1 optional args',
             code => sub ($x, $y, $z = undef) {},
             expect => <<'EOT_EOT');
8  <1> leavesub[1 ref] K/REFC,1 ->(end)
-     <1> ex-argcheck KP/1 ->8
-        <@> lineseq K ->-
1           <;> nextstate(main 1596 optree_signature.t:38) :%,fea=15 ->2
2           <+> multiparam(2..3 $x,$y,$z) ->3
3           <;> nextstate(main 1596 optree_signature.t:37) :%,fea=15 ->4
-           <1> null K/1 ->7
4              <|> paramtest(other->5)[$z:1595,1596] vK ->7
6                 <1> paramstore[$z:1595,1596] K/1 ->7
5                    <0> undef s ->6
7           <;> nextstate(main 1596 optree_signature.t:38) :%,fea=15 ->8
EOT_EOT

checkOptree( name => '2 + slurpy array args',
             code => sub ($x, $y, @rest) {},
             expect => <<'EOT_EOT');
4  <1> leavesub[1 ref] K/REFC,1 ->(end)
-     <1> ex-argcheck KP/1 ->4
-        <@> lineseq K ->-
1           <;> nextstate(main 1587 optree_signature.t:14) :%,fea=15 ->2
2           <+> multiparam(2 $x,$y,@rest) ->3
3           <;> nextstate(main 1587 optree_signature.t:15) :%,fea=15 ->4
EOT_EOT

checkOptree( name => 'named args',
             code => sub (:$alpha, :$beta) {},
             expect => <<'EOT_EOT');
4  <1> leavesub[1 ref] K/REFC,1 ->(end)
-     <1> ex-argcheck KP/1 ->4
-        <@> lineseq K ->-
1           <;> nextstate(main 1587 optree_signature.t:14) :%,fea=15 ->2
2           <+> multiparam(0 :alpha,:beta) ->3
3           <;> nextstate(main 1587 optree_signature.t:15) :%,fea=15 ->4
EOT_EOT

checkOptree( name => '2 + named + slurpy args',
             code => sub ($x, $y, :$alpha, :$beta, @rest) {},
             expect => <<'EOT_EOT');
4  <1> leavesub[1 ref] K/REFC,1 ->(end)
-     <1> ex-argcheck KP/1 ->4
-        <@> lineseq K ->-
1           <;> nextstate(main 1587 optree_signature.t:14) :%,fea=15 ->2
2           <+> multiparam(2 $x,$y,:alpha,:beta,@rest) ->3
3           <;> nextstate(main 1587 optree_signature.t:15) :%,fea=15 ->4
EOT_EOT
