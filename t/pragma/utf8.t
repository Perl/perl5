#!./perl 

BEGIN {
    chdir 't' if -d 't';
    unshift @INC, '../lib';
    $ENV{PERL5LIB} = '../lib';
    if ( ord("\t") != 9 ) { # skip on ebcdic platforms
        print "1..0 # Skip utf8 tests on ebcdic platform.\n";
        exit;
    }
}

print "1..12\n";

my $test = 1;

sub ok {
    my ($got,$expect) = @_;
    print "# expected [$expect], got [$got]\nnot " if $got ne $expect;
    print "ok $test\n";
}

{
    use utf8;
    $_ = ">\x{263A}<"; 
    s/([\x{80}-\x{10ffff}])/"&#".ord($1).";"/eg; 
    ok $_, '>&#9786;<';
    $test++;

    $_ = ">\x{263A}<"; 
    my $rx = "\x{80}-\x{10ffff}";
    s/([$rx])/"&#".ord($1).";"/eg; 
    ok $_, '>&#9786;<';
    $test++;

    $_ = ">\x{263A}<"; 
    my $rx = "\\x{80}-\\x{10ffff}";
    s/([$rx])/"&#".ord($1).";"/eg; 
    ok $_, '>&#9786;<';
    $test++;

    $_ = "alpha,numeric"; 
    m/([[:alpha:]]+)/; 
    ok $1, 'alpha';
    $test++;

    $_ = "alphaNUMERICstring";
    m/([[:^lower:]]+)/; 
    ok $1, 'NUMERIC';
    $test++;

    $_ = "alphaNUMERICstring";
    m/(\p{Ll}+)/; 
    ok $1, 'alpha';
    $test++;

    $_ = "alphaNUMERICstring"; 
    m/(\p{Lu}+)/; 
    ok $1, 'NUMERIC';
    $test++;

    $_ = "alpha,numeric"; 
    m/([\p{IsAlpha}]+)/; 
    ok $1, 'alpha';
    $test++;

    $_ = "alphaNUMERICstring";
    m/([^\p{IsLower}]+)/; 
    ok $1, 'NUMERIC';
    $test++;

    $_ = "alpha123numeric456"; 
    m/([\p{IsDigit}]+)/; 
    ok $1, '123';
    $test++;

    $_ = "alpha123numeric456"; 
    m/([^\p{IsDigit}]+)/; 
    ok $1, 'alpha';
    $test++;

    $_ = ",123alpha,456numeric"; 
    m/([\p{IsAlnum}]+)/; 
    ok $1, '123alpha';
    $test++;
}
