#!perl

BEGIN {
    chdir 't';
    @INC = ('../lib', '../ext/B/t');
    require './test.pl';
}
use OptreeCheck;

plan tests	=> 13;

pass("GENERAL OPTREE EXAMPLES");

pass("IF,THEN,ELSE, ?:");

checkOptree ( name	=> '-basic sub {if shift print then,else}',
	      bcopts	=> '-basic',
	      code	=> sub { if (shift) { print "then" }
				 else       { print "else" }
			     },
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
# B::Concise::compile(CODE(0x81a77b4))
# 9  <1> leavesub[1 ref] K/REFC,1 ->(end)
# -     <@> lineseq KP ->9
# 1        <;> nextstate(main 426 optree.t:16) v ->2
# -        <1> null K/1 ->-
# 5           <|> cond_expr(other->6) K/1 ->a
# 4              <1> shift sK/1 ->5
# 3                 <1> rv2av[t2] sKRM/1 ->4
# 2                    <#> gv[*_] s ->3
# -              <@> scope K ->-
# -                 <0> ex-nextstate v ->6
# 8                 <@> print sK ->9
# 6                    <0> pushmark s ->7
# 7                    <$> const[PV "then"] s ->8
# f              <@> leave KP ->9
# a                 <0> enter ->b
# b                 <;> nextstate(main 424 optree.t:17) v ->c
# e                 <@> print sK ->f
# c                    <0> pushmark s ->d
# d                    <$> const[PV "else"] s ->e
EOT_EOT
# 9  <1> leavesub[1 ref] K/REFC,1 ->(end)
# -     <@> lineseq KP ->9
# 1        <;> nextstate(main 427 optree_samples.t:18) v ->2
# -        <1> null K/1 ->-
# 5           <|> cond_expr(other->6) K/1 ->a
# 4              <1> shift sK/1 ->5
# 3                 <1> rv2av[t1] sKRM/1 ->4
# 2                    <$> gv(*_) s ->3
# -              <@> scope K ->-
# -                 <0> ex-nextstate v ->6
# 8                 <@> print sK ->9
# 6                    <0> pushmark s ->7
# 7                    <$> const(PV "then") s ->8
# f              <@> leave KP ->9
# a                 <0> enter ->b
# b                 <;> nextstate(main 425 optree_samples.t:19) v ->c
# e                 <@> print sK ->f
# c                    <0> pushmark s ->d
# d                    <$> const(PV "else") s ->e
EONT_EONT

checkOptree ( name	=> '-basic (see above, with my $a = shift)',
	      bcopts	=> '-basic',
	      code	=> sub { my $a = shift;
				 if ($a) { print "foo" }
				 else    { print "bar" }
			     },
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
# d  <1> leavesub[1 ref] K/REFC,1 ->(end)
# -     <@> lineseq KP ->d
# 1        <;> nextstate(main 431 optree.t:68) v ->2
# 6        <2> sassign vKS/2 ->7
# 4           <1> shift sK/1 ->5
# 3              <1> rv2av[t3] sKRM/1 ->4
# 2                 <#> gv[*_] s ->3
# 5           <0> padsv[$a:431,435] sRM*/LVINTRO ->6
# 7        <;> nextstate(main 435 optree.t:69) v ->8
# -        <1> null K/1 ->-
# 9           <|> cond_expr(other->a) K/1 ->e
# 8              <0> padsv[$a:431,435] s ->9
# -              <@> scope K ->-
# -                 <0> ex-nextstate v ->a
# c                 <@> print sK ->d
# a                    <0> pushmark s ->b
# b                    <$> const[PV "foo"] s ->c
# j              <@> leave KP ->d
# e                 <0> enter ->f
# f                 <;> nextstate(main 433 optree.t:70) v ->g
# i                 <@> print sK ->j
# g                    <0> pushmark s ->h
# h                    <$> const[PV "bar"] s ->i
EOT_EOT
# 1  <;> nextstate(main 45 optree.t:23) v
# 2  <0> padsv[$a:45,46] M/LVINTRO
# 3  <1> leavesub[1 ref] K/REFC,1
# d  <1> leavesub[1 ref] K/REFC,1 ->(end)
# -     <@> lineseq KP ->d
# 1        <;> nextstate(main 428 optree_samples.t:48) v ->2
# 6        <2> sassign vKS/2 ->7
# 4           <1> shift sK/1 ->5
# 3              <1> rv2av[t2] sKRM/1 ->4
# 2                 <$> gv(*_) s ->3
# 5           <0> padsv[$a:428,432] sRM*/LVINTRO ->6
# 7        <;> nextstate(main 432 optree_samples.t:49) v ->8
# -        <1> null K/1 ->-
# 9           <|> cond_expr(other->a) K/1 ->e
# 8              <0> padsv[$a:428,432] s ->9
# -              <@> scope K ->-
# -                 <0> ex-nextstate v ->a
# c                 <@> print sK ->d
# a                    <0> pushmark s ->b
# b                    <$> const(PV "foo") s ->c
# j              <@> leave KP ->d
# e                 <0> enter ->f
# f                 <;> nextstate(main 430 optree_samples.t:50) v ->g
# i                 <@> print sK ->j
# g                    <0> pushmark s ->h
# h                    <$> const(PV "bar") s ->i
EONT_EONT

checkOptree ( name	=> '-exec sub {if shift print then,else}',
	      bcopts	=> '-exec',
	      code	=> sub { if (shift) { print "then" }
				 else       { print "else" }
			     },
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
# B::Concise::compile(CODE(0x81a77b4))
# 1  <;> nextstate(main 426 optree.t:16) v
# 2  <#> gv[*_] s
# 3  <1> rv2av[t2] sKRM/1
# 4  <1> shift sK/1
# 5  <|> cond_expr(other->6) K/1
# 6      <0> pushmark s
# 7      <$> const[PV "then"] s
# 8      <@> print sK
#            goto 9
# a  <0> enter 
# b  <;> nextstate(main 424 optree.t:17) v
# c  <0> pushmark s
# d  <$> const[PV "else"] s
# e  <@> print sK
# f  <@> leave KP
# 9  <1> leavesub[1 ref] K/REFC,1
EOT_EOT
# 1  <;> nextstate(main 436 optree_samples.t:123) v
# 2  <$> gv(*_) s
# 3  <1> rv2av[t1] sKRM/1
# 4  <1> shift sK/1
# 5  <|> cond_expr(other->6) K/1
# 6      <0> pushmark s
# 7      <$> const(PV "then") s
# 8      <@> print sK
#            goto 9
# a  <0> enter 
# b  <;> nextstate(main 434 optree_samples.t:124) v
# c  <0> pushmark s
# d  <$> const(PV "else") s
# e  <@> print sK
# f  <@> leave KP
# 9  <1> leavesub[1 ref] K/REFC,1
EONT_EONT

checkOptree ( name	=> '-exec (see above, with my $a = shift)',
	      bcopts	=> '-exec',
	      code	=> sub { my $a = shift;
				 if ($a) { print "foo" }
				 else    { print "bar" }
			     },
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
# 1  <;> nextstate(main 423 optree.t:16) v
# 2  <#> gv[*_] s
# 3  <1> rv2av[t3] sKRM/1
# 4  <1> shift sK/1
# 5  <0> padsv[$a:423,427] sRM*/LVINTRO
# 6  <2> sassign vKS/2
# 7  <;> nextstate(main 427 optree.t:17) v
# 8  <0> padsv[$a:423,427] s
# 9  <|> cond_expr(other->a) K/1
# a      <0> pushmark s
# b      <$> const[PV "foo"] s
# c      <@> print sK
#            goto d
# e  <0> enter 
# f  <;> nextstate(main 425 optree.t:18) v
# g  <0> pushmark s
# h  <$> const[PV "bar"] s
# i  <@> print sK
# j  <@> leave KP
# d  <1> leavesub[1 ref] K/REFC,1
EOT_EOT
# 1  <;> nextstate(main 437 optree_samples.t:112) v
# 2  <$> gv(*_) s
# 3  <1> rv2av[t2] sKRM/1
# 4  <1> shift sK/1
# 5  <0> padsv[$a:437,441] sRM*/LVINTRO
# 6  <2> sassign vKS/2
# 7  <;> nextstate(main 441 optree_samples.t:113) v
# 8  <0> padsv[$a:437,441] s
# 9  <|> cond_expr(other->a) K/1
# a      <0> pushmark s
# b      <$> const(PV "foo") s
# c      <@> print sK
#            goto d
# e  <0> enter 
# f  <;> nextstate(main 439 optree_samples.t:114) v
# g  <0> pushmark s
# h  <$> const(PV "bar") s
# i  <@> print sK
# j  <@> leave KP
# d  <1> leavesub[1 ref] K/REFC,1
EONT_EONT

checkOptree ( name	=> '-exec sub { print (shift) ? "foo" : "bar" }',
	      code	=> sub { print (shift) ? "foo" : "bar" },
	      bcopts	=> '-exec',
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
# 1  <;> nextstate(main 428 optree.t:31) v
# 2  <0> pushmark s
# 3  <#> gv[*_] s
# 4  <1> rv2av[t2] sKRM/1
# 5  <1> shift sK/1
# 6  <@> print sK
# 7  <|> cond_expr(other->8) K/1
# 8      <$> const[PV "foo"] s
#            goto 9
# a  <$> const[PV "bar"] s
# 9  <1> leavesub[1 ref] K/REFC,1
EOT_EOT
# 1  <;> nextstate(main 442 optree_samples.t:144) v
# 2  <0> pushmark s
# 3  <$> gv(*_) s
# 4  <1> rv2av[t1] sKRM/1
# 5  <1> shift sK/1
# 6  <@> print sK
# 7  <|> cond_expr(other->8) K/1
# 8      <$> const(PV "foo") s
#            goto 9
# a  <$> const(PV "bar") s
# 9  <1> leavesub[1 ref] K/REFC,1
EONT_EONT

pass ("FOREACH");

checkOptree ( name	=> '-exec sub { foreach (1..10) {print "foo $_"} }',
	      code	=> sub { foreach (1..10) {print "foo $_"} },
	      bcopts	=> '-exec',
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
# 1  <;> nextstate(main 443 optree.t:158) v
# 2  <0> pushmark s
# 3  <$> const[IV 1] s
# 4  <$> const[IV 10] s
# 5  <#> gv[*_] s
# 6  <{> enteriter(next->d last->g redo->7) lKS
# e  <0> iter s
# f  <|> and(other->7) K/1
# 7      <;> nextstate(main 442 optree.t:158) v
# 8      <0> pushmark s
# 9      <$> const[PV "foo "] s
# a      <#> gvsv[*_] s
# b      <2> concat[t4] sK/2
# c      <@> print vK
# d      <0> unstack s
#            goto e
# g  <2> leaveloop K/2
# h  <1> leavesub[1 ref] K/REFC,1
# '
EOT_EOT
# 1  <;> nextstate(main 444 optree_samples.t:182) v
# 2  <0> pushmark s
# 3  <$> const(IV 1) s
# 4  <$> const(IV 10) s
# 5  <$> gv(*_) s
# 6  <{> enteriter(next->d last->g redo->7) lKS
# e  <0> iter s
# f  <|> and(other->7) K/1
# 7      <;> nextstate(main 443 optree_samples.t:182) v
# 8      <0> pushmark s
# 9      <$> const(PV "foo ") s
# a      <$> gvsv(*_) s
# b      <2> concat[t3] sK/2
# c      <@> print vK
# d      <0> unstack s
#            goto e
# g  <2> leaveloop K/2
# h  <1> leavesub[1 ref] K/REFC,1
EONT_EONT

checkOptree ( name	=> '-basic sub { print "foo $_" foreach (1..10) }',
	      code	=> sub { print "foo $_" foreach (1..10) }, 
	      bcopts	=> '-basic',
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
# h  <1> leavesub[1 ref] K/REFC,1 ->(end)
# -     <@> lineseq KP ->h
# 1        <;> nextstate(main 445 optree.t:167) v ->2
# 2        <;> nextstate(main 445 optree.t:167) v ->3
# g        <2> leaveloop K/2 ->h
# 7           <{> enteriter(next->d last->g redo->8) lKS ->e
# -              <0> ex-pushmark s ->3
# -              <1> ex-list lK ->6
# 3                 <0> pushmark s ->4
# 4                 <$> const[IV 1] s ->5
# 5                 <$> const[IV 10] s ->6
# 6              <#> gv[*_] s ->7
# -           <1> null K/1 ->g
# f              <|> and(other->8) K/1 ->g
# e                 <0> iter s ->f
# -                 <@> lineseq sK ->-
# c                    <@> print vK ->d
# 8                       <0> pushmark s ->9
# -                       <1> ex-stringify sK/1 ->c
# -                          <0> ex-pushmark s ->9
# b                          <2> concat[t2] sK/2 ->c
# 9                             <$> const[PV "foo "] s ->a
# -                             <1> ex-rv2sv sK/1 ->b
# a                                <#> gvsv[*_] s ->b
# d                    <0> unstack s ->e
EOT_EOT
# h  <1> leavesub[1 ref] K/REFC,1 ->(end)
# -     <@> lineseq KP ->h
# 1        <;> nextstate(main 446 optree_samples.t:192) v ->2
# 2        <;> nextstate(main 446 optree_samples.t:192) v ->3
# g        <2> leaveloop K/2 ->h
# 7           <{> enteriter(next->d last->g redo->8) lKS ->e
# -              <0> ex-pushmark s ->3
# -              <1> ex-list lK ->6
# 3                 <0> pushmark s ->4
# 4                 <$> const(IV 1) s ->5
# 5                 <$> const(IV 10) s ->6
# 6              <$> gv(*_) s ->7
# -           <1> null K/1 ->g
# f              <|> and(other->8) K/1 ->g
# e                 <0> iter s ->f
# -                 <@> lineseq sK ->-
# c                    <@> print vK ->d
# 8                       <0> pushmark s ->9
# -                       <1> ex-stringify sK/1 ->c
# -                          <0> ex-pushmark s ->9
# b                          <2> concat[t1] sK/2 ->c
# 9                             <$> const(PV "foo ") s ->a
# -                             <1> ex-rv2sv sK/1 ->b
# a                                <$> gvsv(*_) s ->b
# d                    <0> unstack s ->e
EONT_EONT

checkOptree ( name	=> '-exec -e foreach (1..10) {print "foo $_"}',
	      prog	=> 'foreach (1..10) {print "foo $_"}',
	      bcopts	=> '-exec',
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
# 1  <0> enter 
# 2  <;> nextstate(main 2 -e:1) v
# 3  <0> pushmark s
# 4  <$> const[IV 1] s
# 5  <$> const[IV 10] s
# 6  <#> gv[*_] s
# 7  <{> enteriter(next->e last->h redo->8) lKS
# f  <0> iter s
# g  <|> and(other->8) vK/1
# 8      <;> nextstate(main 1 -e:1) v
# 9      <0> pushmark s
# a      <$> const[PV "foo "] s
# b      <#> gvsv[*_] s
# c      <2> concat[t4] sK/2
# d      <@> print vK
# e      <0> unstack v
#            goto f
# h  <2> leaveloop vK/2
# i  <@> leave[1 ref] vKP/REFC
EOT_EOT
# 1  <0> enter 
# 2  <;> nextstate(main 2 -e:1) v
# 3  <0> pushmark s
# 4  <$> const(IV 1) s
# 5  <$> const(IV 10) s
# 6  <$> gv(*_) s
# 7  <{> enteriter(next->e last->h redo->8) lKS
# f  <0> iter s
# g  <|> and(other->8) vK/1
# 8      <;> nextstate(main 1 -e:1) v
# 9      <0> pushmark s
# a      <$> const(PV "foo ") s
# b      <$> gvsv(*_) s
# c      <2> concat[t3] sK/2
# d      <@> print vK
# e      <0> unstack v
#            goto f
# h  <2> leaveloop vK/2
# i  <@> leave[1 ref] vKP/REFC

EONT_EONT

checkOptree ( name	=> '-exec sub { print "foo $_" foreach (1..10) }',
	      code	=> sub { print "foo $_" foreach (1..10) }, 
	      bcopts	=> '-exec',
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
# B::Concise::compile(CODE(0x8332b20))
#            goto -
# 1  <;> nextstate(main 445 optree.t:167) v
# 2  <;> nextstate(main 445 optree.t:167) v
# 3  <0> pushmark s
# 4  <$> const[IV 1] s
# 5  <$> const[IV 10] s
# 6  <#> gv[*_] s
# 7  <{> enteriter(next->d last->g redo->8) lKS
# e  <0> iter s
# f  <|> and(other->8) K/1
# 8      <0> pushmark s
# 9      <$> const[PV "foo "] s
# a      <#> gvsv[*_] s
# b      <2> concat[t2] sK/2
# c      <@> print vK
# d      <0> unstack s
#            goto e
# g  <2> leaveloop K/2
# h  <1> leavesub[1 ref] K/REFC,1
EOT_EOT
# 1  <;> nextstate(main 447 optree_samples.t:252) v
# 2  <;> nextstate(main 447 optree_samples.t:252) v
# 3  <0> pushmark s
# 4  <$> const(IV 1) s
# 5  <$> const(IV 10) s
# 6  <$> gv(*_) s
# 7  <{> enteriter(next->d last->g redo->8) lKS
# e  <0> iter s
# f  <|> and(other->8) K/1
# 8      <0> pushmark s
# 9      <$> const(PV "foo ") s
# a      <$> gvsv(*_) s
# b      <2> concat[t1] sK/2
# c      <@> print vK
# d      <0> unstack s
#            goto e
# g  <2> leaveloop K/2
# h  <1> leavesub[1 ref] K/REFC,1
EONT_EONT

checkOptree ( name	=> '-e use constant j => "junk"; print j',
	      prog	=> 'use constant j => "junk"; print j',
	      bcopts	=> '-exec',
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
# 1  <0> enter 
# 2  <;> nextstate(main 71 -e:1) v
# 3  <0> pushmark s
# 4  <$> const[PV "junk"] s
# 5  <@> print vK
# 6  <@> leave[1 ref] vKP/REFC
EOT_EOT
# 1  <0> enter 
# 2  <;> nextstate(main 71 -e:1) v
# 3  <0> pushmark s
# 4  <$> const(PV "junk") s
# 5  <@> print vK
# 6  <@> leave[1 ref] vKP/REFC
EONT_EONT

__END__

#######################################################################

checkOptree ( name	=> '-exec sub a { print (shift) ? "foo" : "bar" }',
	      code	=> sub { print (shift) ? "foo" : "bar" },
	      bcopts	=> '-exec',
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
   insert threaded reference here
EOT_EOT
   insert non-threaded reference here
EONT_EONT

