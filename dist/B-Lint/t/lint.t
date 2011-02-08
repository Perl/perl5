#!./perl -w

BEGIN {
    unshift @INC, 't';
    require Config;
    if ( ( $Config::Config{'extensions'} !~ /\bB\b/ ) ) {
        print "1..0 # Skip -- Perl configured without B module\n";
        exit 0;
    }
}

use strict;
use warnings;

use Test::More tests => 56;
use Test::PerlRun qw(perlrun perlrun_stderr_like);

# Runs a separate perl interpreter with the appropriate lint options
# turned on
sub runlint ($$$;$) {
    my ( $opts, $prog, $result, $testname ) = @_;
    my ($out, $err) = perlrun({
        switches => ["-MO=Lint,$opts"],
        code     => $prog,
    });
    $err =~ s/-e syntax OK\n$//;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is( $err, $result, $testname || $opts );
    is( $out, '', 'nothing on STDOUT' );
}

runlint 'magic-diamond', 'while(<>){}', <<'RESULT';
Use of <> at -e line 1
RESULT

runlint 'magic-diamond', 'while(<ARGV>){}', <<'RESULT';
Use of <> at -e line 1
RESULT

runlint 'magic-diamond', 'while(<FOO>){}', <<'RESULT';
RESULT

runlint 'context', '$foo = @bar', <<'RESULT';
Implicit scalar context for array in scalar assignment at -e line 1
RESULT

runlint 'context', '$foo = length @bar', <<'RESULT';
Implicit scalar context for array in length at -e line 1
RESULT

runlint 'context', 'our @bar', '';

runlint 'context', 'exists $BAR{BAZ}', '';

runlint 'implicit-read', '/foo/', <<'RESULT';
Implicit match on $_ at -e line 1
RESULT

runlint 'implicit-read', 'grep /foo/, ()', '';

runlint 'implicit-read', 'grep { /foo/ } ()', '';

runlint 'implicit-write', 's/foo/bar/', <<'RESULT';
Implicit substitution on $_ at -e line 1
RESULT

runlint 'implicit-read', 'for ( @ARGV ) { 1 }',
    <<'RESULT', 'implicit-read in foreach';
Implicit use of $_ in foreach at -e line 1
RESULT

runlint 'implicit-read', '1 for @ARGV', '', 'implicit-read in foreach';

runlint 'dollar-underscore', '$_ = 1', <<'RESULT';
Use of $_ at -e line 1
RESULT

runlint 'dollar-underscore', 'sub foo {}; foo( $_ ) for @A',      '';
runlint 'dollar-underscore', 'sub foo {}; map { foo( $_ ) } @A',  '';
runlint 'dollar-underscore', 'sub foo {}; grep { foo( $_ ) } @A', '';

runlint 'dollar-underscore', 'print',
    <<'RESULT', 'dollar-underscore in print';
Use of $_ at -e line 1
RESULT

runlint 'private-names', 'sub A::_f{};A::_f()', <<'RESULT';
Illegal reference to private name '_f' at -e line 1
RESULT

runlint 'private-names', '$A::_x', <<'RESULT';
Illegal reference to private name '_x' at -e line 1
RESULT

runlint 'private-names', 'sub A::_f{};A->_f()', <<'RESULT',
Illegal reference to private method name '_f' at -e line 1
RESULT
    'private-names (method)';

runlint 'undefined-subs', 'foo()', <<'RESULT';
Nonexistent subroutine 'foo' called at -e line 1
RESULT

runlint 'undefined-subs', 'foo();sub foo;', <<'RESULT';
Undefined subroutine 'foo' called at -e line 1
RESULT

runlint 'regexp-variables', 'print $&', <<'RESULT';
Use of regexp variable $& at -e line 1
RESULT

runlint 'regexp-variables', 's/./$&/', <<'RESULT';
Use of regexp variable $& at -e line 1
RESULT

runlint 'bare-subs', 'sub bare(){1};$x=bare', '';

runlint 'bare-subs', 'sub bare(){1}; $x=[bare=>0]; $x=$y{bare}', <<'RESULT';
Bare sub name 'bare' interpreted as string at -e line 1
Bare sub name 'bare' interpreted as string at -e line 1
RESULT

{

    # Check for backwards-compatible plugin support. This was where
    # preloaded mdoules would register themselves with B::Lint.
    perlrun_stderr_like({
        switches => ["-MB::Lint"],
        code =>
            'BEGIN{B::Lint->register_plugin(X=>[q[x]])};use O(qw[Lint x]);sub X::match{warn qq[X ok.\n]};dummy()',
	}, qr/X ok\./, 'Lint legacy plugin' );
}

{

    # Check for Module::Plugin support
    perlrun_stderr_like({
        switches => [ '-It/pluglib', '-MO=Lint,none' ],
        code     => 1,
    }, qr/Module::Pluggable ok\./, 'Lint uses Module::Pluggable' );
}
