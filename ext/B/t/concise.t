#!./perl

BEGIN {
    chdir 't';
    @INC = '../lib';
    require './test.pl';
}

plan tests => 38;

require_ok("B::Concise");

$out = runperl(switches => ["-MO=Concise"], prog => '$a', stderr => 1);

# If either of the next two tests fail, it probably means you need to
# fix the section labeled 'fragile kludge' in Concise.pm

($op_base) = ($out =~ /^(\d+)\s*<0>\s*enter/m);

is($op_base, 1, "Smallest OP sequence number");

($op_base_p1, $cop_base)
  = ($out =~ /^(\d+)\s*<;>\s*nextstate\(main (-?\d+) /m);

is($op_base_p1, 2, "Second-smallest OP sequence number");

is($cop_base, 1, "Smallest COP sequence number");

# test that with -exec B::Concise navigates past logops (bug #18175)

$out = runperl(
    switches => ["-MO=Concise,-exec"],
    prog => q{$a//=$b && print q/foo/},
    stderr => 1,
);

like($out, qr/print/, "'-exec' option output has print opcode");

######## API tests v.60 

use Config;	# used for perlio check
B::Concise->import(qw(set_style set_style_standard add_callback 
		      add_style walk_output));

## walk_output argument checking

# test that walk_output accepts a HANDLE arg
foreach my $foo (\*STDOUT, \*STDERR) {
    eval {  walk_output($foo) };
    is ($@, '', "walk_output() accepts STD* " . ref $foo);
}

# test that walk_output rejects non-HANDLE args
foreach my $foo (undef, 0, "string",[], {}) {
    eval {  walk_output($foo) };
    isnt ($@, '', "walk_output() rejects arg '$foo'");
    $@=''; # clear the fail for next test
}

{   # any object that can print should be ok for walk_output
    package Hugo;
    sub new { my $foo = bless {} };
    sub print { CORE::print @_ }
}
my $foo = new Hugo;	# suggested this API fix
eval {  walk_output($foo) };
is ($@, '', "walk_output() accepts obj that can print");

# now test a ref to scalar
eval {  walk_output(\my $junk) };
is ($@, '', "walk_output() accepts ref-to-sprintf target");

$junk = "non-empty";
eval {  walk_output(\$junk) };
is ($@, '', "walk_output() accepts ref-to-non-empty-scalar");

## add_style
my @stylespec;
$@='';
eval { add_style ('junk_B' => @stylespec) };
like ($@, 'expecting 3 style-format args',
    "add_style rejects insufficient args");

@stylespec = (0,0,0); # right length, invalid values
$@='';
eval { add_style ('junk' => @stylespec) };
is ($@, '', "add_style accepts: stylename => 3-arg-array");

$@='';
eval { add_style (junk => @stylespec) };
like ($@, qr/style 'junk' already exists, choose a new name/,
    "add_style correctly disallows re-adding same style-name" );

# test new arg-checks on set_style
$@='';
eval { set_style (@stylespec) };
is ($@, '', "set_style accepts 3 style-format args");

@stylespec = (); # bad style

eval { set_style (@stylespec) };
like ($@, qr/expecting 3 style-format args/,
    "set_style rejects bad style-format args");


#### for content with doc'd options

set_style_standard('concise');  # MUST CALL b4 output needed
my $func = sub{ $a = $b+42 };

@options = qw(
    -basic -exec -tree -compact -loose -vt -ascii -main
    -base10 -bigendian -littleendian
    );
foreach $opt (@options) {
    walk_output(\my $out);
    my $treegen = B::Concise::compile($opt, $func);
    $treegen->();
    #print "foo:$out\n";
    isnt($out, '', "got output with option $opt");
}

## test output control via walk_output

my $treegen = B::Concise::compile('-basic', $func); # reused

{ # test output into a package global string (sprintf-ish)
    our $thing;
    walk_output(\$thing);
    $treegen->();
    ok($thing, "walk_output to our SCALAR, output seen");
}

{ # test output to GLOB, using perlio feature directly
    skip 1, "no perlio on this build" unless $Config{useperlio};
    open (my $fh, '>', \my $buf);
    walk_output($fh);
    $treegen->();
    ok($buf, "walk_output to GLOB, output seen");
}

## Test B::Concise::compile error checking

# call compile on non-CODE ref items
foreach my $ref ([], {}) {
    my $typ = ref $ref;
    walk_output(\my $out);
    eval { B::Concise::compile('-basic', $ref)->() };
    like ($@, qr/^err: not a coderef: $typ/,
	  "compile detects $typ-ref where expecting subref");
    # is($out,'', "no output when errd"); # announcement prints
}

# test against a bogus autovivified subref.
# in debugger, it should look like:
#  1  CODE(0x84840cc)
#      -> &CODE(0x84840cc) in ???
sub nosuchfunc;
eval { B::Concise::compile('-basic', \&nosuchfunc)->() };
like ($@, qr/^err: coderef has no START/,
      "compile detects CODE-ref w/o actual code");

foreach my $opt (qw( -concise -exec )) {
    eval { B::Concise::compile($opt,'non_existent_function')->() };
    like ($@, qr/unknown function \(main::non_existent_function\)/,
	  "'$opt' reports non-existent-function properly");
}
