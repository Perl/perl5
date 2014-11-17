use strict;
use warnings;
use B;

use Test::Stream;
use Test::MostlyLike;
use Test::More tests => 3;
use Test::Builder; # Not loaded by default in modern mode
my $orig = Test::Builder->can('note');

{
    package MyModernTester;
    use Test::More;
    use Test::Stream;
    use Test::MostlyLike;

    no warnings 'redefine';
    local *Test::Builder::note = sub {
        my $self = shift;
        return $self->$orig(__PACKAGE__ . ": ", @_);
    };
    use warnings;

    my $file = __FILE__;
    # Line number is tricky, just use what B says The sub may not actually think it
    # is on the line it is may be off by 1.
    my $line = B::svref_2object(\&Test::Builder::note)->START->line;

    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings => @_ };
        note('first');
        note('seconds');
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
    use Test::More;
    use Test::Stream;
    use Test::MostlyLike;

    no warnings 'redefine';
    local *Test::Builder::note = sub {
        my $self = shift;
        return $self->$orig(__PACKAGE__ . ": ", @_);
    };
    use warnings;

    my $file = __FILE__;
    # Line number is tricky, just use what B says The sub may not actually think it
    # is on the line it is may be off by 1.
    my $line = B::svref_2object(\&Test::Builder::note)->START->line;

    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings => @_ };
        note('first');
        note('seconds');
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
    local *Test::Builder::note = sub {
        my $self = shift;
        return $self->$orig(__PACKAGE__ . ": ", @_);
    };
    use warnings;

    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings => @_ };
        note('first');
        note('seconds');
    }
    is(@warnings, 0, "no warnings for a legacy tester");
}
