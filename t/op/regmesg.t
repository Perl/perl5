#!./perl -w

BEGIN {
	chdir 't' if -d 't';
	unshift @INC, '../lib';
}

my $debug = 1;

##
## If the markers used are changed (search for "MARKER1" in regcomp.c),
## update only these two variables, and leave the {#} in the @death/@warning
## arrays below. The {#} is a meta-marker -- it marks where the marker should
## go.

my $marker1 = "<HERE<";
my $marker2 = " <<<HERE<<< ";

##
## Key-value pairs of code/error of code that should have fatal errors.
##
my @death =
(
 '/[[=foo=]]/' => 'POSIX syntax [= =] is reserved for future extensions at {#} mark in regex m/[[=foo=]{#}]/',

 '/(?<= .*)/' =>  'Variable length lookbehind not implemented at {#} mark in regex m/(?<= .*){#}/',

 '/(?<= x{10000})/' => 'Lookbehind longer than 255 not implemented at {#} mark in regex m/(?<= x{10000}){#}/',

 '/(?@)/' => 'Sequence (?@...) not implemented at {#} mark in regex m/(?@{#})/',

 '/(?{ 1/' => 'Sequence (?{...}) not terminated or not {}-balanced at {#} mark in regex m/(?{{#} 1/',

 '/(?(1x))/' => 'Switch condition not recognized at {#} mark in regex m/(?(1x{#}))/',

 '/(?(1)x|y|z)/' => 'Switch (?(condition)... contains too many branches at {#} mark in regex m/(?(1)x|y|{#}z)/',

 '/(?(x)y|x)/' => 'Unknown switch condition (?(x) at {#} mark in regex m/(?({#}x)y|x)/',

 '/(?/' => 'Sequence (? incomplete at {#} mark in regex m/(?{#}/',

 '/(?;x/' => 'Sequence (?;...) not recognized at {#} mark in regex m/(?;{#}x/',
 '/(?<;x/' => 'Sequence (?<;...) not recognized at {#} mark in regex m/(?<;{#}x/',

 '/((x)/' => 'Unmatched ( at {#} mark in regex m/({#}(x)/',

 '/x{99999}/' => 'Quantifier in {,} bigger than 32766 at {#} mark in regex m/x{{#}99999}/',

 '/x{3,1}/' => 'Can\'t do {n,m} with n > m at {#} mark in regex m/x{3,1}{#}/',

 '/x**/' => 'Nested quantifiers at {#} mark in regex m/x**{#}/',

 '/x[/' => 'Unmatched [ at {#} mark in regex m/x[{#}/',

 '/*/', => 'Quantifier follows nothing at {#} mark in regex m/*{#}/',

 '/\p{x/' => 'Missing right brace on \p{} at {#} mark in regex m/\p{{#}x/',

 'use utf8; /[\p{x]/' => 'Missing right brace on \p{} at {#} mark in regex m/[\p{{#}x]/',

 '/(x)\2/' => 'Reference to nonexistent group at {#} mark in regex m/(x)\2{#}/',

 'my $m = chr(92); $m =~ $m', => 'Trailing \ in regex m/\/',

 '/\x{1/' => 'Missing right brace on \x{} at {#} mark in regex m/\x{{#}1/',

 'use utf8; /[\x{X]/' => 'Missing right brace on \x{} at {#} mark in regex m/[\x{{#}X]/',

 '/\x{x}/' => 'Can\'t use \x{} without \'use utf8\' declaration at {#} mark in regex m/\x{x}{#}/',

 '/[[:barf:]]/' => 'POSIX class [:barf:] unknown at {#} mark in regex m/[[:barf:]{#}]/',

 '/[[=barf=]]/' => 'POSIX syntax [= =] is reserved for future extensions at {#} mark in regex m/[[=barf=]{#}]/',

 '/[[.barf.]]/' => 'POSIX syntax [. .] is reserved for future extensions at {#} mark in regex m/[[.barf.]{#}]/',
  
 '/[z-a]/' => 'Invalid [] range "z-a" at {#} mark in regex m/[z-a{#}]/',
);

##
## Key-value pairs of code/error of code that should have non-fatal warnings.
##
@warning = (
    "m/(?p{ 'a' })/" => "(?p{}) is deprecated - use (??{}) at {#} mark in regex m/(?p{#}{ 'a' })/",

    'm/\b*/' => '\b* matches null string many times at {#} mark in regex m/\b*{#}/',

    'm/[:blank:]/' => 'POSIX syntax [: :] belongs inside character classes at {#} mark in regex m/[:blank:]{#}/',

    "m'[\\y]'"     => 'Unrecognized escape \y in character class passed through at {#} mark in regex m/[\y{#}]/',

    'm/[a-\d]/' => 'False [] range "a-\d" at {#} mark in regex m/[a-\d{#}]/',
    'm/[\w-x]/' => 'False [] range "\w-" at {#} mark in regex m/[\w-{#}x]/',
    "m'\\y'"     => 'Unrecognized escape \y passed through at {#} mark in regex m/\y{#}/',
);

my $total = (@death + @warning)/2;

print "1..$total\n";

my $count = 0;

while (@death)
{
    $count++;
    my $regex = shift @death;
    my $result = shift @death;

    undef $@;
    $_ = "x";
    eval $regex;
    if (not $@) {
	if ($debug) {
	    print "oops, $regex didn't die\n"
	} else {
	    print "not ok $count\n";
	}
	next;
    }
    chomp $@;
    $@ =~ s/ at \(.*?\) line \d+\.$//;
    $result =~ s/{\#}/$marker1/;
    $result =~ s/{\#}/$marker2/;
    if ($@ ne $result) {
	if ($debug) {
	    print "For $regex, expected:\n  $result\nGot:\n  $@\n\n";
	} else {
	    print "not ok $count\n";
	}
	next;
    }
    print "ok $count\n";
}


our $warning;
$SIG{__WARN__} = sub { $warning = shift };

while (@warning)
{
    $count++;
    my $regex = shift @warning;
    my $result = shift @warning;

    undef $warning;
    $_ = "x";
    eval $regex;

    if ($@)
    {
	if ($debug) {
	    print "oops, $regex died with:\n\t$@\n";
	} else {
	    print "not ok $count\n";
	}
	next;
    }

    if (not $warning)
    {
	if ($debug) {
	    print "oops, $regex didn't generate a warning\n";
	} else {
	    print "not ok $count\n";
	}
	next;
    }
    chomp $warning;
    $warning =~ s/ at \(.*?\) line \d+\.$//;
    $result =~ s/{\#}/$marker1/;
    $result =~ s/{\#}/$marker2/;
    if ($warning ne $result)
    {
	if ($debug) {
	    print "For $regex, expected:\n  $result\nGot:\n  $warning\n\n";
	} else {
	    print "not ok $count\n";
	}
	next;
    }
    print "ok $count\n";
}



