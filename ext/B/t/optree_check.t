#!perl

BEGIN {
    chdir 't';
    @INC = ('../lib', '../ext/B/t');
    require './test.pl';
}

use OptreeCheck;

=head1 OptreeCheck selftest harness

This file is primarily to test services of OptreeCheck itself, ie
checkOptree().  %gOpts provides test-state info, it is 'exported' into
main::  

doing use OptreeCheck runs import(), which processes @ARGV to process
cmdline args in 'standard' way across all clients of OptreeCheck.

=cut

use Config;
plan tests => 5 + 19 + 14 * $gOpts{selftest};	# fudged

SKIP: {
    skip "no perlio in this build", 5 + 19 + 14 * $gOpts{selftest}
    unless $Config::Config{useperlio};


pass("REGEX TEST HARNESS SELFTEST");

checkOptree ( name	=> "bare minimum opcode search",
	      bcopts	=> '-exec',
	      code	=> sub {my $a},
	      expect	=> 'leavesub',
	      expect_nt	=> 'leavesub');

checkOptree ( name	=> "found print opcode",
	      bcopts	=> '-exec',
	      code	=> sub {print 1},
	      expect	=> 'print',
	      expect_nt	=> 'leavesub');

checkOptree ( name	=> 'test skip itself',
	      skip	=> 1,
	      bcopts	=> '-exec',
	      code	=> sub {print 1},
	      expect	=> 'dont-care, skipping',
	      expect_nt	=> 'this insures failure');

checkOptree ( name	=> 'test todo itself',
	      todo	=> "your excuse here ;-)",
	      bcopts	=> '-exec',
	      code	=> sub {print 1},
	      expect	=> 'print',
	      expect_nt	=> 'print');

checkOptree ( name	=> 'impossible match, remove skip to see failure',
	      todo	=> "see! it breaks!",
	      skip	=> 1, # but skip it 1st
	      code	=> sub {print 1},
	      expect	=> 'look out ! Boy Wonder',
	      expect_nt	=> 'holy near earth asteroid Batman !');

pass ("TEST FATAL ERRS");

if (1) {
    # test for fatal errors. Im unsettled on fail vs die.
    # calling fail isnt good enough by itself.
    eval {
	
	checkOptree ( name	=> 'empty code or prog',
		      todo	=> "your excuse here ;-)",
		      code	=> '',
		      prog	=> '',
		      );
    };
    like($@, 'code or prog is required', 'empty code or prog prevented');
    
    $@='';
    eval {
	checkOptree ( name	=> 'test against empty expectations',
		      bcopts	=> '-exec',
		      code	=> sub {print 1},
		      expect	=> '',
		      expect_nt	=> '');
    };
    like($@, 'no reftext found for', "empty expectations prevented");
    
    $@='';
    eval {
	checkOptree ( name	=> 'prevent whitespace only expectations',
		      bcopts	=> '-exec',
		      code	=> sub {my $a},
		      #skip	=> 1,
		      expect_nt	=> "\n",
		      expect	=> "\n");
    };
    like($@, 'no reftext found for', "just whitespace expectations prevented");
}

pass ("TEST -e \$srcCode");

checkOptree ( name	=> '-w errors seen',
	      prog	=> 'sort our @a',
	      expect	=> 'Useless use of sort in void context',
	      expect_nt	=> 'Useless use of sort in void context');

checkOptree ( name	=> "self strict, catch err",
	      prog	=> 'use strict; bogus',
	      expect	=> 'strict subs',
	      expect_nt	=> 'strict subs');

checkOptree ( name	=> "sort vK - flag specific search",
	      prog	=> 'sort our @a',
	      expect	=> '<@> sort vK ',
	      expect_nt	=> '<@> sort vK ');

checkOptree ( name	=> "'prog' => 'sort our \@a'",
	      prog	=> 'sort our @a',
	      expect	=> '<@> sort vK',
	      expect_nt	=> '<@> sort vK');

checkOptree ( name	=> "'code' => 'sort our \@a'",
	      code	=> 'sort our @a',
	      expect	=> '<@> sort K',
	      expect_nt	=> '<@> sort K');

pass ("REFTEXT FIXUP TESTS");

checkOptree ( name	=> 'fixup nextstate (in reftext)',
	      bcopts	=> '-exec',
	      code	=> sub {my $a},
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
#            goto -
# 1  <;> nextstate( NOTE THAT THIS CAN BE ANYTHING ) v
# 2  <0> padsv[$a:54,55] M/LVINTRO
# 3  <1> leavesub[1 ref] K/REFC,1
EOT_EOT
#            goto -
# 1  <;> nextstate(main 54 optree_concise.t:84) v
# 2  <0> padsv[$a:54,55] M/LVINTRO
# 3  <1> leavesub[1 ref] K/REFC,1
EONT_EONT

checkOptree ( name	=> 'fixup square-bracket args',
	      bcopts	=> '-exec',
	      todo	=> 'not done in rexpedant mode',
	      code	=> sub {my $a},
	      #skip	=> 1,
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
#            goto -
# 1  <;> nextstate(main 56 optree_concise.t:96) v
# 2  <0> padsv[$a:56,57] M/LVINTRO
# 3  <1> leavesub[1 ref] K/REFC,1
EOT_EOT
#            goto -
# 1  <;> nextstate(main 56 optree_concise.t:96) v
# 2  <0> padsv[$a:56,57] M/LVINTRO
# 3  <1> leavesub[1 ref] K/REFC,1
EONT_EONT

checkOptree ( name	=> 'unneeded manual rex-ify by test author',
	      # args in 1,2 are manually edited, unnecessarily
	      bcopts	=> '-exec',
	      code	=> sub {my $a},
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
# 1  <;> nextstate(.*?) v
# 2  <0> padsv[.*?] M/LVINTRO
# 3  <1> leavesub[1 ref] K/REFC,1
EOT_EOT
# 1  <;> nextstate(main 57 optree_concise.t:108) v
# 2  <0> padsv[$a:57,58] M/LVINTRO
# 3  <1> leavesub[1 ref] K/REFC,1
EONT_EONT

#################################
pass("CANONICAL B::Concise EXAMPLE");

checkOptree ( name	=> 'canonical example w -basic',
	      bcopts	=> '-basic',
	      code	=>  sub{$a=$b+42},
	      crossfail => 1,
	      debug	=> 1,
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
# 7  <1> leavesub[1 ref] K/REFC,1 ->(end)
# -     <@> lineseq KP ->7
# 1        <;> nextstate(main 380 optree_selftest.t:139) v ->2
# 6        <2> sassign sKS/2 ->7
# 4           <2> add[t3] sK/2 ->5
# -              <1> ex-rv2sv sK/1 ->3
# 2                 <#> gvsv[*b] s ->3
# 3              <$> const[IV 42] s ->4
# -           <1> ex-rv2sv sKRM*/1 ->6
# 5              <#> gvsv[*a] s ->6
EOT_EOT
# 7  <1> leavesub[1 ref] K/REFC,1 ->(end)
# -     <@> lineseq KP ->7
# 1        <;> nextstate(main 60 optree_concise.t:122) v ->2
# 6        <2> sassign sKS/2 ->7
# 4           <2> add[t1] sK/2 ->5
# -              <1> ex-rv2sv sK/1 ->3
# 2                 <$> gvsv(*b) s ->3
# 3              <$> const(IV 42) s ->4
# -           <1> ex-rv2sv sKRM*/1 ->6
# 5              <$> gvsv(*a) s ->6
EONT_EONT

checkOptree ( name	=> 'canonical example w -exec',
	      bcopts	=> '-exec',
	      code	=> sub{$a=$b+42},
	      crossfail => 1,
	      retry	=> 1,
	      debug	=> 1,
	      xtestfail	=> 1,
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
#            goto -
# 1  <;> nextstate(main 61 optree_concise.t:139) v
# 2  <#> gvsv[*b] s
# 3  <$> const[IV 42] s
# 4  <2> add[t3] sK/2
# 5  <#> gvsv[*a] s
# 6  <2> sassign sKS/2
# 7  <1> leavesub[1 ref] K/REFC,1
EOT_EOT
#            goto -
# 1  <;> nextstate(main 61 optree_concise.t:139) v
# 2  <$> gvsv(*b) s
# 3  <$> const(IV 42) s
# 4  <2> add[t1] sK/2
# 5  <$> gvsv(*a) s
# 6  <2> sassign sKS/2
# 7  <1> leavesub[1 ref] K/REFC,1
EONT_EONT

checkOptree ( name	=> 'tree reftext is messy cut-paste',
	      skip	=> 1);

} # skip

__END__

