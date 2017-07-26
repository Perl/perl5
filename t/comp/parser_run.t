#!./perl

# Parser tests that want test.pl, eg to use runperl() for tests to show
# reads through invalid pointers.
# Note that this should still be runnable under miniperl.

BEGIN {
    @INC = qw(. ../lib );
    chdir 't' if -d 't';
}

require './test.pl';
plan(2);

# [perl #130814] can reallocate lineptr while looking ahead for
# "Missing $ on loop variable" diagnostic.
my $result = fresh_perl(
    " foreach m0\n\$" . ("0" x 0x2000),
    { stderr => 1 },
);
is($result . "\n", <<EXPECT);
syntax error at - line 3, near "foreach m0
"
Identifier too long at - line 3.
EXPECT

fresh_perl_is(<<EOS, <<'EXPECT', {}, "linestart before bufptr");
\${ \xD5eeeeeeeeeeee
'x
EOS
Unrecognized character \xD5; marked by <-- HERE after ${ <-- HERE near column 4 at - line 1.
EXPECT

__END__
# ex: set ts=8 sts=4 sw=4 et:
