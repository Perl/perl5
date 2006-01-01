#!perl

BEGIN {
    if ($ENV{PERL_CORE}) {
	chdir('t') if -d 't';
	@INC = ('.', '../lib', '../ext/B/t');
    } else {
	unshift @INC, 't';
	push @INC, "../../t";
    }
    require Config;
    if (($Config::Config{'extensions'} !~ /\bB\b/) ){
        print "1..0 # Skip -- Perl configured without B module\n";
        exit 0;
    }
    # require 'test.pl'; # now done by OptreeCheck
}

use OptreeCheck;	# ALSO DOES @ARGV HANDLING !!!!!!
use Config;

my $tests = 18;
plan tests => $tests;
SKIP: {
skip "no perlio in this build", $tests unless $Config::Config{useperlio};

#################################

use constant {		# see also t/op/gv.t line 282
    myint => 42,
    mystr => 'hithere',
    myfl => 3.14159,
    myrex => qr/foo/,
    myglob => \*STDIN,
    myaref => [ 1,2,3 ],
    myhref => { a => 1 },
};

use constant WEEKDAYS
    => qw ( Sunday Monday Tuesday Wednesday Thursday Friday Saturday );


sub pi () { 3.14159 };
$::{napier} = \2.71828;	# counter-example (doesn't get optimized).
eval "sub napier ();";


# should be able to undefine constant::import here ???
INIT { 
    # eval 'sub constant::import () {}';
    # undef *constant::import::{CODE};
};

#################################
pass("CONSTANT SUBS RETURNING SCALARS");

checkOptree ( name	=> 'myint() as coderef',
	      code	=> \&myint,
	      noanchors => 1,
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
 is a constant sub, optimized to a IV
EOT_EOT
 is a constant sub, optimized to a IV
EONT_EONT


checkOptree ( name	=> 'mystr() as coderef',
	      code	=> \&mystr,
	      noanchors => 1,
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
 is a constant sub, optimized to a PV
EOT_EOT
 is a constant sub, optimized to a PV
EONT_EONT


checkOptree ( name	=> 'myfl() as coderef',
	      code	=> \&myfl,
	      noanchors => 1,
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
 is a constant sub, optimized to a NV
EOT_EOT
 is a constant sub, optimized to a NV
EONT_EONT


checkOptree ( name	=> 'myrex() as coderef',
	      code	=> \&myrex,
	      todo	=> '- currently renders as XS code',
	      noanchors => 1,
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
 is XS code
EOT_EOT
 is XS code
EONT_EONT


checkOptree ( name	=> 'myglob() as coderef',
	      code	=> \&myglob,
	      todo	=> '- currently renders as XS code',
	      noanchors => 1,
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
 is XS code
EOT_EOT
 is XS code
EONT_EONT


checkOptree ( name	=> 'myaref() as coderef',
	      code	=> \&myaref,
	      todo	=> '- currently renders as XS code',
	      noanchors => 1,
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
 is XS code
EOT_EOT
 is XS code
EONT_EONT


checkOptree ( name	=> 'myhref() as coderef',
	      code	=> \&myhref,
	      todo	=> '- currently renders as XS code',
	      noanchors => 1,
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
 is XS code
EOT_EOT
 is XS code
EONT_EONT


##############

checkOptree ( name	=> 'call myint',
	      code	=> 'myint',
	      bc_opts	=> '-nobanner',
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
3  <1> leavesub[2 refs] K/REFC,1 ->(end)
-     <@> lineseq KP ->3
1        <;> dbstate(main 1163 OptreeCheck.pm:511]:1) v ->2
2        <$> const[IV 42] s ->3
EOT_EOT
3  <1> leavesub[2 refs] K/REFC,1 ->(end)
-     <@> lineseq KP ->3
1        <;> dbstate(main 1163 OptreeCheck.pm:511]:1) v ->2
2        <$> const(IV 42) s ->3
EONT_EONT


checkOptree ( name	=> 'call mystr',
	      code	=> 'mystr',
	      bc_opts	=> '-nobanner',
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
3  <1> leavesub[2 refs] K/REFC,1 ->(end)
-     <@> lineseq KP ->3
1        <;> dbstate(main 1163 OptreeCheck.pm:511]:1) v ->2
2        <$> const[PV "hithere"] s ->3
EOT_EOT
3  <1> leavesub[2 refs] K/REFC,1 ->(end)
-     <@> lineseq KP ->3
1        <;> dbstate(main 1163 OptreeCheck.pm:511]:1) v ->2
2        <$> const(PV "hithere") s ->3
EONT_EONT


checkOptree ( name	=> 'call myfl',
	      code	=> 'myfl',
	      bc_opts	=> '-nobanner',
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
3  <1> leavesub[2 refs] K/REFC,1 ->(end)
-     <@> lineseq KP ->3
1        <;> dbstate(main 1163 OptreeCheck.pm:511]:1) v ->2
2        <$> const[NV 3.14159] s ->3
EOT_EOT
3  <1> leavesub[2 refs] K/REFC,1 ->(end)
-     <@> lineseq KP ->3
1        <;> dbstate(main 1163 OptreeCheck.pm:511]:1) v ->2
2        <$> const(NV 3.14159) s ->3
EONT_EONT


checkOptree ( name	=> 'call myrex',
	      code	=> 'myrex',
	      todo	=> '- RV value is bare backslash',
	      noanchors => 1,
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
# 3  <1> leavesub[1 ref] K/REFC,1 ->(end)
# -     <@> lineseq KP ->3
# 1        <;> nextstate(main 753 (eval 27):1) v ->2
# 2        <$> const[RV \\] s ->3
EOT_EOT
# 3  <1> leavesub[1 ref] K/REFC,1 ->(end)
# -     <@> lineseq KP ->3
# 1        <;> nextstate(main 753 (eval 27):1) v ->2
# 2        <$> const(RV \\) s ->3
EONT_EONT


checkOptree ( name	=> 'call myglob',
	      code	=> 'myglob',
	      todo	=> '- RV value is bare backslash',
	      noanchors => 1,
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
# 3  <1> leavesub[1 ref] K/REFC,1 ->(end)
# -     <@> lineseq KP ->3
# 1        <;> nextstate(main 753 (eval 27):1) v ->2
# 2        <$> const[RV \\] s ->3
EOT_EOT
# 3  <1> leavesub[1 ref] K/REFC,1 ->(end)
# -     <@> lineseq KP ->3
# 1        <;> nextstate(main 753 (eval 27):1) v ->2
# 2        <$> const(RV \\) s ->3
EONT_EONT


checkOptree ( name	=> 'call myaref',
	      code	=> 'myaref',
	      todo	=> '- RV value is bare backslash',
	      noanchors => 1,
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
# 3  <1> leavesub[1 ref] K/REFC,1 ->(end)
# -     <@> lineseq KP ->3
# 1        <;> nextstate(main 758 (eval 29):1) v ->2
# 2        <$> const[RV \\] s ->3
EOT_EOT
# 3  <1> leavesub[1 ref] K/REFC,1 ->(end)
# -     <@> lineseq KP ->3
# 1        <;> nextstate(main 758 (eval 29):1) v ->2
# 2        <$> const(RV \\) s ->3
EONT_EONT


checkOptree ( name	=> 'call myhref',
	      code	=> 'myhref',
	      noanchors => 1,
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
# 3  <1> leavesub[1 ref] K/REFC,1 ->(end)
# -     <@> lineseq KP ->3
# 1        <;> nextstate(main 763 (eval 31):1) v ->2
# 2        <$> const[RV \\HASH] s ->3
EOT_EOT
# 3  <1> leavesub[1 ref] K/REFC,1 ->(end)
# -     <@> lineseq KP ->3
# 1        <;> nextstate(main 763 (eval 31):1) v ->2
# 2        <$> const(RV \\HASH) s ->3
EONT_EONT


##################

# test constant sub defined w/o 'use constant'

checkOptree ( name	=> "pi(), defined w/o 'use constant'",
	      code	=> \&pi,
	      noanchors => 1,
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
 is a constant sub, optimized to a NV
EOT_EOT
 is a constant sub, optimized to a NV
EONT_EONT


checkOptree ( name	=> 'constant subs returning lists are not optimized',
	      code	=> \&WEEKDAYS,
	      noanchors => 1,
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
# 3  <1> leavesub[2 refs] K/REFC,1 ->(end)
# -     <@> lineseq K ->3
# 1        <;> nextstate(constant 685 constant.pm:121) v ->2
# 2        <0> padav[@list:FAKE:m:102] ->3
EOT_EOT
# 3  <1> leavesub[2 refs] K/REFC,1 ->(end)
# -     <@> lineseq K ->3
# 1        <;> nextstate(constant 685 constant.pm:121) v ->2
# 2        <0> padav[@list:FAKE:m:76] ->3
EONT_EONT


sub printem {
    printf "myint %d mystr %s myfl %f pi %f\n"
	, myint, mystr, myfl, pi;
}

checkOptree ( name	=> 'call em all in a print statement',
	      code	=> \&printem,
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
# 9  <1> leavesub[1 ref] K/REFC,1 ->(end)
# -     <@> lineseq KP ->9
# 1        <;> nextstate(main 635 optree_constants.t:163) v ->2
# 8        <@> prtf sK ->9
# 2           <0> pushmark s ->3
# 3           <$> const[PV "myint %d mystr %s myfl %f pi %f\n"] s ->4
# 4           <$> const[IV 42] s ->5
# 5           <$> const[PV "hithere"] s ->6
# 6           <$> const[NV 3.14159] s ->7
# 7           <$> const[NV 3.14159] s ->8
EOT_EOT
# 9  <1> leavesub[1 ref] K/REFC,1 ->(end)
# -     <@> lineseq KP ->9
# 1        <;> nextstate(main 635 optree_constants.t:163) v ->2
# 8        <@> prtf sK ->9
# 2           <0> pushmark s ->3
# 3           <$> const(PV "myint %d mystr %s myfl %f pi %f\n") s ->4
# 4           <$> const(IV 42) s ->5
# 5           <$> const(PV "hithere") s ->6
# 6           <$> const(NV 3.14159) s ->7
# 7           <$> const(NV 3.14159) s ->8
EONT_EONT


} #skip

__END__

=head NB

Optimized constant subs are stored as bare scalars in the stash
(package hash), which formerly held only GVs (typeglobs).

But you cant create them manually - you cant assign a scalar to a
stash element, and expect it to work like a constant-sub, even if you
provide a prototype.

This is a feature; alternative is too much action-at-a-distance.  The
following test demonstrates - napier is not seen as a function at all,
much less an optimized one.

=cut

checkOptree ( name	=> 'not evertnapier',
	      code	=> \&napier,
	      noanchors => 1,
	      expect	=> <<'EOT_EOT', expect_nt => <<'EONT_EONT');
 has no START
EOT_EOT
 has no START
EONT_EONT


