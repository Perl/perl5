use strict;
use warnings;

sub trace {
    my $trace = Test::Builder->trace_test;
    return $trace;
}

BEGIN {
    $INC{'XXX/Provider.pm'} = __FILE__;
    $INC{'XXX/LegacyProvider.pm'} = __FILE__;
    $INC{'XXX/Tester.pm'}   = __FILE__;
}

# line 1000
{
    package XXX::Provider;
    use Test::Builder::Provider;

    BEGIN {
        provide explode => sub {
            exploded();
        };
    }

    sub exploded { overkill() }

    sub overkill {
        return main::trace();
    }

    sub nestit(&) {
        my ($code) = @_;
        nest{ $code->() };
        return main::trace();
    }

    sub nonest(&) {
        my ($code) = @_;
        $code->();
        return main::trace();
    }

    BEGIN {
        provides qw/nestit/;

        provides qw/nonest/;
    }
}

# line 1500
{
    package XXX::LegacyProvider;
    use base 'Test::Builder::Module';

    our @EXPORT;
    BEGIN { @EXPORT = qw/do_it do_it_2 do_nestit do_nonest/ };

# line 1600
    sub do_it {
        my $builder = __PACKAGE__->builder;

        my $trace = Test::Builder->trace_test;
        return $trace;
    }

# line 1700
    sub do_it_2 {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        do_it(@_);
    }

# line 1800
    sub do_nestit(&) {
        my ($code) = @_;
        my $trace = Test::Builder->trace_test;
        # TODO: I Think this is wrong...
        local $Test::Builder::Level = $Test::Builder::Level + 3;
        $code->();
        return $trace;
    }
}

# line 2000
package XXX::Tester;
use XXX::Provider;
use XXX::LegacyProvider;
use Test::Builder::Provider;
use Data::Dumper;
use Test::More;

provides 'explodable';
# line 2100
sub explodable    { explode() };
# line 2200
sub explodadouble { explode() };

# line 2300
my $trace = explodable();
is($trace->report->line,    2300,          "got correct line");
is($trace->report->package, 'XXX::Tester', "got correct package");
is_deeply(
    $trace->report->provider_tool,
    {package => 'XXX::Tester', name => 'explodable', named => 1},
    "got tool info"
);

# line 2400
$trace = explodadouble();
is($trace->report->line,    2200,          "got correct line");
is($trace->report->package, 'XXX::Tester', "got correct package");
is_deeply(
    $trace->report->provider_tool,
    {package => 'XXX::Provider', name => 'explode', named => 0},
    "got tool info"
);

# line 2500
$trace = explode();
is($trace->report->line,    2500,          "got correct line");
is($trace->report->package, 'XXX::Tester', "got correct package");
is_deeply(
    $trace->report->provider_tool,
    {package => 'XXX::Provider', name => 'explode', named => 0},
    "got tool info"
);

# line 2600
$trace = do_it();
is($trace->report->line,    2600,          "got correct line");
is($trace->report->package, 'XXX::Tester', "got correct package");
ok(!$trace->report->provider_tool, "No Tool");

# line 2700
$trace = do_it_2();
is($trace->report->line,    2700,          "got correct line");
is($trace->report->package, 'XXX::Tester', "got correct package");
is($trace->report->level,   1,             "Is level");
ok(!$trace->report->provider_tool, "No Tool");

my @results;

# Here we simulate subtests
# line 2800
$trace = nestit {
    push @results => explodable();
    push @results => explodadouble();
    push @results => explode();
    push @results => do_it();
    push @results => do_it_2();
}; # Report line is here

is($trace->report->line, 2806, "Nesting tool reported correct line");

is($results[0]->report->line, 2801, "Got nested line, our tool");
is($results[1]->report->line, 2200, "Nested, but tool is not 'provided' so goes up to provided");
is($results[2]->report->line, 2803, "Got nested line external tool");
is($results[3]->report->line, 2804, "Got nested line legacy tool");
is($results[4]->report->line, 2805, "Got nested line deeper legacy tool");

@results = ();
my $outer;
# line 2900
$outer = nestit {
    $trace = nestit {
        push @results => explodable();
        push @results => explodadouble();
        push @results => explode();
        push @results => do_it();
        push @results => do_it_2();
    }; # Report line is here
};

# line 2920
is($outer->report->line, 2908, "Nesting tool reported correct line");
is($trace->report->line, 2907, "Nesting tool reported correct line");

# line 2930
is($results[0]->report->line, 2902, "Got nested line, our tool");
is($results[1]->report->line, 2200, "Nested, but tool is not 'provided' so goes up to provided");
is($results[2]->report->line, 2904, "Got nested line external tool");
is($results[3]->report->line, 2905, "Got nested line legacy tool");
is($results[4]->report->line, 2906, "Got nested line deeper legacy tool");

@results = ();
# line 3000
$trace = nonest {
    push @results => explodable();
    push @results => explodadouble();
    push @results => explode();
    push @results => do_it();
    push @results => do_it_2();
}; # Report line is here

is($trace->report->line, 3006, "NoNesting tool reported correct line");

is($results[0]->report->line, 3006, "Lowest tool is nonest, so these get squashed (Which is why you use nesting)");
is($results[1]->report->line, 3006, "Lowest tool is nonest, so these get squashed (Which is why you use nesting)");
is($results[2]->report->line, 3006, "Lowest tool is nonest, so these get squashed (Which is why you use nesting)");
is($results[3]->report->line, 3006, "Lowest tool is nonest, so these get squashed(Legacy) (Which is why you use nesting)");
is($results[4]->report->line, 3006, "Lowest tool is nonest, so these get squashed(Legacy) (Which is why you use nesting)");

@results = ();

# line 3100
$trace = do_nestit {
    push @results => explodable();
    push @results => explodadouble();
    push @results => explode();
    push @results => do_it();
    push @results => do_it_2();
}; # Report line is here

is($trace->report->line, 3106, "Nesting tool reported correct line");

is($results[0]->report->line, 3101, "Got nested line, our tool");
is($results[1]->report->line, 2200, "Nested, but tool is not 'provided' so goes up to provided");
is($results[2]->report->line, 3103, "Got nested line external tool");
is($results[3]->report->line, 3104, "Got nested line legacy tool");
is($results[4]->report->line, 3105, "Got nested line deeper legacy tool");

done_testing;
