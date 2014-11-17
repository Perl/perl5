use strict;
use warnings;
use B;

use Test::Stream;
use Test::MostlyLike;
use Test::More tests => 9;
use Test::Builder; # Not loaded by default in modern mode
my $orig = Test::Builder->can('ok');

{
    package MyModernTester;
    use Test::Stream;
    use Test::MostlyLike;
    use Test::More;

    no warnings 'redefine';
    local *Test::Builder::ok = sub {
        my $self = shift;
        my ($bool, $name) = @_;
        $name = __PACKAGE__ . ":  $name";
        return $self->$orig($bool, $name);
    };
    use warnings;

    my $file = __FILE__;
    # Line number is tricky, just use what B says The sub may not actually think it
    # is on the line it is may be off by 1.
    my $line = B::svref_2object(\&Test::Builder::ok)->START->line;

    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings => @_ };
        ok(1, "fred");
        ok(2, "barney");
    }
    mostly_like(
        \@warnings,
        [
            qr{The new sub is 'MyModernTester::__ANON__' defined in \Q$file\E around line $line},
            undef, #Only 1 warning
        ],
        "Found expected warning, just the one"
    );
}

{
    package MyModernTester2;
    use Test::Stream;
    use Test::MostlyLike;
    use Test::More;

    no warnings 'redefine';
    local *Test::Builder::ok = sub {
        my $self = shift;
        my ($bool, $name) = @_;
        $name = __PACKAGE__ . ": $name";
        return $self->$orig($bool, $name);
    };
    use warnings;

    my $file = __FILE__;
    # Line number is tricky, just use what B says The sub may not actually think it
    # is on the line it is may be off by 1.
    my $line = B::svref_2object(\&Test::Builder::ok)->START->line;

    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings => @_ };
        ok(1, "fred");
        ok(2, "barney");
    }
    mostly_like(
        \@warnings,
        [
            qr{The new sub is 'MyModernTester2::__ANON__' defined in \Q$file\E around line $line},
            undef, #Only 1 warning
        ],
        "new override, new warning"
    );
}

{
    package MyLegacyTester;
    use Test::More;

    no warnings 'redefine';
    local *Test::Builder::ok = sub {
        my $self = shift;
        my ($bool, $name) = @_;
        $name = __PACKAGE__ . ":  $name";
        return $self->$orig($bool, $name);
    };
    use warnings;

    my $file = __FILE__;
    # Line number is tricky, just use what B says The sub may not actually think it
    # is on the line it is may be off by 1.
    my $line = B::svref_2object(\&Test::Builder::ok)->START->line;

    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings => @_ };
        ok(1, "fred");
        ok(2, "barney");
    }
    is(@warnings, 0, "no warnings for a legacy tester");
}
