# OptreeCheck.pm
# package-less .pm file allows 'use OptreeCheck';
# otherwise, it's like "require './test.pl'"

=head1 NAME

OptreeCheck - check optrees

=head1 SYNOPSIS

OptreeCheck supports regression testing of perl's parser, optimizer,
bytecode generator, via a single function: checkOptree(%args).

 checkOptree(name   => "your title here",
	     bcopts => '-exec',	# $opt or \@opts, passed to BC::compile
	     code   => sub {my $a},	# must be CODE ref
	     # prog   => 'sort @a',	# run in subprocess, aka -MO=Concise
	     # skip => 1,		# skips test
	     # todo => 'excuse',	# anticipated failures
	     # fail => 1		# fails (by redirecting result)
	     # debug => 1,		# turns on regex debug for match test !!
	     # retry => 1		# retry with debug on test failure
	     expect => <<'EOT_EOT', expect_nt => <<'EONT_EONT');
 # 1  <;> nextstate(main 45 optree.t:23) v
 # 2  <0> padsv[$a:45,46] M/LVINTRO
 # 3  <1> leavesub[1 ref] K/REFC,1
 EOT_EOT
 # 1  <;> nextstate(main 45 optree.t:23) v
 # 2  <0> padsv[$a:45,46] M/LVINTRO
 # 3  <1> leavesub[1 ref] K/REFC,1
 EONT_EONT

=head1 checkOptree(%in) Overview

Runs code or prog through B::Concise, and captures its rendering.

Calls mkCheckRex() to produce a regex which will match the expected
rendering, and fail when it doesn't match.

Also calls like($out,/$regex/,$name), and thereby plugs into the test.pl
framework.

=head1 checkOptree(%Args) API

Accepts %Args, with following requirements and actions:

expect and expect_nt required, not empty, not whitespace.  Its a fatal
error, because false positives are BAD.

Either code or prog must be present.

prog is some source code, and is passed through via runperl, to B::Concise
like this: (bcopts are fixed up for cmdline)

    './perl -w -MO=Concise,$bcopts_massaged -e $src'

code is a subref, or $src, like above.  If it's not a subref, it's
treated like source, and wrapped as a subroutine, and passed to
B::Concise::compile():

    $subref = eval "sub{$src}";

I suppose I should also explain these more, but..

    # prog   => 'sort @a',	# run in subprocess, aka -MO=Concise
    # skip => 1,		# skips test
    # todo => 'excuse',	# anticipated failures
    # fail => 1		# fails (by redirecting result)
    # debug => 1,		# turns on regex debug for match test !!
    # retry => 1		# retry with debug on test failure

=head1 Usage Philosophy

2 platforms --> 2 reftexts: You want an accurate test, independent of
which platform youre on.  This is obvious in retrospect, but ..

I started this with 1 reftext, and tried to use it to construct regexs
for both platforms.  This is extra complexity, trying to build a
single regex for both cases makes the regex more complicated, and
harder to get 'right'.

Having 2 references also allows various 'tests', really explorations
currently.  At the very least, having 2 samples side by side allows
inspection and aids understanding of optrees.

Cross-testing (expect_nt on threaded, expect on non-threaded) exposes
differences in B::Concise output, so mkCheckRex has code to do some
cross-test manipulations.  This area needs more work.

=head1 Test Modes

One consequence of a single-function API is difficulty controlling
test-mode.  Ive chosen for now to use a package hash, %gOpts, to store
test-state.  These properties alter checkOptree() function, either
short-circuiting to selftest, or running a loop that runs the testcase
2^N times, varying conditions each time.  (current N is 2 only).

So Test-mode is controlled with cmdline args, also called options below.
Run with 'help' to see the test-state, and how to change it.

=head2  selftest

This argument invokes runSelftest(), which tests a regex against the
reference renderings that they're made from.  Failure of a regex match
its 'mold' is a strong indicator that mkCheckRex is buggy.

That said, selftest mode currently runs a cross-test too, they're not
completely orthogonal yet.  See below.

=head2 testmode=cross

Cross-testing is purposely creating a T-NT mismatch, looking at the
fallout, and tweaking the regex to deal with it.  Thus tests lead to
'provably' complete understanding of the differences.

