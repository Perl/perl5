# non-package OptreeCheck.pm
# pm allows 'use OptreeCheck', which also imports
# no package decl means all functions defined into main
# otherwise, it's like "require './test.pl'"

=head1 NAME

OptreeCheck - check optrees

=head1 SYNOPSIS

OptreeCheck supports regression testing of perl's parser, optimizer,
bytecode generator, via a single function: checkOptree(%args).'

 checkOptree(name   => "your title here", # optional, (synth from others)
	     bcopts => '-exec',	# $opt or \@opts, passed to BC::compile
	     code   => sub {my $a},	# coderef, or source (wrapped and evald)
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

Calls getRendering(), which runs code or prog through B::Concise, and
captures its rendering.

Calls mkCheckRex() to produce a regex which will match the expected
rendering, and fail when it doesn't match.

Also calls like($rendering,/$regex/,$name), and thereby plugs into the
test.pl framework.

=head1 checkOptree(%Args) API

Accepts %Args, with following requirements and actions:

expect and expect_nt are both: required, not empty, not whitespace.
It's a fatal error otherwise, because false positives are BAD.

Either code or prog must be present.  prog is some source code, and is
passed through via runperl, to B::Concise like this: (bcopts are fixed
up for cmdline)

    './perl -w -MO=Concise,$bcopts_massaged -e $src'

code is a subref, or $src, like above.  If it's not a subref, it's
treated like source, but is wrapped as a subroutine, and passed to
B::Concise::compile().

    $subref = eval "sub{$src}";

I suppose I should also explain these more, but they seem obvious.

    # prog   => 'sort @a',	# run in subprocess, aka -MO=Concise
    # noanchors => 1,		# no /^$/.  needed for 1-liners like above

    # skip => 1,		# skips test
    # todo => 'excuse',		# anticipated failures
    # fail => 1			# fails (by redirecting result)
    # debug => 1,		# turns on regex debug for match test !!
    # retry => 1		# retry with debug on test failure

=head1 Test Philosophy

2 platforms --> 2 reftexts: You want an accurate test, independent of
which platform you're on.  So, two refdata properties, 'expect' and
'expect_nt', carry renderings taken from threaded and non-threaded
builds.  This has several benefits:

 1. native reference data allows closer matching by regex.
 2. samples can be eyeballed to grok t-nt differences.
 3. data can help to validate mkCheckRex() operation.
 4. can develop regexes which accomodate t-nt differences.
 5. can test with both native and cross+converted regexes.

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
tested.'

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
     noanchors	=> 'dont anchor match rex',
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
	label(\%in);
	skip($in{name}, 1) if $in{skip};
	return runSelftest(\%in) if $gOpts{selftest};

	my $rendering = getRendering(\%in);	# get the actual output
	fail("FORCED: $in{name}:\n$rendering") if $gOpts{fail}; # silly ?

	# Test rendering against ..
      TODO:
	foreach $want (@{$modes{$gOpts{testmode}}}) {
	    local $TODO = $in{todo} if $in{todo};

	    my ($rex,$txt,$rexstr) = mkCheckRex(\%in,$want);
	    my $cross = $msgs{"$want-$thrstat"};

	    # bad is anticipated failure on cross testing ONLY
	    my $bad = (0 or ( $cross && $in{crossfail})
			 or (!$cross && $in{fail})
			 or 0); # no undefs! pedant

	    # couldn't bear to pass \%in to likeyn
	    $res = mylike ( # custom test mode stuff
		[ !$bad,
		  $in{retry} || $gOpts{retry},
		  $in{debug} || $gOpts{retrydbg},
		  $rexstr,
		],
		# remaining is std API
		$rendering, qr/$rex/ms, "$cross $in{name} $in{label}")
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
    return if $in->{name};

    my $buf = (ref $in->{bcopts}) 
	? join(',', @{$in->{bcopts}}) : $in->{bcopts};

    foreach (qw( note prog code )) {
	$buf .= " $_: $in->{$_}" if $in->{$_} and not ref $in->{$_};
    }
    return $in->{label} = $buf;
}

sub testCombo {
    # generate a set of test-cases from the options
    my $in = @_;
    my @cases;
    foreach $want (@{$modes{$gOpts{testmode}}}) {
	push @cases, [ %in ]
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
			      $in->{debug} || $gOpts{retrydbg},
			      #label($in)
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
    my ($yes,$retry,$debug,$postmortem) = @$control; # or dies
    my ($got, $expected, $name, @mess) = @_; # pass thru mostly

    die "unintended usage, expecting Regex". Dumper \@_
	unless ref $_[1] eq 'Regexp';

    #ok($got=~/$expected/, "wow");

    # same as A ^ B, but B has side effects
    my $ok = ( (!$yes   and unlike($got, $expected, $name, @mess))
	       or ($yes and   like($got, $expected, $name, @mess)));

    if (not $ok and $postmortem) {
	# split rexstr into units that should eat leading lines.
	my @rexs = map qr/^$_/, split (/\n/,$postmortem);
	foreach my $rex (@rexs) {
	    #$got =~ s/($rex)/ate: $1/msg;	# noisy
	    $got =~ s/($rex)\n//msg;		# remove matches
	}
	print "sequentially deconstructed, these are unmatched:\n$got\n";
    }

    if (not $ok and $retry) {
	# redo, perhaps with use re debug - NOT ROBUST
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

    # convert all (args) and [args] to temp forms wo bracing
    $str =~ s/\[(.*?)\]/__CAPSQR$1__/msg;
    $str =~ s/\((.*?)\)/__CAPRND$1__/msg;
    $str =~ s/\((.*?)\)/__CAPRND$1__/msg; # nested () in nextstate
    
    # escape bracing, etc.. manual \Q (doesnt escape '+')
    $str =~ s/([\[\]()*.\$\@\#\|{}])/\\$1/msg;

    # now replace temp forms with original, preserving reference bracing 
    $str =~ s/__CAPSQR(.*?)__\b/\\[$1\\]/msg; # \b is important
    $str =~ s/__CAPRND(.*?)__\b/\\($1\\)/msg;
    $str =~ s/__CAPRND(.*?)__\b/\\($1\\)/msg; # nested () in nextstate
    
    # no 'invisible' failures in debugger
    $str =~ s/(?:next|db)state(\\\(.*?\\\))/(?:next|db)state(.*?)/msg;
    
    # don't care about:
    $str =~ s/:-?\d+,-?\d+/:-?\\d+,-?\\d+/msg;		# FAKE line numbers
    $str =~ s/match\\\(.*?\\\)/match\(.*?\)/msg;	# match args
    $str =~ s/(0x[0-9A-Fa-f]+)/0x[0-9A-Fa-f]+/msg;	# hexnum values
    $str =~ s/".*?"/".*?"/msg;				# quoted strings

    croak "no reftext found for $want: $in->{name}"
	unless $str =~ /\w+/; # fail unless a real test

    # $str = '.*'	if 1;	# sanity test
    # $str .= 'FAIL'	if 1;	# sanity test

    # allow -eval, banner at beginning of anchored matches
    $str = "(-e .*?)?(B::Concise::compile.*?)?\n" . $str
	unless $in->{noanchors};
    
    eval "use re 'debug'" if $debug;
    my $qr = ($in->{noanchors})	? qr/$str/ms : qr/^$str$/ms ;
    no re 'debug';

    return ($qr, $reftxt, $str) if wantarray;
    return $qr;
}


sub printhelp {
    # crufty - may be still useful
    my ($in, $rendering, $rex) = @_;
    print "<$rendering>\nVS\n<$rex>\n" if $gOpts{vbasic};

    # save this output to afile, edit out 'ok's and 1..N
    # then perl -d afile, and add re 'debug' to suit.
    print("\$str = q%$rendering%;\n".
	  "\$rex = qr%$rex%;\n\n".
	  #"print \"\$str =~ m%\$rex%ms \";\n".
	  "\$str =~ m{\$rex}ms or print \"doh\\n\";\n\n")
	if $in{rextract} or $gOpts{rextract};
}


#########################
# support for test writing

sub preamble {
    my $testct = shift || 1;
    return <<EO_HEADER;
#!perl

BEGIN {
    chdir q(t);
    \@INC = qw(../lib ../ext/B/t);
    require q(./test.pl);
}
use OptreeCheck;
plan tests => $testct;

EO_HEADER

}

sub OptreeCheck::wrap {
    my $code = shift;
    $code =~ s/(?:(\#.*?)\n)//gsm;
    $code =~ s/\s+/ /mgs;	       
    chomp $code;
    return unless $code =~ /\S/;
    my $comment = $1;
    
    my $testcode = qq{
	
checkOptree(note   => q{$comment},
	    bcopts => q{-exec},
	    code   => q{$code},
	    expect => <<EOT_EOT, expect_nt => <<EONT_EONT);
ThreadedRef
EOT_EOT
NonThreadRef
EONT_EONT
    
};
    return $testcode;
}

sub OptreeCheck::gentest {
    my ($code,$opts) = @_;
    my $rendering = getRendering({code => $code});
    my $testcode = OptreeCheck::wrap($code);
    return unless $testcode;

    # run the prog, capture 'reference' concise output
    my $preamble = preamble(1);
    my $got = runperl( prog => "$preamble $testcode", stderr => 1,
		       #switches => ["-I../ext/B/t", "-MOptreeCheck"], 
		       );  #verbose => 1);
    
    # extract the 'reftext' ie the got 'block'
    if ($got =~ m/got \'.*?\n(.*)\n\# \'\n\# expected/s) {
	my $reftext = $1;
	#and plug it into the test-src
	if ($threaded) {
	    $testcode =~ s/ThreadedRef/$reftext/;
	} else {
	    $testcode =~ s/NonThreadRef/$reftext/;
	}
	my $b4 = q{expect => <<EOT_EOT, expect_nt => <<EONT_EONT};
	my $af = q{expect => <<'EOT_EOT', expect_nt => <<'EONT_EONT'};
	$testcode =~ s/$b4/$af/;
	
	my $got;
	if ($internal_retest) {
	    $got = runperl( prog => "$preamble $testcode", stderr => 1,
			    #switches => ["-I../ext/B/t", "-MOptreeCheck"], 
			    verbose => 1);
	    print "got: $got\n";
	}
	return $testcode;
    }
    return '';
}


sub OptreeCheck::processExamples {
    my @files = @_;
    # gets array of paragraphs, which should be tests.

    foreach my $file (@files) {
	open (my $fh, $file) or die "cant open $file: $!\n";
	$/ = "";
	my @chunks = <$fh>;
	print preamble (scalar @chunks);
	foreach $t (@chunks) {
	    print "\n\n=for gentest\n\n# chunk: $t=cut\n\n";
	    print OptreeCheck::gentest ($t);
	}
    }
}

# OK - now for the final insult to your good taste...  

if ($0 =~ /OptreeCheck\.pm/) {

    #use lib 't';
    require './t/test.pl';

    # invoked as program.  Work like former gentest.pl,
    # ie read files given as cmdline args,
    # convert them to usable test files.

    require Getopt::Std;
    Getopt::Std::getopts('') or 
	die qq{ $0 sample-files*    # no options

	  expecting filenames as args.  Each should have paragraphs,
	  these are converted to checkOptree() tests, and printed to
	  stdout.  Redirect to file then edit for test. \n};

  OptreeCheck::processExamples(@ARGV);
}

1;

__END__

=head1 mkCheckRex

mkCheckRex receives the full testcase object, and constructs a regex.
1st, it selects a reftxt from either the expect or expect_nt items.

Once selected, reftext is massaged & converted into a Regex that
accepts 'good' concise renderings, with appropriate input variations,
but is otherwise as strict as possible.  For example, it should *not*
match when opcode flags change, or when optimizations convert an op to
an ex-op.

=head2 match criteria

Opcode arguments (text within braces) are disregarded for matching
purposes.  This loses some info in 'add[t5]', but greatly simplifys
matching 'nextstate(main 22 (eval 10):1)'.  Besides, we are testing
for regressions, not for complete accuracy.

The regex is anchored by default, but can be suppressed with
'noanchors', allowing 1-liner tests to succeed if opcode is found.

=head1 TEST DEVELOPMENT SUPPORT

This optree regression testing framework needs tests in order to find
bugs.  To that end, OptreeCheck has support for developing new tests,
according to the following model:

 1. write a set of sample code into a single file, one per
    paragraph.  f_map and f_sort in ext/B/t/ are examples.

 2. run OptreeCheck as a program on the file

   ./perl -Ilib ext/B/t/OptreeCheck.pm -w ext/B/t/f_map
   ./perl -Ilib ext/B/t/OptreeCheck.pm -w ext/B/t/f_sort

   gentest reads the sample code, runs each to generate a reference
   rendering, folds this rendering into an optreeCheck() statement,
   and prints it to stdout.

 3. run the output file as above, redirect to files, then rerun on
    same build (for sanity check), and on thread-opposite build.  With
    editor in 1 window, and cmd in other, it's fairly easy to cut-paste
    the gots into the expects, easier than running step 2 on both
    builds then trying to sdiff them together.

=head1 TODO

There's a considerable amount of cruft in the whole arg-handling setup.
I'll replace / strip it before 5.10

Treat %in as a test object, interwork better with Test::*

Refactor mkCheckRex() and selfTest() to isolate the selftest,
crosstest, etc selection mechanics.

improve retry, retrydbg, esp. it's control of eval "use re debug".
This seems to work part of the time, but isn't stable enough.

=cut
