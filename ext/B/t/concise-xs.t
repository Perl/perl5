#!./perl

# 2 purpose file: 1-test 2-demonstrate (via args, -v -a options)

=head1 synopsis

To verify that B::Concise properly reports whether functions are XS or
perl, we test against 2 (currently) core packages which have lots of
XS functions; B and Digest::MD5.  They're listed in %$testpkgs, along
with a list of functions that are (or are not) XS.  For brevity, you
can specify the shorter list; if they're non-xs routines, start list
with a '!'.  Data::Dumper is also tested, partly to prove the non-!
usage.

We demand-load each package, scan its stash for function names, and
mark them as XS/not-XS according to the list given for each package.
Then we test B::Concise's report on each.

If module-names are given as args, those packages are run through the
test harness; this is handy for collecting further items to test, and
may be useful otherwise (ie just to see).

If -a option is given, we use Module::CoreList to run all packages,
which gives some interesting results.

-v and -V trigger 2 levels of verbosity.

=cut

BEGIN {
    if ($ENV{PERL_CORE}) {
	chdir('t') if -d 't';
	@INC = ('.', '../lib');
    } else {
	unshift @INC, 't';
	push @INC, "../../t";
    }
    require Config;
    if (($Config::Config{'extensions'} !~ /\bB\b/) ){
        print "1..0 # Skip -- Perl configured without B module\n";
        exit 0;
    }
}

use Getopt::Std;
use Carp;
use Test::More tests => ( 1 * !!$Config::Config{useithreads}
			  + 2 * ($] > 5.009)
			  + 272);

require_ok("B::Concise");

my $testpkgs = {

    Digest::MD5 => [qw/ ! import /],

    B => [qw/ ! class clearsym compile_stats debug objsym parents
	      peekop savesym timing_info walkoptree_exec
	      walkoptree_slow walksymtable /],

    Data::Dumper => [qw/ bootstrap Dumpxs /],
};

############

B::Concise::compile('-nobanner');	# set a silent default
getopts('vaV', \my %opts) or
    die <<EODIE;

usage: PERL_CORE=1 ./perl ext/B/t/concise-xs.t [-av] [module-list]
    tests ability to discern XS funcs using Digest::MD5 package
    -v	: runs verbosely
    -V	: more verbosity
    -a	: runs all modules in CoreList
    <args> : additional modules are loaded and tested
    	(will report failures, since no XS funcs are known aprior)

EODIE
    ;

if (%opts) {
    require Data::Dumper;
    Data::Dumper->import('Dumper');
    $Data::Dumper::Sortkeys = 1;
}
my @argpkgs = @ARGV;

foreach $pkg (sort(keys %$testpkgs), @argpkgs) {
    test_pkg($pkg, $testpkgs->{$pkg});
}

corecheck() if $opts{a};

############

sub test_pkg {
    my ($pkg_name, $xslist) = @_;
    require_ok($pkg_name);

    unless (ref $xslist eq 'ARRAY') {
	warn "no XS/non-XS function list given, assuming empty XS list";
	$xslist = [''];
    }

    my $assumeXS = 0;	# assume list enumerates XS funcs, not perl ones
    $assumeXS = 1	if $xslist->[0] eq '!';

    # build %stash: keys are func-names, vals: 1 if XS, 0 if not
    my (%stash) = map
	( ($_ => $assumeXS)
	  => ( grep exists &{"$pkg_name\::$_"}	# grab CODE symbols
	       => grep !/__ANON__/		# but not anon subs
	       => keys %{$pkg_name.'::'}	# from symbol table
	       ));

    # now invert according to supplied list
    $stash{$_} = int ! $assumeXS foreach @$xslist;

    # and cleanup cruft (easier than preventing)
    delete @stash{'!',''};

    if (%opts) {
	diag("xslist: " => Dumper($xslist));
	diag("$pkg_name stash: " => Dumper(\%stash));
    }

    foreach $func_name (reverse sort keys %stash) {
	$DB::single = 1 if $func_name =~ /AUTOLOAD/;
	checkXS("${pkg_name}::$func_name", $stash{$func_name});
    }
}

sub checkXS {
    my ($func_name, $wantXS) = @_;

    my ($buf, $err) = render($func_name);
    if ($wantXS) {
	like($buf, qr/\Q$func_name is XS code/,
	     "XS code:\t $func_name");
    } else {
	unlike($buf, qr/\Q$func_name is XS code/,
	       "perl code:\t $func_name");
    }
    #returns like or unlike, whichever was called
}

sub render {
    my ($func_name) = @_;

    B::Concise::reset_sequence();
    B::Concise::walk_output(\my $buf);

    my $walker = B::Concise::compile($func_name);
    eval { $walker->() };
    diag("err: $@ $buf") if $@;
    diag("verbose: $buf") if $opts{V};

    return ($buf, $@);
}

sub corecheck {
    eval { require Module::CoreList };
    if ($@) {
	warn "Module::CoreList not available on $]\n";
	return;
    }
    my $mods = $Module::CoreList::version{'5.009001'};	# $]}; # undef ??
    print Dumper($mods);

    foreach my $pkgnm (sort keys %$mods) {
	test_pkg($pkgnm);
    }
}

__END__
