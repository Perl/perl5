#!./perl

# This tests the B:: module(s) with CHECK, BEGIN, END and INIT blocks. The
# text excerpts below marked with "# " in front are the expected output. They
# are there twice, EOT for threading, and EONT for a non-threading Perl. The
# output is matched losely. If the match fails even though the "got" and
# "expected" output look exactly the same, then watch for trailing, invisible
# spaces.
#
# Note that if this test is mysteriously failing smokes and is hard to
# reproduce, try running with LC_ALL=en_US.UTF-8 PERL_UNICODE="".
# This causes nextstate ops to have a bunch of extra hint info, which
# needs adding to the expected output (for both thraded and non-threaded
# versions)

BEGIN {
    unshift @INC, 't';
    require Config;
    if (($Config::Config{'extensions'} !~ /\bB\b/) ){
        print "1..0 # Skip -- Perl configured without B module\n";
        exit 0;
    }
}

# import checkOptree(), and %gOpts (containing test state)
use OptreeCheck;	# ALSO DOES @ARGV HANDLING !!!!!!

plan tests => 13;

require_ok("B::Concise");

my $src = q[our ($beg, $chk, $init, $end, $uc) = qq{'foo'}; BEGIN { $beg++ } CHECK { $chk++ } INIT { $init++ } END { $end++ } UNITCHECK {$uc++}];

