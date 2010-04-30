#!./perl

print "1..30\n";
my $test_num = 0;
sub ok {
       print $_[0] ? "" : "not ", "ok ", ++$test_num, "\n";
}

sub do_test {
    my($src, $expect_value, $match_warning) = @_;
    my($value, $warning);
    local $SIG{__WARN__} = sub { $warning .= $_[0] };
    $value = eval($src);
    ok defined($expect_value) ? $value == $expect_value : !defined($value);
    ok $warning =~ $match_warning;
}

do_test "0x123", 291, qr/\A\z/;
do_test "0x123.8", 2918, qr/\ADot after hexadecimal literal is deprecated /;
do_test "0x123 .8", 2918, qr/\A\z/;
do_test "0x123. 8", 2918, qr/\ADot after hexadecimal literal is deprecated /;
do_test "[0x123..8] && 5", 5, qr/\A\z/;

do_test "0123", 83, qr/\A\z/;
do_test "0123.4", 834, qr/\ADot after octal literal is deprecated /;
do_test "0123 .4", 834, qr/\A\z/;
do_test "0123. 4", 834, qr/\ADot after octal literal is deprecated /;
do_test "[0123..4] && 5", 5, qr/\A\z/;

do_test "0b101", 5, qr/\A\z/;
do_test "0b101.1", 51, qr/\ADot after binary literal is deprecated /;
do_test "0b101 .1", 51, qr/\A\z/;
do_test "0b101. 1", 51, qr/\ADot after binary literal is deprecated /;
do_test "[0b101..1] && 5", 5, qr/\A\z/;

1;
