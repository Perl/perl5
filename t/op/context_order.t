#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}

use strict;
use warnings;

# Compile a sub without executing its body. The two operands warn in
# different categories, so making one category fatal reveals which operand
# was processed first without depending on rendered diagnostic text.
sub compile_expression {
    my ($body, $fatal_category) = @_;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    local $SIG{__DIE__};

    my $policy = defined $fatal_category
        ? "use warnings FATAL => '$fatal_category';"
        : 'use warnings;';
    my $sub = eval "$policy sub { my \@a; my %h; $body }";

    return (defined($sub) ? 1 : 0, scalar @warnings);
}

# Binary operands and the array reference/selector must be contextualized
# in source order. Multiplication is a control: it already used separate
# statements before the other binary actions were repaired.
my @expressions = map {
    [$_, "my \$x = ((sort \@a) $_ %h{1,2});"]
} qw(+ - ** << >> & | ^ .. ... cmp <=> xor * / %);
push @expressions, ['array subscript', 'my $x = (sort @a)->[%h{1,2}];'];

for my $expression (@expressions) {
    my ($name, $body) = @$expression;

    my ($compiled, $warnings) = compile_expression($body);
    ok($compiled, "$name compiles with nonfatal warnings");
    is($warnings, 2, "$name emits both operand warnings");

    ($compiled, $warnings) = compile_expression($body, 'scalar');
    ok(!$compiled, "$name stops on the left operand's fatal warning");
    is($warnings, 0, "$name does not process the right operand first");

    ($compiled, $warnings) = compile_expression($body, 'syntax');
    ok(!$compiled, "$name reaches the right operand's fatal warning");
    is($warnings, 1, "$name warns about the left operand before stopping");
}

# Repetition first handles its scalar RHS while its LHS can remain a list.
# That defined order differs from ordinary binary scalar operands.
my ($repeat_compiled, $repeat_warnings) =
    compile_expression('my $x = ((sort @a) x %h{1,2});', 'scalar');
ok(!$repeat_compiled, 'repetition eventually applies scalar context to its LHS');
is($repeat_warnings, 1, 'repetition processes its scalar RHS first');
($repeat_compiled, $repeat_warnings) =
    compile_expression('my $x = ((sort @a) x %h{1,2});', 'syntax');
ok(!$repeat_compiled, 'repetition stops on a fatal RHS warning');
is($repeat_warnings, 0, 'repetition preserves its distinct LHS context');

# Invalid assignment targets are diagnosed before contextualizing the RHS.
# Once the target adds a compile error, the unrelated RHS warning is skipped.
for my $operator (qw(= += -= *= **=)) {
    my ($compiled, $warnings) = compile_expression("1 $operator sort \@a;");
    ok(!$compiled, "$operator rejects a constant assignment target");
    is($warnings, 0, "$operator suppresses a secondary RHS warning");
}

my ($compiled, $warnings) = compile_expression('(sort @a) += %h{1,2};');
ok(!$compiled, 'compound assignment rejects a sort target');
is($warnings, 1, 'only the target warning precedes its lvalue error');

# Logical assignment already contextualizes the RHS before validating the
# target. Keep that explicit policy while sequencing its op construction.
for my $operator (qw(||= &&= //=)) {
    my ($compiled, $warnings) = compile_expression("1 $operator sort \@a;");
    ok(!$compiled, "$operator rejects a constant assignment target");
    is($warnings, 1, "$operator preserves its explicit RHS-first policy");
}

done_testing();