checkOptree ( name	=> 'BEGIN',
	      bcopts	=> 'BEGIN',
	      prog	=> $src,
	      strip_open_hints => 1,
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
# BEGIN 1:
# 4  <1> leavesub[1 ref] K/REFC,1 ->(end)
# -     <@> lineseq KP ->4
# 1        <;> nextstate(main 3 -e:1) v:{ ->2
# 3        <1> postinc[t3] sK/1 ->4
# -           <1> ex-rv2sv sKRM/1 ->3
# 2              <#> gvsv[*beg] s ->3
EOT_EOT
# BEGIN 1:
# 4  <1> leavesub[1 ref] K/REFC,1 ->(end)
# -     <@> lineseq KP ->4
# 1        <;> nextstate(main 3 -e:1) v:{ ->2
# 3        <1> postinc[t2] sK/1 ->4
# -           <1> ex-rv2sv sKRM/1 ->3
# 2              <$> gvsv(*beg) s ->3
EONT_EONT

checkOptree ( name	=> 'END',
	      bcopts	=> 'END',
	      prog	=> $src,
	      strip_open_hints => 1,
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
# END 1:
# 4  <1> leavesub[1 ref] K/REFC,1 ->(end)
# -     <@> lineseq KP ->4
# 1        <;> nextstate(main 5 -e:6) v:>,<,%,{ ->2
# 3        <1> postinc[t3] sK/1 ->4
# -           <1> ex-rv2sv sKRM/1 ->3
# 2              <#> gvsv[*end] s ->3
EOT_EOT
# END 1:
# 4  <1> leavesub[1 ref] K/REFC,1 ->(end)
# -     <@> lineseq KP ->4
# 1        <;> nextstate(main 5 -e:6) v:>,<,%,{ ->2
# 3        <1> postinc[t2] sK/1 ->4
# -           <1> ex-rv2sv sKRM/1 ->3
# 2              <$> gvsv(*end) s ->3
EONT_EONT

checkOptree ( name	=> 'CHECK',
	      bcopts	=> 'CHECK',
	      prog	=> $src,
	      strip_open_hints => 1,
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
# CHECK 1:
# 4  <1> leavesub[1 ref] K/REFC,1 ->(end)
# -     <@> lineseq KP ->4
# 1        <;> nextstate(main 3 -e:4) v:>,<,%,{ ->2
# 3        <1> postinc[t3] sK/1 ->4
# -           <1> ex-rv2sv sKRM/1 ->3
# 2              <#> gvsv[*chk] s ->3
EOT_EOT
# CHECK 1:
# 4  <1> leavesub[1 ref] K/REFC,1 ->(end)
# -     <@> lineseq KP ->4
# 1        <;> nextstate(main 3 -e:4) v:>,<,%,{ ->2
# 3        <1> postinc[t2] sK/1 ->4
# -           <1> ex-rv2sv sKRM/1 ->3
# 2              <$> gvsv(*chk) s ->3
EONT_EONT

checkOptree ( name	=> 'UNITCHECK',
	      bcopts=> 'UNITCHECK',
	      prog	=> $src,
	      strip_open_hints => 1,
	      expect=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
# UNITCHECK 1:
# 4  <1> leavesub[1 ref] K/REFC,1 ->(end)
# -     <@> lineseq KP ->4
# 1        <;> nextstate(main 3 -e:4) v:>,<,%,{ ->2
# 3        <1> postinc[t3] sK/1 ->4
# -           <1> ex-rv2sv sKRM/1 ->3
# 2              <#> gvsv[*uc] s ->3
EOT_EOT
# UNITCHECK 1:
# 4  <1> leavesub[1 ref] K/REFC,1 ->(end)
# -     <@> lineseq KP ->4
# 1        <;> nextstate(main 3 -e:4) v:>,<,%,{ ->2
# 3        <1> postinc[t2] sK/1 ->4
# -           <1> ex-rv2sv sKRM/1 ->3
# 2              <$> gvsv(*uc) s ->3
EONT_EONT

checkOptree ( name	=> 'INIT',
	      bcopts	=> 'INIT',
	      prog	=> $src,
	      strip_open_hints => 1,
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
# INIT 1:
# 4  <1> leavesub[1 ref] K/REFC,1 ->(end)
# -     <@> lineseq KP ->4
# 1        <;> nextstate(main 4 -e:5) v:>,<,%,{ ->2
# 3        <1> postinc[t3] sK/1 ->4
# -           <1> ex-rv2sv sKRM/1 ->3
# 2              <#> gvsv[*init] s ->3
EOT_EOT
# INIT 1:
# 4  <1> leavesub[1 ref] K/REFC,1 ->(end)
# -     <@> lineseq KP ->4
# 1        <;> nextstate(main 4 -e:5) v:>,<,%,{ ->2
# 3        <1> postinc[t2] sK/1 ->4
# -           <1> ex-rv2sv sKRM/1 ->3
# 2              <$> gvsv(*init) s ->3
EONT_EONT

checkOptree ( name	=> 'all of BEGIN END INIT CHECK UNITCHECK -exec',
	      bcopts	=> [qw/ BEGIN END INIT CHECK UNITCHECK -exec /],
	      prog	=> $src,
	      strip_open_hints => 1,
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
# BEGIN 1:
# 1  <;> nextstate(main 3 -e:1) v:{
# 2  <#> gvsv[*beg] s
# 3  <1> postinc[t3] sK/1
# 4  <1> leavesub[1 ref] K/REFC,1
# END 1:
# 5  <;> nextstate(main 9 -e:1) v:{
# 6  <#> gvsv[*end] s
# 7  <1> postinc[t3] sK/1
# 8  <1> leavesub[1 ref] K/REFC,1
# INIT 1:
# 9  <;> nextstate(main 7 -e:1) v:{
# a  <#> gvsv[*init] s
# b  <1> postinc[t3] sK/1
# c  <1> leavesub[1 ref] K/REFC,1
# CHECK 1:
# d  <;> nextstate(main 5 -e:1) v:{
# e  <#> gvsv[*chk] s
# f  <1> postinc[t3] sK/1
# g  <1> leavesub[1 ref] K/REFC,1
# UNITCHECK 1:
# h  <;> nextstate(main 11 -e:1) v:{
# i  <#> gvsv[*uc] s
# j  <1> postinc[t3] sK/1
# k  <1> leavesub[1 ref] K/REFC,1
EOT_EOT
BEGIN 1:
# 1  <;> nextstate(main 3 -e:1) v:{
# 2  <$> gvsv(*beg) s
# 3  <1> postinc[t2] sK/1
# 4  <1> leavesub[1 ref] K/REFC,1
# END 1:
# 5  <;> nextstate(main 9 -e:1) v:{
# 6  <$> gvsv(*end) s
# 7  <1> postinc[t2] sK/1
# 8  <1> leavesub[1 ref] K/REFC,1
# INIT 1:
# 9  <;> nextstate(main 7 -e:1) v:{
# a  <$> gvsv(*init) s
# b  <1> postinc[t2] sK/1
# c  <1> leavesub[1 ref] K/REFC,1
# CHECK 1:
# d  <;> nextstate(main 5 -e:1) v:{
# e  <$> gvsv(*chk) s
# f  <1> postinc[t2] sK/1
# g  <1> leavesub[1 ref] K/REFC,1
# UNITCHECK 1:
# h  <;> nextstate(main 11 -e:1) v:{
# i  <$> gvsv(*uc) s
# j  <1> postinc[t2] sK/1
# k  <1> leavesub[1 ref] K/REFC,1
EONT_EONT