The tweaking appears contrary to the 2-refs philosophy, but the tweaks
will be made in conversion-specific code, which (will) handles T->NT
and NT->T separately.  The tweaking is incomplete.

A reasonable 1st step is to add tags to indicate when TonNT or NTonT
is known to fail.  This needs an option to force failure, so the
test.pl reporting mechanics show results to aid the user.

=head2 testmode=native

This is normal mode.  Other valid values are: native, cross, both.

=head2 checkOptree Notes

Accepts test code, renders its optree using B::Concise, and matches that
rendering against a regex built from one of 2 reference-renderings %in data.

The regex is built by mkCheckRex(\%in), which scrubs %in data to
remove match-irrelevancies, such as (args) and [args].  For example,
it strips leading '# ', making it easy to cut-paste new tests into
your test-file, run it, and cut-paste actual results into place.  You
then retest and reedit until all 'errors' are gone.  (now make sure you
haven't 'enshrined' a bug).

name: The test name.  May be augmented by a label, which is built from
important params, and which helps keep names in sync with whats being
tested.

=cut

use Config;
use Carp;
use B::Concise qw(walk_output);
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

BEGIN {
    $SIG{__WARN__} = sub {
	my $err = shift;
	$err =~ m/Subroutine re::(un)?install redefined/ and return;
    };
}

# but wait - more skullduggery !
sub OptreeCheck::import {  &getCmdLine; }	# process @ARGV

# %gOpts params comprise a global test-state.  Initial values here are
# HELP strings, they MUST BE REPLACED by runtime values before use, as
# is done by getCmdLine(), via import

our %gOpts = 	# values are replaced at runtime !!
    (
     # scalar values are help string
     rextract	=> 'writes src-code todo same Optree matching',
     vbasic	=> 'prints $str and $rex',
     retry	=> 'retry failures after turning on re debug',
     retrydbg	=> 'retry failures after turning on re debug',
     selftest	=> 'self-tests mkCheckRex vs the reference rendering',
     selfdbg	=> 'redo failing selftests with re debug',
     xtest	=> 'extended thread/non-thread testing',
     fail	=> 'force all test to fail, print to stdout',
     dump	=> 'dump cmdline arg prcessing',
     rexpedant	=> 'try tighter regex, still buggy',
     help	=> 0,	# 1 ends in die

     # array values are one-of selections, with 1st value as default
     #   tbc: 1st value is help, 2nd is default
     testmode => [qw/ native cross both /],
    );


our $threaded = 1 if $Config::Config{usethreads};
our $platform = ($threaded) ? "threaded" : "plain";
our $thrstat = ($threaded)  ? "threaded" : "nonthreaded";

our ($MatchRetry,$MatchRetryDebug);	# let mylike be generic
# test.pl-ish hack
*MatchRetry = \$gOpts{retry};		# but alias it into %gOpts
*MatchRetryDebug = \$gOpts{retrydbg};	# but alias it into %gOpts

our %modes = (
	      both	=> [ 'expect', 'expect_nt'],
	      native	=> [ ($threaded) ? 'expect' : 'expect_nt'],
	      cross	=> [ !($threaded) ? 'expect' : 'expect_nt'],
	      expect	=> [ 'expect' ],
	      expect_nt	=> [ 'expect_nt' ],
	);

our %msgs # announce cross-testing.
    = (
       # cross-platform
       'expect_nt-threaded' => " (Non-threaded-ref on Threaded-build)",
       'expect-nonthreaded' => " (Threaded-ref on Non-threaded-build)",
       # native - nothing to say
       'expect_nt-nonthreaded'	=> '',
       'expect-threaded'	=> '',
       );

#######
sub getCmdLine {	# import assistant
    # offer help
    print(qq{\n$0 accepts args to update these state-vars:
	     turn on a flag by typing its name,
	     select a value from list by typing name=val.\n    },
	  Dumper \%gOpts)
	if grep /help/, @ARGV;

    # replace values for each key !! MUST MARK UP %gOpts
    foreach my $opt (keys %gOpts) {

	# scan ARGV for known params
	if (ref $gOpts{$opt} eq 'ARRAY') {

	    # $opt is a One-Of construct
	    # replace with valid selection from the list

	    # uhh this WORKS. but it's inscrutable
	    # grep s/$opt=(\w+)/grep {$_ eq $1} @ARGV and $gOpts{$opt}=$1/e, @ARGV;
	    my $tval;  # temp
	    if (grep s/$opt=(\w+)/$tval=$1/e, @ARGV) {
		# check val before accepting
		my @allowed = @{$gOpts{$opt}};
		if (grep { $_ eq $tval } @allowed) {
		    $gOpts{$opt} = $tval;
		}
		else {die "invalid value: '$tval' for $opt\n"}
	    }

	    # take 1st val as default
	    $gOpts{$opt} = ${$gOpts{$opt}}[0]
		if ref $gOpts{$opt} eq 'ARRAY';
        }
        else { # handle scalars

	    # if 'opt' is present, true
	    $gOpts{$opt} = (grep /$opt/, @ARGV) ? 1 : 0;

	    # override with 'foo' if 'opt=foo' appears
	    grep s/$opt=(.*)/$gOpts{$opt}=$1/e, @ARGV;
	}
    }
    print("$0 heres current state:\n", Dumper \%gOpts)
	if $gOpts{help} or $gOpts{dump};

    exit if $gOpts{help};
}

##################################
# API

sub checkOptree {
    my %in = @_;
    my ($in, $res) = (\%in,0);	 # set up privates.

    print "checkOptree args: ",Dumper \%in if $in{dump};
    SKIP: {
	skip($in{name}, 1) if $in{skip};
	return runSelftest(\%in) if $gOpts{selftest};

	my $rendering = getRendering(\%in);	# get the actual output
	fail("FORCED: $in{name}:\n$rendering") if $gOpts{fail}; # silly ?

	# Test rendering against ..
	foreach $want (@{$modes{$gOpts{testmode}}}) {

	    my $rex = mkCheckRex(\%in,$want);
	    my $cross = $msgs{"$want-$thrstat"};

	    # bad is anticipated failure on cross testing ONLY
	    my $bad = (0 or ( $cross && $in{crossfail})
			 or (!$cross && $in{fail})
			 or 0);

	    # couldn't bear to pass \%in to likeyn
	    $res = mylike ( # custom test mode stuff
		[ !$bad,
		$in{retry} || $gOpts{retry},
		$in{debug} || $gOpts{retrydbg}
		],
		# remaining is std API
		$rendering, qr/$rex/ms, "$cross $in{name}")
	    || 0;
	    printhelp(\%in, $rendering, $rex);
	}
    }
    $res;
}

#################
# helpers

sub label {
    # may help get/keep test output consistent
    my ($in) = @_;
    $in->{label} = join(',', map {"$_=>$in->{$_}"}
			qw( bcopts name prog code ));
}

sub testCombo {
    # generate a set of test-cases from the options
    my $in = @_;
    my @cases;
    foreach $want (@{$modes{$gOpts{testmode}}}) {

	push @cases, [ %in,
		      ];
    }
    return @cases;
}

sub runSelftest {
    # tests the test-cases offered (expect, expect_nt)
    # needs Unification with above.
    my ($in) = @_;
    my $ok;
    foreach $want (@{$modes{$gOpts{testmode}}}) {}

    for my $provenance (qw/ expect expect_nt /) {
	next unless $in->{$provenance};
	my ($rex,$gospel) = mkCheckRex($in, $provenance);
	return unless $gospel;

	my $cross = $msgs{"$provenance-$thrstat"};
	my $bad = (0 or ( $cross && $in->{crossfail})
		   or   (!$cross && $in->{fail})
		   or 0);
	    # couldn't bear to pass \%in to likeyn
	    $res = mylike ( [ !$bad,
			      $in->{retry} || $gOpts{retry},
			      $in->{debug} || $gOpts{retrydbg}
			      ],
			    $rendering, qr/$rex/ms, "$cross $in{name}")
		|| 0;
    }
    $ok;
}

# use re;
sub mylike {
    # note dependence on unlike()
    my ($control) = shift;
    my ($yes,$retry,$debug) = @$control; # or dies
    my ($got, $expected, $name, @mess) = @_; # pass thru mostly

    die "unintended usage, expecting Regex". Dumper \@_
	unless ref $_[1] eq 'Regexp';

    # same as A ^ B, but B has side effects
    my $ok = ( (!$yes   and unlike($got, $expected, $name, @mess))
	       or ($yes and   like($got, $expected, $name, @mess)));

    if (not $ok and $retry) {
	# redo, perhaps with use re debug
	eval "use re 'debug'" if $debug;
	$ok = (!$yes   and unlike($got, $expected, "(RETRY) $name", @mess)
	       or $yes and   like($got, $expected, "(RETRY) $name", @mess));

	no re 'debug';
    }
    return $ok;
}

sub getRendering {
    my ($in) = @_;
    die "getRendering: code or prog is required\n"
	unless $in->{code} or $in->{prog};

    my @opts = get_bcopts($in);
    my $rendering = ''; # suppress "Use of uninitialized value in open"

    if ($in->{prog}) {
	$rendering = runperl( switches => ['-w',join(',',"-MO=Concise",@opts)],
			      prog => $in->{prog}, stderr => 1,
			      ); #verbose => 1);
    } else {
	my $code = $in->{code};
	unless (ref $code eq 'CODE') {
	    # treat as source, and wrap
	    $code = eval "sub { $code }";
	    die "$@ evaling code 'sub { $in->{code} }'\n"
		unless ref $code eq 'CODE';
	}
	# set walk-output b4 compiling, which writes 'announce' line
	walk_output(\$rendering);
	if ($in->{fail}) {
	    fail("forced failure: stdout follows");
	    walk_output(\*STDOUT);
	}
	my $opwalker = B::Concise::compile(@opts, $code);
	die "bad BC::compile retval" unless ref $opwalker eq 'CODE';

      B::Concise::reset_sequence();
	$opwalker->();
    }
    return $rendering;
}

sub get_bcopts {
    # collect concise passthru-options if any
    my ($in) = shift;
    my @opts = ();
    if ($in->{bcopts}) {
	@opts = (ref $in->{bcopts} eq 'ARRAY')
	    ? @{$in->{bcopts}} : ($in->{bcopts});
    }
    return @opts;
}

# needless complexity due to 'too much info' from B::Concise v.60
my $announce = 'B::Concise::compile\(CODE\(0x[0-9a-f]+\)\)';;

sub mkCheckRex {
    # converts expected text into Regexp which should match against
    # unaltered version.  also adjusts threaded => non-threaded
    my ($in, $want) = @_;
    eval "no re 'debug'";

    my $str = $in->{expect} || $in->{expect_nt};	# standard bias
    $str = $in->{$want} if $want;			# stated pref

    die "no reftext found for $want: $in->{name}" unless $str;
    #fail("rex-str is empty, won't allow false positives") unless $str;

    $str =~ s/^\# //mg;		# ease cut-paste testcase authoring
    my $reftxt = $str;		# extra return val !!

    unless ($gOpts{rexpedant}) {
	# convert all (args) and [args] to temporary '____'
	$str =~ s/(\(.*?\))/____/msg;
	$str =~ s/(\[.*?\])/____/msg;

	# escape remaining metachars. manual \Q (doesnt escape '+')
	$str =~ s/([\[\]()*.\$\@\#])/\\$1/msg;
	#$str =~ s/([*.\$\@\#])/\\$1/msg;

	# now replace '____' with something that matches both.
	#  bracing style agnosticism is important here, it makes many
	#  threaded / non-threaded diffs irrelevant
	$str =~ s/____/(\\[.*?\\]|\\(.*?\\))/msg; # capture in case..

	# no mysterious failures in debugger
	$str =~ s/(?:next|db)state/(?:next|db)state/msg;
    }
    else {
	# precise/pedantic way - only wildcard nextate, leavesub

	# escape some literals
	$str =~ s/([*.\$\@\#])/\\$1/msg;

	# nextstate. replace args, and work under debugger
	$str =~ s/(?:next|db)state\(.*?\)/(?:next|db)state\\(.*?\\)/msg;

	# leavesub refcount changes, dont care
	$str =~ s/leavesub\[.*?\]/leavesub[.*?]/msg;

	# wildcard-ify all [contents]
	$str =~ s/\[.*?\]/[.*?]/msg;	# add capture ?

	# make [] literal now, keeping .* for contents
	$str =~ s/([\[\]])/\\$1/msg;
    }
    # threaded <--> non-threaded transforms ??

    if (not $Config::Config{usethreads}) {
	# written for T->NT transform
	# $str =~ s/<\\#>/<\\\$>/msg;	# GV on pad, a threads thing ?
	$str =~ s/PADOP/SVOP/msg;	# fix terse output diffs
    }
    croak "no reftext found for $want: $in->{name}"
	unless $str =~ /\w+/; # fail unless a real test

    # $str = '.*'	if 1;	# sanity test
    # $str .= 'FAIL'	if 1;	# sanity test

    # tabs fixup
    $str =~ s/\t/ +/msg; # not \s+

    eval "use re 'debug'" if $debug;
    my $qr = qr/$str/;
    no re 'debug';

    return ($qr, $reftxt) if wantarray;
    return $qr;
}

sub printhelp {
    my ($in, $rendering, $rex) = @_;
    print "<$rendering>\nVS\n<$reftext>\n" if $gOpts{vbasic};

    # save this output to afile, edit out 'ok's and 1..N
    # then perl -d afile, and add re 'debug' to suit.
    print("\$str = q{$rendering};\n".
	  "\$rex = qr{$reftext};\n".
	  "print \"\$str =~ m{\$rex}ms \";\n".
	  "\$str =~ m{\$rex}ms or print \"doh\\n\";\n\n")
	if $in{rextract} or $gOpts{rextract};
}

1;

__END__

=head1 mkCheckRex

mkCheckRex receives the full testcase object, and constructs a regex.
1st, it selects a reftxt from either the expect or expect_nt items.

Once selected, reftext massaged & convert into a Regex that accepts
'good' concise renderings, with appropriate input variations, but is
otherwize as strict as possible.  For example, it should *not* match
when opcode flags change, or when optimizations convert an op to an
ex-op.

=head2 match criteria

Opcode arguments (text within braces) are disregarded for matching
purposes.  This loses some info in 'add[t5]', but greatly simplifys
matching 'nextstate(main 22 (eval 10):1)'.  Besides, we are testing
for regressions, not for complete accuracy.

The regex is unanchored, allowing success on simple expectations, such
as one with a single 'print' opcode.

=head2 complicating factors

Note that %in may seem overly complicated, but it's needed to allow
mkCheckRex to better support selftest,

The emerging complexity is that mkCheckRex must choose which refdata
to use as a template for the regex being constructed.  This feels like
selection mechanics being duplicated.

=head1 FEATURES, BUGS, ENHANCEMENTS

Hey, they're the same thing now, modulo heisen-phase-shifting, and the
probe used to observe them.

=head1 Test Data

Test cases were recently doubled, by adding a 2nd ref-data property;
expect and expect_nt carry renderings taken from threaded and
non-threaded builds.  This addition has several benefits:

 1. native reference data allows closer matching by regex.
 2. samples can be eyeballed to grok t-nt differences.
 3. data can help to validate mkCheckRex() operation.
 4. can develop code to smooth t-nt differences.
 5. can test with both native and cross+converted rexes

Enhancements:

Tests should specify both 'expect' and 'expect_nt', making the
distinction now will allow a range of behaviors, in escalating
thoroughness.  This variable is called provenance, indicating where
the reftext came from.

build_only: tests which dont have the reference-sample of the
right provenance will be skipped. NO GOOD.

prefer_expect: This is implied standard, as all tests done thus far
started here.  One way t->nt conversions is done, based upon Config.

activetest: do cross-testing when test-case has both, ie also test
'expect_nt' references on threaded builds.  This is aggressive, and is
intended to seek out t<->nt differences.  if mkCheckRex knows
provenance and Config, it can do 2 way t<->nt conversions.

activemapping: This builds upon activetest by controlling whether
t<->nt conversions are done, and allows simpler verification that each
conversion step is indeed necessary.

pedantic: this fails if tests dont have both, whereas above doesn't care.

=cut
